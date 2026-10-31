# ==============================================================================
# Lead Architect: Emanuel Schaaf | Open Origin Architecture
# Projekt: Google Ecosystem Desktop Hub V2 (Auto-Slide Edge + Inline Search)
# ==============================================================================

$ErrorActionPreference = "Stop"

# Laufende Instanz sauber beenden, damit die EXE überschrieben werden kann
Get-Process -Name "GoogleEcosystemHub" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 300

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ExePath     = Join-Path $DesktopPath "GoogleEcosystemHub.exe"
$IconPath    = Join-Path $env:TEMP "google_grid_icon.ico"

Write-Host "[1/3] Erzeuge 3x3-Raster Programm-Icon..." -ForegroundColor Cyan

Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap(64, 64)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 43, 44, 47))

$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$positions = @(10, 27, 44)
foreach ($x in $positions) {
    foreach ($y in $positions) {
        $g.FillEllipse($brush, $x, $y, 9, 9)
    }
}
$g.Dispose()

$msPng = New-Object System.IO.MemoryStream
$bmp.Save($msPng, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $msPng.ToArray()
$msPng.Dispose()
$bmp.Dispose()

$fsIco = New-Object System.IO.FileStream($IconPath, [System.IO.FileMode]::Create)
$bw    = New-Object System.IO.BinaryWriter($fsIco)
$bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]1)
$bw.Write([Byte]64);  $bw.Write([Byte]64);  $bw.Write([Byte]0); $bw.Write([Byte]0)
$bw.Write([UInt16]1); $bw.Write([UInt16]32)
$bw.Write([UInt32]$pngBytes.Length)
$bw.Write([UInt32]22)
$bw.Write($pngBytes)
$bw.Close()
$fsIco.Close()

Write-Host "[2/3] Kompiliere GoogleEcosystemHub V2 ($ExePath)..." -ForegroundColor Cyan

$CSharpSource = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

namespace GoogleEcosystemHub
{
    public class AppItem
    {
        public string Name;
        public string Category;
        public string Url;
        public string BadgeText;
        public Color BadgeColor;

        public AppItem(string name, string cat, string url, string badge, Color color)
        {
            Name = name;
            Category = cat;
            Url = url;
            BadgeText = badge;
            BadgeColor = color;
        }
    }

    public class SearchResultEntry
    {
        public string Title;
        public string Snippet;
        public string Url;
        public bool IsAiOverview;
    }

    public class ConfigManager
    {
        private static string ConfigDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "GoogleEcosystemHub");
        private static string ConfigFile = Path.Combine(ConfigDir, "settings.ini");

        public int PosX = -1;
        public int PosY = -1;
        public bool IsLocked = false;
        public bool UseAppMode = true;
        public bool AlwaysOnTop = true;
        public bool AutoSlideEdge = true;

        public void Load()
        {
            try
            {
                if (!File.Exists(ConfigFile)) return;
                string[] lines = File.ReadAllLines(ConfigFile);
                foreach (string line in lines)
                {
                    string[] parts = line.Split('=');
                    if (parts.Length != 2) continue;
                    string k = parts[0].Trim();
                    string v = parts[1].Trim();
                    if (k == "PosX") int.TryParse(v, out PosX);
                    if (k == "PosY") int.TryParse(v, out PosY);
                    if (k == "IsLocked") bool.TryParse(v, out IsLocked);
                    if (k == "UseAppMode") bool.TryParse(v, out UseAppMode);
                    if (k == "AlwaysOnTop") bool.TryParse(v, out AlwaysOnTop);
                    if (k == "AutoSlideEdge") bool.TryParse(v, out AutoSlideEdge);
                }
            }
            catch { }
        }

