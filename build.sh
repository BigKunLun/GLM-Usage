#!/bin/bash

# GLM Usage 打包脚本

set -e

echo "🔨 编译 Release 版本..."
swift build -c release

echo "📦 创建 APP 包结构..."
rm -rf GLM_Usage.app
mkdir -p GLM_Usage.app/Contents/MacOS
mkdir -p GLM_Usage.app/Contents/Resources

echo "📋 复制可执行文件..."
cp .build/release/GLM_Usage GLM_Usage.app/Contents/MacOS/
chmod +x GLM_Usage.app/Contents/MacOS/GLM_Usage

echo "📝 创建 Info.plist..."
cat > GLM_Usage.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>GLM_Usage</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.glm.usage</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GLM Usage</string>
    <key>CFBundleDisplayName</key>
    <string>GLM Usage</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "🎨 转换应用图标..."
if [ -f "GLM.png" ]; then
    mkdir -p GLM_Usage.iconset
    sips -z 16 16 GLM.png --out GLM_Usage.iconset/icon_16x16.png >/dev/null 2>&1
    sips -z 32 32 GLM.png --out GLM_Usage.iconset/icon_16x16@2x.png >/dev/null 2>&1
    sips -z 32 32 GLM.png --out GLM_Usage.iconset/icon_32x32.png >/dev/null 2>&1
    sips -z 64 64 GLM.png --out GLM_Usage.iconset/icon_32x32@2x.png >/dev/null 2>&1
    sips -z 128 128 GLM.png --out GLM_Usage.iconset/icon_128x128.png >/dev/null 2>&1
    sips -z 256 256 GLM.png --out GLM_Usage.iconset/icon_128x128@2x.png >/dev/null 2>&1
    sips -z 256 256 GLM.png --out GLM_Usage.iconset/icon_256x256.png >/dev/null 2>&1
    sips -z 512 512 GLM.png --out GLM_Usage.iconset/icon_256x256@2x.png >/dev/null 2>&1
    sips -z 512 512 GLM.png --out GLM_Usage.iconset/icon_512x512.png >/dev/null 2>&1
    sips -z 1024 1024 GLM.png --out GLM_Usage.iconset/icon_512x512@2x.png >/dev/null 2>&1
    iconutil -c icns GLM_Usage.iconset -o GLM_Usage.app/Contents/Resources/AppIcon.icns
    rm -rf GLM_Usage.iconset
fi

echo "📦 创建 ZIP 包..."
rm -f GLM_Usage.zip
zip -r GLM_Usage.zip GLM_Usage.app -x "*.DS_Store"

echo "✅ 打包完成！"
echo "   APP: GLM_Usage.app"
echo "   ZIP: GLM_Usage.zip"
