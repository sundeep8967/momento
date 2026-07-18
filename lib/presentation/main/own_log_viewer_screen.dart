import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import '../../data/log_repository.dart';

class OwnLogViewerScreen extends StatefulWidget {
  final String logId; // date string "2026-06-26"

  const OwnLogViewerScreen({super.key, required this.logId});

  @override
  State<OwnLogViewerScreen> createState() => _OwnLogViewerScreenState();
}

class _OwnLogViewerScreenState extends State<OwnLogViewerScreen> {
  List<DayClip> _clips = [];
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final clips = await LogRepository.instance.getMyClipsForLog(widget.logId);
      if (mounted) {
        setState(() { _clips = clips; _isLoading = false; });
        if (clips.isNotEmpty) _playClip(0);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playClip(int index) async {
    if (index >= _clips.length) return;
    await _videoController?.dispose();
    final clip = _clips[index];
    final controller = VideoPlayerController.networkUrl(Uri.parse(clip.cloudUrl));
    await controller.initialize();
    controller.setLooping(false);
    controller.addListener(() {
      if (controller.value.position >= controller.value.duration &&
          controller.value.isInitialized &&
          !controller.value.isPlaying) {
        _advance();
      }
    });
    if (mounted) {
      setState(() => _videoController = controller);
      controller.play();
    }
  }

  void _advance() {
    if (_currentIndex < _clips.length - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex++);
      _playClip(_currentIndex);
    } else {
      if (mounted) context.pop();
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex--);
      _playClip(_currentIndex);
    }
  }

  Future<void> _downloadClip() async {
    if (_clips.isEmpty || _videoController == null) return;
    HapticFeedback.mediumImpact();
    
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied to save video.')));
          return;
        }
      }

      final clip = _clips[_currentIndex];
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading video...')));

      final response = await http.get(Uri.parse(clip.cloudUrl));
      if (response.statusCode == 200) {
        final file = File('${Directory.systemTemp.path}/temp_${clip.id}.mp4');
        await file.writeAsBytes(response.bodyBytes);
        await Gal.putVideo(file.path);
        HapticFeedback.vibrate();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Camera Roll!')));
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteClip() async {
    if (_clips.isEmpty) return;
    HapticFeedback.mediumImpact();
    final clip = _clips[_currentIndex];
    
    // Pause video
    _videoController?.pause();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Clip?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently delete this clip from your log.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    
    if (confirm != true) {
      _videoController?.play();
      return;
    }
    
    try {
      await LogRepository.instance.deleteClip(widget.logId, clip.id);
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _clips.removeAt(_currentIndex);
          if (_clips.isEmpty) {
            context.pop();
          } else {
            if (_currentIndex >= _clips.length) _currentIndex = _clips.length - 1;
            _playClip(_currentIndex);
          }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting clip: $e')));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_clips.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('No clips yet for this day',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go back',
                    style: TextStyle(color: Colors.white70))),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx > width / 2) {
            _advance();
          } else {
            _goBack();
          }
        },
        child: Stack(
          children: [
            // Video
            Center(
              child: _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // Progress bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: List.generate(_clips.length, (i) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _currentIndex ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Log',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          Text(
                            _formatDate(widget.logId),
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${_currentIndex + 1} / ${_clips.length}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Overlays: Caption, Download, Delete
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_clips[_currentIndex].caption != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _clips[_currentIndex].caption!,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white, size: 28),
                        onPressed: _downloadClip,
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
                        onPressed: _deleteClip,
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

  String _formatDate(String dateStr) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('MMMM d, y').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
