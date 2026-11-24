import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:alarma_comunitaria/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LocationConfirmationScreen extends StatefulWidget {
  const LocationConfirmationScreen({super.key});

  @override
  State<LocationConfirmationScreen> createState() => _LocationConfirmationScreenState();
}

class _LocationConfirmationScreenState extends State<LocationConfirmationScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _fetchLocationAutomatically();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAutomatically() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _loading = false;
      });

      // Obtener los datos extra actuales
      final extra = GoRouterState.of(context).extra;
      AlertType alertType = AlertType.robbery;
      String? customDescription;
      if (extra is AlertType) {
        alertType = extra;
      } else if (extra is Map<String, Object?>) {
        alertType = extra['type'] as AlertType? ?? AlertType.robbery;
        customDescription = extra['description'] as String?;
      }

      // Avanzar automáticamente a la pantalla de confirmación de 3 segundos
      if (mounted) {
        context.pushReplacement('/alert-confirmation', extra: {
          'type': alertType,
          'position': position,
          'description': customDescription,
        });
      }
    } on LocationServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo obtener la ubicación automáticamente.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    AlertType alertType = AlertType.robbery;
    if (extra is AlertType) {
      alertType = extra;
    } else if (extra is Map<String, Object?>) {
      alertType = extra['type'] as AlertType? ?? AlertType.robbery;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                '${alertType.emoji} ${alertType.label}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Obteniendo tu ubicación en menos de 3 segundos...',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_loading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono de alerta en el centro con animación de pulso y escala
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Anillo de pulso exterior
                              Container(
                                width: 150 * _scaleAnimation.value,
                                height: 150 * _scaleAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withValues(alpha: 0.15 * (1.2 - _scaleAnimation.value)),
                                  border: Border.all(
                                    color: AppTheme.primary.withValues(alpha: _pulseAnimation.value),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              // Círculo central con emoji de alerta animado
                              Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.surface,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.5),
                                        blurRadius: 24,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppTheme.primary,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      alertType.emoji,
                                      style: const TextStyle(fontSize: 52),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Localizando dispositivo con alta precisión...',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _fetchLocationAutomatically,
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
