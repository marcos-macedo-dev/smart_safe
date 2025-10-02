import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sos_record.dart';
import '../services/api_service.dart';
import '../services/sos_service.dart';
import 'sos_detail_screen.dart';
import 'sos_media_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
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
      setState(() => _sosRecords = fetchedRecords);
      _fadeController.forward();
    } catch (e) {
      if (mounted) {
        _showMessage('Erro ao carregar histórico de SOS: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(theme)
                  : _sosRecords.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildHistoryList(theme),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 20),
          Text(
            'Carregando histórico...',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 60,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Nenhum registro encontrado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Você ainda não criou nenhum SOS.\nQuando criar, aparecerá aqui.',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _loadSosRecords,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    'Atualizar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadSosRecords,
        color: theme.colorScheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          itemCount: _sosRecords.length,
          itemBuilder: (context, index) {
            final record = _sosRecords[index];
            return _buildSosCard(record, theme, index);
          },
        ),
      ),
    );
  }

  Widget _buildSosCard(SosRecord record, ThemeData theme, int index) {
    return Container(
      margin: EdgeInsets.only(
        bottom: index == _sosRecords.length - 1 ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do card
          _buildCardHeader(record, theme),
          // Divider sutil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: theme.colorScheme.outline.withOpacity(0.1),
              thickness: 1,
            ),
          ),
          // Informações do SOS
          _buildCardInfo(record, theme),
          // Ações
          _buildCardActions(record, theme),
        ],
      ),
    );
  }

  Widget _buildCardHeader(SosRecord record, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOS #${record.id}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _timeAgo(record.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: record.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: record.statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(record.statusIcon, size: 14, color: record.statusColor),
                const SizedBox(width: 6),
                Text(
                  record.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: record.statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo(SosRecord record, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Data
          _buildInfoRow(
            Icons.schedule_rounded,
            'Criado em',
            record.formattedCreatedAt,
            theme,
          ),
          const SizedBox(height: 12),
          // Localização
          _buildInfoRow(
            Icons.location_on_rounded,
            'Localização',
            '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
            theme,
          ),
          // Encerramento
          if (record.encerrado_em != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.check_circle_rounded,
              'Encerrado em',
              DateFormat('dd/MM/yyyy HH:mm').format(record.encerrado_em!),
              theme,
            ),
          ],
          // Última atualização
          if (record.updatedAt != record.createdAt) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.update_rounded,
              'Atualizado em',
              DateFormat('dd/MM/yyyy HH:mm').format(record.updatedAt),
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardActions(SosRecord record, ThemeData theme) {
    final hasMedia =
        (record.fullCaminhoAudioUrl != null &&
            record.fullCaminhoAudioUrl!.isNotEmpty) ||
        (record.fullCaminhoVideoUrl != null &&
            record.fullCaminhoVideoUrl!.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // Botão Ver Mapa
          Expanded(
            child: _buildActionButton(
              icon: Icons.map_rounded,
              label: 'Ver no mapa',
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
              isPrimary: true,
              theme: theme,
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
  }) {
    return SizedBox(
      height: 44,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                foregroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}
