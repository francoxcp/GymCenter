@echo off
REM ============================================================
REM  Script de desarrollo - Ejecuta la app con credenciales
REM ============================================================
REM  Carga las credenciales de local_credentials.bat y ejecuta
REM  flutter run con los --dart-define apropiados.
REM ============================================================

cd /d "%~dp0.."

REM Cargar credenciales
if not exist "scripts\local_credentials.bat" (
    echo.
    echo ERROR: No se encontro scripts\local_credentials.bat
    echo Copia scripts\local_credentials.bat.example a scripts\local_credentials.bat
    echo y rellena tus credenciales de Supabase.
    echo.
    exit /b 1
)

call scripts\local_credentials.bat

REM Validar que las credenciales no esten vacias
if "%SUPABASE_URL%"=="" (
    echo ERROR: SUPABASE_URL esta vacio en local_credentials.bat
    exit /b 1
)
if "%SUPABASE_ANON_KEY%"=="" (
    echo ERROR: SUPABASE_ANON_KEY esta vacio en local_credentials.bat
    exit /b 1
)

echo Ejecutando con Supabase URL: %SUPABASE_URL%
echo.

flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% %*
