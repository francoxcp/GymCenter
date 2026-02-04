@echo off
REM Script de optimización y build para producción
REM Chamos Fitness Center

echo ====================================
echo  OPTIMIZACION Y BUILD PRODUCCION
echo  Chamos Fitness Center
echo ====================================
echo.

REM 1. Limpiar build anterior
echo [1/7] Limpiando builds anteriores...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean fallo
    pause
    exit /b 1
)
echo.

REM 2. Obtener dependencias
echo [2/7] Obteniendo dependencias...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get fallo
    pause
    exit /b 1
)
echo.

REM 3. Analizar código
echo [3/7] Analizando código...
call flutter analyze --no-fatal-infos
if %errorlevel% neq 0 (
    echo ADVERTENCIA: Se encontraron issues en el análisis
    pause
)
echo.

REM 4. Ejecutar tests
echo [4/7] Ejecutando tests...
call flutter test
if %errorlevel% neq 0 (
    echo ERROR: Tests fallaron
    pause
    exit /b 1
)
echo.

REM 5. Formatear código
echo [5/7] Formateando código...
call dart format lib/ test/
echo.

REM 6. Verificar archivo .env
echo [6/7] Verificando configuración...
if not exist .env (
    echo ERROR: Archivo .env no encontrado
    echo Copia .env.example a .env y configura las credenciales de producción
    pause
    exit /b 1
)
echo Archivo .env encontrado
echo.

REM 7. Build opciones
echo [7/7] Selecciona tipo de build:
echo.
echo 1. Android APK (Split por ABI)
echo 2. Android App Bundle (Play Store)
echo 3. Solo análisis y tests (sin build)
echo 4. Web Production
echo 5. Salir
echo.
set /p BUILD_TYPE="Ingresa opción (1-5): "

if "%BUILD_TYPE%"=="1" (
    echo.
    echo Compilando APK para Android...
    call flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
    if %errorlevel% neq 0 (
        echo ERROR: Build falló
        pause
        exit /b 1
    )
    echo.
    echo ====================================
    echo BUILD EXITOSO
    echo APKs generados en: build\app\outputs\flutter-apk\
    echo ====================================
    pause
    exit /b 0
)

if "%BUILD_TYPE%"=="2" (
    echo.
    echo Compilando App Bundle para Google Play...
    call flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
    if %errorlevel% neq 0 (
        echo ERROR: Build falló
        pause
        exit /b 1
    )
    echo.
    echo ====================================
    echo BUILD EXITOSO
    echo App Bundle generado en: build\app\outputs\bundle\release\
    echo ====================================
    pause
    exit /b 0
)

if "%BUILD_TYPE%"=="3" (
    echo.
    echo ====================================
    echo ANÁLISIS COMPLETADO
    echo No se generó ningún build
    echo ====================================
    pause
    exit /b 0
)

if "%BUILD_TYPE%"=="4" (
    echo.
    echo Compilando versión Web...
    call flutter build web --release --web-renderer canvaskit
    if %errorlevel% neq 0 (
        echo ERROR: Build falló
        pause
        exit /b 1
    )
    echo.
    echo ====================================
    echo BUILD EXITOSO
    echo Archivos web en: build\web\
    echo ====================================
    pause
    exit /b 0
)

if "%BUILD_TYPE%"=="5" (
    exit /b 0
)

echo Opción inválida
pause
exit /b 1
