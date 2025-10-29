import 'dart:io';
import '../models/sos_record.dart';
import 'api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/local_database.dart'; // Import LocalDatabase
import 'package:connectivity_plus/connectivity_plus.dart'; // Adicionar este import
import 'advanced_sync_service.dart';

class SosService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalDatabase _localDatabase =
      LocalDatabase(); // LocalDatabase instance
  final AdvancedSyncService _advancedSyncService = AdvancedSyncService();
  bool _isSyncing = false; // Adicionar esta flag

  SosService(this._apiService);

  Future<int?> _getUserId() async {
    String? userIdString = await _secureStorage.read(key: 'userId');
    return userIdString != null ? int.tryParse(userIdString) : null;
  }

  Future<List<SosRecord>> getSosRecords() async {
    final usuarioId = await _getUserId();
    if (usuarioId == null) return [];

    try {
      // Tenta buscar do servidor primeiro
      final response = await _apiService.get('/sos?usuario_id=$usuarioId');
      if (response.statusCode == 200 && response.data is List) {
        // Se a busca online for bem-sucedida, retorna os dados do servidor
        return (response.data as List)
            .map((json) => SosRecord.fromJson(json))
            .toList();
      }
      // Se o status code não for 200, ou dados inválidos, tenta buscar localmente
      print(
        'SosService: Falha ao buscar SOSs online (status: ${response.statusCode}), tentando buscar localmente.',
      );
      return await _localDatabase
          .getUnsyncedSosRecords(); // Retorna os não sincronizados, que são os locais
    } catch (e) {
      // Se houver um erro de conexão ou qualquer outra exceção, busca localmente
      print(
        'SosService: Erro ao buscar SOSs online: $e, tentando buscar localmente.',
      );
      return await _localDatabase
          .getUnsyncedSosRecords(); // Retorna os não sincronizados, que são os locais
    }
  }

  Future<SosRecord?> createSos({
    required double latitude,
    required double longitude,
    String? caminhoAudio, // This will be local path or null
    String? caminhoVideo, // This will be local path or null
  }) async {
    final usuarioId = await _getUserId();
    if (usuarioId == null) return null;

    // Sempre salvar localmente primeiro (modo offline-first)
    final localSosRecord = await _saveSosLocally(
      usuarioId,
      latitude,
      longitude,
      caminhoAudio,
      caminhoVideo,
    );
    if (localSosRecord == null) {
      print('SosService: Falha ao salvar SOS localmente');
      return null;
    }

    // Tentar sincronizar online em background se houver conectividade
    _trySyncOnline(localSosRecord).catchError((error) {
      print('SosService: Erro na sincronização online (background): $error');
      // Se falhar, adicionar ao sistema de sincronização avançada
      _addToAdvancedSync(localSosRecord);
    });

    return localSosRecord;
  }

  // Método para adicionar SOS à fila de sincronização avançada
  Future<void> _addToAdvancedSync(SosRecord sosRecord) async {
    try {
      await _advancedSyncService.queueSosSync(sosRecord, 'create');
      print(
        'SosService: SOS ${sosRecord.id} adicionado à fila de sincronização avançada',
      );
    } catch (e) {
      print('SosService: Erro ao adicionar SOS à fila de sincronização: $e');
    }
  }

  // Método para tentar sincronizar online em background
  Future<void> _trySyncOnline(SosRecord localSosRecord) async {
    try {
      // Verificar conectividade
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        print('SosService: Sem conectividade, pulando sincronização online');
        return;
      }

      print(
        'SosService: Tentando sincronizar SOS ${localSosRecord.id} online...',
      );

      String? finalCaminhoAudio = localSosRecord.caminho_audio;
      String? finalCaminhoVideo = localSosRecord.caminho_video;

      // Tentar fazer upload da mídia se for caminho local
      if (localSosRecord.caminho_audio != null &&
          !localSosRecord.caminho_audio!.startsWith('http')) {
        try {
          final uploadedMedia = await ApiService.uploadFile(
            File(localSosRecord.caminho_audio!),
          );
          if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
            finalCaminhoAudio = uploadedMedia.caminho;
            // Não deletar arquivo local ainda - será deletado após confirmação da sincronização
          }
        } catch (e) {
          print('SosService: Erro ao fazer upload de áudio: $e');
        }
      }

      if (localSosRecord.caminho_video != null &&
          !localSosRecord.caminho_video!.startsWith('http')) {
        try {
          final uploadedMedia = await ApiService.uploadFile(
            File(localSosRecord.caminho_video!),
          );
          if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
            finalCaminhoVideo = uploadedMedia.caminho;
            // Não deletar arquivo local ainda
          }
        } catch (e) {
          print('SosService: Erro ao fazer upload de vídeo: $e');
        }
      }

      // Preparar dados para envio
      final Map<String, dynamic> data = {
        'usuario_id': localSosRecord.usuario_id,
        'latitude': localSosRecord.latitude,
        'longitude': localSosRecord.longitude,
        'status': localSosRecord.status.toString().split('.').last,
        'createdAt': localSosRecord.createdAt.toIso8601String(),
        'updatedAt': localSosRecord.updatedAt.toIso8601String(),
      };

      if (finalCaminhoAudio != null) {
        data['caminho_audio'] = finalCaminhoAudio;
      }
      if (finalCaminhoVideo != null) {
        data['caminho_video'] = finalCaminhoVideo;
      }
      if (localSosRecord.encerrado_em != null) {
        data['encerrado_em'] = localSosRecord.encerrado_em!.toIso8601String();
      }

      // Tentar enviar para API
      final response = await _apiService.post('/sos', data: data);
      if (response.statusCode == 201) {
        // Sucesso - marcar como sincronizado e limpar arquivos locais se foram enviados
        await _localDatabase.markSosRecordAsSynced(localSosRecord.id);
        print(
          'SosService: SOS ${localSosRecord.id} sincronizado com sucesso online',
        );

        // Limpar arquivos locais após confirmação
        if (localSosRecord.caminho_audio != null &&
            finalCaminhoAudio != localSosRecord.caminho_audio) {
          try {
            await File(localSosRecord.caminho_audio!).delete();
            print('SosService: Arquivo de áudio local deletado após upload');
          } catch (e) {
            print('SosService: Erro ao deletar arquivo de áudio local: $e');
          }
        }
        if (localSosRecord.caminho_video != null &&
            finalCaminhoVideo != localSosRecord.caminho_video) {
          try {
            await File(localSosRecord.caminho_video!).delete();
            print('SosService: Arquivo de vídeo local deletado após upload');
          } catch (e) {
            print('SosService: Erro ao deletar arquivo de vídeo local: $e');
          }
        }
      } else {
        print(
          'SosService: Falha ao sincronizar SOS ${localSosRecord.id} - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(
        'SosService: Erro na sincronização online do SOS ${localSosRecord.id}: $e',
      );
    }
  }

  // Helper method to save SOS locally
  Future<SosRecord?> _saveSosLocally(
    int usuarioId,
    double latitude,
    double longitude,
    String? caminhoAudio,
    String? caminhoVideo,
  ) async {
    try {
      final localSosRecord = SosRecord(
        id: 0, // Will be auto-incremented by SQLite
        usuario_id: usuarioId,
        latitude: latitude,
        longitude: longitude,
        status: SosStatus.pendente,
        caminho_audio: caminhoAudio, // Save original local path
        caminho_video: caminhoVideo, // Save original local path
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        encerrado_em: null,
      );
      final localId = await _localDatabase.insertSosRecord(localSosRecord);
      return localSosRecord.copyWith(id: localId);
    } catch (e) {
      print('Erro ao salvar SOS localmente: $e');
      return null;
    }
  }

  // Adicionar esta função ao SosService
  Future<void> syncPendingSosRecords() async {
    if (_isSyncing) {
      // Se já estiver sincronizando, sai
      print('SosService: Sincronização já em andamento, pulando.');
      return;
    }
    _isSyncing = true; // Define a flag para indicar que a sincronização começou

    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        print('SosService: Sem conexão, pulando sincronização.');
        return;
      }

      print('SosService: Tentando sincronizar SOSs pendentes...');
      final unsyncedRecords = await _localDatabase.getUnsyncedSosRecords();
      for (var record in unsyncedRecords) {
        try {
          final Map<String, dynamic> data = {
            'usuario_id': record.usuario_id,
            'latitude': record.latitude,
            'longitude': record.longitude,
            'status': record.status
                .toString()
                .split('.')
                .last, // Convert enum to string
            'createdAt': record.createdAt.toIso8601String(),
            'updatedAt': record.updatedAt.toIso8601String(),
          };
          if (record.caminho_audio != null) {
            data['caminho_audio'] = record.caminho_audio;
          }
          if (record.caminho_video != null) {
            data['caminho_video'] = record.caminho_video;
          }
          if (record.encerrado_em != null) {
            data['encerrado_em'] = record.encerrado_em!.toIso8601String();
          }

          final response = await _apiService.post('/sos', data: data);
          if (response.statusCode == 201) {
            await _localDatabase.markSosRecordAsSynced(record.id);
            print('SosService: SOS ${record.id} sincronizado com sucesso.');
          } else {
            print(
              'SosService: Falha ao sincronizar SOS ${record.id}. Status: ${response.statusCode}',
            );
          }
        } catch (e) {
          print('SosService: Erro ao sincronizar SOS ${record.id}: $e');
        }
      }
    } finally {
      _isSyncing =
          false; // Garante que a flag seja resetada, mesmo em caso de erro
    }
  }

  /// Atualiza os campos de mídia de um SOS existente
  Future<bool> updateSosMedia({
    required int sosId,
    String? caminhoAudio,
    String? caminhoVideo,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (caminhoAudio != null) data['caminho_audio'] = caminhoAudio;
      if (caminhoVideo != null) data['caminho_video'] = caminhoVideo;

      if (data.isEmpty) {
        print('updateSosMedia: Nenhum dado para atualizar.'); // LOG
        return false;
      }

      print(
        'updateSosMedia: Enviando para /sos/$sosId com dados: $data',
      ); // LOG
      final response = await _apiService.put('/sos/$sosId', data: data);
      print(
        'updateSosMedia: Resposta do backend: ${response.statusCode}',
      ); // LOG
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao atualizar SOS: $e');
      return false;
    }
  }

  /// Envia localização em tempo real para rastreamento de apuros
  Future<void> sendRealtimeLocation({
    required int sosId,
    required double latitude,
    required double longitude,
    double precisao = 0.0,
    double nivelBateria = 100.0,
  }) async {
    try {
      await _apiService.post(
        '/rastreamento-apuros',
        data: {
          'sos_id': sosId,
          'latitude': latitude,
          'longitude': longitude,
          'precisao': precisao,
          'nivel_bateria': nivelBateria,
          'registrado_em': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      print('Erro ao enviar localização em tempo real: $e');
    }
  }
}
