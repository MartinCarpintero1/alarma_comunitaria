import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException('El GPS está desactivado. Por favor, actívelo en su dispositivo.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          'Se requieren permisos de ubicación para enviar alertas y usar el mapa.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Los permisos de ubicación están denegados permanentemente. Habilítelos en la configuración.',
      );
    }

    return true;
  }

  Future<Position> getCurrentLocation() async {
    await requestPermission();

    // 1. Intentar obtener la última posición conocida inmediatamente como respaldo rápido
    Position? lastPosition;
    try {
      lastPosition = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    // 2. Intentar obtener posición actual con un límite estricto de 3 segundos (< 3s)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (_) {
      // Si excede los 3 segundos o falla, usar la última posición conocida si existe
      if (lastPosition != null) {
        return lastPosition;
      }

      // Si no hay última posición, intentar un intento rápido de respaldo con precisión media y 2 segundos
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 2),
          ),
        );
      } catch (_) {
        throw const LocationServiceException(
          'No se pudo obtener la ubicación actual en menos de 3 segundos. Verifique su señal GPS o intente nuevamente.',
        );
      }
    }
  }
}

class LocationServiceException implements Exception {
  final String message;

  const LocationServiceException(this.message);

  @override
  String toString() => message;
}
