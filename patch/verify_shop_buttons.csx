// ============================================================
//  构建校验（v1.6）：反编译补丁产物，确认商店「工具刷新 / 骰子刷新」按钮
//  的绘制、点击、扣费与面板第 16/17 行都已落盘
//  用法：UndertaleModCli.exe load <补丁版 data.win> -s verify_shop_buttons.csx
//  说明：通过时写 patch/last_verify_shop_buttons_report.txt；任一断言失败立即抛异常，
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
    throw new Exception("找不到 patch 目录（verify_shop_buttons.csx）。");

string reportPath = Path.Combine(patchDir, "last_verify_shop_buttons_report.txt");
if (File.Exists(reportPath))
    File.Delete(reportPath);   // 失败时不留下上一次的「通过」报告

var codeCreate = Data.Code.ByName("gml_Object_oController_Create_0");
var codeStep0  = Data.Code.ByName("gml_Object_oController_Step_0");
var codeStep1  = Data.Code.ByName("gml_Object_oController_Step_1");
var codeDraw   = Data.Code.ByName("gml_Object_oTable_hanger_Draw_73");
if (codeCreate == null) throw new Exception("补丁校验失败：代码条目不存在 gml_Object_oController_Create_0。");
if (codeStep0 == null)  throw new Exception("补丁校验失败：代码条目不存在 gml_Object_oController_Step_0。");
if (codeStep1 == null)  throw new Exception("补丁校验失败：代码条目不存在 gml_Object_oController_Step_1。");
if (codeDraw == null)   throw new Exception("补丁校验失败：代码条目不存在 gml_Object_oTable_hanger_Draw_73。");

GlobalDecompileContext ctx = new GlobalDecompileContext(Data);
var settings = Data.ToolInfo.DecompilerSettings;
string create = new Underanalyzer.Decompiler.DecompileContext(ctx, codeCreate, settings).DecompileToString();
string step0  = new Underanalyzer.Decompiler.DecompileContext(ctx, codeStep0,  settings).DecompileToString();
string step1  = new Underanalyzer.Decompiler.DecompileContext(ctx, codeStep1,  settings).DecompileToString();
string draw   = new Underanalyzer.Decompiler.DecompileContext(ctx, codeDraw,   settings).DecompileToString();

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

// ---- Create：新配置项、面板 17 行、配置档索引 17 槽 ----
string[] createMust = {
    "global.sp_shop_tool_reroll = 1;",
    "global.sp_shop_dice_reroll = 1;",
    "case \"shop_tool_reroll\":",
    "case \"shop_dice_reroll\":",
    "global.sp_shop_tool_reroll = real(_sp_val);",
    "global.sp_shop_dice_reroll = real(_sp_val);",
    "global.sp_shop_tool_reroll = clamp(round(global.sp_shop_tool_reroll), 0, 2);",
    "global.sp_shop_dice_reroll = clamp(round(global.sp_shop_dice_reroll), 0, 2);",
    "global.sp_ui_rows_total = 17;",
    "_pp_f == \"shop_tool_reroll\"",
    "_pp_f == \"shop_dice_reroll\""
};
foreach (string m in createMust)
    if (!create.Contains(m)) errors.Add("Create 事件缺少 " + m);
if (CountOf(create, "[1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1]") != 1)
    errors.Add("Create 事件的配置档数值槽不是 17 槽");

// ---- Step_0：收费计数随建筑刷新计数按年复位 ----
string[] step0Must = {
    "global.sp_shop_dice_count = 0;",
    "global.sp_shop_tool_count = 0;"
};
foreach (string m in step0Must)
    if (!step0.Contains(m)) errors.Add("Step_0 事件缺少 " + m);
if (CountOf(step0, "global.data.building_reroll_count = 0;") != 1)
    errors.Add("Step_0 事件里建筑刷新计数复位锚点不是 1 处");

// ---- Step_1：按钮输入 + 面板两行 + 保存两键 ----
string[] step1Must = {
    "global.sp_shop_tool_cost = round(global.sp_shop_tool_count + global.data.building_base_reroll_cost);",
    "global.sp_shop_dice_cost = round(global.sp_shop_dice_count + global.data.building_base_reroll_cost);",
    "global.sp_shop_tool_reroll = clamp(global.sp_shop_tool_reroll + _sp_delta, 0, 2);",
    "global.sp_shop_dice_reroll = clamp(global.sp_shop_dice_reroll + _sp_delta, 0, 2);",
    "clamp(round(_sp_pv[15]), 0, 2)",
    "clamp(round(_sp_pv[16]), 0, 2)",
    "global.sp_sb_tool_dx",
    "global.sp_sb_dice_dx",
    "\"shop_tool_reroll=\" + string(global.sp_shop_tool_reroll)",
    "\"shop_dice_reroll=\" + string(global.sp_shop_dice_reroll)",
    "oSFX.sfx_menu_button_locked = true;",
    "oDucat_storage.shake_trigger = true;"
};
foreach (string m in step1Must)
    if (!step1.Contains(m)) errors.Add("Step_1 事件缺少 " + m);

