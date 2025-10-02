import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // Import ApiService
import '../models/media.dart'; // Import Media model

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recording = false;
  String? _currentFilePath;

  bool get recording => _recording;

  Future<void> init() async {
    await _recorder.openRecorder();
  }

  Future<File?> toggleRecording() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) return null;

    if (_recording) {
      // Parar gravação e retornar o arquivo real
      await _recorder.stopRecorder();
      _recording = false;
      if (_currentFilePath == null) return null;
      final file = File(_currentFilePath!);
      _currentFilePath = null;
      return file;
    } else {
      // Iniciar gravação e armazenar path
      _currentFilePath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: _currentFilePath);
      _recording = true;
      return null;
    }
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}
