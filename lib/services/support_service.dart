import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportService {
  static Future<void> openWhatsApp(BuildContext context) async {
    final url = Uri.parse('https://wa.me/5492616950667?text=Hola%20Chino%20Developer,%20necesito%20soporte%20con%20AlarmaGo');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final webUrl = Uri.parse('https://api.whatsapp.com/send?phone=5492616950667&text=Hola%20Chino%20Developer');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp de soporte: +54 9 261 695 0667')),
        );
      }
    }
  }
}
