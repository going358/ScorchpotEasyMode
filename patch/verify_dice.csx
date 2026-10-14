// ============================================================
//  构建校验（v1.4；v1.5 面板扩到 15 行、v1.6 扩到 17 行时同步更新）：反编译补丁产物，确认「骰子上限」加成已挂到全部 5 个赋值点
//  用法：UndertaleModCli.exe load <补丁版 data.win> -s verify_dice.csx
//  说明：通过时写 patch/last_verify_dice_report.txt；任一断言失败立即抛异常，
//        脚本因此非零退出且不生成报告文件 —— ScorchpotEasy.ps1 靠这两点拦下安装。
// ============================================================
using System;
using System.IO;
using System.Text;
using UndertaleModLib.Util;

EnsureDataLoaded();

string patchDir = null;
string[] candidates = {
    System.Environment.GetEnvironmentVariable("SCORCHPOT_MOD_ROOT") != null
        ? Path.Combine(System.Environment.GetEnvironmentVariable("SCORCHPOT_MOD_ROOT"), "patch") : null,
    Path.Combine(Directory.GetCurrentDirectory(), "patch"),
    Path.Combine(System.AppContext.BaseDirectory, "patch")
};
foreach (string c in candidates)
{
    if (c != null && Directory.Exists(c)) { patchDir = c; break; }
}
if (patchDir == null)
    throw new Exception("找不到 patch 目录（verify_dice.csx）。");

string reportPath = Path.Combine(patchDir, "last_verify_dice_report.txt");
if (File.Exists(reportPath))
    File.Delete(reportPath);   // 失败时不留下上一次的「通过」报告

var codeCreate = Data.Code.ByName("gml_Object_oController_Create_0");
var codeStep1  = Data.Code.ByName("gml_Object_oController_Step_1");
var codeDraw   = Data.Code.ByName("gml_Object_oTable_hanger_Draw_73");
if (codeCreate == null)
    throw new Exception("补丁校验失败：代码条目不存在 gml_Object_oController_Create_0。");
if (codeStep1 == null)
    throw new Exception("补丁校验失败：代码条目不存在 gml_Object_oController_Step_1。");
if (codeDraw == null)
    throw new Exception("补丁校验失败：代码条目不存在 gml_Object_oTable_hanger_Draw_73。");

GlobalDecompileContext ctx = new GlobalDecompileContext(Data);
string create = new Underanalyzer.Decompiler.DecompileContext(ctx, codeCreate, Data.ToolInfo.DecompilerSettings).DecompileToString();
string step1  = new Underanalyzer.Decompiler.DecompileContext(ctx, codeStep1,  Data.ToolInfo.DecompilerSettings).DecompileToString();
string draw   = new Underanalyzer.Decompiler.DecompileContext(ctx, codeDraw,   Data.ToolInfo.DecompilerSettings).DecompileToString();

System.Func<string, string, int> CountOf = (text, needle) =>
{
    int n = 0;
    int i = 0;
    while ((i = text.IndexOf(needle, i, StringComparison.Ordinal)) >= 0)
    {
        n++;
        i += needle.Length;
    }
    return n;
};

var errors = new System.Collections.Generic.List<string>();

// Create：初始值 1 处
if (!create.Contains("global.dice_limit = 3 + global.sp_dice_bonus;"))
    errors.Add("Create 事件缺少 global.dice_limit = 3 + global.sp_dice_bonus;");
if (CountOf(create, "global.dice_limit =") != 1)
    errors.Add("Create 事件里 global.dice_limit 赋值出现 " + CountOf(create, "global.dice_limit =") + " 次（期望 1 次）");

// Step：港口四档各 1 处
string[] stepMust = {
    "global.dice_limit = 3 + global.sp_dice_bonus;",
    "global.dice_limit = 4 + global.sp_dice_bonus;",
    "global.dice_limit = 5 + global.sp_dice_bonus;",
    "global.dice_limit = 6 + global.sp_dice_bonus;"
};
foreach (string m in stepMust)
{
    int c = CountOf(step1, m);
    if (c != 1) errors.Add("Step 事件里 " + m + " 出现 " + c + " 次（期望 1 次）");
}
if (CountOf(step1, "global.dice_limit =") != 4)
    errors.Add("Step 事件里 global.dice_limit 赋值出现 " + CountOf(step1, "global.dice_limit =") + " 次（期望 4 次）");

// 面板：12 行（末尾新增「骰子上限」）与切档覆盖
string[] stepPanel = {
    "_sp_rows = global.sp_ui_rows_total",
    "_sp_pv[11]",
    "dice_bonus="
};
foreach (string m in stepPanel)
    if (!step1.Contains(m)) errors.Add("Step 事件面板部分缺少 " + m);

string[] drawMust = {
    "\"骰子上限\"",
    "原版 0 · 港口解锁 3-6",
    "_sp_vi < _sp_vis",
    "global.sp_dice_bonus, global.sp_recipe_store_bonus, global.sp_active_recipe_bonus, global.sp_seasons_bonus, global.sp_shop_tool_reroll, global.sp_shop_dice_reroll]",
    "_sp_i == 12 || _sp_i == 13 || _sp_i == 14"
};
foreach (string m in drawMust)
    if (!draw.Contains(m)) errors.Add("面板 Draw 事件缺少 " + m);

if (errors.Count > 0)
    throw new Exception("补丁校验失败：\n" + string.Join("\n", errors));

var lines = new System.Collections.Generic.List<string>();
{
    int ln = 0;
    foreach (string l in create.Split('\n'))
    {
        ln++;
        if (l.Contains("global.dice_limit")) lines.Add("  Create:" + ln + " " + l.Trim());
    }
    ln = 0;
    foreach (string l in step1.Split('\n'))
    {
        ln++;
        if (l.Contains("global.dice_limit")) lines.Add("  Step_1:" + ln + " " + l.Trim());
    }
}

StringBuilder sb = new StringBuilder();
sb.Append("补丁校验：通过（骰子可拥有上限 dice_limit 已叠加 sp_dice_bonus，共 5 处）\n");
sb.Append("检查项：Create 1 处 + Step 4 处（原版港口分档 3/4/5/6）+ 面板 17 行（一屏 12 行 + 滚轮）与切档覆盖\n");
sb.Append("回读语句：\n").Append(string.Join("\n", lines)).Append('\n');
File.WriteAllText(reportPath, sb.ToString(), new UTF8Encoding(false));
ScriptMessage(sb.ToString());
