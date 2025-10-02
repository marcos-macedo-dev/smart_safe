
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  final LocalAuthentication auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_auth_enabled';

  /// Verifica se a autenticação biométrica está disponível e configurada no dispositivo.
  Future<bool> canAuthenticate() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      print('BiometricAuthService: canCheckBiometrics: $canCheckBiometrics');
      if (!canCheckBiometrics) return false; // Nenhum hardware biométrico

      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      print('BiometricAuthService: availableBiometrics: $availableBiometrics');

      // Se canCheckBiometrics for true e houver qualquer tipo de biometria disponível, então podemos autenticar.
      return availableBiometrics.isNotEmpty;

    } catch (e) {
      print("BiometricAuthService: Erro ao verificar biometria: $e");
      return false;
    }
  }

  /// Tenta autenticar o usuário usando biometria.
  /// Retorna true se a autenticação for bem-sucedida, false caso contrário.
  Future<bool> authenticate() async {
    try {
      print('BiometricAuthService: Attempting to authenticate...');
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Por favor, autentique-se para acessar o aplicativo',
        options: const AuthenticationOptions(
          stickyAuth: true, // Mantém a autenticação ativa mesmo se o app for para o background
          biometricOnly: true, // Apenas biometria, sem fallback para PIN/padrão
        ),
      );
      print('BiometricAuthService: Authentication result: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print("BiometricAuthService: Erro durante a autenticação biométrica: $e");
      return false;
    }
  }

  /// Salva a preferência do usuário para usar autenticação biométrica.
  Future<void> saveBiometricPreference(bool enable) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enable);
    print('BiometricAuthService: Biometric preference saved: $enable');
  }

  /// Obtém a preferência do usuário para autenticação biométrica.
  Future<bool> getBiometricPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? preference = prefs.getBool(_biometricEnabledKey);
    print('BiometricAuthService: Biometric preference retrieved: $preference');
    return preference ?? false; // Padrão é falso
  }
}
