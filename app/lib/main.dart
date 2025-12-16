import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Importações das telas
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/password_reset_success_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/root_screen.dart';

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

/// Callback para ações de interatividade do widget
@pragma('vm:entry-point')
/// Solicita permissões necessárias para o funcionamento do app
Future<void> _requestPermissions() async {
  await [Permission.locationWhenInUse, Permission.locationAlways].request();
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

/// Chave global do navigator para navegação programática
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF311756), // Violeta escura
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF401F56),
        onPrimaryContainer: Color(0xFFE1BEE7),
        secondary: Color(0xFF2BBBAD), // Verde secundário
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE0F2F1),
        onSecondaryContainer: Color(0xFF00695C),
        tertiary: Color(0xFF607D8B), // Cinza metálico
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFECEFF1),
        onTertiaryContainer: Color(0xFF37474F),
        error: Color(0xFFE53935), // Vermelho de alerta
        onError: Colors.white,
        errorContainer: Color(0xFFFFEBEE),
        onErrorContainer: Color(0xFFC62828),
        surface: Color(0xFFFAFAFA), // Fundo cinza claro
        onSurface: Color(0xFF1C1B1F), // Texto escuro
        surfaceContainerHighest: Color(0xFFFFFFFF), // Cards brancos
        onSurfaceVariant: Color(0xFF757575),
        outline: Color(0xFFE0E0E0),
        outlineVariant: Color(0xFFF5F5F5),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF1C1B1F),
        onInverseSurface: Color(0xFFFAFAFA),
        inversePrimary: Color(0xFFE1BEE7),
        surfaceTint: Color(0xFF311756),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Constrói o tema escuro da aplicação
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF311756), // Violeta escura mantida
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF401F56),
        onPrimaryContainer: Color(0xFFE1BEE7),
        secondary: Color(0xFF2BBBAD),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF00695C),
        onSecondaryContainer: Color(0xFFB2DFDB),
        tertiary: Color(0xFF90A4AE),
        onTertiary: Color(0xFF263238),
        tertiaryContainer: Color(0xFF37474F),
        onTertiaryContainer: Color(0xFFB0BEC5),
        error: Color(0xFFEF5350),
        onError: Color(0xFFB71C1C),
        errorContainer: Color(0xFFD32F2F),
        onErrorContainer: Color(0xFFFFCDD2),
        surface: Color(0xFF121212), // Fundo escuro
        onSurface: Color(0xFFE0E0E0), // Texto claro
        surfaceContainerHighest: Color(0xFF2C2C2C), // Cards escuros
        onSurfaceVariant: Color(0xFFBDBDBD),
        outline: Color(0xFF424242),
        outlineVariant: Color(0xFF616161),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE0E0E0),
        onInverseSurface: Color(0xFF121212),
        inversePrimary: Color(0xFF311756),
        surfaceTint: Color(0xFF311756),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Define as rotas da aplicação
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/login': (_) => const LoginScreen(),
      '/forgot-password': (_) => const ForgotPasswordScreen(),
      '/reset-password': (context) => ResetPasswordScreen(
        email:
            (ModalRoute.of(context)!.settings.arguments as Map)['email']
                as String,
        otp:
            (ModalRoute.of(context)!.settings.arguments as Map)['otp']
                as String,
      ),
      '/password-reset-success': (_) => const PasswordResetSuccessScreen(),
      '/change-password': (_) => const ChangePasswordScreen(),
    };
  }
}
