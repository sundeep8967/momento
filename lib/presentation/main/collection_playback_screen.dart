import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../data/log_repository.dart';
import '../../data/crypto_state.dart';
import '../../data/cloudinary_service.dart';

class CollectionPlaybackScreen extends StatefulWidget {
  final String collectionId; // This is the Log ID (or file path for compatibility)

  const CollectionPlaybackScreen({
    super.key,
    required this.collectionId,
  });

  @override
  State<CollectionPlaybackScreen> createState() => _CollectionPlaybackScreenState();
}

class _CollectionPlaybackScreenState extends State<CollectionPlaybackScreen> {
  VideoPlayerController? _videoPlayerController;
  bool _isError = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // 1. Check if the parameter is a direct path (fallback/compatibility)
      if (widget.collectionId.contains('/') || widget.collectionId.contains('\\')) {
        final decodedPath = Uri.decodeComponent(widget.collectionId);
        final file = File(decodedPath);
        if (!await file.exists()) {
          if (mounted) setState(() => _isError = true);
          return;
        }
        await _setupController(file);
        return;
      }

      // 2. Look up the log by ID
      final logs = await LogRepository.instance.getLogs();
      final log = logs.firstWhere((l) => l.id == widget.collectionId, orElse: () => throw Exception('Log not found'));
      
      var file = File(log.path);
      
      // If local file is missing and we have a cloud backup, download and decrypt it
      if (!await file.exists()) {
        if (log.cloudUrl == null) {
          if (mounted) setState(() => _isError = true);
          return;
        }
        
        final masterKey = CryptoState.instance.masterKey;
        if (masterKey == null) {
          throw Exception('Session master key is missing. Re-authentication required.');
        }

        if (mounted) {
          setState(() {
            _isDownloading = true;
          });
        }

        final cachedPath = await CloudinaryService.downloadAndDecryptVideo(log.cloudUrl!, log.id, masterKey);
        file = File(cachedPath);
      }

      await _setupController(file);
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      debugPrint('Playback error: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _setupController(File file) async {
    _videoPlayerController = VideoPlayerController.file(file);
    await _videoPlayerController!.initialize();
    await _videoPlayerController!.setLooping(true);
    await _videoPlayerController!.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  color: Colors.grey[900],
                  child: _buildPlayerContent(),
                ),
              ),
            ),
            
            // Close Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => context.pop(),
              ),
            ),
            
            // Export/Share action
            Positioned(
              bottom: 32,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.ios_share, color: Colors.white, size: 32),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting 9:16 Video...')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_isError) {
      return const Center(
        child: Text(
          'Failed to load video.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (_isDownloading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Decrypting Cloud backup...',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      child: VideoPlayer(_videoPlayerController!),
    );
  }
}
