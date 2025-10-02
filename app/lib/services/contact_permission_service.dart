import 'package:flutter_contacts/flutter_contacts.dart';

class ContactPermissionService {
  /// Pede permissão e retorna true se concedida.
  static Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  /// Retorna a lista de contatos do celular já com propriedades.
  /// Se não tiver permissão, retorna lista vazia.
  static Future<List<Contact>> getPhoneContacts() async {
    final granted = await requestPermission();
    if (!granted) return [];
    return FlutterContacts.getContacts(withProperties: true, withPhoto: false);
  }
}
