import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationService {
  /// Captura a posição atual do dispositivo
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização desativado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização permanentemente negada');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Converte as coordenadas atuais em um endereço legível
  static Future<Map<String, String>> getAddressFromPosition(
    Position pos,
  ) async {
    await geocoding.setLocaleIdentifier('pt_BR');
    final placemarks = await geocoding.placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    if (placemarks.isEmpty) {
      throw Exception('Não foi possível obter o endereço');
    }

    final place = placemarks.first;

    final cidade = place.locality?.isNotEmpty == true
        ? place.locality!
        : (place.subAdministrativeArea ?? '');
    final estado = place.administrativeArea ?? '';
    final rua = place.thoroughfare ?? place.street ?? '';
    final numero = place.subThoroughfare ?? '';
    final bairro = place.subLocality ?? '';

    final endereco = [
      rua,
      numero,
      bairro,
    ].where((segment) => segment.trim().isNotEmpty).join(', ');

    return {
      "cidade": cidade,
      "estado": estado,
      "endereco": endereco, // Ex: "R. Dr. Moacir de Souza Rocha, 229, Araripe"
    };
  }
}
