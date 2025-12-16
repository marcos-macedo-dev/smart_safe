import 'package:flutter/material.dart';

/// Helper para cores que se adaptam ao tema (claro/escuro)
class ThemeHelper {
  /// Retorna a cor de fundo principal (cinza claro no light, escuro no dark)
  static Color getBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.grey.shade50
        : const Color(0xFF121212);
  }

  /// Retorna a cor de fundo dos cards (branco no light, cinza escuro no dark)
  static Color getCardColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.white
        : const Color(0xFF1E1E1E);
  }

  /// Retorna a cor do texto principal
  static Color getTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.black87
        : Colors.grey.shade200;
  }

  /// Retorna a cor do texto secundário
  static Color getSecondaryTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.black54
        : Colors.grey.shade400;
  }

  /// Retorna a cor de borda/divider
  static Color getBorderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.grey.shade300
        : Colors.grey.shade700;
  }

  /// Retorna a cor de fundo para inputs não selecionados
  static Color getInputBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? Colors.grey.shade100
        : const Color(0xFF2C2C2C);
  }

  /// Retorna a sombra apropriada para cards
  static List<BoxShadow> getCardShadow(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return [
      BoxShadow(
        color: brightness == Brightness.light
            ? Colors.black.withOpacity(0.08)
            : Colors.black.withOpacity(0.3),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
