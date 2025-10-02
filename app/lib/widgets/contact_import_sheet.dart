import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../controllers/contact_import_controller.dart';

/// Widget para importação de contatos do dispositivo
class ContactImportSheet extends StatefulWidget {
  const ContactImportSheet({super.key});

  @override
  State<ContactImportSheet> createState() => _ContactImportSheetState();
}

class _ContactImportSheetState extends State<ContactImportSheet> {
  late final ContactImportController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = ContactImportController();
    _searchController = TextEditingController();
    _controller.addListener(_onControllerChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadContacts() async {
    await _controller.loadDeviceContacts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            _buildDragHandle(theme),
            _buildHeader(theme),
            _buildSearchField(theme),
            _buildSelectionInfo(theme),
            _buildContactsList(theme),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Center(
        child: Container(
          width: 50,
          height: 5,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Importar Contatos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_controller.hasContacts)
            IconButton(
              icon: Icon(
                _controller.allFilteredSelected
                    ? Icons.check_box 
                    : Icons.check_box_outline_blank,
                color: theme.colorScheme.primary,
              ),
              onPressed: _controller.toggleAllContacts,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar contato...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _controller.updateSearchQuery,
      ),
    );
  }

  Widget _buildSelectionInfo(ThemeData theme) {
    if (_controller.selectedCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_controller.selectedCount} selecionados',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(
            onPressed: _controller.selectedCount > 0 ? _importContacts : null,
            child: Text(
              'Importar',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(ThemeData theme) {
    if (_controller.isLoading) {
      return const Flexible(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.error != null) {
      return Flexible(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _controller.error!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadContacts,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_controller.hasContacts) {
      return const Flexible(
        child: Center(
          child: Text('Nenhum contato encontrado'),
        ),
      );
    }

    final filteredContacts = _controller.filteredContacts;
    
    if (filteredContacts.isEmpty) {
      return Flexible(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum contato encontrado',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredContacts.length,
        itemBuilder: (context, index) {
          final contact = filteredContacts[index];
          return _ContactListItem(
            contact: contact,
            isSelected: _controller.isContactSelected(contact),
            onTap: () => _controller.toggleContactSelection(contact),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _controller.hasSelection ? _importContacts : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _controller.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Importar (${_controller.selectedCount})'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importContacts() async {
    final result = await _controller.importSelectedContacts();
    
    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      _showSuccessMessage(result);
    } else {
      _showErrorMessage(result.message ?? 'Erro desconhecido');
    }
  }

  void _showSuccessMessage(ImportResult result) {
    final message = result.errorCount > 0
        ? 'Importados ${result.importedCount} contatos com ${result.errorCount} erros'
        : 'Importados ${result.importedCount} contatos com sucesso';

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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(24),
      ),
    );
  }
}

/// Widget para item da lista de contatos
class _ContactListItem extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactListItem({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials(contact.displayName);
    final phone = contact.phones.isNotEmpty 
        ? contact.phones.first.number 
        : 'Sem telefone';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 20,
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
          contact.displayName.isNotEmpty ? contact.displayName : 'Sem nome',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          phone,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (_) => onTap(),
          checkColor: theme.colorScheme.onPrimary,
          activeColor: theme.colorScheme.primary,
        ),
        onTap: onTap,
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
