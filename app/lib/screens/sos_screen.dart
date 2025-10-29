import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final Battery _battery = Battery();

  // Constantes
  static const String _selectedActionKey = 'selected_sos_action';

  // Estado da UI
  bool _recording = false;
  String? _currentAction;
  int? _activeSosId;
  bool _sendLocationRealtime = false;
  Timer? _locationTimer;
  bool _isInitializing = true;
  bool _isOnline = true;

  // Detecção de movimento de emergência
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _lastAcceleration = 0.0;
  bool _emergencyModeActive = false;
  Timer? _emergencyModeTimer;

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

      // Inicializar monitoramento de conectividade
      await _initializeConnectivity();

      // Sincronização em background para não bloquear a UI
      _sosService.syncPendingSosRecords().catchError((error) {
        print('Erro na sincronização: $error');
      });

      // Inicializar detecção de movimento de emergência
      _initializeEmergencyDetection();

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
    _pulseController.dispose();
    _accelerometerSubscription?.cancel();
    _emergencyModeTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    // Verificar status inicial de conectividade
    final connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline =
            connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi);
      });
    }

    // Monitorar mudanças de conectividade
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOnline =
              results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi);
        });
      }
    });
  }

  // ------------------- Detecção de Emergência -------------------

  void _initializeEmergencyDetection() {
    // Monitora o acelerômetro para detectar movimento intenso
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      final acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Detecta movimento muito intenso (queda, corrida, etc.)
      if (acceleration > 25.0 && !_emergencyModeActive && !_recording) {
        // ~2.5g
        _activateEmergencyMode();
      }

      _lastAcceleration = acceleration;
    });
  }

  void _activateEmergencyMode() {
    if (_emergencyModeActive) return;

    setState(() => _emergencyModeActive = true);

    // Feedback de emergência imediato
    _hapticService.emergencyFeedback();

    // Timer para desativar o modo de emergência após 30 segundos
    _emergencyModeTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() => _emergencyModeActive = false);
      }
    });

    // Mostra diálogo de confirmação de emergência
    _showEmergencyDialog();
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 MODO DE EMERGÊNCIA ATIVADO'),
        content: const Text(
          'Detectamos movimento intenso. Deseja ativar o SOS automaticamente?\n\n'
          'Toque em "SIM" para ativar imediatamente ou aguarde 10 segundos para confirmação automática.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _emergencyModeActive = false);
              _emergencyModeTimer?.cancel();
            },
            child: const Text('NÃO'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _triggerEmergencySos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('SIM - ATIVAR SOS'),
          ),
        ],
      ),
    );

    // Confirmação automática após 10 segundos
    Timer(const Duration(seconds: 10), () {
      if (mounted && _emergencyModeActive) {
        Navigator.of(context).pop();
        _triggerEmergencySos();
      }
    });
  }

  void _triggerEmergencySos() async {
    setState(() => _emergencyModeActive = false);
    _emergencyModeTimer?.cancel();

    // Ativa SOS automaticamente com áudio
    await _onSosPressed();
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
    // Feedback de emergência para máxima atenção
    await _hapticService.emergencyFeedback();

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
    if (!_audioService.recording) {
      setState(() => _recording = false);
      return;
    }
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
      final message = _isOnline
          ? 'SOS de áudio enviado com sucesso!'
          : 'SOS de áudio salvo localmente (será sincronizado quando online)';
      _showMessage(message);
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
      final message = _isOnline
          ? 'SOS de vídeo enviado com sucesso!'
          : 'SOS de vídeo salvo localmente (será sincronizado quando online)';
      _showMessage(message);
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
      final message = _isOnline
          ? 'Localização enviada com sucesso!'
          : 'Localização salva localmente (será sincronizada quando online)';
      _showMessage(message);
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
        final batteryLevel = await _battery.batteryLevel;
        await _sosService.sendRealtimeLocation(
          sosId: _activeSosId!,
          latitude: initialPosition.latitude,
          longitude: initialPosition.longitude,
          nivelBateria: batteryLevel.toDouble(),
        );

        _locationTimer = Timer.periodic(const Duration(seconds: 5), (
          timer,
        ) async {
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
            _showMessage(
              'Localização em tempo real pausada. Verifique as permissões.',
            );
            return;
          }
          final battery = await _battery.batteryLevel;
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
        _showMessage(
          'Permita acesso à localização nas configurações do aplicativo.',
        );
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
        _showMessage(
          'Não foi possível obter sua localização. Tente novamente.',
        );
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header compacto
              _buildHeader(theme),
              // Espaço flexível para empurrar o botão SOS para baixo
              const Spacer(flex: 2),
              // Botão SOS Principal (menor e mais harmonioso)
              _buildMainSosButton(theme),
              // Espaço menor
              const SizedBox(height: 32),
              // Indicador do tipo selecionado
              _buildCurrentActionIndicator(theme),
              // Espaço flexível
              const Spacer(flex: 1),
              // Controles na parte inferior (fácil acesso com polegar)
              _buildBottomControls(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          const Spacer(),
          // Indicador de conectividade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isOnline
                  ? theme.colorScheme.primary.withAlpha(200)
                  : Colors.orange.withAlpha(200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_recording) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GRAVANDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Botão SOS Principal (agora menor: 220x220)
  Widget _buildMainSosButton(ThemeData theme) {
    return ScaleTransition(
      scale: _recording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.error.withAlpha(40),
              blurRadius: 16,
              spreadRadius: 2,
            ),
            // Indicador de emergência: borda pulsante vermelha
            if (_emergencyModeActive)
              BoxShadow(
                color: Colors.red.withAlpha(120),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220, // Reduzido para 220 para visual mais slim
              height: 220, // Reduzido para 220 para visual mais slim
              child: ElevatedButton(
                onPressed: _onSosPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emergencyModeActive
                      ? Colors.red.shade900
                      : theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  _recording ? Icons.stop_rounded : Icons.warning_rounded,
                  size: _recording
                      ? 72
                      : 90, // Reduzido para 72/90 para proporção harmoniosa
                ),
              ),
            ),
            // Texto de emergência quando ativo
            if (_emergencyModeActive)
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withAlpha(240),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'EMERGÊNCIA DETECTADA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentActionIndicator(ThemeData theme) {
    final actionInfo = _getActionInfo(_currentAction);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(actionInfo['icon'], size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            actionInfo['label'],
            style: TextStyle(
              fontSize: 13,
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
            const SizedBox(width: 12),
            _buildQuickActionButton('video', Icons.videocam_rounded, theme),
            const SizedBox(width: 12),
            _buildQuickActionButton(
              'location',
              Icons.location_on_rounded,
              theme,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Toggle de localização em tempo real
        Row(
          children: [
            Icon(
              Icons.my_location_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Localização contínua',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withAlpha(140),
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
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? Colors.white : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
