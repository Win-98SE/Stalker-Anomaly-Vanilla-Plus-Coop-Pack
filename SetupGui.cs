// Stalker Anomaly Vanilla+ Coop Pack - Setup window.
// Compiled by "Build Modpack Installer.bat" with the C# compiler that ships with Windows
// (.NET Framework 4.x, C# 5 - so no $"..." strings, no ?. operator).
// The real work is done by Install-Modpack.ps1 (embedded), started hidden with -Gui.
// This file must stay saved as UTF-8 WITH BOM (it contains Ukrainian and Russian text).
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("Stalker Anomaly Vanilla+ Coop Pack Setup")]
[assembly: AssemblyProduct("Stalker Anomaly Vanilla+ Coop Pack")]
[assembly: AssemblyDescription("Downloads and installs the Vanilla+ Coop Pack mods from their original pages")]

namespace VanillaPlusCoopSetup
{
    // ------------------------------------------------------------------------ texts
    static class Tr
    {
        public static int Lang;   // 0 = English, 1 = Ukrainian, 2 = Russian
        public static readonly string[] Codes = { "en", "uk", "ru" };

        static readonly Dictionary<string, string[]> T = new Dictionary<string, string[]>
        {
            { "title", new[] { "Stalker Anomaly Vanilla+ Coop Pack Setup", "Встановлення Stalker Anomaly Vanilla+ Coop Pack", "Установка Stalker Anomaly Vanilla+ Coop Pack" } },
            { "lang_title", new[] { "Setup language", "Мова інсталятора", "Язык установщика" } },
            { "lang_sub", new[] { "Choose the language for this installer.", "Оберіть мову цього інсталятора.", "Выберите язык этого установщика." } },
            { "btn_next", new[] { "Next >", "Далі >", "Далее >" } },
            { "btn_back", new[] { "< Back", "< Назад", "< Назад" } },
            { "btn_cancel", new[] { "Cancel", "Скасувати", "Отмена" } },
            { "btn_install", new[] { "Install", "Встановити", "Установить" } },
            { "btn_update", new[] { "Update", "Оновити", "Обновить" } },
            { "btn_finish", new[] { "Finish", "Готово", "Готово" } },
            { "btn_close", new[] { "Close", "Закрити", "Закрыть" } },
            { "btn_browse", new[] { "Browse...", "Огляд...", "Обзор..." } },

            { "p1_title", new[] { "Choose install location", "Вибір папки встановлення", "Выбор папки установки" } },
            { "p1_sub", new[] { "Select the folder for Anomaly and the Vanilla+ Coop Pack.", "Оберіть папку для Anomaly та Vanilla+ Coop Pack.", "Выберите папку для Anomaly и Vanilla+ Coop Pack." } },
            { "p1_intro", new[] { "Pick an EMPTY folder for a new install, or a folder that already has Anomaly 1.5.3 (or this pack) in it.",
                                  "Оберіть ПОРОЖНЮ папку для нового встановлення або папку, де вже є Anomaly 1.5.3 (чи ця збірка).",
                                  "Выберите ПУСТУЮ папку для новой установки или папку, где уже есть Anomaly 1.5.3 (или эта сборка)." } },
            { "p1_note", new[] { "Avoid Program Files - Windows protects it. A path like D:\\Games\\Anomaly Coop is ideal.",
                                 "Уникайте Program Files - Windows її захищає. Ідеально підійде шлях на кшталт D:\\Games\\Anomaly Coop.",
                                 "Избегайте Program Files - Windows её защищает. Идеально подойдёт путь вроде D:\\Games\\Anomaly Coop." } },
            { "browse_desc", new[] { "Choose the folder for Anomaly and the Vanilla+ Coop Pack", "Оберіть папку для Anomaly та Vanilla+ Coop Pack", "Выберите папку для Anomaly и Vanilla+ Coop Pack" } },
            { "fi_fullpath", new[] { "Type a full path, like D:\\Games\\Anomaly Coop", "Введіть повний шлях, наприклад D:\\Games\\Anomaly Coop", "Введите полный путь, например D:\\Games\\Anomaly Coop" } },
            { "fi_space", new[] { "Space available on {0}  {1:N0} GB", "Вільно на {0}  {1:N0} ГБ", "Свободно на {0}  {1:N0} ГБ" } },
            { "fi_anomaly", new[] { "Anomaly was found in this folder. The pack will be installed into it.", "У цій папці знайдено Anomaly. Збірку буде встановлено в неї.", "В этой папке найдена Anomaly. Сборка будет установлена в неё." } },
            { "fi_update", new[] { "Vanilla+ Coop Pack {0} is installed here. Setup will update it to {1}.", "Тут встановлено Vanilla+ Coop Pack {0}. Інсталятор оновить її до {1}.", "Здесь установлена Vanilla+ Coop Pack {0}. Установщик обновит её до {1}." } },
            { "fi_same", new[] { "Vanilla+ Coop Pack {0} is already installed here. Setup will check and repair it.", "Тут уже встановлено Vanilla+ Coop Pack {0}. Інсталятор перевірить і відновить її.", "Здесь уже установлена Vanilla+ Coop Pack {0}. Установщик проверит и восстановит её." } },
            { "fi_older", new[] { "Warning: a NEWER version ({0}) is installed here than this Setup ({1}).", "Увага: тут встановлено НОВІШУ версію ({0}), ніж у цьому інсталяторі ({1}).", "Внимание: здесь установлена БОЛЕЕ НОВАЯ версия ({0}), чем в этом установщике ({1})." } },
            { "fi_new", new[] { "This folder will be created. Next you choose where Anomaly comes from.", "Цю папку буде створено. Далі ви оберете, звідки взяти Anomaly.", "Эта папка будет создана. Далее вы выберете, откуда взять Anomaly." } },
            { "fi_empty", new[] { "This folder is empty. Next you choose where Anomaly comes from.", "Ця папка порожня. Далі ви оберете, звідки взяти Anomaly.", "Эта папка пуста. Далее вы выберете, откуда взять Anomaly." } },
            { "fi_notempty", new[] { "Warning: this folder is not empty and has no Anomaly in it. An empty folder is safer.", "Увага: ця папка не порожня і в ній немає Anomaly. Безпечніше обрати порожню папку.", "Внимание: эта папка не пуста и в ней нет Anomaly. Безопаснее выбрать пустую папку." } },
            { "fi_needs", new[] { "Needs about 25 GB, or about 55 GB if Anomaly is downloaded too.", "Потрібно близько 25 ГБ, або близько 55 ГБ, якщо також завантажувати Anomaly.", "Нужно около 25 ГБ, или около 55 ГБ, если также скачивать Anomaly." } },
            { "msg_fullpath", new[] { "Type a full folder path, like D:\\Games\\Anomaly Coop.", "Введіть повний шлях до папки, наприклад D:\\Games\\Anomaly Coop.", "Введите полный путь к папке, например D:\\Games\\Anomaly Coop." } },

            { "p2_title", new[] { "S.T.A.L.K.E.R. Anomaly 1.5.3", "S.T.A.L.K.E.R. Anomaly 1.5.3", "S.T.A.L.K.E.R. Anomaly 1.5.3" } },
            { "p2_sub", new[] { "Choose where the base game comes from.", "Оберіть, звідки взяти базову гру.", "Выберите, откуда взять базовую игру." } },
            { "r_gog", new[] { "Use my GOG copy of Anomaly", "Використати мою копію Anomaly з GOG", "Использовать мою копию Anomaly из GOG" } },
            { "gog_found", new[] { "{0}\n(the pack is installed into your GOG folder)", "{0}\n(збірку буде встановлено у вашу папку GOG)", "{0}\n(сборка будет установлена в вашу папку GOG)" } },
            { "gog_none", new[] { "No GOG copy found. Anomaly is free on GOG - install it there, then press 'Check again'.",
                                  "Копію з GOG не знайдено. Anomaly безкоштовна в GOG - встановіть її там і натисніть «Перевірити знову».",
                                  "Копия из GOG не найдена. Anomaly бесплатна в GOG - установите её там и нажмите «Проверить снова»." } },
            { "btn_gog_get", new[] { "Get it free on GOG", "Отримати безкоштовно в GOG", "Получить бесплатно в GOG" } },
            { "btn_gog_check", new[] { "Check again", "Перевірити знову", "Проверить снова" } },
            { "gog_info", new[] { "Install Anomaly from GOG (it's free), then come back and press 'Check again'.",
                                  "Встановіть Anomaly з GOG (це безкоштовно), потім поверніться й натисніть «Перевірити знову».",
                                  "Установите Anomaly из GOG (это бесплатно), затем вернитесь и нажмите «Проверить снова»." } },
            { "r_moddb", new[] { "Download Anomaly 1.5.3 from ModDB into {0}", "Завантажити Anomaly 1.5.3 з ModDB у {0}", "Скачать Anomaly 1.5.3 с ModDB в {0}" } },
            { "moddb_info", new[] { "9.1 GB. ModDB may only allow it in your browser - a page opens and the download starts by itself.",
                                    "9,1 ГБ. ModDB може дозволити це лише через браузер - відкриється сторінка, і завантаження почнеться саме.",
                                    "9,1 ГБ. ModDB может разрешить это только через браузер - откроется страница, и загрузка начнётся сама." } },
            { "chk_delete", new[] { "Delete the 9.1 GB download when done", "Видалити завантажений архів (9,1 ГБ) після встановлення", "Удалить скачанный архив (9,1 ГБ) после установки" } },
            { "r_other", new[] { "Use an Anomaly 1.5.3 folder somewhere else", "Використати папку з Anomaly 1.5.3 в іншому місці", "Использовать папку с Anomaly 1.5.3 в другом месте" } },
            { "other_desc", new[] { "Choose your Anomaly 1.5.3 folder (the one with AnomalyLauncher.exe)", "Оберіть вашу папку Anomaly 1.5.3 (ту, де є AnomalyLauncher.exe)", "Выберите вашу папку Anomaly 1.5.3 (ту, где есть AnomalyLauncher.exe)" } },
            { "msg_no_anomaly", new[] { "No Anomaly found in that folder. Pick the folder that has AnomalyLauncher.exe, bin and db in it.",
                                        "У цій папці немає Anomaly. Оберіть папку, де є AnomalyLauncher.exe, bin і db.",
                                        "В этой папке нет Anomaly. Выберите папку, где есть AnomalyLauncher.exe, bin и db." } },
            { "msg_admin", new[] { "Windows does not allow changes in\n{0}\n\nRestart Setup as administrator?", "Windows не дозволяє змінювати\n{0}\n\nПерезапустити інсталятор від імені адміністратора?", "Windows не разрешает изменять\n{0}\n\nПерезапустить установщик от имени администратора?" } },
            { "msg_close_mo2", new[] { "Close Mod Organizer and the game first, then press Install again.", "Спочатку закрийте Mod Organizer і гру, потім натисніть «Встановити» ще раз.", "Сначала закройте Mod Organizer и игру, затем нажмите «Установить» ещё раз." } },

            { "p3_install", new[] { "Installing", "Встановлення", "Установка" } },
            { "p3_update", new[] { "Updating", "Оновлення", "Обновление" } },
            { "p3_sub", new[] { "Please wait while Setup downloads and installs the mods. This can take a while.", "Зачекайте, поки інсталятор завантажує та встановлює моди. Це може зайняти деякий час.", "Подождите, пока установщик скачивает и устанавливает моды. Это может занять некоторое время." } },
            { "st_starting", new[] { "Starting...", "Запуск...", "Запуск..." } },
            { "browser_text", new[] { "Waiting for downloads in your browser ({0}). Their pages are open and most start by themselves - save them to your Downloads folder. Still missing:",
                                      "Очікування завантажень у браузері ({0}). Сторінки відкрито, більшість завантажень почнеться саме - зберігайте файли в папку «Завантаження». Ще бракує:",
                                      "Ожидание загрузок в браузере ({0}). Страницы открыты, большинство загрузок начнётся само - сохраняйте файлы в папку «Загрузки». Ещё не хватает:" } },
            { "btn_reopen", new[] { "Open pages again", "Відкрити сторінки знову", "Открыть страницы снова" } },
            { "btn_skip", new[] { "Skip these", "Пропустити ці", "Пропустить эти" } },
            { "ask_skip", new[] { "Skip the downloads that are still missing? Those mods won't be installed - you can run Setup again later to add them.",
                                  "Пропустити завантаження, яких ще бракує? Ці моди не буде встановлено - ви зможете запустити інсталятор пізніше, щоб їх додати.",
                                  "Пропустить загрузки, которых ещё не хватает? Эти моды не будут установлены - вы сможете запустить установщик позже, чтобы их добавить." } },
            { "log_target", new[] { "Installing to: {0}", "Встановлення в: {0}", "Установка в: {0}" } },
            { "err_ps", new[] { "Could not start PowerShell: {0}", "Не вдалося запустити PowerShell: {0}", "Не удалось запустить PowerShell: {0}" } },
            { "err_unexpected", new[] { "The installer stopped unexpectedly (exit code {0}). See the log above.", "Інсталятор несподівано зупинився (код {0}). Дивіться журнал вище.", "Установщик неожиданно остановился (код {0}). Смотрите журнал выше." } },
            { "st_stopped", new[] { "Stopped", "Зупинено", "Остановлено" } },
            { "log_error", new[] { "Error: {0}", "Помилка: {0}", "Ошибка: {0}" } },
            { "log_fix", new[] { "Fix the problem and run Setup again - finished downloads are kept.", "Усуньте проблему й запустіть інсталятор знову - готові завантаження зберігаються.", "Устраните проблему и запустите установщик снова - готовые загрузки сохраняются." } },
            { "ask_stop", new[] { "The installer is still running. Stop it?\n(You can run Setup again later - finished downloads are kept.)",
                                  "Інсталятор ще працює. Зупинити?\n(Ви зможете запустити його пізніше - готові завантаження зберігаються.)",
                                  "Установщик ещё работает. Остановить?\n(Вы сможете запустить его позже - готовые загрузки сохраняются.)" } },

            { "btn_readme", new[] { "Open README", "Відкрити README", "Открыть README" } },
            { "btn_folder", new[] { "Open folder", "Відкрити папку", "Открыть папку" } },
            { "btn_launch", new[] { "Launch Mod Organizer", "Запустити Mod Organizer", "Запустить Mod Organizer" } },
            { "err_launch", new[] { "Could not start Mod Organizer: {0}", "Не вдалося запустити Mod Organizer: {0}", "Не удалось запустить Mod Organizer: {0}" } },
            { "done_title", new[] { "Setup complete", "Встановлення завершено", "Установка завершена" } },
            { "done_title_upd", new[] { "Update complete", "Оновлення завершено", "Обновление завершено" } },
            { "done_sub", new[] { "The Stalker Anomaly Vanilla+ Coop Pack is ready.", "Stalker Anomaly Vanilla+ Coop Pack готова до гри.", "Stalker Anomaly Vanilla+ Coop Pack готова к игре." } },
            { "done_head", new[] { "Setup has finished.", "Інсталятор завершив роботу.", "Установщик завершил работу." } },
            { "done_text", new[] {
                "A 'Stalker Anomaly Vanilla+ Coop Pack' shortcut is on your desktop.\n\n1. Start Mod Organizer (button below or the shortcut).\n2. Pick 'Anomaly (DX11-AVX)' or 'Anomaly (DX11)' and press Run.\n3. In the game: Options > Video for resolution, Options > Controls for keys and mouse,\n    and set your co-op player name.\n\nInstalled in: {0}",
                "На робочому столі є ярлик «Stalker Anomaly Vanilla+ Coop Pack».\n\n1. Запустіть Mod Organizer (кнопка нижче або ярлик).\n2. Оберіть «Anomaly (DX11-AVX)» або «Anomaly (DX11)» і натисніть Run.\n3. У грі: Options > Video - роздільна здатність, Options > Controls - клавіші й миша,\n    а також вкажіть своє ім'я для кооперативу.\n\nВстановлено в: {0}",
                "На рабочем столе есть ярлык «Stalker Anomaly Vanilla+ Coop Pack».\n\n1. Запустите Mod Organizer (кнопка ниже или ярлык).\n2. Выберите «Anomaly (DX11-AVX)» или «Anomaly (DX11)» и нажмите Run.\n3. В игре: Options > Video - разрешение, Options > Controls - клавиши и мышь,\n    а также укажите своё имя для кооператива.\n\nУстановлено в: {0}" } },
            { "prob_title", new[] { "Setup finished with problems", "Встановлення завершено з проблемами", "Установка завершена с проблемами" } },
            { "prob_sub", new[] { "Some parts of the pack could not be installed.", "Деякі частини збірки не вдалося встановити.", "Некоторые части сборки не удалось установить." } },
            { "prob_head", new[] { "Installed, but some things went wrong:", "Встановлено, але дещо пішло не так:", "Установлено, но кое-что пошло не так:" } },
            { "prob_retry", new[] { "Run Setup again to retry (finished downloads are kept), or send this list to the pack owner.",
                                    "Запустіть інсталятор знову, щоб повторити спробу (готові завантаження зберігаються), або надішліть цей список автору збірки.",
                                    "Запустите установщик снова, чтобы повторить попытку (готовые загрузки сохраняются), или отправьте этот список автору сборки." } },

            { "upd_avail", new[] { "A newer version of the pack is available: {0}\n(this Setup is {1}).\n\nEveryone playing co-op together should use the same version.\nOpen the download page?",
                                   "Доступна новіша версія збірки: {0}\n(цей інсталятор - {1}).\n\nУсім, хто грає разом у кооперативі, варто мати однакову версію.\nВідкрити сторінку завантаження?",
                                   "Доступна более новая версия сборки: {0}\n(этот установщик - {1}).\n\nВсем, кто играет вместе в кооперативе, стоит иметь одинаковую версию.\nОткрыть страницу загрузки?" } },
            { "upd_link", new[] { "Newer version available: {0}", "Доступна новіша версія: {0}", "Доступна более новая версия: {0}" } },
        };

