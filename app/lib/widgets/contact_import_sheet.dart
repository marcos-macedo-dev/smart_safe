import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../controllers/contact_import_controller.dart';
import '../utils/app_message.dart';

/// Bottom sheet para importar contatos com tema dinâmico
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF7C5CC3) : colorScheme.primary;
    final cardColor = colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;
    final shadow = Colors.black.withOpacity(isDark ? 0.35 : 0.08);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset + bottomPadding),
        child: Column(
          children: [
            _buildDragHandle(textMuted),
            _buildHeader(theme, textPrimary, accent),
            _buildSearchField(cardColor, accent, textMuted, shadow),
            _buildSelectionInfo(
              theme,
              textPrimary,
              textMuted,
              cardColor,
              shadow,
              accent,
            ),
            _buildContactsList(
              theme,
              cardColor,
              textPrimary,
              textMuted,
              accent,
              shadow,
            ),
            _buildActionButtons(accent, cardColor, shadow),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(Color textMuted) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Center(
        child: Container(
          width: 50,
          height: 5,
          decoration: BoxDecoration(
            color: textMuted.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color textPrimary, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Importar Contatos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          if (_controller.hasContacts)
            IconButton(
              icon: Icon(
                _controller.allFilteredSelected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: accent,
              ),
              onPressed: _controller.toggleAllContacts,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    Color cardColor,
    Color accent,
    Color textMuted,
    Color shadow,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar contato...',
            hintStyle: TextStyle(color: textMuted),
            prefixIcon: Icon(Icons.search, color: textMuted),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: textMuted.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: _controller.updateSearchQuery,
        ),
      ),
    );
  }

  Widget _buildSelectionInfo(
    ThemeData theme,
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color shadow,
    Color accent,
  ) {
    if (!_controller.hasContacts || _controller.filteredContacts.isEmpty) {
      return const SizedBox.shrink();
    }

    final message = _controller.allFilteredSelected
        ? 'Todos os contatos filtrados selecionados'
        : _controller.selectedCount > 0
        ? '${_controller.selectedCount} selecionados'
        : 'Selecione contatos para importar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _controller.allFilteredSelected
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: _controller.allFilteredSelected ? accent : textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: textPrimary),
              ),
            ),
            Text(
              '${_controller.selectedCount}/${_controller.filteredContacts.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList(
    ThemeData theme,
    Color cardColor,
    Color textPrimary,
    Color textMuted,
    Color accent,
    Color shadow,
  ) {
    if (_controller.isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_controller.error != null) {
      return Expanded(
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
      return const Expanded(
        child: Center(child: Text('Nenhum contato encontrado')),
      );
    }

    final filteredContacts = _controller.filteredContacts;

    if (filteredContacts.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: textMuted.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum contato encontrado',
                style: TextStyle(color: textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filteredContacts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final contact = filteredContacts[index];
          final isSelected = _controller.isContactSelected(contact);
          return _ContactListItem(
            contact: contact,
            isSelected: isSelected,
            onTap: () => _controller.toggleContactSelection(contact),
            cardColor: cardColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            accent: accent,
            shadow: shadow,
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Color accent, Color cardColor, Color shadow) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                side: BorderSide(color: accent.withOpacity(0.7)),
                foregroundColor: accent,
                backgroundColor: cardColor,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _controller.hasSelection ? _importContacts : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: _controller.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Importar (${_controller.selectedCount})'),
              ),
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

    final hasPartialErrors = result.errorCount > 0;

    AppMessage.show(
      context,
      message: message,
      type: hasPartialErrors ? AppMessageType.warning : AppMessageType.success,
    );
  }

  void _showErrorMessage(String message) {
    AppMessage.error(context, message: message);
  }
}

/// Widget para item da lista de contatos
class _ContactListItem extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color shadow;

  const _ContactListItem({
    required this.contact,
    required this.isSelected,
    required this.onTap,
    required this.cardColor,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(contact.displayName);
    final phone = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : 'Sem telefone';

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? accent.withOpacity(0.08) : cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? accent.withOpacity(0.6)
              : textMuted.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: accent.withOpacity(0.18),
          child: Text(
            initials,
            style: TextStyle(fontWeight: FontWeight.bold, color: accent),
          ),
        ),
        title: Text(
          contact.displayName.isNotEmpty ? contact.displayName : 'Sem nome',
          style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        ),
        subtitle: Text(phone, style: TextStyle(color: textMuted)),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (_) => onTap(),
          activeColor: accent,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
