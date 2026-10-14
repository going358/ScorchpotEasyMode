// ============================================================
//  ScorchpotEasy Mod v1 —— data.win 补丁器（UndertaleModCli 脚本）
//  用法：UndertaleModCli.exe load <原版 data.win> -s apply_mod.csx -o <输出 data.win>
//  说明：按「函数/事件名 + 精确锚点」打补丁；锚点缺失会立即报错，避免半成品补丁
// ============================================================
using System;
using System.IO;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;
using UndertaleModLib.Util;

EnsureDataLoaded();

// ---------- 定位 GML 代码块目录 ----------
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

string configBlock = File.ReadAllText(Path.Combine(gmlDir, "01_config.gml"));
string panelStepBlock = File.ReadAllText(Path.Combine(gmlDir, "02_panel_step.gml"));
string runStartBlock = File.ReadAllText(Path.Combine(gmlDir, "03_runstart.gml"));
string panelDrawBlock = File.ReadAllText(Path.Combine(gmlDir, "04_panel_draw.gml"));
string shopDrawBlock = File.ReadAllText(Path.Combine(gmlDir, "05_shop_buttons_draw.gml"));
string shopStepBlock = File.ReadAllText(Path.Combine(gmlDir, "06_shop_buttons_step.gml"));

// ---------- 面板文案字形体检（构建期强制：中文缺字形立即失败，避免实机出现方块）----------
string glyphReport = "";
{
    var glyphOk = new System.Collections.Generic.HashSet<int>();
    foreach (string fontName in new string[] { "fntHan_l", "fntHan_m", "fntHan_s" })
    {
        UndertaleFont f = null;
        foreach (var ff in Data.Fonts) { if (ff.Name.Content == fontName) { f = ff; break; } }
        if (f == null) throw new Exception("缺少中文字形资源：" + fontName);
        foreach (var gl in f.Glyphs) glyphOk.Add(gl.Character);
    }

    var literalRegex = new System.Text.RegularExpressions.Regex("\"([^\"]*)\"");
    var missing = new System.Collections.Generic.List<string>();
    int skippedConfig = 0;
    int escapedSeqs = 0;
    foreach (var block in new string[] { configBlock, panelStepBlock, runStartBlock, panelDrawBlock, shopDrawBlock, shopStepBlock })
    {
        foreach (System.Text.RegularExpressions.Match m in literalRegex.Matches(block))
        {
            string lit = m.Groups[1].Value;
            bool isConfigLine = lit.Contains("=");
            if (isConfigLine) skippedConfig++;
            // v1.6.2：按 GML 转义规则解码后再体检——\n / \r / \t 是控制字符（不占字形），
            //         \" \\ 等解码成真实字符照常体检；旧版把 "\n" 里的反斜杠当成要画出来的字，误报缺字形。
            for (int ci = 0; ci < lit.Length; ci++)
            {
                char c = lit[ci];
                if (c == '\\' && ci + 1 < lit.Length)
                {
                    char nx = lit[ci + 1];
                    if (nx == 'n' || nx == 'r' || nx == 't')
                    {
                        ci++;
                        escapedSeqs++;
                        continue;
                    }
                    if (nx == '"' || nx == '\\' || nx == '\'')
                    {
                        c = nx;
                        ci++;
                        escapedSeqs++;
                    }
                }
                if (isConfigLine && c == '=') continue;
                if (!glyphOk.Contains(c))
                {
                    string item = "'" + c + "' U+" + ((int)c).ToString("X4") + " 出现在 \"" + lit + "\"";
                    if (!missing.Contains(item)) missing.Add(item);
                }
            }
        }
    }
    if (missing.Count > 0)
        throw new Exception("面板文案存在字体缺字形（" + missing.Count + " 处）：\n" + string.Join("\n", missing));
    glyphReport = "面板文案字形体检：通过（fntHan_l/m/s 共 " + glyphOk.Count + " 字形，检查字符串字面量，跳过 " + skippedConfig + " 处配置文件行，按转义解码 " + escapedSeqs + " 处转义序列）";
}

GlobalDecompileContext ctx = new GlobalDecompileContext(Data);
var settings = Data.ToolInfo.DecompilerSettings;
CodeImportGroup group = new CodeImportGroup(Data) { MainThreadAction = MainThreadAction };

int[] patchCount = new int[1];
string[] report = new string[8];

