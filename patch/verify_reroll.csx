// ============================================================
//  构建校验（v1.3）：反编译补丁产物，确认食谱刷新的「食材」费用已挂钩
//  用法：UndertaleModCli.exe load <补丁版 data.win> -s verify_reroll.csx
//  说明：通过时写 patch/last_verify_report.txt；任一断言失败立即抛异常，
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
    throw new Exception("找不到 patch 目录（verify_reroll.csx）。");

string reportPath = Path.Combine(patchDir, "last_verify_report.txt");
if (File.Exists(reportPath))
    File.Delete(reportPath);   // 失败时不留下上一次的「通过」报告

var codeStep2 = Data.Code.ByName("gml_Object_oController_Step_2");
if (codeStep2 == null)
    throw new Exception("补丁校验失败：代码条目不存在 gml_Object_oController_Step_2。");

GlobalDecompileContext ctx = new GlobalDecompileContext(Data);
string step2 = new Underanalyzer.Decompiler.DecompileContext(ctx, codeStep2, Data.ToolInfo.DecompilerSettings).DecompileToString();

string[] mustHave = {
    "global.sp_reroll_cost_mult",       // 食材费用已乘上「刷新费用倍率」
    "recipe_reroll_ingredients_cost",   // 目标变量仍在被赋值
    "check_buildings",                  // 龙膳按帧判定
    "draconic_delicacy"
};

var missing = new System.Collections.Generic.List<string>();
foreach (string m in mustHave)
{
    if (!step2.Contains(m)) missing.Add(m);
}
if (missing.Count > 0)
    throw new Exception("补丁校验失败：oController End Step 缺少 " + string.Join("、", missing));

var lines = new System.Collections.Generic.List<string>();
foreach (string ln in step2.Split('\n'))
{
    if (ln.Contains("recipe_reroll_ingredients_cost"))
        lines.Add("  " + ln.Trim());
}
if (lines.Count == 0)
    throw new Exception("补丁校验失败：oController End Step 里找不到食谱刷新食材费用的赋值语句。");

StringBuilder sb = new StringBuilder();
sb.Append("补丁校验：通过（oController End Step 已挂钩食谱刷新食材费用）\n");
sb.Append("检查项：").Append(string.Join(" / ", mustHave)).Append('\n');
sb.Append("回读语句：\n").Append(string.Join("\n", lines)).Append('\n');
File.WriteAllText(reportPath, sb.ToString(), new UTF8Encoding(false));
ScriptMessage(sb.ToString());
