# Scripts de Utilidad

Este directorio contiene scripts útiles para el desarrollo y deployment.

## 📜 Scripts Disponibles

### Windows (PowerShell)

#### `build_production.bat`
Compila la app en modo release para Android.

```bash
./scripts/build_production.bat
```

#### `install_dependencies.bat`
Instala todas las dependencias del proyecto.

```bash
./scripts/install_dependencies.bat
```

#### `setup.bat`
Configuración inicial del proyecto en Windows.

```bash
./scripts/setup.bat
```

---

### macOS/Linux (Bash)

#### `setup_ios.sh` ⭐ NUEVO
Configuración automática para desarrollo iOS en MacBook.

**Uso en MacBook:**
```bash
# Dar permisos de ejecución (solo primera vez)
chmod +x scripts/setup_ios.sh

# Ejecutar
./scripts/setup_ios.sh
```

**Qué hace:**
- ✅ Verifica que Flutter, Xcode y CocoaPods estén instalados
- ✅ Ejecuta `flutter clean` y `flutter pub get`
- ✅ Instala pods con `pod install`
- ✅ Configura Xcode Command Line Tools
- ✅ Ejecuta `flutter doctor` para verificar setup
- ✅ Muestra instrucciones para ejecutar en iPhone

---

## 🚀 Workflows Comunes

### Desarrollo en Windows
```bash
# Instalar dependencias
./scripts/install_dependencies.bat

# Ejecutar en Chrome
flutter run -d chrome

# Build de producción
./scripts/build_production.bat
```

### Desarrollo en macOS (para iOS)
```bash
# Setup inicial (solo primera vez)
./scripts/setup_ios.sh

# Ejecutar en iPhone conectado
flutter run

# Build para TestFlight
flutter build ipa --release
```

### Cualquier plataforma
```bash
# Limpiar y reinstalar todo
flutter clean
flutter pub get
cd ios && pod install && cd ..  # Solo en Mac

# Ejecutar tests
flutter test

# Analizar código
flutter analyze
```

---

## 📝 Notas

- Los scripts `.bat` funcionan en Windows (PowerShell/CMD)
- Los scripts `.sh` funcionan en macOS y Linux (Bash)
- Asegurar permisos de ejecución en scripts `.sh` con `chmod +x`
