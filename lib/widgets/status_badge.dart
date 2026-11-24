import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_status.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final AlertStatus status;

  const StatusBadge({super.key, required this.status});

  Color get color {
    switch (status) {
      case AlertStatus.active:
        return AppTheme.primary;
      case AlertStatus.attending:
        return AppTheme.warning;
      case AlertStatus.resolved:
        return AppTheme.success;
      case AlertStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
