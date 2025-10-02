import 'package:intl/intl.dart'; // Para formatação de data, se necessário

class IncidentLocation {
  final int id;
  final int sos_id;
  final double latitude;
  final double longitude;
  final double? precisao; // Renomeado de accuracy
  final double? nivel_bateria; // Renomeado de batteryLevel
  final DateTime registrado_em; // Renomeado de timestamp

  IncidentLocation({
    required this.id,
    required this.sos_id,
    required this.latitude,
    required this.longitude,
    this.precisao,
    this.nivel_bateria,
    required this.registrado_em,
  });

  factory IncidentLocation.fromJson(Map<String, dynamic> json) {
    return IncidentLocation(
      id: json['id'],
      sos_id: json['sos_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      precisao: json['precisao'],
      nivel_bateria: json['nivel_bateria'],
      registrado_em: DateTime.parse(json['registrado_em']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sos_id': sos_id,
        'latitude': latitude,
        'longitude': longitude,
        'precisao': precisao,
        'nivel_bateria': nivel_bateria,
        'registrado_em': registrado_em.toIso8601String(),
      };

  String get formattedRegistradoEm {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(registrado_em);
  }
}