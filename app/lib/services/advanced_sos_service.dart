import 'dart:io';
import '../models/sos_record.dart';
import 'api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/advanced_local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'advanced_sync_service.dart';

class AdvancedSosService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AdvancedLocalDatabase _localDatabase = AdvancedLocalDatabase();
  final AdvancedSyncService _syncService = AdvancedSyncService();
  bool _isSyncing = false;

  AdvancedSosService(this._apiService);

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
        // Se a busca online for bem-sucedida, salva no banco local e retorna os dados do servidor
        final serverRecords = (response.data as List)
            .map((json) => SosRecord.fromJson(json))
            .toList();
        
        // Atualizar banco de dados local com dados do servidor
        for (final record in serverRecords) {
          await _localDatabase.updateSosRecord(record);
        }
        
        return serverRecords;
      }
      // Se o status code não for 200, ou dados inválidos, tenta buscar localmente
      print('AdvancedSosService: Falha ao buscar SOSs online (status: ${response.statusCode}), tentando buscar localmente.');
      return await _localDatabase.getAllSosRecords();
    } catch (e) {
      // Se houver um erro de conexão ou qualquer outra exceção, busca localmente
      print('AdvancedSosService: Erro ao buscar SOSs online: $e, tentando buscar localmente.');
      return await _localDatabase.getAllSosRecords();
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

    // Criar registro SOS local
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

    // Verificar conectividade
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    if (isOnline) {
      // Tentar criar no servidor
      String? finalCaminhoAudio = caminhoAudio;
      String? finalCaminhoVideo = caminhoVideo;

      // Upload de mídia se necessário
      if (caminhoAudio != null && !caminhoAudio.startsWith('http')) {
        try {
          final uploadedMedia = await ApiService.uploadFile(File(caminhoAudio));
          if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
            finalCaminhoAudio = uploadedMedia.caminho; // GCS URL
            await File(caminhoAudio).delete(); // Delete local file after upload
          }
        } catch (e) {
          print('Erro ao enviar áudio para GCS: $e');
        }
      }

      if (caminhoVideo != null && !caminhoVideo.startsWith('http')) {
        try {
          final uploadedMedia = await ApiService.uploadFile(File(caminhoVideo));
          if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
            finalCaminhoVideo = uploadedMedia.caminho; // GCS URL
            await File(caminhoVideo).delete(); // Delete local file after upload
          }
        } catch (e) {
          print('Erro ao enviar vídeo para GCS: $e');
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
          final serverSos = SosRecord.fromJson(response.data);
          // Salvar no banco local
          await _localDatabase.insertSosRecord(serverSos);
          return serverSos;
        }
      } catch (e) {
        print('Erro ao criar SOS online: $e');
      }
    }

    // Se offline ou falha na criação online, salvar localmente e adicionar à fila de sincronização
    final localId = await _localDatabase.insertSosRecord(localSosRecord);
    final sosToSync = localSosRecord.copyWith(id: localId);
    
    // Adicionar à fila de sincronização
    await _syncService.queueSosSync(sosToSync, 'create');
    
    return sosToSync;
  }

  /// Atualiza um SOS existente
  Future<SosRecord?> updateSos(SosRecord sos) async {
    // Atualizar no banco local primeiro
    await _localDatabase.updateSosRecord(sos);
    
    // Verificar conectividade
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    if (isOnline) {
      try {
        final data = sos.toJson();
        final response = await _apiService.put('/sos/${sos.id}', data: data);
        if (response.statusCode == 200) {
          final updatedSos = SosRecord.fromJson(response.data);
          // Marcar como sincronizado
          await _localDatabase.markSosRecordAsSynced(sos.id);
          return updatedSos;
        }
      } catch (e) {
        print('Erro ao atualizar SOS online: $e');
      }
    }

    // Se offline ou falha na atualização online, adicionar à fila de sincronização
    await _syncService.queueSosSync(sos, 'update');
    return sos;
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
      // Em modo offline, podemos salvar a localização localmente para enviar depois
    }
  }
}