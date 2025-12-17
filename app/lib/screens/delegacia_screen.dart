import 'dart:async';
import 'dart:convert'; // Import for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/delegacia.dart';
import '../services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class DelegaciaScreen extends StatefulWidget {
  const DelegaciaScreen({Key? key}) : super(key: key);

  @override
  State<DelegaciaScreen> createState() => _DelegaciaScreenState();
}

class _DelegaciaScreenState extends State<DelegaciaScreen> {
  static const Color _violetaEscura = Color(0xFF311756);

  // Tema dinâmico
  Color get cardColor => Theme.of(context).colorScheme.surface;
  Color get textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get accent {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF7C5CC3) : _violetaEscura;
  }

  Color get shadow {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Colors.black.withOpacity(isDark ? 0.35 : 0.08);
  }

  List<Delegacia> _delegacias = [];
  bool _isLoading = true;
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;
  LatLng _initialPosition = const LatLng(-7.2063196, -40.1335461);
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionStreamSubscription;

  TextEditingController searchController = TextEditingController();
  List<Delegacia> filteredDelegacias = [];

  static const String _delegaciasCacheKey = 'delegacias_cache';
  static const String _cacheTimestampKey = 'delegacias_cache_timestamp';
  static const Duration _cacheDuration = Duration(
    hours: 24,
  ); // Cache por 24 horas

  @override
  void initState() {
    super.initState();
    _initData();
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    await _getUserLocation();
    await _loadDelegacias();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _initialPosition = _userLocation!;
    });

    // Recalcula cores dos marcadores
    if (_delegacias.isNotEmpty) {
      _updateMarkers();
    }
  }

  void _startLocationStream() {
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // meters
          ),
        ).listen((Position position) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
          });
          _updateMarkers();
          _centerMap(); // Center map on user's new location
        });
  }

  void _updateMarkers() {
    final markers = _delegacias
        .where((d) => d.latitude != null && d.longitude != null)
        .map((d) {
          final distance = _userLocation != null
              ? _calculateDistance(
                  _userLocation!,
                  LatLng(d.latitude!, d.longitude!),
                )
              : double.infinity;
          return Marker(
            markerId: MarkerId(d.id.toString()),
            position: LatLng(d.latitude!, d.longitude!),
            infoWindow: InfoWindow(title: d.nome, snippet: d.endereco),
            icon: _getMarkerColor(distance),
          );
        })
        .toSet();

    setState(() {
      _markers = markers;
    });
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
  }

  BitmapDescriptor _getMarkerColor(double distance) {
    if (distance < 10000) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (distance <= 50000) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _loadDelegacias() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_delegaciasCacheKey);
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey);

      // Mostra cache rapidamente (se ainda válido) enquanto buscamos dados frescos
      if (cachedData != null && cachedTimestamp != null) {
        final lastCacheTime = DateTime.fromMillisecondsSinceEpoch(
          cachedTimestamp,
        );
        if (DateTime.now().difference(lastCacheTime) < _cacheDuration) {
          final List<dynamic> jsonList = jsonDecode(cachedData);
          final cached = jsonList
              .map((json) => Delegacia.fromJson(json))
              .toList();
          if (mounted) {
            setState(() {
              _delegacias = cached;
              filteredDelegacias = List.from(cached);
              _isLoading = false;
            });
          }
          _updateMarkers();
        }
      }

      // Sempre tenta atualizar a partir da API para evitar lista desatualizada
      final fetched = await ApiService.getDelegacias();
      if (fetched.isNotEmpty) {
        if (mounted) {
          setState(() {
            _delegacias = fetched;
            filteredDelegacias = List.from(fetched);
            _isLoading = false;
          });
        }
        _updateMarkers();

        // Atualiza cache apenas com resposta não vazia
        final String jsonString = jsonEncode(
          fetched.map((d) => d.toJson()).toList(),
        );
        await prefs.setString(_delegaciasCacheKey, jsonString);
        await prefs.setInt(
          _cacheTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      } else if (mounted && _isLoading) {
        // Não veio nada e não tínhamos cache válido
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar delegacias: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (_isLoading) setState(() => _isLoading = false);
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _centerMap() {
    if (_userLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 12),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : _currentMapType == MapType.satellite
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  void _filterDelegacias(String query) {
    setState(() {
      filteredDelegacias = _delegacias
          .where(
            (d) =>
                d.nome.toLowerCase().contains(query.toLowerCase()) ||
                (d.endereco?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
    });
  }

  Widget _buildSearchField(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: _filterDelegacias,
        style: TextStyle(
          fontSize: textScaler.scale(15),
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar delegacia...',
          hintStyle: TextStyle(
            color: textMuted,
            fontSize: textScaler.scale(15),
            letterSpacing: -0.2,
          ),
          prefixIcon: Icon(LucideIcons.search, color: accent, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDelegaciaCard(
    Delegacia delegacia,
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    final distance =
        _userLocation != null &&
            delegacia.latitude != null &&
            delegacia.longitude != null
        ? _calculateDistance(
                _userLocation!,
                LatLng(delegacia.latitude!, delegacia.longitude!),
              ) /
              1000
        : null;

    Color distanceColor;
    String proximityLabel;
    IconData proximityIcon;

    if (distance != null) {
      if (distance < 10) {
        distanceColor = Colors.green;
        proximityLabel = 'Próximo';
        proximityIcon = LucideIcons.navigation;
      } else if (distance <= 50) {
        distanceColor = Colors.orange;
        proximityLabel = 'Médio';
        proximityIcon = LucideIcons.mapPin;
      } else {
        distanceColor = Colors.red;
        proximityLabel = 'Longe';
        proximityIcon = LucideIcons.mapPinOff;
      }
    } else {
      distanceColor = colorScheme.onSurfaceVariant;
      proximityLabel = 'Desconhecido';
      proximityIcon = LucideIcons.mapPinX;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (delegacia.latitude != null && delegacia.longitude != null) {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(delegacia.latitude!, delegacia.longitude!),
                  15,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Ícone principal
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.shield,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Conteúdo principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delegacia.nome,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: textScaler.scale(15),
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        delegacia.endereco ?? 'Endereço não disponível',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: textScaler.scale(13),
                          color: textMuted,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Status de proximidade
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: distanceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: distanceColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(proximityIcon, size: 12, color: distanceColor),
                            const SizedBox(width: 4),
                            Text(
                              proximityLabel,
                              style: TextStyle(
                                color: distanceColor,
                                fontWeight: FontWeight.w600,
                                fontSize: textScaler.scale(11),
                                letterSpacing: -0.1,
                              ),
                            ),
                            if (distance != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                "${distance.toStringAsFixed(1)} km",
                                style: TextStyle(
                                  color: distanceColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: textScaler.scale(11),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Botão de direções
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final url = Uri.encodeFull(
                          'https://www.google.com/maps/dir/?api=1&destination=${delegacia.latitude},${delegacia.longitude}',
                        );
                        launchUrlString(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: Center(
                        child: Icon(
                          LucideIcons.navigation,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDelegaciaList(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.25,
        minChildSize: 0.1,
        maxChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Campo de busca
              _buildSearchField(theme, colorScheme, textScaler),

              // Lista de delegacias
              if (filteredDelegacias.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.searchX,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma delegacia encontrada',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: textScaler.scale(15),
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredDelegacias.map(
                  (delegacia) => _buildDelegaciaCard(
                    delegacia,
                    theme,
                    colorScheme,
                    textScaler,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _toggleMapType,
                child: Container(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(
                      LucideIcons.layers,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _centerMap,
                child: Container(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(
                      LucideIcons.locate,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accent, strokeWidth: 2),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: textScaler.scale(15),
                      color: textMuted,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 12,
                  ),
                  markers: _markers,
                  mapType: _currentMapType,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  minMaxZoomPreference: const MinMaxZoomPreference(5, 18),
                ),
                _buildDelegaciaList(theme, colorScheme, textScaler),
                _buildFloatingButtons(theme, colorScheme),
              ],
            ),
    );
  }
}
