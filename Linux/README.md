# AIChatConsole for Linux

Linux desktop packaging and GitHub Actions build configuration for AIChatConsole.

## Supported architectures

- x86-64: `linux-x64`
- ARM64: `linux-arm64`

## Package formats

- Ubuntu / Debian: `.deb`
- Fedora / RHEL-compatible: `.rpm`
- Arch Linux: `.pkg.tar.zst`
- Generic Linux: self-contained `.tar.gz`

The Avalonia application project is shared with the macOS implementation at
`../MacOS/AIChatConsole-mac/AIChatConsole.csproj`; Linux-specific packaging
scripts and CI configuration live in this directory.

## Build locally

Requirements: .NET 10 SDK, Go, and nfpm.

```bash
go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest
chmod +x build-linux.sh
./build-linux.sh linux-x64 amd64
./build-linux.sh linux-arm64 arm64
```

## Native dependencies

The .NET runtime is bundled, but GTK and WebKit native libraries remain
operating-system dependencies.

- Ubuntu/Debian: GTK 3, WebKitGTK 4.1, libsoup 3
- Fedora/RHEL: GTK 3, WebKitGTK 4.1, libsoup 3 (package availability varies by release)
- Arch: GTK 3, WebKitGTK 4.1, libsoup 3

GUI launch tests on each target distribution and architecture are still required
before describing every combination as fully supported.
