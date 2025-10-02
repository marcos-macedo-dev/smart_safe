import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final User? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _fetchProfileIfNeeded();
  }

  Future<void> _fetchProfileIfNeeded() async {
    if (_user != null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getProfile();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showMessage('Erro ao carregar perfil');
      }
    }
  }

  void _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ApiService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _showEditProfileBottomSheet() {
    if (_user == null) return;

    final nameCtrl = TextEditingController(text: _user!.nome_completo);
    final emailCtrl = TextEditingController(text: _user!.email);
    final telefoneCtrl = TextEditingController(text: _user!.telefone);
    final cidadeCtrl = TextEditingController(text: _user!.cidade);
    final estadoCtrl = TextEditingController(text: _user!.estado);
    final enderecoCtrl = TextEditingController(text: _user!.endereco);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      "Editar Perfil",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildEditTextField(
                      nameCtrl,
                      "Nome Completo",
                      Icons.person_outline,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      emailCtrl,
                      "Email",
                      Icons.alternate_email,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      telefoneCtrl,
                      "Telefone",
                      Icons.phone_outlined,
                      theme,
                      TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      cidadeCtrl,
                      "Cidade",
                      Icons.location_city_outlined,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      estadoCtrl,
                      "Estado",
                      Icons.map_outlined,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      enderecoCtrl,
                      "Endereço",
                      Icons.home_outlined,
                      theme,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => _saveProfile(
                                context,
                                nameCtrl,
                                emailCtrl,
                                telefoneCtrl,
                                cidadeCtrl,
                                estadoCtrl,
                                enderecoCtrl,
                              ),
                        child: _isSaving
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
                                  Icon(Icons.check, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Salvar Alterações',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile(
    BuildContext context,
    TextEditingController nameCtrl,
    TextEditingController emailCtrl,
    TextEditingController telefoneCtrl,
    TextEditingController cidadeCtrl,
    TextEditingController estadoCtrl,
    TextEditingController enderecoCtrl,
  ) async {
    final nome = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();

    if (nome.isEmpty || email.isEmpty) {
      _showMessage('Nome e email são obrigatórios');
      return;
    }

    setState(() => _isSaving = true);

    final updatedData = {
      'nome_completo': nome,
      'email': email,
      'telefone': telefoneCtrl.text.trim(),
      'cidade': cidadeCtrl.text.trim(),
      'estado': estadoCtrl.text.trim(),
      'endereco': enderecoCtrl.text.trim(),
      'cor': _user!.cor.toString().split('.').last,
      'documento_identificacao': _user!.documento_identificacao,
    };

    try {
      final success = await ApiService.updateUser(_user!.id, updatedData);
      if (success && mounted) {
        setState(() {
          _user = _user!.copyWith(
            nome_completo: nome,
            email: email,
            telefone: telefoneCtrl.text.trim(),
            cidade: cidadeCtrl.text.trim(),
            estado: estadoCtrl.text.trim(),
            endereco: enderecoCtrl.text.trim(),
            updatedAt: DateTime.now(),
          );
          _isSaving = false;
        });
        Navigator.pop(context);
        _showMessage('Perfil atualizado com sucesso!');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        _showMessage('Erro ao atualizar perfil');
      }
    }
  }

  Widget _buildEditTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    ThemeData theme, [
    TextInputType keyboard = TextInputType.text,
  ]) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
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

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String? value,
    required ThemeData theme,
  }) {
    final displayValue = (value?.isEmpty ?? true) ? 'Não informado' : value!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _enumToString(dynamic enumValue) {
    if (enumValue == null) return 'Não informado';
    return enumValue.toString().split('.').last.replaceAll('_', ' ');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary.withOpacity(0.02),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar perfil',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchProfileIfNeeded,
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar e nome
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _user!.nome_completo.isNotEmpty
                                    ? _user!.nome_completo[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            _user!.nome_completo.isNotEmpty
                                ? _user!.nome_completo
                                : 'Nome não informado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _user!.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Informações de contato
                    _buildInfoCard(
                      title: 'CONTATO',
                      theme: theme,
                      children: [
                        _buildInfoItem(
                          icon: Icons.phone_outlined,
                          label: 'Telefone',
                          value: _user!.telefone,
                          theme: theme,
                        ),
                        _buildInfoItem(
                          icon: Icons.alternate_email,
                          label: 'Email',
                          value: _user!.email,
                          theme: theme,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Localização
                    _buildInfoCard(
                      title: 'LOCALIZAÇÃO',
                      theme: theme,
                      children: [
                        _buildInfoItem(
                          icon: Icons.location_city_outlined,
                          label: 'Cidade',
                          value: _user!.cidade,
                          theme: theme,
                        ),
                        _buildInfoItem(
                          icon: Icons.map_outlined,
                          label: 'Estado',
                          value: _user!.estado,
                          theme: theme,
                        ),
                        _buildInfoItem(
                          icon: Icons.home_outlined,
                          label: 'Endereço',
                          value: _user!.endereco,
                          theme: theme,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Dados pessoais
                    _buildInfoCard(
                      title: 'DADOS PESSOAIS',
                      theme: theme,
                      children: [
                        _buildInfoItem(
                          icon: Icons.palette_outlined,
                          label: 'Cor/Raça',
                          value: _enumToString(_user!.cor),
                          theme: theme,
                        ),
                        _buildInfoItem(
                          icon: Icons.badge_outlined,
                          label: 'Documento',
                          value: _user!.documento_identificacao,
                          theme: theme,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _showEditProfileBottomSheet,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 1,
                                ),
                                foregroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Editar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, '/change-password'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 1,
                                ),
                                foregroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Alterar Senha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Sair',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
