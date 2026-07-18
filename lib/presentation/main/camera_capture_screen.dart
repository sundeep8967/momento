import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/log_repository.dart';
import '../../theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isCameraInitialized = false;
  bool _isSaving = false;
  bool _isLandscape = false; 

  XFile? _recordedFile;
  bool _isReviewing = false;
  bool _isVideo = true;
  final TextEditingController _captionController = TextEditingController();
  bool _showStreakCelebration = false;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _stopRecording();
        }
      });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // 'medium' is much safer for Android hardware encoders to avoid green glitch artifacts
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cameraController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isRecordingVideo) return;
    HapticFeedback.mediumImpact();
    try {
      final file = await _cameraController!.takePicture();
      if (mounted) {
        setState(() {
          _recordedFile = file;
          _isVideo = false;
          _isReviewing = true;
        });
      }
    } catch (e) {
      debugPrint('Take picture error: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isRecordingVideo) return;
    HapticFeedback.mediumImpact();
    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
      _progressController.forward(from: 0.0);
    } catch (e) {
      debugPrint('Record start error: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;
    try {
      HapticFeedback.lightImpact();
      _progressController.stop();
      final file = await _cameraController!.stopVideoRecording();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordedFile = file;
          _isVideo = true;
          _isReviewing = true;
        });
      }
    } catch (e) {
      debugPrint('Record stop error: $e');
    }
  }

  Future<void> _saveClip() async {
    if (_recordedFile == null) return;
    HapticFeedback.lightImpact();
    
    final caption = _captionController.text.trim();
    
    // Navigate to SendToScreen with the recorded file path and type
    context.push('/main/send_to', extra: {
      'mediaPath': _recordedFile!.path,
      'isVideo': _isVideo,
      'caption': caption.isEmpty ? null : caption,
    });
    
    // Reset state here in case they go back
    setState(() {
      _recordedFile = null;
      _isReviewing = false;
      _captionController.clear();
    });
  }

  void _discardClip() {
    setState(() {
      _recordedFile = null;
      _isReviewing = false;
      _captionController.clear();
    });
  }

  void _flipOrientation() {
    HapticFeedback.lightImpact();
    setState(() => _isLandscape = !_isLandscape);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.cameraBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            Center(
              child: RotatedBox(
                quarterTurns: _isLandscape ? 1 : 0,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isCameraInitialized
                      ? Transform.scale(
                          scale: 1.05,
                          child: Center(child: CameraPreview(_cameraController!)),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: SetlogColors.authTerminalAccent),
                        ),
                ),
              ),
            ),

            if (!_isReviewing) ...[
              // Top controls
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isLandscape ? Icons.stay_current_portrait : Icons.stay_current_landscape,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: _flipOrientation,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

              // Record button
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _takePicture, // single tap for photo
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressController.value,
                                color: SetlogColors.cameraTimerProgress,
                                backgroundColor: Colors.white24,
                                strokeWidth: 6,
                              );
                            },
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isRecording ? 52 : 70,
                          height: _isRecording ? 52 : 70,
                          decoration: BoxDecoration(
                            color: _isRecording ? SetlogColors.cameraTimerProgress : Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),

              // Hint
              Positioned(
                bottom: 158,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _isRecording ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Text(
                      'Hold to record  ·  5s max',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
            ],

            if (_isReviewing && !_isSaving) ...[
              // Review Overlay (Caption & Send)
              Container(color: Colors.black54),
              Positioned(
                top: 32,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: _discardClip,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                right: 24,
                child: CupertinoButton.filled(
                  onPressed: _saveClip,
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Send To', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(CupertinoIcons.paperplane_fill, size: 20),
                    ],
                  ),
                ),
              )
            ],

            // Saving overlay
            if (_isSaving)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: SetlogColors.authTerminalAccent),
                      SizedBox(height: 16),
                      Text(
                        'Uploading moment...',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            // Streak Celebration Overlay
            if (_showStreakCelebration)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: SetlogColors.blueFlame,
                        size: 100,
                      ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 20),
                      Text(
                        'Streak +1',
                        style: const TextStyle(
                          color: SetlogColors.brownPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                      const SizedBox(height: 10),
                      Text(
                        '$_currentStreak days strong',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms).fadeOut(delay: 1500.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
