// ============================================================
//  构建校验（v1.5）：反编译补丁产物，确认新三项（食谱栏上限 / 可激活食谱 / 每年季度）
//  以及面板滚动、食谱卡排版表都已正确落盘
//  用法：UndertaleModCli.exe load <补丁版 data.win> -s verify_recipes_seasons.csx
//  说明：通过时写 patch/last_verify_recipes_report.txt；任一断言失败立即抛异常，
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
    throw new Exception("找不到 patch 目录（verify_recipes_seasons.csx）。");

string reportPath = Path.Combine(patchDir, "last_verify_recipes_report.txt");
if (File.Exists(reportPath))
    File.Delete(reportPath);   // 失败时不留下上一次的「通过」报告

System.Func<string, string, string> Load = (entry, label) =>
{
    var code = Data.Code.ByName(entry);
    if (code == null)
        throw new Exception("补丁校验失败：代码条目不存在 " + entry + "（" + label + "）。");
    return new Underanalyzer.Decompiler.DecompileContext(
        new GlobalDecompileContext(Data), code, Data.ToolInfo.DecompilerSettings).DecompileToString();
};

string create  = Load("gml_Object_oController_Create_0", "配置读取与初始值");
string step1   = Load("gml_Object_oController_Step_1", "面板输入与档位重算");
string draw    = Load("gml_Object_oTable_hanger_Draw_73", "面板绘制");
string ckOn    = Load("gml_Object_oCookbook_on_Step_0", "激活区排版");
string ckOff   = Load("gml_Object_oCookbook_off_Step_0", "食谱栏排版");

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
System.Action<string, string, string> Need = (text, needle, label) =>
{
    if (!text.Contains(needle)) errors.Add(label + " 缺少：" + needle);
};

// ---- 版本号 ----
Need(create, "global.sp_version = \"1.6.4\";", "Create");

// ---- 默认面板按键（v1.6.4：默认 F9 / 键码 120）----
Need(create, "global.sp_panel_hotkey = \"F9\";", "Create");
Need(create, "global.sp_hotkey_code = 120;", "Create");
if (create.Contains("global.sp_panel_hotkey = \"mouse_forward\";"))
    errors.Add("Create 里默认面板按键仍是 mouse_forward（期望 F9）");
// 注意：不要断言「不含 global.sp_hotkey_code = 5;」——Create 里 case "mouse_forward" 分支
// 合法地写着这个赋值（鼠标侧键仍是可选键位），只断言默认值那一行即可。
if (CountOf(create, "global.sp_hotkey_code = 120;") < 2)
    errors.Add("Create 里 global.sp_hotkey_code = 120; 出现 "
        + CountOf(create, "global.sp_hotkey_code = 120;") + " 次（期望 2 次：默认值 + case \"F9\" 分支）");

// ---- Create：三处初始值 ----
Need(create, "global.recipe_limit = 3 + global.sp_recipe_store_bonus;", "Create");
Need(create, "global.activated_recipes_limit = 1 + global.sp_active_recipe_bonus;", "Create");
Need(create, "global.max_seasons = 2 + global.sp_seasons_bonus;", "Create");
if (CountOf(create, "global.recipe_limit =") != 1)
    errors.Add("Create 里 global.recipe_limit 赋值出现 " + CountOf(create, "global.recipe_limit =") + " 次（期望 1 次）");
if (CountOf(create, "global.activated_recipes_limit =") != 1)
    errors.Add("Create 里 global.activated_recipes_limit 赋值出现 " + CountOf(create, "global.activated_recipes_limit =") + " 次（期望 1 次）");
if (CountOf(create, "global.max_seasons =") != 1)
    errors.Add("Create 里 global.max_seasons 赋值出现 " + CountOf(create, "global.max_seasons =") + " 次（期望 1 次）");

// ---- Step_1：食谱栏四档 ----
string[] recipeMust = {
    "global.recipe_limit = 3 + global.sp_recipe_store_bonus;",
    "global.recipe_limit = 4 + global.sp_recipe_store_bonus;",
    "global.recipe_limit = 5 + global.sp_recipe_store_bonus;",
    "global.recipe_limit = 6 + global.sp_recipe_store_bonus;"
};
foreach (string m in recipeMust)
{
    int c = CountOf(step1, m);
    if (c != 1) errors.Add("Step 里 " + m + " 出现 " + c + " 次（期望 1 次）");
}
if (CountOf(step1, "global.recipe_limit =") != 4)
    errors.Add("Step 里 global.recipe_limit 赋值出现 " + CountOf(step1, "global.recipe_limit =") + " 次（期望 4 次）");

