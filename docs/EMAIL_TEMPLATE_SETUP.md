# 📧 Template de Email Personalizado - Chamos Fitness Center

## 🎨 Configuración Completa del Email de Recuperación de Contraseña

Este documento contiene el template de email profesional con el branding completo de Chamos Fitness Center.

---

## 🚀 Guía Rápida de Implementación

### Paso 1: Acceder a Supabase Dashboard

1. Abre [https://app.supabase.com](https://app.supabase.com)
2. Selecciona tu proyecto **Chamos Fitness Center**
3. En el menú lateral, ve a **Authentication** → **Email Templates**
4. Busca la sección **"Reset Password"** o **"Forgot Password"**

### Paso 2: Configurar el Subject (Asunto)

Reemplaza el asunto predeterminado por:

```
🔐 Recupera tu Acceso - Chamos Fitness Center
```

### Paso 3: Copiar el Template HTML

Copia el siguiente código HTML completo y pégalo en el editor de Supabase:

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>Recuperar Contraseña - Chamos Fitness Center</title>
  <!--[if mso]>
  <style type="text/css">
    body, table, td {font-family: Arial, Helvetica, sans-serif !important;}
  </style>
  <![endif]-->
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      margin: 0;
      padding: 0;
      width: 100% !important;
      -webkit-text-size-adjust: 100%;
      -ms-text-size-adjust: 100%;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background-color: #0a0a0a;
      color: #ffffff;
    }
    .email-container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #0a0a0a;
    }
    .wrapper {
      padding: 40px 20px;
    }
    
    /* Header con gradiente dorado */
    .header {
      text-align: center;
      padding: 40px 20px 30px;
      background: linear-gradient(135deg, #FFD700 0%, #FFA500 50%, #FFD700 100%);
      border-radius: 16px 16px 0 0;
      position: relative;
      overflow: hidden;
    }
    .header::before {
      content: '';
      position: absolute;
      top: -50%;
      left: -50%;
      width: 200%;
      height: 200%;
      background: repeating-linear-gradient(
        45deg,
        transparent,
        transparent 10px,
        rgba(255, 255, 255, 0.1) 10px,
        rgba(255, 255, 255, 0.1) 20px
      );
      animation: shimmer 20s linear infinite;
    }
    @keyframes shimmer {
      0% { transform: translate(-50%, -50%) rotate(0deg); }
      100% { transform: translate(-50%, -50%) rotate(360deg); }
    }
    
    /* Logo */
    .logo-container {
      position: relative;
      z-index: 1;
    }
    .logo {
      width: 100px;
      height: 100px;
      background: #000000;
      margin: 0 auto 20px;
      border-radius: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 50px;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
      border: 3px solid rgba(255, 255, 255, 0.2);
    }
    .brand-name {
      font-size: 36px;
      font-weight: 900;
      color: #000000;
      margin: 0 0 8px;
      letter-spacing: 4px;
      text-transform: uppercase;
      text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
      position: relative;
      z-index: 1;
    }
    .brand-tagline {
      font-size: 13px;
      font-weight: 600;
      color: #000000;
      margin: 0;
      letter-spacing: 3px;
      text-transform: uppercase;
      position: relative;
      z-index: 1;
    }
    
    /* Content area */
    .content {
      background-color: #1a1a1a;
      padding: 48px 32px;
      border-radius: 0 0 16px 16px;
      box-shadow: 0 4px 24px rgba(0, 0, 0, 0.5);
    }
    
    /* Icono animado */
    .icon-wrapper {
      text-align: center;
      margin-bottom: 24px;
    }
    .icon {
      font-size: 64px;
      line-height: 1;
      display: inline-block;
      animation: pulse 2s ease-in-out infinite;
    }
    @keyframes pulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.1); }
    }
    
    .title {
      font-size: 28px;
      font-weight: 800;
      color: #FFD700;
      margin: 0 0 24px;
      text-align: center;
      line-height: 1.3;
    }
    .greeting {
      font-size: 18px;
      font-weight: 600;
      color: #FFD700;
      text-align: center;
      margin: 0 0 16px;
    }
    .message {
      color: #cccccc;
      line-height: 1.7;
      margin: 0 0 32px;
      text-align: center;
      font-size: 15px;
    }
    .message strong {
      color: #FFD700;
      font-weight: 700;
    }
    
    /* Botón principal */
    .button-container {
      text-align: center;
      margin: 40px 0;
    }
    .button {
      display: inline-block;
      padding: 18px 56px;
      background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
      color: #000000 !important;
      text-decoration: none;
      border-radius: 12px;
      font-weight: 800;
      font-size: 17px;
      letter-spacing: 1px;
      text-transform: uppercase;
      box-shadow: 
        0 6px 20px rgba(255, 215, 0, 0.4),
        0 0 0 3px rgba(255, 215, 0, 0.2);
      transition: all 0.3s ease;
      border: none;
    }
    .button:hover {
      transform: translateY(-2px);
      box-shadow: 
        0 8px 24px rgba(255, 215, 0, 0.5),
        0 0 0 3px rgba(255, 215, 0, 0.3);
    }
    
    /* Avisos de seguridad */
    .security-notice {
      background: linear-gradient(135deg, #2a2a2a 0%, #1f1f1f 100%);
      border-left: 5px solid #FFD700;
      padding: 20px;
      margin: 28px 0;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
    }
    .security-notice p {
      margin: 0 0 12px;
      color: #cccccc;
      font-size: 14px;
      line-height: 1.6;
    }
    .security-notice p:last-child {
      margin-bottom: 0;
    }
    .security-notice strong {
      color: #FFD700;
      font-weight: 700;
    }
    .security-notice .icon-inline {
      margin-right: 8px;
    }
    
    /* Lista de consejos */
    .tips-list {
      margin: 12px 0 0 0;
      padding-left: 0;
      list-style: none;
    }
    .tips-list li {
      padding: 6px 0 6px 28px;
      position: relative;
      color: #cccccc;
      font-size: 13px;
    }
    .tips-list li:before {
      content: '✓';
      position: absolute;
      left: 0;
      color: #FFD700;
      font-weight: bold;
      font-size: 16px;
    }
    
    /* Footer */
    .footer {
      text-align: center;
      padding: 40px 20px;
      color: #666666;
      font-size: 13px;
      line-height: 1.6;
    }
    .footer strong {
      color: #999999;
    }
    .footer a {
      color: #FFD700;
      text-decoration: none;
      font-weight: 600;
      transition: color 0.3s ease;
    }
    .footer a:hover {
      color: #FFA500;
      text-decoration: underline;
    }
    .footer-links {
      margin: 20px 0;
    }
    .footer-links a {
      margin: 0 12px;
      display: inline-block;
    }
    .copyright {
      margin-top: 24px;
      color: #444444;
      font-size: 12px;
    }
    .tagline {
      color: #FFD700;
      font-weight: 700;
      font-size: 14px;
      margin-top: 8px;
    }
    
    /* Divider */
    .divider {
      height: 1px;
      background: linear-gradient(90deg, transparent 0%, #333333 50%, transparent 100%);
      margin: 32px 0;
    }
    
    /* Responsive */
    @media only screen and (max-width: 600px) {
      .wrapper {
        padding: 20px 10px !important;
      }
      .content {
        padding: 32px 20px !important;
      }
      .brand-name {
        font-size: 28px !important;
      }
      .title {
        font-size: 22px !important;
      }
      .button {
        padding: 16px 40px !important;
        font-size: 15px !important;
      }
      .logo {
        width: 80px !important;
        height: 80px !important;
        font-size: 40px !important;
      }
    }
  </style>
</head>
<body>
  <div class="email-container">
    <div class="wrapper">
      <!-- Header con branding -->
      <div class="header">
        <div class="logo-container">
          <div class="logo">🏋️</div>
          <h1 class="brand-name">CHAMOS</h1>
          <p class="brand-tagline">Fitness Center</p>
        </div>
      </div>
      
      <!-- Contenido principal -->
      <div class="content">
        <div class="icon-wrapper">
          <span class="icon">🔐</span>
        </div>
        
        <h2 class="title">Recuperación de Contraseña</h2>
        
        <p class="greeting">¡Hola, Chamo! 👋</p>
        
        <p class="message">
          Recibimos una solicitud para <strong>restablecer la contraseña</strong> de tu cuenta<br>
          en <strong>Chamos Fitness Center</strong>.
        </p>
        
        <p class="message" style="font-size: 14px; color: #999999;">
          Para continuar con el proceso, haz clic en el botón de abajo:
        </p>
        
        <!-- Botón de acción -->
        <div class="button-container">
          <a href="{{ .ConfirmationURL }}" class="button">
            🔓 Restablecer Mi Contraseña
          </a>
        </div>
        
        <!-- Aviso de tiempo de expiración -->
        <div class="security-notice">
          <p>
            <strong><span class="icon-inline">⏰</span>Importante:</strong> 
            Este enlace expirará en <strong>24 horas</strong> por razones de seguridad.
          </p>
        </div>
        
        <div class="divider"></div>
        
        <p class="message" style="font-size: 14px; color: #888888;">
          Si <strong>NO solicitaste</strong> este cambio, puedes ignorar este correo de forma segura.<br>
          Tu cuenta permanecerá completamente protegida.
        </p>
        
        <!-- Consejos de seguridad -->
        <div class="security-notice">
          <p><strong><span class="icon-inline">🛡️</span>Consejos de Seguridad:</strong></p>
          <ul class="tips-list">
            <li>Nunca compartas tu contraseña con nadie</li>
            <li>Usa una contraseña única y diferente a otros sitios</li>
            <li>Combina letras, números y símbolos</li>
            <li>Cambia tu contraseña periódicamente</li>
            <li>No uses información personal obvia</li>
          </ul>
        </div>
      </div>
      
      <!-- Footer -->
      <div class="footer">
        <p>
          Este correo fue enviado desde <strong>Chamos Fitness Center</strong>
        </p>
        <p style="margin-top: 8px;">
          📧 <a href="mailto:support@chamosfitnesscenter.com">support@chamosfitnesscenter.com</a>
        </p>
        
        <div class="footer-links">
          <a href="{{ .SiteURL }}/terms-and-conditions">Términos y Condiciones</a>
          <span style="color: #333;">•</span>
          <a href="{{ .SiteURL }}/privacy-policy">Política de Privacidad</a>
        </div>
        
        <div class="divider"></div>
        
        <p class="copyright">
          © 2026 Chamos Fitness Center<br>
          Todos los derechos reservados
        </p>
        <p class="tagline">
          💪 Tu mejor versión comienza aquí
        </p>
      </div>
    </div>
  </div>
</body>
</html>
```

---

## ✅ Vista Previa del Email

Así se verá el email que recibirán tus usuarios:

**Header:**
- 🏋️ Logo negro con emoji de pesas
- "CHAMOS" en letras grandes y negras
- "FITNESS CENTER" en subtítulo
- Fondo con gradiente dorado animado (#FFD700 → #FFA500)

**Contenido:**
- 🔐 Icono de candado con animación de pulso
- Título dorado: "Recuperación de Contraseña"
- Saludo personalizado: "¡Hola, Chamo! 👋"
- Mensaje claro y conciso
- Botón prominente dorado: "🔓 Restablecer Mi Contraseña"
- Aviso de expiración (24h) en caja destacada
- Lista de consejos de seguridad con checkmarks
- Footer con links legales y branding

**Diseño:**
- ✨ Animaciones sutiles (pulso en icono, shimmer en header)
- 📱 100% responsive (se adapta perfectamente a móviles)
- 🎨 Paleta de colores consistente con la app
- 🌙 Dark theme para reducir fatiga visual
- 🖼️ Compatible con todos los clientes de email (Gmail, Outlook, Apple Mail)

---

### Paso 4: Versión de Texto Plano (Fallback)

También configura la versión en texto plano para clientes de email básicos:

```
═══════════════════════════════════════════════════════════════
            🏋️ CHAMOS FITNESS CENTER 🏋️
           Tu mejor versión comienza aquí 💪
═══════════════════════════════════════════════════════════════

🔐 RECUPERACIÓN DE CONTRASEÑA

¡Hola, Chamo! 👋

Recibimos una solicitud para RESTABLECER LA CONTRASEÑA de tu 
cuenta en Chamos Fitness Center.

───────────────────────────────────────────────────────────────
📌 ACCIÓN REQUERIDA:
───────────────────────────────────────────────────────────────

Haz clic en el siguiente enlace para crear una nueva contraseña:

{{ .ConfirmationURL }}

───────────────────────────────────────────────────────────────
⏰ IMPORTANTE:
───────────────────────────────────────────────────────────────

Este enlace expirará en 24 HORAS por razones de seguridad.

Si NO solicitaste este cambio, puedes ignorar este correo de 
forma segura. Tu cuenta permanecerá completamente protegida.

───────────────────────────────────────────────────────────────
🛡️ CONSEJOS DE SEGURIDAD:
───────────────────────────────────────────────────────────────

✓ Nunca compartas tu contraseña con nadie
✓ Usa una contraseña única y diferente a otros sitios
✓ Combina letras, números y símbolos
✓ Cambia tu contraseña periódicamente
✓ No uses información personal obvia (fechas, nombres)

───────────────────────────────────────────────────────────────
📧 SOPORTE Y AYUDA:
───────────────────────────────────────────────────────────────

¿Necesitas ayuda? Escríbenos:
Email: support@chamosfitnesscenter.com

Términos y Condiciones:
{{ .SiteURL }}/terms-and-conditions

Política de Privacidad:
{{ .SiteURL }}/privacy-policy

═══════════════════════════════════════════════════════════════
© 2026 Chamos Fitness Center
Todos los derechos reservados.

💪 Sigue entrenando, sigue creciendo
═══════════════════════════════════════════════════════════════
```

---

## 🔧 Configuración en Supabase Dashboard

### Paso 5: Configurar URLs de Redirección

En **Authentication** → **URL Configuration**, agrega:

**Site URL:**
```
https://chamosfitnesscenter.app
```

**Redirect URLs (una por línea):**
```
chamosfitnessapp://reset-password
https://chamosfitnesscenter.app/reset-password
http://localhost:3000/reset-password
```

### Paso 6: Configurar Tiempo de Expiración del Token

En **Authentication** → **Settings** → **Auth Email**:

- **Email Link Expiry**: `86400` segundos (24 horas)
- **Enable Email Confirmations**: `ON`
- **Secure Email Change**: `ON`

---

## 🧪 Probar el Template

### Paso 7: Hacer una Prueba Real

1. **Guarda** todos los cambios en Supabase
2. Abre tu app en el dispositivo
3. Ve a **Login** → **¿Olvidaste tu contraseña?**
4. Introduce tu email de prueba
5. Espera 1-2 minutos
6. **Revisa tu bandeja de entrada**
7. Verifica que el diseño se vea correcto
8. Haz clic en el botón para probar el flujo completo

### Checklist de Verificación:

- [ ] El email llega en menos de 2 minutos
- [ ] El diseño se ve bien en Gmail
- [ ] El diseño se ve bien en Outlook
- [ ] El diseño se ve bien en Apple Mail (móvil)
- [ ] Los colores son dorados y negros
- [ ] El logo se muestra correctamente
- [ ] El botón es clicable y funciona
- [ ] El enlace redirige correctamente
- [ ] La versión texto plano se ve bien
- [ ] No está marcado como spam
- [ ] El header animado funciona
- [ ] El icono tiene la animación de pulso

---

## 🎨 Personalización Adicional (Opcional)

### Agregar Logo Real (en lugar del emoji)

Sube tu logo a un CDN o hosting público y reemplaza:

```html
<div class="logo">🏋️</div>
```

Por:

```html
<img src="https://tu-cdn.com/chamos-logo.png" 
     alt="Chamos Fitness Center" 
     style="width: 100%; height: 100%; object-fit: contain; border-radius: 24px;">
```

### Agregar Redes Sociales en el Footer

En el footer, después de los links legales, agrega:

```html
<div style="margin: 24px 0;">
  <a href="https://instagram.com/chamosfitness" style="margin: 0 10px; color: #FFD700;">
    📸 Instagram
  </a>
  <a href="https://facebook.com/chamosfitness" style="margin: 0 10px; color: #FFD700;">
    📘 Facebook
  </a>
  <a href="https://twitter.com/chamosfitness" style="margin: 0 10px; color: #FFD700;">
    🐦 Twitter
  </a>
</div>
```

### Cambiar Colores de Marca

Si quieres usar otros colores, busca y reemplaza:

- `#FFD700` (Dorado principal) → Tu color primario
- `#FFA500` (Naranja/Dorado oscuro) → Tu color secundario
- `#0a0a0a` (Negro background) → Tu fondo oscuro
- `#1a1a1a` (Gris oscuro content) → Tu fondo de contenido

---

## 📱 Deep Linking (Configuración Avanzada)

Para que el enlace abra directamente la app en móviles:

### Android (AndroidManifest.xml)

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="chamosfitnessapp"
        android:host="reset-password" />
</intent-filter>
```

### iOS (Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>chamosfitnessapp</string>
        </array>
    </dict>
</array>
```

---

## 📊 Métricas y Análisis

Para rastrear el rendimiento del email:

1. **Tasa de apertura**: Cuántos usuarios abren el email
2. **Tasa de clic**: Cuántos hacen clic en el botón
3. **Tiempo promedio**: Cuánto tardan en restablecer
4. **Bounces**: Emails que rebotan
5. **Spam reports**: Reportes de spam

Puedes usar servicios como:
- SendGrid Analytics
- AWS SES Metrics
- Mailgun Analytics

---

## 🔒 Seguridad y Mejores Prácticas

### ✅ Implementado en este template:

- ✅ HTTPS en todos los enlaces
- ✅ Token de seguridad de Supabase
- ✅ Expiración de 24 horas
- ✅ Mensaje claro si no fue solicitado
- ✅ No se pide contraseña por email
- ✅ Links directos (sin redirecciones sospechosas)
- ✅ Branding consistente (anti-phishing)
- ✅ Texto alternativo para accesibilidad

### 🛡️ Recomendaciones adicionales:

- Configurar SPF/DKIM/DMARC en tu dominio
- Usar un dominio propio (@chamosfitnesscenter.com)
- Monitorear reportes de spam
- Mantener lista de emails bloqueados
- No enviar emails masivos desde el mismo sistema

---

## 📞 Soporte

Si tienes problemas configurando el template:

1. Verifica que copiaste el HTML completo
2. Asegúrate de que las variables `{{ .ConfirmationURL }}` y `{{ .SiteURL }}` estén presentes
3. Prueba primero con un email personal
4. Revisa la carpeta de spam
5. Consulta los logs de Supabase

Para más ayuda:
- **Documentación Supabase**: https://supabase.com/docs/guides/auth/auth-email-templates
- **Soporte**: docs/SUPABASE_EMAIL_CONFIG.md

---

**¡Listo!** Tu sistema de recuperación de contraseña ahora tiene el branding completo de Chamos Fitness Center 🎉

**Última actualización:** 11 de febrero de 2026  
**Versión:** 2.0  
**Mantenedor:** Equipo Chamos Fitness Center
