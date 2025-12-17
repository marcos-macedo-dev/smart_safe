import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:app/screens/emergency_contacts_screen.dart';
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
import '../utils/theme_helper.dart';
import 'sos_action_dialog.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  // Serviços
  final AudioService _audioService = AudioService();
  CameraService? _cameraService;
  late final SosService _sosService;
  final _storage = const FlutterSecureStorage();
  final Battery _battery = Battery();

  // Constantes
  static const String _selectedActionKey = 'selected_sos_action';
  // Paleta violeta institucional
  static const Color _violetaEscura = Color(0xFF311756);

  // Tema dinâmico para usar em múltiplos métodos
  Color get cardColor => Theme.of(context).colorScheme.surface;
  Color get textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get accent {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF7C5CC3) : _violetaEscura;
  }

  Color get shadow {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Colors.black.withOpacity(isDark ? 0.35 : 0.08);
  }

  // Estado da UI
  bool _recording = false;
  String? _currentAction;
  int? _activeSosId;
  bool _sendLocationRealtime = false;
  Timer? _locationTimer;
  bool _isInitializing = true;
  bool _isOnline = true;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Detecção de movimento de emergência
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
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
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _recordingSeconds++);
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingSeconds = 0;
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
    });
  }

  void _activateEmergencyMode() {
    if (_emergencyModeActive) return;

    setState(() => _emergencyModeActive = true);

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
  }

  Future<void> _onSosPressed() async {
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
    if (action == 'audio' || action == 'video') {
      _startRecordingTimer();
    }
    try {
      if (action == 'audio') {
        await _audioService.toggleRecording();
      } else if (action == 'video') {
        _cameraService ??= CameraService();
        await _cameraService!.initCamera();
        if (!_cameraService!.initialized) {
          _showMessage('Falha ao inicializar câmera');
          setState(() => _recording = false);
          return;
        }
        await _cameraService!.startRecording();
      }
    } catch (e) {
      _showMessage('Erro ao iniciar gravação: $e');
      setState(() => _recording = false);
      _stopRecordingTimer();
    }
  }

  Future<bool> _requestPermissions(String action) async {
    final mic = await Permission.microphone.request();
    final cam = action == 'video'
        ? await Permission.camera.request()
        : PermissionStatus.granted;
    if (!mic.isGranted || !cam.isGranted) {
      _showMessage('Permissão de câmera/microfone negada');
      // Facilita correção imediata em caso extremo
      openAppSettings();
      return false;
    }
    return true;
  }

  Future<void> _stopAudioRecording() async {
    if (!_audioService.recording) {
      setState(() => _recording = false);
      _stopRecordingTimer();
      return;
    }
    try {
      final File? audioFile = await _audioService.toggleRecording();
      if (audioFile == null) {
        _showMessage('Falha ao gravar áudio.');
        setState(() => _recording = false);
        _stopRecordingTimer();
        return;
      }
      final pos = await _obtainCurrentPosition();
      if (pos == null) {
        setState(() => _recording = false);
        _stopRecordingTimer();
        return;
      }
      final sos = await _sosService.createSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
        caminhoAudio: audioFile.path,
      );
      if (sos == null) {
        _showMessage('Falha ao criar SOS.');
        _stopRecordingTimer();
        return;
      }
      setState(() {
        _recording = false;
        _activeSosId = sos.id;
      });
      _stopRecordingTimer();
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
    if (_cameraService == null || !_cameraService!.recording) return;
    try {
      final File? videoFile = await _cameraService!.stopRecording();
      _cameraService!.dispose();
      _cameraService = null;
      if (videoFile == null) {
        _showMessage('Falha ao salvar vídeo.');
        setState(() => _recording = false);
        _stopRecordingTimer();
        return;
      }
      final pos = await _obtainCurrentPosition();
      if (pos == null) {
        setState(() => _recording = false);
        _stopRecordingTimer();
        return;
      }
      final sos = await _sosService.createSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
        caminhoVideo: videoFile.path,
      );
      if (sos == null) {
        _showMessage('Falha ao criar SOS.');
        _stopRecordingTimer();
        return;
      }
      setState(() {
        _recording = false;
        _activeSosId = sos.id;
      });
      _stopRecordingTimer();
      final message = _isOnline
          ? 'SOS de vídeo enviado com sucesso!'
          : 'SOS de vídeo salvo localmente (será sincronizado quando online)';
      _showMessage(message);
      if (_sendLocationRealtime) _toggleRealtimeLocation(true);
    } catch (e) {
      _showMessage('Erro ao processar vídeo: $e');
      setState(() => _recording = false);
      _stopRecordingTimer();
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
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = this.cardColor;
    final Color textPrimary = this.textPrimary;
    final Color textMuted = this.textMuted;
    final Color accent = this.accent;
    final Color shadow = this.shadow;

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: cardColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textScaler.scale(15),
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Ajuste dinâmico do tamanho do botão baseado na altura disponível
              final double availableHeight = constraints.maxHeight;
              final double buttonSize = (availableHeight * 0.30).clamp(160.0, 220.0);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com badges flutuantes
                  _buildHeader(theme, colorScheme, textScaler),
                  if (_currentAction != null) ...[
                    const SizedBox(height: 8),
                    _buildCurrentActionIndicator(theme, colorScheme, textScaler),
                  ],
                  const SizedBox(height: 12),
                  // Botão SOS Principal - Card flutuante (prioridade máxima)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: _buildMainSosButton(theme, colorScheme, buttonSize),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Card de seleção de tipo (compacto)
                  _buildActionTypeCard(theme, colorScheme, textScaler),
                  const SizedBox(height: 10),
                  // Card de localização (compacto)
                  _buildLocationCard(theme, colorScheme, textScaler),
                  const SizedBox(height: 4),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    if (_recording) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Gravando · ${_formatDuration(_recordingSeconds)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade700,
                    fontSize: textScaler.scale(12),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // Botão SOS Principal estilo Uber
  Widget _buildMainSosButton(ThemeData theme, ColorScheme colorScheme, double size) {
    return ScaleTransition(
      scale: _recording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _emergencyModeActive
                  ? Colors.red.shade600.withOpacity(0.4)
                  : accent.withOpacity(0.25),
              blurRadius: 32,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: _emergencyModeActive ? Colors.red.shade700 : accent,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onSosPressed,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _recording
                              ? Icons.stop_rounded
                              : Icons.warning_rounded,
                          size: size * 0.35, // Proporcional ao tamanho
                          color: Colors.white,
                        ),
                        SizedBox(height: size * 0.07),
                        Text(
                          _recording
                              ? 'PARAR'
                              : (_isOnline ? 'SOS' : 'SOS OFFLINE'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.11, // Proporcional
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        if (!_isOnline)
                          Padding(
                            padding: EdgeInsets.only(top: size * 0.03),
                            child: Text(
                              'Salva e envia quando\nvoltar a ficar online',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: size * 0.05,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Texto de emergência quando ativo
            if (_emergencyModeActive)
              Positioned(
                bottom: size * 0.06,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withAlpha(240),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'EMERGÊNCIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentActionIndicator(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    final actionInfo = _getActionInfo(_currentAction);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(actionInfo['icon'], size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            actionInfo['label'],
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: textScaler.scale(14),
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.2,
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

  // Card de seleção de tipo - Estilo Uber
  Widget _buildActionTypeCard(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de alerta',
            style: TextStyle(
              fontSize: textScaler.scale(15),
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickActionButton(
                'audio',
                Icons.mic_rounded,
                theme,
                colorScheme,
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                'video',
                Icons.videocam_rounded,
                theme,
                colorScheme,
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                'location',
                Icons.location_on_rounded,
                theme,
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card de localização - Estilo Uber
  Widget _buildLocationCard(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.my_location_rounded, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localização contínua',
                  style: TextStyle(
                    fontSize: textScaler.scale(14),
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Compartilhar em tempo real',
                  style: TextStyle(
                    fontSize: textScaler.scale(11),
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: _sendLocationRealtime,
              onChanged: _activeSosId != null ? _toggleRealtimeLocation : null,
              activeColor: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Column(
      children: [
        // Label
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tipo de alerta',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: textScaler.scale(15),
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Seletor de tipo de SOS (estilo dos campos do login)
        Row(
          children: [
            _buildQuickActionButton(
              'audio',
              Icons.mic_rounded,
              theme,
              colorScheme,
            ),
            const SizedBox(width: 12),
            _buildQuickActionButton(
              'video',
              Icons.videocam_rounded,
              theme,
              colorScheme,
            ),
            const SizedBox(width: 12),
            _buildQuickActionButton(
              'location',
              Icons.location_on_rounded,
              theme,
              colorScheme,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Toggle de localização em tempo real
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.my_location_rounded, size: 20, color: textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Localização contínua',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: textScaler.scale(15),
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _sendLocationRealtime,
                onChanged: _activeSosId != null
                    ? _toggleRealtimeLocation
                    : null,
                activeColor: accent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String action,
    IconData icon,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = _currentAction == action;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectAction(action),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? accent : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accent : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: shadow.withOpacity(0.9),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.white : textPrimary.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
