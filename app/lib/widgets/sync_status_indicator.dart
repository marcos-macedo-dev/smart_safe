import 'package:flutter/material.dart';
import 'dart:async';
import '../services/advanced_sync_service.dart';

class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  late final AdvancedSyncService _syncService;
  SyncStatus _currentStatus = SyncStatus.idle;
  int _pendingItems = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _syncService = AdvancedSyncService();
    _loadPendingItems();
    _syncService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
        // Recarregar contagem quando terminar sincronização (com debounce)
        if (status == SyncStatus.idle) {
          _debouncedLoadPendingItems();
        }
      }
    });
  }

  void _debouncedLoadPendingItems() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadPendingItems();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPendingItems() async {
    try {
      final count = await _syncService.getPendingItemsCount();
      if (mounted) {
        setState(() {
          _pendingItems = count;
        });
      }
    } catch (e) {
      print('Erro ao carregar itens pendentes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSyncing = _currentStatus == SyncStatus.syncing;
    final hasError = _currentStatus == SyncStatus.error;

    if (_pendingItems == 0 && !isSyncing && !hasError) {
      return const SizedBox.shrink();
    }

    final topPadding = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Container(
        color: isSyncing
            ? Colors.blue.shade100
            : hasError
            ? Colors.red.shade100
            : Colors.orange.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            if (isSyncing) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sincronizando dados...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (hasError) ...[
              const Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Erro na sincronização',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _syncService.forceSync,
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              const Icon(Icons.sync_problem, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text(
                '$_pendingItems itens aguardando sincronização',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _syncService.forceSync,
                child: const Text(
                  'Sincronizar agora',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
