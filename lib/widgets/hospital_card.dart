import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/hospital.dart';
import 'package:alarma_comunitaria/repositories/hospital_repository.dart';
import 'package:flutter/material.dart';

class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final int rank; // 1, 2, 3

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFirst = rank == 1;

    final badgeColor = isFirst
        ? const Color(0xFF10B981)
        : rank == 2
            ? const Color(0xFF059669)
            : const Color(0xFF3B82F6);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFirst
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : const Color(0xFF10B981).withValues(alpha: 0.3),
          width: isFirst ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFirst
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
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
                        isFirst ? Icons.stars_rounded : Icons.local_hospital_rounded,
                        size: 14,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFirst ? 'HOSPITAL MÁS CERCANO' : 'OPCIÓN #$rank',
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
                if (hospital.distanceInMeters != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 3),
                        Text(
                          hospital.formattedDistance,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hospital.direccion,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (hospital.phones.isNotEmpty) ...[
              for (int i = 0; i < hospital.phones.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i < hospital.phones.length - 1 ? 8 : 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: i == 0 ? const Color(0xFF10B981) : const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => HospitalRepository.callPhone(hospital.phones[i]),
                      icon: const Icon(Icons.call_rounded, size: 20),
                      label: Text(
                        hospital.phones.length == 1
                            ? 'LLAMAR A GUARDIA (${hospital.phones[i]})'
                            : 'LLAMAR: ${hospital.phones[i]}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: null,
                  icon: const Icon(Icons.call_rounded, size: 20),
                  label: const Text('SIN TELÉFONO REGISTRADO'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