string Decompile(string name)
{
    UndertaleCode code = Data.Code.ByName(name);
    if (code == null)
        throw new Exception("代码条目不存在：" + name);
    return new Underanalyzer.Decompiler.DecompileContext(ctx, code, settings).DecompileToString();
}

int CountOf(string text, string needle)
{
    int count = 0;
    int idx = 0;
    while ((idx = text.IndexOf(needle, idx, StringComparison.Ordinal)) >= 0)
    {
        count++;
        idx += needle.Length;
    }
    return count;
}

string ReplaceOnce(string text, string from, string to, string label)
{
    int count = CountOf(text, from);
    if (count != 1)
        throw new Exception("锚点数量异常（" + label + "）：期望 1 处，实际 " + count + " 处");
    int idx = text.IndexOf(from, StringComparison.Ordinal);
    patchCount[0]++;
    return text.Substring(0, idx) + to + text.Substring(idx + from.Length);
}

string InsertBefore(string text, string anchor, string block, string label)
{
    int count = CountOf(text, anchor);
    if (count != 1)
        throw new Exception("锚点数量异常（" + label + "）：期望 1 处，实际 " + count + " 处");
    int idx = text.IndexOf(anchor, StringComparison.Ordinal);
    patchCount[0]++;
    return text.Substring(0, idx) + block + "\n" + text.Substring(idx);
}

// ---------- 1. oController Create：插入配置读取 + 基础投掷次数 ----------
{
    string t = Decompile("gml_Object_oController_Create_0");
    t = configBlock + "\n" + t;
    patchCount[0]++;
    t = ReplaceOnce(t, "global.roll_limit = 4;", "global.roll_limit = 4 + global.sp_rolls_bonus;", "Create/roll_limit");
    // 骰子可拥有上限的初始值（原版 3；随后每 30 帧按港口数在 Step_1 里重算）
    t = ReplaceOnce(t, "global.dice_limit = 3;", "global.dice_limit = 3 + global.sp_dice_bonus;", "Create/dice_limit");
    // v1.5：食谱栏格数 / 可同时激活食谱数 / 每年季度数 的初始值（随后同样每 30 帧重算）
    t = ReplaceOnce(t, "global.recipe_limit = 3;",
        "global.recipe_limit = 3 + global.sp_recipe_store_bonus;", "Create/recipe_limit");
    t = ReplaceOnce(t, "global.activated_recipes_limit = 1;",
        "global.activated_recipes_limit = 1 + global.sp_active_recipe_bonus;", "Create/activated_recipes_limit");
    t = ReplaceOnce(t, "global.max_seasons = 2;",
        "global.max_seasons = 2 + global.sp_seasons_bonus;", "Create/max_seasons");
    group.QueueReplace("gml_Object_oController_Create_0", t);
    report[0] = "oController Create：配置读取 + roll_limit / dice_limit / recipe_limit / activated_recipes_limit / max_seasons 基础值";
}

