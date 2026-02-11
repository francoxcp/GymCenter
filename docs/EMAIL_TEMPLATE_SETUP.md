# Configuración del Template de Email para Recuperación de Contraseña

## 📧 Template Personalizado para Supabase

Para personalizar el email de recuperación de contraseña en Supabase con el branding de Chamos Fitness Center:

### 1. Acceder al Dashboard de Supabase

1. Ve a [https://app.supabase.com](https://app.supabase.com)
2. Selecciona tu proyecto: **Chamos Fitness Center**
3. Ve a **Authentication** → **Email Templates**

### 2. Seleccionar Template "Reset Password"

Busca el template **"Reset Password"** o **"Magic Link"** y haz clic en editar.

### 3. Copiar el siguiente HTML Personalizado

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Recuperar Contraseña - Chamos Fitness Center</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background-color: #0a0a0a;
      color: #ffffff;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      padding: 40px 20px;
    }
    .header {
      text-align: center;
      padding: 30px 0;
      background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
      border-radius: 12px 12px 0 0;
    }
    .logo {
      width: 80px;
      height: 80px;
      background-color: #FFD700;
      margin: 0 auto 16px;
      border-radius: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 40px;
      font-weight: bold;
      color: #000000;
    }
    .brand-name {
      font-size: 28px;
      font-weight: bold;
      color: #000000;
      margin: 0;
      letter-spacing: 2px;
    }
    .brand-tagline {
      font-size: 14px;
      color: #000000;
      margin: 8px 0 0;
      letter-spacing: 2px;
    }
    .content {
      background-color: #1a1a1a;
      padding: 40px 32px;
      border-radius: 0 0 12px 12px;
    }
    .title {
      font-size: 24px;
      font-weight: bold;
      color: #FFD700;
      margin: 0 0 16px;
      text-align: center;
    }
    .message {
      color: #b3b3b3;
      line-height: 1.6;
      margin: 0 0 32px;
      text-align: center;
      font-size: 15px;
    }
    .button-container {
      text-align: center;
      margin: 32px 0;
    }
    .button {
      display: inline-block;
      padding: 16px 48px;
      background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
      color: #000000;
      text-decoration: none;
      border-radius: 8px;
      font-weight: bold;
      font-size: 16px;
      letter-spacing: 0.5px;
      box-shadow: 0 4px 12px rgba(255, 215, 0, 0.3);
    }
    .security-notice {
      background-color: #2a2a2a;
      border-left: 4px solid #FFD700;
      padding: 16px;
      margin: 24px 0;
      border-radius: 4px;
    }
    .security-notice p {
      margin: 0;
      color: #b3b3b3;
      font-size: 13px;
      line-height: 1.5;
    }
    .security-notice strong {
      color: #FFD700;
    }
    .footer {
      text-align: center;
      padding: 32px 20px;
      color: #666666;
      font-size: 12px;
    }
    .footer a {
      color: #FFD700;
      text-decoration: none;
    }
    .icon {
      font-size: 48px;
      text-align: center;
      margin: 0 0 16px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">🏋️</div>
      <h1 class="brand-name">CHAMOS</h1>
      <p class="brand-tagline">FITNESS CENTER</p>
    </div>
    
    <div class="content">
      <div class="icon">🔐</div>
      <h2 class="title">Recuperación de Contraseña</h2>
      
      <p class="message">
        ¡Hola, Chamo! 👋<br><br>
        Recibimos una solicitud para restablecer la contraseña de tu cuenta en <strong>Chamos Fitness Center</strong>.
      </p>
      
      <div class="button-container">
        <a href="{{ .ConfirmationURL }}" class="button">
          🔓 Restablecer Contraseña
        </a>
      </div>
      
      <div class="security-notice">
        <p>
          <strong>⏰ Importante:</strong> Este enlace expirará en <strong>24 horas</strong> por seguridad.
        </p>
      </div>
      
      <p class="message" style="font-size: 13px; color: #888888;">
        Si no solicitaste cambiar tu contraseña, puedes ignorar este correo de forma segura.
        Tu cuenta permanecerá protegida.
      </p>
      
      <div class="security-notice">
        <p>
          <strong>🛡️ Consejos de seguridad:</strong><br>
          • Nunca compartas tu contraseña con nadie<br>
          • Usa una contraseña única y segura<br>
          • Cambia tu contraseña regularmente<br>
          • No uses esta contraseña en otros sitios
        </p>
      </div>
    </div>
    
    <div class="footer">
      <p>
        Este correo fue enviado desde <strong>Chamos Fitness Center</strong><br>
        <a href="mailto:support@chamosfitnesscenter.com">support@chamosfitnesscenter.com</a>
      </p>
      <p style="margin-top: 16px;">
        <a href="{{ .SiteURL }}/terms-and-conditions">Términos y Condiciones</a> • 
        <a href="{{ .SiteURL }}/privacy-policy">Política de Privacidad</a>
      </p>
      <p style="margin-top: 16px; color: #444444;">
        © 2026 Chamos Fitness Center. Todos los derechos reservados.<br>
        Tu mejor versión comienza aquí 💪
      </p>
    </div>
  </div>
</body>
</html>
```

### 4. Variables Disponibles en Supabase

El template de Supabase reemplaza automáticamente estas variables:

- `{{ .ConfirmationURL }}` - El enlace para restablecer contraseña
- `{{ .SiteURL }}` - URL base de tu aplicación
- `{{ .Token }}` - Token de confirmación
- `{{ .TokenHash }}` - Hash del token

### 5. Configurar la URL de Redirección

En **Authentication** → **URL Configuration**, configura:

```
Site URL: https://chamosfitnesscenter.app
Redirect URLs: 
  - chamosfitnessapp://reset-password
  - https://chamosfitnesscenter.app/reset-password
  - http://localhost:3000/reset-password (para desarrollo)
```

### 6. Subject del Email (Asunto)

Cambia el asunto del email a:

```
🔐 Recupera tu acceso - Chamos Fitness Center
```

### 7. Versión de Texto Plano (Fallback)

También configura la versión en texto plano para clientes de email que no soporten HTML:

```
CHAMOS FITNESS CENTER
Tu mejor versión comienza aquí

===============================================

RECUPERACIÓN DE CONTRASEÑA

Hola!

Recibimos una solicitud para restablecer la contraseña de tu cuenta.

Haz clic en el siguiente enlace para crear una nueva contraseña:
{{ .ConfirmationURL }}

⏰ IMPORTANTE: Este enlace expirará en 24 horas por seguridad.

Si no solicitaste cambiar tu contraseña, puedes ignorar este correo.
Tu cuenta permanecerá protegida.

===============================================

CONSEJOS DE SEGURIDAD:
• Nunca compartas tu contraseña con nadie
• Usa una contraseña única y segura
• Cambia tu contraseña regularmente
• No uses esta contraseña en otros sitios

===============================================

¿Necesitas ayuda?
Escríbenos a: support@chamosfitnesscenter.com

Términos: {{ .SiteURL }}/terms-and-conditions
Privacidad: {{ .SiteURL }}/privacy-policy

© 2026 Chamos Fitness Center
Todos los derechos reservados.
```

### 8. Probar el Template

1. Guarda los cambios en Supabase
2. Ve a la app y usa la opción "¿Olvidaste tu contraseña?"
3. Introduce un email de prueba
4. Revisa tu bandeja de entrada para verificar el diseño

### 9. Personalización Adicional

Puedes personalizar más aspectos:

- **Colores**: Cambia `#FFD700` (dorado) y `#FFA500` (naranja) por tus colores de marca
- **Logo**: Reemplaza el emoji 🏋️ por una URL de imagen real
- **Fuentes**: Agrega Google Fonts si deseas tipografías específicas
- **Footer**: Agrega links a redes sociales

### 10. Mejores Prácticas

✅ **Testing**: Siempre prueba en múltiples clientes de email (Gmail, Outlook, Apple Mail)
✅ **Mobile**: Verifica que se vea bien en dispositivos móviles
✅ **Spam**: Evita palabras como "FREE", "CLICK HERE", exceso de mayúsculas
✅ **Accesibilidad**: Mantén buen contraste y tamaños de fuente legibles
✅ **Autenticación**: Nunca pidas la contraseña por email

---

## 🎨 Personalización Avanzada

### Agregar Logo Real

Sube tu logo a un CDN o hosting público y reemplaza:

```html
<div class="logo">🏋️</div>
```

Por:

```html
<img src="https://tu-cdn.com/chamos-logo.png" alt="Chamos Fitness Center" style="width: 80px; height: 80px; border-radius: 20px;">
```

### Agregar Redes Sociales

En el footer, agrega:

```html
<div style="margin: 20px 0;">
  <a href="https://instagram.com/chamosfitness" style="margin: 0 8px;">📸 Instagram</a>
  <a href="https://facebook.com/chamosfitness" style="margin: 0 8px;">📘 Facebook</a>
  <a href="https://twitter.com/chamosfitness" style="margin: 0 8px;">🐦 Twitter</a>
</div>
```

---

## 📱 Deep Linking (Opcional)

Para que el enlace abra directamente la app en móviles, configura:

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

**¡Listo!** Tu sistema de recuperación de contraseña ahora tiene el branding completo de Chamos Fitness Center 🎉
