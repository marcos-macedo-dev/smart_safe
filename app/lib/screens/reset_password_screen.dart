import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const Color accent = Color(0xFF7C5CC3);

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Campo obrigatório';
      } else if (value.length < 8) {
        _passwordError = 'Mínimo 8 caracteres';
      } else {
        final strongPasswordRegex = RegExp(
          r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
        );
        if (!strongPasswordRegex.hasMatch(value)) {
          _passwordError = 'Senha fraca';
        } else {
          _passwordError = null;
        }
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = 'Campo obrigatório';
      } else if (value != _passwordController.text) {
        _confirmPasswordError = 'Senhas não coincidem';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  Future<void> _resetPassword() async {
    _validatePassword(_passwordController.text);
    _validateConfirmPassword(_confirmPasswordController.text);

    if (_passwordError != null || _confirmPasswordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.resetPasswordWithOTP(
      widget.email,
      widget.otp,
      _passwordController.text,
    );

    if (mounted) {
      if (result['success']) {
        _showMessage('Senha redefinida com sucesso!');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/password-reset-success');
          }
        });
      } else {
        _showMessage(
          result['message'] ??
              'Não foi possível redefinir a senha. O código pode ser inválido ou ter expirado.',
        );
      }
      setState(() => _isLoading = false);
    }
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
    final cardColor = colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;
    final shadow = Colors.black.withOpacity(isDark ? 0.35 : 0.08);
    final bottomPadding =
        MediaQuery.viewPaddingOf(context).bottom +
        MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: accent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Redefinir\nSenha',
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
          Align(
            alignment: Alignment.bottomCenter,
            child:
                Container(
                  height: MediaQuery.sizeOf(context).height * 0.75,
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
                        Text(
                          'Crie sua nova senha',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Digite uma senha forte e única para sua conta.',
                          style: TextStyle(fontSize: 14, color: textMuted),
                        ),
                        const SizedBox(height: 32),
                        _buildPasswordField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              label: 'Nova Senha',
                              icon: LucideIcons.lock,
                              obscureText: _obscurePassword,
                              onChanged: _validatePassword,
                              errorText: _passwordError,
                              onToggleObscure: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              onSubmitted: (_) => FocusScope.of(
                                context,
                              ).requestFocus(_confirmPasswordFocus),
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              fill: colorScheme.surface,
                              accentColor: accent,
                            )
                            .animate()
                            .fade(delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              label: 'Confirmar Nova Senha',
                              icon: LucideIcons.lock,
                              obscureText: _obscureConfirmPassword,
                              onChanged: _validateConfirmPassword,
                              errorText: _confirmPasswordError,
                              onToggleObscure: () {
                                setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                );
                              },
                              onSubmitted: (_) => _resetPassword(),
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              fill: colorScheme.surface,
                              accentColor: accent,
                            )
                            .animate()
                            .fade(delay: 300.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _resetPassword,
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
                                    'REDEFINIR SENHA',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ).animate().fade(delay: 400.ms).scale(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requisitos da senha:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPasswordRequirement(
                                'Mínimo de 8 caracteres',
                                textMuted,
                              ),
                              _buildPasswordRequirement(
                                'Letras maiúsculas e minúsculas',
                                textMuted,
                              ),
                              _buildPasswordRequirement('Números', textMuted),
                              _buildPasswordRequirement(
                                'Caracteres especiais (@\$!%*?&)',
                                textMuted,
                              ),
                            ],
                          ),
                        ).animate().fade(delay: 500.ms),
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

  Widget _buildPasswordRequirement(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: textColor),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 11, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required bool obscureText,
    required ValueChanged<String>? onChanged,
    required ValueChanged<String>? onSubmitted,
    required VoidCallback onToggleObscure,
    required Color textPrimary,
    required Color textMuted,
    required Color fill,
    required Color accentColor,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted),
        prefixIcon: Icon(icon, color: textMuted),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: textMuted,
          ),
          onPressed: onToggleObscure,
        ),
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
          borderSide: BorderSide(color: accentColor, width: 2),
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