// ---------- 2. oController Begin Step：面板输入 + 开局应用 + 数值挂钩 ----------
{
    string t = Decompile("gml_Object_oController_Step_1");

    // 2.1 面板输入（在 new_run 处理之前，紧跟输入状态读取）
    t = InsertBefore(t, "if (new_run == true)", panelStepBlock, "Step_1/panel");

    // 2.1b 商店刷新按钮输入（同一锚点，插在面板块之后：面板先吃输入，面板打开时本块自动跳过）
    t = InsertBefore(t, "if (new_run == true)", shopStepBlock, "Step_1/shop_buttons");

    // 2.2 开局应用
    t = InsertBefore(t, "    new_run = false;", runStartBlock, "Step_1/runstart");

    // 2.3 饥饿倍率（每帧重置点）
    t = ReplaceOnce(t, "global.hunger_reduction = 1;",
        "global.hunger_reduction = 1 * global.sp_hunger_mult;", "Step_1/hunger");

    // 2.4 刷新成本
    t = ReplaceOnce(t,
        "global.recipe_reroll_ducat_cost = global.data.recipe_reroll_discount + floor(2 * global.data.recipe_reroll_count * power(1 + (global.data.recipe_reroll_count / 20), 1.1));",
        "global.recipe_reroll_ducat_cost = round((global.data.recipe_reroll_discount + floor(2 * global.data.recipe_reroll_count * power(1 + (global.data.recipe_reroll_count / 20), 1.1))) * global.sp_reroll_cost_mult);",
        "Step_1/reroll_recipe");
    t = ReplaceOnce(t,
        "global.building_reroll_cost = global.data.building_reroll_count + global.data.building_base_reroll_cost;",
        "global.building_reroll_cost = round((global.data.building_reroll_count + global.data.building_base_reroll_cost) * global.sp_reroll_cost_mult);",
        "Step_1/reroll_building");

    // 2.5 建筑上限额外加成
    t = ReplaceOnce(t, "global.buildings_extra = 0;",
        "global.buildings_max += global.sp_building_bonus;\n    global.buildings_extra = 0;", "Step_1/buildings_bonus");

    // 2.6 每季掷骰次数
    t = ReplaceOnce(t, "global.roll_limit = global.data.base_rolls;",
        "global.roll_limit = global.data.base_rolls + global.sp_rolls_bonus;", "Step_1/rolls0");
    t = ReplaceOnce(t, "global.roll_limit = global.data.base_rolls + 1;",
        "global.roll_limit = global.data.base_rolls + 1 + global.sp_rolls_bonus;", "Step_1/rolls1");
    t = ReplaceOnce(t, "global.roll_limit = global.data.base_rolls + 2;",
        "global.roll_limit = global.data.base_rolls + 2 + global.sp_rolls_bonus;", "Step_1/rolls2");
    t = ReplaceOnce(t, "global.roll_limit = global.data.base_rolls + 3;",
        "global.roll_limit = global.data.base_rolls + 3 + global.sp_rolls_bonus;", "Step_1/rolls3");

    // 2.7 骰子可拥有上限（原版按港口数量分 3/4/5/6 四档，每 30 帧重算；四档全部叠加加成）
    t = ReplaceOnce(t, "global.dice_limit = 3;",
        "global.dice_limit = 3 + global.sp_dice_bonus;", "Step_1/dice_limit0");
    t = ReplaceOnce(t, "global.dice_limit = 4;",
        "global.dice_limit = 4 + global.sp_dice_bonus;", "Step_1/dice_limit1");
    t = ReplaceOnce(t, "global.dice_limit = 5;",
        "global.dice_limit = 5 + global.sp_dice_bonus;", "Step_1/dice_limit2");
    t = ReplaceOnce(t, "global.dice_limit = 6;",
        "global.dice_limit = 6 + global.sp_dice_bonus;", "Step_1/dice_limit3");

    // 2.8 食谱栏格数（原版按贸易站数量分 3/4/5/6 四档，游戏内叫「烹饪书进度」）
    t = ReplaceOnce(t, "global.recipe_limit = 3;",
        "global.recipe_limit = 3 + global.sp_recipe_store_bonus;", "Step_1/recipe_limit0");
    t = ReplaceOnce(t, "global.recipe_limit = 4;",
        "global.recipe_limit = 4 + global.sp_recipe_store_bonus;", "Step_1/recipe_limit1");
    t = ReplaceOnce(t, "global.recipe_limit = 5;",
        "global.recipe_limit = 5 + global.sp_recipe_store_bonus;", "Step_1/recipe_limit2");
    t = ReplaceOnce(t, "global.recipe_limit = 6;",
        "global.recipe_limit = 6 + global.sp_recipe_store_bonus;", "Step_1/recipe_limit3");

    // 2.9 可同时激活的食谱数（原版 1/2/3 + 工具修正，第 4 档取 activated_recipes_limit_max）
    //     注：不改 activated_recipes_limit_max（原版 4），工具「魔杖」的临时上限维持原版语义
    t = ReplaceOnce(t, "global.activated_recipes_limit = 1 + global.data.staff_limit_adj;",
        "global.activated_recipes_limit = 1 + global.data.staff_limit_adj + global.sp_active_recipe_bonus;", "Step_1/active0");
    t = ReplaceOnce(t, "global.activated_recipes_limit = 2 + global.data.staff_limit_adj;",
        "global.activated_recipes_limit = 2 + global.data.staff_limit_adj + global.sp_active_recipe_bonus;", "Step_1/active1");
    t = ReplaceOnce(t, "global.activated_recipes_limit = 3 + global.data.staff_limit_adj;",
        "global.activated_recipes_limit = 3 + global.data.staff_limit_adj + global.sp_active_recipe_bonus;", "Step_1/active2");
    t = ReplaceOnce(t, "global.activated_recipes_limit = global.activated_recipes_limit_max;",
        "global.activated_recipes_limit = global.activated_recipes_limit_max + global.sp_active_recipe_bonus;", "Step_1/active3");

    // 2.10 每年季度数（原版 = base_seasons + 农庄档位 0/1/2/3，游戏内叫「轮耕进度」）
    //      外面套 max(…, 当前季度)：把季度数往回调时不会因 season > max_seasons 当场判负
    t = ReplaceOnce(t, "global.max_seasons = global.data.base_seasons;",
        "global.max_seasons = max(global.data.base_seasons + global.sp_seasons_bonus, global.data.season);", "Step_1/seasons0");
    t = ReplaceOnce(t, "global.max_seasons = global.data.base_seasons + 1;",
        "global.max_seasons = max(global.data.base_seasons + 1 + global.sp_seasons_bonus, global.data.season);", "Step_1/seasons1");
    t = ReplaceOnce(t, "global.max_seasons = global.data.base_seasons + 2;",
        "global.max_seasons = max(global.data.base_seasons + 2 + global.sp_seasons_bonus, global.data.season);", "Step_1/seasons2");
    t = ReplaceOnce(t, "global.max_seasons = global.data.base_seasons + 3;",
        "global.max_seasons = max(global.data.base_seasons + 3 + global.sp_seasons_bonus, global.data.season);", "Step_1/seasons3");

    group.QueueReplace("gml_Object_oController_Step_1", t);
    report[1] = "oController Begin Step：面板输入 + 商店刷新按钮输入 + 开局应用 + 饥饿/刷新/建筑上限/掷骰/骰子上限/食谱栏/可激活食谱/每年季度";
}