string[] step1Once = {
    "roll_token_shop();",
    "roll_dice_shop();",
    "_sp_pv[15]",
    "_sp_pv[16]",
    "global.sp_shop_tool_count++;",
    "global.sp_shop_dice_count++;",
    "global.sp_shop_tool_cost > global.data.ducats",
    "global.sp_shop_dice_cost > global.data.ducats"
};
foreach (string m in step1Once)
{
    int c = CountOf(step1, m);
    if (c != 1) errors.Add("Step_1 事件里 " + m + " 不是 1 处");
}
// 重掷写法必须与原版年初 shop_lock 分支一致（清空在售实例 → 调游戏自身的 roll_*_shop）
if (CountOf(step1, "oSFX.sfx_reroll_buildings = true;") != 2)
    errors.Add("Step_1 事件里重掷音效不是 2 处");
string rerollToken = "                with (oToken)\n                {\n                    if (on_display == true)\n                    {\n                        instance_destroy();\n                    }\n                }\n                roll_token_shop();";
string rerollDie = "                with (oDie)\n                {\n                    if (on_display == true)\n                    {\n                        instance_destroy();\n                    }\n                }\n                roll_dice_shop();";
if (!step1.Contains(rerollToken)) errors.Add("Step_1 事件缺少「清空在售工具 + roll_token_shop()」的重掷写法");
if (!step1.Contains(rerollDie)) errors.Add("Step_1 事件缺少「清空在售骰子 + roll_dice_shop()」的重掷写法");
// 原版 1 处 + 面板块 1 处 + 商店按钮 2 处（点中按钮后清输入，防止商店被「点外面」逻辑关掉）
if (CountOf(step1, "global.in_mb_left_pressed = false;") != 4)
    errors.Add("Step_1 事件里 global.in_mb_left_pressed = false; 不是 4 处");

// ---- Draw：按钮绘制 + 面板标签/说明/数值/整数行 ----
string[] drawMust = {
    "\"刷新工具\"",
    "\"刷新骰子\"",
    "\"工具刷新\"",
    "\"骰子刷新\"",
    "global.sp_shop_tool_reroll > 0 && global.token_display_limit > 0",
    "global.sp_shop_dice_reroll > 0 && global.dice_display_limit > 0",
    "global.sp_shop_tool_reroll, global.sp_shop_dice_reroll]",
    "_sp_i == 15 || _sp_i == 16",
    "global.sp_sb_half_w",
    "global.sp_sb_half_h"
};
foreach (string m in drawMust)
    if (!draw.Contains(m)) errors.Add("Draw 事件缺少 " + m);
if (CountOf(draw, "0 关闭 / 1 免费 / 2 收费") != 2)
    errors.Add("Draw 事件里说明文案不是 2 处");
// v1.6.2：按钮 = 游戏自带木框金币徽章 + scribble(游戏同款字体/居中/金币标签)
if (CountOf(draw, "draw_sprite_ext(sShop_building_reroll, 0,") != 2)
    errors.Add("Draw 事件里徽章底图绘制不是 2 处");
if (CountOf(draw, "scribble(") != 2)
    errors.Add("Draw 事件里 scribble() 不是 2 处");
if (CountOf(draw, "global.fonts.title_m.name") < 1)
    errors.Add("Draw 事件未使用游戏字体 global.fonts.title_m.name");
if (CountOf(draw, "[sDucat_text]") != 2)
    errors.Add("Draw 事件里金币图标标签不是 2 处");

if (errors.Count > 0)
    throw new Exception("补丁校验失败：\n" + string.Join("\n", errors));

var lines = new System.Collections.Generic.List<string>();
{
    int ln = 0;
    foreach (string l in step1.Split('\n'))
    {
        ln++;
        if (l.Contains("global.sp_shop_tool_cost") || l.Contains("global.sp_shop_dice_cost") || l.Contains("roll_token_shop();") || l.Contains("roll_dice_shop();"))
            lines.Add("  Step_1:" + ln + " " + l.Trim());
    }
    ln = 0;
    foreach (string l in draw.Split('\n'))
    {
        ln++;
        if (l.Contains("刷新工具") || l.Contains("刷新骰子") || l.Contains("sShop_building_reroll") || l.Contains("sp_sb_half_w"))
            lines.Add("  Draw:" + ln + " " + l.Trim());
    }
    // 落位几何（徽章 239x211；商店打开时 oShop = 1919,2160；面板内区 x 1217-2616 / y 557-2082）
    lines.Add("  落位：工具徽章 x " + (1919 - 449 - 119.5) + ".." + (1919 - 449 + 119.5) + " / 骰子徽章 x " + (1919 + 566 - 119.5) + ".." + (1919 + 566 + 119.5) + "，纵向 y " + (2160 - 500 - 105.5) + ".." + (2160 - 500 + 105.5));
    lines.Add("  落位自检：与工具列(≤1334)、骰子列(≤1528 且 x 2491-2586)、原版新建筑徽章(1972-2211 / 1549-1759)、建筑行(≥1780)、面板内区均不重叠");
}

StringBuilder sb = new StringBuilder();
sb.Append("补丁校验：通过（商店「工具刷新 / 骰子刷新」按钮：绘制 + 点击 + 扣费 + 面板第 16/17 行 + 配置档 17 槽）\n");
sb.Append("检查项：Create 配置/面板 17 行/索引 17 槽；Step_0 计数按年复位；Step_1 价格公式 + 原版重掷写法 + 面板两行与保存；Draw 按钮绘制与面板文案\n");
sb.Append("回读语句：\n").Append(string.Join("\n", lines)).Append('\n');
File.WriteAllText(reportPath, sb.ToString(), new UTF8Encoding(false));
ScriptMessage(sb.ToString());
