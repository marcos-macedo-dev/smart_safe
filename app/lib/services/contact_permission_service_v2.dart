import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

/// Serviço melhorado para gerenciar permissões de contatos
class ContactPermissionServiceV2 {
  /// Verifica se a permissão de contatos está concedida
  static Future<bool> hasPermission() async {
    return await FlutterContacts.requestPermission();
  }

  /// Solicita permissão de contatos e retorna o resultado
  static Future<PermissionResult> requestPermission() async {
    try {
      final granted = await FlutterContacts.requestPermission();
      return granted 
          ? PermissionResult.granted()
          : PermissionResult.denied('Permissão negada pelo usuário');
    } catch (e) {
      return PermissionResult.error('Erro ao solicitar permissão: $e');
    }
  }

  /// Carrega contatos do dispositivo com tratamento de erros
  static Future<ContactLoadResult> loadDeviceContacts() async {
    try {
      // Verificar permissão primeiro
      final permissionResult = await requestPermission();
      if (!permissionResult.isGranted) {
        return ContactLoadResult.error(permissionResult.message ?? 'Permissão negada');
      }

      // Carregar contatos
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filtrar apenas contatos com telefone
      final contactsWithPhone = contacts
          .where((contact) => contact.phones.isNotEmpty)
          .toList();

      if (contactsWithPhone.isEmpty) {
        return ContactLoadResult.empty('Nenhum contato com telefone encontrado');
      }

      return ContactLoadResult.success(contactsWithPhone);
    } catch (e) {
      return ContactLoadResult.error('Erro ao carregar contatos: $e');
    }
  }

  /// Abre as configurações do app para o usuário alterar permissões
  static Future<bool> openAppSettings() async {
    return await permission_handler.openAppSettings();
  }
}

/// Resultado da verificação de permissão
class PermissionResult {
  final bool isGranted;
  final String? message;

  PermissionResult._({
    required this.isGranted,
    this.message,
  });

  factory PermissionResult.granted() {
    return PermissionResult._(isGranted: true);
  }

  factory PermissionResult.denied(String message) {
    return PermissionResult._(isGranted: false, message: message);
  }

  factory PermissionResult.error(String message) {
    return PermissionResult._(isGranted: false, message: message);
  }
}

/// Resultado do carregamento de contatos
class ContactLoadResult {
  final bool success;
  final List<Contact> contacts;
  final String? message;

  ContactLoadResult._({
    required this.success,
    this.contacts = const [],
    this.message,
  });

  factory ContactLoadResult.success(List<Contact> contacts) {
    return ContactLoadResult._(
      success: true,
      contacts: contacts,
    );
  }

  factory ContactLoadResult.empty(String message) {
    return ContactLoadResult._(
      success: false,
      message: message,
    );
  }

  factory ContactLoadResult.error(String message) {
    return ContactLoadResult._(
      success: false,
      message: message,
    );
  }
}