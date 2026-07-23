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
  bool _isFrontCamera = true;
  bool _isFlashOn = false;
  bool _isDualCamera = false;
  Offset _pipOffset = const Offset(20, 100);

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

  Future<void> _switchCamera() async {
    HapticFeedback.mediumImpact();
    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;
      
      _isFrontCamera = !_isFrontCamera;
      final targetLens = _isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;
      
      final selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == targetLens,
        orElse: () => cameras.first,
      );

      await _cameraController?.dispose();
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (_isFlashOn && !_isFrontCamera) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    HapticFeedback.mediumImpact();
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  void _toggleDualCamera() {
    HapticFeedback.mediumImpact();
    setState(() => _isDualCamera = !_isDualCamera);
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

          // Dual Camera PIP Window Overlay (Draggable anywhere on screen)
          if (_isDualCamera && _isCameraInitialized && !_isReviewing)
            Positioned(
              top: _pipOffset.dy,
              left: _pipOffset.dx,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pipOffset += details.delta;
                  });
                },
                onTap: _switchCamera,
                child: Container(
                  width: 110,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize?.height ?? 1,
                              height: _cameraController!.value.previewSize?.width ?? 1,
                              child: CameraPreview(_cameraController!),
                            ),
                          ),
                        ),
                        Container(
                          color: SetlogColors.momentoPink.withOpacity(0.2),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: const [
                                Icon(CupertinoIcons.switch_camera, color: Colors.white, size: 10),
                                SizedBox(width: 4),
                                Text(
                                  'Dual Cam',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (!_isReviewing) ...[
              // Snapchat-style Top & Vertical Side Toolbar
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Close Button
                        IconButton(
                          icon: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 32),
                          onPressed: () => context.pop(),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                        const Spacer(),
                        // Vertical Toolbar with Labels (Switch Camera, Flash, Dual Cam, Music)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             // 1. Switch Camera (Front/Back)
                            _buildToolbarItem(
                              icon: CupertinoIcons.arrow_2_circlepath,
                              label: 'Switch Camera',
                              onTap: _switchCamera,
                            ),
                            // 2. Flash
                            _buildToolbarItem(
                              icon: _isFlashOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash,
                              label: 'Flash',
                              onTap: _toggleFlash,
                            ),
                            // 3. Dual Camera Mode
                            _buildToolbarItem(
                              icon: CupertinoIcons.rectangle_on_rectangle_angled,
                              label: 'Dual Cam',
                              onTap: _toggleDualCamera,
                            ),
                          ],
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
              // Top Bar Controls (Only Close Button on top left)
              Positioned(
                top: 0,
                left: 20,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 32),
                      onPressed: _discardClip,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),

              // Bottom Area: Frosted Caption Pill + Centered Pink Send Button
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

                    // Centered Primary Pink Send Button
                    Center(
                      child: GestureDetector(
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
    double buttonSize = 52,
    double iconSize = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 26,
              shadows: const [
                Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
