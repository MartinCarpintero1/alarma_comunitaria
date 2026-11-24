import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:alarma_comunitaria/models/bombero.dart';
import 'package:alarma_comunitaria/models/comisaria.dart';
import 'package:alarma_comunitaria/models/emergency_alert.dart';
import 'package:alarma_comunitaria/models/hospital.dart';
import 'package:alarma_comunitaria/repositories/bombero_repository.dart';
import 'package:alarma_comunitaria/repositories/comisaria_repository.dart';
import 'package:alarma_comunitaria/repositories/hospital_repository.dart';
import 'package:alarma_comunitaria/services/location_service.dart';
import 'package:alarma_comunitaria/widgets/bombero_card.dart';
import 'package:alarma_comunitaria/widgets/comisaria_card.dart';
import 'package:alarma_comunitaria/widgets/hospital_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AlertSentScreen extends ConsumerStatefulWidget {
  const AlertSentScreen({super.key});

  @override
  ConsumerState<AlertSentScreen> createState() => _AlertSentScreenState();
}

class _AlertSentScreenState extends ConsumerState<AlertSentScreen> {
  List<Comisaria> _nearestComisarias = [];
  List<Hospital> _nearestHospitals = [];
  List<Bombero> _nearestBomberos = [];

  bool _loadingComisarias = true;
  bool _loadingHospitals = true;
  bool _loadingBomberos = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearestEntities();
    });
  }

  Future<void> _loadNearestEntities() async {
    final alert = GoRouterState.of(context).extra as EmergencyAlert?;
    double lat = alert?.latitude ?? 0.0;
    double lng = alert?.longitude ?? 0.0;

    if (lat == 0.0 && lng == 0.0) {
      try {
        final position = await LocationService().getCurrentLocation();
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {}
    }

    if (lat != 0.0 || lng != 0.0) {
      final comisariaRepo = ref.read(comisariaRepositoryProvider);
      final hospitalRepo = ref.read(hospitalRepositoryProvider);
      final bomberoRepo = ref.read(bomberoRepositoryProvider);

      final comisariasFuture = comisariaRepo.getNearestComisarias(userLat: lat, userLng: lng, limit: 3);
      final hospitalsFuture = hospitalRepo.getNearestHospitals(userLat: lat, userLng: lng, limit: 3);
      final bomberosFuture = bomberoRepo.getNearestBomberos(userLat: lat, userLng: lng, limit: 3);

      final results = await Future.wait([comisariasFuture, hospitalsFuture, bomberosFuture]);

      if (mounted) {
        setState(() {
          _nearestComisarias = results[0] as List<Comisaria>;
          _nearestHospitals = results[1] as List<Hospital>;
          _nearestBomberos = results[2] as List<Bombero>;
          _loadingComisarias = false;
          _loadingHospitals = false;
          _loadingBomberos = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loadingComisarias = false;
          _loadingHospitals = false;
          _loadingBomberos = false;
        });
      }
    }
  }

  // ── SECCIÓN CENTRALIZADA LLAMADA 911 ─────────────────────────────────────
  Widget _buildEmergencyCallBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF991B1B), const Color(0xFF450A0A)]
              : [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'LLAMADA DIRECTA DE EMERGENCIA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: () => HospitalRepository.call911(),
              icon: const Icon(Icons.phone_in_talk_rounded, size: 22, color: Color(0xFFDC2626)),
              label: const Text(
                'LLAMAR DIRECTO AL 911',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Central de Emergencias Policiales, Médicas y Bomberos',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN DE COMISARÍAS Y POLICÍA ─────────────────────────────────────
  Widget _buildComisariasSection(bool isDark, Color primaryTextColor, Color cardBg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : const Color(0xFF93C5FD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_police_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comisarías y Destacamentos',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: primaryTextColor),
                    ),
                    const Text(
                      'Ordenadas por cercanía a tu ubicación GPS',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!_loadingComisarias && _nearestComisarias.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_nearestComisarias.length} cercan',
                    style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          if (_loadingComisarias)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(height: 10),
                    Text('Buscando comisarías más cercanas...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_nearestComisarias.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No se encontraron comisarías registradas en la base de datos cerca de tu zona.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _nearestComisarias.length; i++)
                  ComisariaCard(
                    comisaria: _nearestComisarias[i],
                    rank: i + 1,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ── SECCIÓN DE HOSPITALES Y SALUD ────────────────────────────────────────
  Widget _buildHospitalsSection(bool isDark, Color primaryTextColor, Color cardBg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFA7F3D0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hospitales y Guardias Médicas',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: primaryTextColor),
                    ),
                    const Text(
                      'Centros de salud ordenados por cercanía a tu ubicación GPS',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!_loadingHospitals && _nearestHospitals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_nearestHospitals.length} cercanos',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          if (_loadingHospitals)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(height: 10),
                    Text('Buscando hospitales cercanos...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_nearestHospitals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No se encontraron hospitales registrados en la base de datos cerca de tu zona.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _nearestHospitals.length; i++)
                  HospitalCard(
                    hospital: _nearestHospitals[i],
                    rank: i + 1,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ── SECCIÓN DE BOMBEROS Y INCENDIOS ───────────────────────────────────────
  Widget _buildBomberosSection(bool isDark, Color primaryTextColor, Color cardBg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFFF97316).withValues(alpha: 0.4) : const Color(0xFFFED7AA),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuarteles de Bomberos',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: primaryTextColor),
                    ),
                    const Text(
                      'Unidades de bomberos ordenadas por cercanía GPS',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!_loadingBomberos && _nearestBomberos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_nearestBomberos.length} cercanos',
                    style: const TextStyle(color: Color(0xFFF97316), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          if (_loadingBomberos)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(height: 10),
                    Text('Buscando cuarteles de bomberos...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_nearestBomberos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No se encontraron cuarteles de bomberos registrados en la base de datos cerca de tu zona.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _nearestBomberos.length; i++)
                  BomberoCard(
                    bombero: _nearestBomberos[i],
                    rank: i + 1,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alert = GoRouterState.of(context).extra as EmergencyAlert?;
    final alertType = alert?.type ?? AlertType.robbery;
    final isMedical = alertType == AlertType.medical;
    final isFire = alertType == AlertType.fire;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.surface : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final timeStr = alert != null
        ? '${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')} hs'
        : '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Confirmación de Alerta'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Hero de Confirmación
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF064E3B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡ALERTA EMITIDA!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Notificación distribuida en tiempo real a tus vecinos.',
                              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card de Resumen de Alerta Emitida
                if (alert != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(alert.type.emoji, style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.type.label,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    'Emitida a las $timeStr',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDC2626)),
                              ),
                              child: const Text(
                                '🚨 ACTIVA',
                                style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        if (alert.customDescription != null && alert.customDescription!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.description_outlined, size: 18, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '📝 "${alert.customDescription!.trim()}"',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Botón Directo al 911
                _buildEmergencyCallBanner(isDark),

                // Título de la sección de servicios auxiliares
                Row(
                  children: [
                    const Icon(Icons.near_me_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ENTIDADES Y AUXILIOS MÁS CERCANOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── ORDEN JERÁRQUICO SEGÚN TIPO DE ALERTA ─────────────────────
                if (isMedical) ...[
                  _buildHospitalsSection(isDark, primaryTextColor, cardBg),
                  _buildComisariasSection(isDark, primaryTextColor, cardBg),
                  _buildBomberosSection(isDark, primaryTextColor, cardBg),
                ] else if (isFire) ...[
                  _buildBomberosSection(isDark, primaryTextColor, cardBg),
                  _buildComisariasSection(isDark, primaryTextColor, cardBg),
                  _buildHospitalsSection(isDark, primaryTextColor, cardBg),
                ] else ...[
                  _buildComisariasSection(isDark, primaryTextColor, cardBg),
                  _buildHospitalsSection(isDark, primaryTextColor, cardBg),
                  _buildBomberosSection(isDark, primaryTextColor, cardBg),
                ],

                const SizedBox(height: 10),

                // Acciones inferiores de navegación
                Row(
                  children: [
                    if (alert != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFF60A5FA) : AppTheme.primary,
                            side: BorderSide(color: isDark ? const Color(0xFF3B82F6) : AppTheme.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => context.go('/map', extra: alert),
                          icon: const Icon(Icons.map_rounded, size: 20),
                          label: const Text('VER EN MAPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    if (alert != null) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: const Text('INICIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
