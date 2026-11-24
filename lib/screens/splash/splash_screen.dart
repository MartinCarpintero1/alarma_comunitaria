import 'package:alarma_comunitaria/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _requestInitialPermissions();
  }

  Future<void> _requestInitialPermissions() async {
    try {
      await LocationService().requestPermission();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.unauthenticated || next.status == AuthStatus.fail) {
        context.go('/login');
      }
    });
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, size: 96, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Alarma Comunitaria',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
