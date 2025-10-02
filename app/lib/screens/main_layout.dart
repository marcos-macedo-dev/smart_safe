import 'package:flutter/material.dart';
import 'sos_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'delegacia_screen.dart';
import 'emergency_contacts_screen_v2.dart';
import 'profile_screen.dart';
import '../services/api_service.dart';
import '../services/biometric_auth_service.dart';
import '../models/user.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  Widget _currentScreen = SosScreen();
  String _title = "SOS";
  bool _isLoadingUser = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    try {
      ApiService.initialize();
      _loadUser();
    } catch (e) {
      print('Erro na inicialização do MainLayout: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadUser() async {
    setState(() => _isLoadingUser = true);
    try {
      final user = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar usuário: $e');
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  void _selectScreen(Widget screen, String title) {
    if (!mounted) return;
    
    try {
      setState(() {
        _currentScreen = screen;
        _title = title;
      });
      Navigator.pop(context);
    } catch (e) {
      print('Erro ao selecionar tela: $e');
    }
  }

  void _showLogoutDialog() {
    if (!mounted) return;
    
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sair da conta'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                BiometricAuthService().saveBiometricPreference(false);
                ApiService.logout().then(
                  (_) => Navigator.pushReplacementNamed(context, '/login'),
                ).catchError((e) {
                  print('Erro ao fazer logout: $e');
                  Navigator.pushReplacementNamed(context, '/login');
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erro ao mostrar diálogo de logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary.withOpacity(0.02),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        title: Text(
          _title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: theme.colorScheme.onSurface,
              size: 22,
            ),
            onPressed: () {
              try {
                Scaffold.of(context).openDrawer();
              } catch (e) {
                print('Erro ao abrir drawer: $e');
              }
            },
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } catch (e) {
                print('Erro ao navegar para perfil: $e');
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _isLoadingUser
                        ? '?'
                        : (_user?.nome_completo.isNotEmpty == true
                              ? _user!.nome_completo[0].toUpperCase()
                              : '?'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _drawer(theme),
      body: _isLoadingUser
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _currentScreen,
            ),
    );
  }

  Drawer _drawer(ThemeData theme) {
    return Drawer(
      width: 280,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header do drawer (com logotipo, título e slogan)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Coluna 1: Logotipo (1 linha)
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shield_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Coluna 2: Título e slogan (2 linhas)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Smart Safe",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "A segurança na palma da sua mão",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Divisor
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
            // Divisor
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildMenuSection(
                    title: 'NAVEGAÇÃO',
                    theme: theme,
                    items: [
                      _MenuItem(
                        icon: Icons.shield_outlined,
                        activeIcon: Icons.shield,
                        title: 'SOS',
                        screen: SosScreen(),
                      ),
                      _MenuItem(
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history,
                        title: 'Histórico',
                        screen: HistoryScreen(),
                      ),
                      _MenuItem(
                        icon: Icons.contacts_outlined,
                        activeIcon: Icons.contacts,
                        title: 'Contatos de Emergência',
                        screen: EmergencyContactsScreenV2(),
                      ),
                      _MenuItem(
                        icon: Icons.local_police_outlined,
                        activeIcon: Icons.local_police,
                        title: 'Delegacias',
                        screen: DelegaciaScreen(),
                      ),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        title: 'Configurações',
                        screen: SettingsScreen(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMenuSection(
                    title: 'CONTA',
                    theme: theme,
                    items: [
                      _MenuItem(
                        icon: Icons.swap_horiz_outlined,
                        activeIcon: Icons.swap_horiz,
                        title: 'Trocar de Conta',
                        isSpecial: true,
                        onTap: () {
                          try {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/login');
                          } catch (e) {
                            print('Erro ao trocar de conta: $e');
                          }
                        },
                      ),
                      _MenuItem(
                        icon: Icons.logout,
                        activeIcon: Icons.logout,
                        title: 'Sair',
                        isSpecial: true,
                        onTap: () {
                          try {
                            Navigator.pop(context);
                            _showLogoutDialog();
                          } catch (e) {
                            print('Erro ao sair: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Smart Safe v1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required ThemeData theme,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...items.map((item) => _buildMenuItem(item, theme)),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item, ThemeData theme) {
    final isSelected = _title == item.title;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          isSelected ? item.activeIcon : item.icon,
          size: 22,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
        onTap:
            item.onTap ??
            () {
              try {
                if (item.screen != null) {
                  _selectScreen(item.screen!, item.title);
                }
              } catch (e) {
                print('Erro ao tocar no item do menu: $e');
              }
            },
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final Widget? screen;
  final VoidCallback? onTap;
  final bool isSpecial;

  _MenuItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    this.screen,
    this.onTap,
    this.isSpecial = false,
  });
}
