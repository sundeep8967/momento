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

class SnapMapScreen extends ConsumerStatefulWidget {
  const SnapMapScreen({super.key});

  @override
  ConsumerState<SnapMapScreen> createState() => _SnapMapScreenState();
}

class _SnapMapScreenState extends ConsumerState<SnapMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  int _selectedTab = 0; // 0: Friends, 1: Local

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_currentLocation!, 15);
      }
    }
  }

  void _onSnapTapped(DirectSnap snap) async {
    if (_currentLocation == null) return;
    if (snap.lat == null || snap.lng == null) return;

    final distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      snap.lat!,
      snap.lng!
    );

    if (distance <= 50) {
      // Unlock!
      context.push('/main/snap_viewer', extra: [snap]);
    } else {
      // Too far
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Get closer! You must be within 50 meters to unlock this Momento. You are ${distance.toStringAsFixed(0)}m away.'),
          backgroundColor: Colors.redAccent,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapRepo = ref.read(snapRepositoryProvider);

    return Scaffold(
      body: StreamBuilder<List<DirectSnap>>(
        stream: _selectedTab == 0 ? snapRepo.getInboxStream() : snapRepo.getLocalSnapsStream(),
        builder: (context, snapshot) {
          final snaps = snapshot.data ?? [];
          final mapSnaps = snaps.where((s) {
            if (s.lat == null || s.lng == null) return false;
            if (s.isViewed) return false; // Viewed snaps disappear from map

            if (_selectedTab == 1 && _currentLocation != null) {
              // Local public snaps: filter by 10km radius
              final dist = Geolocator.distanceBetween(_currentLocation!.latitude, _currentLocation!.longitude, s.lat!, s.lng!);
              if (dist > 10000) return false;
            }
            return true;
          }).toList();

          // ── Spiderfy at snap coordinates ──────────────────────────────────
          // Group snaps by their actual drop location (~22 m grid).
          // Each group spreads in concentric rings AT that location.
          // Live-location dot is completely independent – not used as centre.
          const double gridRes = 5000.0; // 1 / 5000 ≈ 22 m per cell

          final Map<String, List<int>> buckets = {};
          for (int i = 0; i < mapSnaps.length; i++) {
            final lat = (mapSnaps[i].lat! * gridRes).round();
            final lng = (mapSnaps[i].lng! * gridRes).round();
            buckets.putIfAbsent('$lat,$lng', () => []).add(i);
          }

          // Ring geometry — marker 52 px wide, need 64 px between centres (52+12 gap)
          // At zoom 15: 1° lat ≈ 23 871 px  →  64 px ≈ 0.00268°
          // Ring k radius = k * baseRadius
          // baseRadius chosen so ring-1 circumference holds ≥ 6 markers cleanly
          //   ring-1 capacity = floor(2π * baseRadius / slotDeg) ≈ floor(2π * 0.004 / 0.00268) ≈ 9
          const double slotDeg  = 0.00268;   // ~64 px at zoom 15
          const double baseRadius = 0.004;    // ~95 px radius on ring-1

          final List<(DirectSnap, LatLng)> positioned = [];

          for (final entry in buckets.entries) {
            final indices = entry.value;
            final centre = LatLng(
              mapSnaps[indices.first].lat!,
              mapSnaps[indices.first].lng!,
            );

            if (indices.length == 1) {
              // Single snap: place exactly at its coordinates
              positioned.add((mapSnaps[indices.first], centre));
              continue;
            }

            // Fill concentric rings until all snaps are placed
            int placed = 0;
            int ring = 1;
            while (placed < indices.length) {
              final double r = baseRadius * ring;
              // How many markers fit on this ring without overlapping?
              final int capacity =
                  math.max(4, (2 * math.pi * r / slotDeg).floor());
              final int toPlace =
                  math.min(capacity, indices.length - placed);

              for (int j = 0; j < toPlace; j++) {
                final double angle =
                    (2 * math.pi * j / toPlace) - math.pi / 2;
                positioned.add((
                  mapSnaps[indices[placed + j]],
                  LatLng(
                    centre.latitude + r * math.cos(angle),
                    centre.longitude +
                        r *
                            math.sin(angle) /
                            math.cos(centre.latitude * math.pi / 180),
                  ),
                ));
              }
              placed += toPlace;
              ring++;
            }
          }

          return Stack(
            children: [
              // 1. The Fullscreen Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(51.509364, -0.128928),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
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
                            avatar: MomentoAvatar.fromSeed(FirebaseAuth.instance.currentUser?.uid ?? 'momento'),
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

              // 2. Floating UI Layer
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Stack(
                    children: [
                      // Floating Back Button
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                            ]
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                            onPressed: () => context.pop(),
                          ),
                        ),
                      ),
                      
                      // Floating Segmented Control (Pill)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                            ]
                          ),
                          child: CupertinoSlidingSegmentedControl<int>(
                            groupValue: _selectedTab,
                            backgroundColor: Colors.transparent,
                            thumbColor: SetlogColors.collectionsHomeBackground,
                            children: const {
                              0: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Friends', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                              1: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Local', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
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

              // 3. Floating My Location Button
              if (_currentLocation != null)
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    heroTag: 'locate_btn',
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black),
                    onPressed: () {
                      _mapController.move(_currentLocation!, 15);
                    },
                  ),
                ),

              // 4. Floating 'Send a Snap' Button (Bottom Center)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.push('/main/camera', extra: {'from': 'map'}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: SetlogColors.momentoPink,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: SetlogColors.momentoPink.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                        ]
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Send a Snap',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      )
    );
  }
}
