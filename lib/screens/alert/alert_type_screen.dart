import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AlertTypeScreen extends StatelessWidget {
  const AlertTypeScreen({super.key});

  /// Muestra un diálogo con descripción opcional para cualquier tipo de alerta.
  /// El usuario puede omitirla, escribir un texto o tocar sugerencias rápidas.
  void _showDescriptionDialog(BuildContext context, AlertType type) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Podés agregar una descripción opcional para dar más contexto a tus vecinos:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 200,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: type.hintText,
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      counterStyle: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sugerencias rápidas
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Sugerencias rápidas (toca para usar):',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: type.quickSuggestions.map((suggestion) {
                      final isSelected = controller.text == suggestion;
                      return ActionChip(
                        backgroundColor: isSelected
                            ? const Color(0xFF2563EB)
                            : isDark(context)
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF334155),
                          ),
                        ),
                        label: Text(
                          suggestion,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            controller.text = suggestion;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.push('/location-confirmation', extra: {
                    'type': type,
                  });
                },
                child: const Text('Omitir'),
              ),
              FilledButton(
                onPressed: () {
                  final desc = controller.text.trim();
                  Navigator.pop(dialogContext);
                  context.push('/location-confirmation', extra: {
                    'type': type,
                    if (desc.isNotEmpty) 'description': desc,
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final types = AlertType.values;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tipo de alerta'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Selecciona el tipo de emergencia',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Podrás elegir sugerencias rápidas o escribir una descripción antes de enviar.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ...types.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => _showDescriptionDialog(context, type),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: type == AlertType.robbery
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : type == AlertType.medical
                                        ? Colors.blue.withValues(alpha: 0.2)
                                        : type == AlertType.fire
                                            ? Colors.orange.withValues(alpha: 0.2)
                                            : type == AlertType.following
                                                ? Colors.purple.withValues(alpha: 0.2)
                                                : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(type.emoji, style: const TextStyle(fontSize: 32)),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.label,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    type.subtitle,
                                    style: const TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
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
