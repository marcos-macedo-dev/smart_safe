import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';
import '../services/api_service.dart';
import '../widgets/contact_import_sheet.dart';

/// Tela de contatos de emergência com foco na importação do celular
class EmergencyContactsScreenV2 extends StatefulWidget {
  const EmergencyContactsScreenV2({super.key});

  @override
  State<EmergencyContactsScreenV2> createState() => _EmergencyContactsScreenV2State();
}

class _EmergencyContactsScreenV2State extends State<EmergencyContactsScreenV2> {
  late final EmergencyContactService _contactService;
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _contactService = EmergencyContactService(ApiService());
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contacts = await _contactService.getContacts();
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar contatos: $e';
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
        content: Text('Deseja remover $contactName dos contatos de emergência?'),
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
    ) ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: _buildBody(theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImportContacts,
        icon: const Icon(Icons.contacts_rounded),
        label: const Text('Importar Contatos'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_contacts.isEmpty) {
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
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 20),
          Text(
            'Carregando contatos...',
            style: TextStyle(
              fontSize: 16,
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
        padding: const EdgeInsets.all(32),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadContacts,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contact_page_rounded,
              size: 96,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum contato de emergência',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Importe contatos do seu celular para serem notificados em emergências.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _showImportContacts,
              icon: const Icon(Icons.contacts_rounded),
              label: const Text('Importar Contatos'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadContacts,
      color: theme.colorScheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _contacts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return _ContactCard(
            contact: contact,
            onDelete: () => _deleteContact(contact),
          );
        },
      ),
    );
  }
}

/// Widget para o cartão de contato
class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onDelete,
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
            backgroundColor: theme.colorScheme.error.withOpacity(0.1),
            foregroundColor: theme.colorScheme.error,
            icon: Icons.delete_rounded,
            label: 'Remover',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Text(
              initials,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            contact.nome,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.telefone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (contact.parentesco != null) ...[
                const SizedBox(height: 2),
                Text(
                  contact.parentesco!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          trailing: Icon(
            Icons.drag_handle_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
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
