import 'dart:async';
import 'dart:convert'; // Import for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
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
    final markers = _delegacias.where((d) => d.latitude != null && d.longitude != null).map((d) {
      final distance = _userLocation != null
          ? _calculateDistance(_userLocation!, LatLng(d.latitude!, d.longitude!))
          : double.infinity;
      return Marker(
        markerId: MarkerId(d.id.toString()),
        position: LatLng(d.latitude!, d.longitude!),
        infoWindow: InfoWindow(title: d.nome, snippet: d.endereco),
        icon: _getMarkerColor(distance),
      );
    }).toSet();

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

      if (cachedData != null && cachedTimestamp != null) {
        final lastCacheTime = DateTime.fromMillisecondsSinceEpoch(
          cachedTimestamp,
        );
        if (DateTime.now().difference(lastCacheTime) < _cacheDuration) {
          // Use cached data
          final List<dynamic> jsonList = jsonDecode(cachedData);
          final fetched = jsonList
              .map((json) => Delegacia.fromJson(json))
              .toList();
          setState(() {
            _delegacias = fetched;
            filteredDelegacias = List.from(fetched);
          });
          _updateMarkers();
          return; // Exit early, using cached data
        }
      }

      // Fetch from API if no cache or cache expired
      final fetched = await ApiService.getDelegacias();
      setState(() {
        _delegacias = fetched;
        filteredDelegacias = List.from(fetched);
      });
      _updateMarkers();

      // Save to cache
      final String jsonString = jsonEncode(
        fetched.map((d) => d.toJson()).toList(),
      );
      await prefs.setString(_delegaciasCacheKey, jsonString);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
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
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                (d.endereco?.toLowerCase().contains(query.toLowerCase()) ?? false),
          )
          .toList();
    });
  }

  Widget _buildSearchField(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: _filterDelegacias,
        style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Buscar delegacia...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.primary.withOpacity(0.7),
            size: 20,
          ),
          filled: true,
          fillColor: theme.colorScheme.primary.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDelegaciaCard(Delegacia delegacia, ThemeData theme) {
    final distance = _userLocation != null && delegacia.latitude != null && delegacia.longitude != null
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
        proximityIcon = Icons.near_me;
      } else if (distance <= 50) {
        distanceColor = Colors.orange;
        proximityLabel = 'Médio';
        proximityIcon = Icons.location_on;
      } else {
        distanceColor = Colors.red;
        proximityLabel = 'Longe';
        proximityIcon = Icons.location_off;
      }
    } else {
      distanceColor = theme.colorScheme.onSurface.withOpacity(0.5);
      proximityLabel = 'Desconhecido';
      proximityIcon = Icons.location_disabled;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone principal
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_police,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Conteúdo principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delegacia.nome,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        delegacia.endereco ?? 'Endereço não disponível',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Status de proximidade
                      Row(
                        children: [
                          Icon(proximityIcon, size: 14, color: distanceColor),
                          const SizedBox(width: 4),
                          Text(
                            proximityLabel,
                            style: TextStyle(
                              color: distanceColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              "${distance.toStringAsFixed(1)} km",
                              style: TextStyle(
                                color: distanceColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Botão de direções
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
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
                          Icons.directions,
                          color: theme.colorScheme.primary,
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

  Widget _buildDelegaciaList(ThemeData theme) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.25,
        minChildSize: 0.1,
        maxChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Campo de busca
              _buildSearchField(theme),

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
                          Icons.search_off,
                          size: 32,
                          color: theme.colorScheme.onSurface.withAlpha(128),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhuma delegacia encontrada',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withAlpha(128),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredDelegacias.map(
                  (delegacia) => _buildDelegaciaCard(delegacia, theme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(ThemeData theme) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _toggleMapType,
                child: Container(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(
                      Icons.layers,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _centerMap,
                child: Container(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(
                      Icons.my_location,
                      color: theme.colorScheme.primary,
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

    return Scaffold(
      backgroundColor: theme.colorScheme.primary.withAlpha(30),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
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
                _buildDelegaciaList(theme),
                _buildFloatingButtons(theme),
              ],
            ),
    );
  }
}
