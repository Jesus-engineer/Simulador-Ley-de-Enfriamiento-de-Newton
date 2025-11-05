#!/bin/bash
set -e

# Instalar Flutter desde fuente segura sin dependencias Git activas

wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.4-stable.tar.xz -O flutter_sdk.tar.xz
tar -xf flutter_sdk.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Eliminar la necesidad de comprobar propiedad del repositorio
flutter doctor --verbose || true

# Configurar y compilar Flutter Web
flutter config --enable-web
flutter pub get
flutter build web --release
