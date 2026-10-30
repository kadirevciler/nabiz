#!/bin/zsh
# Nabız.app paketini derler: ./scripts/build_app.sh
set -e
cd "$(dirname "$0")/.."
swift build -c release
APP="build/Nabız.app"
rm -rf "$APP" build/AppIcon.iconset
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Nabiz "$APP/Contents/MacOS/Nabiz"
cp Resources/Info.plist "$APP/Contents/Info.plist"
swift scripts/make_icon.swift build/AppIcon.iconset
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP"
echo "Hazır: $APP"
