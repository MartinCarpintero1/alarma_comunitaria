import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_status.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:alarma_comunitaria/providers/alert_provider.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:alarma_comunitaria/providers/theme_provider.dart';
import 'package:alarma_comunitaria/services/haptic_service.dart';
import 'package:alarma_comunitaria/services/location_service.dart';
import 'package:alarma_comunitaria/services/support_service.dart';
import 'package:alarma_comunitaria/widgets/alert_button.dart';
import 'package:alarma_comunitaria/widgets/status_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  bool _hasLocationPermission = true;
  bool _expandActiveAlerts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startForegroundService();
    _subscribeToFcmTopic();
    _subscribeToOneSignal();
    _checkPermissions();
    _checkSubscriptionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      _checkSubscriptionStatus();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission != LocationPermission.denied && permission != LocationPermission.deniedForever;
      if (mounted) {
        setState(() {
          _hasLocationPermission = granted;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final profile = ref.read(authProvider).profile;
      final prefs = await SharedPreferences.getInstance();
      final code = (profile?.activationCode.isNotEmpty == true)
          ? profile!.activationCode
          : (prefs.getString('activationCode') ?? '');

      if (code.isEmpty) {
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('codigos_dispositivos')
          .where('codigo', isEqualTo: code.trim())
          .get();

      if (query.docs.isEmpty) {
        return;
      }

      final data = query.docs.first.data();
      final Timestamp? vencimientoTs = data['fechaVencimiento'] as Timestamp?;
      if (vencimientoTs != null) {
        final expirationDate = vencimientoTs.toDate();
        final now = DateTime.now();

        if (now.isAfter(expirationDate)) {
          if (mounted) {
            _showSubscriptionExpiredOverlay();
          }
        }
      }
    } catch (_) {}
  }

  void _showSubscriptionExpiredOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.surface : Colors.white,
          title: Text('⚠️ Suscripción Vencida', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))),
          content: Text(
            'Tu suscripción mensual de AlarmaGo ha expirado. Por favor, contacta con soporte y abone otro mes para continuar utilizando la red de seguridad.',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF475569)),
          ),
          actions: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              onPressed: () => SupportService.openWhatsApp(context),
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Contactar Soporte WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribeToFcmTopic() async {
    try {
      final profile = ref.read(authProvider).profile;
      if (profile != null && profile.communityId.isNotEmpty) {
        await FirebaseMessaging.instance.subscribeToTopic('community_${profile.communityId}');
      }
    } catch (_) {}
  }

  Future<void> _subscribeToOneSignal() async {
    try {
      final profile = ref.read(authProvider).profile;
      final firebaseUser = ref.read(authProvider).firebaseUser;
      if (profile != null && profile.communityId.isNotEmpty) {
        if (firebaseUser != null) {
          // OneSignal login handled
        }
      }
    } catch (_) {}
  }

  Future<void> _startForegroundService() async {
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.startService(
          serviceId: 888,
          notificationTitle: '🟢 Conectado - AlarmaGo',
          notificationText: 'Red de seguridad comunitaria activa 24/7',
          callback: startCallback,
        );
      }
    } catch (_) {}
  }

  Future<void> _checkAndRequestAccessibilityPermissions() async {
    try {
      await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abre la configuración del sistema para permitir la ejecución en segundo plano.')),
        );
      }
    }
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        title: Text('Salir de la aplicación', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A))),
        content: Text('¿Estás seguro de que deseas salir de AlarmaGo?', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Text(
            'Creado por Chino Developer',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => SupportService.openWhatsApp(context),
            icon: const Icon(Icons.support_agent_rounded, size: 20),
            label: const Text('Soporte Técnico WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 80,
          leading: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/guide'),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_rounded, color: AppTheme.secondary, size: 22),
                SizedBox(height: 2),
                Text(
                  'Guía de uso',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF60A5FA),
                  ),
                ),
              ],
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security_rounded, color: AppTheme.primary, size: 28),
              const SizedBox(width: 8),
              Text('AlarmaGo • ${profile.communityId}'),
            ],
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        color: const Color(0xFF60A5FA),
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDark ? 'Claro' : 'Nocturno',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                if (!_hasLocationPermission)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Permiso de ubicación requerido para enviar alertas.',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await LocationService().requestPermission();
                            _checkPermissions();
                          },
                          child: const Text('Activar'),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                          : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const ContainerDot(),
                          const SizedBox(width: 8),
                          const Text(
                            'SISTEMA ACTIVO 24/7',
                            style: TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.settings_suggest_rounded, size: 22, color: Colors.white70),
                            tooltip: 'Optimización de batería',
                            onPressed: _checkAndRequestAccessibilityPermissions,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hola, ${profile.name}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manzana: ${profile.manzana.isEmpty ? 'N/A' : profile.manzana} • Casa: ${profile.casa.isEmpty ? 'N/A' : profile.casa} • ${profile.barrio}',
                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AlertButton(
                  onPressed: () {
                    HapticService.light();
                    context.push('/alert-type');
                  },
                ),
                const SizedBox(height: 24),
                activeAlertsAsync.when(
                  data: (alerts) {
                    final activeCount = alerts.where((alert) => alert.status != AlertStatus.resolved && alert.status != AlertStatus.cancelled).length;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surface : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
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
                              Text(
                                '$activeCount emergencias activas',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(_expandActiveAlerts ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                onPressed: () {
                                  setState(() {
                                    _expandActiveAlerts = !_expandActiveAlerts;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_expandActiveAlerts) ...[
                            const SizedBox(height: 12),
                            if (alerts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text('No hay alertas activas en este momento.', style: TextStyle(color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B))),
                              )
                            else
                              SizedBox(
                                height: alerts.length > 2 ? 260 : null,
                                child: ListView.builder(
                                  shrinkWrap: alerts.length <= 2,
                                  physics: alerts.length > 2 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                                  itemCount: alerts.length,
                                  itemBuilder: (context, index) {
                                    final alert = alerts[index];
                                    final timeStr = '${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')} hrs';
                                    final locationLabel = 'Manzana: ${alert.manzana?.isEmpty ?? true ? 'N/A' : alert.manzana} • Casa: ${alert.casa?.isEmpty ?? true ? 'N/A' : alert.casa}';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(alert.type.emoji, style: const TextStyle(fontSize: 26)),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      alert.type.label,
                                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '$locationLabel • $timeStr',
                                                      style: TextStyle(color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                                                    ),
                                                    if (alert.phone != null && alert.phone!.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '📱 Celular: ${alert.phone}',
                                                        style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w700),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              StatusBadge(status: alert.status),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: isDark ? const Color(0xFF60A5FA) : AppTheme.primary,
                                                    side: BorderSide(color: isDark ? const Color(0xFF3B82F6) : AppTheme.primary),
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                  onPressed: alert.userId == firebaseUser.uid ? () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('No puedes marcar como vista tu propia alerta.')),
                                                    );
                                                  } : () async {
                                                    await ref.read(alertRepositoryProvider).markAsViewed(alert.id, firebaseUser.uid);
                                                  },
                                                  icon: Icon(Icons.touch_app_rounded, size: 18, color: alert.userId == firebaseUser.uid ? Colors.grey : null),
                                                  label: Text(
                                                    alert.userId == firebaseUser.uid ? 'Tu alerta (${alert.viewsCount})' : 'Visto (${alert.viewsCount})',
                                                    style: TextStyle(color: alert.userId == firebaseUser.uid ? Colors.grey : null),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: FilledButton.icon(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: AppTheme.secondary,
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                  onPressed: () {
                                                    context.go('/map', extra: alert);
                                                  },
                                                  icon: const Icon(Icons.map_rounded, size: 18),
                                                  label: const Text('Ver mapa'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 24),
                _buildDeveloperFooter(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
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

class ContainerDot extends StatelessWidget {
  const ContainerDot({super.key});

  @override
  Widget build(BuildContext context) {
    const Color dotColor = Color(0xFF4ADE80);
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
