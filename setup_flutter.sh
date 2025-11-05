#!/bin/bash
# Instalar Flutter y compilar la app para web

set -e  # Hace que el script se detenga si hay cualquier error

# Descargar Flutter (versión estable compatible con fl_chart 1.1.1)
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.4-stable.tar.xz
tar xf flutter_linux_3.24.4-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Solución al error de "dubious ownership"
git config --global --add safe.directory /vercel/path0/flutter

flutter config --enable-web
flutter build web --release
