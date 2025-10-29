import '../models/emergency_contact.dart';
import 'api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/database_helper.dart';
import '../models/contact_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EmergencyContactService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  EmergencyContactService(this._apiService);

  Future<int?> _getUserId() async {
    String? userIdString = await _secureStorage.read(key: 'userId');
    return userIdString != null ? int.tryParse(userIdString) : null;
  }

  Future<bool> _isOnline() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);
  }

  Future<List<EmergencyContact>> getContacts() async {
    List<EmergencyContact> contacts = [];
    bool online = await _isOnline();
    final currentUserId = await _getUserId();

    if (online) {
      try {
        if (currentUserId == null) {
          return [];
        }
        final response = await _apiService.get(
          '/contacts?usuario_id=$currentUserId',
        );
        if (response.statusCode == 200) {
          contacts = (response.data as List)
              .map((json) => EmergencyContact.fromJson(json))
              .toList();
          // Update local database with fresh data from API
          for (var contact in contacts) {
            final existingContacts = await _databaseHelper.getContacts();
            final existingContact = existingContacts.firstWhere(
              (c) => c.id == contact.id,
              orElse: () => ContactLocal(name: '', phone: ''),
            );

            if (existingContact.id != null) {
              await _databaseHelper.updateContact(
                ContactLocal(
                  id: contact.id,
                  name: contact.nome,
                  phone: contact.telefone,
                  email: contact.email,
                  parentesco: contact.parentesco,
                  isSynced: true,
                ),
              );
            } else {
              await _databaseHelper.insertContact(
                ContactLocal(
                  id: contact.id,
                  name: contact.nome,
                  phone: contact.telefone,
                  email: contact.email,
                  parentesco: contact.parentesco,
                  isSynced: true,
                ),
              );
            }
          }
          _syncContacts(); // Attempt to sync any pending local changes
        }
      } catch (e) {
        print('Erro ao buscar contatos da API, tentando localmente: $e');
      }
    }

    // Always try to get from local database
    final localContacts = await _databaseHelper.getContacts();
    // Convert ContactLocal to EmergencyContact
    contacts = localContacts
        .map(
          (c) => EmergencyContact(
            id: c.id,
            nome: c.name,
            telefone: c.phone,
            email: c.email,
            parentesco: c.parentesco,
            usuarioId: currentUserId ?? 0, // Use actual userId if available
          ),
        )
        .toList();

    return contacts;
  }

  Future<EmergencyContact?> addContact(EmergencyContact contact) async {
    // Save to local database first
    ContactLocal newLocalContact = ContactLocal(
      name: contact.nome,
      phone: contact.telefone,
      email: contact.email,
      parentesco: contact.parentesco,
      isSynced: false,
    );
    int localId = await _databaseHelper.insertContact(newLocalContact);
    newLocalContact.id = localId; // Update local contact with its generated ID

    bool online = await _isOnline();
    if (online) {
      try {
        final usuarioId = await _getUserId();
        if (usuarioId == null) {
          // TODO: Tratar erro: usuarioId não encontrado
          return null;
        }
        final response = await _apiService.post(
          '/contacts',
          data: contact.toJson()..['usuario_id'] = usuarioId,
        );
        if (response.statusCode == 201) {
          EmergencyContact apiContact = EmergencyContact.fromJson(
            response.data,
          );
          // Update local contact with API ID and mark as synced
          newLocalContact.id = apiContact.id; // Use API's ID
          newLocalContact.isSynced = true;
          await _databaseHelper.updateContact(newLocalContact);
          return apiContact;
        }
      } catch (e) {
        print('Erro ao adicionar contato na API, mantendo localmente: $e');
      }
    }
    // If offline or API call failed, return the locally saved contact
    return EmergencyContact(
      id: newLocalContact.id,
      nome: newLocalContact.name,
      telefone: newLocalContact.phone,
      email: newLocalContact.email,
      parentesco: newLocalContact.parentesco,
      usuarioId: contact
          .usuarioId, // Use the original usuarioId from the passed contact
    );
  }

  Future<EmergencyContact?> updateContact(EmergencyContact contact) async {
    // Update local database first
    ContactLocal updatedLocalContact = ContactLocal(
      id: contact.id,
      name: contact.nome,
      phone: contact.telefone,
      email: contact.email,
      parentesco: contact.parentesco,
      isSynced: false, // Mark as unsynced
    );
    await _databaseHelper.updateContact(updatedLocalContact);

    bool online = await _isOnline();
    if (online) {
      try {
        final response = await _apiService.put(
          '/contacts/${contact.id}',
          data: contact.toJson(),
        );
        if (response.statusCode == 200) {
          EmergencyContact apiContact = EmergencyContact.fromJson(
            response.data,
          );
          // Mark as synced
          updatedLocalContact.isSynced = true;
          await _databaseHelper.updateContact(updatedLocalContact);
          return apiContact;
        }
      } catch (e) {
        print('Erro ao atualizar contato na API, mantendo localmente: $e');
      }
    }
    // If offline or API call failed, return the locally updated contact
    return EmergencyContact(
      id: updatedLocalContact.id,
      nome: updatedLocalContact.name,
      telefone: updatedLocalContact.phone,
      email: updatedLocalContact.email,
      parentesco: updatedLocalContact.parentesco,
      usuarioId: contact
          .usuarioId, // Use the original usuarioId from the passed contact
    );
  }

  Future<bool> deleteContact(int id) async {
    // Delete from local database first
    await _databaseHelper.deleteContact(id);

    bool online = await _isOnline();
    if (online) {
      try {
        final response = await _apiService.delete('/contacts/$id');
        return response.statusCode == 204; // No Content
      } catch (e) {
        print('Erro ao deletar contato na API, deletado localmente: $e');
        return false;
      }
    }
    return true; // Assume success if offline, will be synced later (or not if API delete fails)
  }

  Future<void> _syncContacts() async {
    bool online = await _isOnline();
    if (!online) return; // Only sync if online

    final unsyncedContacts = (await _databaseHelper.getContacts())
        .where((c) => !c.isSynced)
        .toList();

    for (var localContact in unsyncedContacts) {
      try {
        final usuarioId = await _getUserId();
        if (usuarioId == null) continue; // Skip if user ID not found

        EmergencyContact contactToSync = EmergencyContact(
          id: localContact.id,
          nome: localContact.name,
          telefone: localContact.phone,
          email: localContact.email,
          parentesco: localContact.parentesco,
          usuarioId: usuarioId,
        );

        if (localContact.id == null) {
          // This is a new contact that was added offline
          final response = await _apiService.post(
            '/contacts',
            data: contactToSync.toJson()..['usuario_id'] = usuarioId,
          );
          if (response.statusCode == 201) {
            EmergencyContact apiContact = EmergencyContact.fromJson(
              response.data,
            );
            // Update local contact with API ID and mark as synced
            localContact.id = apiContact.id;
            localContact.isSynced = true;
            await _databaseHelper.updateContact(localContact);
          }
        } else {
          // This is an existing contact that was updated offline
          final response = await _apiService.put(
            '/contacts/${localContact.id}',
            data: contactToSync.toJson(),
          );
          if (response.statusCode == 200) {
            localContact.isSynced = true;
            await _databaseHelper.updateContact(localContact);
          }
        }
      } catch (e) {
        print('Erro ao sincronizar contato ${localContact.name}: $e');
        // Keep isSynced = false so it's retried later
      }
    }
  }

  Future<List<EmergencyContact>> getContactsFiltered({
    String? relationship,
  }) async {
    final allContacts = await getContacts();
    if (relationship == null) {
      return allContacts;
    }
    return allContacts
        .where(
          (contact) =>
              contact.parentesco == relationship ||
              (relationship == 'Sem parentesco' && contact.parentesco == null),
        )
        .toList();
  }

  /// Retorna lista de relacionamentos únicos disponíveis nos contatos
  Future<List<String>> getAvailableRelationships() async {
    final contacts = await getContacts();
    final relationships = contacts
        .map((contact) => contact.parentesco)
        .where((relationship) => relationship != null)
        .cast<String>()
        .toSet()
        .toList();
    relationships.sort();
    return relationships;
  }
}
