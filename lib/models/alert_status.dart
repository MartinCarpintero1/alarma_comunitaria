enum AlertStatus {
  active,
  attending,
  resolved,
  cancelled,
}

extension AlertStatusX on AlertStatus {
  String get label {
    switch (this) {
      case AlertStatus.active:
        return 'Activa';
      case AlertStatus.attending:
        return 'En atención';
      case AlertStatus.resolved:
        return 'Resuelta';
      case AlertStatus.cancelled:
        return 'Cancelada';
    }
  }

  String get colorName {
    switch (this) {
      case AlertStatus.active:
        return 'red';
      case AlertStatus.attending:
        return 'orange';
      case AlertStatus.resolved:
        return 'green';
      case AlertStatus.cancelled:
        return 'grey';
    }
  }

  static AlertStatus fromString(String value) {
    switch (value) {
      case 'active':
        return AlertStatus.active;
      case 'attending':
        return AlertStatus.attending;
      case 'resolved':
        return AlertStatus.resolved;
      case 'cancelled':
        return AlertStatus.cancelled;
      default:
        return AlertStatus.active;
    }
  }
}
