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
    if (_controller == null || !initialized || !_recording) return null;

    final XFile video = await _controller!.stopVideoRecording();
    _recording = false;

    final List<Directory>? dirs = await getExternalStorageDirectories(
      type: StorageDirectory.movies,
    );
    if (dirs == null || dirs.isEmpty) return null;

    final Directory extDir = dirs.first;
    final String filePath =
        '${extDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final bytes = await video.readAsBytes();
    await File(filePath).writeAsBytes(bytes);
    log('Video saved to: $filePath');
    return File(filePath);
  }

  void dispose() {
    log('Disposing camera...');
    _controller?.dispose();
    _controller = null;
  }

  }
