import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFF7C5CC3);
    final cardColor = colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;
    final shadow = Colors.black.withOpacity(isDark ? 0.35 : 0.08);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: accent,
      body: Stack(
        children: [
          // --- Parte Superior: Branding ---
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Minimalista Branco
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.shield,
                      size: 72,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Smart Safe',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),

          // --- Parte Inferior: Ações (Sheet) ---
          Align(
            alignment: Alignment.bottomCenter,
            child:
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(32, 40, 32, 24 + bottomPadding),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadow,
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Ocupa só o espaço necessário
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bem-vindo(a)',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fade(delay: 400.ms),

                      const SizedBox(height: 12),

                      Text(
                        'Proteção inteligente para você e sua família em qualquer lugar.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: textMuted,
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                      ).animate().fade(delay: 500.ms),

                      const SizedBox(height: 40),

                      // Botão Primário (Login)
                      SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Entrar na minha conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fade(delay: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // Botão Secundário (Registro)
                      SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(
                                  color: accent.withOpacity(0.35),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Criar nova conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fade(delay: 700.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 24),
                    ],
                  ),
                ).animate().slideY(
                  begin: 1.0,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutQuart,
                ),
          ),
        ],
      ),
    );
  }
}
