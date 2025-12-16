import 'package:app/screens/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/biometric_auth_service.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  bool _canCheckBiometrics = false;
  bool _isAuthenticating = false;
  bool _showBiometricOption = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _initializeBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _initializeBiometrics() async {
    _canCheckBiometrics = await _biometricAuthService.canAuthenticate();
    final biometricEnabled = await _biometricAuthService
        .getBiometricPreference();

    if (mounted) {
      setState(() {
        _showBiometricOption = _canCheckBiometrics && biometricEnabled;
      });
    }

    if (_showBiometricOption) {
      _authenticateWithBiometrics();
    }
  }

  void _validateEmail(String value) {
    setState(() {
      _emailError = value.isNotEmpty && value.contains('@')
          ? null
          : 'Email inválido';
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _passwordError = value.isNotEmpty && value.length >= 6
          ? null
          : 'Mínimo 6 caracteres';
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_canCheckBiometrics) return;

    try {
      setState(() => _isAuthenticating = true);
      final authenticated = await _biometricAuthService.authenticate();
      if (!mounted) return;

      if (authenticated) {
        final User? user = await ApiService.getProfile();
        if (user != null) {
          _navigateToMain();
        } else {
          _showMessage('Sessão expirada. Faça login novamente.');
          await _biometricAuthService.saveBiometricPreference(false);
          if (mounted) setState(() => _showBiometricOption = false);
        }
      } else {
        _showMessage('Autenticação biométrica falhou.');
      }
    } on PlatformException catch (e) {
      if (e.code != 'AUTH_CANCELED' && e.code != 'NOT_ENROLLED') {
        _showMessage('Erro na autenticação biométrica: ${e.message}');
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _login() async {
    _validateEmail(_emailController.text.trim());
    _validatePassword(_passwordController.text.trim());
    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);
    try {
      final User? user = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        await _promptForBiometrics();
        if (!mounted) return;
        _navigateToMain();
      } else {
        _showMessage('Credenciais inválidas');
      }
    } catch (_) {
      _showMessage('Erro ao fazer login. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promptForBiometrics() async {
    if (!await _biometricAuthService.canAuthenticate()) return;

    final enableBiometrics = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Login rápido'),
        content: const Text(
          'Deseja habilitar login com Face ID/Touch ID para futuros acessos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );

    if (enableBiometrics != null) {
      await _biometricAuthService.saveBiometricPreference(enableBiometrics);
      if (mounted) {
        setState(() {
          _showBiometricOption = enableBiometrics;
        });
      }
    }
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayoutWithIndicators()),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFF7C5CC3);
    final cardColor = colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;
    final shadow = Colors.black.withOpacity(isDark ? 0.35 : 0.08);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: accent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Header
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Bem-vindo\nde volta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ).animate().fade().slideX(begin: -0.2, end: 0),
                ],
              ),
            ),
          ),

          // Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child:
                Container(
                  height:
                      MediaQuery.sizeOf(context).height *
                      0.75, // Altura fixa confortável
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadow,
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      32,
                      40,
                      32,
                      24 + bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Fields
                        _buildTextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              label: 'E-mail',
                              icon: LucideIcons.mail,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: _validateEmail,
                              errorText: _emailError,
                              onSubmitted: (_) => FocusScope.of(
                                context,
                              ).requestFocus(_passwordFocus),
                            )
                            .animate()
                            .fade(delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        _buildTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              label: 'Senha',
                              icon: LucideIcons.lock,
                              obscureText: true,
                              onChanged: _validatePassword,
                              errorText: _passwordError,
                              onSubmitted: (_) => _login(),
                            )
                            .animate()
                            .fade(delay: 300.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/forgot-password',
                            ),
                            child: Text(
                              'Esqueci minha senha',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'ENTRAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ).animate().fade(delay: 400.ms).scale(),
                        if (_showBiometricOption) ...[
                          const SizedBox(height: 24),
                          Center(
                            child: IconButton(
                              onPressed: _isAuthenticating
                                  ? null
                                  : _authenticateWithBiometrics,
                              icon: const Icon(
                                Icons.fingerprint,
                                size: 48,
                                color: accent,
                              ),
                              tooltip: 'Entrar com biometria',
                            ),
                          ).animate().fade(delay: 500.ms),
                          Center(
                            child: Text(
                              'Toque para usar biometria',
                              style: TextStyle(color: textMuted, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().slideY(
                  begin: 1.0,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutQuart,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accent = Color(0xFF7C5CC3);
    final textPrimary = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;
    final fill = colorScheme.surface;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: textPrimary), // Texto digitado adaptado ao tema
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted), // Cor do label (placeholder)
        prefixIcon: Icon(icon, color: textMuted), // Cor do ícone
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textMuted.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
        errorText: errorText,
        errorStyle: TextStyle(color: Colors.red.shade700, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }
}
