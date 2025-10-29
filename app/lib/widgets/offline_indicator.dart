import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/local_database.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  int _pendingItems = 0;
  bool _isExpanded = false;

  final LocalDatabase _localDatabase = LocalDatabase();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadPendingItems();
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        final wasOnline = _isOnline;
        setState(() {
          _isOnline =
              results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi);
        });
        // Se voltou online, recarregar itens pendentes
        if (!wasOnline && _isOnline) {
          _loadPendingItems();
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline =
            connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi);
      });
    }
  }

  Future<void> _loadPendingItems() async {
    try {
      final pendingSos = await _localDatabase.getUnsyncedSosRecords();
      if (mounted) {
        setState(() {
          _pendingItems = pendingSos.length;
        });
      }
    } catch (e) {
      print('Erro ao carregar itens pendentes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && _pendingItems == 0) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isOnline ? Colors.blue.shade600 : Colors.orange.shade600,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isOnline ? Icons.cloud_done : Icons.cloud_off,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isOnline
                              ? (_pendingItems > 0
                                    ? '$_pendingItems item(s) aguardando sincronização'
                                    : 'Conectado - dados sincronizados')
                              : 'Modo offline - funcionalidade limitada',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'Status: Conectado' : 'Status: Offline',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isOnline
                                ? '• SOS enviados diretamente\n• Sincronização automática\n• Todos os recursos disponíveis'
                                : '• SOS salvos localmente\n• Sincronização pendente\n• Recursos limitados',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          if (_pendingItems > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Itens pendentes: $_pendingItems',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
