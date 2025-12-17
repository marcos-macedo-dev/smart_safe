import 'dart:io';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // Import ApiService
import '../models/media.dart'; // Import Media model

class CameraService {
  CameraController? _controller;
  bool _recording = false;

  CameraController? get controller => _controller;
  bool get initialized => _controller?.value.isInitialized ?? false;
  bool get recording => _recording;

  /// Inicializa a câmera apenas quando necessário
  Future<void> initCamera() async {
    if (_controller != null && initialized) return;

    log('Initializing camera...');
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('Nenhuma câmera disponível');

    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
  }

  /// Inicia a gravação
  Future<void> startRecording() async {
    if (_controller == null || !initialized) return;
    await _controller!.startVideoRecording();
    _recording = true;
  }

  /// Para a gravação e salva o arquivo no diretório Movies (público)
  Future<File?> stopRecording() async {
    if (_controller == null || !initialized || !_recording) {
      log('[CameraService] stopRecording: Controller não inicializado, não gravando ou já parou. Retornando null.');
      return null;
    }

    try {
      final XFile video = await _controller!.stopVideoRecording();
      _recording = false;
      log('[CameraService] stopRecording: Gravação parada. XFile criado: ${video.path}');

      final List<Directory>? dirs = await getExternalStorageDirectories(
        type: StorageDirectory.movies,
      );
      
      if (dirs == null || dirs.isEmpty) {
        log('[CameraService] stopRecording: Nenhum diretório de filmes externo encontrado. Retornando null.');
        return null;
      }

      final Directory extDir = dirs.first;
      final String filePath = '${extDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      log('[CameraService] stopRecording: Caminho de destino para salvar: $filePath');

      final bytes = await video.readAsBytes();
      log('[CameraService] stopRecording: Bytes do vídeo lidos. Tamanho: ${bytes.length} bytes.');
      
      final File newFile = File(filePath);
      await newFile.writeAsBytes(bytes);
      log('[CameraService] stopRecording: Vídeo salvo com sucesso em: $filePath');
      return newFile;
    } catch (e) {
      log('[CameraService] stopRecording: Erro ao parar gravação ou salvar arquivo: $e');
      _recording = false; // Garantir que o estado de gravação seja resetado
      return null;
    }
  }

  void dispose() {
    log('Disposing camera...');
    _controller?.dispose();
    _controller = null;
  }
}
