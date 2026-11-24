import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_status.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:alarma_comunitaria/providers/alert_provider.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:alarma_comunitaria/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyAlertsScreen extends ConsumerWidget {
  const MyAlertsScreen({super.key});

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final firebaseUser = authState.firebaseUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState.status != AuthStatus.authenticated || profile == null || firebaseUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final alertsAsync = ref.watch(historyAlertsProvider(profile.communityId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Alertas'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: alertsAsync.when(
            data: (allAlerts) {
              final myAlerts = allAlerts.where((a) => a.userId == firebaseUser.uid).toList();
              if (myAlerts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No has lanzado ninguna alerta todavía.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myAlerts.length,
                itemBuilder: (context, index) {
                  final alert = myAlerts[index];
                  final isActive = alert.status != AlertStatus.resolved && alert.status != AlertStatus.cancelled;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isDark ? AppTheme.surface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(alert.type.emoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.customDescription != null && alert.customDescription!.isNotEmpty
                                          ? alert.customDescription!
                                          : alert.type.label,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _timeAgo(alert.createdAt),
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: alert.status),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${alert.viewsCount} vecinos vieron tu alerta',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  context.go('/map', extra: alert);
                                },
                                icon: const Icon(Icons.map, size: 16, color: Color(0xFF2563EB)),
                                label: const Text('Ver en mapa', style: TextStyle(color: Color(0xFF2563EB))),
                              ),
                            ],
                          ),
                          if (isActive) ...[
                            Divider(height: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                ),
                                onPressed: () async {
                                  try {
                                    await ref.read(alertRepositoryProvider).deleteAlert(alert.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Alerta eliminada correctamente.')),
                                      );
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No se pudo eliminar la alerta.')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Cancelar y Borrar Alerta'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 2,
          backgroundColor: isDark ? AppTheme.surface : Colors.white,
          selectedItemColor: isDark ? AppTheme.secondary : AppTheme.primary,
          unselectedItemColor: isDark ? AppTheme.textSecondary : Colors.grey[600],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
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
