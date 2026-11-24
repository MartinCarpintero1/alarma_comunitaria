import 'package:alarma_comunitaria/app/theme.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  AlertType _selectedDemoType = AlertType.robbery;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.surface : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de Uso AlarmaGo'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner de Bienvenida
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Manual del Vecino',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Conoce cómo emitir alertas con descripción personalizada, comunicarte con emergencias al 911 y llamar a las comisarías, hospitales o cuarteles de bomberos más cercanos.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 1. EMITIR ALERTAS Y DESCRIPCIÓN CUSTOM ──────────────────────
            _buildSectionHeader(
              icon: Icons.notification_important_rounded,
              title: '1. Emisión de Alertas y Descripción Personalizada',
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Al presionar el Botón Rojo de Pánico en el inicio, seleccionarás el tipo de emergencia. Antes de confirmar, puedes escribir una descripción opcional sobre lo que ocurre.',
                    style: TextStyle(fontSize: 14.5, color: secondaryText, height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // DEMO INTERACTIVA DE TIPOS DE ALERTAS
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.touch_app_rounded, color: Color(0xFF3B82F6), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'PRUEBA INTERACTIVA (Toca una alerta):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: primaryText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Selector de tipo de alerta interactivo
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AlertType.values.map((type) {
                            final isSelected = _selectedDemoType == type;
                            return ChoiceChip(
                              label: Text('${type.emoji} ${type.label}'),
                              selected: isSelected,
                              selectedColor: const Color(0xFF2563EB),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedDemoType = type);
                                }
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Previsualización de cómo se ve en la app
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedDemoType == AlertType.medical
                                  ? const Color(0xFF10B981)
                                  : _selectedDemoType == AlertType.fire
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFFEF4444),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(_selectedDemoType.emoji, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedDemoType.label,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: primaryText,
                                          ),
                                        ),
                                        Text(
                                          _selectedDemoType.subtitle,
                                          style: TextStyle(fontSize: 12, color: secondaryText),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedDemoType == AlertType.robbery
                                            ? '💬 "Me robaron / Rejas forzadas en la propiedad"'
                                            : _selectedDemoType == AlertType.medical
                                                ? '💬 "Adulto mayor se cayó y está grave"'
                                                : _selectedDemoType == AlertType.fire
                                                    ? '💬 "Fuego en la casa / Cortocircuito y humo"'
                                                    : _selectedDemoType == AlertType.following
                                                        ? '💬 "Me siguen dos encapuchados por la calle"'
                                                        : '💬 "Personas merodeando mirando las casas"',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.amberAccent : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 2. SERVICIOS DE EMERGENCIA (911, COMISARÍAS, HOSPITALES Y BOMBEROS) ──
            _buildSectionHeader(
              icon: Icons.phone_in_talk_rounded,
              title: '2. Llamadas de Emergencia y Entidades Cercanas',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'En todas las alertas de la comunidad, el número principal centralizado es el 911. Además, la aplicación detecta tu ubicación GPS para mostrar las entidades de auxilio más cercanas:',
                    style: TextStyle(fontSize: 14.5, color: secondaryText, height: 1.5),
                  ),
                  const SizedBox(height: 14),

                  _buildFeatureBullet(
                    icon: Icons.shield_rounded,
                    color: const Color(0xFFDC2626),
                    title: '911 (Emergencias Centralizadas)',
                    description: 'Acceso directo con un solo toque desde cualquier alerta enviada o desde el mapa para comunicarte al instante.',
                  ),
                  _buildFeatureBullet(
                    icon: Icons.local_police_rounded,
                    color: const Color(0xFF2563EB),
                    title: 'Comisarías más cercanas',
                    description: 'Visualiza la comisaría más cercana con distancia en km, tiempo estimado en auto y opción de llamada directa.',
                  ),
                  _buildFeatureBullet(
                    icon: Icons.local_hospital_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Hospitales y Guardias Médicas',
                    description: 'En emergencias de salud o médicas, consulta los hospitales más cercanos con mapa de ruta en Google Maps y teléfonos de guardia.',
                  ),
                  _buildFeatureBullet(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFF97316),
                    title: 'Cuarteles de Bomberos (Alertas de Incendio 🔥)',
                    description: 'En alertas de incendio, la app te permite llamar a los bomberos y muestra los cuarteles más cercanos con teléfonos de guardia y mapa de ruta.',
                  ),

                  const SizedBox(height: 16),

                  // MUESTRA VISTA DE BOTONES DE LLAMADA
                  Text(
                    'VISTA DE OPCIONES DE LLAMADA EN LA APP:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: primaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              _showDemoSnackbar(context, 'Demostración: Inicia llamada directo al 911');
                            },
                            icon: const Icon(Icons.shield_rounded, size: 20),
                            label: const Text('LLAMAR DIRECTO AL 911 (EMERGENCIAS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Fila ejemplo Comisaría
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_police_rounded, color: Color(0xFF2563EB), size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Comisaría 12ª • 1.2 km (4 min en auto)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _showDemoSnackbar(context, 'Demostración: Llamando a la Comisaría 12ª');
                                },
                                child: const Text('Llamar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),

                        // Fila ejemplo Hospital
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_hospital_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Hospital Central • 2.5 km (7 min en auto)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _showDemoSnackbar(context, 'Demostración: Llamando al Hospital Central');
                                },
                                child: const Text('Llamar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981))),
                              ),
                            ],
                          ),
                        ),

                        // Fila ejemplo Bomberos
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Cuartel de Bomberos • 1.8 km (5 min en auto)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _showDemoSnackbar(context, 'Demostración: Llamando al Cuartel de Bomberos');
                                },
                                child: const Text('Llamar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFF97316))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 3. MAPA INTERACTIVO Y ALERTA ACTIVA ───────────────────────────
            _buildSectionHeader(
              icon: Icons.map_rounded,
              title: '3. Mapa Interactivo y Alertas Activas en la Red',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'El Mapa muestra en tiempo real la ubicación exacta de las emergencias, comisarías, hospitales, bomberos y la posición de los vecinos conectados.',
                    style: TextStyle(fontSize: 14.5, color: secondaryText, height: 1.5),
                  ),
                  const SizedBox(height: 14),

                  // Muestra interactiva del banner de alerta activa
                  Text(
                    'BANNER FLOTANTE CUANDO HAY ALERTAS ACTIVAS:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: primaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      _showDemoSnackbar(context, 'Al tocar este banner en el mapa, vuelas automáticamente al lugar exacto de la emergencia.');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚨 1 ALERTA ACTIVA EN TU RED',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  'Toca aquí para volar a la ubicación en el mapa',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildFeatureBullet(
                    icon: Icons.person_pin_circle_rounded,
                    color: const Color(0xFFEF4444),
                    title: 'Ficha completa del hogar',
                    description: 'Al tocar el marcador de una alerta en el mapa, verás los datos del vecino en peligro: Manzana, Casa, Departamento, Barrio y Referencias de la vivienda.',
                  ),
                  _buildFeatureBullet(
                    icon: Icons.directions_car_rounded,
                    color: const Color(0xFF22C55E),
                    title: 'Cálculo de Distancia y Tiempo en Auto',
                    description: 'Calcula el tiempo estimado en vehículo (estilo Google Maps) hacia comisarías, hospitales o bomberos para saber cómo actuar rápidamente.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 4. CONFIRMACIÓN Y VISTOS ───────────────────────────────────────
            _buildSectionHeader(
              icon: Icons.touch_app_rounded,
              title: '4. "Marcar Visto" y Acompañamiento',
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuando un vecino emite una alerta, presiona "Marcar Visto" para avisarle que estás al tanto y la ayuda está en marcha. Si la alerta es tuya, verás cuántos vecinos ya la leyeron en tiempo real.',
                    style: TextStyle(fontSize: 14.5, color: secondaryText, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF3B82F6), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '5 vecinos vieron esta alerta',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 5. SEGUIMIENTO "ME SIGUEN" ─────────────────────────────────────
            _buildSectionHeader(
              icon: Icons.directions_run_rounded,
              title: '5. Modo "Me Siguen / Sospechosos"',
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              isDark: isDark,
              child: Text(
                'Al activar "Me siguen", la aplicación transmitirá tu posición GPS actualizada cada pocos segundos en el mapa de la comunidad para que tus vecinos puedan dar seguimiento a tus pasos hasta que ingreses seguro a tu hogar.',
                style: TextStyle(fontSize: 14.5, color: secondaryText, height: 1.5),
              ),
            ),

            const SizedBox(height: 24),

            // ── 6. RECLAMOS VECINALES Y DENUNCIA ONLINE ───────────────────────
            _buildSectionHeader(
              icon: Icons.forum_rounded,
              title: '6. Reclamos Vecinales y Denuncia Online',
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'En la nueva sección de Reclamos, cualquier vecino puede exponer inquietudes de la comunidad (luminarias rotas, ruidos molestos, seguridad del barrio) y coordinar soluciones.',
                    style: TextStyle(fontSize: 14.5, color: secondaryText, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  _buildFeatureBullet(
                    icon: Icons.add_comment_rounded,
                    color: const Color(0xFF0284C7),
                    title: 'Publicación de Reclamos con Notificación',
                    description: 'Al presionar "+ Nuevo Reclamo", puedes describir la situación. Al publicar, se emite una notificación con sonido personalizado exclusivo de reclamos.',
                  ),
                  _buildFeatureBullet(
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFEF4444),
                    title: 'Me Gusta y Respuestas',
                    description: 'Dale "Me gusta" a los reclamos para apoyar la inquietud y responde en el hilo de comentarios para dialogar con los demás vecinos.',
                  ),
                  _buildFeatureBullet(
                    icon: Icons.person_search_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Identificación y Ficha del Vecino',
                    description: 'Cada reclamo muestra el autor. Al tocar el nombre o avatar, se despliega su ficha con Manzana, Casa, Barrio y botón para llamarlo.',
                  ),
                  _buildFeatureBullet(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFDC2626),
                    title: 'Gestión y Eliminación de Publicaciones',
                    description: 'Si tú creaste el reclamo, verás el icono de tacho de basura para eliminar la publicación cuando el tema esté resuelto.',
                  ),
                  _buildFeatureBullet(
                    icon: Icons.gavel_rounded,
                    color: const Color(0xFF0284C7),
                    title: 'Botón Denuncia Online (Portal MPF)',
                    description: 'Si necesitas realizar una denuncia formal, el botón "Denuncia Online" te redirige directamente al sitio oficial del Ministerio Público Fiscal.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón de Cierre
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('ENTENDIDO, VOLVER AL INICIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showDemoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
