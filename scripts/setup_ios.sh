#!/bin/bash

# Script de configuración para macOS
# Chamos Fitness Center - iOS Setup

echo "🏋️ Chamos Fitness Center - iOS Setup Script"
echo "=============================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que estamos en macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ Este script solo funciona en macOS${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Verificando requisitos...${NC}"
echo ""

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter no está instalado${NC}"
    echo "Instalar desde: https://docs.flutter.dev/get-started/install/macos"
    exit 1
else
    echo -e "${GREEN}✅ Flutter instalado${NC}"
    flutter --version | head -1
fi

# Verificar Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode no está instalado${NC}"
    echo "Instalar desde: App Store"
    exit 1
else
    echo -e "${GREEN}✅ Xcode instalado${NC}"
    xcodebuild -version | head -1
fi

# Verificar CocoaPods
if ! command -v pod &> /dev/null; then
    echo -e "${YELLOW}⚠️  CocoaPods no está instalado${NC}"
    echo -e "${YELLOW}Instalando CocoaPods...${NC}"
    sudo gem install cocoapods
    echo -e "${GREEN}✅ CocoaPods instalado${NC}"
else
    echo -e "${GREEN}✅ CocoaPods instalado${NC}"
    pod --version
fi

echo ""
echo -e "${YELLOW}🔧 Configurando proyecto...${NC}"
echo ""

# Limpiar builds previos
echo "1/5 Limpiando builds previos..."
flutter clean

# Obtener dependencias de Flutter
echo "2/5 Obteniendo dependencias de Flutter..."
flutter pub get

# Verificar que existe el archivo .env
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    echo "Creando .env de ejemplo..."
    cat > .env << EOF
SUPABASE_URL=https://xxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxxxxx
EOF
    echo -e "${YELLOW}⚠️  Por favor, edita el archivo .env con tus credenciales de Supabase${NC}"
fi

# Instalar CocoaPods
echo "3/5 Instalando CocoaPods (esto puede tardar varios minutos)..."
cd ios
pod install
cd ..

# Verificar configuración de Xcode
echo "4/5 Verificando configuración de Xcode..."
if xcode-select -p &> /dev/null; then
    echo -e "${GREEN}✅ Xcode Command Line Tools configurados${NC}"
else
    echo -e "${YELLOW}Configurando Xcode Command Line Tools...${NC}"
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    sudo xcodebuild -runFirstLaunch
fi

# Flutter Doctor
echo "5/5 Ejecutando Flutter Doctor..."
echo ""
flutter doctor

echo ""
echo -e "${GREEN}✅ Configuración completada!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}📱 Próximos pasos:${NC}"
echo ""
echo "1. Conecta tu iPhone con cable USB"
echo "2. Desbloquea el iPhone y confía en este Mac"
echo "3. Activa el Modo de Desarrollador en el iPhone:"
echo "   Ajustes → Privacidad → Modo de Desarrollador"
echo ""
echo "4. Ejecuta la app:"
echo -e "   ${GREEN}flutter run${NC}"
echo ""
echo "5. O abre en Xcode:"
echo -e "   ${GREEN}open ios/Runner.xcworkspace${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}📖 Para más información, lee: docs/IOS_SETUP_GUIDE.md${NC}"
echo ""
