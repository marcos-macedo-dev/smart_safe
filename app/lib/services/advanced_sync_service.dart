import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/advanced_local_database.dart';
import 'api_service.dart';
import '../models/sos_record.dart';
import '../models/emergency_contact.dart';
import '../models/user.dart';
import '../models/delegacia.dart';

enum SyncStatus { idle, syncing, error }

class AdvancedSyncService {
  static final AdvancedSyncService _instance = AdvancedSyncService._internal();
  factory AdvancedSyncService() => _instance;
  AdvancedSyncService._internal();

  final AdvancedLocalDatabase _localDatabase = AdvancedLocalDatabase();
  final ApiService _apiService = ApiService();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Stream para notificar mudanças de status
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  // Status atual
  SyncStatus _currentStatus = SyncStatus.idle;

  SyncStatus get currentStatus => _currentStatus;

  void initialize() {
    // Monitorar conectividade
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _triggerSync();
      }
    });

    // Sincronização periódica otimizada (a cada 2 minutos para ser mais responsivo)
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _triggerSync();
    });

    // Sincronização inicial
    _triggerSync();
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _syncTimer?.cancel();
    _statusController.close();
  }

  void _triggerSync() async {
    // Verificar conectividade antes de sincronizar
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _updateStatus(SyncStatus.idle);
      return;
    }

    // Não iniciar nova sincronização se já estiver em andamento
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);
    try {
      // Sincronizar itens pendentes com prioridade (SOSs primeiro)
      await _syncPendingItems();

      // Sincronizar dados em paralelo para maior velocidade
      await Future.wait([_syncUserData(), _syncDelegacias()]).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Timeout na sincronização de dados secundários');
          return [];
        },
      );

      _updateStatus(SyncStatus.idle);
    } catch (e) {
      print('Erro durante sincronização: $e');
      _updateStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<void> _syncPendingItems() async {
    final unsyncedItems = await _localDatabase.getUnsyncedItems();

    // Separar SOSs de outros itens para priorização
    final sosItems = unsyncedItems
        .where((item) => item['entity_type'] == 'sos')
        .toList();
    final otherItems = unsyncedItems
        .where((item) => item['entity_type'] != 'sos')
        .toList();

    // Processar SOSs primeiro (críticos)
    await _processSyncItems(sosItems);

    // Processar outros itens em paralelo (não críticos)
    if (otherItems.isNotEmpty) {
      // Dividir em lotes de 5 para processamento paralelo
      for (int i = 0; i < otherItems.length; i += 5) {
        final batch = otherItems.skip(i).take(5).toList();
        await Future.wait(
          batch.map((item) => _processSingleItem(item)),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('Timeout no batch de sincronização');
            return [];
          },
        );
      }
    }
  }

  Future<void> _processSyncItems(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      await _processSingleItem(item);
    }
  }

  Future<void> _processSingleItem(Map<String, dynamic> item) async {
    try {
      final id = item['id'] as int;
      final entityType = item['entity_type'] as String;
      final entityId = item['entity_id'] as int;
      final operation = item['operation'] as String;
      final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

      bool success = false;

      switch (entityType) {
        case 'sos':
          success = await _syncSosItem(entityId, operation, data).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Timeout ao sincronizar SOS $entityId');
              return false;
            },
          );
          break;
        case 'contact':
          success = await _syncContactItem(entityId, operation, data).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Timeout ao sincronizar contato $entityId');
              return false;
            },
          );
          break;
        default:
          // Entidade não reconhecida, marcar como sincronizada para evitar loop
          await _localDatabase.markItemAsSynced(id);
          return;
      }

      if (success) {
        await _localDatabase.markItemAsSynced(id);
      } else {
        // Incrementar contador de tentativas
        final retryCount = await _localDatabase.incrementRetryCount(id);
        // Se falhar muitas vezes, marcar como erro (após 3 tentativas para ser mais agressivo)
        if (retryCount > 3) {
          print('Item $id falhou após 3 tentativas: $entityType $operation');
        }
      }
    } catch (e) {
      print('Erro ao sincronizar item ${item['id']}: $e');
    }
  }

  Future<bool> _syncSosItem(
    int entityId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (operation) {
        case 'create':
          final response = await _apiService.post('/sos', data: data);
          if (response.statusCode == 201) {
            // Atualizar o ID local com o ID do servidor
            final serverSos = SosRecord.fromJson(response.data);
            // Atualizar o registro local com o ID do servidor
            await _localDatabase.updateSosRecord(serverSos);
            return true;
          }
          return false;
        case 'update':
          final response = await _apiService.put('/sos/$entityId', data: data);
          return response.statusCode == 200;
        case 'delete':
          final response = await _apiService.delete('/sos/$entityId');
          return response.statusCode == 204;
        default:
          return false;
      }
    } catch (e) {
      print('Erro ao sincronizar SOS $entityId: $e');
      return false;
    }
  }

  Future<bool> _syncContactItem(
    int entityId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (operation) {
        case 'create':
          final response = await _apiService.post('/contacts', data: data);
          if (response.statusCode == 201) {
            // Atualizar o ID local com o ID do servidor
            final serverContact = EmergencyContact.fromJson(response.data);
            // Atualizar o registro local com o ID do servidor
            await _localDatabase.updateEmergencyContact(serverContact);
            // Marcar como sincronizado
            await _localDatabase.markEmergencyContactAsSynced(
              serverContact.id!,
            );
            return true;
          }
          return false;
        case 'update':
          final response = await _apiService.put(
            '/contacts/$entityId',
            data: data,
          );
          if (response.statusCode == 200) {
            // Marcar como sincronizado
            await _localDatabase.markEmergencyContactAsSynced(entityId);
            return true;
          }
          return false;
        case 'delete':
          final response = await _apiService.delete('/contacts/$entityId');
          return response.statusCode == 204;
        default:
          return false;
      }
    } catch (e) {
      print('Erro ao sincronizar contato $entityId: $e');
      return false;
    }
  }

  Future<void> _syncUserData() async {
    try {
      // Sincronizar perfil do usuário
      final userResponse = await _apiService.get('/users/me');
      if (userResponse.statusCode == 200) {
        // Atualizar dados locais do usuário
        final user = User.fromJson(userResponse.data);
        await _localDatabase.updateUser(user);
      }
    } catch (e) {
      print('Erro ao sincronizar dados do usuário: $e');
    }
  }

  Future<void> _syncDelegacias() async {
    try {
      // Sincronizar lista de delegacias (dados estáticos)
      final delegacias = await ApiService.getDelegacias();
      for (final delegacia in delegacias) {
        await _localDatabase.updateDelegacia(delegacia);
      }
    } catch (e) {
      print('Erro ao sincronizar delegacias: $e');
    }
  }

  // Métodos públicos para adicionar itens à fila de sincronização
  Future<void> queueSosSync(SosRecord sos, String operation) async {
    await _localDatabase.addToSyncQueue(
      entityType: 'sos',
      entityId: sos.id,
      operation: operation,
      data: sos.toJson(),
    );
    _triggerSync(); // Tentar sincronizar imediatamente
  }

  Future<void> queueContactSync(
    EmergencyContact contact,
    String operation,
  ) async {
    await _localDatabase.addToSyncQueue(
      entityType: 'contact',
      entityId: contact.id ?? 0,
      operation: operation,
      data: contact.toJson(),
    );
    _triggerSync(); // Tentar sincronizar imediatamente
  }

  Future<int> getPendingItemsCount() async {
    try {
      final unsyncedItems = await _localDatabase.getUnsyncedItems();
      return unsyncedItems.length;
    } catch (e) {
      print('Erro ao contar itens pendentes: $e');
      return 0;
    }
  }

  Future<void> forceSync() async {
    _triggerSync();
  }
}
