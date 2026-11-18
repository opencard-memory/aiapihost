# AI 채팅 콘솔 (Windows, .NET 10)

엔드포인트 주소와 API 키를 입력해 AI와 대화하는 데스크톱 앱입니다.
OpenAI 호환 API(OpenAI, OpenRouter, Groq, DeepSeek, Ollama, LM Studio 등), Anthropic, Google Gemini를 지원합니다.
스트리밍, 이미지·PDF 첨부, 시스템 프롬프트, 도구 호출, 생각 과정 표시, 대화 저장과 내보내기를 쓸 수 있습니다.

## 빌드

필요한 것: [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) (`winget install Microsoft.DotNet.SDK.10`)

```bat
build.bat
```

결과물은 `dist` 폴더에 만들어집니다.

| 파일 | 대상 |
| --- | --- |
| `dist\AIChatConsole-win-x64.exe` | 64비트 Windows |
| `dist\AIChatConsole-win-x86.exe` | 32비트 Windows |

기본 빌드는 .NET 런타임을 포함한 단일 exe라서 .NET이 설치되지 않은 PC에서도 실행됩니다. 크기는 수십 MB입니다.
작은 exe가 필요하면 `build.bat fd`로 빌드하세요. 이 경우 실행하는 PC에 .NET 10 Desktop Runtime이 필요합니다.

SDK를 설치하지 않고 빌드하려면 이 폴더를 GitHub 저장소에 올리세요. `.github/workflows/build.yml`이 두 exe를 만들어 Actions 결과물로 내려줍니다.

수동으로 빌드하려면 다음 명령을 사용합니다.

```bat
dotnet publish src\AIChatConsole\AIChatConsole.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o dist\win-x64
dotnet publish src\AIChatConsole\AIChatConsole.csproj -c Release -r win-x86 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o dist\win-x86
```

## 실행 환경

- Windows 10 이상 (64비트 또는 32비트)
- Microsoft Edge WebView2 런타임. Windows 11과 최신 Windows 10에는 기본으로 들어 있고, 없으면 앱이 설치 페이지를 안내합니다.

## 동작 방식

- WinForms 창 안에서 WebView2가 `Assets/index.html`(앱 화면 전체)을 보여 줍니다. 화면을 고치려면 이 파일을 수정하고 다시 빌드하세요.
- 페이지는 exe에 내장되어 있고, 실행할 때 `%LOCALAPPDATA%\AIChatConsole\web`에 풀립니다.
- 대화 기록과 설정은 `%LOCALAPPDATA%\AIChatConsole\profile`에 저장됩니다. 지우면 초기화됩니다.
- 데스크톱 앱이라 WebView2의 CORS 제한을 꺼 두었습니다. 그래서 Ollama나 사내 서버 같은 엔드포인트에도 별도 프록시 없이 연결됩니다.
  이 창은 내장 페이지만 열고, 외부 링크는 기본 브라우저로 넘깁니다.
- API 키는 설정에서 "이 브라우저에 키 저장"을 켠 경우에만 프로필 폴더에 남습니다.

## 구조

```
build.bat                         x64, x86 두 exe 빌드
src/AIChatConsole/
  AIChatConsole.csproj            net10.0-windows, WinForms, WebView2
  Program.cs                      진입점
  MainForm.cs                     창, WebView2 초기화, 외부 링크 처리
  Assets/index.html               채팅 화면 (exe에 내장)
  app.ico                         앱 아이콘
.github/workflows/build.yml       GitHub Actions 빌드
```
