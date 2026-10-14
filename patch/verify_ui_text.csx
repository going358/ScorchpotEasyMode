// ============================================================
//  ScorchpotEasy 面板文案字形体检（独立可复跑）
//  用法：UndertaleModCli.exe load <data.win> -s patch\verify_ui_text.csx
//  作用：把 patch/gml/*.gml 里所有字符串字面量的字符，逐个对照游戏内置中文字形
//        （fntHan_l / fntHan_m / fntHan_s，各 1568 字形）——缺字形直接报错，
//        避免面板实机显示方块或空白。以后改文案后重跑本脚本即可。
//  说明：含 "=" 的字符串是写入配置文件的「键=值」行，不参与绘制，跳过 "=" 本身。
// ============================================================
EnsureDataLoaded();

string gmlDir = null;
string[] candidates = {
    System.Environment.GetEnvironmentVariable("SCORCHPOT_MOD_ROOT") != null
        ? Path.Combine(System.Environment.GetEnvironmentVariable("SCORCHPOT_MOD_ROOT"), "patch", "gml") : null,
    Path.Combine(Directory.GetCurrentDirectory(), "patch", "gml"),
    Path.Combine(System.AppContext.BaseDirectory, "patch", "gml")
};
foreach (string c in candidates)
{
    if (c != null && Directory.Exists(c)) { gmlDir = c; break; }
}
if (gmlDir == null)
    throw new Exception("找不到 GML 代码块目录（patch/gml）。");

var glyphOk = new System.Collections.Generic.HashSet<int>();
var fontInfo = new System.Collections.Generic.List<string>();
foreach (string fontName in new string[] { "fntHan_l", "fntHan_m", "fntHan_s" })
{
    UndertaleFont f = null;
    foreach (var ff in Data.Fonts) { if (ff.Name.Content == fontName) { f = ff; break; } }
    if (f == null)
        throw new Exception("缺少中文字形资源：" + fontName);
    foreach (var gl in f.Glyphs) glyphOk.Add(gl.Character);
    fontInfo.Add(fontName + "(em=" + f.EmSize + ", glyphs=" + f.Glyphs.Count + ")");
}

var literalRegex = new System.Text.RegularExpressions.Regex("\"([^\"]*)\"");
var missing = new System.Collections.Generic.List<string>();
int literalCount = 0;
int skippedConfig = 0;

foreach (string file in Directory.GetFiles(gmlDir, "*.gml"))
{
    string block = File.ReadAllText(file);
    foreach (System.Text.RegularExpressions.Match m in literalRegex.Matches(block))
    {
        literalCount++;
        string lit = m.Groups[1].Value;
        bool isConfigLine = lit.Contains("=");
        if (isConfigLine) skippedConfig++;
        foreach (char c in lit)
        {
            if (isConfigLine && c == '=') continue;
            if (!glyphOk.Contains(c))
            {
                string item = Path.GetFileName(file) + " 中的 \"" + lit + "\" 含缺字形字符 '"
                    + c + "' (U+" + ((int)c).ToString("X4") + ")";
                if (!missing.Contains(item)) missing.Add(item);
            }
        }
    }
}

ScriptMessage("字体：" + string.Join("，", fontInfo));
ScriptMessage("扫描字符串字面量：" + literalCount + " 条（其中配置文件行 " + skippedConfig + " 条）");

if (missing.Count > 0)
{
    foreach (string item in missing) ScriptMessage("[缺字形] " + item);
    throw new Exception("面板文案存在字体缺字形，共 " + missing.Count + " 处，已在上方列出。");
}

ScriptMessage("面板文案字形体检：通过。");
