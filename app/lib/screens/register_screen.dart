import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/user_enums.dart';
import '../services/location_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  // Máscaras
  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _documentoFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final List<String> _stepTitles = [
    'Informações Básicas',
    'Localização',
    'Dados Pessoais',
  ];

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 2) {
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
  }

  Future<void> _fillLocation() async {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Obtendo sua localização...',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
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

  void _register() async {
    if (!consentimento) {
      _showMessage('Aceite os termos de consentimento');
      return;
    }

    setState(() => _isLoading = true);

    User user = User(
      id: 0,
      nome_completo: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text.trim(),
      telefone: _telefoneController.text.trim(),
      cidade: _cidadeController.text.trim(),
      estado: _estadoController.text.trim(),
      endereco: _enderecoController.text.trim().isEmpty
          ? null
          : _enderecoController.text.trim(),
      genero: _genero,
      cor: _cor,
      documento_identificacao: _documentoController.text.trim().isEmpty
          ? null
          : _documentoController.text.trim(),
      consentimento: consentimento,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success = await ApiService.register(user);
    setState(() => _isLoading = false);

    if (success) {
      _showMessage('Registro concluído com sucesso!');
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } else {
      _showMessage('Erro ao registrar');
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
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: required
          ? (val) => (val == null || val.isEmpty) ? 'Campo obrigatório' : null
          : null,
      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.primary.withOpacity(0.7),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.primary.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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
  }) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(displayText(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.primary.withOpacity(0.7),
          size: 20,
        ),
        filled: true,
        fillColor: theme.colorScheme.primary.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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
            size: 20,
          ),
          onPressed: _previousStep,
        ),
        title: Text(
          'Criar Conta',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Progress indicator e título do step
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / 3,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título do step atual
                      Text(
                        _stepTitles[_currentStep],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Indicador do step
                      Text(
                        'Passo ${_currentStep + 1} de 3',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Conteúdo dos steps
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_step1(), _step2(), _step3()],
                  ),
                ),

                // Botão de ação
                Container(
                  padding: const EdgeInsets.all(32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: theme.colorScheme.primary
                            .withOpacity(0.6),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
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
                                  _currentStep == 2
                                      ? Icons.check
                                      : Icons.arrow_forward,
                                  size: 18,
                                  color: theme.colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _currentStep == 2
                                      ? 'Criar Conta'
                                      : 'Continuar',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),

          _buildTextField(
            controller: _nomeController,
            label: 'Nome Completo',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _senhaController,
            label: 'Senha',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _step2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),

          _buildTextField(
            controller: _telefoneController,
            label: 'Telefone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [_telefoneFormatter],
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _cidadeController,
            label: 'Cidade',
            icon: Icons.location_city_outlined,
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _estadoController,
            label: 'Estado (UF)',
            icon: Icons.map_outlined,
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _enderecoController,
            label: 'Endereço (Opcional)',
            icon: Icons.home_outlined,
            required: false,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _step3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),

          _buildDropdown<Genero>(
            value: _genero,
            label: 'Gênero',
            icon: Icons.female,
            items: Genero.values,
            onChanged: (Genero? val) => setState(() => _genero = val!),
            displayText: (g) =>
                g.toString().split('.').last.replaceAll('_', ' '),
          ),
          const SizedBox(height: 20),

          _buildDropdown<Cor>(
            value: _cor,
            label: 'Cor/Raça',
            icon: Icons.palette_outlined,
            items: Cor.values,
            onChanged: (Cor? val) => setState(() => _cor = val!),
            displayText: (c) =>
                c.toString().split('.').last.replaceAll('_', ' '),
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _documentoController,
            label: 'CPF (Opcional)',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [_documentoFormatter],
            required: false,
          ),

          const SizedBox(height: 32),

          // Checkbox de consentimento
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: consentimento,
                  onChanged: (v) => setState(() => consentimento = v!),
                  activeColor: Theme.of(context).colorScheme.primary,
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

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
