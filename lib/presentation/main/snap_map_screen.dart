
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momento/data/snap_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:momento/theme/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:momento/avatar_kit/avatar_widget.dart';
import 'dart:ui';
import 'package:momento/avatar_kit/momento_avatar.dart';
import 'package:momento/data/algorithms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui' as ui;
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    
    // Add shadow
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SnapMapScreen extends ConsumerStatefulWidget {
  final double? targetLat;
  final double? targetLng;

  const SnapMapScreen({super.key, this.targetLat, this.targetLng});

  @override
  ConsumerState<SnapMapScreen> createState() => _SnapMapScreenState();
}

class _SnapMapScreenState extends ConsumerState<SnapMapScreen> {
  // Persists across navigator push/pop — avoids London fallback on re-entry
  static LatLng? _cachedUserLocation;

  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  int _selectedTab = 0; // 0: Friends, 1: Local

  // ── Snap data ─────────────────────────────────────────────────────────────
  List<DirectSnap> _inboxSnaps = [];
  List<DirectSnap> _localSnaps = [];

  // ── Cluster cache: only recompute when snaps or location actually change ──
  List<(List<DirectSnap>, LatLng)> _cachedClusters = [];
  bool _positionedDirty = true;
  List<DirectSnap>? _selectedCluster;
  int _carouselIndex = 0;

  // ── Geocoding cache ────────────────────────────────────────────────────────
  // Key: "lat,lng" (rounded to 3dp) → resolved place name
  final Map<String, String> _placeCache = {};

