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
        _showMessage('Erro ao carregar histórico de SOS: $e');
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
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedFilter != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusText(_selectedFilter!),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _setFilter(null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
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
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState(theme)
                    : _filteredRecords.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildHistoryList(theme),
              ),
            ],
          ),
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
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando...',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
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
                  color: theme.colorScheme.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFilter ? Icons.filter_list_rounded : Icons.history_rounded,
                  size: 40,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasFilter
                    ? 'Nenhum SOS encontrado'
                    : 'Nenhum registro encontrado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasFilter
                    ? 'Não há SOS com o status selecionado.'
                    : 'Você ainda não criou nenhum SOS.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: hasFilter
                      ? () => _setFilter(null)
                      : _loadSosRecords,
                  icon: Icon(
                    hasFilter
                        ? Icons.filter_list_off_rounded
                        : Icons.refresh_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    hasFilter ? 'Remover filtro' : 'Atualizar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withAlpha(40),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _filteredRecords.length,
          itemBuilder: (context, index) {
            final record = _filteredRecords[index];
            return _buildSosCard(record, theme, index);
          },
        ),
      ),
    );
  }

  Widget _buildSosCard(SosRecord record, ThemeData theme, int index) {
    return Container(
      margin: EdgeInsets.only(
        bottom: index == _filteredRecords.length - 1 ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do card
          _buildCardHeader(record, theme),
          // Divider sutil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOS #${record.id}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _timeAgo(record.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: record.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: record.statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(record.statusIcon, size: 12, color: record.statusColor),
                const SizedBox(width: 4),
                Text(
                  record.statusText,
                  style: TextStyle(
                    fontSize: 10,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Data
          _buildInfoRow(
            Icons.schedule_rounded,
            'Criado em',
            record.formattedCreatedAt,
            theme,
          ),
          const SizedBox(height: 8),
          // Localização
          _buildInfoRow(
            Icons.location_on_rounded,
            'Localização',
            '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
            theme,
          ),
          // Mídia
          if (record.fullCaminhoAudioUrl != null ||
              record.fullCaminhoVideoUrl != null) ...[
            const SizedBox(height: 8),
            _buildMediaRow(record, theme),
          ],
          // Encerramento
          if (record.encerrado_em != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.check_circle_rounded,
              'Encerrado em',
              DateFormat('dd/MM/yyyy HH:mm').format(record.encerrado_em!),
              theme,
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaRow(SosRecord record, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.perm_media_rounded,
          size: 14,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mídia',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded, size: 10, color: Colors.blue),
                          const SizedBox(width: 3),
                          Text(
                            'Áudio',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.blue,
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
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            size: 10,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Vídeo',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.red,
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
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            const SizedBox(width: 8),
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
      height: 40,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
    );
  }
}
