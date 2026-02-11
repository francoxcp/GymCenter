import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Política de Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.privacy_tip, color: AppColors.primary, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Política de Privacidad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Última actualización: 11 de febrero de 2026',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSection(
              'Introducción',
              'En Chamos Fitness Center, respetamos su privacidad y nos comprometemos a proteger '
                  'sus datos personales. Esta política explica cómo recopilamos, usamos y protegemos '
                  'su información cuando utiliza nuestra aplicación.',
            ),

            _buildSection(
              '1. Información que Recopilamos',
              'Recopilamos los siguientes tipos de información:\n\n'
                  '**Información de Cuenta:**\n'
                  '• Nombre completo\n'
                  '• Correo electrónico\n'
                  '• Contraseña (encriptada)\n'
                  '• Fecha de nacimiento\n\n'
                  '**Información Física:**\n'
                  '• Peso y altura\n'
                  '• Medidas corporales (pecho, cintura, cadera, bíceps, muslos)\n'
                  '• Fotografías de progreso (opcional)\n'
                  '• Nivel de experiencia\n\n'
                  '**Información de Actividad:**\n'
                  '• Entrenamientos completados\n'
                  '• Duración de sesiones\n'
                  '• Calorías quemadas\n'
                  '• Metas y objetivos\n'
                  '• Historial de progreso',
            ),

            _buildSection(
              '2. Cómo Usamos su Información',
              'Utilizamos su información para:\n\n'
                  '• Proporcionar y personalizar nuestros servicios\n'
                  '• Crear rutinas de entrenamiento personalizadas\n'
                  '• Hacer seguimiento de su progreso físico\n'
                  '• Enviar notificaciones sobre entrenamientos\n'
                  '• Mejorar la experiencia del usuario\n'
                  '• Comunicarnos con usted sobre actualizaciones\n'
                  '• Cumplir con requisitos legales',
            ),

            _buildSection(
              '3. Almacenamiento de Datos',
              'Sus datos se almacenan de forma segura en servidores cloud de Supabase:\n\n'
                  '• Encriptación en tránsito y en reposo\n'
                  '• Acceso restringido mediante autenticación\n'
                  '• Copias de seguridad regulares\n'
                  '• Cumplimiento con estándares de seguridad internacionales',
            ),

            _buildSection(
              '4. Compartir Información',
              'NO vendemos ni compartimos su información personal con terceros, excepto:\n\n'
                  '• Con su consentimiento explícito\n'
                  '• Para cumplir con requisitos legales\n'
                  '• Con proveedores de servicios (Supabase) bajo estrictos acuerdos de confidencialidad\n\n'
                  'Cuando comparte su progreso usando la función "Compartir", usted controla qué información se comparte.',
            ),

            _buildSection(
              '5. Sus Derechos',
              'Usted tiene derecho a:\n\n'
                  '**Acceso:** Ver toda su información personal\n'
                  '**Rectificación:** Corregir datos incorrectos\n'
                  '**Eliminación:** Borrar su cuenta y datos permanentemente\n'
                  '**Portabilidad:** Exportar sus datos\n'
                  '**Revocación:** Retirar consentimientos en cualquier momento',
            ),

            _buildSection(
              '6. Retención de Datos',
              'Conservamos su información mientras:\n\n'
                  '• Su cuenta esté activa\n'
                  '• Sea necesario para proporcionar servicios\n'
                  '• Lo requieran obligaciones legales\n\n'
                  'Al eliminar su cuenta, todos sus datos se borran permanentemente en un plazo de 30 días.',
            ),

            _buildSection(
              '7. Seguridad',
              'Implementamos medidas de seguridad técnicas y organizativas:\n\n'
                  '• Autenticación segura (JWT tokens)\n'
                  '• Encriptación de contraseñas con bcrypt\n'
                  '• Row Level Security (RLS) en base de datos\n'
                  '• Conexiones HTTPS/SSL\n'
                  '• Auditorías de seguridad regulares\n'
                  '• Validación de entrada de datos',
            ),

            _buildSection(
              '8. Cookies y Tecnologías Similares',
              'Utilizamos tecnologías de almacenamiento local para:\n\n'
                  '• Mantener su sesión activa\n'
                  '• Recordar preferencias de la aplicación\n'
                  '• Mejorar el rendimiento\n\n'
                  'No utilizamos cookies de terceros para rastreo o publicidad.',
            ),

            _buildSection(
              '9. Menores de Edad',
              'Nuestra aplicación está dirigida a personas mayores de 16 años. '
                  'Los menores entre 13-16 años requieren consentimiento parental. '
                  'No recopilamos intencionalmente datos de menores de 13 años.',
            ),

            _buildSection(
              '10. Transferencias Internacionales',
              'Sus datos pueden ser procesados en servidores ubicados fuera de Venezuela. '
                  'Garantizamos que estas transferencias cumplan con las leyes de protección de datos aplicables.',
            ),

            _buildSection(
              '11. Cambios a esta Política',
              'Podemos actualizar esta política ocasionalmente. Le notificaremos de cambios '
                  'significativos mediante:\n\n'
                  '• Notificación en la aplicación\n'
                  '• Email a su dirección registrada\n'
                  '• Actualización de la fecha al inicio de este documento',
            ),

            _buildSection(
              '12. Contacto',
              'Para ejercer sus derechos o preguntas sobre privacidad:\n\n'
                  '• Email: privacy@chamosfitnesscenter.com\n'
                  '• Sección de Ajustes → Privacidad\n'
                  '• Responderemos en un plazo de 30 días',
            ),

            _buildSection(
              'Cumplimiento Legal',
              'Esta política cumple con:\n\n'
                  '• GDPR (Reglamento General de Protección de Datos - UE)\n'
                  '• CCPA (California Consumer Privacy Act)\n'
                  '• Ley Orgánica de Protección de Datos Personales (Venezuela)\n'
                  '• Mejores prácticas internacionales de privacidad',
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_user, color: AppColors.primary, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Su Privacidad es Nuestra Prioridad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nos comprometemos a proteger sus datos personales con los más altos estándares de seguridad.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