  Future<String> _getPlaceName(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    if (_placeCache.containsKey(key)) return _placeCache[key]!;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final name = [p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        final result = name.isNotEmpty ? name : (p.country ?? 'Unknown');
        _placeCache[key] = result;
        return result;
      }
    } catch (_) {}
    _placeCache[key] = 'Unknown';
    return 'Unknown';
  }


  @override
  void initState() {
    super.initState();
    // Temporary fix for missing username
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'username': 'Sundeep'},
        SetOptions(merge: true),
      );
    }
    // Use the cached location immediately — zero wait, no jump
    _currentLocation = _cachedUserLocation;
    _initLocation();
  }

  Future<void> _initLocation() async {
    // If a target location was passed, center on it immediately
    if (widget.targetLat != null && widget.targetLng != null) {
      final loc = LatLng(widget.targetLat!, widget.targetLng!);
      setState(() => _currentLocation = loc);
      // Wait for map to be ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(loc, 15);
      });
      return;
    }

    // 1. Instantly use cached location if available
    if (_cachedUserLocation != null) {
      setState(() => _currentLocation = _cachedUserLocation);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_cachedUserLocation!, 15);
      });
    } else {
      // 1b. Fast fallback: London
      setState(() => _currentLocation = const LatLng(51.5074, -0.1278));
    }

    // 2. Permission check
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Location permission is permanently denied. Please enable it in Settings.'),
          ),
        );
      }
      return;
    }

    // 3. High-accuracy refresh
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        if (mounted) {
          final loc = LatLng(pos.latitude, pos.longitude);
          _cachedUserLocation = loc;
          setState(() => _currentLocation = loc);
          _mapController.move(loc, 15);
        }
      } catch (_) {}
    }
  }

  // ── Build marker positions (cluster overlapping snaps) ───────────────────
  List<(List<DirectSnap>, LatLng)> _computeClusters(List<DirectSnap> snaps) {
    List<DirectSnap> mapSnaps;
    if (_selectedTab == 1 && _currentLocation != null) {
      final grid = SpatialHashGrid<DirectSnap>(cellSizeDegrees: 0.05);
      for (final s in snaps) {
        if (s.lat != null && s.lng != null && !s.isViewed) {
          grid.insert(s.lat!, s.lng!, s);
        }
      }
      mapSnaps = grid.queryRadius(
          _currentLocation!.latitude, _currentLocation!.longitude, 10000);
    } else {
      mapSnaps =
          snaps.where((s) => s.lat != null && s.lng != null && !s.isViewed).toList();
    }

    const double gridRes = 5000.0;
    final Map<String, List<int>> buckets = {};
    for (int i = 0; i < mapSnaps.length; i++) {
      final lat = (mapSnaps[i].lat! * gridRes).round();
      final lng = (mapSnaps[i].lng! * gridRes).round();
      buckets.putIfAbsent('$lat,$lng', () => []).add(i);
    }

    final List<(List<DirectSnap>, LatLng)> clusters = [];
    for (final entry in buckets.entries) {
      final indices = entry.value;
      final centre = LatLng(mapSnaps[indices.first].lat!, mapSnaps[indices.first].lng!);
      final clusterSnaps = indices.map((i) => mapSnaps[i]).toList();
      clusters.add((clusterSnaps, centre));
    }
    return clusters;
  }

  void _openDirections(DirectSnap snap) async {
    if (snap.lat == null || snap.lng == null) return;
    final url = Uri.parse('https://maps.apple.com/?daddr=${snap.lat},${snap.lng}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${snap.lat},${snap.lng}');
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl);
      }
    }
  }

  void _onSnapTapped(DirectSnap snap) {
    if (_currentLocation == null) return;
    if (snap.lat == null || snap.lng == null) return;

    final distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      snap.lat!,
      snap.lng!,
    );

    if (distance <= 50) {
      context.push('/main/snap_viewer', extra: [snap]);
    } else {
      _openDirections(snap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapRepo = ref.read(snapRepositoryProvider);
    final activeSnaps = _selectedTab == 0 ? _inboxSnaps : _localSnaps;

    // Only re-run expensive cluster geometry when snaps or location actually changed
    if (_positionedDirty) {
      _cachedClusters = _computeClusters(activeSnaps);
      _positionedDirty = false;
    }
    final clusters = _cachedClusters;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. The Fullscreen Map — lives outside StreamBuilder so it NEVER resets ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Only used on the very first build; after that the controller drives everything
              initialCenter: _currentLocation ??
                  _cachedUserLocation ??
                  const LatLng(51.509364, -0.128928),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.setlog.momento',
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 100,
                      height: 100,
                        child: _buildPointyMarker(
                          MomentoAvatar.fromSeed(FirebaseAuth.instance.currentUser?.uid ?? 'momento'),
                          'Me',
                        ),
                    ),
                  ...clusters.map((entry) {
                    final (clusterSnaps, point) = entry;
                    return Marker(
                      point: point,
                      width: 140,
                      height: 145,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCluster = clusterSnaps;
                            _carouselIndex = 0;
                          });
                        },
                        child: _buildStackedMarker(clusterSnaps),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── 2. Invisible stream listeners — update state, never rebuild the map ──
          StreamBuilder<List<DirectSnap>>(
            stream: snapRepo.getInboxStream(),
            builder: (context, snapshot) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && snapshot.hasData) {
                  final fresh = snapshot.data!;
                  if (fresh.length != _inboxSnaps.length) {
                    setState(() {
                      _inboxSnaps = fresh;
                      _positionedDirty = true;
                    });
                  }
                }
              });
              return const SizedBox.shrink();
            },
          ),

          StreamBuilder<List<DirectSnap>>(
            stream: snapRepo.getLocalSnapsStream(),
            builder: (context, snapshot) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && snapshot.hasData) {
                  final fresh = snapshot.data!;
                  if (fresh.length != _localSnaps.length) {
                    setState(() {
                      _localSnaps = fresh;
                      _positionedDirty = true;
                    });
                  }
                }
              });
              return const SizedBox.shrink();
            },
          ),


          // ── 3. Floating UI Layer ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Stack(
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.black, size: 20),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/main');
                          }
                        },
                      ),
                    ),
                  ),

                  // Segmented Tab Control
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: CupertinoSlidingSegmentedControl<int>(
                        groupValue: _selectedTab,
                        backgroundColor: Colors.transparent,
                        thumbColor: SetlogColors.collectionsHomeBackground,
                        children: const {
                          0: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Text('Friends',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black))),
                          1: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Text('Local',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black))),
                        },
                        onValueChanged: (val) {
                          if (val != null) setState(() { _selectedTab = val; _positionedDirty = true; });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. My Location FAB ───────────────────────────────────────────
          if (_currentLocation != null)
            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'locate_btn',
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.black),
                onPressed: () => _mapController.move(_currentLocation!, 15),
              ),
            ),

          // ── 5. Send a Snap Button ────────────────────────────────────────
          if (_selectedCluster == null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => context.push('/main/camera', extra: {'from': 'map'}),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: SetlogColors.momentoPink,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: SetlogColors.momentoPink.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Send a Snap',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
          // ── 6. Carousel Overlay ──────────────────────────────────────────
          if (_selectedCluster != null)
            _buildCarouselOverlay(),
        ],
      ),
    );
  }

  Widget _buildStackedMarker(List<DirectSnap> snaps) {
    if (snaps.isEmpty) return const SizedBox.shrink();

    final uniqueSenders = <String, DirectSnap>{};
    for (var snap in snaps) {
      if (!uniqueSenders.containsKey(snap.senderUid)) {
        uniqueSenders[snap.senderUid] = snap;
      }
    }
    final uniqueSnaps = uniqueSenders.values.toList();
    final isMe = uniqueSnaps.first.senderUid == FirebaseAuth.instance.currentUser?.uid;
    final displayName = uniqueSnaps.length > 1
        ? '${uniqueSnaps.length} Friends'
        : (isMe ? 'Me' : uniqueSnaps.first.senderUsername);

    const double cardW = 120;
    const double photoH = 80;
    const double labelH = 44;
    const double cardH = photoH + labelH;

    final snap = snaps.first;
    final snapTime = snap.timestamp;
    final timeAgoStr = timeago.format(snapTime, allowFromNow: true);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Back cards (stacked illusion)
        if (snaps.length > 2)
          Positioned(
            top: 8,
            left: 14,
            child: Transform.rotate(
              angle: 0.18,
              child: _buildPolaroidCard(cardW, cardH),
            ),
          ),
        if (snaps.length > 1)
          Positioned(
            top: 4,
            left: 7,
            child: Transform.rotate(
              angle: 0.09,
              child: _buildPolaroidCard(cardW, cardH),
            ),
          ),

        // Top polaroid card
        Container(
          width: cardW,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo area — dark background with avatars side-by-side
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Container(
                  width: cardW,
                  height: photoH,
                  color: const Color(0xFF1A0A10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      uniqueSnaps.length > 3 ? 3 : uniqueSnaps.length,
                      (i) {
                        final avatarSize = uniqueSnaps.length == 1
                            ? 64.0
                            : uniqueSnaps.length == 2
                                ? 50.0
                                : 42.0;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: uniqueSnaps.length == 1 ? 0 : 1),
                          child: AvatarWidget(
                            avatar: MomentoAvatar.fromSeed(uniqueSnaps[i].senderUid),
                            size: avatarSize,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // White label strip — location + timeago
              Container(
                width: cardW,
                height: labelH,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: FutureBuilder<String>(
                  future: _getPlaceName(snap.lat ?? 0, snap.lng ?? 0),
                  builder: (context, snapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          snapshot.hasData ? '${snapshot.data} • $timeAgoStr' : timeAgoStr,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.black.withValues(alpha: 0.45),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // V-shaped tail pointing down
        Positioned(
          bottom: -8,
          left: (cardW / 2) - 15, // centered with new width of 30
          child: CustomPaint(
            painter: TrianglePainter(color: Colors.white),
            size: const Size(30, 15),
          ),
        ),

        // Badge
        if (snaps.length > 1)
          Positioned(
            top: -10,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: SetlogColors.momentoPink,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: SetlogColors.momentoPink.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${snaps.length} Snaps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPolaroidCard(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCluster = null), // dismiss on tap outside
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {}, // consume tap inside carousel
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.only(top: 24, bottom: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle pill
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          
                          SizedBox(
                            height: 280,
                            child: PageView.builder(
                              controller: PageController(viewportFraction: 0.8),
                              onPageChanged: (index) => setState(() => _carouselIndex = index),
                              itemCount: _selectedCluster!.length,
                              itemBuilder: (context, index) {
                                final snap = _selectedCluster![index];
                                final isMe = snap.senderUid == FirebaseAuth.instance.currentUser?.uid;
                                final displayName = isMe ? 'Me' : snap.senderUsername;
                                
                                double distance = double.infinity;
                                if (_currentLocation != null && snap.lat != null && snap.lng != null) {
                                  distance = Geolocator.distanceBetween(
                                    _currentLocation!.latitude,
                                    _currentLocation!.longitude,
                                    snap.lat!,
                                    snap.lng!,
                                  );
                                }
                                
                                final unlocked = distance <= 50;

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Blurred Preview Area
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFE5D5DD), Color(0xFFD6C8D0)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                                              size: 48,
                                              color: Colors.black.withValues(alpha: 0.2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Bottom Info Area
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                AvatarWidget(
                                                  avatar: MomentoAvatar.fromSeed(snap.senderUid),
                                                  size: 40,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        displayName,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      if (!unlocked && distance != double.infinity)
                                                        Text(
                                                          '${distance.toStringAsFixed(0)}m away',
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.black54,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            GestureDetector(
                                              onTap: () => _onSnapTapped(snap),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: unlocked ? SetlogColors.momentoPink : const Color(0xFF1A0A10),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  unlocked ? 'View Snap' : 'Get Directions 📍',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Pagination Dots
                          if (_selectedCluster!.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _selectedCluster!.length,
                                  (i) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _carouselIndex == i 
                                          ? SetlogColors.momentoPink 
                                          : Colors.black.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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

  Widget _buildPointyMarker(MomentoAvatar avatar, String name) {
    final glowColor = Color(MomentoAvatar.bgGradients[avatar.bgScene][0]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // The Pointy bit (triangle) using a rotated container
            Positioned(
              bottom: -4,
              child: Transform.rotate(
                angle: 3.14159 / 4, // 45 degrees
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: glowColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // The Circle with border
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3), // Border thickness
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white, // Inner thin border
                ),
                padding: const EdgeInsets.all(1.5),
                child: ClipOval(
                  child: AvatarWidget(
                    avatar: avatar,
                    size: 50,
                    showBorder: false,
                    showGlow: false,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Name Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
