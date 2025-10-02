import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_layout.dart';
import 'root_screen.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../services/biometric_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  bool _canCheckBiometrics = false;
  bool _isAuthenticating = false;
  bool _showBiometricOption = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initializeBiometrics();
  }

  Future<void> _initializeBiometrics() async {
    _canCheckBiometrics = await _biometricAuthService.canAuthenticate();
    final bool biometricEnabled = await _biometricAuthService
        .getBiometricPreference();

    print('LoginScreen: _canCheckBiometrics: $_canCheckBiometrics');
    print('LoginScreen: biometricEnabled (preference): $biometricEnabled');

    if (mounted) {
      setState(() {
        _showBiometricOption = _canCheckBiometrics && biometricEnabled;
      });
    }

    print('LoginScreen: _showBiometricOption: $_showBiometricOption');

    if (_showBiometricOption) {
      print('LoginScreen: Attempting automatic biometric authentication...');
      _authenticateWithBiometrics(); // Reativado para tentar autenticação automática
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_canCheckBiometrics) return;

    try {
      setState(() => _isAuthenticating = true);
      final authenticated = await _biometricAuthService.authenticate();

      print('LoginScreen: Biometric authentication result: $authenticated');

      if (!mounted) return;

      if (authenticated) {
        final User? user = await ApiService.getProfile();
        if (user != null) {
          _navigateToMain();
        } else {
          _showMessage('Sessão expirada. Por favor, faça login novamente.');
          await _biometricAuthService.saveBiometricPreference(false);
          if (mounted) setState(() => _showBiometricOption = false);
        }
      } else {
        _showMessage('Autenticação biométrica falhou. Tente novamente.');
      }
    } on PlatformException catch (e) {
      if (e.code != 'AUTH_CANCELED' && e.code != 'NOT_ENROLLED') {
        _showMessage('Erro na autenticação biométrica: ${e.message}');
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Preencha email e senha');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final User? user = await ApiService.login(email, password);
      if (user != null) {
        _promptForBiometrics();
        _navigateToMain();
      } else {
        _showMessage('Credenciais inválidas');
      }
    } catch (e) {
      _showMessage('Erro ao fazer login. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promptForBiometrics() async {
    if (!await _biometricAuthService.canAuthenticate()) return;

    final bool? enableBiometrics = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Rápido'),
          content: const Text(
            'Deseja habilitar o login com reconhecimento facial/digital para futuros acessos?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
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
    
    try {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => MainLayoutWithIndicators(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      print('Erro ao navegar para MainLayout: $e');
      // Fallback para navegação simples
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainLayoutWithIndicators()),
      );
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        title: Text(
          'Login',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Bem-vindo de volta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entre na sua conta para continuar',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.alternate_email_outlined,
                inputType: TextInputType.emailAddress,
                theme: theme,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'Senha',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                theme: theme,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  splashRadius: 24,
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 36),
                  ),
                  child: Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 2,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor: theme.colorScheme.primary
                        .withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              size: 20,
                              color: theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_showBiometricOption) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isAuthenticating
                        ? null
                        : _authenticateWithBiometrics,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        width: 1.5,
                      ),
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _isAuthenticating
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.fingerprint_rounded,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                    label: Text(
                      'Usar biometria',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    TextInputType inputType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 16,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.primary.withOpacity(0.8),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.primary.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

