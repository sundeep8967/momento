import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:momento/data/snap_repository.dart';
import 'package:momento/theme/colors.dart';
import 'dart:async';

class SnapViewerScreen extends ConsumerStatefulWidget {
  final List<DirectSnap> snaps;

  const SnapViewerScreen({
    super.key,
    required this.snaps,
  });

  @override
  ConsumerState<SnapViewerScreen> createState() => _SnapViewerScreenState();
}

class _SnapViewerScreenState extends ConsumerState<SnapViewerScreen> {
  VideoPlayerController? _videoController;
  Timer? _imageTimer;
  bool _isPlaying = false;
  bool _isError = false;
  int _currentIndex = 0;

  DirectSnap get currentSnap => widget.snaps[_currentIndex];

  @override
  void initState() {
    super.initState();
    if (widget.snaps.isNotEmpty) {
      _loadSnap();
    }
  }

  Future<void> _loadSnap() async {
    _isError = false;
    _isPlaying = false;
    setState(() {});
    
    _markAsViewed();

    _imageTimer?.cancel();
    _videoController?.removeListener(_videoListener);
    await _videoController?.dispose();
    _videoController = null;

    if (currentSnap.isVideo) {
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(currentSnap.videoUrl));
        await _videoController!.initialize();
        _videoController!.setLooping(false);
        _videoController!.addListener(_videoListener);
        
        if (mounted) {
          setState(() {});
          _videoController!.play();
          _isPlaying = true;
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isError = true;
          });
        }
      }
    } else {
      // It's an image. Just set a 5-second timer.
      _imageTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) _nextSnap();
      });
      if (mounted) setState(() {});
    }
  }

  void _videoListener() {
    if (!mounted) return;
    if (_videoController == null) return;
    
    final value = _videoController!.value;
    if (value.isInitialized && value.position >= value.duration && !_isPlaying) {
      // Video finished
      _nextSnap();
    } else {
      if (_isPlaying != value.isPlaying) {
        setState(() {
          _isPlaying = value.isPlaying;
        });
      }
    }
  }

  void _nextSnap() {
    if (_currentIndex < widget.snaps.length - 1) {
      _currentIndex++;
      _loadSnap();
    } else {
      context.pop();
    }
  }

  Future<void> _markAsViewed() async {
    if (!currentSnap.isViewed) {
      try {
        await ref.read(snapRepositoryProvider).markSnapAsViewed(currentSnap.id);
      } catch (e) {
        debugPrint('Error marking snap as viewed: $e');
      }
    }
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!currentSnap.isVideo) {
      _nextSnap(); // Skip image if tapped
      return;
    }
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.snaps.isEmpty) return const Scaffold(backgroundColor: Colors.black);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Media Player
          if (_isError)
            const Center(child: Text('Failed to load media', style: TextStyle(color: Colors.white)))
          else if (!currentSnap.isVideo)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Image.network(currentSnap.videoUrl, fit: BoxFit.contain),
            )
          else if (_videoController != null && _videoController!.value.isInitialized)
            GestureDetector(
              onTap: _togglePlayPause,
              onLongPress: () => _videoController?.pause(),
              onLongPressUp: () => _videoController?.play(),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: SetlogColors.brownPrimary)),
            
          // Top Overlay (Sender info)
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: SetlogColors.authSurface,
                  child: Text(
                    currentSnap.senderUsername.isNotEmpty ? currentSnap.senderUsername[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: SetlogColors.authInk),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSnap.senderUsername,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (currentSnap.groupName != null)
                      Text(
                        'in ${currentSnap.groupName}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Close button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),
          
          // Tap indicators for next (right side)
          Positioned(
            top: 150,
            right: 0,
            bottom: 100,
            width: MediaQuery.of(context).size.width * 0.3,
            child: GestureDetector(
              onTap: _nextSnap,
              behavior: HitTestBehavior.translucent,
            ),
          ),

          // Play/Pause Overlay Indicator
          if (_videoController != null && _videoController!.value.isInitialized && !_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
            ),
        ],
      ),
    );
  }
}
