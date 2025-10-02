// Para formatação de data, se necessário

enum TipoMidia {
  video,
  audio,
}

class Media {
  final int? id;
  final int? sos_id;
  final TipoMidia tipo;
  final String caminho;
  final DateTime createdAt;
  final DateTime updatedAt;

  Media({
    this.id,
    this.sos_id,
    required this.tipo,
    required this.caminho,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      sos_id: json['sos_id'],
      tipo: TipoMidia.values.firstWhere(
        (e) => e.toString().split('.').last == json['tipo'],
        orElse: () => TipoMidia.audio,
      ),
      caminho: json['caminho'] ?? '', // Read 'caminho' directly from backend response
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sos_id': sos_id,
    'tipo': tipo.toString().split('.').last,
    'caminho': caminho,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
