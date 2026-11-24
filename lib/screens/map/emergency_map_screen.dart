import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:alarma_comunitaria/models/bombero.dart';
import 'package:alarma_comunitaria/models/comisaria.dart';
import 'package:alarma_comunitaria/models/emergency_alert.dart';
import 'package:alarma_comunitaria/models/hospital.dart';
import 'package:alarma_comunitaria/models/user_model.dart';
import 'package:alarma_comunitaria/providers/alert_provider.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:alarma_comunitaria/repositories/bombero_repository.dart';
import 'package:alarma_comunitaria/repositories/comisaria_repository.dart';
import 'package:alarma_comunitaria/repositories/hospital_repository.dart';
import 'package:alarma_comunitaria/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

class EmergencyMapScreen extends ConsumerStatefulWidget {
  const EmergencyMapScreen({super.key});

  @override
  ConsumerState<EmergencyMapScreen> createState() => _EmergencyMapScreenState();
}

class _EmergencyMapScreenState extends ConsumerState<EmergencyMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(-33.032, -68.587); // Default
  LatLng? _userLatLng;
  bool _loadingLocation = true;
  bool _initializedTarget = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedTarget) {
      _initializedTarget = true;
      final extra = GoRouterState.of(context).extra;
      if (extra is EmergencyAlert) {
        _center = LatLng(extra.latitude, extra.longitude);
        _loadingLocation = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animatedMapMove(_center, 17.0);
        });
        _initUserLocationOnly();
      } else {
        _initLocation();
      }
    }
  }

  /// Desplaza suavemente el mapa hacia las coordenadas y zoom objetivo
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _initLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (mounted) {
        final target = LatLng(position.latitude, position.longitude);
        setState(() {
          _center = target;
          _userLatLng = target;
          _loadingLocation = false;
        });
        _animatedMapMove(target, 15.5);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  Future<void> _initUserLocationOnly() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLatLng = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (_) {}
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else {
      return 'Hace ${diff.inDays} d';
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODAL: LISTADO DE ALERTAS ACTIVAS
  // ───────────────────────────────────────────────────────────────────────────
  void _showActiveAlertsListModal(
    BuildContext context,
    List<EmergencyAlert> alerts,
    List<Hospital> hospitals,
    List<Comisaria> comisarias,
    List<Bombero> bomberos,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ALERTAS ACTIVAS EN LA RED (${alerts.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toca una para volar en el mapa a su ubicación exacta',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: alerts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        final timeAgo = _formatTimeAgo(alert.createdAt);
                        final isMedical = alert.type == AlertType.medical;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(bottomSheetContext);
                              final targetLatLng = LatLng(alert.latitude, alert.longitude);
                              _animatedMapMove(targetLatLng, 17.5);

                              Future.delayed(const Duration(milliseconds: 950), () {
                                if (mounted) {
                                  _showAlertDetailsModal(this.context, alert, hospitals, comisarias, bomberos, isDark);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMedical
                                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: isMedical
                                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                          : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(alert.type.emoji, style: const TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                alert.type.label,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                timeAgo,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFEF4444),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Vecino: ${alert.userName ?? 'Vecino'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        if (alert.customDescription != null && alert.customDescription!.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            '💬 "${alert.customDescription}"',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          '📍 Mz: ${alert.manzana ?? '-'} • Casa: ${alert.casa ?? '-'} • ${alert.barrio ?? ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.my_location_rounded, color: Color(0xFFEF4444), size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODAL: LISTADO DE COMISARÍAS
  // ───────────────────────────────────────────────────────────────────────────
  void _showComisariasListModal(BuildContext context, List<Comisaria> comisarias, bool isDark) {
    final sortedList = List<Comisaria>.from(comisarias);
    if (_userLatLng != null) {
      for (int i = 0; i < sortedList.length; i++) {
        sortedList[i] = sortedList[i].copyWithDistance(
          _userLatLng!.latitude,
          _userLatLng!.longitude,
        );
      }
      sortedList.sort((a, b) {
        final distA = a.distanceInMeters ?? double.infinity;
        final distB = b.distanceInMeters ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.local_police_rounded,
                          color: Color(0xFF3B82F6),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMISARÍAS EN LA RED',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toca una para centrarla en el mapa y ver opciones de llamada',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón 911 arriba
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => HospitalRepository.call911(),
                      icon: const Icon(Icons.shield_rounded, size: 20),
                      label: const Text(
                        'LLAMAR DIRECTO AL 911 (POLICÍA)',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (sortedList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 36, color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron documentos en la colección "comisarias".',
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sortedList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final comisaria = sortedList[index];
                          final hasCoords = comisaria.latitude != 0.0 || comisaria.longitude != 0.0;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pop(bottomSheetContext);

                                if (hasCoords) {
                                  final targetLatLng = LatLng(comisaria.latitude, comisaria.longitude);
                                  _animatedMapMove(targetLatLng, 17.0);

                                  Future.delayed(const Duration(milliseconds: 950), () {
                                    if (mounted) {
                                      _showComisariaDetails(this.context, comisaria, isDark);
                                    }
                                  });
                                } else {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Esta comisaría no tiene coordenadas válidas.')),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_police_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comisaria.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            comisaria.direccion,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (comisaria.distanceInMeters != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF60A5FA)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  comisaria.formattedDistance,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF60A5FA),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(Icons.directions_car_rounded, size: 14, color: Color(0xFF22C55E)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  comisaria.formattedDrivingTime,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF22C55E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.call_rounded, color: Color(0xFF22C55E)),
                                      tooltip: comisaria.phones.isNotEmpty
                                          ? 'Llamar al ${comisaria.phones.first}'
                                          : 'Sin teléfono',
                                      onPressed: comisaria.phones.isEmpty
                                          ? null
                                          : () => ComisariaRepository.callComisaria(comisaria.phones.first),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF60A5FA)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODAL: LISTADO DE HOSPITALES Y GUARDIAS
  // ───────────────────────────────────────────────────────────────────────────
  void _showHospitalsListModal(BuildContext context, List<Hospital> hospitals, bool isDark) {
    final sortedList = List<Hospital>.from(hospitals);
    if (_userLatLng != null) {
      for (int i = 0; i < sortedList.length; i++) {
        sortedList[i] = sortedList[i].copyWithDistance(
          _userLatLng!.latitude,
          _userLatLng!.longitude,
        );
      }
      sortedList.sort((a, b) {
        final distA = a.distanceInMeters ?? double.infinity;
        final distB = b.distanceInMeters ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Color(0xFF10B981),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOSPITALES Y GUARDIAS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toca uno para centrarlo en el mapa y ver teléfonos de emergencia',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón 911 Emergencias
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => HospitalRepository.call911(),
                      icon: const Icon(Icons.shield_rounded, size: 20),
                      label: const Text(
                        'LLAMAR DIRECTO AL 911 (EMERGENCIAS)',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (sortedList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 36, color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron documentos en la colección "hospitales".',
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sortedList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final hospital = sortedList[index];
                          final hasCoords = hospital.latitude != 0.0 || hospital.longitude != 0.0;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pop(bottomSheetContext);

                                if (hasCoords) {
                                  final targetLatLng = LatLng(hospital.latitude, hospital.longitude);
                                  _animatedMapMove(targetLatLng, 17.0);

                                  Future.delayed(const Duration(milliseconds: 950), () {
                                    if (mounted) {
                                      _showHospitalDetails(this.context, hospital, isDark);
                                    }
                                  });
                                } else {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Este hospital no tiene coordenadas válidas.')),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_hospital_rounded,
                                        color: Color(0xFF10B981),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hospital.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            hospital.direccion,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (hospital.distanceInMeters != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF34D399)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  hospital.formattedDistance,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF34D399),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(Icons.directions_car_rounded, size: 14, color: Color(0xFF10B981)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  hospital.formattedDrivingTime,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981)),
                                      tooltip: hospital.phones.isNotEmpty
                                          ? 'Llamar al ${hospital.phones.first}'
                                          : 'Sin teléfono',
                                      onPressed: hospital.phones.isEmpty
                                          ? null
                                          : () => HospitalRepository.callPhone(hospital.phones.first),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF34D399)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODAL: LISTADO DE BOMBEROS
  // ───────────────────────────────────────────────────────────────────────────
  void _showBomberosListModal(BuildContext context, List<Bombero> bomberos, bool isDark) {
    final sortedList = List<Bombero>.from(bomberos);
    if (_userLatLng != null) {
      for (int i = 0; i < sortedList.length; i++) {
        sortedList[i] = sortedList[i].copyWithDistance(
          _userLatLng!.latitude,
          _userLatLng!.longitude,
        );
      }
      sortedList.sort((a, b) {
        final distA = a.distanceInMeters ?? double.infinity;
        final distB = b.distanceInMeters ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF97316), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFF97316),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUARTELES DE BOMBEROS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toca uno para centrarlo en el mapa y ver teléfonos de guardia',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón 911 Emergencias
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => HospitalRepository.call911(),
                      icon: const Icon(Icons.shield_rounded, size: 20),
                      label: const Text(
                        'LLAMAR DIRECTO AL 911 (EMERGENCIAS)',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (sortedList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 36, color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron documentos en la colección "bomberos".',
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sortedList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final bombero = sortedList[index];
                          final hasCoords = bombero.latitude != 0.0 || bombero.longitude != 0.0;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pop(bottomSheetContext);

                                if (hasCoords) {
                                  final targetLatLng = LatLng(bombero.latitude, bombero.longitude);
                                  _animatedMapMove(targetLatLng, 17.0);

                                  Future.delayed(const Duration(milliseconds: 950), () {
                                    if (mounted) {
                                      _showBomberoDetails(this.context, bombero, isDark);
                                    }
                                  });
                                } else {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Este cuartel no tiene coordenadas válidas.')),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFFF97316).withValues(alpha: 0.3)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF97316).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Color(0xFFF97316),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bombero.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            bombero.direccion,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (bombero.distanceInMeters != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFFF97316)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  bombero.formattedDistance,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFF97316),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(Icons.directions_car_rounded, size: 14, color: Color(0xFFF97316)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  bombero.formattedDrivingTime,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFF97316),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.call_rounded, color: Color(0xFFF97316)),
                                      tooltip: bombero.phones.isNotEmpty
                                          ? 'Llamar al ${bombero.phones.first}'
                                          : 'Sin teléfono',
                                      onPressed: bombero.phones.isEmpty
                                          ? null
                                          : () => BomberoRepository.callPhone(bombero.phones.first),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFF97316)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODAL: LISTADO COMPLETO DE MIEMBROS EN LA RED
  // ───────────────────────────────────────────────────────────────────────────
  void _showCommunityNeighborsListModal(BuildContext context, String communityId, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final neighborsAsync = ref.watch(communityNeighborsStreamProvider(communityId));

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: Color(0xFF3B82F6),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MIEMBROS EN LA RED',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Código de Red: $communityId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF60A5FA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      neighborsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Cargando miembros de la red...'),
                              ],
                            ),
                          ),
                        ),
                        error: (err, stack) => Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Error al cargar vecinos: $err',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        data: (neighborsList) {
                          if (neighborsList.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'No se encontraron miembros registrados en esta red.',
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${neighborsList.length} VECINO${neighborsList.length == 1 ? '' : 'S'} REGISTRADO${neighborsList.length == 1 ? '' : 'S'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF60A5FA),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: neighborsList.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final neighbor = neighborsList[index];
                                      final roleLabel = neighbor.role == UserRole.admin
                                          ? 'ADMINISTRADOR'
                                          : neighbor.role == UserRole.security
                                              ? 'SEGURIDAD'
                                              : 'RESIDENTE';

                                      final roleColor = neighbor.role == UserRole.admin
                                          ? const Color(0xFFEC4899)
                                          : neighbor.role == UserRole.security
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFF3B82F6);

                                      return Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: roleColor.withValues(alpha: 0.2),
                                                  child: Text(
                                                    neighbor.name.isNotEmpty
                                                        ? neighbor.name.substring(0, 1).toUpperCase()
                                                        : '👤',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w900,
                                                      color: roleColor,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              neighbor.name.isNotEmpty ? neighbor.name : 'Vecino sin nombre',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w900,
                                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: roleColor.withValues(alpha: 0.15),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              roleLabel,
                                                              style: TextStyle(
                                                                color: roleColor,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w900,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (neighbor.email.isNotEmpty) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          neighbor.email,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),

                                            // Ficha de dirección completa
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 6,
                                              children: [
                                                if (neighbor.manzana.isNotEmpty)
                                                  _buildInfoTag('🏠 Mz / Sector:', neighbor.manzana, isDark),
                                                if (neighbor.casa.isNotEmpty)
                                                  _buildInfoTag('🏡 Casa / Lote:', neighbor.casa, isDark),
                                                if (neighbor.department.isNotEmpty)
                                                  _buildInfoTag('🏢 Dpto:', neighbor.department, isDark),
                                                if (neighbor.barrio.isNotEmpty)
                                                  _buildInfoTag('📍 Barrio / Dirección:', neighbor.barrio, isDark),
                                              ],
                                            ),

                                            if (neighbor.houseDescription.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                '📝 Referencia: ${neighbor.houseDescription}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                                ),
                                              ),
                                            ],

                                            if (neighbor.phone.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                width: double.infinity,
                                                child: FilledButton.icon(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                                    foregroundColor: const Color(0xFF2563EB),
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  onPressed: () => HospitalRepository.callPhone(neighbor.phone),
                                                  icon: const Icon(Icons.call_rounded, size: 16),
                                                  label: Text(
                                                    'Llamar al ${neighbor.phone}',
                                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoTag(String label, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DETALLES DE COMISARÍA
  // ───────────────────────────────────────────────────────────────────────────
  void _showComisariaDetails(BuildContext context, Comisaria comisaria, bool isDark) {
    Comisaria comisariaWithDistance = comisaria;
    if (_userLatLng != null) {
      comisariaWithDistance = comisaria.copyWithDistance(
        _userLatLng!.latitude,
        _userLatLng!.longitude,
      );
    }

    List<Widget> buildCallButtons(Comisaria c) {
      if (c.phones.isEmpty) {
        return [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: null,
              icon: const Icon(Icons.call_rounded, size: 22),
              label: const Text('SIN TELÉFONO REGISTRADO'),
            ),
          ),
        ];
      }
      final buttons = <Widget>[];
      for (int i = 0; i < c.phones.length; i++) {
        final phone = c.phones[i];
        final isLast = i == c.phones.length - 1;
        buttons.add(
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: i == 0 ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final ok = await ComisariaRepository.callComisaria(phone);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo llamar al $phone')),
                    );
                  }
                },
                icon: const Icon(Icons.call_rounded, size: 22),
                label: Text(
                  c.phones.length == 1 ? 'LLAMAR A COMISARÍA ($phone)' : 'LLAMAR: $phone',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }
      return buttons;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.local_police_rounded,
                        color: Color(0xFF3B82F6),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'POLICÍA / COMISARÍA',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comisariaWithDistance.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Botón directo al 911
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => HospitalRepository.call911(),
                    icon: const Icon(Icons.shield_rounded, size: 20),
                    label: const Text(
                      'LLAMAR DIRECTO AL 911 (EMERGENCIAS)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                if (comisariaWithDistance.distanceInMeters != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A).withValues(alpha: 0.4), const Color(0xFF0F172A)]
                            : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car_rounded, color: Color(0xFF22C55E), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comisariaWithDistance.formattedDrivingTime,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A ${comisariaWithDistance.formattedDistance} de tu ubicación',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            foregroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (comisariaWithDistance.latitude == 0.0 && comisariaWithDistance.longitude == 0.0)
                              ? null
                              : () => ComisariaRepository.openNavigation(
                                    comisariaWithDistance.latitude,
                                    comisariaWithDistance.longitude,
                                  ),
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: const Text('Maps', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFEF4444)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dirección',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  comisariaWithDistance.direccion,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.phone_rounded, size: 20, color: Color(0xFF22C55E)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comisariaWithDistance.phones.length > 1 ? 'Teléfonos / Celulares' : 'Teléfono / Celular',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (comisariaWithDistance.phones.isEmpty)
                                  Text(
                                    'Sin teléfono registrado',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  )
                                else
                                  ...comisariaWithDistance.phones.map(
                                    (phone) => Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                ...buildCallButtons(comisariaWithDistance),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DETALLES DE HOSPITAL
  // ───────────────────────────────────────────────────────────────────────────
  void _showHospitalDetails(BuildContext context, Hospital hospital, bool isDark) {
    Hospital hospitalWithDistance = hospital;
    if (_userLatLng != null) {
      hospitalWithDistance = hospital.copyWithDistance(
        _userLatLng!.latitude,
        _userLatLng!.longitude,
      );
    }

    List<Widget> buildCallButtons(Hospital h) {
      if (h.phones.isEmpty) {
        return [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: null,
              icon: const Icon(Icons.call_rounded, size: 22),
              label: const Text('SIN TELÉFONO REGISTRADO'),
            ),
          ),
        ];
      }
      final buttons = <Widget>[];
      for (int i = 0; i < h.phones.length; i++) {
        final phone = h.phones[i];
        final isLast = i == h.phones.length - 1;
        buttons.add(
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: i == 0 ? const Color(0xFF10B981) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final ok = await HospitalRepository.callPhone(phone);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo llamar al $phone')),
                    );
                  }
                },
                icon: const Icon(Icons.call_rounded, size: 22),
                label: Text(
                  h.phones.length == 1 ? 'LLAMAR A GUARDIA / HOSPITAL ($phone)' : 'LLAMAR: $phone',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }
      return buttons;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Color(0xFF10B981),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hospitalWithDistance.tipo?.toUpperCase() ?? 'HOSPITAL / GUARDIA MÉDICA',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hospitalWithDistance.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Botón directo al 911
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => HospitalRepository.call911(),
                    icon: const Icon(Icons.shield_rounded, size: 20),
                    label: const Text(
                      'LLAMAR DIRECTO AL 911 (EMERGENCIAS)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                if (hospitalWithDistance.distanceInMeters != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF064E3B).withValues(alpha: 0.4), const Color(0xFF0F172A)]
                            : [const Color(0xFFECFDF5), const Color(0xD1D1FAE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car_rounded, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospitalWithDistance.formattedDrivingTime,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A ${hospitalWithDistance.formattedDistance} de tu ubicación',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                            foregroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (hospitalWithDistance.latitude == 0.0 && hospitalWithDistance.longitude == 0.0)
                              ? null
                              : () => HospitalRepository.openNavigation(
                                    hospitalWithDistance.latitude,
                                    hospitalWithDistance.longitude,
                                  ),
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: const Text('Maps', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFEF4444)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dirección',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hospitalWithDistance.direccion,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.phone_rounded, size: 20, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hospitalWithDistance.phones.length > 1 ? 'Teléfonos / Guardia' : 'Teléfono / Guardia',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (hospitalWithDistance.phones.isEmpty)
                                  Text(
                                    'Sin teléfono registrado',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  )
                                else
                                  ...hospitalWithDistance.phones.map(
                                    (phone) => Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                ...buildCallButtons(hospitalWithDistance),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DETALLES DE BOMBERO
  // ───────────────────────────────────────────────────────────────────────────
  void _showBomberoDetails(BuildContext context, Bombero bombero, bool isDark) {
    Bombero bomberoWithDistance = bombero;
    if (_userLatLng != null) {
      bomberoWithDistance = bombero.copyWithDistance(
        _userLatLng!.latitude,
        _userLatLng!.longitude,
      );
    }

    List<Widget> buildCallButtons(Bombero b) {
      if (b.phones.isEmpty) {
        return [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: null,
              icon: const Icon(Icons.call_rounded, size: 22),
              label: const Text('SIN TELÉFONO REGISTRADO'),
            ),
          ),
        ];
      }
      final buttons = <Widget>[];
      for (int i = 0; i < b.phones.length; i++) {
        final phone = b.phones[i];
        final isLast = i == b.phones.length - 1;
        buttons.add(
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: i == 0 ? const Color(0xFFF97316) : const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final ok = await BomberoRepository.callPhone(phone);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo llamar al $phone')),
                    );
                  }
                },
                icon: const Icon(Icons.call_rounded, size: 22),
                label: Text(
                  b.phones.length == 1 ? 'LLAMAR A BOMBEROS ($phone)' : 'LLAMAR: $phone',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }
      return buttons;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF97316), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFF97316),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bomberoWithDistance.tipo?.toUpperCase() ?? 'CUARTEL DE BOMBEROS',
                              style: const TextStyle(
                                color: Color(0xFFF97316),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bomberoWithDistance.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Botón directo al 911
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => HospitalRepository.call911(),
                    icon: const Icon(Icons.shield_rounded, size: 20),
                    label: const Text(
                      'LLAMAR DIRECTO AL 911 (EMERGENCIAS)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                if (bomberoWithDistance.distanceInMeters != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF7C2D12).withValues(alpha: 0.4), const Color(0xFF0F172A)]
                            : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car_rounded, color: Color(0xFFF97316), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bomberoWithDistance.formattedDrivingTime,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF97316),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A ${bomberoWithDistance.formattedDistance} de tu ubicación',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.2),
                            foregroundColor: const Color(0xFFF97316),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (bomberoWithDistance.latitude == 0.0 && bomberoWithDistance.longitude == 0.0)
                              ? null
                              : () => BomberoRepository.openNavigation(
                                    bomberoWithDistance.latitude,
                                    bomberoWithDistance.longitude,
                                  ),
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: const Text('Maps', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFFF97316).withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFEF4444)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dirección',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bomberoWithDistance.direccion,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.phone_rounded, size: 20, color: Color(0xFFF97316)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bomberoWithDistance.phones.length > 1 ? 'Teléfonos / Guardia' : 'Teléfono / Guardia',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (bomberoWithDistance.phones.isEmpty)
                                  Text(
                                    'Sin teléfono registrado',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  )
                                else
                                  ...bomberoWithDistance.phones.map(
                                    (phone) => Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                ...buildCallButtons(bomberoWithDistance),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DETALLES DE UNA ALERTA ESPECÍFICA CON OPCIONES DE EMERGENCIAS Y TELÉFONOS
  // ───────────────────────────────────────────────────────────────────────────
  void _showAlertDetailsModal(
    BuildContext context,
    EmergencyAlert alert,
    List<Hospital> hospitals,
    List<Comisaria> comisarias,
    List<Bombero> bomberos,
    bool isDark,
  ) {
    final authState = ref.read(authProvider);
    final firebaseUser = authState.firebaseUser;
    final isMedical = alert.type == AlertType.medical;
    final isFire = alert.type == AlertType.fire;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(alert.type.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.type.label,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimeAgo(alert.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (alert.customDescription != null && alert.customDescription!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      '💬 "${alert.customDescription}"',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? Colors.amberAccent : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Datos del vecino en peligro
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vecino: ${alert.userName ?? 'Vecino de la red'}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '🏠 Manzana / Sector: ${alert.manzana?.isEmpty ?? true ? 'No especificada' : alert.manzana}',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                      Text(
                        '🏡 Casa / Lote: ${alert.casa?.isEmpty ?? true ? 'No especificada' : alert.casa}',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                      if (alert.department != null && alert.department!.isNotEmpty)
                        Text(
                          '🏢 Departamento: ${alert.department}',
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      Text(
                        '📍 Barrio: ${alert.barrio?.isEmpty ?? true ? 'No especificado' : alert.barrio}',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                      if (alert.houseDescription != null && alert.houseDescription!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📝 Referencia: ${alert.houseDescription}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                      if (alert.phone != null && alert.phone!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '📱 Celular / Teléfono: ${alert.phone}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => HospitalRepository.callPhone(alert.phone!),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: Text(
                              'LLAMAR AL VECINO (${alert.phone})',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── SECCIÓN DE LLAMADAS A EMERGENCIAS ─────────────────────────
                Text(
                  'LLAMAR A SERVICIOS DE EMERGENCIA',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Botón único de emergencia 911
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => HospitalRepository.call911(),
                    icon: const Icon(Icons.shield_rounded, size: 20),
                    label: const Text(
                      'LLAMAR DIRECTO AL 911 (EMERGENCIAS)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),

                // Sección Comisarías más cercanas (siempre para todas las alertas)
                if (comisarias.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'COMISARÍAS MÁS CERCANAS (POLICÍA)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3B82F6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...comisarias.take(2).map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showComisariaDetails(this.context, c, isDark);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_police_rounded, color: Color(0xFF3B82F6), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (c.phones.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => ComisariaRepository.callComisaria(c.phones.first),
                                  icon: const Icon(Icons.call_rounded, size: 16, color: Color(0xFF3B82F6)),
                                  label: const Text('Llamar', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],

                // Si es Alerta Médica, mostrar TAMBIÉN accesos a hospitales más cercanos
                if (isMedical && hospitals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'HOSPITALES Y GUARDIAS MÁS CERCANAS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...hospitals.take(2).map((h) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showHospitalDetails(this.context, h, isDark);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_hospital_rounded, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  h.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (h.phones.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => HospitalRepository.callPhone(h.phones.first),
                                  icon: const Icon(Icons.call_rounded, size: 16, color: Color(0xFF10B981)),
                                  label: const Text('Llamar', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],

                // Si es Alerta de Incendio, mostrar TAMBIÉN accesos a cuarteles de bomberos
                if (isFire && bomberos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'CUARTELES DE BOMBEROS MÁS CERCANOS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF97316),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...bomberos.take(2).map((b) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showBomberoDetails(this.context, b, isDark);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (b.phones.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => BomberoRepository.callPhone(b.phones.first),
                                  icon: const Icon(Icons.call_rounded, size: 16, color: Color(0xFFF97316)),
                                  label: const Text('Llamar', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${alert.viewsCount} vecinos vieron esta alerta',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    if (firebaseUser != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: alert.userId == firebaseUser.uid ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No puedes marcar como vista tu propia alerta.')),
                            );
                          } : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref.read(alertRepositoryProvider).markAsViewed(alert.id, firebaseUser.uid);
                            if (bottomSheetContext.mounted) {
                              Navigator.pop(bottomSheetContext);
                              messenger.showSnackBar(
                                const SnackBar(content: Text('¡Marcado como visto!')),
                              );
                            }
                          },
                          icon: Icon(Icons.touch_app_rounded, color: alert.userId == firebaseUser.uid ? Colors.grey : const Color(0xFF2563EB)),
                          label: Text(
                            alert.userId == firebaseUser.uid ? 'Tu alerta (${alert.viewsCount})' : 'Visto (${alert.viewsCount})',
                            style: TextStyle(color: alert.userId == firebaseUser.uid ? Colors.grey : const Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (firebaseUser != null) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD METHOD
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final firebaseUser = authState.firebaseUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState.status != AuthStatus.authenticated || profile == null || firebaseUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeAlertsAsync = ref.watch(activeAlertsProvider(profile.communityId));
    final comisariasAsync = ref.watch(comisariasStreamProvider);
    final hospitalsAsync = ref.watch(hospitalesStreamProvider);
    final bomberosAsync = ref.watch(bomberosStreamProvider);

    final alertsList = activeAlertsAsync.value ?? [];
    final comisariasList = comisariasAsync.value ?? [];
    final hospitalsList = hospitalsAsync.value ?? [];
    final bomberosList = bomberosAsync.value ?? [];

    // Lista unificada de marcadores para el mapa
    final List<Marker> markers = [];

    // 1. Marcador "Aquí estoy" del usuario
    if (_userLatLng != null) {
      markers.add(
        Marker(
          point: _userLatLng!,
          width: 100,
          height: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2)),
                  ],
                ),
                child: const Text(
                  '📍 Aquí estoy',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(blurRadius: 6, color: Colors.blueAccent, spreadRadius: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Marcadores de Comisarías
    for (final comisaria in comisariasList) {
      if (comisaria.latitude == 0.0 && comisaria.longitude == 0.0) continue;

      markers.add(
        Marker(
          point: LatLng(comisaria.latitude, comisaria.longitude),
          width: 120,
          height: 80,
          child: GestureDetector(
            onTap: () => _showComisariaDetails(context, comisaria, isDark),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF60A5FA), width: 1.2),
                    boxShadow: const [
                      BoxShadow(blurRadius: 4, color: Colors.black38, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    comisaria.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_police_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Marcadores de Hospitales
    for (final hospital in hospitalsList) {
      if (hospital.latitude == 0.0 && hospital.longitude == 0.0) continue;

      markers.add(
        Marker(
          point: LatLng(hospital.latitude, hospital.longitude),
          width: 120,
          height: 80,
          child: GestureDetector(
            onTap: () => _showHospitalDetails(context, hospital, isDark),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF34D399), width: 1.2),
                    boxShadow: const [
                      BoxShadow(blurRadius: 4, color: Colors.black38, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    hospital.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 4. Marcadores de Bomberos
    for (final bombero in bomberosList) {
      if (bombero.latitude == 0.0 && bombero.longitude == 0.0) continue;

      markers.add(
        Marker(
          point: LatLng(bombero.latitude, bombero.longitude),
          width: 120,
          height: 80,
          child: GestureDetector(
            onTap: () => _showBomberoDetails(context, bombero, isDark),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C2D12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF97316), width: 1.2),
                    boxShadow: const [
                      BoxShadow(blurRadius: 4, color: Colors.black38, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    bombero.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: const Color(0xFFF97316).withValues(alpha: 0.6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 5. Marcadores de Alertas Vecinales Activas
    for (final alert in alertsList) {
      markers.add(
        Marker(
          point: LatLng(alert.latitude, alert.longitude),
          width: 52,
          height: 52,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => _showAlertDetailsModal(context, alert, hospitalsList, comisariasList, bomberosList, isDark),
              child: Container(
                decoration: BoxDecoration(
                  color: alert.type == AlertType.medical
                      ? const Color(0xFF10B981)
                      : alert.type == AlertType.fire
                          ? const Color(0xFFF97316)
                          : AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black38, offset: Offset(0, 3)),
                  ],
                ),
                child: Center(
                  child: Text(
                    alert.type.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de emergencias'),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.alarma_comunitaria',
                ),
                MarkerLayer(markers: markers),
              ],
            ),

            // ── BARRA SUPERIOR FLOTANTE ─────────────────────────────────────
            Positioned(
              top: 14,
              left: 10,
              right: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BANNER DE ALERTAS ACTIVAS (SÓLO APARECE SI HAY ALERTAS)
                  if (alertsList.isNotEmpty) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _showActiveAlertsListModal(context, alertsList, hospitalsList, comisariasList, bomberosList, isDark),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '🚨 ${alertsList.length} ALERTA${alertsList.length > 1 ? 'S' : ''} ACTIVA${alertsList.length > 1 ? 'S' : ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            alertsList.first.type.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Toca aquí para ver la alerta y centrarla en el mapa',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // FILA DE BOTONES: Comisarías, Hospitales, Bomberos y Contador de Vecinos
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Botón Comisarías
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showComisariasListModal(context, comisariasList, isDark),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.surface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_police_rounded, color: Color(0xFF2563EB), size: 18),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Comisarías',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      Text(
                                        '${comisariasList.length}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Botón Hospitales
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showHospitalsListModal(context, hospitalsList, isDark),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.surface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_hospital_rounded, color: Color(0xFF10B981), size: 18),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Hospitales',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      Text(
                                        '${hospitalsList.length}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Botón Bomberos
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showBomberosListModal(context, bomberosList, isDark),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.surface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.5), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 18),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Bomberos',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFF97316),
                                        ),
                                      ),
                                      Text(
                                        '${bomberosList.length}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Contador de vecinos conectados (Toca para ver la lista completa)
                        Consumer(
                          builder: (context, ref, child) {
                            final neighborsCountAsync = ref.watch(communityNeighborsCountProvider(profile.communityId));
                            final count = neighborsCountAsync.asData?.value ?? 1;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showCommunityNeighborsListModal(context, profile.communityId, isDark),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.surface : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people_alt_rounded, color: Color(0xFF60A5FA), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_loadingLocation)
              const Positioned(
                top: 70,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.secondary,
          onPressed: () async {
            try {
              final position = await LocationService().getCurrentLocation();
              if (!context.mounted) return;
              final newLatLng = LatLng(position.latitude, position.longitude);
              setState(() {
                _userLatLng = newLatLng;
              });
              _animatedMapMove(newLatLng, 16.0);
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo obtener la ubicación actual.')),
              );
            }
          },
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          backgroundColor: isDark ? AppTheme.surface : Colors.white,
          selectedItemColor: isDark ? AppTheme.secondary : AppTheme.primary,
          unselectedItemColor: isDark ? AppTheme.textSecondary : Colors.grey[600],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Mapa'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active_rounded), label: 'Mis Alertas'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Reclamos'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/home');
              case 1:
                context.go('/map');
              case 2:
                context.go('/my-alerts');
              case 3:
                context.go('/claims');
              case 4:
                context.go('/profile');
            }
          },
        ),
      ),
    );
  }
}
