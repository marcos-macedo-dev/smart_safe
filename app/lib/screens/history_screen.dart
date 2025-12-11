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

  late final SosService _sosService;
  List<SosRecord> _sosRecords = [];
  List<SosRecord> _filteredRecords = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  SosStatus? _selectedFilter;

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
        _applyFilter();
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

  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredRecords = _sosRecords;
    } else {
      _filteredRecords = _sosRecords
          .where((record) => record.status == _selectedFilter)
          .toList();
    }
  }

  void _setFilter(SosStatus? status) {
    setState(() {
      _selectedFilter = status;
      _applyFilter();
    });
  }

  void _showMessage(String msg, {AppMessageType type = AppMessageType.info}) {
    if (!mounted) return;
    AppMessage.show(context, message: msg, type: type);
  }

  String _getStatusText(SosStatus status) {
    switch (status) {
      case SosStatus.pendente:
        return 'Pendente';
      case SosStatus.ativo:
        return 'Ativo';
      case SosStatus.aguardando_autoridade:
        return 'Aguardando Autoridade';
      case SosStatus.fechado:
        return 'Fechado';
      case SosStatus.cancelado:
        return 'Cancelado';
    }
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
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedFilter != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _violetaEscura,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _violetaEscura, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusText(_selectedFilter!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: textScaler.scale(12),
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _setFilter(null),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          PopupMenuButton<SosStatus?>(
            onSelected: _setFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              ...SosStatus.values.map((status) {
                final dummyRecord = SosRecord(
                  id: 0,
                  usuario_id: 0,
                  caminho_audio: null,
                  latitude: 0,
                  longitude: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  status: status,
                );
                return PopupMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        dummyRecord.statusIcon,
                        size: 16,
                        color: dummyRecord.statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(_getStatusText(status)),
                    ],
                  ),
                );
              }),
            ],
            icon: Icon(
              Icons.filter_list_rounded,
              color: _selectedFilter != null
                  ? _violetaEscura
                  : colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Content
              _isLoading
                  ? _buildLoadingState(theme, colorScheme, textScaler)
                  : _filteredRecords.isEmpty
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
          CircularProgressIndicator(color: _violetaEscura, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Carregando...',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: textScaler.scale(15),
              color: colorScheme.onSurfaceVariant,
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
    final hasFilter = _selectedFilter != null;
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
                  color: _violetaEscura.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _violetaEscura.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Icon(
                  hasFilter ? Icons.filter_list_rounded : Icons.history_rounded,
                  size: 40,
                  color: _violetaEscura,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasFilter
                    ? 'Nenhum SOS encontrado'
                    : 'Nenhum registro encontrado',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                  fontSize: textScaler.scale(18),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasFilter
                    ? 'Não há SOS com o status selecionado.'
                    : 'Você ainda não criou nenhum SOS.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textScaler.scale(15),
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: hasFilter
                      ? () => _setFilter(null)
                      : _loadSosRecords,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: _violetaEscura,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasFilter
                            ? Icons.filter_list_off_rounded
                            : Icons.refresh_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasFilter ? 'Remover filtro' : 'Atualizar',
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
        color: _violetaEscura,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _filteredRecords.length,
          itemBuilder: (context, index) {
            final record = _filteredRecords[index];
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
        bottom: index == _filteredRecords.length - 1 ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do card
          _buildCardHeader(record, theme, colorScheme, textScaler),
          // Divider sutil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: colorScheme.outline.withOpacity(0.2),
              thickness: 1,
              height: 1,
            ),
          ),
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
        ? _violetaEscura
        : record.statusColor.withOpacity(0.1);
    final Color chipBorder = highlightStatus
        ? _violetaEscura
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
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                  fontSize: textScaler.scale(16),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _timeAgo(record.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: textScaler.scale(12),
                  color: colorScheme.onSurfaceVariant,
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
          // Data
          _buildInfoRow(
            Icons.schedule_rounded,
            'Criado em',
            record.formattedCreatedAt,
            theme,
            colorScheme,
            textScaler,
          ),
          const SizedBox(height: 8),
          // Localização
          _buildInfoRow(
            Icons.location_on_rounded,
            'Localização',
            '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
            theme,
            colorScheme,
            textScaler,
          ),
          // Mídia
          if (record.fullCaminhoAudioUrl != null ||
              record.fullCaminhoVideoUrl != null) ...[
            const SizedBox(height: 8),
            _buildMediaRow(record, theme, colorScheme, textScaler),
          ],
          // Encerramento
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
          // Última atualização
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
        Icon(Icons.perm_media_rounded, size: 16, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mídia',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.85),
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
                        color: _violetaEscura.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            size: 10,
                            color: _violetaEscura,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Áudio',
                            style: TextStyle(
                              fontSize: 9,
                              color: _violetaEscura,
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
                        color: _violetaEscura,
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
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: textScaler.scale(12),
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textScaler.scale(14),
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
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
              height: 44,
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
                  backgroundColor: _violetaEscura,
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
      height: 44,
      child: isPrimary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: _violetaEscura,
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
