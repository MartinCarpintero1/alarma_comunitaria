import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/claim.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:alarma_comunitaria/repositories/claim_repository.dart';
import 'package:alarma_comunitaria/repositories/hospital_repository.dart';
import 'package:alarma_comunitaria/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

final claimsStreamProvider = StreamProvider.autoDispose.family<List<Claim>, String>((ref, communityId) {
  return ref.watch(claimRepositoryProvider).watchClaims(communityId);
});

class ClaimsScreen extends ConsumerStatefulWidget {
  const ClaimsScreen({super.key});

  @override
  ConsumerState<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends ConsumerState<ClaimsScreen> {
  static final Set<String> _notifiedClaimIds = {};

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

  void _showNewClaimDialog(BuildContext context, WidgetRef ref, String communityId) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nuevo Reclamo Vecinal', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del reclamo',
                  hintText: 'Ej. Luminaria rota en esquina',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada',
                  hintText: 'Explica los detalles para tus vecinos...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();
              if (title.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor completa el título y la descripción.')),
                );
                return;
              }

              final authState = ref.read(authProvider);
              final profile = authState.profile;
              final user = authState.firebaseUser;
              if (profile == null || user == null) return;

              Navigator.pop(dialogContext);

              final newClaim = Claim(
                id: '',
                communityId: communityId,
                userId: user.uid,
                userName: profile.name,
                manzana: profile.manzana,
                casa: profile.casa,
                barrio: profile.barrio,
                phone: profile.phone,
                title: title,
                description: desc,
                createdAt: DateTime.now(),
                likesCount: 0,
                likedUserIds: [],
                replies: [],
              );

