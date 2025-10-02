import 'package:flutter/material.dart';

class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  bool _isSyncing = false;
  int _pendingItems = 0;

  // TODO: Implementar lógica real para monitorar status de sincronização
  // Esta é uma implementação de exemplo que precisa ser conectada ao AdvancedSyncService

  @override
  void initState() {
    super.initState();
    // Iniciar monitoramento do status de sincronização
    _startMonitoring();
  }

  void _startMonitoring() {
    // TODO: Conectar com o AdvancedSyncService para obter status real
    // Por enquanto, simulando com um timer
    // Timer.periodic(const Duration(seconds: 5), (timer) {
    //   if (mounted) {
    //     setState(() {
    //       _isSyncing = !_isSyncing;
    //       _pendingItems = _isSyncing ? 0 : 3;
    //     });
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingItems == 0 && !_isSyncing) {
      return const SizedBox.shrink();
    }

    return Container(
      color: _isSyncing ? Colors.blue.shade100 : Colors.orange.shade100,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (_isSyncing) ...[
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
          ] else ...[
            const Icon(
              Icons.sync_problem,
              color: Colors.orange,
              size: 16,
            ),
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
              onPressed: () {
                // TODO: Forçar sincronização
              },
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
    );
  }
}