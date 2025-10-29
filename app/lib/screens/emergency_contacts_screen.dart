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
  late final EmergencyContactService _contactService;
  List<EmergencyContact> _filteredContacts = [];
  List<String> _availableRelationships = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _selectedFilter;

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
      _availableRelationships = await _contactService
          .getAvailableRelationships();
      _availableRelationships.add('Sem parentesco');
      _applyFilter();
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

  Future<void> _applyFilter() async {
    if (!mounted) return;

    try {
      _filteredContacts = await _contactService.getContactsFiltered(
        relationship: _selectedFilter,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao aplicar filtro: $e';
        });
      }
    }
  }

  Future<void> _setFilter(String? filter) async {
    setState(() {
      _selectedFilter = filter;
    });
    await _applyFilter();
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
      if (mounted) {
        await _loadContacts();
        _showMessage('Contato removido com sucesso');
      }
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
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedFilter != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedFilter!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _setFilter(null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          PopupMenuButton<String>(
            onSelected: _setFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              ..._getUniqueParentescos().map(
                (parentesco) =>
                    PopupMenuItem(value: parentesco, child: Text(parentesco)),
              ),
            ],
            icon: Icon(
              Icons.filter_list_rounded,
              color: _selectedFilter != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(theme),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImportContacts,
        child: const Icon(Icons.contacts_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  List<String> _getUniqueParentescos() {
    return _availableRelationships;
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_filteredContacts.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildContactsList(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando...',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              'Erro ao carregar contatos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _loadContacts,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tentar Novamente'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final hasFilter = _selectedFilter != null;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFilter
                      ? Icons.filter_list_rounded
                      : Icons.contact_page_rounded,
                  size: 40,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasFilter
                    ? 'Nenhum contato encontrado'
                    : 'Nenhum contato de emergência',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasFilter
                    ? 'Não há contatos com o filtro selecionado.'
                    : 'Importe contatos do seu celular para serem notificados em emergências.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: hasFilter
                      ? () => _setFilter(null)
                      : _showImportContacts,
                  icon: Icon(
                    hasFilter
                        ? Icons.filter_list_off_rounded
                        : Icons.contacts_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    hasFilter ? 'Remover filtro' : 'Importar Contatos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _buildContactsList(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadContacts,
        color: theme.colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _filteredContacts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final contact = _filteredContacts[index];
            return _ContactCard(
              contact: contact,
              onDelete: () => _deleteContact(contact),
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

  const _ContactCard({required this.contact, required this.onDelete});

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
            backgroundColor: theme.colorScheme.error.withOpacity(0.1),
            foregroundColor: theme.colorScheme.error,
            icon: Icons.delete_rounded,
            label: 'Remover',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            contact.nome,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.phone_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    contact.telefone,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (contact.parentesco != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    contact.parentesco!,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Icon(
            Icons.drag_handle_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            size: 16,
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
