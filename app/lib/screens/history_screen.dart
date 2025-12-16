import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sos_record.dart';
import '../services/api_service.dart';
import '../services/sos_service.dart';
import '../utils/app_message.dart';
import 'sos_detail_screen.dart';
import 'sos_media_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  // Paleta institucional
  static const Color _violetaEscura = Color(0xFF311756);
  static const Color _violetaMedia = Color(0xFF401F56);

  // Tema dinâmico
  Color get cardColor => Theme.of(context).colorScheme.surface;
  Color get textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get accent {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF7C5CC3) : _violetaEscura;
  }

  Color get shadow {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Colors.black.withOpacity(isDark ? 0.35 : 0.08);
  }

  late final SosService _sosService;
  List<SosRecord> _sosRecords = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _sosService = SosService(ApiService());
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _loadSosRecords();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadSosRecords() async {
    setState(() => _isLoading = true);
    try {
      final fetchedRecords = await _sosService.getSosRecords();
      setState(() {
        _sosRecords = fetchedRecords;
      });
      _fadeController.forward();
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Erro ao carregar histórico de SOS: $e',
          type: AppMessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {AppMessageType type = AppMessageType.info}) {
    if (!mounted) return;
    AppMessage.show(context, message: msg, type: type);
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Agora';
    if (difference.inHours < 1) return '${difference.inMinutes} min atrás';
    if (difference.inDays < 1) return '${difference.inHours} h atrás';
    return '${difference.inDays} dia(s) atrás';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content
              _isLoading
                  ? _buildLoadingState(theme, colorScheme, textScaler)
                  : _sosRecords.isEmpty
                  ? _buildEmptyState(theme, colorScheme, textScaler)
                  : _buildHistoryList(theme, colorScheme, textScaler),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accent, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Carregando...',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: textScaler.scale(15),
              color: textMuted,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.5), width: 1),
                ),
                child: Icon(Icons.history_rounded, size: 40, color: accent),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhum registro encontrado',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  letterSpacing: -0.3,
                  fontSize: textScaler.scale(18),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Você ainda não criou nenhum SOS.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textScaler.scale(15),
                  color: textMuted,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loadSosRecords,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: accent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Atualizar',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: Colors.white,
                          fontSize: textScaler.scale(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadSosRecords,
        color: accent,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _sosRecords.length,
          itemBuilder: (context, index) {
            final record = _sosRecords[index];
            return _buildSosCard(record, theme, colorScheme, textScaler, index);
          },
        ),
      ),
    );
  }

  Widget _buildSosCard(
    SosRecord record,
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
    int index,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: index == _sosRecords.length - 1 ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do card
          _buildCardHeader(record, theme, colorScheme, textScaler),
          // Informações do SOS
          _buildCardInfo(record, theme, colorScheme, textScaler),
          // Ações
          _buildCardActions(record, theme, colorScheme, textScaler),
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    SosRecord record,
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    final bool highlightStatus = record.status == SosStatus.ativo;
    final Color chipBackground = highlightStatus
        ? accent
        : record.statusColor.withOpacity(0.1);
    final Color chipBorder = highlightStatus
        ? accent
        : record.statusColor.withOpacity(0.3);
    final Color chipContentColor = highlightStatus
        ? Colors.white
        : record.statusColor;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOS #${record.id}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                  fontSize: textScaler.scale(17),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _timeAgo(record.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: textScaler.scale(13),
                  color: textMuted,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: chipBorder, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(record.statusIcon, size: 14, color: chipContentColor),
                const SizedBox(width: 6),
                Text(
                  record.statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: textScaler.scale(11),
                    color: chipContentColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo(
    SosRecord record,
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.schedule_rounded,
            'Criado em',
            record.formattedCreatedAt,
            theme,
            colorScheme,
            textScaler,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.location_on_rounded,
            'Localização',
            '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
            theme,
            colorScheme,
            textScaler,
          ),
          if (record.fullCaminhoAudioUrl != null ||
              record.fullCaminhoVideoUrl != null) ...[
            const SizedBox(height: 8),
            _buildMediaRow(record, theme, colorScheme, textScaler),
          ],
          if (record.encerrado_em != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.check_circle_rounded,
              'Encerrado em',
              DateFormat('dd/MM/yyyy HH:mm').format(record.encerrado_em!),
              theme,
              colorScheme,
              textScaler,
            ),
          ],
          if (record.updatedAt != record.createdAt) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.update_rounded,
              'Atualizado em',
              DateFormat('dd/MM/yyyy HH:mm').format(record.updatedAt),
              theme,
              colorScheme,
              textScaler,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaRow(
    SosRecord record,
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.perm_media_rounded, size: 18, color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mídia',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (record.fullCaminhoAudioUrl != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded, size: 10, color: accent),
                          const SizedBox(width: 3),
                          Text(
                            'Áudio',
                            style: TextStyle(
                              fontSize: 9,
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (record.fullCaminhoAudioUrl != null &&
                      record.fullCaminhoVideoUrl != null)
                    const SizedBox(width: 6),
                  if (record.fullCaminhoVideoUrl != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Vídeo',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: textScaler.scale(12),
                  color: textMuted,
                  letterSpacing: -0.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textScaler.scale(14),
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardActions(
    SosRecord record,
    ThemeData theme,
    ColorScheme colorScheme,
    TextScaler textScaler,
  ) {
    final hasMedia =
        (record.fullCaminhoAudioUrl != null &&
            record.fullCaminhoAudioUrl!.isNotEmpty) ||
        (record.fullCaminhoVideoUrl != null &&
            record.fullCaminhoVideoUrl!.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          // Botão Ver Mapa
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SosDetailScreen(
                        latitude: record.latitude,
                        longitude: record.longitude,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Ver no mapa',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        fontSize: textScaler.scale(15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botão Ver Mídia (se disponível)
          if (hasMedia) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.play_circle_rounded,
                label: 'Ver mídia',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SosMediaScreen(record: record),
                    ),
                  );
                },
                isPrimary: false,
                theme: theme,
                colorScheme: colorScheme,
                textScaler: textScaler,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required TextScaler textScaler,
  }) {
    return SizedBox(
      height: 48,
      child: isPrimary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      fontSize: textScaler.scale(15),
                    ),
                  ),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                      fontSize: textScaler.scale(15),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