        public static string L(string key)
        {
            string[] v;
            if (!T.TryGetValue(key, out v)) return key;
            return v[Lang];
        }
        public static string L(string key, params object[] args)
        {
            return string.Format(L(key), args);
        }
    }

    // ------------------------------------------------------------------------ look
    static class Theme
    {
        public static readonly Color Back = SystemColors.Control;
        public static readonly Color Field = SystemColors.Window;
        public static readonly Color Text = SystemColors.ControlText;
        public static readonly Color Dim = SystemColors.GrayText;
        public static readonly Color Amber = Color.FromArgb(156, 87, 0);
        public static readonly Color Red = Color.FromArgb(176, 28, 28);
        public static readonly Color Ok = Color.FromArgb(16, 112, 40);
        public static readonly Font UI = new Font("Segoe UI", 9f);
        public static readonly Font UIBold = new Font("Segoe UI", 9f, FontStyle.Bold);
        public static readonly Font LogFont = new Font("Consolas", 9f);

        public static void DrawTrefoil(Graphics g, float cx, float cy, float r, Color fg, Color bg)
        {
            using (SolidBrush b = new SolidBrush(fg))
            using (SolidBrush k = new SolidBrush(bg))
            {
                RectangleF outer = new RectangleF(cx - r, cy - r, r * 2, r * 2);
                for (int i = 0; i < 3; i++) g.FillPie(b, outer.X, outer.Y, outer.Width, outer.Height, -90 - 30 + i * 120, 60);
                float ri = r * 0.30f;
                g.FillEllipse(k, cx - ri, cy - ri, ri * 2, ri * 2);
                float rc = r * 0.18f;
                g.FillEllipse(b, cx - rc, cy - rc, rc * 2, rc * 2);
            }
        }
    }

