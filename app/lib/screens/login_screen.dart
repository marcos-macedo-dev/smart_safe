import 'package:app/screens/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _animController,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).animate(_fadeAnimation);

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
    _animController.dispose();
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
        title: Text(
          'Login rápido',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Deseja habilitar login com Face ID/Touch ID para futuros acessos?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13, letterSpacing: -0.1),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Agora não',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 144, 179, 201),
            ),
            child: const Text(
              'Habilitar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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

  void _navigateToWelcome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  Future<bool> _handleBackNavigation() async {
    if (Navigator.of(context).canPop()) {
      return true;
    }
    _navigateToWelcome();
    return false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          'Aviso',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  letterSpacing: -0.1,
                ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF004A77),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface.withOpacity(0.9),
          elevation: 0,
          leading: IconButton(
            onPressed: () async {
              final canLeave = await _handleBackNavigation();
              if (canLeave && mounted) Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Título principal com Material Design 3
                    Text(
                      'Bem-vinda',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                        fontSize: textScaler.scale(34),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse sua conta com segurança',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: -0.2,
                        fontSize: textScaler.scale(17),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Campo de email com Material Design 3
                    _buildMaterialField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: _validateEmail,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      errorText: _emailError,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    // Campo de senha com Material Design 3
                    _buildMaterialField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      label: 'Senha',
                      obscureText: true,
                      onChanged: _validatePassword,
                      onSubmitted: (_) => _login(),
                      errorText: _passwordError,
                      icon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 16),
                    // Link "Esqueceu a senha?" discreto
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Esqueceu a senha?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                            letterSpacing: -0.2,
                            fontSize: textScaler.scale(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botão de login principal - destaque suave
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFF004A77),
                          disabledBackgroundColor: colorScheme.onSurface
                              .withOpacity(0.12),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                'Entrar',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  fontSize: textScaler.scale(17),
                                ),
                              ),
                      ),
                    ),
                    if (_showBiometricOption) ...[
                      const SizedBox(height: 24),
                      _buildDivider(context),
                      const SizedBox(height: 24),
                      // Botão de biometria minimalista
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isAuthenticating
                              ? null
                              : _authenticateWithBiometrics,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isAuthenticating)
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onSurface,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.fingerprint,
                                  color: colorScheme.onSurface,
                                  size: 20,
                                ),
                              const SizedBox(width: 10),
                              Text(
                                'Usar biometria',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.2,
                                  fontSize: textScaler.scale(17),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    bool obscureText = false,
    ValueChanged<String>? onSubmitted,
    String? errorText,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: textScaler.scale(16),
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: textScaler.scale(16),
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: colorScheme.onSurfaceVariant, size: 24)
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF004A77), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        errorText: errorText,
        errorStyle: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
          fontSize: textScaler.scale(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    return Row(
      children: [
        Expanded(
          child: Container(height: 0.5, color: colorScheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: textScaler.scale(15),
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 0.5, color: colorScheme.outlineVariant),
        ),
      ],
    );
  }
}
