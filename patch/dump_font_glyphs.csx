// ============================================================
//  ScorchpotEasy 字形白名单导出（v1.2）
//  用法：UndertaleModCli.exe load <原版 data.win> -s patch\dump_font_glyphs.csx
//  作用：把游戏内置中文字形（fntHan_l / fntHan_m / fntHan_s）的全部字形写进
//        patch/font-glyphs-hans.txt（单行，UTF-8 无 BOM）。ScorchpotEasy.ps1 用它校验
//        配置档名能否在游戏内画出——游戏内置中文字形只有 1568 个，缺字会显示成方块。
//  说明：游戏更新替换 data.win 后重跑一次即可刷新白名单。
//        本脚本只读 data.win，不写回游戏文件。
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

var glyphSet = new System.Collections.Generic.SortedSet<int>();
var fontInfo = new System.Collections.Generic.List<string>();
foreach (string fontName in new string[] { "fntHan_l", "fntHan_m", "fntHan_s" })
{
    UndertaleFont f = null;
    foreach (var ff in Data.Fonts) { if (ff.Name.Content == fontName) { f = ff; break; } }
    if (f == null)
        throw new Exception("缺少中文字形资源：" + fontName);
    foreach (var gl in f.Glyphs) glyphSet.Add((int)gl.Character);
    fontInfo.Add(fontName + "=" + f.Glyphs.Count);
}

var sb = new System.Text.StringBuilder();
foreach (int c in glyphSet) sb.Append((char)c);

string outPath = Path.GetFullPath(Path.Combine(gmlDir, "..", "font-glyphs-hans.txt"));
File.WriteAllText(outPath, sb.ToString(), new System.Text.UTF8Encoding(false));

ScriptMessage("字形白名单已写出：" + outPath);
ScriptMessage("合计字形 " + glyphSet.Count + " 个（" + string.Join(" / ", fontInfo) + "）");
