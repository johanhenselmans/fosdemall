import 'package:latlong2/latlong.dart';

class RoomLocationInfo {
  final String roomName;
  final String buildingName;
  final String buildingCode;
  final LatLng coordinates;
  final String? roomAssetPath;
  final String campusAssetPath;

  const RoomLocationInfo({
    required this.roomName,
    required this.buildingName,
    required this.buildingCode,
    required this.coordinates,
    this.roomAssetPath,
    this.campusAssetPath = 'assets/maps/ulb_solbosch.png',
  });

  /// OpenStreetMap URL centered on building marker
  String get openStreetMapUrl =>
      'https://www.openstreetmap.org/?mlat=${coordinates.latitude}&mlon=${coordinates.longitude}#map=18/${coordinates.latitude}/${coordinates.longitude}';

  /// OpenStreetMap directions URL
  String get openStreetMapDirectionsUrl =>
      'https://www.openstreetmap.org/directions?engine=fossgis_osrm_foot&route=%2C${coordinates.latitude}%2C${coordinates.longitude}';

  /// Universal Google Maps navigation URL
  String get googleMapsDirectionsUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=${coordinates.latitude},${coordinates.longitude}';

  /// Apple Maps navigation URL
  String get appleMapsDirectionsUrl =>
      'https://maps.apple.com/?daddr=${coordinates.latitude},${coordinates.longitude}&dirflg=w';

  /// Geo URI for launching native map application
  Uri get geoUri => Uri.parse(
        'geo:${coordinates.latitude},${coordinates.longitude}?q=${coordinates.latitude},${coordinates.longitude}(${Uri.encodeComponent('$buildingName - $roomName')})',
      );
}

class RoomLocationHelper {
  // Known ULB Solbosch Campus Building Coordinates (derived from OpenStreetMap)
  static const LatLng buildingJCoordinates = LatLng(50.8131305, 4.3794405);
  static const LatLng buildingKCoordinates = LatLng(50.8147335, 4.3818078);
  static const LatLng buildingHCoordinates = LatLng(50.8128642, 4.3801921);
  static const LatLng buildingUCoordinates = LatLng(50.8122095, 4.3826605);
  static const LatLng buildingACoordinates = LatLng(50.8117216, 4.3810881);
  static const LatLng campusCenterCoordinates = LatLng(50.8124400, 4.3792100);

  // Set of all available room map assets in assets/maps/
  static const Set<String> availableRoomAssets = {
    'AW1.105',
    'AW1.117',
    'AW1.120',
    'AW1.121',
    'AW1.124',
    'AW1.125',
    'AW1.126',
    'Chavanne',
    'Ferrer',
    'H.1301 (Cornil)',
    'H.1301',
    'H.1302 (Depage)',
    'H.1302 (Depagne)',
    'H.1302',
    'H.1308 (Rolin)',
    'H.1308',
    'H.1309 (Van Rijn)',
    'H.1309',
    'H.2213',
    'H.2214',
    'H.2215 (Ferrer)',
    'H.3327',
    'Janson',
    'K.1.105 (La Fontaine)',
    'K.1.105',
    'K.3.201',
    'K.3.401',
    'K.3.601',
    'K.4.201',
    'K.4.401',
    'K.4.601',
    'Lameere',
    'UA2.114 (Baudoux)',
    'UA2.114',
    'UB2.147',
    'UB2.252A (Lameere)',
    'UD2.120 (Chavanne)',
    'UD2.218A',
  };

