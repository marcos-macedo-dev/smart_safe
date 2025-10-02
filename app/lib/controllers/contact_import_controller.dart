import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';
import '../services/api_service.dart';

/// Controller responsável por gerenciar a importação de contatos do celular
class ContactImportController extends ChangeNotifier {
  final EmergencyContactService _contactService;
  
  List<Contact> _deviceContacts = [];
  List<Contact> _filteredContacts = [];
  List<Contact> _selectedContacts = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  ContactImportController() : _contactService = EmergencyContactService(ApiService());

  // Getters
  List<Contact> get deviceContacts => _deviceContacts;
  List<Contact> get filteredContacts => _filteredContacts;
  List<Contact> get selectedContacts => _selectedContacts;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasContacts => _deviceContacts.isNotEmpty;
  int get selectedCount => _selectedContacts.length;
  bool get hasSelection => _selectedContacts.isNotEmpty;
  bool get allFilteredSelected => _allFilteredSelected;

  /// Carrega contatos do dispositivo
  Future<void> loadDeviceContacts() async {
    _setLoading(true);
    _clearError();

    try {
      // Solicitar permissão
      final permissionStatus = await Permission.contacts.request();
      if (!permissionStatus.isGranted) {
        _setError('Permissão para acessar contatos foi negada');
        return;
      }

      // Carregar contatos do dispositivo
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filtrar apenas contatos com telefone
      _deviceContacts = contacts
          .where((contact) => contact.phones.isNotEmpty)
          .toList();

      _updateFilteredContacts();
      
      if (_deviceContacts.isEmpty) {
        _setError('Nenhum contato com telefone encontrado');
      }
    } catch (e) {
      _setError('Erro ao carregar contatos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza a consulta de busca
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _updateFilteredContacts();
    notifyListeners();
  }

  /// Alterna seleção de um contato
  void toggleContactSelection(Contact contact) {
    if (_selectedContacts.contains(contact)) {
      _selectedContacts.remove(contact);
    } else {
      _selectedContacts.add(contact);
    }
    notifyListeners();
  }

  /// Seleciona/deseleciona todos os contatos filtrados
  void toggleAllContacts() {
    if (_allFilteredSelected) {
      // Deselecionar todos os filtrados
      for (final contact in _filteredContacts) {
        _selectedContacts.remove(contact);
      }
    } else {
      // Selecionar todos os filtrados
      for (final contact in _filteredContacts) {
        if (!_selectedContacts.contains(contact)) {
          _selectedContacts.add(contact);
        }
      }
    }
    notifyListeners();
  }

  /// Verifica se todos os contatos filtrados estão selecionados
  bool get _allFilteredSelected {
    if (_filteredContacts.isEmpty) return false;
    return _filteredContacts.every((contact) => _selectedContacts.contains(contact));
  }

  /// Verifica se um contato específico está selecionado
  bool isContactSelected(Contact contact) {
    return _selectedContacts.contains(contact);
  }

  /// Importa os contatos selecionados
  Future<ImportResult> importSelectedContacts() async {
    if (_selectedContacts.isEmpty) {
      return ImportResult.error('Nenhum contato selecionado');
    }

    _setLoading(true);
    _clearError();

    try {
      int importedCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (final contact in _selectedContacts) {
        try {
          final phone = contact.phones.isNotEmpty
              ? contact.phones.first.number
              : '';

          if (phone.isEmpty) {
            errorCount++;
            errors.add('${contact.displayName}: Sem telefone');
            continue;
          }

          final emergencyContact = EmergencyContact(
            nome: contact.displayName.isNotEmpty ? contact.displayName : 'Sem nome',
            telefone: phone,
            usuarioId: 0, // Será preenchido pelo serviço
          );

          await _contactService.addContact(emergencyContact);
          importedCount++;
        } catch (e) {
          errorCount++;
          errors.add('${contact.displayName}: $e');
        }
      }

      // Limpar seleções após importação
      _selectedContacts.clear();
      notifyListeners();

      return ImportResult.success(
        importedCount: importedCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult.error('Erro durante importação: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza a lista de contatos filtrados baseada na consulta de busca
  void _updateFilteredContacts() {
    if (_searchQuery.isEmpty) {
      _filteredContacts = List.from(_deviceContacts);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredContacts = _deviceContacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final phone = contact.phones.isNotEmpty 
            ? contact.phones.first.number.toLowerCase()
            : '';
        return name.contains(query) || phone.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  /// Define o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Define um erro
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Limpa erros
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Resultado da importação de contatos
class ImportResult {
  final bool success;
  final int importedCount;
  final int errorCount;
  final List<String> errors;
  final String? message;

  ImportResult._({
    required this.success,
    this.importedCount = 0,
    this.errorCount = 0,
    this.errors = const [],
    this.message,
  });

  factory ImportResult.success({
    required int importedCount,
    int errorCount = 0,
    List<String> errors = const [],
  }) {
    return ImportResult._(
      success: true,
      importedCount: importedCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  factory ImportResult.error(String message) {
    return ImportResult._(
      success: false,
      message: message,
    );
  }
}
