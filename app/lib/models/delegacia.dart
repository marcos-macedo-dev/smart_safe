class Delegacia {
  final int id;
  final String nome;
  final String? endereco;
  final double? latitude;
  final double? longitude;
  final String? telefone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Delegacia({
    required this.id,
    required this.nome,
    this.endereco,
    this.latitude,
    this.longitude,
    this.telefone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Delegacia.fromJson(Map<String, dynamic> json) {
    return Delegacia(
      id: json['id'],
      nome: json['nome'],
      endereco: json['endereco'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      telefone: json['telefone'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'telefone': telefone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Delegacia copyWith({
    int? id,
    String? nome,
    String? endereco,
    double? latitude,
    double? longitude,
    String? telefone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Delegacia(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      telefone: telefone ?? this.telefone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}