#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/PinyinKitchen.swiftpm"
PKG_FILE="$PKG_DIR/Package.swift"
PKG_BAK="$PKG_DIR/.Package.swift.ipad.bak"
APP_NAME="满满的奇妙料理城"
APP_BUNDLE="$SCRIPT_DIR/${APP_NAME}.app"
OLD_APP_BUNDLE="$SCRIPT_DIR/拼音小厨房.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 保持仓库内 Package.swift 为 iPad Swift Playgrounds 专用格式 (.iOSApplication)
# 在 Mac 命令行编译时临时切换为标准 SwiftPM executable 清单，编译完立即自动还原
cp "$PKG_FILE" "$PKG_BAK"
restore_pkg() {
    if [ -f "$PKG_BAK" ]; then
        mv "$PKG_BAK" "$PKG_FILE"
    fi
}
trap restore_pkg EXIT

cat > "$PKG_FILE" << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PinyinKitchen",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(name: "PinyinKitchen", targets: ["PinyinKitchen"])
    ],
    targets: [
        .executableTarget(
            name: "PinyinKitchen",
            path: "Sources"
        )
    ]
)
EOF

echo "🍲 正在编译 SwiftUI 原生应用《${APP_NAME}》v5.0（沪教一年级语数英冒险屋）..."
cd "$PKG_DIR"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/PinyinKitchen"
if [ ! -f "$BIN_PATH" ]; then
    echo "❌ 未找到编译产物: $BIN_PATH"
    exit 1
fi

echo "📦 正在封装 macOS 原生应用包: ${APP_BUNDLE}..."
rm -rf "$APP_BUNDLE" "$OLD_APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/PinyinKitchen"
chmod +x "$MACOS_DIR/PinyinKitchen"

cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>满满的奇妙料理城</string>
    <key>CFBundleExecutable</key>
    <string>PinyinKitchen</string>
    <key>CFBundleIdentifier</key>
    <string>com.songxc1995.pinyinkitchen</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>满满的奇妙料理城</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>5.0</string>
    <key>CFBundleVersion</key>
    <string>500</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc 签名以允许在本地 macOS 直接双击运行
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "✅ 打包完成！双击即可运行: $APP_BUNDLE"
