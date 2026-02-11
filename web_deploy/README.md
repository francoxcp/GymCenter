# 🌐 Archivos HTML para GitHub Pages

Este directorio contiene las páginas web estáticas de **Privacy Policy** y **Terms & Conditions** para Chamos Fitness Center.

## 📄 Archivos

- **`privacy.html`** - Política de Privacidad completa
- **`terms.html`** - Términos y Condiciones completos

## 🚀 Despliegue en GitHub Pages (GRATIS)

### Paso 1: Crear Repositorio

```bash
# Opción A: Crear repo desde GitHub.com
1. Ve a https://github.com/new
2. Nombre: chamos-privacy (o el que prefieras)
3. Público ✅
4. Create repository

# Opción B: Desde terminal
git init
git add .
git commit -m "Add privacy and terms pages"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/chamos-privacy.git
git push -u origin main
```

### Paso 2: Habilitar GitHub Pages

1. En el repo, ve a **Settings** → **Pages**
2. **Source:** Deploy from a branch
3. **Branch:** `main` → carpeta: `/ (root)`
4. **Save**
5. Espera 1-2 minutos

### Paso 3: Verificar URLs

Tus páginas estarán disponibles en:

```
https://TU_USUARIO.github.io/chamos-privacy/privacy.html
https://TU_USUARIO.github.io/chamos-privacy/terms.html
```

## 🔧 Actualizar URLs en la App

Después de publicar, actualiza estas URLs en tu código:

### 1. Privacy Policy Screen

**Archivo:** `lib/screens/legal/privacy_policy_screen.dart`

```dart
// Línea ~187
'• Email: privacy@chamosfitnesscenter.com\n'

// Cambiar a tu email real:
'• Email: TU_EMAIL@gmail.com\n'
```

### 2. App Store Connect / Play Console

Al subir a las tiendas, usa estas URLs:

```
Privacy Policy: https://TU_USUARIO.github.io/chamos-privacy/privacy.html
Terms of Service: https://TU_USUARIO.github.io/chamos-privacy/terms.html
```

## ✅ Checklist de Publicación

- [ ] Repo creado en GitHub (público)
- [ ] Archivos `privacy.html` y `terms.html` subidos
- [ ] GitHub Pages habilitado
- [ ] URLs funcionando (sin 404)
- [ ] URLs actualizadas en código de la app
- [ ] URLs agregadas en Play Store listing
- [ ] URLs agregadas en App Store Connect
- [ ] Email de contacto actualizado a uno real

## 🎨 Personalización

Si quieres personalizar los archivos HTML:

### Cambiar colores

```css
/* En <style> sección */
.header {
    background: linear-gradient(135deg, #TU_COLOR_1 0%, #TU_COLOR_2 100%);
}

h2 {
    color: #TU_COLOR;
    border-bottom: 3px solid #TU_COLOR;
}
```

### Cambiar información de contacto

Busca y reemplaza en ambos archivos:

```
privacy@chamosfitnesscenter.com → tu-email@ejemplo.com
support@chamosfitnesscenter.com → soporte@ejemplo.com
legal@chamosfitnesscenter.com → legal@ejemplo.com
https://chamosfitness.com → https://tu-sitio.com
```

## 🆓 Alternativas a GitHub Pages

Si GitHub Pages no te funciona, usa:

### Netlify (Gratis)
1. [Netlify.com](https://www.netlify.com/)
2. Conecta tu repo de GitHub
3. Auto-deploy en cada push
4. URL: `https://tu-app.netlify.app`

### Vercel (Gratis)
1. [Vercel.com](https://vercel.com/)
2. Conecta GitHub
3. Deploy automático
4. URL: `https://tu-app.vercel.app`

### Surge.sh (Gratis)
```bash
npm install -g surge
cd web_deploy
surge
# URL: https://tu-dominio.surge.sh
```

## 📱 Testing

Antes de enviar a las tiendas, verifica:

1. **Abre las URLs** en navegador móvil
2. **Verifica que sean responsive** (se vean bien en móvil)
3. **Comprueba todos los links** internos
4. **Lee el contenido** para asegurar que es correcto
5. **Sin errores 404** o problemas de carga

## 🔒 Seguridad y HTTPS

GitHub Pages automáticamente usa HTTPS, lo cual es **requerido** por Apple y Google.

✅ Tus URLs serán: `https://` (seguras)

## 📧 Emails de Contacto

**IMPORTANTE:** Actualiza los emails a direcciones reales que monitorees:

```
privacy@chamosfitnesscenter.com → Crear email real
support@chamosfitnesscenter.com → Crear email real
legal@chamosfitnesscenter.com → Crear email real
```

**Opciones:**
- Gmail personal (gratis)
- Google Workspace ($6/mes/usuario)
- ProtonMail (gratis/premium)
- Email de dominio propio

## ❓ Problemas Comunes

### Error: "404 - Page not found"
- Espera 2-5 minutos después de habilitar Pages
- Verifica que los archivos estén en la raíz del repo
- Nombres deben ser `privacy.html` y `terms.html` (minúsculas)

### No se ve bien en móvil
- Los archivos ya son responsive
- Si editaste el CSS, verifica las media queries

### Apple/Google rechazan las URLs
- Asegúrate que sean HTTPS (no HTTP)
- Verifica que las páginas carguen sin errores
- El contenido debe ser accesible públicamente

## 📞 Soporte

Si tienes problemas:
- [Documentación de GitHub Pages](https://docs.github.com/es/pages)
- [Foro de GitHub](https://github.community/)

---

**Última actualización:** 11 de febrero de 2026  
**Mantenido por:** Chamos Fitness Center  
**Versión:** 1.0.0
