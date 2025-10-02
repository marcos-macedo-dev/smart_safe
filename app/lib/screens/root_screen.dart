import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'main_layout.dart';
import '../services/biometric_auth_service.dart';
import '../services/api_service.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/sync_status_indicator.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final _storage = const FlutterSecureStorage();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final token = await _storage.read(key: 'token');
      if (!mounted) return;

      if (token != null) {
        // Se um token existir, o usuário deve sempre autenticar novamente.
        // Navegue para a tela de login, que lidará com a lógica de biometria/senha.
        _navigateToLogin();
      } else {
        // Nenhum token, o usuário precisa fazer login ou se registrar.
        _navigateToWelcome();
      }
    } catch (e) {
      print('Erro ao verificar status de login: $e');
      if (mounted) {
        _navigateToWelcome();
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayoutWithIndicators()),
    );
  }

  void _navigateToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// Novo widget que inclui os indicadores de status
class MainLayoutWithIndicators extends StatelessWidget {
  const MainLayoutWithIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        OfflineIndicator(),
        SyncStatusIndicator(),
        Expanded(child: MainLayout()),
      ],
    );
  }
}