// ---- Step_1：可激活食谱四档（含原版 4 档取 _max 的那一支）----
string[] activeMust = {
    "global.activated_recipes_limit = 1 + global.data.staff_limit_adj + global.sp_active_recipe_bonus;",
    "global.activated_recipes_limit = 2 + global.data.staff_limit_adj + global.sp_active_recipe_bonus;",
    "global.activated_recipes_limit = 3 + global.data.staff_limit_adj + global.sp_active_recipe_bonus;",
    "global.activated_recipes_limit = global.activated_recipes_limit_max + global.sp_active_recipe_bonus;"
};
foreach (string m in activeMust)
{
    int c = CountOf(step1, m);
    if (c != 1) errors.Add("Step 里 " + m + " 出现 " + c + " 次（期望 1 次）");
}
if (CountOf(step1, "global.activated_recipes_limit =") != 4)
    errors.Add("Step 里 global.activated_recipes_limit 赋值出现 " + CountOf(step1, "global.activated_recipes_limit =") + " 次（期望 4 次）");
// 工具「魔杖」上限保持原版 4
if (!create.Contains("global.activated_recipes_limit_max = 4;"))
    errors.Add("Create 里 activated_recipes_limit_max 不是原版 4（魔杖上限应保持原版语义）");

// ---- Step_1：每年季度四档（含不低于当前季度的下限保护）----
string[] seasonsMust = {
    "global.max_seasons = max(global.data.base_seasons + global.sp_seasons_bonus, global.data.season);",
    "global.max_seasons = max(global.data.base_seasons + 1 + global.sp_seasons_bonus, global.data.season);",
    "global.max_seasons = max(global.data.base_seasons + 2 + global.sp_seasons_bonus, global.data.season);",
    "global.max_seasons = max(global.data.base_seasons + 3 + global.sp_seasons_bonus, global.data.season);"
};
foreach (string m in seasonsMust)
{
    int c = CountOf(step1, m);
    if (c != 1) errors.Add("Step 里 " + m + " 出现 " + c + " 次（期望 1 次）");
}
if (CountOf(step1, "global.max_seasons =") != 4)
    errors.Add("Step 里 global.max_seasons 赋值出现 " + CountOf(step1, "global.max_seasons =") + " 次（期望 4 次）");

// ---- Step_1：面板滚动 + 17 行 + 保存行 ----
string[] stepPanel = {
    "_sp_rows = global.sp_ui_rows_total",
    "_sp_vis = global.sp_ui_rows_vis",
    "mouse_wheel_down()",
    "mouse_wheel_up()",
    // v1.6.3：滚轮只移动视窗 + 高亮贴边；键盘导航才让视窗跟随
    "var _sp_wheel = 0;",
    "_sp_wheel = 1;",
    "_sp_wheel = -1;",
    "if (_sp_wheel != 0)",
    "global.sp_panel_scroll = clamp(global.sp_panel_scroll + _sp_wheel, 0, global.sp_ui_scroll_max);",
    "global.sp_panel_sel = clamp(global.sp_panel_sel, global.sp_panel_scroll,",
    "var _sp_sel_moved = false;",
    "_sp_sel_moved = true;",
    "if (_sp_sel_moved)",
    "_sp_pv[14]",
    "recipe_store_bonus=",
    "active_recipe_bonus=",
    "seasons_bonus=",
    "global.sp_recipe_store_bonus = clamp(global.sp_recipe_store_bonus",
    "global.sp_active_recipe_bonus = clamp(global.sp_active_recipe_bonus",
    "global.sp_seasons_bonus = clamp(global.sp_seasons_bonus",
    "global.sp_recipe_store_bonus = 0;",
    "global.sp_active_recipe_bonus = 0;",
    "global.sp_seasons_bonus = 0;"
};
foreach (string m in stepPanel)
    Need(step1, m, "Step 面板部分");

