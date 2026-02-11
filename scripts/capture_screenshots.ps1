# ============================================================================
# SCRIPT DE CAPTURA DE SCREENSHOTS - Chamos Fitness Center
# ============================================================================
# Automatiza la captura de screenshots para Google Play Store y Apple App Store
# 
# REQUISITOS:
# - Flutter instalado
# - ADB configurado para Android
# - Xcode + Simulador para iOS (solo en Mac)
# 
# USO:
#   .\capture_screenshots.ps1 -Platform android
#   .\capture_screenshots.ps1 -Platform ios
#   .\capture_screenshots.ps1 -Platform all
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("android", "ios", "all")]
    [string]$Platform
)

# Configuración
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
$SCREENSHOTS_DIR = Join-Path $PROJECT_ROOT "screenshots"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Crear directorios para screenshots
function Initialize-Directories {
    Write-Host "📁 Creando directorios para screenshots..." -ForegroundColor Cyan
    
    $dirs = @(
        "$SCREENSHOTS_DIR\android\phone",
        "$SCREENSHOTS_DIR\android\tablet",
        "$SCREENSHOTS_DIR\ios\iphone_6_7",
        "$SCREENSHOTS_DIR\ios\iphone_6_5",
        "$SCREENSHOTS_DIR\ios\ipad_12_9"
    )
    
    foreach ($dir in $dirs) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  ✅ Creado: $dir" -ForegroundColor Green
        }
    }
}

