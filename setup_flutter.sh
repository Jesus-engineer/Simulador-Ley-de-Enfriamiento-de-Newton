#!/bin/bash
# Instalar Flutter SDK temporalmente en Vercel
echo "🚀 Instalando Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar instalación
flutter --version

# Descargar dependencias
echo "📦 Instalando dependencias..."
flutter pub get
