import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/utils/room_locations.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationView extends StatefulWidget {
  final Event? event;
  final SettingsController controller;

  const LocationView({
    super.key,
    required this.event,
    required this.controller,
  });

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RoomLocationInfo _locationInfo;
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  StreamSubscription<Position>? _positionStream;
  bool _isLocating = false;
  String? _distanceText;

  @override
  void initState() {
    super.initState();
    _locationInfo = RoomLocationHelper.getLocationInfo(widget.event?.room);
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.of(context).go('/eventlist');
    }
  }

  void _updateDistance() {
    if (_userLocation != null) {
      const distance = Distance();
      final meters = distance.as(LengthUnit.Meter, _userLocation!, _locationInfo.coordinates);
      if (meters < 1000) {
        _distanceText = '${meters.round()} m away';
      } else {
        _distanceText = '${(meters / 1000).toStringAsFixed(1)} km away';
      }
    } else {
      _distanceText = null;
    }
  }

  Future<void> _startLocationTracking() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled on your device.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission was denied.')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is permanently denied. Please enable in device settings.'),
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      // 1. Get current position to immediately place marker and center map
      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(currentPos.latitude, currentPos.longitude);
          _updateDistance();
          _isLocating = false;
        });
        _mapController.move(_userLocation!, 17.5);
      }

      // 2. Stream subsequent position updates
      await _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((pos) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(pos.latitude, pos.longitude);
            _updateDistance();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _onMyLocationPressed() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 17.5);
    } else {
      _startLocationTracking();
    }
  }

  Future<void> _startNavigation() async {
    // 1. Try launching native maps via geo URI
    final geoUri = _locationInfo.geoUri;
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // 2. Fallback to Google Maps directions
    final gmapsUri = Uri.parse(_locationInfo.googleMapsDirectionsUrl);
    try {
      if (await canLaunchUrl(gmapsUri)) {
        await launchUrl(gmapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // 3. Fallback to OpenStreetMap directions in browser
    final osmUri = Uri.parse(_locationInfo.openStreetMapDirectionsUrl);
    if (await canLaunchUrl(osmUri)) {
      await launchUrl(osmUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openOpenStreetMap() async {
    final osmUri = Uri.parse(_locationInfo.openStreetMapUrl);
    if (await canLaunchUrl(osmUri)) {
      await launchUrl(osmUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SimpleGestureDetector(
          onHorizontalSwipe: (SwipeDirection direction) {
            if (direction == SwipeDirection.right) {
              _goBack();
            }
          },
          swipeConfig: const SimpleSwipeConfig(
            verticalThreshold: 40.0,
            horizontalThreshold: 40.0,
            swipeDetectionBehavior: SwipeDetectionBehavior.continuousDistinct,
          ),
          child: Column(
            children: [
              // Top Bar with Back Button and Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      style: fosdemElevatedButtonStyle,
                      onPressed: _goBack,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text(
                            "Back",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationInfo.buildingName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Room: ${_locationInfo.roomName}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Selector
              Container(
                color: Colors.grey[100],
                child: TabBar(
                  controller: _tabController,
                  labelColor: fosdemBlue,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: fosdemBlue,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.map_outlined),
                      text: "OpenStreetMap",
                    ),
                    Tab(
                      icon: Icon(Icons.meeting_room_outlined),
                      text: "Room Plan",
                    ),
                    Tab(
                      icon: Icon(Icons.domain_outlined),
                      text: "Campus Map",
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: OpenStreetMap
                    _buildOsmMapView(),

                    // Tab 2: Room Floor Plan
                    _buildRoomPlanView(),

                    // Tab 3: Campus Terrain Map
                    _buildCampusTerrainView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOsmMapView() {
    final markers = <Marker>[
      // Target building marker
      Marker(
        point: _locationInfo.coordinates,
        width: 90,
        height: 90,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: fosdemBlue,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                _locationInfo.buildingCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ],
        ),
      ),
    ];

    // Live User Location Marker ("blue dot")
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _locationInfo.coordinates,
            initialZoom: 17.5,
            minZoom: 14.0,
            maxZoom: 19.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.fosdem.fosdemall',
            ),
            MarkerLayer(
              markers: markers,
            ),
            SimpleAttributionWidget(
              alignment: Alignment.bottomLeft,
              source: const Text('© OpenStreetMap contributors'),
              onTap: () => launchUrl(
                Uri.parse('https://openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),

        // OpenStreetMap Attribution Badge (Top-Left overlay, un-obscured)
        Positioned(
          left: 12,
          top: 12,
          child: InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://openstreetmap.org/copyright'),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue[800]),
                  const SizedBox(width: 4),
                  Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),


        // "My Location" Floating Action Button on the map
        Positioned(
          right: 16,
          bottom: 150,
          child: FloatingActionButton.small(
            heroTag: 'btnMyLocation',
            onPressed: _onMyLocationPressed,
            backgroundColor: Colors.white,
            foregroundColor: _userLocation != null ? Colors.blue[700] : Colors.grey[700],
            tooltip: 'My Location',
            child: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _userLocation != null ? Icons.my_location : Icons.location_searching,
                  ),
          ),
        ),

        // Floating Action Card at the bottom with navigation & distance
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white.withOpacity(0.96),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_city, color: fosdemBlue, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationInfo.buildingName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  "Room: ${_locationInfo.roomName}",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                                if (_distanceText != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.directions_walk, size: 12, color: Colors.blue[800]),
                                        const SizedBox(width: 2),
                                        Text(
                                          _distanceText!,
                                          style: TextStyle(
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startNavigation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: fosdemBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text(
                            "Navigate",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _openOpenStreetMap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: fosdemBlue,
                          side: const BorderSide(color: fosdemBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("OSM"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomPlanView() {
    if (_locationInfo.roomAssetPath != null) {
      return Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Room Floor Plan: ${_locationInfo.roomName}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
                    _locationInfo.roomAssetPath!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text("Could not load room map image."),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                "Pinch to zoom and drag to pan",
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "No floor plan diagram available for\n\"${_locationInfo.roomName}\"",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                "Please refer to the OpenStreetMap view or Campus Map for building location (${_locationInfo.buildingName}).",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCampusTerrainView() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          const Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "ULB Solbosch Campus Terrain",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.asset(
                  _locationInfo.campusAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text("Could not load campus terrain map."),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text(
              "Pinch to zoom and drag to pan",
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
