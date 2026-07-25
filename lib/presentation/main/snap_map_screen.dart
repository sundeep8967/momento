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
            if (s.lat == null || s.lng == null || s.isViewed) return false;
            
            if (_selectedTab == 1 && _currentLocation != null) {
              // Local public snaps: filter by 10km radius
              final dist = Geolocator.distanceBetween(_currentLocation!.latitude, _currentLocation!.longitude, s.lat!, s.lng!);
              if (dist > 10000) return false;
            }
            return true;
          }).toList();

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
                      ...mapSnaps.map((snap) => Marker(
                        point: LatLng(snap.lat!, snap.lng!),
                        width: 80,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _onSnapTapped(snap),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))
                              ]
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock, color: SetlogColors.momentoPink, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Snap', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))
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
                    onTap: () => context.push('/main/camera'),
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
