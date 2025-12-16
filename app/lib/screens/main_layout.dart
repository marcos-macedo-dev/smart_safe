import 'package:app/screens/emergency_contacts_screen.dart';
import 'package:app/screens/sos_screen.dart';
import 'package:flutter/material.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'delegacia_screen.dart';
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
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Sair da conta'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                BiometricAuthService().saveBiometricPreference(false);
                ApiService.logout()
                    .then(
                      (_) => Navigator.pushReplacementNamed(context, '/login'),
                    )
                    .catchError((e) {
                      print('Erro ao fazer logout: $e');
                      Navigator.pushReplacementNamed(context, '/login');
                      return null;
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
    final bool isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFF7C5CC3);
    final cardColor = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;
    final textMuted = theme.colorScheme.onSurfaceVariant;
    final shadow = Colors.black.withOpacity(isDark ? 0.35 : 0.08);

    return Scaffold(
      backgroundColor: cardColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                _title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              centerTitle: true,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: accent, size: 24),
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
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    } catch (e) {
                      print('Erro ao navegar para perfil: $e');
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C5CC3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isLoadingUser
                              ? '?'
                              : (_user?.nome_completo.isNotEmpty == true
                                    ? _user!.nome_completo[0].toUpperCase()
                                    : '?'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: _drawer(theme, accent, cardColor, textPrimary, textMuted, shadow),
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

  Drawer _drawer(
    ThemeData theme,
    Color accent,
    Color cardColor,
    Color textPrimary,
    Color textMuted,
    Color shadow,
  ) {
    return Drawer(
      width: 240,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header do drawer (simplificado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_rounded, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Smart Safe",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuSection(
                    title: 'NAVEGAÇÃO',
                    theme: theme,
                    accent: accent,
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    shadow: shadow,
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
                        screen: EmergencyContactsScreen(),
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
                  const SizedBox(height: 12),
                  _buildMenuSection(
                    title: 'CONTA',
                    theme: theme,
                    accent: accent,
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    shadow: shadow,
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
            // Footer simplificado
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'V 1.0.0 Beta',
                style: TextStyle(
                  fontSize: 11,
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
    required Color accent,
    required Color cardColor,
    required Color textPrimary,
    required Color textMuted,
    required Color shadow,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map(
          (item) => _buildMenuItem(
            item,
            theme,
            accent,
            cardColor,
            textPrimary,
            textMuted,
            shadow,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    _MenuItem item,
    ThemeData theme,
    Color accent,
    Color cardColor,
    Color textPrimary,
    Color textMuted,
    Color shadow,
  ) {
    final isSelected = _title == item.title;
    final Color iconColor = isSelected
        ? Colors.white
        : textPrimary.withOpacity(item.isSpecial ? 0.9 : 0.7);
    final Color textColor = isSelected
        ? Colors.white
        : textPrimary.withOpacity(item.isSpecial ? 0.9 : 0.8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? accent : cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: isSelected ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        dense: false,
        leading: Icon(
          isSelected ? item.activeIcon : item.icon,
          size: 22,
          color: iconColor,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
          ),
        ),
        selected: isSelected,
        selectedColor: Colors.white,
        selectedTileColor: Colors.transparent,
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
