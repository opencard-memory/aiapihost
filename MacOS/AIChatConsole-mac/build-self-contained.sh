#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT_DIR/AIChatConsole.csproj"
OUTPUT_ROOT="$ROOT_DIR/dist-self-contained"

if ! command -v dotnet >/dev/null 2>&1; then
  echo "[ERROR] .NET 10 SDK is required. Install it from https://dotnet.microsoft.com/download/dotnet/10.0" >&2
  exit 1
fi

SDK_VERSION="$(dotnet --version)"
SDK_MAJOR="${SDK_VERSION%%.*}"
if [[ "$SDK_MAJOR" != "10" ]]; then
  echo "[ERROR] .NET 10 SDK is required; the selected SDK is $SDK_VERSION." >&2
  echo "        Install .NET 10 SDK or select it with a global.json file." >&2
  exit 1
fi

if [[ ! -f "$PROJECT" ]]; then
  echo "[ERROR] Project file not found: $PROJECT" >&2
  exit 1
fi

rm -rf "$OUTPUT_ROOT"
mkdir -p "$OUTPUT_ROOT"

for RID in osx-arm64 osx-x64; do
  echo
  echo "=== Publishing self-contained macOS build: $RID ==="

  PUBLISH_DIR="$OUTPUT_ROOT/.publish/$RID"
  APP_DIR="$OUTPUT_ROOT/$RID/AIChatConsole.app"
  MACOS_DIR="$APP_DIR/Contents/MacOS"
  RESOURCES_DIR="$APP_DIR/Contents/Resources"
  ZIP_PATH="$OUTPUT_ROOT/AIChatConsole-$RID-self-contained.zip"

  mkdir -p "$PUBLISH_DIR" "$MACOS_DIR" "$RESOURCES_DIR"

  dotnet publish "$PROJECT" \
    --configuration Release \
    --runtime "$RID" \
    --self-contained true \
    --output "$PUBLISH_DIR" \
    -p:SelfContained=true \
    -p:UseAppHost=true \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true \
    -p:EnableCompressionInSingleFile=true \
    -p:DebugType=none \
    -p:DebugSymbols=false

  if [[ ! -s "$PUBLISH_DIR/AIChatConsole" ]]; then
    echo "[ERROR] Publish did not produce AIChatConsole for $RID." >&2
    exit 1
  fi

  # Keep every publish output beside the app host. Some Avalonia native assets
  # are emitted as separate dylib files and must remain next to the executable.
  cp -R "$PUBLISH_DIR/." "$MACOS_DIR/"
  chmod +x "$MACOS_DIR/AIChatConsole"

  cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>AIChatConsole</string>
  <key>CFBundleIdentifier</key>
  <string>com.opencard.aichatconsole</string>
  <key>CFBundleName</key>
  <string>AIChatConsole</string>
  <key>CFBundleDisplayName</key>
  <string>AI Chat Console</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

  cat > "$RESOURCES_DIR/BUILD-INFO.txt" <<INFO
AI Chat Console — self-contained macOS build
Runtime identifier: $RID
.NET SDK used: $SDK_VERSION
The .NET runtime is included in this application bundle.
The macOS system WebKit/WKWebView framework is provided by macOS itself.
This build is unsigned; macOS may ask you to approve the first launch.
INFO

  if command -v plutil >/dev/null 2>&1; then
    plutil -lint "$APP_DIR/Contents/Info.plist"
  fi

  # ditto preserves macOS bundle metadata and executable permissions.
  ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

  echo "Created: $APP_DIR"
  echo "Created: $ZIP_PATH"
done

rm -rf "$OUTPUT_ROOT/.publish"
echo
echo "Self-contained builds completed. No separately installed .NET runtime is required on target Macs."
