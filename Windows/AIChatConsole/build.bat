@echo off
setlocal
cd /d "%~dp0"

rem Usage:
rem   build.bat      self-contained single-file exe (no .NET install needed to run)
rem   build.bat fd   framework-dependent exe (small, needs .NET 10 Desktop Runtime)

where dotnet >nul 2>nul
if errorlevel 1 (
  echo [ERROR] .NET 10 SDK was not found.
  echo         Install it with: winget install Microsoft.DotNet.SDK.10
  exit /b 1
)

set SC=true
if /I "%~1"=="fd" set SC=false

if exist dist rmdir /s /q dist

for %%R in (win-x64 win-x86) do (
  echo.
  echo === Building %%R ===
  dotnet publish src\AIChatConsole\AIChatConsole.csproj -c Release -r %%R --self-contained %SC% -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:EnableCompressionInSingleFile=%SC% -p:DebugType=none -o dist\%%R
  if errorlevel 1 (
    echo [ERROR] Build failed for %%R
    exit /b 1
  )
  copy /Y dist\%%R\AIChatConsole.exe dist\AIChatConsole-%%R.exe >nul
)

echo.
echo Done. Output:
echo   dist\AIChatConsole-win-x64.exe   (64-bit)
echo   dist\AIChatConsole-win-x86.exe   (32-bit)
endlocal
