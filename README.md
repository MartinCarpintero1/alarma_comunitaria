# Alarma Comunitaria

Aplicación Flutter para alertas comunitarias con enfoque en rapidez, claridad y accesibilidad.

## Stack

- Flutter
- Dart
- Material 3
- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- Geolocator
- Google Maps
- Riverpod
- Go Router

## Requisitos

- Flutter 3.13+
- Android Studio / Xcode para compilación nativa
- Firebase project configured
- Google Maps API key

## Configuración rápida

1. Ejecuta `flutter pub get`.
2. Crea un proyecto Firebase y activa Authentication, Firestore y Messaging.
3. Descarga `google-services.json` para Android y `GoogleService-Info.plist` para iOS.
4. Reemplaza los valores ficticios en `lib/firebase_options.dart` con tus credenciales reales.
5. Añade tu API key de Google Maps en las plataformas correspondientes.
6. Ejecuta la app con `flutter run`.

## Estructura

```text
lib/
  app/
  models/
  providers/
  repositories/
  screens/
  services/
  widgets/
```

## Firestore sugerido

```text
alerts/
  alertId/
    userId
    communityId
    type
    latitude
    longitude
    createdAt
    status
    resolvedBy
    resolvedAt
```

## Nota

La app está preparada para conectarse a Firebase y Google Maps reales. Las credenciales deben configurarse manualmente para no guardar secretos en el repositorio.
