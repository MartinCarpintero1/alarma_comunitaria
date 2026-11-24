import 'package:alarma_comunitaria/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(title: Text('Notificaciones'), trailing: Icon(Icons.notifications)),
            ListTile(title: Text('Privacidad'), trailing: Icon(Icons.lock_outline)),
            ListTile(title: Text('Tema'), trailing: Icon(Icons.palette_outlined)),
            ListTile(
              title: const Text('Cerrar sesión'),
              trailing: const Icon(Icons.logout),
              onTap: () => ref.read(authProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
