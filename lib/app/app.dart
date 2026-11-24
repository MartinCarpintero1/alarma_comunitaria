import 'package:alarma_comunitaria/app/router.dart';
import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlarmaComunitariaApp extends ConsumerWidget {
  const AlarmaComunitariaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AlarmaGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
