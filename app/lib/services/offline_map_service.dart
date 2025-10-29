import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  static const String _cachedRegionsKey = 'offline_map_regions';
  final List<OfflineRegion> _cachedRegions = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadCachedRegions();
      _isInitialized = true;
      print(
        'OfflineMapService: Inicializado com ${_cachedRegions.length} regiões em cache',
      );
    } catch (e) {
      print('OfflineMapService: Erro na inicialização: $e');
    }
  }

  Future<void> _loadCachedRegions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final regionsJson = prefs.getStringList(_cachedRegionsKey) ?? [];

      for (final regionJson in regionsJson) {
        final regionMap = jsonDecode(regionJson) as Map<String, dynamic>;
        final region = OfflineRegion.fromJson(regionMap);
        _cachedRegions.add(region);
      }
    } catch (e) {
      print('OfflineMapService: Erro ao carregar regiões em cache: $e');
    }
  }

  Future<void> _saveCachedRegions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Serializar regiões para JSON
      final regionsJson = _cachedRegions
          .map((region) => jsonEncode(region.toJson()))
          .toList();
      await prefs.setStringList(_cachedRegionsKey, regionsJson);
    } catch (e) {
      print('OfflineMapService: Erro ao salvar regiões em cache: $e');
    }
  }

  /// Faz download de uma área para uso offline
  Future<bool> downloadOfflineRegion({
    required LatLngBounds bounds,
    required String name,
    required int minZoom,
    required int maxZoom,
  }) async {
    try {
      // Verificar conectividade antes de fazer download
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('OfflineMapService: Sem conectividade para fazer download');
        return false;
      }

      // Criar região offline
      final offlineRegion = OfflineRegion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: maxZoom,
        creationTime: DateTime.now(),
      );

      // Adicionar à lista de regiões em cache
      _cachedRegions.add(offlineRegion);
      await _saveCachedRegions();

      print('OfflineMapService: Região "$name" adicionada ao cache offline');
      return true;
    } catch (e) {
      print('OfflineMapService: Erro ao fazer download da região: $e');
      return false;
    }
  }

  /// Remove uma região do cache offline
  Future<bool> removeOfflineRegion(String regionId) async {
    try {
      _cachedRegions.removeWhere((region) => region.id == regionId);
      await _saveCachedRegions();
      print('OfflineMapService: Região $regionId removida do cache offline');
      return true;
    } catch (e) {
      print('OfflineMapService: Erro ao remover região: $e');
      return false;
    }
  }

  /// Verifica se uma coordenada está dentro de uma região em cache
  bool isLocationInOfflineRegion(LatLng location) {
    return _cachedRegions.any((region) => region.containsLocation(location));
  }

  /// Obtém todas as regiões em cache
  List<OfflineRegion> getCachedRegions() {
    return List.unmodifiable(_cachedRegions);
  }

  /// Calcula bounds para uma área crítica baseada na localização atual
  LatLngBounds calculateEmergencyBounds(
    LatLng center, {
    double radiusKm = 5.0,
  }) {
    // Aproximação: 1 grau ≈ 111 km
    final latOffset = radiusKm / 111.0;
    final lngOffset = radiusKm / (111.0 * cos(center.latitude * pi / 180.0));

    return LatLngBounds(
      southwest: LatLng(
        center.latitude - latOffset,
        center.longitude - lngOffset,
      ),
      northeast: LatLng(
        center.latitude + latOffset,
        center.longitude + lngOffset,
      ),
    );
  }

  /// Faz download automático de área de emergência baseada na localização atual
  Future<bool> downloadEmergencyArea(LatLng currentLocation) async {
    const emergencyName = 'Área de Emergência';
    final bounds = calculateEmergencyBounds(currentLocation);

    return await downloadOfflineRegion(
      bounds: bounds,
      name: emergencyName,
      minZoom: 10,
      maxZoom: 16,
    );
  }

  /// Limpa todas as regiões em cache
  Future<void> clearAllCache() async {
    _cachedRegions.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedRegionsKey);
    print('OfflineMapService: Cache de mapas limpo');
  }
}

/// Representa uma região offline
class OfflineRegion {
  final String id;
  final String name;
  final LatLngBounds bounds;
  final int minZoom;
  final int maxZoom;
  final DateTime creationTime;

  OfflineRegion({
    required this.id,
    required this.name,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.creationTime,
  });

  bool containsLocation(LatLng location) {
    return location.latitude >= bounds.southwest.latitude &&
        location.latitude <= bounds.northeast.latitude &&
        location.longitude >= bounds.southwest.longitude &&
        location.longitude <= bounds.northeast.longitude;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bounds': {
        'southwest': {
          'lat': bounds.southwest.latitude,
          'lng': bounds.southwest.longitude,
        },
        'northeast': {
          'lat': bounds.northeast.latitude,
          'lng': bounds.northeast.longitude,
        },
      },
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'creationTime': creationTime.toIso8601String(),
    };
  }

  factory OfflineRegion.fromJson(Map<String, dynamic> json) {
    final boundsJson = json['bounds'] as Map<String, dynamic>;
    final sw = boundsJson['southwest'] as Map<String, dynamic>;
    final ne = boundsJson['northeast'] as Map<String, dynamic>;

    return OfflineRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      bounds: LatLngBounds(
        southwest: LatLng(sw['lat'] as double, sw['lng'] as double),
        northeast: LatLng(ne['lat'] as double, ne['lng'] as double),
      ),
      minZoom: json['minZoom'] as int,
      maxZoom: json['maxZoom'] as int,
      creationTime: DateTime.parse(json['creationTime'] as String),
    );
  }
}
