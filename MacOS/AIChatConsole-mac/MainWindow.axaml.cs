using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;
using Avalonia.Controls;

namespace AIChatConsole;

/// <summary>
/// NativeWebView 안에 내장된 채팅 페이지(Assets/index.html)를 띄우는 메인 창.
/// 페이지는 앱 데이터 폴더에 풀린 뒤 로드된다.
/// </summary>
public partial class MainWindow : Window
{
    private const string AppTitle = "AI 채팅 콘솔";
    private const string HostName = "aichat.app";

    public MainWindow()
    {
        InitializeComponent();
        Title = AppTitle;
        Opened += async (_, _) => await InitializeWebAsync();
    }

    private async Task InitializeWebAsync()
    {
        try
        {
            string dataDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "AIChatConsole");
            string webDir = Path.Combine(dataDir, "web");
            string profileDir = Path.Combine(dataDir, "profile");
            Directory.CreateDirectory(webDir);
            Directory.CreateDirectory(profileDir);

            ExtractPage(Path.Combine(webDir, "index.html"));

            // EnvironmentRequested로 플랫폼별 설정 (Windows에서 CORS 해제 등)
            WebView.EnvironmentRequested += (sender, args) =>
            {
                // Windows WebView2: CORS 제한 해제
                if (args.GetType().Name.Contains("Windows") || args.GetType().Name.Contains("WebView2"))
                {
                    var prop = args.GetType().GetProperty("AdditionalBrowserArguments");
                    if (prop != null)
                    {
                        prop.SetValue(args, "--disable-web-security --allow-running-insecure-content");
                    }
                    var userDataProp = args.GetType().GetProperty("UserDataFolder");
                    if (userDataProp != null)
                    {
                        userDataProp.SetValue(args, profileDir);
                    }
                }
            };

            // 가상 호스트 매핑 시도 (가능한 경우)
            try
            {
                var setMapping = WebView.GetType().GetMethod("SetVirtualHostNameToFolderMapping",
                    BindingFlags.Public | BindingFlags.Instance);
                if (setMapping != null)
                {
                    setMapping.Invoke(WebView, new object[] { HostName, webDir, 1 });
                    WebView.Source = new Uri($"https://{HostName}/index.html");
                    return;
                }
            }
            catch
            {
                // fallback
            }

            // Fallback: file:// 로 로드
            string indexPath = Path.Combine(webDir, "index.html");
            WebView.Source = new Uri(new Uri("file://"), indexPath);
        }
        catch (Exception ex)
        {
            Content = new TextBlock
            {
                Text = "앱을 시작하지 못했습니다.\n\n" + ex.Message,
                TextWrapping = Avalonia.Media.TextWrapping.Wrap,
                Margin = new Avalonia.Thickness(20)
            };
        }
    }

    private static void ExtractPage(string path)
    {
        Assembly asm = Assembly.GetExecutingAssembly();
        using Stream? src = asm.GetManifestResourceStream("Assets.index.html")
                         ?? asm.GetManifestResourceStream("index.html")
                         ?? asm.GetManifestResourceStream("AIChatConsole.Assets.index.html");
        if (src is null)
        {
            string fallback = Path.Combine(AppContext.BaseDirectory, "Assets", "index.html");
            if (File.Exists(fallback))
            {
                File.Copy(fallback, path, true);
                return;
            }
            throw new InvalidOperationException("내장 페이지(index.html)를 찾을 수 없습니다.");
        }

        try
        {
            using FileStream dst = File.Create(path);
            src.CopyTo(dst);
        }
        catch (IOException) when (File.Exists(path))
        {
            // 다른 인스턴스가 사용 중이면 기존 파일 사용
        }
    }

    private static bool IsAllowedNavigation(string uri)
    {
        if (!Uri.TryCreate(uri, UriKind.Absolute, out Uri? u))
            return false;

        if (u.Scheme is "blob" or "data" or "about" or "file")
            return true;

        return u.Host.Equals(HostName, StringComparison.OrdinalIgnoreCase);
    }

    private static void OpenExternal(string uri)
    {
        if (!Uri.TryCreate(uri, UriKind.Absolute, out Uri? u))
            return;

        if (u.Scheme != Uri.UriSchemeHttp && u.Scheme != Uri.UriSchemeHttps)
            return;

        try
        {
            Process.Start(new ProcessStartInfo(u.AbsoluteUri) { UseShellExecute = true });
        }
        catch
        {
            // ignore
        }
    }
}
