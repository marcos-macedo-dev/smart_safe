import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';
import '../services/api_service.dart';
import '../widgets/contact_import_sheet.dart';

/// Tela de contatos de emergência com foco na importação do celular
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  // Paleta institucional
  static const Color _violetaEscura = Color(0xFF311756);
  static const Color _violetaMedia = Color(0xFF401F56);

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

  late final EmergencyContactService _contactService;
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _contactService = EmergencyContactService(ApiService());
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _loadContacts();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _contacts = await _contactService.getContactsFiltered();
      _fadeController.forward();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar contatos: $e';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showImportContacts() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ContactImportSheet(),
    );

    // Recarregar contatos após importação
    await _loadContacts();
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    if (contact.id == null) return;

    final confirmed = await _showDeleteConfirmation(contact.nome);
    if (!confirmed || !mounted) return;

    try {
      await _contactService.deleteContact(contact.id!);
      await _loadContacts();
      _showMessage('Contato removido com sucesso');
    } catch (e) {
      if (mounted) {
        _showMessage('Erro ao remover contato: $e');
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String contactName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remover Contato'),
            content: Text(
              'Deseja remover $contactName dos contatos de emergência?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remover'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: accent,
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: _buildBody(theme, colorScheme, textScaler),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImportContacts,
        backgroundColor: accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Adicionar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    if (_isLoading) {
      return _buildLoadingState(theme, colorScheme, textScaler);
    }

    if (_error != null) {
      return _buildErrorState(theme, colorScheme, textScaler);
    }

    if (_contacts.isEmpty) {
      return _buildEmptyState(theme, colorScheme, textScaler);
    }

    return _buildContactsList(theme, colorScheme, textScaler);
  }

  Widget _buildLoadingState(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accent, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Carregando...',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: textScaler.scale(15),
              color: textMuted,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: colorScheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              'Erro ao carregar contatos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: textScaler.scale(20),
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: textScaler.scale(15),
                color: colorScheme.onSurfaceVariant,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _loadContacts,
                icon: Icon(Icons.refresh_rounded, size: 18, color: accent),
                label: Text(
                  'Tentar Novamente',
                  style: TextStyle(
                    fontSize: textScaler.scale(15),
                    fontWeight: FontWeight.w600,
                    color: accent,
                    letterSpacing: -0.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accent, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.contact_page_rounded,
                  size: 50,
                  color: accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhum contato de emergência',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: textScaler.scale(20),
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Adicione contatos para serem notificados em situações de emergência.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textScaler.scale(15),
                  color: textMuted,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _showImportContacts,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Adicionar Contatos',
                    style: TextStyle(
                      fontSize: textScaler.scale(16),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildContactsList(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadContacts,
        color: accent,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _contacts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final contact = _contacts[index];
            return _ContactCard(
              contact: contact,
              onDelete: () => _deleteContact(contact),
              colorScheme: colorScheme,
              textScaler: textScaler,
              accentColor: accent,
              accentTextColor: Colors.white,
              cardColor: cardColor,
              shadow: shadow,
              textPrimary: textPrimary,
              textMuted: textMuted,
            );
          },
        ),
      ),
    );
  }
}

/// Widget para o cartão de contato
class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onDelete;
  final ColorScheme colorScheme;
  final TextScaler textScaler;
  final Color accentColor;
  final Color accentTextColor;
  final Color cardColor;
  final Color shadow;
  final Color textPrimary;
  final Color textMuted;

  const _ContactCard({
    required this.contact,
    required this.onDelete,
    required this.colorScheme,
    required this.textScaler,
    required this.accentColor,
    required this.accentTextColor,
    required this.cardColor,
    required this.shadow,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials(contact.nome);

    return Slidable(
      key: ValueKey(contact.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colorScheme.error.withOpacity(0.1),
            foregroundColor: colorScheme.error,
            icon: Icons.delete_rounded,
            label: 'Remover',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
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
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: accentColor.withOpacity(0.15),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: textScaler.scale(14),
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
          title: Text(
            contact.nome,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: textScaler.scale(16),
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    contact.telefone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: textScaler.scale(14),
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
              if (contact.parentesco != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    contact.parentesco!,
                    style: TextStyle(
                      fontSize: textScaler.scale(11),
                      color: accentTextColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Icon(
            Icons.drag_handle_rounded,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            size: 18,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }

    return words
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join('');
  }
}
