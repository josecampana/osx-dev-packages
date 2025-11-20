#!/bin/bash

set -e

TMP=$(mktemp -d)
cd "$TMP"

echo "Descargando herramientas de instalación..."
curl -L https://github.com/tuusuario/osx-dev-packages/archive/refs/heads/main.zip -o repo.zip

unzip repo.zip >/dev/null
cd osx-dev-packages-main

chmod +x install.sh
./install.sh