        public void Save()
        {
            try
            {
                if (!Directory.Exists(ConfigDir)) Directory.CreateDirectory(ConfigDir);
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("PosX=" + PosX);
                sb.AppendLine("PosY=" + PosY);
                sb.AppendLine("IsLocked=" + IsLocked);
                sb.AppendLine("UseAppMode=" + UseAppMode);
                sb.AppendLine("AlwaysOnTop=" + AlwaysOnTop);
                sb.AppendLine("AutoSlideEdge=" + AutoSlideEdge);
                File.WriteAllText(ConfigFile, sb.ToString());
            }
            catch { }
        }
    }

    public static class ChromeAccountDetector
    {
        public static string GetChromeExePath()
        {
            string[] candidates = new string[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Google\Chrome\Application\chrome.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Google\Chrome\Application\chrome.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Google\Chrome\Application\chrome.exe")
            };
            foreach (string path in candidates)
            {
                if (File.Exists(path)) return path;
            }
            return null;
        }

        public static string DetectLoggedInAccount(out bool isLoggedIn)
        {
            isLoggedIn = false;
            try
            {
                string localStatePath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    @"Google\Chrome\User Data\Local State");

                if (File.Exists(localStatePath))
                {
                    string content;
                    using (FileStream fs = new FileStream(localStatePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    using (StreamReader sr = new StreamReader(fs, Encoding.UTF8))
                    {
                        content = sr.ReadToEnd();
                    }

                    Match mUser = Regex.Match(content, "\"user_name\"\\s*:\\s*\"([^\"]+@[^\"]+)\"");
                    if (mUser.Success && !string.IsNullOrEmpty(mUser.Groups[1].Value))
                    {
                        isLoggedIn = true;
                        return mUser.Groups[1].Value;
                    }
                }

                string prefPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    @"Google\Chrome\User Data\Default\Preferences");

                if (File.Exists(prefPath))
                {
                    string prefContent;
                    using (FileStream fs = new FileStream(prefPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    using (StreamReader sr = new StreamReader(fs, Encoding.UTF8))
                    {
                        prefContent = sr.ReadToEnd();
                    }

                    Match mEmail = Regex.Match(prefContent, "\"email\"\\s*:\\s*\"([^\"]+@[^\"]+)\"");
                    if (mEmail.Success && !string.IsNullOrEmpty(mEmail.Groups[1].Value))
                    {
                        isLoggedIn = true;
                        return mEmail.Groups[1].Value;
                    }
                }
            }
            catch { }

            return "Nicht in Chrome angemeldet";
        }

        public static void LaunchUrl(string url, bool appMode)
        {
            bool loggedIn;
            DetectLoggedInAccount(out loggedIn);

            string targetUrl = url;
            if (!loggedIn && !url.Contains("accounts.google.com"))
            {
                DialogResult dr = MessageBox.Show(
                    "Es wurde kein aktives Google-Konto im lokalen Chrome-Profil erkannt.\n\nMöchtest du dich jetzt zuerst mit deinem Google-Konto anmelden?",
                    "Google Account Verknüpfung",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Information);

                if (dr == DialogResult.Yes)
                {
                    targetUrl = "https://accounts.google.com/ServiceLogin?continue=" + Uri.EscapeDataString(url);
                }
            }

            string chromePath = GetChromeExePath();
            if (chromePath != null)
            {
                string args = appMode ? ("--app=\"" + targetUrl + "\"") : ("\"" + targetUrl + "\"");
                Process.Start(chromePath, args);
            }
            else
            {
                Process.Start(targetUrl);
            }
        }
    }

    public static class InlineSearchEngine
    {
        static InlineSearchEngine()
        {
            try { ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072; } catch { }
        }

        private static string FetchString(string url)
        {
            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
            req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) GoogleEcosystemHub/2.0";
            req.Timeout = 7000;
            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
            using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
            {
                return sr.ReadToEnd();
            }
        }

        private static string CleanStopWords(string query)
        {
            string q = query.Trim();
            string[] prefixes = new string[]
            {
                "erkläre mir was ein ", "erkläre mir was eine ", "erkläre mir was ", "erkläre mir ",
                "was ist ein ", "was ist eine ", "was sind ", "was ist ", "wer ist ", "wie funktioniert ein ",
                "wie funktioniert eine ", "wie funktioniert ", "erkläre ", "definiere "
            };
            string lower = q.ToLowerInvariant();
            foreach (string p in prefixes)
            {
                if (lower.StartsWith(p))
                {
                    q = q.Substring(p.Length);
                    break;
                }
            }
            q = Regex.Replace(q, @"(\s+ist)?\s*[\?\!\.]*$", "", RegexOptions.IgnoreCase).Trim();
            return string.IsNullOrEmpty(q) ? query.Trim() : q;
        }

        private static string DecodeJsonString(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            string s = input.Replace("\\\"", "\"").Replace("\\n", "\n").Replace("\\r", "").Replace("\\/", "/").Replace("\\t", " ");
            s = Regex.Replace(s, @"\\u([0-9a-fA-F]{4})", delegate(Match m) {
                return ((char)Convert.ToInt32(m.Groups[1].Value, 16)).ToString();
            });
            return s;
        }

        private static string StripHtml(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            string s = Regex.Replace(input, "<[^>]+>", "");
            s = WebUtility.HtmlDecode(s);
            return s.Trim();
        }

        public static List<SearchResultEntry> QueryInline(string rawQuery)
        {
            List<SearchResultEntry> list = new List<SearchResultEntry>();
            string coreTerm = CleanStopWords(rawQuery);

            try
            {
                // 1. Wikipedia DE Suche nach bestem Artikel für KI-Übersicht
                string searchApi = "https://de.wikipedia.org/w/api.php?action=query&list=search&srsearch=" +
                                   Uri.EscapeDataString(coreTerm) + "&utf8=1&format=json&srlimit=4";
                string searchJson = FetchString(searchApi);

                MatchCollection titleMatches = Regex.Matches(searchJson, "\"title\"\\s*:\\s*\"([^\"]+)\"");
                if (titleMatches.Count > 0)
                {
                    string bestTitle = DecodeJsonString(titleMatches[0].Groups[1].Value);
                    string summaryUrl = "https://de.wikipedia.org/api/rest_v1/page/summary/" + Uri.EscapeDataString(bestTitle.Replace(" ", "_"));
                    string sumJson = FetchString(summaryUrl);

                    Match mExtract = Regex.Match(sumJson, "\"extract\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");
                    if (mExtract.Success)
                    {
                        string extract = DecodeJsonString(mExtract.Groups[1].Value);
                        if (!string.IsNullOrEmpty(extract))
                        {
                            SearchResultEntry overview = new SearchResultEntry();
                            overview.Title = "✦ Übersicht mit KI  —  " + bestTitle;
                            overview.Snippet = extract;
                            overview.Url = "https://de.wikipedia.org/wiki/" + Uri.EscapeDataString(bestTitle.Replace(" ", "_"));
                            overview.IsAiOverview = true;
                            list.Add(overview);
                        }
                    }
                }

                // 2. Weitere Suchtreffer aus der API aufbereiten
                MatchCollection snippetMatches = Regex.Matches(searchJson, "\"title\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\".*?\"snippet\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");
                foreach (Match m in snippetMatches)
                {
                    string t = DecodeJsonString(m.Groups[1].Value);
                    string snip = StripHtml(DecodeJsonString(m.Groups[2].Value));
                    if (!string.IsNullOrEmpty(t) && !string.IsNullOrEmpty(snip))
                    {
                        SearchResultEntry entry = new SearchResultEntry();
                        entry.Title = t + " – Wissensdatenbank & Lexikon";
                        entry.Snippet = snip + " ...";
                        entry.Url = "https://de.wikipedia.org/wiki/" + Uri.EscapeDataString(t.Replace(" ", "_"));
                        entry.IsAiOverview = false;
                        list.Add(entry);
                    }
                }
            }
            catch { }

            // 3. Ergänzende Google-News / Web-Treffer via RSS für aktuelle Themen
            try
            {
                string rssUrl = "https://news.google.com/rss/search?q=" + Uri.EscapeDataString(rawQuery) + "&hl=de&gl=DE&ceid=DE:de";
                string rssXml = FetchString(rssUrl);
                MatchCollection items = Regex.Matches(rssXml, "<item>.*?<title>(.*?)</title>.*?<link>(.*?)</link>.*?(?:<pubDate>(.*?)</pubDate>)?.*?</item>", RegexOptions.Singleline);
                int count = 0;
                foreach (Match m in items)
                {
                    if (count >= 5) break;
                    string t = StripHtml(m.Groups[1].Value);
                    string l = StripHtml(m.Groups[2].Value);
                    string d = StripHtml(m.Groups[3].Value);

                    SearchResultEntry webEntry = new SearchResultEntry();
                    webEntry.Title = t;
                    webEntry.Snippet = string.IsNullOrEmpty(d) ? "Aktueller Web-Beitrag über Google Suche" : ("Veröffentlicht: " + d);
                    webEntry.Url = l;
                    webEntry.IsAiOverview = false;
                    list.Add(webEntry);
                    count++;
                }
            }
            catch { }

            if (list.Count == 0)
            {
                SearchResultEntry fallback = new SearchResultEntry();
                fallback.Title = "✦ Direkt-Suche für: " + rawQuery;
                fallback.Snippet = "Klicke hier, um die vollständige Google-KI-Übersicht für diese Anfrage zu öffnen.";
                fallback.Url = "https://www.google.com/search?q=" + Uri.EscapeDataString(rawQuery);
                fallback.IsAiOverview = true;
                list.Add(fallback);
            }

            return list;
        }
    }

    public class HubPopupForm : Form
    {
        private ConfigManager Config;
        private List<AppItem> AllApps = new List<AppItem>();
        private FlowLayoutPanel ContentPanel;
        private TextBox SearchBox;
        private Label AccountStatusLabel;
        private Button LoginActionButton;
        private CheckBox AppModeCheck;
        private CheckBox AutostartCheck;
        private Label ModeHintLabel;
        private bool ShowingSearchResults = false;

        public HubPopupForm(ConfigManager config)
        {
            Config = config;

            this.FormBorderStyle = FormBorderStyle.None;
            this.ShowInTaskbar = false;
            this.StartPosition = FormStartPosition.Manual;
            this.Size = new Size(385, 630);
            this.BackColor = Color.FromArgb(30, 31, 34);
            this.TopMost = true;
            this.DoubleBuffered = true;

            InitAppCatalog();
            BuildUI();
        }

        private void InitAppCatalog()
        {
            Color cBlue   = Color.FromArgb(66, 133, 244);
            Color cRed    = Color.FromArgb(234, 67, 53);
            Color cYellow = Color.FromArgb(251, 188, 5);
            Color cGreen  = Color.FromArgb(52, 168, 83);
            Color cPurple = Color.FromArgb(161, 66, 244);
            Color cTeal   = Color.FromArgb(0, 172, 193);

            AllApps.Add(new AppItem("Konto", "Fav", "https://myaccount.google.com", "👤", cBlue));
            AllApps.Add(new AppItem("Suche", "Fav", "https://www.google.com", "G", cBlue));
            AllApps.Add(new AppItem("Maps", "Fav", "https://maps.google.com", "📍", cGreen));
            AllApps.Add(new AppItem("YouTube", "Fav", "https://www.youtube.com", "▶", cRed));
            AllApps.Add(new AppItem("Play", "Fav", "https://play.google.com/store/points", "▶+", cGreen));
            AllApps.Add(new AppItem("Gmail", "Fav", "https://mail.google.com", "M", cRed));
            AllApps.Add(new AppItem("Drive", "Fav", "https://drive.google.com", "△", cYellow));
            AllApps.Add(new AppItem("Kalender", "Fav", "https://calendar.google.com", "31", cBlue));
            AllApps.Add(new AppItem("Übersetzer", "Fav", "https://translate.google.com", "文", cBlue));

            AllApps.Add(new AppItem("Unternehm...", "Ext", "https://business.google.com", "🏪", cBlue));
            AllApps.Add(new AppItem("Gemini", "Ext", "https://gemini.google.com", "✦", cPurple));
            AllApps.Add(new AppItem("News", "Ext", "https://news.google.com", "📰", cBlue));
            AllApps.Add(new AppItem("Fotos", "Ext", "https://photos.google.com", "❖", cRed));
            AllApps.Add(new AppItem("Google TV", "Ext", "https://tv.google.com", "TV", cRed));
            AllApps.Add(new AppItem("Sheets", "Ext", "https://docs.google.com/spreadsheets", "⊞", cGreen));
            AllApps.Add(new AppItem("Docs", "Ext", "https://docs.google.com/document", "≡", cBlue));
            AllApps.Add(new AppItem("Präsentati...", "Ext", "https://docs.google.com/presentation", "▭", cYellow));
            AllApps.Add(new AppItem("Google One", "Ext", "https://one.google.com", "1", cBlue));
            AllApps.Add(new AppItem("Shopping", "Ext", "https://shopping.google.com", "🏷", cGreen));
            AllApps.Add(new AppItem("Google Store", "Ext", "https://store.google.com", "🛍", cBlue));
            AllApps.Add(new AppItem("Finanzen", "Ext", "https://www.google.com/finance", "📈", cGreen));
            AllApps.Add(new AppItem("Notizen", "Ext", "https://keep.google.com", "💡", cYellow));
            AllApps.Add(new AppItem("Mein Anz...", "Ext", "https://myadcenter.google.com", "⚙", cTeal));
            AllApps.Add(new AppItem("Classroom", "Ext", "https://classroom.google.com", "🎓", cGreen));
            AllApps.Add(new AppItem("Chat", "Ext", "https://chat.google.com", "💬", cGreen));
            AllApps.Add(new AppItem("Earth", "Ext", "https://earth.google.com/web", "🌍", cBlue));
            AllApps.Add(new AppItem("Gespeichert", "Ext", "https://www.google.com/interests/saved", "🔖", cYellow));
            AllApps.Add(new AppItem("Arts & Cul...", "Ext", "https://artsandculture.google.com", "🏛", cTeal));
            AllApps.Add(new AppItem("Google Ads", "Ext", "https://ads.google.com/ups/routing?source=206&subid=xs-ip-gemini-adlt", "▲", cBlue));
            AllApps.Add(new AppItem("Merchant ...", "Ext", "https://merchants.google.com", "🛒", cBlue));
            AllApps.Add(new AppItem("Kontakte", "Ext", "https://contacts.google.com", "👥", cBlue));
            AllApps.Add(new AppItem("Reisen", "Ext", "https://www.google.com/travel", "🧳", cBlue));
            AllApps.Add(new AppItem("Formulare", "Ext", "https://docs.google.com/forms", "☷", cPurple));
            AllApps.Add(new AppItem("Books", "Ext", "https://books.google.com", "📘", cTeal));
            AllApps.Add(new AppItem("Chrome Web", "Ext", "https://chromewebstore.google.com", "🌐", cBlue));
            AllApps.Add(new AppItem("Passwort...", "Ext", "https://passwords.google.com", "🔑", cGreen));
            AllApps.Add(new AppItem("Google A...", "Ext", "https://analytics.google.com", "📊", cYellow));
            AllApps.Add(new AppItem("Blogger", "Ext", "https://www.blogger.com", "B", cYellow));
            AllApps.Add(new AppItem("YT Music", "Ext", "https://music.youtube.com", "♫", cRed));
            AllApps.Add(new AppItem("Wallet", "Ext", "https://wallet.google.com", "💳", cBlue));
            AllApps.Add(new AppItem("Notebook", "Ext", "https://notebooklm.google.com", "📓", cTeal));
            AllApps.Add(new AppItem("Tasks", "Ext", "https://tasksboard.com/app", "✔", cBlue));
        }

        private void BuildUI()
        {
            Panel headerPanel = new Panel();
            headerPanel.Dock = DockStyle.Top;
            headerPanel.Height = 128;
            headerPanel.BackColor = Color.FromArgb(24, 25, 28);
            headerPanel.Padding = new Padding(12);

            AccountStatusLabel = new Label();
            AccountStatusLabel.Location = new Point(12, 10);
            AccountStatusLabel.Size = new Size(255, 22);
            AccountStatusLabel.Font = new Font("Segoe UI Semibold", 9.0f);
            AccountStatusLabel.ForeColor = Color.White;
            headerPanel.Controls.Add(AccountStatusLabel);

            LoginActionButton = new Button();
            LoginActionButton.Location = new Point(275, 7);
            LoginActionButton.Size = new Size(96, 26);
            LoginActionButton.FlatStyle = FlatStyle.Flat;
            LoginActionButton.FlatAppearance.BorderSize = 0;
            LoginActionButton.BackColor = Color.FromArgb(66, 133, 244);
            LoginActionButton.ForeColor = Color.White;
            LoginActionButton.Font = new Font("Segoe UI Semibold", 8.0f);
            LoginActionButton.Text = "Mein Konto";
            LoginActionButton.Cursor = Cursors.Hand;
            LoginActionButton.Click += delegate {
                ChromeAccountDetector.LaunchUrl("https://accounts.google.com", Config.UseAppMode);
                this.Hide();
            };
            headerPanel.Controls.Add(LoginActionButton);

            SearchBox = new TextBox();
            SearchBox.Location = new Point(12, 42);
            SearchBox.Size = new Size(288, 26);
            SearchBox.BackColor = Color.FromArgb(43, 45, 49);
            SearchBox.ForeColor = Color.White;
            SearchBox.BorderStyle = BorderStyle.FixedSingle;
            SearchBox.Font = new Font("Segoe UI", 9.5f);
            SearchBox.Text = "";
            SearchBox.TextChanged += delegate {
                string txt = SearchBox.Text.Trim();
                if (string.IsNullOrEmpty(txt))
                {
                    PopulateAppGrid("");
                }
                else if (!ShowingSearchResults)
                {
                    // Nur filtern, wenn eine App dazu passt – sonst Apps stehen lassen!
                    bool anyMatch = false;
                    foreach (AppItem a in AllApps)
                    {
                        if (a.Name.IndexOf(txt, StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            anyMatch = true;
                            break;
                        }
                    }
                    if (anyMatch) PopulateAppGrid(txt);
                }
            };
            SearchBox.KeyDown += delegate(object s, KeyEventArgs e) {
                if (e.KeyCode == Keys.Enter && !string.IsNullOrEmpty(SearchBox.Text.Trim()))
                {
                    e.SuppressKeyPress = true;
                    RunInlineSearch(SearchBox.Text.Trim());
                }
            };
            headerPanel.Controls.Add(SearchBox);

            Button btnInlineSearch = new Button();
            btnInlineSearch.Location = new Point(306, 41);
            btnInlineSearch.Size = new Size(65, 26);
            btnInlineSearch.FlatStyle = FlatStyle.Flat;
            btnInlineSearch.FlatAppearance.BorderSize = 0;
            btnInlineSearch.BackColor = Color.FromArgb(138, 66, 244);
            btnInlineSearch.ForeColor = Color.White;
            btnInlineSearch.Font = new Font("Segoe UI Semibold", 8.0f);
            btnInlineSearch.Text = "✦ Frage";
            btnInlineSearch.Cursor = Cursors.Hand;
            btnInlineSearch.Click += delegate {
                if (!string.IsNullOrEmpty(SearchBox.Text.Trim()))
                {
                    RunInlineSearch(SearchBox.Text.Trim());
                }
                else
                {
                    SearchBox.Focus();
                }
            };
            headerPanel.Controls.Add(btnInlineSearch);

            AppModeCheck = new CheckBox();
            AppModeCheck.Location = new Point(12, 76);
            AppModeCheck.Size = new Size(215, 20);
            AppModeCheck.ForeColor = Color.FromArgb(200, 204, 210);
            AppModeCheck.Font = new Font("Segoe UI", 8.2f);
            AppModeCheck.Text = "Apps rahmenlos öffnen (--app)";
            AppModeCheck.Checked = Config.UseAppMode;
            AppModeCheck.CheckedChanged += delegate {
                Config.UseAppMode = AppModeCheck.Checked;
                Config.Save();
            };
            headerPanel.Controls.Add(AppModeCheck);

            AutostartCheck = new CheckBox();
            AutostartCheck.Location = new Point(235, 76);
            AutostartCheck.Size = new Size(135, 20);
            AutostartCheck.ForeColor = Color.FromArgb(200, 204, 210);
            AutostartCheck.Font = new Font("Segoe UI", 8.2f);
            AutostartCheck.Text = "Windows-Autostart";
            AutostartCheck.Checked = IsAutostartEnabled();
            AutostartCheck.CheckedChanged += delegate {
                SetAutostart(AutostartCheck.Checked);
            };
            headerPanel.Controls.Add(AutostartCheck);

            ModeHintLabel = new Label();
            ModeHintLabel.Location = new Point(12, 101);
            ModeHintLabel.Size = new Size(358, 18);
            ModeHintLabel.ForeColor = Color.FromArgb(145, 150, 160);
            ModeHintLabel.Font = new Font("Segoe UI", 7.8f);
            ModeHintLabel.Text = "Frage eintippen & [Enter] drücken -> Antwort erscheint direkt unten drunter!";
            headerPanel.Controls.Add(ModeHintLabel);

            this.Controls.Add(headerPanel);

            // Scrollable Content Area (Apps + Inline Search Results)
            ContentPanel = new FlowLayoutPanel();
            ContentPanel.Location = new Point(6, 132);
            ContentPanel.Size = new Size(373, 490);
            ContentPanel.AutoScroll = true;
            ContentPanel.FlowDirection = FlowDirection.LeftToRight;
            ContentPanel.WrapContents = true;
            ContentPanel.BackColor = Color.FromArgb(30, 31, 34);
            ContentPanel.Padding = new Padding(4);
            this.Controls.Add(ContentPanel);

            RefreshAccountBanner();
            PopulateAppGrid("");
        }

        private void RunInlineSearch(string query)
        {
            ShowingSearchResults = true;
            ContentPanel.SuspendLayout();
            ContentPanel.Controls.Clear();

            // Navigation Bar inside Inline View
            Panel navBar = new Panel();
            navBar.Size = new Size(338, 34);
            navBar.BackColor = Color.FromArgb(38, 40, 44);
            navBar.Margin = new Padding(4, 4, 4, 8);

            Button btnBack = new Button();
            btnBack.Location = new Point(4, 4);
            btnBack.Size = new Size(175, 26);
            btnBack.FlatStyle = FlatStyle.Flat;
            btnBack.FlatAppearance.BorderSize = 0;
            btnBack.BackColor = Color.FromArgb(66, 133, 244);
            btnBack.ForeColor = Color.White;
            btnBack.Font = new Font("Segoe UI Semibold", 8.2f);
            btnBack.Text = "← Zurück zu Google-Apps";
            btnBack.Cursor = Cursors.Hand;
            btnBack.Click += delegate {
                ShowingSearchResults = false;
                PopulateAppGrid("");
            };
            navBar.Controls.Add(btnBack);

            Button btnBrowser = new Button();
            btnBrowser.Location = new Point(186, 4);
            btnBrowser.Size = new Size(148, 26);
            btnBrowser.FlatStyle = FlatStyle.Flat;
            btnBrowser.FlatAppearance.BorderSize = 0;
            btnBrowser.BackColor = Color.FromArgb(55, 58, 64);
            btnBrowser.ForeColor = Color.White;
            btnBrowser.Font = new Font("Segoe UI", 8.0f);
            btnBrowser.Text = "Im Browser öffnen ↗";
            btnBrowser.Cursor = Cursors.Hand;
            btnBrowser.Click += delegate {
                ChromeAccountDetector.LaunchUrl("https://www.google.com/search?q=" + Uri.EscapeDataString(query), Config.UseAppMode);
                this.Hide();
            };
            navBar.Controls.Add(btnBrowser);

            ContentPanel.Controls.Add(navBar);

            Label loadingLbl = new Label();
            loadingLbl.Text = "✦ Lade KI-Übersicht & Ergebnisse für \"" + query + "\" ...";
            loadingLbl.Font = new Font("Segoe UI Semibold", 9.5f);
            loadingLbl.ForeColor = Color.FromArgb(161, 194, 250);
            loadingLbl.Size = new Size(335, 40);
            loadingLbl.Margin = new Padding(8, 10, 8, 10);
            ContentPanel.Controls.Add(loadingLbl);
            ContentPanel.ResumeLayout();

            ThreadPool.QueueUserWorkItem(delegate {
                List<SearchResultEntry> results = InlineSearchEngine.QueryInline(query);
                try
                {
                    this.BeginInvoke((MethodInvoker)delegate {
                        RenderInlineResults(query, results);
                    });
                }
                catch { }
            });
        }

        private void RenderInlineResults(string query, List<SearchResultEntry> results)
        {
            if (!ShowingSearchResults) return;

            ContentPanel.SuspendLayout();
            while (ContentPanel.Controls.Count > 1)
            {
                ContentPanel.Controls.RemoveAt(1);
            }

            foreach (SearchResultEntry entry in results)
            {
                Panel card = new Panel();
                card.Width = 338;
                card.BackColor = entry.IsAiOverview ? Color.FromArgb(36, 42, 54) : Color.FromArgb(40, 42, 46);
                card.Margin = new Padding(4, 4, 4, 8);
                card.Padding = new Padding(10);
                card.Cursor = Cursors.Hand;

                Label lblTitle = new Label();
                lblTitle.Text = entry.Title;
                lblTitle.Font = new Font("Segoe UI Semibold", entry.IsAiOverview ? 10.0f : 9.2f);
                lblTitle.ForeColor = entry.IsAiOverview ? Color.FromArgb(138, 180, 248) : Color.FromArgb(168, 199, 250);
                lblTitle.Location = new Point(10, 10);
                lblTitle.MaximumSize = new Size(318, 0);
                lblTitle.AutoSize = true;
                card.Controls.Add(lblTitle);

                Label lblBody = new Label();
                lblBody.Text = entry.Snippet;
                lblBody.Font = new Font("Segoe UI", 9.0f);
                lblBody.ForeColor = Color.FromArgb(232, 234, 237);
                lblBody.Location = new Point(10, lblTitle.Bottom + 8);
                lblBody.MaximumSize = new Size(318, 0);
                lblBody.AutoSize = true;
                card.Controls.Add(lblBody);

                int totalHeight = lblBody.Bottom + 14;
                card.Height = totalHeight;

                EventHandler openLink = delegate {
                    ChromeAccountDetector.LaunchUrl(entry.Url, Config.UseAppMode);
                    this.Hide();
                };
                card.Click += openLink;
                lblTitle.Click += openLink;
                lblBody.Click += openLink;

                ContentPanel.Controls.Add(card);
            }

            ContentPanel.ResumeLayout();
            ContentPanel.Focus();
        }

        public void RefreshAccountBanner()
        {
            bool loggedIn;
            string acc = ChromeAccountDetector.DetectLoggedInAccount(out loggedIn);
            if (loggedIn)
            {
                AccountStatusLabel.Text = "● " + acc;
                AccountStatusLabel.ForeColor = Color.FromArgb(129, 201, 149);
                LoginActionButton.Text = "Mein Konto";
                LoginActionButton.BackColor = Color.FromArgb(55, 60, 68);
            }
            else
            {
                AccountStatusLabel.Text = "● Nicht in Chrome eingeloggt";
                AccountStatusLabel.ForeColor = Color.FromArgb(242, 139, 130);
                LoginActionButton.Text = "Jetzt Login";
                LoginActionButton.BackColor = Color.FromArgb(234, 67, 53);
            }
        }

        public void PopulateAppGrid(string filter)
        {
            ShowingSearchResults = false;
            ContentPanel.SuspendLayout();
            ContentPanel.Controls.Clear();

            bool showHeaders = string.IsNullOrEmpty(filter);

            if (showHeaders)
            {
                ContentPanel.Controls.Add(CreateSectionHeader("Meine Favoriten"));
            }

            bool addedExtHeader = false;
            foreach (AppItem item in AllApps)
            {
                if (!string.IsNullOrEmpty(filter))
                {
                    if (item.Name.IndexOf(filter, StringComparison.OrdinalIgnoreCase) < 0)
                        continue;
                }
                else if (item.Category == "Ext" && !addedExtHeader)
                {
                    addedExtHeader = true;
                    ContentPanel.Controls.Add(CreateSectionHeader("Alle Google-Dienste & Tools"));
                }

                ContentPanel.Controls.Add(CreateAppTile(item));
            }

            ContentPanel.ResumeLayout();
        }

        private Control CreateSectionHeader(string title)
        {
            Label lbl = new Label();
            lbl.Text = title;
            lbl.Font = new Font("Segoe UI Semibold", 9.5f);
            lbl.ForeColor = Color.FromArgb(210, 214, 220);
            lbl.Size = new Size(335, 26);
            lbl.TextAlign = ContentAlignment.BottomLeft;
            lbl.Margin = new Padding(6, 6, 6, 4);
            return lbl;
        }

        private Control CreateAppTile(AppItem item)
        {
            Panel tile = new Panel();
            tile.Size = new Size(106, 88);
            tile.Margin = new Padding(4);
            tile.BackColor = Color.FromArgb(40, 42, 46);
            tile.Cursor = Cursors.Hand;

            tile.Paint += delegate(object s, PaintEventArgs e) {
                e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                Rectangle badgeRect = new Rectangle(33, 10, 40, 40);
                using (SolidBrush b = new SolidBrush(item.BadgeColor))
                {
                    e.Graphics.FillEllipse(b, badgeRect);
                }
                StringFormat sf = new StringFormat();
                sf.Alignment = StringAlignment.Center;
                sf.LineAlignment = StringAlignment.Center;
                using (Font f = new Font("Segoe UI Bold", 12.0f))
                using (SolidBrush tb = new SolidBrush(Color.White))
                {
                    e.Graphics.DrawString(item.BadgeText, f, tb, badgeRect, sf);
                }

                Rectangle textRect = new Rectangle(2, 54, 102, 28);
                using (Font tf = new Font("Segoe UI", 8.5f))
                using (SolidBrush tBrush = new SolidBrush(Color.FromArgb(232, 234, 237)))
                {
                    e.Graphics.DrawString(item.Name, tf, tBrush, textRect, sf);
                }
            };

            tile.MouseEnter += delegate { tile.BackColor = Color.FromArgb(58, 61, 66); };
            tile.MouseLeave += delegate { tile.BackColor = Color.FromArgb(40, 42, 46); };
            tile.Click += delegate {
                ChromeAccountDetector.LaunchUrl(item.Url, Config.UseAppMode);
                this.Hide();
            };

            return tile;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            using (Pen p = new Pen(Color.FromArgb(70, 74, 80), 1))
            {
                e.Graphics.DrawRectangle(p, 0, 0, this.Width - 1, this.Height - 1);
            }
        }

        protected override void OnDeactivate(EventArgs e)
        {
            base.OnDeactivate(e);
            this.Hide();
        }

        private bool IsAutostartEnabled()
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", false))
                {
                    if (key == null) return false;
                    return key.GetValue("GoogleEcosystemHub") != null;
                }
            }
            catch { return false; }
        }

        private void SetAutostart(bool enable)
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true))
                {
                    if (key == null) return;
                    if (enable)
                        key.SetValue("GoogleEcosystemHub", "\"" + Application.ExecutablePath + "\"");
                    else
                        key.DeleteValue("GoogleEcosystemHub", false);
                }
            }
            catch { }
        }
    }

    public class LauncherOrbForm : Form
    {
        private ConfigManager Config;
        private HubPopupForm PopupMenu;
        private bool IsDragging = false;
        private Point DragStartPoint;
        private bool DidMove = false;
        private bool IsHovered = false;
        private Rectangle LockButtonRect = new Rectangle(42, 2, 20, 20);
        private ToolTip OrbToolTip;

        // Auto-Slide / Edge Docking Steuerung
        private System.Windows.Forms.Timer IdleTimer;
        private System.Windows.Forms.Timer SlideTimer;
        private bool IsDockedCollapsed = false;
        private int TargetX = 0;
        private const int PeekWidth = 22; // Nur 1 Spalte mit 3 Punkten sichtbar wie im Screenshot

        public LauncherOrbForm()
        {
            Config = new ConfigManager();
            Config.Load();

            this.FormBorderStyle = FormBorderStyle.None;
            this.ShowInTaskbar = false;
            this.Size = new Size(64, 64);
            this.StartPosition = FormStartPosition.Manual;
            this.BackColor = Color.FromArgb(43, 44, 47);
            this.TopMost = Config.AlwaysOnTop;
            this.DoubleBuffered = true;
            this.Cursor = Cursors.Hand;

            Rectangle wa = Screen.PrimaryScreen.WorkingArea;
            if (Config.PosX >= 0 && Config.PosY >= 0)
            {
                this.Location = new Point(Config.PosX, Config.PosY);
            }
            else
            {
                this.Location = new Point(wa.Right - this.Width, wa.Top + 120);
            }

            OrbToolTip = new ToolTip();
            UpdateTooltipText();

            PopupMenu = new HubPopupForm(Config);
            BuildContextMenu();
            InitSlideTimers();
        }

        private void InitSlideTimers()
        {
            IdleTimer = new System.Windows.Forms.Timer();
            IdleTimer.Interval = 1800; // Nach 1,8 Sekunden Inaktivität einfahren
            IdleTimer.Tick += delegate {
                if (!IsDragging && !PopupMenu.Visible && Config.AutoSlideEdge)
                {
                    Point cursor = Cursor.Position;
                    if (!this.Bounds.Contains(cursor))
                    {
                        IdleTimer.Stop();
                        CollapseToEdge();
                    }
                }
            };

            SlideTimer = new System.Windows.Forms.Timer();
            SlideTimer.Interval = 15;
            SlideTimer.Tick += delegate {
                int diff = TargetX - this.Left;
                if (Math.Abs(diff) <= 4)
                {
                    this.Left = TargetX;
                    SlideTimer.Stop();
                    this.Invalidate();
                }
                else
                {
                    int step = diff / 2;
                    if (step == 0) step = diff > 0 ? 1 : -1;
                    this.Left += step;
                }
            };

            IdleTimer.Start();
        }

        private Screen GetCurrentScreen()
        {
            return Screen.FromPoint(new Point(this.Left + this.Width / 2, this.Top + this.Height / 2));
        }

        private bool IsRightSideOfScreen()
        {
            Screen scr = GetCurrentScreen();
            int center = scr.Bounds.Left + (scr.Bounds.Width / 2);
            return (this.Left + this.Width / 2) >= center;
        }

        private void CollapseToEdge()
        {
            Screen scr = GetCurrentScreen();
            IsDockedCollapsed = true;
            if (IsRightSideOfScreen())
            {
                // Am rechten Rand bis auf 22px (1 Punktespalte) einfahren
                TargetX = scr.Bounds.Right - PeekWidth;
            }
            else
            {
                // Am linken Rand bis auf 22px einfahren
                TargetX = scr.Bounds.Left - (this.Width - PeekWidth);
            }
            SlideTimer.Start();
        }

        private void ExpandFromEdge()
        {
            Screen scr = GetCurrentScreen();
            IsDockedCollapsed = false;
            if (IsRightSideOfScreen())
            {
                TargetX = scr.WorkingArea.Right - this.Width;
            }
            else
            {
                TargetX = scr.WorkingArea.Left;
            }
            SlideTimer.Start();
        }

        private void UpdateTooltipText()
        {
            string state = Config.IsLocked ? "VERRIEGELT (Fest fixiert)" : "ENTRIEGELT (Frei verschiebbar)";
            OrbToolTip.SetToolTip(this, "Google Ecosystem Hub [" + state + "]\n• Klick: Google Apps & Inline-Suche\n• Schloss oben rechts: Position sperren/entsperren\n• Rechtsklick: Optionen");
        }

        private void BuildContextMenu()
        {
            ContextMenuStrip cms = new ContextMenuStrip();
            ToolStripMenuItem miLock = new ToolStripMenuItem("Position verriegeln / fixieren");
            miLock.Click += delegate { ToggleLock(); };

            ToolStripMenuItem miSlide = new ToolStripMenuItem("Automatisch seitlich einfahren");
            miSlide.Checked = Config.AutoSlideEdge;
            miSlide.Click += delegate {
                Config.AutoSlideEdge = !Config.AutoSlideEdge;
                miSlide.Checked = Config.AutoSlideEdge;
                Config.Save();
                if (Config.AutoSlideEdge) IdleTimer.Start();
                else ExpandFromEdge();
            };

            ToolStripMenuItem miTop = new ToolStripMenuItem("Immer im Vordergrund");
            miTop.Checked = Config.AlwaysOnTop;
            miTop.Click += delegate {
                Config.AlwaysOnTop = !Config.AlwaysOnTop;
                this.TopMost = Config.AlwaysOnTop;
                miTop.Checked = Config.AlwaysOnTop;
                Config.Save();
            };

            ToolStripMenuItem miExit = new ToolStripMenuItem("Google Hub beenden");
            miExit.Click += delegate { Application.Exit(); };

            cms.Opening += delegate {
                miLock.Checked = Config.IsLocked;
                miSlide.Checked = Config.AutoSlideEdge;
            };

            cms.Items.Add(miLock);
            cms.Items.Add(miSlide);
            cms.Items.Add(miTop);
            cms.Items.Add(new ToolStripSeparator());
            cms.Items.Add(miExit);
            this.ContextMenuStrip = cms;
        }

        private void ToggleLock()
        {
            Config.IsLocked = !Config.IsLocked;
            Config.Save();
            UpdateTooltipText();
            this.Invalidate();
        }

        protected override void OnMouseEnter(EventArgs e)
        {
            base.OnMouseEnter(e);
            IsHovered = true;
            IdleTimer.Stop();
            if (IsDockedCollapsed)
            {
                ExpandFromEdge();
            }
            this.Invalidate();
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            IsHovered = false;
            if (Config.AutoSlideEdge && !PopupMenu.Visible)
            {
                IdleTimer.Start();
            }
            this.Invalidate();
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button == MouseButtons.Left)
            {
                if (!IsDockedCollapsed && LockButtonRect.Contains(e.Location))
                {
                    ToggleLock();
                    return;
                }

                IsDragging = true;
                DidMove = false;
                DragStartPoint = e.Location;
            }
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            if (IsDragging && !Config.IsLocked)
            {
                int dx = Math.Abs(e.X - DragStartPoint.X);
                int dy = Math.Abs(e.Y - DragStartPoint.Y);
                if (dx > 3 || dy > 3)
                {
                    DidMove = true;
                    SlideTimer.Stop();
                    IsDockedCollapsed = false;
                    this.Location = new Point(this.Left + e.X - DragStartPoint.X, this.Top + e.Y - DragStartPoint.Y);
                }
            }
        }

        protected override void OnMouseUp(MouseEventArgs e)
        {
            base.OnMouseUp(e);
            if (e.Button == MouseButtons.Left && IsDragging)
            {
                IsDragging = false;
                if (DidMove)
                {
                    Screen scr = GetCurrentScreen();
                    if (Config.AutoSlideEdge)
                    {
                        this.Left = IsRightSideOfScreen() ? (scr.WorkingArea.Right - this.Width) : scr.WorkingArea.Left;
                    }
                    Config.PosX = this.Left;
                    Config.PosY = this.Top;
                    Config.Save();
                    IdleTimer.Start();
                }
                else
                {
                    TogglePopupMenu();
                }
            }
        }

        private void TogglePopupMenu()
        {
            if (PopupMenu.Visible)
            {
                PopupMenu.Hide();
                IdleTimer.Start();
            }
            else
            {
                if (IsDockedCollapsed) ExpandFromEdge();
                PopupMenu.RefreshAccountBanner();
                Screen scr = GetCurrentScreen();
                Rectangle wa = scr.WorkingArea;

                int x = IsRightSideOfScreen() ? (wa.Right - PopupMenu.Width - 6) : (wa.Left + 6);
                int y = this.Bottom + 8;

                if (y + PopupMenu.Height > wa.Bottom)
                    y = this.Top - PopupMenu.Height - 8;
                if (y < wa.Top)
                    y = wa.Top + 8;

                PopupMenu.Location = new Point(x, y);
                PopupMenu.Show();
                PopupMenu.Activate();
            }
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            Color bg = IsHovered ? Color.FromArgb(58, 60, 64) : Color.FromArgb(43, 44, 47);
            g.Clear(bg);

            Color borderColor = Config.IsLocked ? Color.FromArgb(66, 133, 244) : Color.FromArgb(95, 99, 104);
            using (Pen borderPen = new Pen(borderColor, 2))
            {
                g.DrawRectangle(borderPen, 1, 1, this.Width - 2, this.Height - 2);
            }

            // 3x3 Punkte so platziert, dass im eingefahrenen Zustand (22px) exakt 1 Spalte sichtbar bleibt
            int[] coordsX = new int[] { 8, 28, 48 };
            int[] coordsY = new int[] { 14, 30, 46 };
            using (SolidBrush dotBrush = new SolidBrush(Color.White))
            {
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        g.FillEllipse(dotBrush, coordsX[i], coordsY[j], 8, 8);
                    }
                }
            }

            // Schloss nur zeichnen, wenn ausgefahren
            if (!IsDockedCollapsed)
            {
                Color lockBg = Config.IsLocked ? Color.FromArgb(52, 168, 83) : Color.FromArgb(95, 99, 104);
                using (SolidBrush lb = new SolidBrush(lockBg))
                {
                    g.FillEllipse(lb, LockButtonRect);
                }

                using (Pen shacklePen = new Pen(Color.White, 1.6f))
                using (SolidBrush bodyBrush = new SolidBrush(Color.White))
                {
                    if (Config.IsLocked)
                        g.DrawArc(shacklePen, 49, 5, 6, 7, 180, 180);
                    else
                        g.DrawArc(shacklePen, 52, 4, 6, 7, 180, 180);
                    g.FillRectangle(bodyBrush, 48, 11, 8, 6);
                }
            }
        }
    }

    public static class Program
    {
        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new LauncherOrbForm());
        }
    }
}
'@

$Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
$Params   = New-Object System.CodeDom.Compiler.CompilerParameters
$Params.GenerateExecutable = $true
$Params.OutputAssembly     = $ExePath
$Params.CompilerOptions    = "/target:winexe /optimize /win32icon:`"$IconPath`""
$Params.ReferencedAssemblies.AddRange(@(
    "System.dll",
    "System.Core.dll",
    "System.Net.dll",
    "System.Drawing.dll",
    "System.Windows.Forms.dll"
))

$Results = $Provider.CompileAssemblyFromSource($Params, $CSharpSource)

if ($Results.Errors.HasErrors) {
    Write-Host "Kompilierungsfehler aufgetreten:" -ForegroundColor Red
    foreach ($err in $Results.Errors) {
        Write-Host $err.ToString() -ForegroundColor Yellow
    }
} else {
    Write-Host "[3/3] Update erfolgreich kompiliert! Starte GoogleEcosystemHub V2..." -ForegroundColor Green
    Start-Process -FilePath $ExePath
}