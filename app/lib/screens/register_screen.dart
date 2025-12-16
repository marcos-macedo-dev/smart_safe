import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../models/user.dart';
import '../models/user_enums.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color accent = Color(0xFF7C5CC3);

  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _documentoController = TextEditingController();

  Cor _cor = Cor.Outra;
  Genero _genero = Genero.Feminino;
  bool consentimento = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  int _currentStep = 0;

  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _documentoFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final List<String> _stepTitles = [
    'Suas Informações',
    'Sua Localização',
    'Detalhes Finais',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _telefoneController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _enderecoController.dispose();
    _documentoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() != true) {
      _showMessage('Preencha todos os campos obrigatórios.');
      return;
    }

    if (_currentStep < _stepTitles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);

      if (_currentStep == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fillLocation();
        });
      }
    } else {
      _register();
    }
  }

  Future<void> _fillLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Obtendo sua localização...'),
          ],
        ),
      ),
    );

    try {
      final pos = await LocationService.getCurrentPosition();
      final data = await LocationService.getAddressFromPosition(pos);
      setState(() {
        _cidadeController.text = data['cidade'] ?? '';
        _estadoController.text = data['estado'] ?? '';
        _enderecoController.text = data['endereco'] ?? '';
      });
    } catch (e) {
      _showMessage('Erro ao obter localização: $e');
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) {
      _showMessage('Preencha todos os campos obrigatórios.');
      return;
    }

    if (!consentimento) {
      _showMessage('Você deve aceitar os termos de consentimento.');
      return;
    }

    setState(() => _isLoading = true);

    final user = User(
      id: 0,
      nome_completo: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text.trim(),
      telefone: _telefoneController.text.trim(),
      cidade: _cidadeController.text.trim(),
      estado: _estadoController.text.trim(),
      endereco:
          _enderecoController.text.trim().isEmpty ? null : _enderecoController.text.trim(),
      genero: _genero,
      cor: _cor,
      documento_identificacao:
          _documentoController.text.trim().isEmpty ? null : _documentoController.text.trim(),
      consentimento: consentimento,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ApiService.register(user);
    setState(() => _isLoading = false);

    if (success) {
      _showMessage('Registro concluído com sucesso! Faça login para acessar.');
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } else {
      _showMessage('Erro ao registrar. Verifique seus dados ou tente novamente.');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.onSurface;
    final textMuted = scheme.onSurfaceVariant;
    final fill = scheme.surface;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: isRequired
          ? (val) => (val == null || val.isEmpty) ? 'Campo obrigatório' : null
          : null,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted),
        prefixIcon: Icon(icon, color: textMuted),
        suffixIcon: suffixIcon,
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
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
        errorStyle: TextStyle(color: Colors.red.shade700, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) displayText,
    bool isRequired = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.onSurface;
    final textMuted = scheme.onSurfaceVariant;
    final fill = scheme.surface;

    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                displayText(item),
                style: TextStyle(color: textPrimary),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: isRequired ? (val) => (val == null) ? 'Campo obrigatório' : null : null,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted),
        prefixIcon: Icon(icon, color: textMuted),
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
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
        errorStyle: TextStyle(color: Colors.red.shade700, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = colorScheme.surface;
    final textMuted = colorScheme.onSurfaceVariant;
    final shadow = Colors.black.withOpacity(isDark ? 0.35 : 0.08);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 12;

    return Scaffold(
      backgroundColor: accent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _previousStep,
        ),
        title: Text(
          _stepTitles[_currentStep],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                  Text(
                    'Crie sua conta\ncom segurança',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ).animate().fade().slideX(begin: -0.2, end: 0),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * 0.78,
              ),
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
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  32,
                  24,
                  24 + bottomPadding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / _stepTitles.length,
                          backgroundColor: textMuted.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            accent,
                          ),
                          minHeight: 6,
                        ),
                      ).animate().fade(delay: 100.ms),
                      const SizedBox(height: 16),
                      Text(
                        'Passo ${_currentStep + 1} de ${_stepTitles.length}',
                        style: TextStyle(fontSize: 14, color: textMuted),
                      ).animate().fade(delay: 200.ms),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.52,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1(),
                            _buildStep2(),
                            _buildStep3(),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                              : Text(
                                  _currentStep == _stepTitles.length - 1
                                      ? 'CRIAR CONTA'
                                      : 'CONTINUAR',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
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

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildTextField(
            controller: _nomeController,
            label: 'Nome Completo',
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _senhaController,
            label: 'Senha',
            icon: LucideIcons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildTextField(
            controller: _telefoneController,
            label: 'Telefone',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [_telefoneFormatter],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _cidadeController,
            label: 'Cidade',
            icon: LucideIcons.building,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _estadoController,
            label: 'Estado (UF)',
            icon: LucideIcons.map,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _enderecoController,
            label: 'Endereço (Opcional)',
            icon: LucideIcons.house,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildDropdown<Genero>(
            value: _genero,
            label: 'Gênero',
            icon: LucideIcons.users,
            items: Genero.values,
            onChanged: (Genero? val) => setState(() => _genero = val!),
            displayText: (g) => g.toString().split('.').last.replaceAll('_', ' '),
          ),
          const SizedBox(height: 20),
          _buildDropdown<Cor>(
            value: _cor,
            label: 'Cor/Raça',
            icon: LucideIcons.palette,
            items: Cor.values,
            onChanged: (Cor? val) => setState(() => _cor = val!),
            displayText: (c) => c.toString().split('.').last.replaceAll('_', ' '),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _documentoController,
            label: 'CPF (Opcional)',
            icon: LucideIcons.creditCard,
            keyboardType: TextInputType.number,
            inputFormatters: [_documentoFormatter],
            isRequired: false,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: consentimento,
                  onChanged: (v) => setState(() => consentimento = v ?? false),
                  activeColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Aceito os termos de consentimento e política de privacidade',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
