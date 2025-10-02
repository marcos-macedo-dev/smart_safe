import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOnline = results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi);
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.orange.shade100,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          const Text(
            'Modo offline - seus dados serão sincronizados quando a conexão for restabelecida',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16, color: Colors.orange),
            onPressed: _checkConnectivity,
          ),
        ],
      ),
    );
  }
}