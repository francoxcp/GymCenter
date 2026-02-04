@echo off
echo ============================================
echo Chamos Fitness Center - Setup
echo ============================================
echo.

echo [1/4] Instalando dependencias de Flutter...
call flutter pub get
if errorlevel 1 (
    echo Error al instalar dependencias
    pause
    exit /b 1
)

echo.
echo [2/4] Verificando archivo .env...
if not exist .env (
    echo WARNING: No se encontro el archivo .env
    echo Copiando .env.example a .env...
    copy .env.example .env
    echo IMPORTANTE: Edita el archivo .env con tus credenciales de Supabase
    pause
)

echo.
echo [3/4] Verificando codigo...
call flutter analyze
if errorlevel 1 (
    echo Advertencia: Se encontraron problemas en el codigo
)

echo.
echo [4/4] Formateando codigo...
call dart format lib/

echo.
echo ============================================
echo Setup completado!
echo ============================================
echo.
echo Proximos pasos:
echo 1. Edita .env con tus credenciales de Supabase
echo 2. Ejecuta los scripts SQL en Supabase (database/)
echo 3. Ejecuta: flutter run
echo.
pause
