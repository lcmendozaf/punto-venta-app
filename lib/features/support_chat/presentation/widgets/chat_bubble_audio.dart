import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;

class ChatBubbleAudio extends StatefulWidget {
  const ChatBubbleAudio({
    super.key,
    required this.audioUrl,
    required this.fileName,
    required this.fileSizeBytes,
    required this.isOutbound,
  });

  final String? audioUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final bool isOutbound;

  @override
  State<ChatBubbleAudio> createState() => _ChatBubbleAudioState();
}

class _ChatBubbleAudioState extends State<ChatBubbleAudio> {
  late final ja.AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  bool _isAudioSet = false;

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();

    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ja.ProcessingState.completed) {
            _isPlaying = false;
            _position = Duration.zero;
            _player.seek(Duration.zero);
            _player.pause();
          }
        });
      }
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _positionSubscription = _player.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return;

    try {
      if (!_isAudioSet) {
        await _player.setUrl(widget.audioUrl!);
        _isAudioSet = true;
      }

      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${twoDigits(seconds)}';
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final progressText = _formatDuration(_position);
    final durationText = _duration != Duration.zero 
        ? _formatDuration(_duration)
        : _formatBytes(widget.fileSizeBytes);

    final String extension;
    final path = (widget.fileName ?? widget.audioUrl ?? '').toLowerCase();
    if (path.contains('.webm')) {
      extension = '.webm';
    } else if (path.contains('.ogg')) {
      extension = '.ogg';
    } else {
      extension = '.mp3';
    }

    final displayTitle = widget.fileName != null && widget.fileName!.isNotEmpty
        ? widget.fileName!
        : 'Mensaje de voz$extension';

    final iconColor = widget.isOutbound ? Colors.white : Colors.deepPurple;
    final backgroundColor = widget.isOutbound
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.grey[200];
    final textColor = widget.isOutbound ? Colors.white : Colors.black87;
    final subtitleColor = widget.isOutbound ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 270),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.isOutbound
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.deepPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: iconColor,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: widget.isOutbound
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progressPercent.clamp(0.0, 1.0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progressText,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 10,
                        ),
                      ),
                      if (durationText.isNotEmpty)
                        Text(
                          durationText,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
