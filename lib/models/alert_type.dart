enum AlertType {
  robbery,
  medical,
  fire,
  following,
  notice,
}

extension AlertTypeX on AlertType {
  String get label {
    switch (this) {
      case AlertType.robbery:
        return 'Robo / Intruso';
      case AlertType.medical:
        return 'Médica';
      case AlertType.fire:
        return 'Incendio';
      case AlertType.following:
        return 'Me siguen / Sospechosos';
      case AlertType.notice:
        return 'Aviso vecinal / Vi algo';
    }
  }

  String get subtitle {
    switch (this) {
      case AlertType.robbery:
        return 'Posible intrusión o robo';
      case AlertType.medical:
        return 'Emergencia médica';
      case AlertType.fire:
        return 'Posible incendio';
      case AlertType.following:
        return 'Seguimiento GPS en tiempo real';
      case AlertType.notice:
        return 'Aviso o reporte con descripción';
    }
  }

  String get emoji {
    switch (this) {
      case AlertType.robbery:
        return '🚨';
      case AlertType.medical:
        return '🚑';
      case AlertType.fire:
        return '🔥';
      case AlertType.following:
        return '🏃‍♂️';
      case AlertType.notice:
        return '👁️';
    }
  }

  /// Texto de sugerencia o ejemplo para el campo de entrada de texto
  String get hintText {
    switch (this) {
      case AlertType.robbery:
        return 'Ej: Me robaron, rejas forzadas, intruso en el patio...';
      case AlertType.medical:
        return 'Ej: Adulto mayor se cayó y está grave, convulsiones...';
      case AlertType.fire:
        return 'Ej: Fuego en la cocina, cortocircuito, fuga de gas...';
      case AlertType.following:
        return 'Ej: Me siguen dos encapuchados por la calle...';
      case AlertType.notice:
        return 'Ej: Personas merodeando mirando las casas...';
    }
  }

  /// Lista de sugerencias rápidas predefinidas para tocar y seleccionar
  List<String> get quickSuggestions {
    switch (this) {
      case AlertType.robbery:
        return [
          'Me robaron / Asalto en la calle',
          'Intruso en la propiedad / Rejas forzadas',
          'Entraron a mi casa',
          'Robo de vehículo / Auto sospechoso',
        ];
      case AlertType.medical:
        return [
          'Adulto mayor se cayó y está grave',
          'Persona descompensada / Convulsiones',
          'Accidente doméstico grave',
          'Dolor de pecho / Emergencia de salud',
        ];
      case AlertType.fire:
        return [
          'Fuego en la casa / Fuga de gas',
          'Cortocircuito con chispas y humo',
          'Incendio en terreno baldío / Maleza',
          'Explosión de garrafa / Artefacto',
        ];
      case AlertType.following:
        return [
          'Me siguen dos encapuchados por la calle',
          'Auto / Moto sospechosa me persigue',
          'Siento que me acechan en la cuadra',
          'Persona sospechosa sacando fotos',
        ];
      case AlertType.notice:
        return [
          'Personas merodeando mirando casas',
          'Vehículo extraño estacionado sin patente',
          'Corte de luz / Portón o reja abierta',
          'Mascota / Perro perdido en la manzana',
        ];
    }
  }

  static AlertType fromString(String value) {
    switch (value) {
      case 'robbery':
        return AlertType.robbery;
      case 'medical':
        return AlertType.medical;
      case 'fire':
        return AlertType.fire;
      case 'following':
        return AlertType.following;
      case 'notice':
        return AlertType.notice;
      default:
        return AlertType.robbery;
    }
  }
}
