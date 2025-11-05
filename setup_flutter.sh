#!/bin/bash
# Instalar Flutter y compilar la app para web

curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.4-stable.tar.xz
tar xf flutter_linux_3.24.4-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# 🔧 Solución al error de "dubious ownership"
git config --global --add safe.directory /vercel/path0/flutter

flutter config --enable-web
flutter build web --release