              try {
                final claimId = await ref.read(claimRepositoryProvider).createClaim(newClaim);
                _notifiedClaimIds.add(claimId);

                // Notificación local inmediata en el dispositivo del usuario con el sonido personalizado 'reclamos'
                await NotificationService().showClaimNotification(
                  id: claimId.hashCode,
                  title: '📢 RECLAMO PUBLICADO',
                  body: '${profile.name}: $title',
                );

                // Enviar notificación Push OneSignal a los vecinos
                await NotificationService().sendClaimPushNotification(
                  communityId: communityId,
                  userName: profile.name,
                  title: title,
                  description: desc,
                  userId: user.uid,
                  manzana: profile.manzana,
                  casa: profile.casa,
                  phone: profile.phone,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Reclamo publicado con éxito!')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al publicar el reclamo. Inténtalo de nuevo.')),
                  );
                }
              }
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteClaimDialog(BuildContext context, WidgetRef ref, String claimId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar reclamo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que deseas eliminar este reclamo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(claimRepositoryProvider).deleteClaim(claimId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reclamo eliminado correctamente.')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al eliminar el reclamo.')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showNeighborDetailsModal(BuildContext context, Claim claim, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
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
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    claim.userName.isNotEmpty ? claim.userName.substring(0, 1).toUpperCase() : 'V',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.userName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Vecino de la comunidad',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('🏠 Manzana / Sector:', claim.manzana.isEmpty ? 'N/A' : claim.manzana, isDark),
            const SizedBox(height: 10),
            _buildInfoRow('🏡 Casa / Lote:', claim.casa.isEmpty ? 'N/A' : claim.casa, isDark),
            const SizedBox(height: 10),
            _buildInfoRow('📍 Barrio:', claim.barrio.isEmpty ? 'N/A' : claim.barrio, isDark),
            const SizedBox(height: 10),
            _buildInfoRow('📱 Celular:', claim.phone.isEmpty ? 'No especificado' : claim.phone, isDark),
            const SizedBox(height: 28),
            if (claim.phone.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => HospitalRepository.callPhone(claim.phone),
                  icon: const Icon(Icons.phone_rounded),
                  label: Text('Llamar al ${claim.phone}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _showReplyDialog(BuildContext context, WidgetRef ref, Claim claim) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Responder al reclamo', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: replyController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Escribe tu respuesta...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final text = replyController.text.trim();
              if (text.isEmpty) return;

              final authState = ref.read(authProvider);
              final profile = authState.profile;
              final user = authState.firebaseUser;
              if (profile == null || user == null) return;

              Navigator.pop(dialogContext);

              final reply = ClaimReply(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: user.uid,
                userName: profile.name,
                manzana: profile.manzana,
                casa: profile.casa,
                text: text,
                createdAt: DateTime.now(),
              );

              try {
                await ref.read(claimRepositoryProvider).addReply(claim.id, reply);
              } catch (_) {}
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openOnlineDenuncia() async {
    final uri = Uri.parse('https://denuncias.mpfmza.gob.ar/#/denuncias_dashboard');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error al abrir URL de denuncia online: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final user = authState.firebaseUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState.status != AuthStatus.authenticated || profile == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final claimsAsync = ref.watch(claimsStreamProvider(profile.communityId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reclamos Vecinales'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Botón de Denuncia Online
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                child: Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: Color(0xFF0284C7)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '¿Necesitas hacer una denuncia formal?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _openOnlineDenuncia,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Denuncia Online'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: claimsAsync.when(
                  data: (claims) {
                    for (final claim in claims) {
                      if (claim.userId != user.uid &&
                          !_notifiedClaimIds.contains(claim.id) &&
                          claim.createdAt.isAfter(DateTime.now().subtract(const Duration(minutes: 5)))) {
                        _notifiedClaimIds.add(claim.id);
                        NotificationService().showClaimNotification(
                          id: claim.id.hashCode,
                          title: '📢 NUEVO RECLAMO VECINAL',
                          body: '${claim.userName}: ${claim.title}',
                        );
                      }
                    }

                    if (claims.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.forum_outlined, size: 64, color: AppTheme.textSecondary),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay reclamos en tu comunidad todavía.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => _showNewClaimDialog(context, ref, profile.communityId),
                                icon: const Icon(Icons.add),
                                label: const Text('Crear primer reclamo'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: claims.length,
                      itemBuilder: (context, index) {
                        final claim = claims[index];
                        final isLiked = claim.likedUserIds.contains(user.uid);
                        final isOwner = claim.userId == user.uid;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: isDark ? AppTheme.surface : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showNeighborDetailsModal(context, claim, isDark),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                        child: Text(
                                          claim.userName.isNotEmpty ? claim.userName.substring(0, 1).toUpperCase() : 'V',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _showNeighborDetailsModal(context, claim, isDark),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              claim.userName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              'Mz: ${claim.manzana.isEmpty ? 'N/A' : claim.manzana} • Casa: ${claim.casa.isEmpty ? 'N/A' : claim.casa} • ${_timeAgo(claim.createdAt)}',
                                              style: TextStyle(color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isOwner)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                        tooltip: 'Eliminar reclamo',
                                        onPressed: () => _showDeleteClaimDialog(context, ref, claim.id),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  claim.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  claim.description,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: isDark ? AppTheme.textSecondary : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                // Acciones: Me gusta y Responder
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isLiked ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF60A5FA) : AppTheme.primary),
                                        side: BorderSide(
                                          color: isLiked ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF3B82F6) : AppTheme.primary),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () async {
                                        await ref.read(claimRepositoryProvider).toggleLike(claim.id, user.uid);
                                      },
                                      icon: Icon(
                                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        size: 18,
                                      ),
                                      label: Text('Me gusta (${claim.likesCount})'),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showReplyDialog(context, ref, claim),
                                      icon: const Icon(Icons.reply_rounded, size: 18),
                                      label: Text('Responder (${claim.replies.length})'),
                                    ),
                                  ],
                                ),
                                // Listado de respuestas
                                if (claim.replies.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Respuestas de vecinos:',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                        const SizedBox(height: 8),
                                        ...claim.replies.map((reply) => Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        reply.userName,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                          color: isDark ? const Color(0xFF60A5FA) : AppTheme.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '(Mz: ${reply.manzana}, Casa: ${reply.casa})',
                                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    reply.text,
                                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ],
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
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          onPressed: () => _showNewClaimDialog(context, ref, profile.communityId),
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
          label: const Text('Nuevo Reclamo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 3,
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
