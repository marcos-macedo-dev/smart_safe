import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

/// Um serviço para gerenciar o feedback tátil (vibração) e auditivo.
///
/// Abstrai a implementação do pacote `haptic_feedback` e facilita
/// o uso de feedbacks táteis simples e em loop. Também inclui sons de confirmação.
class HapticService {
  Timer? _hapticTimer;
  AudioPlayer? _audioPlayer;

  /// Aciona um feedback tátil único e leve.
  ///
  /// Ideal para confirmar ações do usuário, como toques em botões.
  Future<void> lightImpact() async {
    try {
      if (await Haptics.canVibrate()) {
        await Haptics.vibrate(HapticsType.light);
      }
    } catch (e) {
      debugPrint('Haptic feedback (lightImpact) não disponível: $e');
    }
  }

  /// Controla o loop de feedback tátil.
  ///
  /// Quando [active] é `true`, inicia um loop de vibrações que alternam
  /// entre forte e leve, útil para indicar um estado contínuo (ex: gravação).
  /// Quando [active] é `false`, para o loop.
  void toggleHapticLoop(bool active) {
    if (active) {
      _startHapticLoop();
    } else {
      _stopHapticLoop();
    }
  }

  void _startHapticLoop() {
    _hapticTimer?.cancel(); // Garante que não haja timers duplicados
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) async {
      try {
        if (await Haptics.canVibrate()) {
          // Impulso forte seguido de um fraco para criar um padrão distinto
          await Haptics.vibrate(HapticsType.heavy);
          await Future.delayed(const Duration(milliseconds: 50));
          await Haptics.vibrate(HapticsType.light);
        }
      } catch (e) {
        debugPrint('Haptic feedback (loop) não disponível: $e');
        _stopHapticLoop(); // Para o loop se ocorrer um erro
      }
    });
  }

  void _stopHapticLoop() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  /// Libera os recursos, como o timer.
  ///
  /// Deve ser chamado no `dispose` do widget que utiliza este serviço.
  void dispose() {
    _stopHapticLoop();
    _audioPlayer?.dispose();
  }

  /// Vibração de emergência para situações críticas.
  ///
  /// Usa vibração pesada em loop rápido para alertar o usuário
  /// durante situações de emergência extrema.
  Future<void> emergencyVibration() async {
    try {
      final canVibrate = await Haptics.canVibrate();
      if (!canVibrate) return;

      // Cancela qualquer loop existente antes de iniciar o de emergência
      _stopHapticLoop();

      // Vibração pesada em loop por 5 segundos
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (timer.tick >= 25) {
          // 5 segundos
          timer.cancel();
          _hapticTimer = null;
          return;
        }
        Haptics.vibrate(HapticsType.heavy);
      });
    } catch (e) {
      debugPrint('Erro na vibração de emergência: $e');
    }
  }

  /// Reproduz um som de confirmação de emergência.
  ///
  /// Toca um beep curto para confirmar que o SOS foi ativado.
  Future<void> playEmergencySound() async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.setAsset('assets/sounds/emergency_beep.mp3');
      await _audioPlayer!.play();
    } catch (e) {
      debugPrint('Erro ao reproduzir som de emergência: $e');
    }
  }

  /// Feedback completo de emergência: vibração + som.
  ///
  /// Combina vibração pesada com som de confirmação para máxima atenção.
  Future<void> emergencyFeedback() async {
    await Future.wait([emergencyVibration(), playEmergencySound()]);
  }
}
