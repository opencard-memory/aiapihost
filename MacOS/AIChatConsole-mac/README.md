# AI 채팅 콘솔 — macOS Self-contained 빌드

Avalonia 기반 AI 채팅 데스크톱 앱입니다. Apple Silicon과 Intel Mac용으로 각각 독립 실행 가능한 `.app` 번들을 생성합니다.

## Self-contained 버전이란?

`build.sh` 또는 `build-self-contained.sh`를 실행하면 .NET 런타임을 앱에 포함해 게시합니다. 따라서 **완성된 앱을 실행하는 Mac에는 별도의 .NET Runtime 설치가 필요하지 않습니다.**

macOS의 WebKit/WKWebView는 운영체제에서 제공하는 시스템 구성 요소이므로 앱에 중복 포함하지 않습니다.

## 빌드 요구사항

- macOS 빌드 머신
- .NET 10 SDK
- NuGet 패키지 복원을 위한 인터넷 연결(최초 빌드 시)

## 빌드 방법

프로젝트 폴더에서 실행하세요.

```bash
chmod +x build.sh
./build.sh
```

또는 직접 실행할 수 있습니다.

```bash
./build-self-contained.sh
```

스크립트는 아래 두 RID를 차례대로 게시합니다.

| 대상 Mac | Runtime Identifier |
| --- | --- |
| Apple Silicon (M1/M2/M3/M4 등) | `osx-arm64` |
| Intel Mac | `osx-x64` |

## 생성 결과

빌드가 성공하면 `dist-self-contained` 아래에 다음 파일이 생성됩니다.

```text
dist-self-contained/
├── osx-arm64/
│   └── AIChatConsole.app/
├── osx-x64/
│   └── AIChatConsole.app/
├── AIChatConsole-osx-arm64-self-contained.zip
└── AIChatConsole-osx-x64-self-contained.zip
```

각 ZIP에는 해당 아키텍처의 `.app` 번들이 들어 있습니다. 대상 Mac에 맞는 ZIP을 전달하고 압축을 푼 다음 `AIChatConsole.app`을 실행하면 됩니다.

## 최초 실행 안내

앱은 현재 자동 서명되지 않은 상태로 생성됩니다. macOS Gatekeeper가 실행을 차단하면 Finder에서 앱을 마우스 오른쪽 버튼으로 클릭하고 **열기(Open)** 를 선택해 실행을 승인하세요. 신뢰할 수 있는 본인이 직접 빌드한 앱에만 적용하세요.

## 중요: 기존 `dist-fd` 실행 파일

압축파일에 원래 포함되어 있던 `dist-fd/osx-arm64` 및 `dist-fd/osx-x64`는 **Framework-dependent 빌드**입니다. 이 파일들은 별도의 .NET 10 Runtime 설치가 필요하므로 self-contained 버전이 아닙니다. Self-contained 결과물은 위 빌드 스크립트가 생성하는 `dist-self-contained` 폴더의 파일을 사용하세요.

## 프로젝트 구조

```text
AIChatConsole.csproj          .NET 10 + Avalonia 프로젝트
MainWindow.axaml(.cs)         NativeWebView 호스트
Assets/index.html             채팅 UI
Program.cs / App.axaml        Avalonia 앱 진입점
build.sh                      Self-contained 빌드 진입점
build-self-contained.sh       두 macOS 아키텍처 게시 및 .app/ZIP 생성
```

## 참고

- 앱 실행 시 채팅 페이지를 `Assets/index.html` 내장 리소스에서 앱 데이터 폴더로 추출합니다.
- 대화 기록과 설정은 앱 데이터의 `profile` 폴더에 저장됩니다.
- macOS에서는 시스템 WKWebView를 사용합니다. 일부 로컬 API(Ollama 등)는 WKWebView의 CORS 정책에 영향을 받을 수 있습니다.
