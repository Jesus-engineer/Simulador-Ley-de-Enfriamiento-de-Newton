#!/bin/bash
set -e  # Detiene la ejecución si hay errores

git config --global --add safe.directory /vercel/path0/flutter

# Descargar e instalar Flutter
echo "⬇️ Descargando Flutter..."
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.4-stable.tar.xz
tar xf flutter_linux_3.24.4-stable.tar.xz

export PATH="$PATH:`pwd`/flutter/bin"

# 🧩 Solución: marca el directorio de Flutter como seguro
git config --global --add safe.directory $(pwd)/flutter

# Verificar instalación
flutter --version

# Habilitar web y compilar
flutter config --enable-web
flutter build web --release
