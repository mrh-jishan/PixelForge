#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "🔨 Compiling PixelForge (Release with LLVM -O optimizations)..."
swift build -c release

APP_NAME="PixelForge.app"
APP_DIR="$DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Packaging $APP_NAME..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp .build/release/PixelForge "$MACOS_DIR/PixelForge"
chmod +x "$MACOS_DIR/PixelForge"

# Copy Icon
if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Write Info.plist
cat << 'PLIST' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>PixelForge</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.pixelforge.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>PixelForge</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# Sign bundle ad-hoc
codesign --force --deep --sign - "$APP_DIR"
echo "✨ Successfully built $APP_DIR"

# Optional packaging for distribution (DMG and ZIP)
if [ "$1" == "--package" ] || [ "$1" == "-p" ]; then
    echo "💿 Creating DMG installer..."
    DMG_NAME="PixelForge-macOS.dmg"
    ZIP_NAME="PixelForge-macOS.zip"
    STAGING_DIR="$DIR/dmg_staging"
    
    rm -rf "$STAGING_DIR" "$DIR/$DMG_NAME" "$DIR/$ZIP_NAME"
    mkdir -p "$STAGING_DIR"
    cp -R "$APP_DIR" "$STAGING_DIR/"
    ln -s /Applications "$STAGING_DIR/Applications"
    
    hdiutil create -volname "PixelForge" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DIR/$DMG_NAME"
    rm -rf "$STAGING_DIR"
    
    echo "🗜️ Creating ZIP archive..."
    ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$DIR/$ZIP_NAME"
    
    echo "📋 Generating SHA256 checksums..."
    shasum -a 256 "$DMG_NAME" "$ZIP_NAME" > "$DIR/checksums.txt"
    cat "$DIR/checksums.txt"
    echo "🎉 Distribution packages created: $DMG_NAME and $ZIP_NAME"
fi
