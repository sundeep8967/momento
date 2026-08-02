import 'dart:math' as math;
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
import 'package:momento/avatar_kit/momento_avatar.dart';
import 'package:momento/data/algorithms.dart';

class SnapMapScreen extends ConsumerStatefulWidget {
  const SnapMapScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    // Use the cached location immediately — zero wait, no jump
    _currentLocation = _cachedUserLocation;
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    // 1. Fast Path: last known OS cache (0 ms, no GPS cold-start)
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        final loc = LatLng(lastPos.latitude, lastPos.longitude);
        _cachedUserLocation = loc;
        if (_currentLocation == null) {
          setState(() => _currentLocation = loc);
          _mapController.move(loc, 15);
        }
      }
    } catch (_) {}

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

  // ── Build marker positions (spiderfy overlapping snaps) ───────────────────
  List<(DirectSnap, LatLng)> _computePositioned(List<DirectSnap> snaps) {
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

    const double slotDeg = 0.00268;
    const double baseRadius = 0.004;

    final List<(DirectSnap, LatLng)> positioned = [];
    for (final entry in buckets.entries) {
      final indices = entry.value;
      final centre = LatLng(mapSnaps[indices.first].lat!, mapSnaps[indices.first].lng!);

      if (indices.length == 1) {
        positioned.add((mapSnaps[indices.first], centre));
        continue;
      }

      int placed = 0;
      int ring = 1;
      while (placed < indices.length) {
        final double r = baseRadius * ring;
        final int capacity = math.max(4, (2 * math.pi * r / slotDeg).floor());
        final int toPlace = math.min(capacity, indices.length - placed);
        for (int j = 0; j < toPlace; j++) {
          final double angle = (2 * math.pi * j / toPlace) - math.pi / 2;
          positioned.add((
            mapSnaps[indices[placed + j]],
            LatLng(
              centre.latitude + r * math.cos(angle),
              centre.longitude +
                  r * math.sin(angle) / math.cos(centre.latitude * math.pi / 180),
            ),
          ));
        }
        placed += toPlace;
        ring++;
      }
    }
    return positioned;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '📍 Get closer! You must be within 50 meters to unlock this Momento. You are ${distance.toStringAsFixed(0)}m away.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapRepo = ref.read(snapRepositoryProvider);
    final activeSnaps = _selectedTab == 0 ? _inboxSnaps : _localSnaps;
    final positioned = _computePositioned(activeSnaps);

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
                      width: 50,
                      height: 50,
                      child: AvatarWidget(
                        avatar: MomentoAvatar.fromSeed(
                            FirebaseAuth.instance.currentUser?.uid ?? 'momento'),
                        size: 50,
                        showBorder: true,
                        showGlow: true,
                      ),
                    ),
                  ...positioned.map((entry) {
                    final (snap, point) = entry;
                    return Marker(
                      point: point,
                      width: 56,
                      height: 56,
                      child: GestureDetector(
                        onTap: () => _onSnapTapped(snap),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SetlogColors.snapViewerAccent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: AvatarWidget(
                              avatar: MomentoAvatar.fromSeed(snap.senderUid),
                              size: 48,
                              showBorder: false,
                              showGlow: false,
                            ),
                          ),
                        ),
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
                    setState(() => _inboxSnaps = fresh);
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
                    setState(() => _localSnaps = fresh);
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
                          if (val != null) setState(() => _selectedTab = val);
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
        ],
      ),
    );
  }
}