  /// Resolves the room image asset path if one is available.
  static String? getRoomAssetPath(String? rawRoom) {
    if (rawRoom == null || rawRoom.trim().isEmpty) return null;
    final clean = rawRoom.trim();

    // 1. Direct match
    if (availableRoomAssets.contains(clean)) {
      return 'assets/maps/$clean.png';
    }

    // 2. Try stripped parentheses (e.g. "K.1.105 (La Fontaine)" -> "K.1.105")
    final parenIndex = clean.indexOf('(');
    if (parenIndex > 0) {
      final base = clean.substring(0, parenIndex).trim();
      if (availableRoomAssets.contains(base)) {
        return 'assets/maps/$base.png';
      }
      // Also check content inside parentheses (e.g. "Chavanne" from "UD2.120 (Chavanne)")
      final insideParen = clean.substring(parenIndex + 1).replaceAll(')', '').trim();
      if (availableRoomAssets.contains(insideParen)) {
        return 'assets/maps/$insideParen.png';
      }
    }

    // 3. Known special mappings / aliases
    final lower = clean.toLowerCase();
    if (lower.contains('janson')) {
      return 'assets/maps/Janson.png';
    }
    if (lower.contains('chavanne')) {
      return 'assets/maps/UD2.120 (Chavanne).png';
    }
    if (lower.contains('ferrer')) {
      return 'assets/maps/H.2215 (Ferrer).png';
    }
    if (lower.contains('lameere')) {
      return 'assets/maps/UB2.252A (Lameere).png';
    }
    if (lower.contains('la fontaine') || lower.contains('fontaine')) {
      return 'assets/maps/K.1.105 (La Fontaine).png';
    }
    if (lower.contains('cornil')) {
      return 'assets/maps/H.1301 (Cornil).png';
    }
    if (lower.contains('depage')) {
      return 'assets/maps/H.1302 (Depage).png';
    }
    if (lower.contains('rolin')) {
      return 'assets/maps/H.1308 (Rolin).png';
    }
    if (lower.contains('van rijn')) {
      return 'assets/maps/H.1309 (Van Rijn).png';
    }
    if (lower.contains('baudoux')) {
      return 'assets/maps/UA2.114 (Baudoux).png';
    }

    // 4. Dot-stripped variations (e.g. "J1.106" -> "J.1.106")
    for (final asset in availableRoomAssets) {
      if (asset.toLowerCase() == lower) {
        return 'assets/maps/$asset.png';
      }
    }

    return null;
  }

  /// Resolves location information (building, coordinates, assets) for a room.
  static RoomLocationInfo getLocationInfo(String? rawRoom) {
    final room = (rawRoom == null || rawRoom.trim().isEmpty) ? 'Unknown' : rawRoom.trim();
    final roomUpper = room.toUpperCase();
    final roomAsset = getRoomAssetPath(rawRoom);

    // Janson / Building J
    if (roomUpper.contains('JANSON') || roomUpper.startsWith('J.') || roomUpper.startsWith('J1')) {
      return RoomLocationInfo(
        roomName: room,
        buildingName: 'Building J (Auditoire Paul-Émile Janson)',
        buildingCode: 'J',
        coordinates: buildingJCoordinates,
        roomAssetPath: roomAsset,
      );
    }

    // Building K
    if (roomUpper.startsWith('K.') || roomUpper.startsWith('K1') || roomUpper.startsWith('K3') || roomUpper.startsWith('K4') || roomUpper.contains('LA FONTAINE')) {
      return RoomLocationInfo(
        roomName: room,
        buildingName: 'Building K',
        buildingCode: 'K',
        coordinates: buildingKCoordinates,
        roomAssetPath: roomAsset,
      );
    }

    // Building H
    if (roomUpper.startsWith('H.') || roomUpper.startsWith('H1') || roomUpper.startsWith('H2') || roomUpper.startsWith('H3') || roomUpper.contains('FERRER') || roomUpper.contains('CORNIL') || roomUpper.contains('DEPAGE') || roomUpper.contains('ROLIN') || roomUpper.contains('VAN RIJN')) {
      return RoomLocationInfo(
        roomName: room,
        buildingName: 'Building H',
        buildingCode: 'H',
        coordinates: buildingHCoordinates,
        roomAssetPath: roomAsset,
      );
    }

    // Building U (UA, UB, UD, U)
    if (roomUpper.startsWith('U.') || roomUpper.startsWith('UA') || roomUpper.startsWith('UB') || roomUpper.startsWith('UD') || roomUpper.contains('CHAVANNE') || roomUpper.contains('LAMEERE') || roomUpper.contains('BAUDOUX') || roomUpper.contains('GUILLISSEN') || roomUpper.contains('HENRIOT') || roomUpper.contains('DECROLY')) {
      return RoomLocationInfo(
        roomName: room,
        buildingName: 'Building U',
        buildingCode: 'U',
        coordinates: buildingUCoordinates,
        roomAssetPath: roomAsset,
      );
    }

    // Building AW / A
    if (roomUpper.startsWith('AW') || roomUpper.startsWith('A.') || roomUpper.startsWith('AY')) {
      return RoomLocationInfo(
        roomName: room,
        buildingName: 'Building A (AW - Aile Ouest)',
        buildingCode: 'AW',
        coordinates: buildingACoordinates,
        roomAssetPath: roomAsset,
      );
    }

    // Default fallback: ULB Solbosch Campus
    return RoomLocationInfo(
      roomName: room,
      buildingName: 'ULB Campus Solbosch',
      buildingCode: 'Campus',
      coordinates: campusCenterCoordinates,
      roomAssetPath: roomAsset,
    );
  }
}
