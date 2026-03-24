import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';

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
        title: Text(AppL10n.of(context).privacyPolicyTitle),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip,
                      color: AppColors.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppL10n.of(context).privacyPolicyTitle,
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
              'Introducci�n',
              'En Chamos Fitness Center, respetamos su privacidad y nos comprometemos a proteger '
                  'sus datos personales. Esta pol�tica explica c�mo recopilamos, usamos y protegemos '
                  'su informaci�n cuando utiliza nuestra aplicaci�n.',
            ),

            _buildSection(
              '1. Informaci�n que Recopilamos',
              'Recopilamos los siguientes tipos de informaci�n:\n\n'
                  'Informaci�n de Cuenta:\n'
                  '� Nombre completo\n'
                  '� Correo electr�nico\n'
                  '� Contrase�a (encriptada)\n'
                  '� Fecha de nacimiento\n\n'
                  'Informaci�n f�sica:\n'
                  '� Peso y altura\n'
                  '� Medidas corporales (pecho, cintura, cadera, b�ceps, muslos)\n'
                  '� Fotograf�as de progreso (opcional)\n'
                  '� Nivel de experiencia\n\n'
                  'Informaci�n de Actividad:\n'
                  '� Entrenamientos completados\n'
                  '� Duraci�n de sesiones\n'
                  '� Calor�as quemadas\n'
                  '� Metas y objetivos\n'
                  '� Historial de progreso',
            ),

            _buildSection(
              '2. C�mo Usamos su Informaci�n',
              'Utilizamos su informaci�n para:\n\n'
                  '� Proporcionar y personalizar nuestros servicios\n'
                  '� Crear rutinas de entrenamiento personalizadas\n'
                  '� Hacer seguimiento de su progreso f�sico\n'
                  '� Enviar notificaciones sobre entrenamientos\n'
                  '� Mejorar la experiencia del usuario\n'
                  '� Comunicarnos con usted sobre actualizaciones\n'
                  '� Cumplir con requisitos legales',
            ),

            _buildSection(
              '3. Almacenamiento de Datos',
              'Sus datos se almacenan de forma segura en servidores cloud de Supabase:\n\n'
                  '� Encriptaci�n en tr�nsito y en reposo\n'
                  '� Acceso restringido mediante autenticaci�n\n'
                  '� Copias de seguridad regulares\n'
                  '� Cumplimiento con est�ndares de seguridad internacionales',
            ),

            _buildSection(
              '4. Compartir Informaci�n',
              'NO vendemos ni compartimos su informaci�n personal con terceros, excepto:\n\n'
                  '� Con su consentimiento expl�cito\n'
                  '� Para cumplir con requisitos legales\n'
                  '� Con proveedores de servicios (Supabase) bajo estrictos acuerdos de confidencialidad\n\n'
                  'Cuando comparte su progreso usando la funci�n "Compartir", usted controla qu� informaci�n se comparte.',
            ),

            _buildSection(
              '5. Sus Derechos',
              'Usted tiene derecho a:\n\n'
                  '**Acceso:** Ver toda su informaci�n personal\n'
                  '**Rectificaci�n:** Corregir datos incorrectos\n'
                  '**Eliminaci�n:** Borrar su cuenta y datos permanentemente\n'
                  '**Portabilidad:** Exportar sus datos\n'
                  '**Revocaci�n:** Retirar consentimientos en cualquier momento',
            ),

            _buildSection(
              '6. Retenci�n de Datos',
              'Conservamos su informaci�n mientras:\n\n'
                  '� Su cuenta est� activa\n'
                  '� Sea necesario para proporcionar servicios\n'
                  '� Lo requieran obligaciones legales\n\n'
                  'Al eliminar su cuenta, todos sus datos se borran permanentemente en un plazo de 30 d�as.',
            ),

            _buildSection(
              '7. Seguridad',
              'Implementamos medidas de seguridad t�cnicas y organizativas:\n\n'
                  '� Autenticaci�n segura (JWT tokens)\n'
                  '� Encriptaci�n de contrase�as con bcrypt\n'
                  '� Row Level Security (RLS) en base de datos\n'
                  '� Conexiones HTTPS/SSL\n'
                  '� Auditor�as de seguridad regulares\n'
                  '� Validaci�n de entrada de datos',
            ),

            _buildSection(
              '8. Cookies y Tecnolog�as Similares',
              'Utilizamos tecnolog�as de almacenamiento local para:\n\n'
                  '� Mantener su sesi�n activa\n'
                  '� Recordar preferencias de la aplicaci�n\n'
                  '� Mejorar el rendimiento\n\n'
                  'No utilizamos cookies de terceros para rastreo o publicidad.',
            ),

            _buildSection(
              '9. Menores de Edad',
              'Nuestra aplicaci�n est� dirigida a personas mayores de 18 a�os. '
                  'Los menores entre 13-16 a�os requieren consentimiento parental. '
                  'No recopilamos intencionalmente datos de menores de 13 a�os.',
            ),

            _buildSection(
              '10. Transferencias Internacionales',
              'Sus datos pueden ser procesados en servidores ubicados fuera de Venezuela. '
                  'Garantizamos que estas transferencias cumplan con las leyes de protecci�n de datos aplicables.',
            ),

            _buildSection(
              '11. Cambios a esta Pol�tica',
              'Podemos actualizar esta pol�tica ocasionalmente. Le notificaremos de cambios '
                  'significativos mediante:\n\n'
                  '� Notificaci�n en la aplicaci�n\n'
                  '� Email a su direcci�n registrada\n'
                  '� Actualizaci�n de la fecha al inicio de este documento',
            ),

            _buildSection(
              '12. Contacto',
              'Para ejercer sus derechos o preguntas sobre privacidad:\n\n'
                  '� Email: privacy@chamosfitnesscenter.com\n'
                  '� Secci�n de Ajustes ? Privacidad\n'
                  '� Responderemos en un plazo de 30 d�as',
            ),

            _buildSection(
              'Cumplimiento Legal',
              'Esta pol�tica cumple con:\n\n'
                  '� GDPR (Reglamento General de Protecci�n de Datos - UE)\n'
                  '� CCPA (California Consumer Privacy Act)\n'
                  '� Ley Org�nica de Protecci�n de Datos Personales (Venezuela)\n'
                  '� Mejores pr�cticas internacionales de privacidad',
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
                    'Nos comprometemos a proteger sus datos personales con los m�s altos est�ndares de seguridad.',
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
