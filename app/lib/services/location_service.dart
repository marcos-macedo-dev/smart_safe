import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _apiKey =
      "AIzaSyB8wfAvwFWSUnx6xxitWbszOMzVYJTpAkM"; // pega do manifest

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

  /// Usa a Google Geocoding API para obter endereço detalhado
  static Future<Map<String, String>> getAddressFromPosition(
    Position pos,
  ) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&key=$_apiKey&language=pt-BR",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Erro ao acessar Geocoding API: ${response.statusCode}");
    }

    final data = json.decode(response.body);

    if (data["status"] != "OK" || data["results"].isEmpty) {
      throw Exception("Não foi possível obter o endereço");
    }

    final result = data["results"][0];
    final components = result["address_components"] as List;

    String cidade = "";
    String estado = "";
    String rua = "";
    String numero = "";
    String bairro = "";

    for (var comp in components) {
      final types = List<String>.from(comp["types"]);
      if (types.contains("administrative_area_level_2")) {
        cidade = comp["long_name"];
      } else if (types.contains("administrative_area_level_1")) {
        estado = comp["short_name"]; // ex: CE
      } else if (types.contains("route")) {
        rua = comp["long_name"]; // nome da rua
      } else if (types.contains("street_number")) {
        numero = comp["long_name"]; // número da casa/prédio
      } else if (types.contains("sublocality") ||
          types.contains("sublocality_level_1")) {
        bairro = comp["long_name"]; // bairro
      }
    }

    final endereco = [
      rua,
      numero,
      bairro,
    ].where((e) => e.isNotEmpty).join(", ");

    return {
      "cidade": cidade,
      "estado": estado,
      "endereco": endereco, // Ex: "R. Dr. Moacir de Souza Rocha, 229, Araripe"
    };
  }
}
