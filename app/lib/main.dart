import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Importações das telas
import 'screens/root_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/password_reset_success_screen.dart';
import 'screens/change_password_screen.dart';

// Importações dos serviços e providers
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';
import 'services/advanced_sync_service.dart';

/// Ponto de entrada da aplicação Smart Safe
void main() async {
  // Garante que os bindings do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Solicita permissões necessárias
  await _requestPermissions();
  
  // Inicializa o serviço de API
  ApiService.initialize();

  // Inicializa serviços de sincronização
  final syncService = await _initializeSyncServices();

  // Inicia a aplicação com os providers necessários
  _startApp(syncService);
}

/// Solicita permissões necessárias para o funcionamento do app
Future<void> _requestPermissions() async {
  await [
    Permission.locationWhenInUse,
    Permission.locationAlways,
  ].request();
}

/// Inicializa os serviços de sincronização
Future<SyncService> _initializeSyncServices() async {
  final apiService = ApiService();
  final syncService = SyncService(apiService);
  
  // Realiza sincronização inicial
  await syncService.startInitialSync();
  
  // Inicializa serviço avançado de sincronização
  AdvancedSyncService().initialize();
  
  return syncService;
}

/// Inicia a aplicação com os providers configurados
void _startApp(SyncService syncService) {
  runApp(
    MultiProvider(
      providers: [
        // Provider para gerenciamento de tema
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Provider para serviço de sincronização
        Provider<SyncService>.value(value: syncService),
      ],
      child: const MyApp(),
    ),
  );
}

/// Widget principal da aplicação
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Safe',
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const RootScreen(),
      routes: _buildRoutes(),
    );
  }

  /// Constrói o tema claro da aplicação
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blueGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
    );
  }

  /// Constrói o tema escuro da aplicação
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blueGrey,
      scaffoldBackgroundColor: Colors.black87,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Define as rotas da aplicação
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/login': (_) => const LoginScreen(),
      '/forgot-password': (_) => const ForgotPasswordScreen(),
      '/reset-password': (context) => ResetPasswordScreen(
            email: (ModalRoute.of(context)!.settings.arguments as Map)['email'] as String,
            otp: (ModalRoute.of(context)!.settings.arguments as Map)['otp'] as String,
          ),
      '/password-reset-success': (_) => const PasswordResetSuccessScreen(),
      '/change-password': (_) => const ChangePasswordScreen(),
    };
  }
}