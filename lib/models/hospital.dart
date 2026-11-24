import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class Hospital {
  final String id;
  final String name;
  final String direccion;
  final double latitude;
  final double longitude;
  final double? distanceInMeters;

  /// Lista de teléfonos/celulares del hospital o guardia
  final List<String> phones;

  /// Tipo de centro de salud (ej: "Hospital Público", "Guardia 24hs", "Clínica Privada")
  final String? tipo;

  const Hospital({
    required this.id,
    required this.name,
    required this.direccion,
    required this.latitude,
    required this.longitude,
    required this.phones,
    this.distanceInMeters,
    this.tipo,
  });

  /// Primer teléfono disponible
  String get celular => phones.isNotEmpty ? phones.first : '';

  factory Hospital.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    double? userLat,
    double? userLng,
  }) {
    final data = doc.data() ?? {};
    return Hospital.fromMap(data, doc.id, userLat: userLat, userLng: userLng);
  }

  factory Hospital.fromMap(
    Map<String, dynamic> map,
    String id, {
    double? userLat,
    double? userLng,
  }) {
    double lat = 0.0;
    double lng = 0.0;

    // Soporte para GeoPoint nativo de Firestore, Map, String o List
    final rawCoords = map['coordenadas'];
    if (rawCoords is GeoPoint) {
      lat = rawCoords.latitude;
      lng = rawCoords.longitude;
    } else if (rawCoords is Map) {
      lat = (rawCoords['latitude'] ?? rawCoords['lat'])?.toDouble() ?? 0.0;
      lng = (rawCoords['longitude'] ?? rawCoords['lng'])?.toDouble() ?? 0.0;
    } else if (rawCoords is List && rawCoords.length >= 2) {
      lat = _parseCoordinate(rawCoords[0]);
      lng = _parseCoordinate(rawCoords[1]);
    } else if (rawCoords is String) {
      final parsed = _parseCoordsFromString(rawCoords);
      lat = parsed[0];
      lng = parsed[1];
    } else {
      lat = _parseCoordinate(map['latitude'] ?? map['lat']);
      lng = _parseCoordinate(map['longitude'] ?? map['lng']);
    }

    double? distance;
    if (userLat != null && userLng != null && lat != 0.0 && lng != 0.0) {
      distance = Geolocator.distanceBetween(userLat, userLng, lat, lng);
    }

    // Recopilación de todos los números de teléfono
    final Set<String> phoneSet = {};

    final celularesRaw = map['celulares'];
    if (celularesRaw is List) {
      for (final e in celularesRaw) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) phoneSet.add(s);
      }
    }

    for (int i = 1; i <= 10; i++) {
      final val = map['celular$i']?.toString().trim() ?? '';
      if (val.isNotEmpty) phoneSet.add(val);
    }

    for (final key in ['celular', 'telefono', 'phone', 'guardia', 'emergencia']) {
      final val = map[key]?.toString().trim() ?? '';
      if (val.isNotEmpty) phoneSet.add(val);
    }

    return Hospital(
      id: id,
      name: (map['name'] as String?)?.trim() ??
          (map['nombre'] as String?)?.trim() ??
          'Hospital / Guardia',
      direccion: (map['direccion'] as String?)?.trim() ??
          (map['address'] as String?)?.trim() ??
          'Sin dirección registrada',
      phones: phoneSet.toList(),
      latitude: lat,
      longitude: lng,
      distanceInMeters: distance,
      tipo: (map['tipo'] as String?)?.trim() ?? (map['type'] as String?)?.trim(),
    );
  }

  static double _parseCoordinate(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final isSouth = val.toUpperCase().contains('S');
      final isWest = val.toUpperCase().contains('W');
      final clean = val.replaceAll(RegExp(r'[^\d.-]'), '');
      double? numVal = double.tryParse(clean);
      if (numVal != null) {
        if ((isSouth || isWest) && numVal > 0) {
          numVal = -numVal;
        }
        return numVal;
      }
    }
    return 0.0;
  }

  static List<double> _parseCoordsFromString(String str) {
    final parts = str.split(',');
    if (parts.length >= 2) {
      return [_parseCoordinate(parts[0]), _parseCoordinate(parts[1])];
    }
    return [0.0, 0.0];
  }

  Hospital copyWithDistance(double userLat, double userLng) {
    if (latitude == 0.0 && longitude == 0.0) return this;
    final dist = Geolocator.distanceBetween(userLat, userLng, latitude, longitude);
    return Hospital(
      id: id,
      name: name,
      direccion: direccion,
      phones: phones,
      latitude: latitude,
      longitude: longitude,
      distanceInMeters: dist,
      tipo: tipo,
    );
  }

  /// Distancia formateada en metros o kilómetros
  String get formattedDistance {
    if (distanceInMeters == null) return 'Distancia desconocida';
    if (distanceInMeters! < 1000) {
      return '${distanceInMeters!.round()} m';
    } else {
      final km = distanceInMeters! / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Tiempo estimado de viaje en auto estilo Google Maps (~35 km/h)
  String get formattedDrivingTime {
    if (distanceInMeters == null) return 'Tiempo desconocido';

    final roadDistanceKm = (distanceInMeters! / 1000) * 1.3;
    final totalMinutes = ((roadDistanceKm / 35.0) * 60).round();

    if (totalMinutes <= 1) {
      return '1 min en auto';
    } else if (totalMinutes < 60) {
      return '$totalMinutes min en auto';
    } else {
      final hours = totalMinutes ~/ 60;
      final remainingMins = totalMinutes % 60;
      if (remainingMins == 0) {
        return '$hours h en auto';
      }
      return '$hours h $remainingMins min en auto';
    }
  }
}
