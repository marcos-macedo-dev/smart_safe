// Assuming User model might be needed for usuario_id reference

class EmergencyContact {
  final int? id;
  final String nome;
  final String telefone;
  final String? email;
  final String? parentesco; // Added parentesco field
  final int usuarioId; // Foreign key to User
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmergencyContact({
    this.id,
    required this.nome,
    required this.telefone,
    this.email,
    this.parentesco, // Added to constructor
    required this.usuarioId,
    this.createdAt,
    this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      nome: json['nome'],
      telefone: json['telefone'],
      email: json['email'],
      parentesco: json['parentesco'], // Added to fromJson
      usuarioId: json['usuario_id'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'parentesco': parentesco, // Added to toJson
      'usuario_id': usuarioId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Added copyWith method
  EmergencyContact copyWith({
    int? id,
    String? nome,
    String? telefone,
    String? email,
    String? parentesco,
    int? usuarioId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      parentesco: parentesco ?? this.parentesco,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}