// v1.6.3：选中行跟随钳位必须被关在键盘分支里（旧版无条件执行 → 滚轮前进一格被拽回原位）
int iWheelBlock = step1.IndexOf("if (_sp_wheel != 0)");
int iSelPin     = step1.IndexOf("global.sp_panel_sel = clamp(global.sp_panel_sel, global.sp_panel_scroll,");
int iSelMoved   = step1.IndexOf("if (_sp_sel_moved)");
int iSelFollow  = step1.IndexOf("global.sp_panel_scroll = global.sp_panel_sel;");
if (iWheelBlock < 0 || iSelPin < 0 || iSelMoved < 0)
    errors.Add("Step 面板部分：滚轮/键盘拆分语句缺失（_sp_wheel / 高亮贴边 / _sp_sel_moved）。");
else
{
    if (iSelPin < iWheelBlock)
        errors.Add("Step 面板部分：高亮贴边语句不在滚轮分支之后。");
    if (iSelPin > iSelMoved)
        errors.Add("Step 面板部分：高亮贴边语句跑到了键盘分支后面（顺序异常）。");
}
if (iSelFollow < 0 || iSelFollow < iSelMoved)
    errors.Add("Step 面板部分：选中行跟随钳位没有被 _sp_sel_moved 包住（滚轮会再次被拽回原位）。");
if (CountOf(step1, "global.sp_panel_sel = clamp(global.sp_panel_sel,") != 1)
    errors.Add("Step 面板部分：滚轮高亮贴边语句出现 " + CountOf(step1, "global.sp_panel_sel = clamp(global.sp_panel_sel,") + " 次（期望 1 次）。");

// ---- Draw：17 行标签 / 说明 / 滚动窗口与滚动条 ----
string[] drawMust = {
    "\"食谱栏上限\"",
    "\"可激活食谱\"",
    "\"每年季度\"",
    "原版 0 · 贸易站解锁 3-6",
    "原版 0 · 上限 1-4",
    "原版 0 · 农庄解锁 1-4",
    "滚轮 上下",
    "_sp_vi < _sp_vis",
    "_sp_i == 12 || _sp_i == 13 || _sp_i == 14",
    "global.sp_recipe_store_bonus, global.sp_active_recipe_bonus, global.sp_seasons_bonus, global.sp_shop_tool_reroll, global.sp_shop_dice_reroll]",
    "global.sp_ui_bar_x1",
    "global.sp_panel_scroll + global.sp_ui_rows_vis"
};
foreach (string m in drawMust)
    Need(draw, m, "面板 Draw 事件");

// ---- 食谱卡排版表 ----
Need(ckOn, "case 5:", "激活区排版");
Need(ckOn, "pos_x[4] = x + (2 * (recipe_width + spacing));", "激活区排版");
Need(ckOff, "pos_x[0] = x - (3 * (recipe_width + spacing));", "食谱栏排版");
Need(ckOff, "pos_x[6] = x + (3 * (recipe_width + spacing));", "食谱栏排版");
if (ckOff.Contains("(4 * (recipe_width + spacing))"))
    errors.Add("食谱栏排版里仍存在不等距的 4 倍偏移（case 7 未改成等距）");

if (errors.Count > 0)
    throw new Exception("补丁校验失败：\n" + string.Join("\n", errors));

var lines = new System.Collections.Generic.List<string>();
System.Action<string, string> Echo = (text, key) =>
{
    int ln = 0;
    foreach (string l in text.Split('\n'))
    {
        ln++;
        if (l.Contains(key)) lines.Add("  " + ln + " " + l.Trim());
    }
};
Echo(create, "global.recipe_limit");
Echo(create, "global.activated_recipes_limit");
Echo(create, "global.max_seasons");
Echo(create, "global.sp_panel_hotkey");
Echo(create, "global.sp_hotkey_code");
Echo(step1, "global.recipe_limit =");
Echo(step1, "global.activated_recipes_limit =");
Echo(step1, "global.max_seasons =");

StringBuilder sb = new StringBuilder();
sb.Append("补丁校验：通过（食谱栏上限 recipe_limit / 可激活食谱 activated_recipes_limit / 每年季度 max_seasons 均已叠加加成）\n");
sb.Append("检查项：Create 3 处 + Step 12 处档位赋值 + 面板 17 行与滚轮（v1.6.3：滚轮只移动视窗 / 高亮贴边 / 选中行跟随仅键盘分支）+ 食谱卡排版表（激活 5 张 / 食谱栏 7 张等距）\n");
sb.Append("默认面板按键：F9（键码 120）——已在 Create 段断言\n");
sb.Append("回读语句：\n").Append(string.Join("\n", lines)).Append('\n');
File.WriteAllText(reportPath, sb.ToString(), new UTF8Encoding(false));
ScriptMessage(sb.ToString());
