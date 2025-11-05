#!/bin/bash
# Script para configurar y construir Flutter Web en Vercel

set -e  # Detenerse si ocurre un error

# 🔧 Arregla el problema de permisos "dubious ownership"
git config --global --add safe.directory /vercel/path0/flutter

# 📦 Descargar Flutter SDK (versión estable compatible)
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.4-stable.tar.xz
tar xf flutter_linux_3.24.4-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# 🚀 Activar web y construir
flutter config --enable-web
flutter build web --release
