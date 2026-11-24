import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:alarma_comunitaria/services/support_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Escribe tu correo y contraseña.');
      return;
    }
    setState(() => _loading = true);
    final success = await ref.read(authProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      context.go('/home');
    } else {
      final err = ref.read(authProvider).errorMessage;
      if (err == 'SUBSCRIPCIÓN_VENCIDA') {
        _showSubscriptionExpiredDialog(context);
      } else {
        _showMessage(err ?? 'No se pudo iniciar sesión.');
      }
    }
  }

  void _showSubscriptionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('⚠️ Suscripción Vencida', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tu suscripción mensual de AlarmaGo ha expirado. Por favor, contacta con soporte y abone otro mes para continuar utilizando la red de seguridad.',
          style: TextStyle(color: Colors.white70),
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
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Escribe tu correo para recuperar la contraseña.');
      return;
    }
    final success = await ref.read(authProvider.notifier).resetPassword(email);
    if (!mounted) return;
    _showMessage(success
        ? 'Se envió un correo para restablecer tu contraseña.'
        : ref.read(authProvider).errorMessage ?? 'No se pudo enviar el correo.');
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('AlarmaGo', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                TextField(controller: _emailController, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 16),
                TextField(controller: _passwordController, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline))),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('INICIAR SESIÓN'),
                )),
                TextButton(onPressed: _loading ? null : _resetPassword, child: const Text('¿Olvidaste tu contraseña?')),
                TextButton(onPressed: _loading ? null : () => context.go('/register'), child: const Text('Crear cuenta')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
