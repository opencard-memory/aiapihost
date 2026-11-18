#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
ROOT_DIR="$PWD"
PROJECT="$ROOT_DIR/AIChatConsole.csproj"
DIST="$ROOT_DIR/dist-linux"
RID="$1"
GOARCH="$2"
VERSION="${VERSION:-1.0.0}"

case "$RID:$GOARCH" in
  linux-x64:amd64|linux-arm64:arm64) ;;
  *) echo "[ERROR] Unsupported RID/architecture: $RID / $GOARCH" >&2; exit 2 ;;
esac
command -v dotnet >/dev/null 2>&1 || { echo "[ERROR] .NET SDK 10 is required." >&2; exit 1; }
command -v nfpm >/dev/null 2>&1 || { echo "[ERROR] Install nfpm first." >&2; exit 1; }
SDK_MAJOR="$(dotnet --version | cut -d. -f1)"
test "$SDK_MAJOR" = "10" || { echo "[ERROR] .NET 10 SDK required." >&2; exit 1; }

rm -rf "$DIST"
mkdir -p "$DIST/publish" "$DIST/staging/usr/lib/aichatconsole" "$DIST/staging/usr/bin" "$DIST/staging/usr/share/applications"

dotnet publish "$PROJECT" --configuration Release --runtime "$RID" --self-contained true --output "$DIST/publish" -p:SelfContained=true -p:UseAppHost=true -p:PublishSingleFile=false -p:DebugType=none -p:DebugSymbols=false
test -s "$DIST/publish/AIChatConsole"
cp -a "$DIST/publish/." "$DIST/staging/usr/lib/aichatconsole/"
chmod +x "$DIST/staging/usr/lib/aichatconsole/AIChatConsole"

cat > "$DIST/staging/usr/bin/aichatconsole" <<'LAUNCHER'
#!/usr/bin/env sh
exec /usr/lib/aichatconsole/AIChatConsole "$@"
LAUNCHER
chmod 0755 "$DIST/staging/usr/bin/aichatconsole"

cat > "$DIST/staging/usr/share/applications/aichatconsole.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=AIChatConsole
Comment=AI Chat Console
Exec=aichatconsole
Terminal=false
Categories=Utility;Network;
StartupNotify=true
DESKTOP
chmod 0644 "$DIST/staging/usr/share/applications/aichatconsole.desktop"

export GOARCH VERSION
cat > "$DIST/nfpm.yaml" <<'NFPM'
name: aichatconsole
arch: ${GOARCH}
platform: linux
version: ${VERSION}
section: utils
priority: optional
maintainer: OpenCard Memory
description: AIChatConsole desktop application built with Avalonia and .NET 10.
homepage: https://github.com/opencard-memory/aiapihost
contents:
  - src: dist-linux/staging/usr/lib/aichatconsole/
    dst: /usr/lib/aichatconsole
    type: tree
  - src: dist-linux/staging/usr/bin/aichatconsole
    dst: /usr/bin/aichatconsole
    file_info:
      mode: 0755
  - src: dist-linux/staging/usr/share/applications/aichatconsole.desktop
    dst: /usr/share/applications/aichatconsole.desktop
    file_info:
      mode: 0644
overrides:
  deb:
    depends: [libgtk-3-0t64, libwebkit2gtk-4.1-0, libsoup-3.0-0, libx11-6, libice6, libsm6, libfontconfig1]
  rpm:
    depends: [gtk3, webkit2gtk4.1, libsoup3, libX11, libICE, libSM, fontconfig]
  archlinux:
    depends: [gtk3, webkit2gtk-4.1, libsoup3, libx11, libice, libsm, fontconfig]
NFPM

mkdir -p "$DIST/packages"
for FORMAT in deb rpm archlinux; do
  nfpm package --config "$DIST/nfpm.yaml" --packager "$FORMAT" --target "$DIST/packages/"
done
tar -C "$DIST/staging" -czf "$DIST/packages/AIChatConsole-$RID-self-contained.tar.gz" .
find "$DIST/packages" -maxdepth 1 -type f -printf '%f %s bytes\n' | sort
