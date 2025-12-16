import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/local_database.dart';
import 'api_service.dart';
import '../models/sos_record.dart';
import 'sos_service.dart'; // To use createSos for syncing

import 'dart:async';
import 'dart:io'; // Import for File
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/local_database.dart';
import 'api_service.dart';
import '../models/sos_record.dart';
import 'sos_service.dart'; // To use createSos for syncing

class SyncService {
  final LocalDatabase _localDatabase = LocalDatabase();
  final ApiService _apiService;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late SosService _sosService; // Will be initialized later

  SyncService(this._apiService) {
    _sosService = SosService(_apiService); // Initialize SosService here
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _syncUnsyncedSosRecords();
      }
    });
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }

  Future<String?> _uploadMediaAndGetPath(String? localPath) async {
    if (localPath == null ||
        localPath.isEmpty ||
        localPath.startsWith('http')) {
      return localPath; // Already uploaded or no media
    }

    final file = File(localPath);
    if (!await file.exists()) {
      print('Local media file not found: $localPath');
      return null; // File not found, cannot upload
    }

    try {
      final uploadedMedia = await ApiService.uploadFile(file);
      if (uploadedMedia != null && uploadedMedia.caminho.isNotEmpty) {
        await file.delete(); // Delete local file after successful upload
        return uploadedMedia.caminho; // Return GCS URL
      }
      print('Failed to upload media file: $localPath');
      return null;
    } catch (e) {
      print('Error uploading media file $localPath: $e');
      return null;
    }
  }

  Future<void> _syncUnsyncedSosRecords() async {
    print('Attempting to sync unsynced SOS records...');
    final unsyncedRecords = await _localDatabase.getUnsyncedSosRecords();

    // Processar em lotes de 3 para otimização
    for (int i = 0; i < unsyncedRecords.length; i += 3) {
      final batch = unsyncedRecords.skip(i).take(3).toList();

      await Future.wait(
        batch.map((record) => _syncSingleRecord(record)),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Timeout no batch de sincronização');
          return [];
        },
      );
    }

    // Deletar registros sincronizados
    await _localDatabase.deleteSyncedSosRecords();
    print('Sync process completed.');
  }

  Future<void> _syncSingleRecord(dynamic record) async {
    try {
      String? audioCloudPath = record.caminho_audio;
      String? videoCloudPath = record.caminho_video;

      // Upload de áudio e vídeo em paralelo se ambos existirem
      final uploadFutures = <Future<String?>>[];

      if (record.caminho_audio != null &&
          !record.caminho_audio!.startsWith('http')) {
        uploadFutures.add(_uploadMediaAndGetPath(record.caminho_audio));
      }

      if (record.caminho_video != null &&
          !record.caminho_video!.startsWith('http')) {
        uploadFutures.add(_uploadMediaAndGetPath(record.caminho_video));
      }

      if (uploadFutures.isNotEmpty) {
        final results = await Future.wait(uploadFutures).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            print('Timeout no upload de mídias do SOS ${record.id}');
            return List.filled(uploadFutures.length, null);
          },
        );

        int resultIndex = 0;
        if (record.caminho_audio != null &&
            !record.caminho_audio!.startsWith('http')) {
          audioCloudPath = results[resultIndex];
          if (audioCloudPath == null) {
            print('Skipping SOS ${record.id} due to audio upload failure.');
            return;
          }
          resultIndex++;
        }

        if (record.caminho_video != null &&
            !record.caminho_video!.startsWith('http')) {
          videoCloudPath = results[resultIndex];
          if (videoCloudPath == null) {
            print('Skipping SOS ${record.id} due to video upload failure.');
            return;
          }
        }
      }

      // Preparar dados para API
      final data = {
        'usuario_id': record.usuario_id,
        'latitude': record.latitude,
        'longitude': record.longitude,
        'status': record.status.toString().split('.').last,
        if (audioCloudPath != null) 'caminho_audio': audioCloudPath,
        if (videoCloudPath != null) 'caminho_video': videoCloudPath,
        'createdAt': record.createdAt.toIso8601String(),
        'updatedAt': record.updatedAt.toIso8601String(),
        if (record.encerrado_em != null)
          'encerrado_em': record.encerrado_em!.toIso8601String(),
      };

      // Enviar para API com timeout
      final response = await _apiService
          .post('/sos', data: data)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Timeout ao enviar SOS ${record.id} para API');
              throw TimeoutException('API timeout');
            },
          );

      if (response.statusCode == 201) {
        await _localDatabase.markSosRecordAsSynced(record.id);
        print('SOS record ${record.id} synced successfully.');
      } else {
        print('Failed to sync SOS record ${record.id}: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing SOS record ${record.id}: $e');
    }
  }

  // Call this method when the app starts to sync any pending records
  Future<void> startInitialSync() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _syncUnsyncedSosRecords();
    }
  }
}