# Verificar dispositivos conectados
function Test-AndroidDevice {
    Write-Host "`n🔍 Verificando dispositivos Android..." -ForegroundColor Cyan
    $devices = adb devices | Select-String -Pattern "device$"
    
    if ($devices.Count -eq 0) {
        Write-Host "  ❌ No hay dispositivos Android conectados" -ForegroundColor Red
        Write-Host "  💡 Conecta un dispositivo o inicia un emulador" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "  ✅ Dispositivo(s) encontrado(s): $($devices.Count)" -ForegroundColor Green
    return $true
}

# Instrucciones para el usuario
function Show-Instructions {
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  📸 INSTRUCCIONES PARA CAPTURA DE SCREENSHOTS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  El script va a iniciar la app en el dispositivo/emulador." -ForegroundColor White
    Write-Host "  Después de cada pantalla mencionada, presiona:" -ForegroundColor White
    Write-Host ""
    Write-Host "    ENTER" -ForegroundColor Green -NoNewline
    Write-Host " - Para capturar la pantalla actual" -ForegroundColor White
    Write-Host "    Q" -ForegroundColor Red -NoNewline
    Write-Host " - Para saltar esta pantalla" -ForegroundColor White
    Write-Host ""
    Write-Host "  Pantallas a capturar (en orden):" -ForegroundColor Yellow
    Write-Host "    1️⃣  Dashboard principal (home)" -ForegroundColor White
    Write-Host "    2️⃣  Lista de rutinas de entrenamiento" -ForegroundColor White
    Write-Host "    3️⃣  Detalle de rutina con ejercicios" -ForegroundColor White
    Write-Host "    4️⃣  Video de ejercicio reproduciéndose" -ForegroundColor White
    Write-Host "    5️⃣  Pantalla de progreso/estadísticas" -ForegroundColor White
    Write-Host "    6️⃣  Perfil de usuario" -ForegroundColor White
    Write-Host "    7️⃣  Plan de nutrición o recetas" -ForegroundColor White
    Write-Host "    8️⃣  (Opcional) Logros o medallas" -ForegroundColor White
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  ¿Listo para comenzar? " -ForegroundColor Yellow -NoNewline
    $ready = Read-Host "[Y/n]"
    
    if ($ready -eq "n" -or $ready -eq "N") {
        Write-Host "`n❌ Cancelado por el usuario" -ForegroundColor Red
        exit 1
    }
}

# Capturar screenshot en Android
function Capture-AndroidScreenshot {
    param(
        [string]$Name,
        [string]$Description,
        [int]$Index
    )
    
    Write-Host "`n📸 Screenshot $Index : $Description" -ForegroundColor Cyan
    Write-Host "  Navega a la pantalla y presiona ENTER para capturar (Q para saltar)..." -ForegroundColor Yellow
    
    $input = Read-Host
    
    if ($input -eq "q" -or $input -eq "Q") {
        Write-Host "  ⏭️  Saltado" -ForegroundColor Yellow
        return
    }
    
    # Capturar screenshot
    $filename = "$($Index)_$Name`_$TIMESTAMP.png"
    $devicePath = "/sdcard/screenshot_temp.png"
    
    Write-Host "  📷 Capturando..." -ForegroundColor Gray
    adb shell screencap -p $devicePath | Out-Null
    
    # Obtener resolución
    $resolution = adb shell wm size | Select-String -Pattern "Physical size: (\d+)x(\d+)"
    $width = [int]$resolution.Matches.Groups[1].Value
    $height = [int]$resolution.Matches.Groups[2].Value
    
    # Determinar si es phone o tablet
    $deviceType = if ($width -ge 1200 -or $height -ge 1920) { "tablet" } else { "phone" }
    $localPath = Join-Path "$SCREENSHOTS_DIR\android\$deviceType" $filename
    
    # Descargar screenshot
    adb pull $devicePath $localPath | Out-Null
    adb shell rm $devicePath | Out-Null
    
    if (Test-Path $localPath) {
        Write-Host "  ✅ Capturado: $filename ($width x $height)" -ForegroundColor Green
        Write-Host "     Guardado en: android\$deviceType\" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Error al capturar screenshot" -ForegroundColor Red
    }
}

# Screenshots para Android
function Capture-AndroidScreenshots {
    Write-Host "`n🤖 CAPTURA DE SCREENSHOTS - ANDROID" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════" -ForegroundColor Yellow
    
    if (!(Test-AndroidDevice)) {
        return
    }
    
    Show-Instructions
    
    # Iniciar app
    Write-Host "`n🚀 Iniciando app en dispositivo Android..." -ForegroundColor Cyan
    Set-Location $PROJECT_ROOT
    Start-Process -NoNewWindow -FilePath "flutter" -ArgumentList "run --release" -PassThru | Out-Null
    Start-Sleep -Seconds 10
    
    # Lista de screenshots a capturar
    $screenshots = @(
        @{Name="dashboard"; Description="Dashboard principal con estadísticas"},
        @{Name="workouts"; Description="Lista de rutinas de entrenamiento"},
        @{Name="workout_detail"; Description="Detalle de rutina con ejercicios"},
        @{Name="exercise_video"; Description="Video de ejercicio en reproducción"},
        @{Name="progress"; Description="Gráficas de progreso y estadísticas"},
        @{Name="profile"; Description="Perfil de usuario con datos"},
        @{Name="nutrition"; Description="Planes de nutrición o recetas"},
        @{Name="achievements"; Description="(Opcional) Logros y medallas"}
    )
    
    for ($i = 0; $i -lt $screenshots.Count; $i++) {
        $shot = $screenshots[$i]
        Capture-AndroidScreenshot -Name $shot.Name -Description $shot.Description -Index ($i + 1)
    }
    
    Write-Host "`n✅ Captura de screenshots Android completada!" -ForegroundColor Green
    Write-Host "   Revisa la carpeta: $SCREENSHOTS_DIR\android\" -ForegroundColor Cyan
}

# Screenshots para iOS (solo Mac)
function Capture-iOSScreenshots {
    Write-Host "`n🍎 CAPTURA DE SCREENSHOTS - iOS" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════" -ForegroundColor Yellow
    
    if ($IsMacOS) {
        Write-Host "`n  Este script requiere ejecución en macOS" -ForegroundColor Yellow
        Write-Host "  Por favor, sigue estas instrucciones en tu Mac:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1. Abre el simulador de iOS (iPhone 15 Pro Max)" -ForegroundColor White
        Write-Host "  2. Ejecuta: flutter run" -ForegroundColor White
        Write-Host "  3. Navega por las pantallas y presiona Cmd+S para capturar" -ForegroundColor White
        Write-Host "  4. Los screenshots se guardan automáticamente en Desktop" -ForegroundColor White
        Write-Host "  5. Mueve las capturas a: $SCREENSHOTS_DIR\ios\iphone_6_7\" -ForegroundColor White
        Write-Host ""
        Write-Host "  Simuladores recomendados:" -ForegroundColor Yellow
        Write-Host "    - iPhone 15 Pro Max (6.7'') - 1290 x 2796" -ForegroundColor White
        Write-Host "    - iPhone 14 Plus (6.5'') - 1284 x 2778" -ForegroundColor White
        Write-Host "    - iPad Pro 12.9'' - 2048 x 2732" -ForegroundColor White
    } else {
        Write-Host "  ❌ Este sistema operativo no soporta simuladores de iOS" -ForegroundColor Red
        Write-Host "  💡 Necesitas un Mac con Xcode para capturar screenshots de iOS" -ForegroundColor Yellow
    }
}

# Generar README con información
function Generate-ReadMe {
    $readmePath = Join-Path $SCREENSHOTS_DIR "README.md"
    
    $content = @"
# 📸 Screenshots - Chamos Fitness Center

**Fecha de captura:** $(Get-Date -Format "dd/MM/yyyy HH:mm")  
**Versión de la app:** 1.0.0

---

## 🤖 Android - Google Play Store

### Requisitos de Google Play

| Tipo | Resolución | Mínimo | Máximo | Formato |
|------|-----------|--------|--------|---------|
| **Phone** | 1242 x 2688 px | 3 | 8 | PNG/JPG |
| **7" Tablet** | 1024 x 1920 px | 0 | 8 | PNG/JPG |
| **10" Tablet** | 2048 x 1536 px | 0 | 8 | PNG/JPG |

**Ubicación:** ``screenshots/android/``

**Screenshots recomendados (en orden):**
1. 🏠 Dashboard principal - Primera impresión con estadísticas
2. 💪 Rutinas disponibles - Muestra variedad de entrenamientos
3. 📋 Detalle de rutina - Ejercicios incluidos
4. 🎥 Video de ejercicio - Demuestra contenido de calidad
5. 📊 Progreso y gráficas - Tracking de resultados
6. 👤 Perfil de usuario - Personalización
7. 🥗 Nutrición - Valor agregado
8. 🏆 Logros - Gamificación

---

## 🍎 iOS - Apple App Store

### Requisitos de App Store

| Dispositivo | Resolución | Mínimo | Máximo | Formato |
|-------------|-----------|--------|--------|---------|
| **6.7" Display** | 1290 x 2796 px | 3 | 10 | PNG/JPG |
| **6.5" Display** | 1284 x 2778 px | 3 | 10 | PNG/JPG |
| **iPad Pro 12.9"** | 2048 x 2732 px | 0 | 10 | PNG/JPG |

**Ubicación:** ``screenshots/ios/``

---

## 📝 Notas Importantes

### ✅ Buenas Prácticas

- **Orden estratégico:** La primera screenshot es la MÁS importante
- **Contenido real:** Usa datos realistas, no "Lorem ipsum"
- **Sin texto en screenshots:** Apple/Google rechazan imágenes con mucho texto
- **Coherencia:** Usa el mismo usuario/progreso en todas las capturas
- **Iluminación:** Pantallas brillantes, sin modo oscuro (salvo que sea feature)
- **Sin barra de notificaciones:** Modo inmersivo para capturas limpias

### ❌ Evitar

- ❌ Screenshots con información de desarrollo (debug info)
- ❌ Capturas borrosas o pixeladas
- ❌ Diferentes niveles de usuario entre screenshots
- ❌ Errores visibles o pantallas vacías
- ❌ Contenido ofensivo o inapropiado

---

## 🎨 Post-Procesamiento (Opcional)

Si quieres mejorar tus screenshots:

1. **Agregar marcos de dispositivo:**
   - [Shots.so](https://shots.so/) - Gratis, online
   - [Previewed](https://previewed.app/) - Mockups profesionales
   
2. **Agregar texto descriptivo:**
   - Canva (templates de app screenshots)
   - Figma (diseño personalizado)
   
3. **Comprimir sin pérdida:**
   - [TinyPNG](https://tinypng.com/)
   - [ImageOptim](https://imageoptim.com/) (Mac)

**⚠️ Importante:** Las dimensiones finales DEBEN coincidir exactamente con los requisitos.

---

## 📤 Checklist de Subida

### Android (Google Play Console)

- [ ] Mínimo 3 screenshots de phone
- [ ] Máximo 8 screenshots por tipo
- [ ] Formato: PNG o JPG
- [ ] Resolución: 1242 x 2688 (phone)
- [ ] Peso: Menos de 8 MB cada una
- [ ] Sin bordes negros o espacios en blanco

### iOS (App Store Connect)

- [ ] Mínimo 3 screenshots de 6.7"
- [ ] Mínimo 3 screenshots de 6.5"
- [ ] Máximo 10 screenshots por tamaño
- [ ] Formato: PNG o JPG
- [ ] Resolución exacta: 1290 x 2796 y 1284 x 2778
- [ ] Sin alpha channel (transparencia)
- [ ] Espacio de color: sRGB o Display P3

---

## 🔗 Recursos Útiles

- [Google Play Screenshot Guidelines](https://support.google.com/googleplay/android-developer/answer/9866151)
- [App Store Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)
- [Flutter Screenshot Package](https://pub.dev/packages/screenshot) (automatización)

---

**Generado automáticamente por:** ``capture_screenshots.ps1``
"@

    Set-Content -Path $readmePath -Value $content -Encoding UTF8
    Write-Host "`n📝 README generado: $readmePath" -ForegroundColor Green
}

# Resumen final
function Show-Summary {
    Write-Host "`n"
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  ✅ PROCESO COMPLETADO" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  📁 Screenshots guardados en:" -ForegroundColor Yellow
    Write-Host "     $SCREENSHOTS_DIR" -ForegroundColor White
    Write-Host ""
    Write-Host "  📋 Próximos pasos:" -ForegroundColor Yellow
    Write-Host "     1. Revisa las capturas y elimina las que no sirvan" -ForegroundColor White
    Write-Host "     2. Renombra archivos para mejor organización" -ForegroundColor White
    Write-Host "     3. (Opcional) Agrega marcos con https://shots.so" -ForegroundColor White
    Write-Host "     4. Sube a Google Play Console / App Store Connect" -ForegroundColor White
    Write-Host ""
    Write-Host "  📖 Lee el README.md generado para más información" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "║     📸 CHAMOS FITNESS CENTER - SCREENSHOT CAPTURE 📸      ║" -ForegroundColor Yellow
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Initialize-Directories

switch ($Platform) {
    "android" {
        Capture-AndroidScreenshots
    }
    "ios" {
        Capture-iOSScreenshots
    }
    "all" {
        Capture-AndroidScreenshots
        Capture-iOSScreenshots
    }
}

Generate-ReadMe
Show-Summary

Write-Host "🎉 ¡Listo! Buena suerte con la publicación 🚀" -ForegroundColor Green
Write-Host ""
