import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/comisaria.dart';
import 'package:alarma_comunitaria/widgets/comisaria_card.dart';
import 'package:flutter/material.dart';

Future<void> showNearestComisariasDialog({
  required BuildContext context,
  required List<Comisaria> comisarias,
}) async {
  if (comisarias.isEmpty) return;

  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppTheme.surface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_police_rounded,
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¿Deseas llamar a la comisaría?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  'Hemos encontrado las 3 comisarías más cercanas a tu ubicación actual:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 16),

                // List of comisarias
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: comisarias.length,
                    itemBuilder: (context, index) {
                      return ComisariaCard(
                        comisaria: comisarias[index],
                        rank: index + 1,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar / Ahora no'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
