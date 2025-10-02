import 'user_enums.dart';

class User {
  final int id;
  final String nome_completo;
  final String email;
  final String? senha; // Add senha field for registration
  final String? telefone;
  final String? cpf;
  final DateTime? data_nascimento;
  final Genero? genero; // Use Genero enum
  final Cor? cor; // Use Cor enum
  final String? cidade;
  final String? estado;
  final String? endereco;
  final String? documento_identificacao;
  final bool? consentimento; // Add consentimento field
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.nome_completo,
    required this.email,
    this.senha,
    this.telefone,
    this.cpf,
    this.data_nascimento,
    this.genero,
    this.cor,
    this.cidade,
    this.estado,
    this.endereco,
    this.documento_identificacao,
    this.consentimento,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nome_completo: json['nome_completo'],
      email: json['email'],
      senha: json['senha'],
      telefone: json['telefone'],
      cpf: json['cpf'],
      data_nascimento: json['data_nascimento'] != null
          ? DateTime.parse(json['data_nascimento']).toLocal()
          : null,
      genero: json['genero'] != null 
          ? Genero.values.firstWhere(
              (e) => e.toString().split('.').last == json['genero'],
              orElse: () => Genero.Feminino)
          : null,
      cor: json['cor'] != null
          ? Cor.values.firstWhere(
              (e) => e.toString().split('.').last == json['cor'],
              orElse: () => Cor.Outra)
          : null,
      cidade: json['cidade'],
      estado: json['estado'],
      endereco: json['endereco'],
      documento_identificacao: json['documento_identificacao'],
      consentimento: json['consentimento'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_completo': nome_completo,
      'email': email,
      'senha': senha,
      'telefone': telefone,
      'cpf': cpf,
      'data_nascimento': data_nascimento?.toIso8601String(),
      'genero': genero?.toString().split('.').last,
      'cor': cor?.toString().split('.').last,
      'cidade': cidade,
      'estado': estado,
      'endereco': endereco,
      'documento_identificacao': documento_identificacao,
      'consentimento': consentimento,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toRegisterJson() {
    return {
      'nome_completo': nome_completo,
      'email': email,
      'senha': senha,
      'telefone': telefone,
      'cpf': cpf,
      'data_nascimento': data_nascimento?.toIso8601String(),
      'genero': genero?.toString().split('.').last,
      'cor': cor?.toString().split('.').last,
      'cidade': cidade,
      'estado': estado,
      'endereco': endereco,
      'documento_identificacao': documento_identificacao,
      'consentimento': consentimento,
    };
  }

  User copyWith({
    int? id,
    String? nome_completo,
    String? email,
    String? senha,
    String? telefone,
    String? cpf,
    DateTime? data_nascimento,
    Genero? genero,
    Cor? cor,
    String? cidade,
    String? estado,
    String? endereco,
    String? documento_identificacao,
    bool? consentimento,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      nome_completo: nome_completo ?? this.nome_completo,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      data_nascimento: data_nascimento ?? this.data_nascimento,
      genero: genero ?? this.genero,
      cor: cor ?? this.cor,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      endereco: endereco ?? this.endereco,
      documento_identificacao: documento_identificacao ?? this.documento_identificacao,
      consentimento: consentimento ?? this.consentimento,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}