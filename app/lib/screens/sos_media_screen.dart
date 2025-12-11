import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/sos_record.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io'; // Moved to the top

class SosMediaScreen extends StatefulWidget {
  final SosRecord record;

  const SosMediaScreen({super.key, required this.record});

  @override
  State<SosMediaScreen> createState() => _SosMediaScreenState();
}

class _SosMediaScreenState extends State<SosMediaScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isVideoInitialized = false;
  bool _isAudioInitialized = false;
  bool _isLoadingVideo = false;
  bool _isLoadingAudio = false;
  bool _hasVideoError = false;
  bool _hasAudioError = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  Future<void> _initMedia() async {
    // Vídeo
    if (widget.record.fullCaminhoVideoUrl != null) {
      setState(() => _isLoadingVideo = true);
      try {
        if (widget.record.fullCaminhoVideoUrl!.startsWith('http')) {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(widget.record.fullCaminhoVideoUrl!),
          );
        } else {
          _videoController = VideoPlayerController.file(
            File(widget.record.fullCaminhoVideoUrl!),
          );
        }
        await _videoController!.initialize();
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });
      } catch (e) {
        print('Erro ao inicializar vídeo: $e');
        setState(() => _hasVideoError = true);
      } finally {
        setState(() => _isLoadingVideo = false);
      }
    }

    // Áudio
    if (widget.record.fullCaminhoAudioUrl != null) {
      print('URL áudio: ${widget.record.fullCaminhoAudioUrl}');
      setState(() => _isLoadingAudio = true);
      _audioPlayer = AudioPlayer();
      try {
        if (widget.record.fullCaminhoAudioUrl!.startsWith('http')) {
          await _audioPlayer!.setUrl(widget.record.fullCaminhoAudioUrl!);
        } else {
          await _audioPlayer!.setFilePath(widget.record.fullCaminhoAudioUrl!);
        }
        setState(() {
          _isAudioInitialized = true;
          _hasAudioError = false;
        });
      } catch (e) {
        print('Erro ao carregar áudio: $e');
        setState(() {
          _hasAudioError = true;
          _isAudioInitialized = false;
        });
      } finally {
        if (mounted) setState(() => _isLoadingAudio = false);
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildVideoPlayer() {
    if (_isLoadingVideo) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasVideoError) {
      return const Center(
        child: Text(
          'Erro ao carregar vídeo.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    if (_videoController == null || !_isVideoInitialized) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vídeo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_videoController!),
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  if (!_videoController!.value.isPlaying)
                    const Center(
                      child: Icon(
                        LucideIcons.play,
                        size: 64,
                        color: Colors.white70,
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: ValueListenableBuilder(
                      valueListenable: _videoController!,
                      builder: (context, VideoPlayerValue value, child) {
                        return Text(
                          '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? LucideIcons.pause
                        : LucideIcons.play,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    if (_isLoadingAudio) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasAudioError) {
      return const Center(
        child: Text(
          'Erro ao carregar áudio.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    if (_audioPlayer == null || !_isAudioInitialized) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Áudio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StreamBuilder<PlayerState>(
                  stream: _audioPlayer!.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final playing = playerState?.playing ?? false;
                    return IconButton(
                      icon: Icon(
                        playing ? LucideIcons.pause : LucideIcons.play,
                      ),
                      iconSize: 48,
                      onPressed: () {
                        if (playing) {
                          _audioPlayer!.pause();
                        } else {
                          _audioPlayer!.play();
                        }
                      },
                    );
                  },
                ),
                Expanded(
                  child: StreamBuilder<Duration>(
                    stream: _audioPlayer!.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = _audioPlayer!.duration ?? Duration.zero;
                      return Column(
                        children: [
                          Slider(
                            value: position.inMilliseconds.toDouble().clamp(
                              0.0,
                              duration.inMilliseconds.toDouble(),
                            ),
                            max: duration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              _audioPlayer!.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.record.fullCaminhoVideoUrl != null;
    final hasAudio = widget.record.fullCaminhoAudioUrl != null;

    final hasMedia = hasVideo || hasAudio;

    return Scaffold(
      appBar: AppBar(title: const Text('Mídia do SOS')),
      body: hasMedia
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasVideo) _buildVideoPlayer(),
                  if (hasAudio) _buildAudioPlayer(),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.folderOpen,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhuma mídia disponível para este SOS.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
