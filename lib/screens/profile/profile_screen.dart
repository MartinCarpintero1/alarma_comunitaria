import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _manzanaController;
  late final TextEditingController _casaController;
  late final TextEditingController _barrioController;
  late final TextEditingController _departmentController;
  late final TextEditingController _houseDescriptionController;
  late final TextEditingController _phoneController;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _manzanaController = TextEditingController(text: profile?.manzana ?? '');
    _casaController = TextEditingController(text: profile?.casa ?? '');
    _barrioController = TextEditingController(text: profile?.barrio ?? '');
    _departmentController = TextEditingController(text: profile?.department ?? '');
    _houseDescriptionController = TextEditingController(text: profile?.houseDescription ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manzanaController.dispose();
    _casaController.dispose();
    _barrioController.dispose();
    _departmentController.dispose();
    _houseDescriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
            name: _nameController.text,
            manzana: _manzanaController.text,
            casa: _casaController.text,
            barrio: _barrioController.text,
            department: _departmentController.text,
            houseDescription: _houseDescriptionController.text,
            phone: _phoneController.text,
          );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = success ? 'Perfil actualizado correctamente.' : 'No se pudo actualizar el perfil.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'Ocurrió un error al guardar.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil y Ubicación'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información personal y de vivienda',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configura tus datos para que tus vecinos te identifiquen rápidamente en caso de emergencia.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                if (_message != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondary),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre y Apellido',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de celular',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manzanaController,
                        decoration: const InputDecoration(
                          labelText: 'Manzana / Sector',
                          prefixIcon: Icon(Icons.grid_view),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _casaController,
                        decoration: const InputDecoration(
                          labelText: 'Casa / Lote',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Departamento / Torre (Opcional)',
                    prefixIcon: Icon(Icons.apartment),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _barrioController,
                  decoration: const InputDecoration(
                    labelText: 'Barrio / Urbanización',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _houseDescriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la casa / Referencias (Ej: portón negro, rejas blancas)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Comunidad ID', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(profile.communityId, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 12),
                      const Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(profile.email, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar Cambios'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 4,
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
