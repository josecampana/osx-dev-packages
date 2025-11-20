#!/bin/bash
set -e

TMP=$(mktemp -d)
cd "$TMP"

echo "downloading osx-dev-packages installation tool"

curl -L \
  https://github.com/josecampana/osx-dev-packages/archive/refs/heads/main.zip \
  -o repo.zip

echo "unzipping..."
unzip -q repo.zip

cd osx-dev-packages-main

chmod +x install.sh
./install.sh
