import 'package:flutter/services.dart';

class HapticService {
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void light() {
    HapticFeedback.lightImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }
}
