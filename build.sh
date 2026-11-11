#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$DIR/build"
SAVER_DIR="$BUILD_DIR/Fireworks.saver"
TEMP_DIR="$BUILD_DIR/temp"

echo "==> Limpando builds anteriores..."
rm -rf "$BUILD_DIR"
mkdir -p "$SAVER_DIR/Contents/MacOS"
mkdir -p "$TEMP_DIR"

echo "==> Compilando Universal Binary (arm64 + x86_64)..."
swiftc -target x86_64-apple-macosx14.0 -emit-library "$DIR/FireworksView.swift" \
  -framework ScreenSaver -framework AppKit \
  -O -o "$TEMP_DIR/Fireworks_x86_64"

swiftc -target arm64-apple-macosx14.0 -emit-library "$DIR/FireworksView.swift" \
  -framework ScreenSaver -framework AppKit \
  -O -o "$TEMP_DIR/Fireworks_arm64"

lipo -create "$TEMP_DIR/Fireworks_x86_64" "$TEMP_DIR/Fireworks_arm64" \
  -output "$SAVER_DIR/Contents/MacOS/Fireworks"

rm -rf "$TEMP_DIR"

echo "==> Gerando Info.plist..."
cat << 'PLIST' > "$SAVER_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Fireworks</string>
    <key>CFBundleIdentifier</key>
    <string>com.tissot.fireworks</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Fireworks</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string>FireworksView</string>
</dict>
</plist>
PLIST

echo "==> Assinando bundle..."
codesign -s - --force "$SAVER_DIR"

echo "==> Instalando em ~/Library/Screen Savers/..."
mkdir -p ~/Library/Screen\ Savers/
rm -rf ~/Library/Screen\ Savers/Fireworks.saver
cp -R "$SAVER_DIR" ~/Library/Screen\ Savers/

# Reiniciar processo do protetor de tela do macOS para recarregar alterações
killall legacyScreenSaver 2>/dev/null || true

echo "==> Gerando pacote de distribuição (ZIP)..."
(cd "$BUILD_DIR" && zip -q -r "Fireworks-macOS.zip" "Fireworks.saver")

echo ""
echo "✅ Sucesso!"
echo "   - Protetor instalado: ~/Library/Screen Savers/Fireworks.saver"
echo "   - Pacote para distribuição: $BUILD_DIR/Fireworks-macOS.zip"
