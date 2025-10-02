import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SosDetailScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const SosDetailScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SosDetailScreen> createState() => _SosDetailScreenState();
}

class _SosDetailScreenState extends State<SosDetailScreen> {
  late GoogleMapController _mapController;
  late LatLng _sosLocation;
  LatLng? _userLocation;
  late Set<Marker> _markers;
  late Set<Circle> _circles;
  MapType _currentMapType = MapType.normal;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _sosLocation = LatLng(widget.latitude, widget.longitude);

    _markers = {
      Marker(
        markerId: const MarkerId('sos_location'),
        position: _sosLocation,
        infoWindow: const InfoWindow(
          title: 'Local do SOS',
          snippet: 'Este é o local exato onde o SOS foi acionado',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    _circles = {
      Circle(
        circleId: const CircleId('sos_radius'),
        center: _sosLocation,
        radius: 200,
        fillColor: Colors.redAccent.withOpacity(0.2),
        strokeColor: Colors.redAccent,
        strokeWidth: 2,
      ),
    };

    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviços de localização desativados.')),
          );
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permissão de localização negada.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Permissão de localização negada permanentemente. Habilite nas configurações.')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: _userLocation!,
            infoWindow: const InfoWindow(title: 'Sua posição'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização do usuário: $e')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
  }

  void _centerMap() {
    if (_isMapReady) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _sosLocation, zoom: 15),
        ),
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 20,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Legenda do Mapa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '🔴 Círculo vermelho: Área do SOS (200m de raio)',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 4),
            Text(
              '📍 Marcador vermelho: Local exato do SOS',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 4),
            Text(
              '📍 Marcador azul: Sua posição atual',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _toggleMapType,
            tooltip: 'Alterar tipo de mapa',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerMap,
            tooltip: 'Centralizar mapa',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _sosLocation,
                zoom: 15.0,
              ),
              markers: _markers,
              circles: _circles,
              mapType: _currentMapType,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(12, 18),
            ),
            _buildLegend(),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          child: const Icon(Icons.zoom_in),
          onPressed: () {
            if (_isMapReady) {
              _mapController.animateCamera(CameraUpdate.zoomIn());
            }
          },
          tooltip: 'Aproximar mapa',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
