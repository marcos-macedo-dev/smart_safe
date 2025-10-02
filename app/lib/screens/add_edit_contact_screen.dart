import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/contact_permission_service.dart';

class AddEditContactScreen extends StatefulWidget {
  final EmergencyContact? contact;

  const AddEditContactScreen({super.key, this.contact});

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  late final TextEditingController nomeController;
  late final TextEditingController telefoneController;
  late final TextEditingController parentescoController;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.contact?.nome);
    telefoneController = TextEditingController(text: widget.contact?.telefone);
    parentescoController = TextEditingController(
      text: widget.contact?.parentesco,
    );
  }

  Future<void> _pickFromPhoneContacts() async {
    final contacts = await ContactPermissionService.getPhoneContacts();
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum contato ou permissão negada')),
      );
      return;
    }

    Contact? selectedContact;

    await showDialog(
      context: context,
      builder: (context) {
        final searchController = TextEditingController();
        List<Contact> filteredContacts = contacts;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Escolha um contato'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar contato',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        filteredContacts = contacts
                            .where(
                              (c) => c.displayName.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredContacts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = filteredContacts[index];
                        final phone = c.phones.isNotEmpty
                            ? c.phones.first.number
                            : '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              c.displayName.isNotEmpty
                                  ? c.displayName
                                        .trim()
                                        .split(' ')
                                        .map((e) => e[0])
                                        .take(2)
                                        .join()
                                        .toUpperCase()
                                  : '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(c.displayName),
                          subtitle: phone.isNotEmpty ? Text(phone) : null,
                          onTap: () {
                            selectedContact = c;
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedContact != null) {
      setState(() {
        nomeController.text = selectedContact!.displayName;
        telefoneController.text = selectedContact!.phones.isNotEmpty
            ? selectedContact!.phones.first.number
            : '';
      });
    }
  }

  void _save() {
    final nome = nomeController.text.trim();
    final telefone = telefoneController.text.trim();
    final parentesco = parentescoController.text.trim().isEmpty
        ? null
        : parentescoController.text.trim();

    if (nome.isEmpty || telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome e número de telefone não podem ser vazios'),
        ),
      );
      return;
    }

    final result = EmergencyContact(
      id: widget.contact?.id,
      nome: nome,
      telefone: telefone,
      parentesco: parentesco,
      usuarioId: widget.contact?.usuarioId ?? 0,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.contact == null ? 'Adicionar Contato' : 'Editar Contato',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.contacts),
                    onPressed: _pickFromPhoneContacts,
                    tooltip: 'Importar do celular',
                    color: theme.colorScheme.primary,
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Número de Telefone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: parentescoController,
                decoration: const InputDecoration(
                  labelText: 'Parentesco (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.contact == null ? 'Adicionar' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
