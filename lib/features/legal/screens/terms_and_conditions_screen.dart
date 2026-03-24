import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';

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
        title: Text(AppL10n.of(context).termsTitle),
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
              child: Row(
                children: [
                  const Icon(Icons.description, color: AppColors.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppL10n.of(context).termsTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '�ltima actualizaci�n: 11 de febrero de 2026',
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
              '1. Aceptaci�n de los T�rminos',
              'Al acceder y utilizar la aplicaci�n Chamos Fitness Center, usted acepta estar sujeto a estos T�rminos y Condiciones. Si no est� de acuerdo con alguna parte de estos t�rminos, no debe utilizar nuestra aplicaci�n.',
            ),

            _buildSection(
              '2. Uso del Servicio',
              'Chamos Fitness Center es una plataforma de fitness que proporciona:\n\n'
                  '� Rutinas de entrenamiento personalizadas\n'
                  '� Planes de alimentaci�n\n'
                  '� Seguimiento de progreso f�sico\n'
                  '� Gesti�n de sesiones de entrenamiento\n\n'
                  'Usted se compromete a utilizar el servicio �nicamente para fines legales y de acuerdo con estos t�rminos.',
            ),

            _buildSection(
              '3. Registro de Cuenta',
              'Para utilizar ciertas funciones de la aplicaci�n, debe:\n\n'
                  '� Proporcionar informaci�n veraz y actualizada\n'
                  '� Mantener la seguridad de su contrase�a\n'
                  '� Notificarnos inmediatamente sobre cualquier uso no autorizado\n'
                  '� Ser mayor de 16 a�os o tener consentimiento parental',
            ),

            _buildSection(
              '4. Privacidad y Protecci�n de Datos',
              'Nos tomamos muy en serio la protecci�n de sus datos personales. '
                  'Su informaci�n ser� tratada de acuerdo con nuestra Pol�tica de Privacidad, '
                  'que cumple con las regulaciones de protecci�n de datos aplicables.',
            ),

            _buildSection(
              '5. Servicios de Entrenamiento',
              'Los servicios de entrenamiento proporcionados son �nicamente para fines informativos y educativos:\n\n'
                  '� Consulte a un m�dico antes de comenzar cualquier programa de ejercicios\n'
                  '� No somos responsables de lesiones derivadas del uso inadecuado\n'
                  '� Los resultados pueden variar seg�n cada persona\n'
                  '� Siga las instrucciones de forma segura y responsable',
            ),

            _buildSection(
              '6. Contenido del Usuario',
              'Al compartir contenido en la aplicaci�n (fotos, medidas, comentarios):\n\n'
                  '� Usted mantiene la propiedad de su contenido\n'
                  '� Nos otorga licencia para usar ese contenido en la plataforma\n'
                  '� Es responsable de la precisi�n de la informaci�n proporcionada\n'
                  '� No debe compartir contenido ofensivo o inapropiado',
            ),

            _buildSection(
              '7. Cancelaci�n de Cuenta',
              'Usted puede eliminar su cuenta en cualquier momento desde la configuraci�n. '
                  'Esta acci�n es permanente e irreversible, eliminando todos sus datos asociados.',
            ),

            _buildSection(
              '8. Limitaci�n de Responsabilidad',
              'Chamos Fitness Center no ser� responsable de:\n\n'
                  '� Lesiones o da�os derivados del uso de los programas de entrenamiento\n'
                  '� P�rdida de datos debido a fallas t�cnicas\n'
                  '� Interrupci�n del servicio por mantenimiento\n'
                  '� Resultados espec�ficos no alcanzados',
            ),

            _buildSection(
              '9. Modificaciones del Servicio',
              'Nos reservamos el derecho de:\n\n'
                  '� Modificar o descontinuar funcionalidades\n'
                  '� Actualizar estos t�rminos en cualquier momento\n'
                  '� Suspender cuentas que violen estos t�rminos',
            ),

            _buildSection(
              '10. Propiedad Intelectual',
              'Todo el contenido de la aplicaci�n (rutinas, planes, dise�o, logotipos) '
                  'es propiedad de Chamos Fitness Center y est� protegido por leyes de derechos de autor.',
            ),

            _buildSection(
              '11. Ley Aplicable',
              'Estos t�rminos se regir�n e interpretar�n de acuerdo con las leyes aplicables '
                  'en la Rep�blica Bolivariana de Venezuela.',
            ),

            _buildSection(
              '12. Contacto',
              'Para preguntas sobre estos t�rminos, puede contactarnos a trav�s de:\n\n'
                  '� Email: legal@chamos?tnessenter.com\n'
                  '� En la secci�n de Ajustes de la aplicaci�n',
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Al continuar usando Chamos Fitness Center, usted acepta estos T�rminos y Condiciones en su totalidad.',
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
