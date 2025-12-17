import 'dart:io';
import 'dart:async';
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

    // Verificar conectividade ANTES de decidir o fluxo
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      // TEM INTERNET: Enviar direto para API (sem adicionar à fila de sincronização)
      print('SosService: Online - enviando SOS direto para API');
      final onlineSos = await _sendSosDirectlyToApi(
        usuarioId,
        latitude,
        longitude,
        caminhoAudio,
        caminhoVideo,
      );

      if (onlineSos != null) {
        // Sucesso online - salvar cópia local já marcada como sincronizada
        await _localDatabase.insertSosRecord(onlineSos);
        await _localDatabase.markSosRecordAsSynced(onlineSos.id);
        return onlineSos;
      }

      // Falhou mesmo com internet: faz fallback para fluxo offline para não perder o SOS
      print('SosService: Falha ao enviar online, caindo para fila offline.');
    }

    // SEM INTERNET OU FALHA ONLINE: Salvar localmente e adicionar à fila
    print(
      'SosService: Offline - salvando SOS localmente para sincronização posterior',
    );
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

    // Adicionar à fila de sincronização (SOMENTE para SOSs offline)
    await _addToAdvancedSync(localSosRecord);

    return localSosRecord;
  }

  // Método para enviar SOS direto para API (quando online)
  Future<SosRecord?> _sendSosDirectlyToApi(
    int usuarioId,
    double latitude,
    double longitude,
    String? caminhoAudio,
    String? caminhoVideo,
  ) async {
    try {
      String? finalCaminhoAudio = caminhoAudio;
      String? finalCaminhoVideo = caminhoVideo;

      // Upload de mídia se necessário
      if (caminhoAudio != null && !caminhoAudio.startsWith('http')) {
        try {
          final uploadedMedia = await ApiService.uploadFile(File(caminhoAudio));
          if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
            finalCaminhoAudio = uploadedMedia.caminho;
            await File(caminhoAudio).delete();
          } else {
            print('SosService: Upload de áudio falhou, seguindo sem áudio');
            finalCaminhoAudio = null; // Evitar enviar caminho local
          }
        } catch (e) {
          print('SosService: Erro ao fazer upload de áudio: $e');
          finalCaminhoAudio = null; // Prosseguir sem mídia para não abortar
        }
      }

      if (caminhoVideo != null && !caminhoVideo.startsWith('http')) {
        try {
          print('SosService: Iniciando upload de vídeo: $caminhoVideo');
          final uploadedMedia = await ApiService.uploadFile(File(caminhoVideo));
          if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
            print('SosService: Upload de vídeo finalizado. Caminho remoto: ${uploadedMedia.caminho}');
            finalCaminhoVideo = uploadedMedia.caminho;
            await File(caminhoVideo).delete();
          } else {
            print('SosService: Upload de vídeo falhou, seguindo sem vídeo');
            finalCaminhoVideo = null;
          }
        } catch (e) {
          print('SosService: Erro ao fazer upload de vídeo: $e');
          finalCaminhoVideo = null;
        }
      }

      // Preparar dados para envio
      final Map<String, dynamic> data = {
        'usuario_id': usuarioId,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'pendente',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (finalCaminhoAudio != null) data['caminho_audio'] = finalCaminhoAudio;
      if (finalCaminhoVideo != null) data['caminho_video'] = finalCaminhoVideo;

      // Enviar para API
      final response = await _apiService.post('/sos', data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('SosService: SOS enviado com sucesso para API');
        return SosRecord.fromJson(response.data);
      }

      print('SosService: Falha ao enviar SOS - Status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('SosService: Erro ao enviar SOS direto para API: $e');
      return null;
    }
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
      print('SosService: Sincronização já em andamento, pulando.');
      return;
    }
    _isSyncing = true;

    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        print('SosService: Sem conexão, pulando sincronização.');
        return;
      }

      print('SosService: Tentando sincronizar SOSs pendentes...');
      final unsyncedRecords = await _localDatabase.getUnsyncedSosRecords();

      // Processar em lotes de 3 para evitar sobrecarga
      for (int i = 0; i < unsyncedRecords.length; i += 3) {
        final batch = unsyncedRecords.skip(i).take(3).toList();

        await Future.wait(
          batch.map((record) => _syncSingleSos(record)),
        ).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            print('SosService: Timeout no batch de SOSs');
            return [];
          },
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncSingleSos(dynamic record) async {
    try {
      final Map<String, dynamic> data = {
        'usuario_id': record.usuario_id,
        'latitude': record.latitude,
        'longitude': record.longitude,
        'status': record.status.toString().split('.').last,
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

      final response = await _apiService
          .post('/sos', data: data)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('SosService: Timeout ao sincronizar SOS ${record.id}');
              throw TimeoutException('Timeout na sincronização');
            },
          );

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
