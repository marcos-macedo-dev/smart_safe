import 'package:flutter/material.dart';

enum AppMessageType { success, error, warning, info }

class AppMessage {
  AppMessage._();

  static const Color _successBackground = Color(0xFF2E7D32);
  static const Color _errorBackground = Color(0xFFC62828);
  static const Color _warningBackground = Color(0xFFFBC02D);

  static void show(
    BuildContext context, {
    required String message,
    AppMessageType type = AppMessageType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool clearQueue = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = _backgroundColor(type, colorScheme);
    final foregroundColor = _foregroundColor(type, colorScheme);

    final SnackBar snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: foregroundColor,
            )
          : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: duration,
    );

    final messenger = ScaffoldMessenger.of(context);
    if (clearQueue) {
      messenger.clearSnackBars();
    }
    messenger.showSnackBar(snackBar);
  }

  static Color _backgroundColor(
    AppMessageType type,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case AppMessageType.success:
        return _successBackground;
      case AppMessageType.error:
        return _errorBackground;
      case AppMessageType.warning:
        return _warningBackground;
      case AppMessageType.info:
      default:
        final base = colorScheme.surfaceContainerHighest;
        return base.withAlpha(242); // ~95% opacity
    }
  }

  static Color _foregroundColor(
    AppMessageType type,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case AppMessageType.success:
        return Colors.white;
      case AppMessageType.error:
        return Colors.white;
      case AppMessageType.warning:
        return Colors.black87;
      case AppMessageType.info:
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  static void success(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool clearQueue = true,
  }) {
    show(
      context,
      message: message,
      type: AppMessageType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      clearQueue: clearQueue,
    );
  }

  static void error(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool clearQueue = true,
  }) {
    show(
      context,
      message: message,
      type: AppMessageType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      clearQueue: clearQueue,
    );
  }

  static void warning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool clearQueue = true,
  }) {
    show(
      context,
      message: message,
      type: AppMessageType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      clearQueue: clearQueue,
    );
  }

  static void info(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool clearQueue = true,
  }) {
    show(
      context,
      message: message,
      type: AppMessageType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      clearQueue: clearQueue,
    );
  }
}
