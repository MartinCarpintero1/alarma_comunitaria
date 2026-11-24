import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/comisaria.dart';
import 'package:alarma_comunitaria/repositories/comisaria_repository.dart';
import 'package:flutter/material.dart';

class ComisariaCard extends StatelessWidget {
  final Comisaria comisaria;
  final int rank; // 1, 2, 3

  const ComisariaCard({
    super.key,
    required this.comisaria,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFirst = rank == 1;

    final badgeColor = isFirst
        ? const Color(0xFFEF4444)
        : rank == 2
            ? const Color(0xFF3B82F6)
            : const Color(0xFF10B981);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFirst
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : const Color(0xFF3B82F6).withValues(alpha: 0.3),
          width: isFirst ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFirst
                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ranking badge & distancia + tiempo en auto
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFirst ? Icons.stars_rounded : Icons.local_police_rounded,
                        size: 14,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFirst ? 'OPCIÓN MÁS CERCANA' : 'OPCIÓN #$rank',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Distancia y tiempo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF60A5FA)),
                      const SizedBox(width: 4),
                      Text(
                        comisaria.formattedDistance,
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (comisaria.distanceInMeters != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.directions_car_rounded, size: 14, color: Color(0xFF22C55E)),
                        const SizedBox(width: 3),
                        Text(
                          comisaria.formattedDrivingTime,
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nombre de la comisaría
            Text(
              comisaria.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Dirección
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    comisaria.direccion,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),

            // Teléfonos
            if (comisaria.phones.isNotEmpty) ...[
              const SizedBox(height: 6),
              for (final phone in comisaria.phones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF22C55E)),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Text(
                    'Sin teléfono registrado',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textSecondary : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Botones de llamada: uno por número disponible
            if (comisaria.phones.isEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: null,
                  icon: const Icon(Icons.call_rounded, size: 20),
                  label: const Text('SIN TELÉFONO'),
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < comisaria.phones.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i < comisaria.phones.length - 1 ? 8 : 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: i == 0
                                ? (isFirst ? const Color(0xFFEF4444) : const Color(0xFF22C55E))
                                : const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final phone = comisaria.phones[i];
                            final ok = await ComisariaRepository.callComisaria(phone);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('No se pudo iniciar la llamada al $phone'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.call_rounded, size: 20),
                          label: Text(
                            comisaria.phones.length == 1
                                ? 'LLAMAR A ${comisaria.name.toUpperCase()}'
                                : 'LLAMAR: ${comisaria.phones[i]}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