// ---------- 3. oController End Step：商店货位 + 食谱刷新食材费用 ----------
{
    string t = Decompile("gml_Object_oController_Step_2");
    t = ReplaceOnce(t, "global.recipe_display_limit = global.recipe_base_display_limit;",
        "global.recipe_display_limit = global.recipe_base_display_limit + global.sp_extra_slots;", "Step_2/recipe_slot");
    t = ReplaceOnce(t, "global.token_display_limit = global.token_base_display_limit;",
        "global.token_display_limit = global.token_base_display_limit + global.sp_extra_slots;", "Step_2/token_slot");
    t = ReplaceOnce(t, "global.building_display_limit = global.building_base_display_limit;",
        "global.building_display_limit = global.building_base_display_limit + global.sp_extra_slots;", "Step_2/building_slot");
    t = ReplaceOnce(t, "global.dice_display_limit = global.dice_base_display_limit;",
        "global.dice_display_limit = global.dice_base_display_limit + global.sp_extra_slots;", "Step_2/dice_slot");

    // 3.5 食谱刷新的「食材」那一半（oReroll_recipe 同时扣金币与当季食材）
    //     原版每帧把食材费用重置成 recipe_reroll_ingredients_base（=10），所以只缩放宽金币倍率对食材无效。
    //     这里改成「base × 刷新费用倍率」；龙膳（draconic_delicacy，港湾 3 级）的原生 act 也写这一行，
    //     但 act 只在建筑落成时执行一次、必定被本行重置覆盖 → 改为每帧按 check_buildings 判定，
    //     只要本局棋盘上存在龙膳，食材费用恒为 0（与原生意图一致：只免食材，金币照旧）。
    t = ReplaceOnce(t, "global.recipe_reroll_ingredients_cost = recipe_reroll_ingredients_base;",
        "global.recipe_reroll_ingredients_cost = round(recipe_reroll_ingredients_base * global.sp_reroll_cost_mult);\n"
        + "if (check_buildings(\"draconic_delicacy\", 1)) { global.recipe_reroll_ingredients_cost = 0; }",
        "Step_2/reroll_ingredients");

    group.QueueReplace("gml_Object_oController_Step_2", t);
    report[2] = "oController End Step：商店货位 +N、食谱刷新食材费用倍率（含龙膳免食材）";
}

// ---------- 4. oBuy_button Step：价格倍率 ----------
{
    string t = Decompile("gml_Object_oBuy_button_Step_0");
    string priceBlock = string.Join("\n", new string[] {
        "var _sp_pm = global.sp_price_mult;",
        "if (item_instance.object_index == oBuilding_piece) { _sp_pm = global.sp_building_price_mult; }",
        "else if (item_instance.object_index == oRecipe) { _sp_pm = global.sp_recipe_price_mult; }",
        "final_price = round((price + (floor(global.data.year / 3) * global.data.shop_expensive)) * _sp_pm);"
    });
    t = ReplaceOnce(t, "final_price = round(price + (floor(global.data.year / 3) * global.data.shop_expensive));",
        priceBlock, "Buy_button/price");
    group.QueueReplace("gml_Object_oBuy_button_Step_0", t);
    report[3] = "oBuy_button Step：价格倍率（建筑/食谱/其他分开）";
}

