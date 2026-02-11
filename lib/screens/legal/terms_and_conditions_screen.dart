import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Términos y Condiciones'),
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
                  Icon(Icons.description, color: AppColors.primary, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Términos y Condiciones',
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
              '1. Aceptación de los Términos',
              'Al acceder y utilizar la aplicación Chamos Fitness Center, usted acepta estar sujeto a estos Términos y Condiciones. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestra aplicación.',
            ),

            _buildSection(
              '2. Uso del Servicio',
              'Chamos Fitness Center es una plataforma de fitness que proporciona:\n\n'
                  '• Rutinas de entrenamiento personalizadas\n'
                  '• Planes de alimentación\n'
                  '• Seguimiento de progreso físico\n'
                  '• Gestión de sesiones de entrenamiento\n\n'
                  'Usted se compromete a utilizar el servicio únicamente para fines legales y de acuerdo con estos términos.',
            ),

            _buildSection(
              '3. Registro de Cuenta',
              'Para utilizar ciertas funciones de la aplicación, debe:\n\n'
                  '• Proporcionar información veraz y actualizada\n'
                  '• Mantener la seguridad de su contraseña\n'
                  '• Notificarnos inmediatamente sobre cualquier uso no autorizado\n'
                  '• Ser mayor de 16 años o tener consentimiento parental',
            ),

            _buildSection(
              '4. Privacidad y Protección de Datos',
              'Nos tomamos muy en serio la protección de sus datos personales. '
                  'Su información será tratada de acuerdo con nuestra Política de Privacidad, '
                  'que cumple con las regulaciones de protección de datos aplicables.',
            ),

            _buildSection(
              '5. Servicios de Entrenamiento',
              'Los servicios de entrenamiento proporcionados son únicamente para fines informativos y educativos:\n\n'
                  '• Consulte a un médico antes de comenzar cualquier programa de ejercicios\n'
                  '• No somos responsables de lesiones derivadas del uso inadecuado\n'
                  '• Los resultados pueden variar según cada persona\n'
                  '• Siga las instrucciones de forma segura y responsable',
            ),

            _buildSection(
              '6. Contenido del Usuario',
              'Al compartir contenido en la aplicación (fotos, medidas, comentarios):\n\n'
                  '• Usted mantiene la propiedad de su contenido\n'
                  '• Nos otorga licencia para usar ese contenido en la plataforma\n'
                  '• Es responsable de la precisión de la información proporcionada\n'
                  '• No debe compartir contenido ofensivo o inapropiado',
            ),

            _buildSection(
              '7. Cancelación de Cuenta',
              'Usted puede eliminar su cuenta en cualquier momento desde la configuración. '
                  'Esta acción es permanente e irreversible, eliminando todos sus datos asociados.',
            ),

            _buildSection(
              '8. Limitación de Responsabilidad',
              'Chamos Fitness Center no será responsable de:\n\n'
                  '• Lesiones o daños derivados del uso de los programas de entrenamiento\n'
                  '• Pérdida de datos debido a fallas técnicas\n'
                  '• Interrupción del servicio por mantenimiento\n'
                  '• Resultados específicos no alcanzados',
            ),

            _buildSection(
              '9. Modificaciones del Servicio',
              'Nos reservamos el derecho de:\n\n'
                  '• Modificar o descontinuar funcionalidades\n'
                  '• Actualizar estos términos en cualquier momento\n'
                  '• Suspender cuentas que violen estos términos',
            ),

            _buildSection(
              '10. Propiedad Intelectual',
              'Todo el contenido de la aplicación (rutinas, planes, diseño, logotipos) '
                  'es propiedad de Chamos Fitness Center y está protegido por leyes de derechos de autor.',
            ),

            _buildSection(
              '11. Ley Aplicable',
              'Estos términos se regirán e interpretarán de acuerdo con las leyes aplicables '
                  'en la República Bolivariana de Venezuela.',
            ),

            _buildSection(
              '12. Contacto',
              'Para preguntas sobre estos términos, puede contactarnos a través de:\n\n'
                  '• Email: legal@chamosﬁtnessenter.com\n'
                  '• En la sección de Ajustes de la aplicación',
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Al continuar usando Chamos Fitness Center, usted acepta estos Términos y Condiciones en su totalidad.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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