    class WizButton : Button
    {
        public WizButton(string text)
        {
            Text = text;
            FlatStyle = FlatStyle.System;
            Font = Theme.UI;
            AutoSize = true;
            AutoSizeMode = AutoSizeMode.GrowOnly;
            MinimumSize = new Size(88, 26);
            UseVisualStyleBackColor = true;
        }
    }

    class WizProgress : ProgressBar
    {
        public WizProgress() { Height = 20; Minimum = 0; Style = ProgressBarStyle.Continuous; }
        public void Set(int value, int max)
        {
            Maximum = Math.Max(1, max);
            Value = Math.Max(0, Math.Min(value, Maximum));
        }
    }

    class Banner : Control
    {
        private string _title = "", _sub = "";
        public Banner()
        {
            DoubleBuffered = true;
            Height = 64;
            Dock = DockStyle.Top;
            BackColor = SystemColors.Window;
        }
        public void SetText(string title, string sub) { _title = title; _sub = sub; Invalidate(); }
        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.Clear(SystemColors.Window);
            TextRenderer.DrawText(g, _title, Theme.UIBold, new Point(20, 12), SystemColors.WindowText);
            TextRenderer.DrawText(g, _sub, Theme.UI, new Rectangle(34, 32, Width - 120, 28), SystemColors.WindowText,
                TextFormatFlags.Left | TextFormatFlags.WordBreak | TextFormatFlags.EndEllipsis);
            Theme.DrawTrefoil(g, Width - 40, Height / 2f, 20, Color.FromArgb(40, 40, 40), SystemColors.Window);
            using (Pen ring = new Pen(Color.FromArgb(230, 180, 0), 3)) g.DrawEllipse(ring, Width - 64, Height / 2f - 24, 48, 48);
            g.DrawLine(SystemPens.ControlDark, 0, Height - 2, Width, Height - 2);
            g.DrawLine(SystemPens.ControlLightLight, 0, Height - 1, Width, Height - 1);
        }
    }

    static class Msg
    {
        public static bool YesNo(IWin32Window owner, string msg)
        {
            return MessageBox.Show(owner, msg, Tr.L("title"), MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes;
        }
        public static void Info(IWin32Window owner, string msg)
        {
            MessageBox.Show(owner, msg, Tr.L("title"), MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }

    // ------------------------------------------------------------------------ the wizard
    class SetupForm : Form
    {
        const string GogProductId = "1700809445";
        const string GogPage = "https://www.gog.com/en/game/stalker_anomaly";

        readonly string _payloadDir;
        readonly string _version;     // "2026-11-16 09:29" (from modpack.json)
        readonly string _github;      // "owner/repo" for the update check
        int _page;
        string _root;                 // final Anomaly folder
        string _folderText;           // kept when the pages are rebuilt for another language
        bool _installBase, _deleteBase, _isUpdate;
        Process _proc;
        bool _finished, _failed;
        readonly List<string> _problems = new List<string>();
        string _newerTag, _newerUrl;
        bool _newerShown;

        WizButton _back, _next, _cancel;
        LinkLabel _updLink;
        Banner _banner;
        Panel _footer;

        // page 0
        Panel _p0; RadioButton[] _langRadios;
        // page 1
        Panel _p1; TextBox _folder; Label _folderInfo;
        // page 2
        Panel _p2; RadioButton _rGog, _rModdb, _rOther; Label _gogInfo; WizButton _gogGet, _gogCheck;
        CheckBox _delArchive; TextBox _otherPath;
        // page 3
        Panel _p3; Label _status, _count; WizProgress _bar; Panel _browserBox; Label _browserText;
        RichTextBox _log;
        // page 4
        Panel _p4; Label _doneTitle, _doneText;

        public SetupForm(string payloadDir, string version, string github, string presetTarget)
        {
            _payloadDir = payloadDir;
            _version = version;
            _github = github;
            _folderText = presetTarget;
            try
            {
                using (Stream ic = Assembly.GetExecutingAssembly().GetManifestResourceStream("setup.ico"))
                    if (ic != null) Icon = new Icon(ic);
                    else Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            }
            catch { }
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Theme.Back;
            Font = Theme.UI;
            ClientSize = new Size(760, 540);

            Controls.Add(BuildFooter());
            _banner = new Banner();
            Controls.Add(_banner);

            // default language: the Windows display language
            string ui = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
            Tr.Lang = ui == "uk" ? 1 : (ui == "ru" ? 2 : 0);
            BuildPage0();
            ShowPage(0);
            Shown += delegate { StartUpdateCheck(); };
        }

        // ---------------------------------------------------------------- helpers
        static Label MakeLabel(string text, Color color, Font font)
        {
            Label l = new Label();
            l.Text = text; l.ForeColor = color; l.Font = font; l.BackColor = Color.Transparent;
            l.AutoSize = false;
            return l;
        }
        static TextBox MakeBox()
        {
            TextBox t = new TextBox();
            t.BackColor = Theme.Field; t.ForeColor = Theme.Text; t.Font = Theme.UI;
            t.BorderStyle = BorderStyle.Fixed3D;
            return t;
        }
        static RadioButton MakeRadio(string text)
        {
            RadioButton r = new RadioButton();
            r.Text = text; r.ForeColor = Theme.Text; r.Font = Theme.UI;
            r.FlatStyle = FlatStyle.System; r.AutoSize = true;
            return r;
        }
        Panel NewPage()
        {
            Panel p = new Panel();
            p.SetBounds(26, 82, 708, 384);
            p.BackColor = Theme.Back;
            p.Visible = false;
            Controls.Add(p);
            p.BringToFront();
            return p;
        }
        static string Date10(string v)
        {
            Match m = Regex.Match(v ?? "", @"\d{4}-\d{2}-\d{2}");
            return m.Success ? m.Value : "";
        }

        Control BuildFooter()
        {
            _footer = new Panel();
            Panel f = _footer;
            f.Dock = DockStyle.Bottom; f.Height = 52; f.BackColor = Theme.Back;
            f.Paint += delegate(object s, PaintEventArgs e)
            {
                e.Graphics.DrawLine(SystemPens.ControlDark, 10, 2, f.Width - 10, 2);
                e.Graphics.DrawLine(SystemPens.ControlLightLight, 10, 3, f.Width - 10, 3);
                if (!_updLink.Visible)
                    TextRenderer.DrawText(e.Graphics, "Vanilla+ Coop Pack  " + _version, Theme.UI, new Point(14, 20), SystemColors.GrayText);
            };
            _cancel = new WizButton("Cancel");
            _back = new WizButton("< Back");
            _next = new WizButton("Next >");
            _updLink = new LinkLabel();
            _updLink.AutoSize = true; _updLink.Location = new Point(14, 20); _updLink.Visible = false; _updLink.Font = Theme.UIBold;
            _updLink.LinkClicked += delegate { OpenUrl(_newerUrl); };
            f.Controls.Add(_cancel); f.Controls.Add(_back); f.Controls.Add(_next); f.Controls.Add(_updLink);
            f.Layout += delegate
            {
                int x = f.Width - 24;
                foreach (WizButton b in new WizButton[] { _cancel, _next, _back })
                {
                    if (!b.Visible) continue;
                    int w = Math.Max(88, b.PreferredSize.Width);
                    x -= w; b.Location = new Point(x, 15);
                    x -= (b == _cancel ? 18 : 2);
                }
            };
            _cancel.Click += delegate { Close(); };
            _back.Click += delegate { if (_page == 1) ShowPage(0); else if (_page == 2) ShowPage(1); };
            _next.Click += delegate { OnNext(); };
            return f;
        }

        void ApplyChrome()
        {
            Text = Tr.L("title");
            _back.Text = Tr.L("btn_back");
            _cancel.Text = (_page == 3 && _failed) ? Tr.L("btn_close") : Tr.L("btn_cancel");
            if (_newerTag != null) _updLink.Text = Tr.L("upd_link", _newerTag);
        }

        void ShowPage(int n)
        {
            _page = n;
            Panel[] pages = { _p0, _p1, _p2, _p3, _p4 };
            for (int i = 0; i < pages.Length; i++) if (pages[i] != null) pages[i].Visible = i == n;
            ApplyChrome();
            _back.Visible = n == 1 || n == 2;
            _next.Visible = n <= 2 || n == 4;
            _cancel.Visible = n != 4;
            if (n == 0) { _banner.SetText(Tr.L("lang_title") + "  /  Мова  /  Язык", Tr.L("lang_sub")); _next.Text = Tr.L("btn_next"); }
            if (n == 1) { _banner.SetText(Tr.L("p1_title"), Tr.L("p1_sub")); _next.Text = Tr.L("btn_next"); UpdateFolderInfo(); }
            if (n == 2) { _banner.SetText(Tr.L("p2_title"), Tr.L("p2_sub")); _next.Text = Tr.L("btn_install"); RefreshSourcePage(); }
            if (n == 3) { _banner.SetText(Tr.L(_isUpdate ? "p3_update" : "p3_install"), Tr.L("p3_sub")); }
            if (n == 4) { _next.Text = Tr.L("btn_finish"); }
            AcceptButton = _next.Visible ? _next : null;
            _footer.PerformLayout();
            _footer.Invalidate();
        }

        // ---------------------------------------------------------------- page 0: language
        void BuildPage0()
        {
            _p0 = NewPage();
            Label l = MakeLabel("Select a language  /  Оберіть мову  /  Выберите язык:", Theme.Text, Theme.UI);
            l.SetBounds(0, 0, 700, 24);
            _p0.Controls.Add(l);
            string[] names = { "English", "Українська", "Русский" };
            _langRadios = new RadioButton[3];
            for (int i = 0; i < 3; i++)
            {
                RadioButton r = MakeRadio(names[i]);
                r.Location = new Point(20, 40 + i * 34);
                r.Checked = i == Tr.Lang;
                int idx = i;
                r.CheckedChanged += delegate { if (r.Checked) { Tr.Lang = idx; ShowPage(0); } };
                _langRadios[i] = r;
                _p0.Controls.Add(r);
            }
        }

        void BuildLanguagePages()
        {
            // (re)build pages 1-4 in the chosen language
            if (_folder != null) _folderText = _folder.Text;
            foreach (Panel p in new Panel[] { _p1, _p2, _p3, _p4 }) if (p != null) { Controls.Remove(p); p.Dispose(); }
            BuildPage1(); BuildPage2(); BuildPage3(); BuildPage4();
        }

        // ---------------------------------------------------------------- page 1: folder
        void BuildPage1()
        {
            _p1 = NewPage();
            Label l = MakeLabel(Tr.L("p1_intro"), Theme.Text, Theme.UI);
            l.SetBounds(0, 0, 700, 40);
            _folder = MakeBox(); _folder.SetBounds(0, 48, 590, 24);
            WizButton browse = new WizButton(Tr.L("btn_browse"));
            browse.Location = new Point(600, 47);
            _folderInfo = MakeLabel("", Theme.Dim, Theme.UI); _folderInfo.SetBounds(0, 88, 700, 150);
            Label note = MakeLabel(Tr.L("p1_note"), Theme.Dim, Theme.UI);
            note.SetBounds(0, 330, 700, 40);
            _p1.Controls.Add(l); _p1.Controls.Add(_folder); _p1.Controls.Add(browse); _p1.Controls.Add(_folderInfo); _p1.Controls.Add(note);

            browse.Click += delegate
            {
                using (FolderBrowserDialog d = new FolderBrowserDialog())
                {
                    d.Description = Tr.L("browse_desc");
                    d.ShowNewFolderButton = true;
                    if (Directory.Exists(_folder.Text)) d.SelectedPath = _folder.Text;
                    if (d.ShowDialog(this) == DialogResult.OK) _folder.Text = d.SelectedPath;
                }
            };
            _folder.TextChanged += delegate { UpdateFolderInfo(); };

            string def = _folderText;
            if (string.IsNullOrEmpty(def))
            {
                string exeDir = Path.GetDirectoryName(Application.ExecutablePath);
                if (IsAnomalyDir(exeDir)) def = exeDir;
                else def = Path.Combine(BestDrive(), "Games\\Anomaly Coop");
            }
            _folder.Text = def;
        }

        static string BestDrive()
        {
            string best = "C:\\"; long free = -1;
            foreach (DriveInfo d in DriveInfo.GetDrives())
            {
                try
                {
                    if (d.DriveType != DriveType.Fixed || !d.IsReady) continue;
                    if (d.AvailableFreeSpace > free) { free = d.AvailableFreeSpace; best = d.RootDirectory.FullName; }
                }
                catch { }
            }
            return best;
        }

        static bool IsAnomalyDir(string d)
        {
            try
            {
                return !string.IsNullOrEmpty(d) && File.Exists(Path.Combine(d, "AnomalyLauncher.exe"))
                    && Directory.Exists(Path.Combine(d, "bin")) && Directory.Exists(Path.Combine(d, "db"));
            }
            catch { return false; }
        }

        static string CleanPath(string p)
        {
            p = (p ?? "").Trim().Trim('"');
            while (p.Length > 3 && (p.EndsWith("\\") || p.EndsWith("/"))) p = p.Substring(0, p.Length - 1);
            return p;
        }

        // version of the pack installed in a folder ("" if none)
        static string InstalledVersion(string dir)
        {
            try
            {
                string f = Path.Combine(dir, "modpack_installed.json");
                if (!File.Exists(f)) return "";
                Match m = Regex.Match(File.ReadAllText(f), "\"created\"\\s*:\\s*\"([^\"]+)\"");
                return m.Success ? m.Groups[1].Value : "";
            }
            catch { return ""; }
        }

        void UpdateFolderInfo()
        {
            if (_folderInfo == null) return;
            string p = CleanPath(_folder.Text);
            StringBuilder sb = new StringBuilder();
            _folderInfo.ForeColor = Theme.Text;
            try
            {
                if (!Path.IsPathRooted(p)) { _folderInfo.Text = Tr.L("fi_fullpath"); _folderInfo.ForeColor = Theme.Amber; return; }
                DriveInfo di = new DriveInfo(Path.GetPathRoot(p));
                if (di.IsReady) sb.AppendLine(Tr.L("fi_space", di.Name, di.AvailableFreeSpace / 1073741824.0));
                sb.AppendLine();
                if (IsAnomalyDir(p))
                {
                    string inst = InstalledVersion(p);
                    if (inst.Length == 0) sb.AppendLine(Tr.L("fi_anomaly"));
                    else
                    {
                        int c = string.CompareOrdinal(inst, _version);
                        if (c < 0) sb.AppendLine(Tr.L("fi_update", inst, _version));
                        else if (c == 0) sb.AppendLine(Tr.L("fi_same", inst));
                        else { sb.AppendLine(Tr.L("fi_older", inst, _version)); _folderInfo.ForeColor = Theme.Amber; }
                    }
                }
                else if (!Directory.Exists(p)) sb.AppendLine(Tr.L("fi_new"));
                else if (Directory.GetFileSystemEntries(p).Length == 0) sb.AppendLine(Tr.L("fi_empty"));
                else { sb.AppendLine(Tr.L("fi_notempty")); _folderInfo.ForeColor = Theme.Amber; }
                sb.AppendLine();
                sb.AppendLine(Tr.L("fi_needs"));
            }
            catch (Exception ex) { sb.AppendLine(ex.Message); _folderInfo.ForeColor = Theme.Amber; }
            _folderInfo.Text = sb.ToString();
            if (_page == 1)
            {
                bool upd = IsAnomalyDir(p) && InstalledVersion(p).Length > 0;
                _next.Text = upd ? Tr.L("btn_update") : (IsAnomalyDir(p) ? Tr.L("btn_install") : Tr.L("btn_next"));
                _footer.PerformLayout();
            }
        }

        // ---------------------------------------------------------------- page 2: where Anomaly comes from
        void BuildPage2()
        {
            _p2 = NewPage();
            _rGog = MakeRadio(Tr.L("r_gog")); _rGog.Location = new Point(0, 0);
            _gogInfo = MakeLabel("", Theme.Dim, Theme.UI); _gogInfo.SetBounds(22, 26, 680, 36);
            _gogGet = new WizButton(Tr.L("btn_gog_get")); _gogGet.Location = new Point(22, 62);
            _gogCheck = new WizButton(Tr.L("btn_gog_check")); _gogCheck.Location = new Point(260, 62);

            _rModdb = MakeRadio(Tr.L("r_moddb", "")); _rModdb.Location = new Point(0, 116);
            Label moddbInfo = MakeLabel(Tr.L("moddb_info"), Theme.Dim, Theme.UI);
            moddbInfo.SetBounds(22, 142, 680, 36);
            _delArchive = new CheckBox();
            _delArchive.Text = Tr.L("chk_delete"); _delArchive.Checked = true;
            _delArchive.Font = Theme.UI; _delArchive.FlatStyle = FlatStyle.System;
            _delArchive.AutoSize = true; _delArchive.Location = new Point(22, 178);

            _rOther = MakeRadio(Tr.L("r_other")); _rOther.Location = new Point(0, 224);
            _otherPath = MakeBox(); _otherPath.SetBounds(22, 252, 568, 24);
            WizButton otherBrowse = new WizButton(Tr.L("btn_browse")); otherBrowse.Location = new Point(600, 251);

            foreach (Control c in new Control[] { _rGog, _gogInfo, _gogGet, _gogCheck, _rModdb, moddbInfo, _delArchive, _rOther, _otherPath, otherBrowse })
                _p2.Controls.Add(c);

            _gogGet.Click += delegate { OpenUrl(GogPage); Msg.Info(this, Tr.L("gog_info")); };
            _gogCheck.Click += delegate { RefreshSourcePage(); };
            otherBrowse.Click += delegate
            {
                using (FolderBrowserDialog d = new FolderBrowserDialog())
                {
                    d.Description = Tr.L("other_desc");
                    if (d.ShowDialog(this) == DialogResult.OK) { _otherPath.Text = d.SelectedPath; _rOther.Checked = true; }
                }
            };
            _otherPath.TextChanged += delegate { if (_otherPath.Focused) _rOther.Checked = true; };
        }

        static string FindGog()
        {
            string[] keys = { "SOFTWARE\\WOW6432Node\\GOG.com\\Games\\" + GogProductId, "SOFTWARE\\GOG.com\\Games\\" + GogProductId };
            foreach (string k in keys)
            {
                try
                {
                    using (RegistryKey rk = Registry.LocalMachine.OpenSubKey(k))
                    {
                        if (rk == null) continue;
                        string p = rk.GetValue("path") as string;
                        if (p != null && IsAnomalyDir(p)) return CleanPath(p);
                    }
                }
                catch { }
            }
            return null;
        }

        void RefreshSourcePage()
        {
            string gog = FindGog();
            _rGog.Enabled = gog != null;
            _rGog.Tag = gog;
            if (gog != null)
            {
                _gogInfo.Text = Tr.L("gog_found", gog);
                _gogGet.Visible = false; _gogCheck.Visible = false;
            }
            else
            {
                _gogInfo.Text = Tr.L("gog_none");
                _gogGet.Visible = true; _gogCheck.Visible = true;
                if (_rGog.Checked) _rModdb.Checked = true;
            }
            _rModdb.Text = Tr.L("r_moddb", CleanPath(_folder.Text));
            if (!_rGog.Checked && !_rModdb.Checked && !_rOther.Checked) { if (gog != null) _rGog.Checked = true; else _rModdb.Checked = true; }
        }

        // ---------------------------------------------------------------- next / validation
        void OnNext()
        {
            if (_page == 4) { Close(); return; }
            if (_page == 0) { BuildLanguagePages(); ShowPage(1); return; }
            if (_page == 1)
            {
                string p = CleanPath(_folder.Text);
                if (!Path.IsPathRooted(p)) { Msg.Info(this, Tr.L("msg_fullpath")); return; }
                if (IsAnomalyDir(p)) { _root = p; _installBase = false; StartInstall(); }
                else ShowPage(2);
                return;
            }
            if (_page == 2)
            {
                if (_rGog.Checked && _rGog.Tag != null) { _root = (string)_rGog.Tag; _installBase = false; }
                else if (_rModdb.Checked) { _root = CleanPath(_folder.Text); _installBase = true; _deleteBase = _delArchive.Checked; }
                else if (_rOther.Checked)
                {
                    string o = CleanPath(_otherPath.Text);
                    if (!IsAnomalyDir(o)) { Msg.Info(this, Tr.L("msg_no_anomaly")); return; }
                    _root = o; _installBase = false;
                }
                else return;
                StartInstall();
            }
        }

        static bool CanWrite(string dir)
        {
            try
            {
                Directory.CreateDirectory(dir);
                string t = Path.Combine(dir, "_setup_write_test_" + Guid.NewGuid().ToString("N"));
                File.WriteAllText(t, "x"); File.Delete(t);
                return true;
            }
            catch { return false; }
        }

        // ---------------------------------------------------------------- page 3: progress
        void BuildPage3()
        {
            _p3 = NewPage();
            _status = MakeLabel(Tr.L("st_starting"), Theme.Text, Theme.UI); _status.SetBounds(0, 0, 600, 22);
            _count = MakeLabel("", Theme.Dim, Theme.UI); _count.TextAlign = ContentAlignment.TopRight; _count.SetBounds(600, 0, 108, 22);
            _bar = new WizProgress(); _bar.SetBounds(0, 26, 708, 22);

            _browserBox = new Panel(); _browserBox.SetBounds(0, 58, 708, 150); _browserBox.BackColor = Color.FromArgb(255, 248, 220); _browserBox.Visible = false;
            _browserBox.Paint += delegate(object s, PaintEventArgs e) { using (Pen p = new Pen(Color.FromArgb(220, 190, 110))) e.Graphics.DrawRectangle(p, 0, 0, _browserBox.Width - 1, _browserBox.Height - 1); };
            _browserText = MakeLabel("", Color.FromArgb(90, 60, 0), Theme.UI); _browserText.SetBounds(10, 6, 690, 106);
            WizButton reopen = new WizButton(Tr.L("btn_reopen")); reopen.Location = new Point(10, 114);
            WizButton skip = new WizButton(Tr.L("btn_skip"));
            _browserBox.Controls.Add(_browserText); _browserBox.Controls.Add(reopen); _browserBox.Controls.Add(skip);
            skip.Location = new Point(reopen.Right + 12, 114);
            reopen.Click += delegate { TouchFlag("reopen.flag"); };
            skip.Click += delegate { if (Msg.YesNo(this, Tr.L("ask_skip"))) TouchFlag("skip.flag"); };

            _log = new RichTextBox();
            _log.SetBounds(0, 58, 708, 322);
            _log.ReadOnly = true; _log.BackColor = Theme.Field; _log.ForeColor = Theme.Text; _log.Font = Theme.LogFont;
            _log.BorderStyle = BorderStyle.Fixed3D; _log.DetectUrls = false; _log.WordWrap = true;
            foreach (Control c in new Control[] { _status, _count, _bar, _browserBox, _log }) _p3.Controls.Add(c);
        }

        void TouchFlag(string name)
        {
            try { File.WriteAllText(Path.Combine(_payloadDir, name), "1"); } catch { }
        }

        void Log(string text, Color color)
        {
            _log.SelectionStart = _log.TextLength;
            _log.SelectionLength = 0;
            _log.SelectionColor = color;
            _log.AppendText(text + "\n");
            _log.SelectionColor = _log.ForeColor;
            _log.ScrollToCaret();
        }

        static Color ColorFor(string name)
        {
            switch (name)
            {
                case "Red": return Theme.Red;
                case "Yellow": return Theme.Amber;
                case "Green": return Theme.Ok;
                case "DarkGray": return Theme.Dim;
                default: return Theme.Text;
            }
        }

        void StartInstall()
        {
            if (!CanWrite(_root))
            {
                if (Msg.YesNo(this, Tr.L("msg_admin", _root)))
                {
                    try
                    {
                        ProcessStartInfo si = new ProcessStartInfo(Application.ExecutablePath, "\"/target:" + CleanPath(_folder.Text) + "\" /lang:" + Tr.Codes[Tr.Lang]);
                        si.Verb = "runas"; si.UseShellExecute = true;
                        Process.Start(si);
                        _finished = true;
                        Close();
                    }
                    catch { }
                }
                return;
            }
            if (Process.GetProcessesByName("ModOrganizer").Length > 0) { Msg.Info(this, Tr.L("msg_close_mo2")); return; }
            _isUpdate = !_installBase && InstalledVersion(_root).Length > 0;
            ShowPage(3);
            Log(Tr.L("log_target", _root), Theme.Dim);
            string ps = Path.Combine(Environment.SystemDirectory, "WindowsPowerShell\\v1.0\\powershell.exe");
            string script = Path.Combine(_payloadDir, "Install-Modpack.ps1");
            string args = "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\" -Gui -Lang " + Tr.Codes[Tr.Lang] + " -Target \"" + _root.TrimEnd('\\') + "\"";
            if (_installBase) args += " -InstallBase";
            if (_installBase && _deleteBase) args += " -DeleteBaseArchive";
            ProcessStartInfo psi = new ProcessStartInfo(ps, args);
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
            psi.RedirectStandardInput = true;
            psi.StandardOutputEncoding = Encoding.UTF8;
            psi.StandardErrorEncoding = Encoding.UTF8;
            psi.WorkingDirectory = _payloadDir;
            _proc = new Process();
            _proc.StartInfo = psi;
            _proc.EnableRaisingEvents = true;
            _proc.OutputDataReceived += delegate(object s, DataReceivedEventArgs e) { if (e.Data != null) { string d = e.Data; Ui(delegate { OnLine(d); }); } };
            _proc.ErrorDataReceived += delegate(object s, DataReceivedEventArgs e) { if (!string.IsNullOrEmpty(e.Data)) { string d = e.Data; Ui(delegate { Log(d, Theme.Dim); }); } };
            _proc.Exited += delegate
            {
                // let the last output lines arrive before reporting the exit
                try { _proc.WaitForExit(); } catch { }
                Ui(OnExited);
            };
            try
            {
                _proc.Start();
                _proc.BeginOutputReadLine();
                _proc.BeginErrorReadLine();
            }
            catch (Exception ex) { Fail(Tr.L("err_ps", ex.Message)); }
        }

        void Ui(Action a)
        {
            try { if (!IsDisposed && IsHandleCreated) BeginInvoke(a); } catch { }
        }

        void OnLine(string line)
        {
            if (!line.StartsWith("@@")) { Log(line, Theme.Dim); return; }
            int bar = line.IndexOf('|');
            string kind = bar > 0 ? line.Substring(2, bar - 2) : line.Substring(2);
            string data = bar > 0 ? line.Substring(bar + 1) : "";
            switch (kind)
            {
                case "LOG":
                    {
                        int c = data.IndexOf('|');
                        string col = c >= 0 ? data.Substring(0, c) : "Gray";
                        string msg = c >= 0 ? data.Substring(c + 1) : data;
                        if (msg.Trim().Length > 0) Log(msg, ColorFor(col));
                        break;
                    }
                case "STATUS": _status.Text = data; break;
                case "PROGRESS":
                    {
                        string[] parts = data.Split('|');
                        int cur, max;
                        if (parts.Length == 2 && int.TryParse(parts[0], out cur) && int.TryParse(parts[1], out max))
                        {
                            _bar.Set(cur, max);
                            _count.Text = cur + " / " + max;
                        }
                        break;
                    }
                case "BROWSER":
                    {
                        int c = data.IndexOf('|');
                        string n = c >= 0 ? data.Substring(0, c) : data;
                        string files = c >= 0 ? data.Substring(c + 1) : "";
                        if (n == "0") { _browserBox.Visible = false; _log.SetBounds(0, 58, 708, 322); break; }
                        _browserText.Text = Tr.L("browser_text", n) + "\n  " + files.Replace(" ;; ", "\n  ");
                        _browserBox.Visible = true;
                        _log.SetBounds(0, 216, 708, 164);
                        break;
                    }
                case "ASK":
                    {
                        bool yes = Msg.YesNo(this, data);
                        try { _proc.StandardInput.WriteLine(yes ? "Y" : "N"); _proc.StandardInput.Flush(); } catch { }
                        break;
                    }
                case "DONE":
                    {
                        _finished = true;
                        if (data.Trim().Length > 0) foreach (string pr in Regex.Split(data, @"\s*\|\|\s*")) if (pr.Trim().Length > 0) _problems.Add(pr.Trim());
                        ShowFinish();
                        break;
                    }
                case "ERROR": Fail(data); break;
            }
        }

        void OnExited()
        {
            if (_finished || _failed) return;
            int code = -1;
            try { code = _proc.ExitCode; } catch { }
            Fail(Tr.L("err_unexpected", code));
        }

        void Fail(string msg)
        {
            if (_failed) return;
            _failed = true;
            _browserBox.Visible = false;
            _log.SetBounds(0, 58, 708, 322);
            _status.Text = Tr.L("st_stopped");
            _status.ForeColor = Theme.Red;
            Log(Tr.L("log_error", msg), Theme.Red);
            Log(Tr.L("log_fix"), Theme.Amber);
            ApplyChrome();
            _footer.PerformLayout();
        }

        // ---------------------------------------------------------------- page 4: finish
        void BuildPage4()
        {
            _p4 = NewPage();
            _doneTitle = MakeLabel("", Theme.Text, Theme.UIBold); _doneTitle.SetBounds(0, 0, 700, 26);
            _doneText = MakeLabel("", Theme.Text, Theme.UI); _doneText.SetBounds(0, 34, 700, 270);
            WizButton readme = new WizButton(Tr.L("btn_readme")); readme.Location = new Point(0, 320);
            WizButton openFolder = new WizButton(Tr.L("btn_folder"));
            WizButton launch = new WizButton(Tr.L("btn_launch"));
            foreach (Control c in new Control[] { _doneTitle, _doneText, readme, openFolder, launch }) _p4.Controls.Add(c);
            openFolder.Location = new Point(readme.Right + 8, 320);
            launch.Location = new Point(openFolder.Right + 8, 320);
            readme.Click += delegate { OpenPath(Path.Combine(_root, "README - Modpack Installer.txt")); };
            openFolder.Click += delegate { OpenPath(_root); };
            launch.Click += delegate
            {
                try
                {
                    ProcessStartInfo si = new ProcessStartInfo(Path.Combine(_root, "ModOrganizer.exe"));
                    si.WorkingDirectory = _root; si.UseShellExecute = true;
                    Process.Start(si);
                    Close();
                }
                catch (Exception ex) { Msg.Info(this, Tr.L("err_launch", ex.Message)); }
            };
        }

        void ShowFinish()
        {
            ShowPage(4);
            if (_problems.Count == 0)
            {
                _banner.SetText(Tr.L(_isUpdate ? "done_title_upd" : "done_title"), Tr.L("done_sub"));
                _doneTitle.Text = Tr.L("done_head");
                _doneTitle.ForeColor = Theme.Text;
                _doneText.Text = Tr.L("done_text", _root);
            }
            else
            {
                _banner.SetText(Tr.L("prob_title"), Tr.L("prob_sub"));
                _doneTitle.Text = Tr.L("prob_head");
                _doneTitle.ForeColor = Theme.Amber;
                StringBuilder sb = new StringBuilder();
                foreach (string p in _problems) sb.AppendLine("- " + p);
                sb.AppendLine();
                sb.AppendLine(Tr.L("prob_retry"));
                _doneText.Text = sb.ToString();
            }
        }

        // ---------------------------------------------------------------- newer release on GitHub?
        void StartUpdateCheck()
        {
            if (string.IsNullOrEmpty(_github) || Date10(_version).Length == 0) return;
            Thread t = new Thread(delegate ()
            {
                try
                {
                    ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072;   // TLS 1.2
                    using (WebClient wc = new WebClient())
                    {
                        wc.Headers[HttpRequestHeader.UserAgent] = "VanillaPlusCoopSetup";
                        wc.Headers[HttpRequestHeader.Accept] = "application/vnd.github+json";
                        wc.Encoding = Encoding.UTF8;
                        string json = wc.DownloadString("https://api.github.com/repos/" + _github + "/releases/latest");
                        Match tag = Regex.Match(json, "\"tag_name\"\\s*:\\s*\"([^\"]+)\"");
                        Match url = Regex.Match(json, "\"html_url\"\\s*:\\s*\"([^\"]+/releases/tag/[^\"]+)\"");
                        if (!tag.Success) return;
                        string tagDate = Date10(tag.Groups[1].Value);
                        if (tagDate.Length == 0 || string.CompareOrdinal(tagDate, Date10(_version)) <= 0) return;
                        string u = url.Success ? url.Groups[1].Value : "https://github.com/" + _github + "/releases/latest";
                        string tg = tag.Groups[1].Value;
                        Ui(delegate { OnNewerRelease(tg, u); });
                    }
                }
                catch { }   // offline or GitHub unavailable: no update hint
            });
            t.IsBackground = true;
            t.Start();
        }

        void OnNewerRelease(string tag, string url)
        {
            _newerTag = tag; _newerUrl = url;
            _updLink.Text = Tr.L("upd_link", tag);
            _updLink.Visible = true;
            _footer.Invalidate();
            if (!_newerShown && _page <= 1)
            {
                _newerShown = true;
                if (Msg.YesNo(this, Tr.L("upd_avail", tag, Date10(_version)))) OpenUrl(url);
            }
        }

        static void OpenUrl(string url) { try { if (!string.IsNullOrEmpty(url)) Process.Start(url); } catch { } }
        static void OpenPath(string p) { try { Process.Start(p); } catch { } }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            bool running = false;
            try { running = _proc != null && !_proc.HasExited; } catch { }
            if (running && !_failed && !_finished)
            {
                if (!Msg.YesNo(this, Tr.L("ask_stop"))) { e.Cancel = true; return; }
                KillTree(_proc.Id);
            }
            base.OnFormClosing(e);
        }

        static void KillTree(int pid)
        {
            try
            {
                ProcessStartInfo si = new ProcessStartInfo("taskkill", "/T /F /PID " + pid);
                si.CreateNoWindow = true; si.UseShellExecute = false;
                Process p = Process.Start(si);
                p.WaitForExit(5000);
            }
            catch { }
        }

        public void PresetLanguage(string code)
        {
            for (int i = 0; i < Tr.Codes.Length; i++)
                if (Tr.Codes[i] == code) { Tr.Lang = i; if (_langRadios != null) _langRadios[i].Checked = true; }
        }
    }

    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            string preset = null, lang = null;
            foreach (string a in args)
            {
                if (a.StartsWith("/target:", StringComparison.OrdinalIgnoreCase)) preset = a.Substring(8);
                if (a.StartsWith("/lang:", StringComparison.OrdinalIgnoreCase)) lang = a.Substring(6);
            }

            string dir = Path.Combine(Path.GetTempPath(), "AnomalyVanillaPlusCoopSetup_" + Process.GetCurrentProcess().Id);
            string version = "", github = "";
            try
            {
                if (Directory.Exists(dir)) Directory.Delete(dir, true);
                Directory.CreateDirectory(dir);
                using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
                {
                    if (s == null) throw new Exception("the installer data is missing from this .exe");
                    string zip = Path.Combine(dir, "payload.zip");
                    using (FileStream f = File.Create(zip)) s.CopyTo(f);
                    ZipFile.ExtractToDirectory(zip, dir);
                    File.Delete(zip);
                }
                string json = File.ReadAllText(Path.Combine(dir, "modpack.json"));
                Match m = Regex.Match(json, "\"created\"\\s*:\\s*\"([^\"]+)\"");
                if (m.Success) version = m.Groups[1].Value;
                Match g = Regex.Match(json, "\"github\"\\s*:\\s*\"([^\"]+)\"");
                if (g.Success) github = g.Groups[1].Value;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Setup could not unpack its files: " + ex.Message, "Stalker Anomaly Vanilla+ Coop Pack", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            try
            {
                SetupForm form = new SetupForm(dir, version, github, preset);
                if (lang != null) form.PresetLanguage(lang);
                Application.Run(form);
            }
            finally { try { Directory.Delete(dir, true); } catch { } }
        }
    }
}
