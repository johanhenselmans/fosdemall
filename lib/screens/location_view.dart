import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/utils/room_locations.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _locationInfo = RoomLocationHelper.getLocationInfo(widget.event?.room);
    // Determine default tab: if room plan is available, default to OSM (index 0), else index 0
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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
    return Stack(
      children: [
        FlutterMap(
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
              markers: [
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
              ],
            ),
          ],
        ),

        // Floating Action Card at the bottom with navigation
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white.withOpacity(0.95),
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
                            Text(
                              "Room: ${_locationInfo.roomName}",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
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
