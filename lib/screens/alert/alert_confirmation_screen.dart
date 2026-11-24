import 'dart:async';

import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_status.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:alarma_comunitaria/models/emergency_alert.dart';
import 'package:alarma_comunitaria/providers/alert_provider.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:alarma_comunitaria/services/haptic_service.dart';
import 'package:alarma_comunitaria/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class AlertConfirmationScreen extends ConsumerStatefulWidget {
  const AlertConfirmationScreen({super.key});

  @override
  ConsumerState<AlertConfirmationScreen> createState() => _AlertConfirmationScreenState();
}

class _AlertConfirmationScreenState extends ConsumerState<AlertConfirmationScreen> {
  int _countdown = 3;
  Timer? _timer;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cancelled) {
        timer.cancel();
        return;
      }

      if (_countdown == 1) {
        timer.cancel();
        _submitAlert();
        return;
      }

      setState(() => _countdown--);
    });
  }

  Future<void> _submitAlert() async {
    final payload = GoRouterState.of(context).extra as Map<String, Object?>?;
    final alertType = payload?['type'] as AlertType? ?? AlertType.robbery;
    final position = payload?['position'] as Position?;
    final customDescription = payload?['description'] as String?;
    final authState = ref.read(authProvider);
    final profile = authState.profile;
    final firebaseUser = authState.firebaseUser;

    if (position == null || profile == null || firebaseUser == null || profile.communityId.isEmpty) {
      _showSnackbar('No se pudo confirmar la ubicación.');
      return;
    }

    HapticService.heavy();

    final alert = EmergencyAlert(
      id: '',
      userId: firebaseUser.uid,
      communityId: profile.communityId,
      type: alertType,
      latitude: position.latitude,
      longitude: position.longitude,
      createdAt: DateTime.now(),
      status: AlertStatus.active,
      customDescription: customDescription,
      userName: profile.name,
      manzana: profile.manzana,
      casa: profile.casa,
      barrio: profile.barrio,
      department: profile.department,
      houseDescription: profile.houseDescription,
      phone: profile.phone,
    );

    try {
      final repository = ref.read(alertRepositoryProvider);
      final alertId = await repository.createAlert(alert);

      if (alertType == AlertType.following) {
        Timer.periodic(const Duration(seconds: 4), (timer) async {
          try {
            final currentPos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
            );
            await repository.updateAlertLocation(alertId, currentPos.latitude, currentPos.longitude);
          } catch (_) {}
        });
      }

      await NotificationService().sendCommunityPushNotification(
        communityId: profile.communityId,
        emoji: alertType.emoji,
        label: alertType.label,
        userName: profile.name,
        manzana: profile.manzana,
        casa: profile.casa,
        barrio: profile.barrio,
        latitude: position.latitude,
        longitude: position.longitude,
        customDescription: customDescription,
        phone: profile.phone,
        userId: firebaseUser.uid,
      );

      if (mounted) {
        context.go('/alert-sent', extra: alert);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('No se pudo enviar la alerta. Inténtalo de nuevo.');
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = GoRouterState.of(context).extra as Map<String, Object?>?;
    final alertType = payload?['type'] as AlertType? ?? AlertType.robbery;
    final position = payload?['position'] as Position?;
    final customDescription = payload?['description'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿CONFIRMAR ALERTA?',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(alertType.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      customDescription != null && customDescription.isNotEmpty ? customDescription : alertType.label,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      position == null
                          ? 'Sin ubicación disponible'
                          : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu ubicación será compartida con los vecinos de tu comunidad.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'ENVIAR ALERTA A TODOS LOS VECINOS',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _cancelled = true;
                    _timer?.cancel();
                    context.pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(0, 64),
                  ),
                  child: const Text('CANCELAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
