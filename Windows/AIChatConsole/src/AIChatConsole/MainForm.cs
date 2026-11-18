using System.Diagnostics;
using System.Reflection;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace AIChatConsole;

/// <summary>
/// WebView2 안에 내장된 채팅 페이지(Assets/index.html)를 띄우는 메인 창.
/// 페이지는 가상 호스트(https://aichat.app)로 제공되어 localStorage와 IndexedDB가 안정적으로 동작한다.
/// </summary>
public sealed class MainForm : Form
{
    private const string AppTitle = "AI 채팅 콘솔";
    private const string HostName = "aichat.app";

    private readonly WebView2 _web = new() { Dock = DockStyle.Fill };

    public MainForm()
    {
        Text = AppTitle;
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(480, 480);

        Rectangle area = Screen.PrimaryScreen?.WorkingArea ?? new Rectangle(0, 0, 1366, 768);
        ClientSize = new Size(Math.Min(1280, area.Width - 80), Math.Min(820, area.Height - 120));

        try
        {
            Icon = System.Drawing.Icon.ExtractAssociatedIcon(Environment.ProcessPath ?? Application.ExecutablePath);
        }
        catch (Exception)
        {
            // 아이콘을 못 읽어도 실행에는 문제가 없다.
        }

        Controls.Add(_web);
        Load += async (_, _) => await InitializeWebAsync();
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
            ExtractPage(Path.Combine(webDir, "index.html"));

            // 데스크톱 앱이므로 CORS 제한을 풀어 어떤 API 엔드포인트와도 직접 통신할 수 있게 한다.
            // 이 창은 내장 페이지만 열고, 다른 주소로의 이동은 아래에서 막는다.
            var options = new CoreWebView2EnvironmentOptions
            {
                AdditionalBrowserArguments = "--disable-web-security --allow-running-insecure-content"
            };
            CoreWebView2Environment env = await CoreWebView2Environment.CreateAsync(null, profileDir, options);
            await _web.EnsureCoreWebView2Async(env);

            CoreWebView2 core = _web.CoreWebView2;
            core.Settings.IsStatusBarEnabled = false;
            core.SetVirtualHostNameToFolderMapping(HostName, webDir, CoreWebView2HostResourceAccessKind.Allow);

            core.DocumentTitleChanged += (_, _) =>
                Text = string.IsNullOrWhiteSpace(core.DocumentTitle) ? AppTitle : core.DocumentTitle;

            core.NewWindowRequested += (_, e) =>
            {
                e.Handled = true;
                OpenExternal(e.Uri);
            };

            core.NavigationStarting += (_, e) =>
            {
                if (!IsAllowedNavigation(e.Uri))
                {
                    e.Cancel = true;
                    OpenExternal(e.Uri);
                }
            };

            core.Navigate($"https://{HostName}/index.html");
        }
        catch (WebView2RuntimeNotFoundException)
        {
            DialogResult answer = MessageBox.Show(
                this,
                "Microsoft Edge WebView2 런타임이 설치되어 있지 않습니다.\n설치 페이지를 열까요?",
                AppTitle,
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);
            if (answer == DialogResult.Yes)
            {
                OpenExternal("https://developer.microsoft.com/microsoft-edge/webview2/");
            }
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, "앱을 시작하지 못했습니다.\n\n" + ex.Message, AppTitle,
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            Close();
        }
    }

    private static void ExtractPage(string path)
    {
        Assembly asm = Assembly.GetExecutingAssembly();
        using Stream? src = asm.GetManifestResourceStream("index.html");
        if (src is null)
        {
            throw new InvalidOperationException("내장 페이지(index.html)를 찾을 수 없습니다.");
        }

        try
        {
            using FileStream dst = File.Create(path);
            src.CopyTo(dst);
        }
        catch (IOException) when (File.Exists(path))
        {
            // 다른 실행 중인 인스턴스가 파일을 쓰고 있으면 기존 파일을 그대로 사용한다.
        }
    }

    private static bool IsAllowedNavigation(string uri)
    {
        if (!Uri.TryCreate(uri, UriKind.Absolute, out Uri? u))
        {
            return false;
        }

        if (u.Scheme is "blob" or "data" or "about")
        {
            return true;
        }

        return u.Host.Equals(HostName, StringComparison.OrdinalIgnoreCase);
    }

    private static void OpenExternal(string uri)
    {
        if (!Uri.TryCreate(uri, UriKind.Absolute, out Uri? u))
        {
            return;
        }

        if (u.Scheme != Uri.UriSchemeHttp && u.Scheme != Uri.UriSchemeHttps)
        {
            return;
        }

        try
        {
            Process.Start(new ProcessStartInfo(u.AbsoluteUri) { UseShellExecute = true });
        }
        catch (Exception)
        {
            // 기본 브라우저를 열지 못해도 앱은 계속 동작한다.
        }
    }
}
