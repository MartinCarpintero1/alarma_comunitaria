import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _communityController = TextEditingController();
  final _departmentController = TextEditingController();
  final _manzanaController = TextEditingController();
  final _casaController = TextEditingController();
  final _barrioController = TextEditingController();
  final _houseDescriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _activationCodeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in [
      _nameController, _emailController, _passwordController,
      _confirmController, _communityController, _departmentController,
      _manzanaController, _casaController, _barrioController, _houseDescriptionController, _phoneController, _activationCodeController,
    ]) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _register() async {
    final requiredControllers = [
      _nameController, _emailController, _passwordController,
      _confirmController, _communityController, _manzanaController,
      _casaController, _barrioController, _phoneController, _activationCodeController,
    ];
    if (requiredControllers.any((controller) => controller.text.trim().isEmpty)) {
      _showMessage('Completa todos los campos obligatorios, incluyendo el código de activación.');
      return;
    }
    if (_activationCodeController.text.trim().length != 5) {
      _showMessage('El código de activación debe tener exactamente 5 cifras.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }
    setState(() => _loading = true);
    final success = await ref.read(authProvider.notifier).signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          communityId: _communityController.text,
          department: _departmentController.text,
          manzana: _manzanaController.text,
          casa: _casaController.text,
          barrio: _barrioController.text,
          houseDescription: _houseDescriptionController.text,
          phone: _phoneController.text,
          activationCode: _activationCodeController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      context.go('/home');
    } else {
      _showMessage(ref.read(authProvider).errorMessage ?? 'No se pudo crear la cuenta.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Crear Cuenta'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/login'),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                const Text(
                  'Únete a tu red vecinal',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crea tu cuenta configurando tus datos, ubicación y código de activación mensual.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _activationCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: const InputDecoration(
                    labelText: 'Código de activación (5 cifras) *',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre y Apellido *', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico *', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Número de celular *', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _communityController,
                  decoration: const InputDecoration(
                    labelText: 'ID de Comunidad / Complejo *',
                    prefixIcon: Icon(Icons.group_outlined),
                    helperText: 'Este ID sirve para que todos tus vecinos estén conectados en la misma red de alertas.',
                    helperMaxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manzanaController,
                        decoration: const InputDecoration(labelText: 'Manzana / Sector *', prefixIcon: Icon(Icons.grid_view)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _casaController,
                        decoration: const InputDecoration(labelText: 'Casa / Lote *', prefixIcon: Icon(Icons.home_outlined)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _departmentController,
                  decoration: const InputDecoration(labelText: 'Departamento / Torre (Opcional)', prefixIcon: Icon(Icons.apartment_outlined)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _barrioController,
                  decoration: const InputDecoration(labelText: 'Barrio / Urbanización *', prefixIcon: Icon(Icons.location_city)),
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
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña *', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar contraseña *', prefixIcon: Icon(Icons.lock_reset_outlined)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('REGISTRARME'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
