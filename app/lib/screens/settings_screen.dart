import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'privacy_screen.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _violetaEscura = Color(0xFF311756);

  // Tema dinâmico
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

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: accent,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção: Aparência
              _buildSettingCard(
                theme: theme,
                colorScheme: colorScheme,
                textScaler: textScaler,
                icon: Icons.palette_rounded,
                title: "Tema do aplicativo",
                subtitle: "Escolha entre claro, escuro ou sistema",
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildThemeOption(
                            "Claro",
                            ThemeMode.light,
                            theme,
                            colorScheme,
                            textScaler,
                            themeProvider,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildThemeOption(
                            "Escuro",
                            ThemeMode.dark,
                            theme,
                            colorScheme,
                            textScaler,
                            themeProvider,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildThemeOption(
                            "Sistema",
                            ThemeMode.system,
                            theme,
                            colorScheme,
                            textScaler,
                            themeProvider,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Seção: Privacidade
              _buildSettingCard(
                theme: theme,
                colorScheme: colorScheme,
                textScaler: textScaler,
                icon: Icons.shield_rounded,
                title: "Privacidade e Dados",
                subtitle: "Gerencie permissões e privacidade",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),

              // Seção: Sobre
              _buildSettingCard(
                theme: theme,
                colorScheme: colorScheme,
                textScaler: textScaler,
                icon: Icons.info_rounded,
                title: "Sobre o Smart Safe",
                subtitle:
                    "Versão ${_packageInfo.version} (Build ${_packageInfo.buildNumber}) Beta",
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Sistema de emergência inteligente para sua segurança.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: textScaler.scale(14),
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para cartões de configuração (reutilizável)
  Widget _buildSettingCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required TextScaler textScaler,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? child,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: textScaler.scale(15),
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: textScaler.scale(13),
                            color: textMuted,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              if (child != null) child,
            ],
          ),
        ),
      ),
    );
  }

  // Widget para opções de tema
  Widget _buildThemeOption(
    String label,
    ThemeMode mode,
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    return GestureDetector(
      onTap: () {
        themeProvider.setThemeMode(mode);
        _showMessage('Tema alterado para $label');
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? accent : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(color: textMuted.withOpacity(0.2), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: textScaler.scale(14),
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
