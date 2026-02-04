# 🏋️ Chamos Fitness Center

App móvil completa para gestión de gimnasio con autenticación, rutinas personalizadas, planes de alimentación, seguimiento de progreso y más.

## 📱 Características

- ✅ **Autenticación completa** con Supabase (Login, Registro, Recuperación)
- ✅ **Onboarding personalizado** para nuevos usuarios
- ✅ **Rutinas de entrenamiento** con videos y seguimiento
- ✅ **Planes de alimentación** categorizados
- ✅ **Seguimiento de progreso** con gráficas (peso, medidas corporales)
- ✅ **Sistema de logros** para motivación
- ✅ **Notificaciones locales** (recordatorios, logros)
- ✅ **Panel de administración** para entrenadores
- ✅ **Subida de fotos** de perfil y progreso
- ✅ **Subida de videos** de ejercicios (solo admins)
- ✅ **Sistema de seguridad** (cambio de contraseña, eliminación de cuenta)

## 🛠️ Tecnologías

- **Frontend:** Flutter 3.27.0 / Dart 3.5.4
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **State Management:** Provider
- **Navigation:** GoRouter
- **Charts:** fl_chart
- **Notifications:** flutter_local_notifications
- **Image Processing:** flutter_image_compress

## 🚀 Configuración Rápida

### Windows

```powershell
# Clonar proyecto
git clone https://github.com/TU_USUARIO/chamos-fitness-center.git
cd chamos-fitness-center

# Instalar dependencias
./scripts/install_dependencies.bat

# Ejecutar en Chrome
flutter run -d chrome
```

### macOS (Para desarrollo iOS)

```bash
# Clonar proyecto
git clone https://github.com/TU_USUARIO/chamos-fitness-center.git
cd chamos-fitness-center

# Setup automático
chmod +x scripts/setup_ios.sh
./scripts/setup_ios.sh

# Conectar iPhone y ejecutar
flutter run
```

## 📖 Documentación

### Guías de Instalación
- [📱 iOS Setup Guide](docs/IOS_SETUP_GUIDE.md) - Configuración completa para MacBook e iPhone
- [🔄 Transferir a Mac](TRANSFER_TO_MAC.md) - Cómo mover el proyecto a MacBook

### Documentación de Desarrollo
- [📋 Checklist de Producción](docs/PRODUCCION_CHECKLIST.md) - Todo lo necesario antes de publicar
- [🗄️ Base de Datos](database/README.md) - Scripts SQL y orden de ejecución
- [🔧 Scripts](scripts/README.md) - Utilidades de desarrollo

## 🔧 Configuración de Supabase

### 1. Crear archivo `.env` en la raíz

```bash
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

### 2. Ejecutar scripts SQL

En **Supabase Dashboard → SQL Editor**, ejecutar en orden:

1. `database/supabase_schema.sql` - Tablas, índices, triggers
2. `database/supabase_rls_policies.sql` - Políticas de seguridad
3. `database/storage_policies.sql` - Buckets y permisos de Storage
4. `database/delete_account_function.sql` - Función de eliminación

Ver [database/README.md](database/README.md) para más detalles.

## 📦 Estructura del Proyecto

```
chamos_fitness_center/
├── lib/
│   ├── main.dart                  # Punto de entrada
│   ├── config/                    # Configuración (router, theme, Supabase)
│   ├── models/                    # Modelos de datos
│   ├── providers/                 # State management (7 providers)
│   ├── screens/                   # Pantallas de la app
│   │   ├── auth/                  # Login, registro, recuperación
│   │   ├── home/                  # Dashboard principal
│   │   ├── workouts/              # Rutinas y ejercicios
│   │   ├── meal_plans/            # Planes de alimentación
│   │   ├── progress/              # Gráficas y seguimiento
│   │   ├── profile/               # Perfil y edición
│   │   ├── settings/              # Configuración
│   │   └── admin/                 # Panel de administración
│   ├── services/                  # Servicios (Storage, Notificaciones, Seguridad)
│   └── widgets/                   # Componentes reutilizables
├── ios/                           # Configuración iOS ⭐
├── android/                       # Configuración Android
├── assets/                        # Imágenes e íconos
├── database/                      # Scripts SQL de Supabase
├── docs/                          # Documentación
└── scripts/                       # Scripts de utilidad
```

## 🧪 Testing

```bash
# Ejecutar tests
flutter test

# Análisis de código
flutter analyze

# Debe mostrar: "No issues found!"
```

## 📱 Build de Producción

### Android

```bash
# APK
flutter build apk --release

# App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

### iOS

```bash
# IPA para TestFlight/App Store
flutter build ipa --release
```

## 🔐 Seguridad

- ✅ **Row Level Security (RLS)** habilitado en todas las tablas
- ✅ **Autenticación PKCE** con Supabase
- ✅ **Validación de permisos** a nivel de base de datos
- ✅ **Storage policies** para imágenes y videos
- ✅ **Compresión de imágenes** antes de subir
- ✅ **Hashing de archivos** para evitar duplicados

## 📊 Estado del Proyecto

- ✅ **100% funcional** - Todas las features implementadas
- ✅ **0 errores** de compilación (`flutter analyze`)
- ✅ **Tests pasando** (`flutter test`)
- ✅ **Documentación completa**
- ✅ **Listo para iOS** - Configuración completa
- ⏳ **Pendiente:** Pruebas en dispositivo físico iPhone
- ⏳ **Pendiente:** Publicación en tiendas

## 🎯 Próximos Pasos

1. **Probar en iPhone** - Ver [docs/IOS_SETUP_GUIDE.md](docs/IOS_SETUP_GUIDE.md)
2. **Ajustar UI** según pruebas en dispositivo real
3. **Crear assets** para tiendas (screenshots, iconos, videos)
4. **Configurar Firebase** para analytics (opcional)
5. **Setup CI/CD** con GitHub Actions
6. **Beta testing** con TestFlight / Google Play Internal Testing
7. **Publicación** en App Store y Play Store

## 📞 Soporte

Para problemas o preguntas:

1. Revisar la documentación en `/docs`
2. Ejecutar `flutter doctor -v` para diagnóstico
3. Revisar logs con `flutter logs`

## 📝 Licencia

Proyecto privado - Chamos Fitness Center © 2026

---

**Desarrollado con ❤️ usando Flutter + Supabase**
