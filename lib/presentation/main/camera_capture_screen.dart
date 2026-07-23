import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() {
          _recordedFile = pickedFile;
          _isVideo = false;
          _isReviewing = true;
        });
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  void _flipOrientation() {
    HapticFeedback.lightImpact();
    setState(() => _isLandscape = !_isLandscape);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Camera preview / Media display (Full edge-to-edge screen)
          Positioned.fill(
            child: RotatedBox(
              quarterTurns: _isLandscape ? 1 : 0,
              child: SizedBox.expand(
                child: (_isReviewing && _recordedFile != null && !_isVideo)
                    ? Image.file(
                        File(_recordedFile!.path),
                        fit: BoxFit.cover,
                      )
                    : _isCameraInitialized
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize?.height ?? 1,
                              height: _cameraController!.value.previewSize?.width ?? 1,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(color: SetlogColors.authTerminalAccent),
                          ),
              ),
            ),
          ),

            if (!_isReviewing) ...[
              // Top controls with frosted glass circular buttons
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        _buildFrostedCircularButton(
                          icon: CupertinoIcons.xmark,
                          onTap: () => context.pop(),
                        ),
                        const Spacer(),
                        _buildFrostedCircularButton(
                          icon: _isLandscape ? CupertinoIcons.device_phone_portrait : CupertinoIcons.device_phone_landscape,
                          onTap: _flipOrientation,
                        ),
                      ],
                    ),
                  ),
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
                            color: _isRecording ? SetlogColors.cameraTimerProgress : SetlogColors.momentoPink,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: SetlogColors.momentoPink.withOpacity(0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
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
                      'Tap for photo  ·  Hold to record',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
            ],
            if (_isReviewing && !_isSaving) ...[
              // Top Bar Controls (Floating on photo, no dark background)
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        _buildFrostedCircularButton(
                          icon: CupertinoIcons.xmark,
                          onTap: _discardClip,
                          buttonSize: 38,
                          iconSize: 18,
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.38),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                              ),
                              child: const Text(
                                'New Moment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Area: Frosted Caption Pill + Circular Action Row
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Frosted Glass Capsule Caption Field
                    ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _captionController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Add a caption...',
                                    hintStyle: TextStyle(color: Colors.white70, fontSize: 16),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                ),
                              ),
                              const Icon(CupertinoIcons.smiley, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons Row (Gallery on left, Pink Send in middle)
                    Row(
                      children: [
                        // Gallery / Photos Icon on far left
                        _buildFrostedCircularButton(
                          icon: CupertinoIcons.photo_on_rectangle,
                          onTap: _pickFromGallery,
                        ),
                        const Spacer(),
                        // Primary Pink Send Button with "Send" text in center
                        GestureDetector(
                          onTap: _saveClip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                            decoration: BoxDecoration(
                              color: SetlogColors.momentoPink,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: SetlogColors.momentoPink.withOpacity(0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Send',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  CupertinoIcons.paperplane_fill,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Spacer balance to keep Send button perfectly centered
                        const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),
              ),
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
      );
    }

  Widget _buildFrostedCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    double buttonSize = 48,
    double iconSize = 22,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.38),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}
