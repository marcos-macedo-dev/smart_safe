import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Um serviço para gerenciar o feedback tátil (vibração).
///
/// Abstrai a implementação do pacote `haptic_feedback` e facilita
/// o uso de feedbacks táteis simples e em loop.
class HapticService {
  Timer? _hapticTimer;

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
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
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
  }

  /// Libera os recursos, como o timer.
  ///
  /// Deve ser chamado no `dispose` do widget que utiliza este serviço.
  void dispose() {
    _stopHapticLoop();
  }
}