// ---------- 5. oTable_hanger Draw End：面板绘制 ----------
{
    string t = Decompile("gml_Object_oTable_hanger_Draw_73");
    t = t + "\n" + panelDrawBlock;
    patchCount[0]++;
    // v1.6：商店「工具刷新 / 骰子刷新」按钮绘制（同一 Draw End 事件，画在商店物品之上）
    t = t + "\n" + shopDrawBlock;
    patchCount[0]++;
    group.QueueReplace("gml_Object_oTable_hanger_Draw_73", t);
    report[4] = "oTable_hanger Draw End：Mod 面板绘制 + 商店刷新按钮绘制";
}

// ---------- 6. 食谱卡排版表：激活区补第 5 张、食谱栏第 7 张改等距 ----------
//   激活区（oCookbook_on）原版只写了 1~4 张的位置，pos_x 数组本身有 7 格；
//   加成后最多同时激活 5 张，必须补 case 5，否则第 5 张会停在上一帧的旧坐标上。
//   食谱栏（oCookbook_off）自带的 case 7 间距不等距（±195/±390/±780），最左侧会画出屏幕，
//   这里改成与其余档位一致的等距（±195/±390/±585）。
{
    string t = Decompile("gml_Object_oCookbook_on_Step_0");
    t = ReplaceOnce(t,
        "        pos_x[3] = x + recipe_width + (2 * spacing);\n        break;",
        "        pos_x[3] = x + recipe_width + (2 * spacing);\n        break;\n"
        + "    case 5:\n"
        + "        pos_x[0] = x - (2 * (recipe_width + spacing));\n"
        + "        pos_x[1] = x - recipe_width - spacing;\n"
        + "        pos_x[2] = x;\n"
        + "        pos_x[3] = x + recipe_width + spacing;\n"
        + "        pos_x[4] = x + (2 * (recipe_width + spacing));\n"
        + "        break;",
        "Cookbook_on/case5");
    group.QueueReplace("gml_Object_oCookbook_on_Step_0", t);

    string t2 = Decompile("gml_Object_oCookbook_off_Step_0");
    t2 = ReplaceOnce(t2, "pos_x[0] = x - (4 * (recipe_width + spacing));",
        "pos_x[0] = x - (3 * (recipe_width + spacing));", "Cookbook_off/case7_left");
    t2 = ReplaceOnce(t2, "pos_x[6] = x + (4 * (recipe_width + spacing));",
        "pos_x[6] = x + (3 * (recipe_width + spacing));", "Cookbook_off/case7_right");
    group.QueueReplace("gml_Object_oCookbook_off_Step_0", t2);

    report[5] = "食谱卡排版：oCookbook_on 补 case 5（同时激活 5 张）、oCookbook_off case 7 改等距（食谱栏 7 张）";
}

// ---------- 7. oController Step：商店刷新按钮计数随建筑刷新计数按年复位 ----------
//   原版每年年初在 year_start_check == 1 分支里把 recipe_reroll_count / building_reroll_count 归零，
//   这里挂在 building_reroll_count 那一行后面（全文件仅此 1 处），让收费模式的价格每年重新从 3 金币起算。
{
    string t = Decompile("gml_Object_oController_Step_0");
    t = ReplaceOnce(t, "global.data.building_reroll_count = 0;",
        "global.data.building_reroll_count = 0;\n"
        + "        global.sp_shop_dice_count = 0;\n"
        + "        global.sp_shop_tool_count = 0;",
        "Step_0/shop_reroll_count_reset");
    group.QueueReplace("gml_Object_oController_Step_0", t);
    report[6] = "oController Step：商店刷新按钮的本局计数随建筑刷新计数按年复位";
}

// ---------- 执行编译 ----------
group.Import();
report[7] = "补丁点数量：" + patchCount[0] + "\n" + glyphReport;

string reportPath = Path.Combine(gmlDir, "..", "last_patch_report.txt");
File.WriteAllText(Path.GetFullPath(reportPath), string.Join("\n", report) + "\n");
foreach (string line in report)
    ScriptMessage(line);
