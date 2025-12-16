import 'package:flutter/material.dart'; // Para IconData, se necessário
import 'package:intl/intl.dart'; // Para formatação de data
import '../config.dart'; // Importação da configuração global

enum SosStatus { pendente, ativo, aguardando_autoridade, fechado, cancelado }

class SosRecord {
  final int id;
  final int usuario_id; // Renomeado de userId
  final String? caminho_video; // Novo campo
  final String? caminho_audio; // Renomeado de audioUrl
  final double latitude;
  final double longitude;
  final SosStatus status; // Enum atualizado
  final DateTime? encerrado_em; // Novo campo
  final DateTime createdAt;
  final DateTime updatedAt;

  static const String _baseUrl = baseUrl; // Uso da constante global

  SosRecord({
    required this.id,
    required this.usuario_id,
    this.caminho_video,
    required this.caminho_audio,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.encerrado_em,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SosRecord.fromJson(Map<String, dynamic> json) {
    return SosRecord(
      id: json['id'],
      usuario_id: json['usuario_id'],
      caminho_video: json['caminho_video'],
      caminho_audio: json['caminho_audio'],
      latitude: double.parse(json['latitude'].toString()), // Parse to double
      longitude: double.parse(json['longitude'].toString()), // Parse to double
      status: SosStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SosStatus.pendente,
      ), // Valor padrão caso não encontre
      encerrado_em: json['encerrado_em'] != null
          ? DateTime.parse(json['encerrado_em']).toLocal()
          : null,
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt']).toLocal(),
    );
  }

  String? get fullCaminhoVideoUrl {
    if (caminho_video == null || caminho_video!.isEmpty) return null;
    if (caminho_video!.startsWith('http')) return caminho_video;
    final normalized = caminho_video!.startsWith('/')
        ? caminho_video!.substring(1)
        : caminho_video!;
    // Garante que a baseUrl termine com '/' se o caminho não começar com '/'
    // ou remove a '/' extra se ambos tiverem
    if (_baseUrl.endsWith('/') && normalized.startsWith('/')) {
        return '$_baseUrl${normalized.substring(1)}';
    } else if (!_baseUrl.endsWith('/') && !normalized.startsWith('/')) {
        return '$_baseUrl/$normalized';
    }
    return '$_baseUrl$normalized';
  }

  String? get fullCaminhoAudioUrl {
    if (caminho_audio == null || caminho_audio!.isEmpty) return null;
    if (caminho_audio!.startsWith('http')) return caminho_audio;
    final normalized = caminho_audio!.startsWith('/')
        ? caminho_audio!.substring(1)
        : caminho_audio!;
    
    // Mesma lógica de normalização de barra
    if (_baseUrl.endsWith('/') && normalized.startsWith('/')) {
        return '$_baseUrl${normalized.substring(1)}';
    } else if (!_baseUrl.endsWith('/') && !normalized.startsWith('/')) {
        return '$_baseUrl/$normalized';
    }
    return '$_baseUrl$normalized';
  }


  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuario_id,
    'caminho_video': caminho_video,
    'caminho_audio': caminho_audio,
    'latitude': latitude,
    'longitude': longitude,
    'status': status.toString().split('.').last,
    'encerrado_em': encerrado_em?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  String get statusText {
    switch (status) {
      case SosStatus.pendente:
        return 'Pendente';
      case SosStatus.ativo:
        return 'Ativo';
      case SosStatus.aguardando_autoridade:
        return 'Aguardando Autoridade';
      case SosStatus.fechado:
        return 'Fechado';
      case SosStatus.cancelado:
        return 'Cancelado';
    }
  }

  Color get statusColor {
    switch (status) {
      case SosStatus.pendente:
        return Colors.orange;
      case SosStatus.ativo:
        return Colors.blue;
      case SosStatus.aguardando_autoridade:
        return Colors.purple;
      case SosStatus.fechado:
        return Colors.green;
      case SosStatus.cancelado:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case SosStatus.pendente:
        return Icons.hourglass_empty;
      case SosStatus.ativo:
        return Icons.warning;
      case SosStatus.aguardando_autoridade:
        return Icons.local_police;
      case SosStatus.fechado:
        return Icons.check_circle;
      case SosStatus.cancelado:
        return Icons.cancel;
    }
  }

  SosRecord copyWith({
    int? id,
    int? usuario_id,
    String? caminho_video,
    String? caminho_audio,
    double? latitude,
    double? longitude,
    SosStatus? status,
    DateTime? encerrado_em,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SosRecord(
      id: id ?? this.id,
      usuario_id: usuario_id ?? this.usuario_id,
      caminho_video: caminho_video ?? this.caminho_video,
      caminho_audio: caminho_audio ?? this.caminho_audio,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      encerrado_em: encerrado_em ?? this.encerrado_em,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
