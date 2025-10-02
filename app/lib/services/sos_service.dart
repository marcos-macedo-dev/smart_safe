import 'dart:io'; // Import dart:io
import '../models/sos_record.dart';
import 'api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/local_database.dart'; // Import LocalDatabase
import 'package:connectivity_plus/connectivity_plus.dart'; // Adicionar este import

class SosService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalDatabase _localDatabase = LocalDatabase(); // LocalDatabase instance
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
      print('SosService: Falha ao buscar SOSs online (status: ${response.statusCode}), tentando buscar localmente.');
      return await _localDatabase.getUnsyncedSosRecords(); // Retorna os não sincronizados, que são os locais
    } catch (e) {
      // Se houver um erro de conexão ou qualquer outra exceção, busca localmente
      print('SosService: Erro ao buscar SOSs online: $e, tentando buscar localmente.');
      return await _localDatabase.getUnsyncedSosRecords(); // Retorna os não sincronizados, que são os locais
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

    String? finalCaminhoAudio = caminhoAudio;
    String? finalCaminhoVideo = caminhoVideo;

    // Attempt to upload media if it's a local path (online scenario)
    if (caminhoAudio != null && !caminhoAudio.startsWith('http')) {
      try {
        final uploadedMedia = await ApiService.uploadFile(File(caminhoAudio));
        if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
          finalCaminhoAudio = uploadedMedia.caminho; // GCS URL
          await File(caminhoAudio).delete(); // Delete local file after upload
        } else {
          print('Falha ao enviar áudio para GCS, salvando SOS localmente.');
          // If media upload fails, save SOS locally with local media path
          return await _saveSosLocally(usuarioId, latitude, longitude, caminhoAudio, caminhoVideo);
        }
      } catch (e) {
        print('Erro ao enviar áudio para GCS: $e, salvando SOS localmente.');
        return await _saveSosLocally(usuarioId, latitude, longitude, caminhoAudio, caminhoVideo);
      }
    }

    if (caminhoVideo != null && !caminhoVideo.startsWith('http')) {
      try {
        final uploadedMedia = await ApiService.uploadFile(File(caminhoVideo));
        if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
          finalCaminhoVideo = uploadedMedia.caminho; // GCS URL
          await File(caminhoVideo).delete(); // Delete local file after upload
        } else {
          print('Falha ao enviar vídeo para GCS, salvando SOS localmente.');
          return await _saveSosLocally(usuarioId, latitude, longitude, caminhoAudio, caminhoVideo);
        }
      } catch (e) {
        print('Erro ao enviar vídeo para GCS: $e, salvando SOS localmente.');
        return await _saveSosLocally(usuarioId, latitude, longitude, caminhoAudio, caminhoVideo);
      }
    }

    final Map<String, dynamic> data = {
      'usuario_id': usuarioId,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'pendente',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (finalCaminhoAudio != null) {
      data['caminho_audio'] = finalCaminhoAudio;
    }
    if (finalCaminhoVideo != null) {
      data['caminho_video'] = finalCaminhoVideo;
    }

    try {
      final response = await _apiService.post('/sos', data: data);
      if (response.statusCode == 201) {
        return SosRecord.fromJson(response.data);
      }
      // If API call fails but no exception, fall through to local save
    } catch (e) {
      print('Erro ao criar SOS online: $e, salvando localmente.');
      // Fallback to local storage
    }

    // If API call failed or returned non-201, save original (local) SOS to local DB
    return await _saveSosLocally(usuarioId, latitude, longitude, caminhoAudio, caminhoVideo);
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
    if (_isSyncing) { // Se já estiver sincronizando, sai
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
            'status': record.status.toString().split('.').last, // Convert enum to string
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
            print('SosService: Falha ao sincronizar SOS ${record.id}. Status: ${response.statusCode}');
          }
        } catch (e) {
          print('SosService: Erro ao sincronizar SOS ${record.id}: $e');
        }
      }
    } finally {
      _isSyncing = false; // Garante que a flag seja resetada, mesmo em caso de erro
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

      print('updateSosMedia: Enviando para /sos/$sosId com dados: $data'); // LOG
      final response = await _apiService.put('/sos/$sosId', data: data);
      print('updateSosMedia: Resposta do backend: ${response.statusCode}'); // LOG
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
