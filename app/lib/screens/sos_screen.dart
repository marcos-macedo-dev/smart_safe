import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/audio_service.dart';
import '../services/camera_service.dart';
import '../services/sos_service.dart';
import '../services/api_service.dart';
import '../services/haptic_service.dart';
import 'sos_action_dialog.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  // Serviços
  final AudioService _audioService = AudioService();
  final HapticService _hapticService = HapticService();
  CameraService? _cameraService;
  late final SosService _sosService;
  final _storage = const FlutterSecureStorage();

  // Constantes
  static const String _selectedActionKey = 'selected_sos_action';

  // Estado da UI
  bool _recording = false;
  String? _currentAction;
  int? _activeSosId;
  bool _sendLocationRealtime = false;
  Timer? _locationTimer;
  bool _isInitializing = true;

  // Animações
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      _audioService.init();
      _sosService = SosService(ApiService());
      _initializeAnimations();
      await _loadSelectedAction();
      
      // Sincronização em background para não bloquear a UI
      _sosService.syncPendingSosRecords().catchError((error) {
        print('Erro na sincronização: $error');
      });
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Erro na inicialização da tela SOS: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    _cameraService?.dispose();
    _locationTimer?.cancel();
    _hapticService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ------------------- Lógica -------------------

  Future<void> _loadSelectedAction() async {
    final action = await _storage.read(key: _selectedActionKey);
    if (action != null) setState(() => _currentAction = action);
  }

  Future<void> _selectAction(String action) async {
    await _storage.write(key: _selectedActionKey, value: action);
    setState(() => _currentAction = action);
    await _hapticService.lightImpact();
  }

  Future<void> _onSosPressed() async {
    await _hapticService.lightImpact();
    if (_recording) {
      if (_currentAction == 'audio') {
        await _stopAudioRecording();
      } else if (_currentAction == 'video') {
        await _stopVideoRecording();
      }
      return;
    }
    if (!mounted) return;
    final action = _currentAction ?? await showSosActionDialog(context);
    if (action == null) return;
    if (action == 'location') {
      await _sendLocation();
      return;
    }
    if (!await _requestPermissions(action)) return;
    setState(() {
      _recording = true;
      _currentAction = action;
    });
    _hapticService.toggleHapticLoop(true);
    try {
      if (action == 'audio') {
        await _audioService.toggleRecording();
      } else if (action == 'video') {
        _cameraService ??= CameraService();
        await _cameraService!.initCamera();
        if (!_cameraService!.initialized) {
          _showMessage('Falha ao inicializar câmera');
          setState(() => _recording = false);
          _hapticService.toggleHapticLoop(false);
          return;
        }
        await _cameraService!.startRecording();
      }
    } catch (e) {
      _showMessage('Erro ao iniciar gravação: $e');
      setState(() => _recording = false);
      _hapticService.toggleHapticLoop(false);
    }
  }

  Future<bool> _requestPermissions(String action) async {
    final mic = await Permission.microphone.request();
    final cam = action == 'video'
        ? await Permission.camera.request()
        : PermissionStatus.granted;
    if (!mic.isGranted || !cam.isGranted) {
      _showMessage('Permissão de câmera/microfone negada');
      return false;
    }
    return true;
  }

  Future<void> _stopAudioRecording() async {
    _hapticService.toggleHapticLoop(false);
    try {
      final File? audioFile = await _audioService.toggleRecording();
      if (audioFile == null) {
        _showMessage('Falha ao gravar áudio.');
        setState(() => _recording = false);
        return;
      }
      final pos = await _obtainCurrentPosition();
      if (pos == null) {
        setState(() => _recording = false);
        return;
      }
      final sos = await _sosService.createSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
        caminhoAudio: audioFile.path,
      );
      if (sos == null) {
        _showMessage('Falha ao criar SOS.');
        return;
      }
      setState(() {
        _recording = false;
        _activeSosId = sos.id;
      });
      _showMessage('SOS de áudio enviado com sucesso!');
      if (_sendLocationRealtime) _toggleRealtimeLocation(true);
    } catch (e) {
      _showMessage('Erro ao processar áudio: $e');
      setState(() => _recording = false);
    }
  }

  Future<void> _stopVideoRecording() async {
    _hapticService.toggleHapticLoop(false);
    if (_cameraService == null || !_cameraService!.recording) return;
    try {
      final File? videoFile = await _cameraService!.stopRecording();
      _cameraService!.dispose();
      _cameraService = null;
      if (videoFile == null) {
        _showMessage('Falha ao salvar vídeo.');
        setState(() => _recording = false);
        return;
      }
      final pos = await _obtainCurrentPosition();
      if (pos == null) {
        setState(() => _recording = false);
        return;
      }
      final sos = await _sosService.createSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
        caminhoVideo: videoFile.path,
      );
      if (sos == null) {
        _showMessage('Falha ao criar SOS.');
        return;
      }
      setState(() {
        _recording = false;
        _activeSosId = sos.id;
      });
      _showMessage('SOS de vídeo enviado com sucesso!');
      if (_sendLocationRealtime) _toggleRealtimeLocation(true);
    } catch (e) {
      _showMessage('Erro ao processar vídeo: $e');
      setState(() => _recording = false);
    }
  }

  Future<void> _sendLocation() async {
    try {
      final pos = await _obtainCurrentPosition();
      if (pos == null) {
        return;
      }
      final sos = await _sosService.createSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (sos == null) {
        _showMessage('Falha ao enviar localização.');
        return;
      }
      setState(() => _activeSosId = sos.id);
      _showMessage('Localização enviada com sucesso!');
      if (_sendLocationRealtime) _toggleRealtimeLocation(true);
    } catch (e) {
      _showMessage('Erro ao capturar localização: $e');
    }
  }

  void _toggleRealtimeLocation(bool value) {
    setState(() => _sendLocationRealtime = value);
    _locationTimer?.cancel();
    if (value && _activeSosId != null) {
      () async {
        final initialPosition = await _obtainCurrentPosition();
        if (initialPosition == null) {
          if (mounted) {
            setState(() => _sendLocationRealtime = false);
          }
          return;
        }

        if (!mounted || !_sendLocationRealtime || _activeSosId == null) {
          return;
        }

        // Envia uma atualização inicial opcional com a posição atual
        final batteryLevel = await Battery().batteryLevel;
        await _sosService.sendRealtimeLocation(
          sosId: _activeSosId!,
          latitude: initialPosition.latitude,
          longitude: initialPosition.longitude,
          nivelBateria: batteryLevel.toDouble(),
        );

        _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
          if (_activeSosId == null || !_sendLocationRealtime) {
            timer.cancel();
            return;
          }
          final pos = await _obtainCurrentPosition(silent: true);
          if (pos == null) {
            timer.cancel();
            if (mounted) {
              setState(() => _sendLocationRealtime = false);
            }
            _showMessage('Localização em tempo real pausada. Verifique as permissões.');
            return;
          }
          final battery = await Battery().batteryLevel;
          await _sosService.sendRealtimeLocation(
            sosId: _activeSosId!,
            latitude: pos.latitude,
            longitude: pos.longitude,
            nivelBateria: battery.toDouble(),
          );
        });
      }();
    }
  }

  Future<Position?> _obtainCurrentPosition({bool silent = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!silent) {
        _showMessage('Ative o serviço de localização para enviar um SOS.');
        await Geolocator.openLocationSettings();
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!silent) {
          _showMessage('Precisamos da sua localização para enviar o SOS.');
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!silent) {
        _showMessage('Permita acesso à localização nas configurações do aplicativo.');
        await Geolocator.openAppSettings();
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (!silent) {
        _showMessage('Não foi possível obter sua localização. Tente novamente.');
      }
      return null;
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ------------------- UI Minimalista e Acessível -------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando...',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header compacto
              _buildHeader(theme),
              // Espaço flexível para empurrar o botão SOS para baixo
              const Spacer(flex: 3),
              // Botão SOS Principal (maior e mais baixo)
              _buildMainSosButton(theme),
              // Espaço menor
              const SizedBox(height: 40),
              // Indicador do tipo selecionado
              _buildCurrentActionIndicator(theme),
              // Espaço flexível
              const Spacer(flex: 2),
              // Controles na parte inferior (fácil acesso com polegar)
              _buildBottomControls(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        const Spacer(),
        if (_recording)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'GRAVANDO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Botão SOS Principal (agora maior: 250x250)
  Widget _buildMainSosButton(ThemeData theme) {
    return ScaleTransition(
      scale: _recording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.error.withAlpha(80),
              blurRadius: 32,
              spreadRadius: 8,
            ),
          ],
        ),
        child: SizedBox(
          width: 250, // Aumentado de 200 para 250
          height: 250, // Aumentado de 200 para 250
          child: ElevatedButton(
            onPressed: _onSosPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
            ),
            child: Icon(
              _recording ? Icons.stop_rounded : Icons.warning_rounded,
              size: _recording ? 72 : 88, // Aumentado de 60/72 para 72/88
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentActionIndicator(ThemeData theme) {
    final actionInfo = _getActionInfo(_currentAction);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(actionInfo['icon'], size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            actionInfo['label'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getActionInfo(String? action) {
    switch (action) {
      case 'audio':
        return {'icon': Icons.mic_rounded, 'label': 'Áudio'};
      case 'video':
        return {'icon': Icons.videocam_rounded, 'label': 'Vídeo'};
      case 'location':
        return {'icon': Icons.location_on_rounded, 'label': 'Localização'};
      default:
        return {'icon': Icons.help_outline_rounded, 'label': 'Escolher tipo'};
    }
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Column(
      children: [
        // Seletor de tipo de SOS
        Row(
          children: [
            _buildQuickActionButton('audio', Icons.mic_rounded, theme),
            const SizedBox(width: 16),
            _buildQuickActionButton('video', Icons.videocam_rounded, theme),
            const SizedBox(width: 16),
            _buildQuickActionButton(
              'location',
              Icons.location_on_rounded,
              theme,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Toggle de localização em tempo real
        Row(
          children: [
            Icon(
              Icons.my_location_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Localização contínua',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ),
            Switch.adaptive(
              value: _sendLocationRealtime,
              onChanged: _activeSosId != null ? _toggleRealtimeLocation : null,
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String action,
    IconData icon,
    ThemeData theme,
  ) {
    final isSelected = _currentAction == action;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectAction(action),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.white : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
