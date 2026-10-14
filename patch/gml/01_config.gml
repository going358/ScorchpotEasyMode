// ===== ScorchpotEasy Mod v1.1：配置读取（由 apply_mod.csx 自动插入 oController Create 事件顶部）=====
global.sp_version = "1.6.4";
global.sp_cfg_file = "ScorchpotEasy.cfg";
global.sp_profile = "vanilla";
global.sp_profile_ascii = "vanilla";
global.sp_hunger_mult = 1;
global.sp_rolls_bonus = 0;
global.sp_price_mult = 1;
global.sp_building_price_mult = 1;
global.sp_recipe_price_mult = 1;
global.sp_reroll_cost_mult = 1;
global.sp_hanger_mode = 0;
global.sp_start_gold = 0;
global.sp_activation_mult = 1;
global.sp_building_bonus = 0;
global.sp_extra_slots = 0;
global.sp_dice_bonus = 0;
global.sp_recipe_store_bonus = 0;
global.sp_active_recipe_bonus = 0;
global.sp_seasons_bonus = 0;
// v1.6：商店工具列 / 骰子列的手动刷新按钮 0 关闭 / 1 免费（默认） / 2 收费
global.sp_shop_tool_reroll = 1;
global.sp_shop_dice_reroll = 1;
global.sp_panel_enabled = 1;
// v1.6.4：默认面板按键改为 F9（120）；cfg 里没写 panel_hotkey 时用这个兜底
global.sp_panel_hotkey = "F9";
global.sp_hotkey_code = 120;
global.sp_panel_open = false;
global.sp_panel_sel = 0;
global.sp_panel_scroll = 0;
global.sp_panel_learn = false;
global.sp_learn_wait = 0;
global.sp_panel_msg = "";
// v1.6：收费模式的本局刷新计数（每年年初复位，不写存档）与当帧价格（绘制与扣费共用）
global.sp_shop_tool_count = 0;
global.sp_shop_dice_count = 0;
global.sp_shop_tool_cost = 0;
global.sp_shop_dice_cost = 0;

if (file_exists(global.sp_cfg_file))
{
    var _sp_fid = file_text_open_read(global.sp_cfg_file);
    var _sp_guard = 0;
    while (!file_text_eof(_sp_fid) && _sp_guard < 200)
    {
        _sp_guard++;
        // 注意：GameMaker 中 file_text_read_string 读完后必须再 file_text_readln 才会推进到下一行
        var _sp_tok = file_text_read_string(_sp_fid);
        file_text_readln(_sp_fid);
        if (string_length(_sp_tok) == 0)
        {
            continue;
        }
        if (string_pos("=", _sp_tok) <= 0)
        {
            continue;
        }
        if (string_length(_sp_tok) > 0)
        {
            var _sp_eq = string_pos("=", _sp_tok);
            if (_sp_eq > 1)
            {
                var _sp_key = string_copy(_sp_tok, 1, _sp_eq - 1);
                var _sp_val = string_copy(_sp_tok, _sp_eq + 1, string_length(_sp_tok) - _sp_eq);
                // 去掉行尾空白/回车（兼容用记事本编辑过的配置文件）
                while (string_length(_sp_val) > 0 && ord(string_copy(_sp_val, string_length(_sp_val), 1)) <= 32)
                {
                    _sp_val = string_delete(_sp_val, string_length(_sp_val), 1);
                }
                switch (_sp_key)
                {
                    case "profile": global.sp_profile = _sp_val; break;
                    case "profile_ascii": global.sp_profile_ascii = _sp_val; break;
                    case "hunger_mult": global.sp_hunger_mult = real(_sp_val); break;
                    case "rolls_bonus": global.sp_rolls_bonus = real(_sp_val); break;
                    case "price_mult": global.sp_price_mult = real(_sp_val); break;
                    case "building_price_mult": global.sp_building_price_mult = real(_sp_val); break;
                    case "recipe_price_mult": global.sp_recipe_price_mult = real(_sp_val); break;
                    case "reroll_cost_mult": global.sp_reroll_cost_mult = real(_sp_val); break;
                    case "hanger_mode": global.sp_hanger_mode = real(_sp_val); break;
                    case "start_gold": global.sp_start_gold = real(_sp_val); break;
                    case "activation_mult": global.sp_activation_mult = real(_sp_val); break;
                    case "building_bonus": global.sp_building_bonus = real(_sp_val); break;
                    case "extra_slots": global.sp_extra_slots = real(_sp_val); break;
                    case "dice_bonus": global.sp_dice_bonus = real(_sp_val); break;
                    case "recipe_store_bonus": global.sp_recipe_store_bonus = real(_sp_val); break;
                    case "active_recipe_bonus": global.sp_active_recipe_bonus = real(_sp_val); break;
                    case "seasons_bonus": global.sp_seasons_bonus = real(_sp_val); break;
                    case "shop_tool_reroll": global.sp_shop_tool_reroll = real(_sp_val); break;
                    case "shop_dice_reroll": global.sp_shop_dice_reroll = real(_sp_val); break;
                    case "panel_enabled": global.sp_panel_enabled = real(_sp_val); break;
                    case "panel_hotkey": global.sp_panel_hotkey = _sp_val; break;
                }
            }
        }
    }
    file_text_close(_sp_fid);
}

// 数值安全范围（非法值自动回退，绝不崩溃）
global.sp_hunger_mult = clamp(global.sp_hunger_mult, 0.02, 2);
global.sp_rolls_bonus = clamp(round(global.sp_rolls_bonus), 0, 10);
global.sp_price_mult = clamp(global.sp_price_mult, 0, 3);
global.sp_building_price_mult = clamp(global.sp_building_price_mult, 0, 3);
global.sp_recipe_price_mult = clamp(global.sp_recipe_price_mult, 0, 3);
global.sp_reroll_cost_mult = clamp(global.sp_reroll_cost_mult, 0, 3);
global.sp_hanger_mode = clamp(round(global.sp_hanger_mode), 0, 2);
global.sp_start_gold = clamp(round(global.sp_start_gold), 0, 100000);
global.sp_activation_mult = clamp(global.sp_activation_mult, 0, 3);
global.sp_building_bonus = clamp(round(global.sp_building_bonus), 0, 30);
global.sp_extra_slots = clamp(round(global.sp_extra_slots), 0, 3);
global.sp_dice_bonus = clamp(round(global.sp_dice_bonus), 0, 6);
global.sp_recipe_store_bonus = clamp(round(global.sp_recipe_store_bonus), 0, 1);
global.sp_active_recipe_bonus = clamp(round(global.sp_active_recipe_bonus), 0, 1);
global.sp_seasons_bonus = clamp(round(global.sp_seasons_bonus), 0, 2);
global.sp_shop_tool_reroll = clamp(round(global.sp_shop_tool_reroll), 0, 2);
global.sp_shop_dice_reroll = clamp(round(global.sp_shop_dice_reroll), 0, 2);
global.sp_panel_enabled = clamp(round(global.sp_panel_enabled), 0, 1);

// 快捷键名称 -> 内部代码（>=6 为键盘按键代码，1..5 为鼠标按键）
switch (global.sp_panel_hotkey)
{
    case "mouse_left": global.sp_hotkey_code = 1; break;
    case "mouse_right": global.sp_hotkey_code = 2; break;
    case "mouse_middle": global.sp_hotkey_code = 3; break;
    case "mouse_back": global.sp_hotkey_code = 4; break;
    case "mouse_forward": global.sp_hotkey_code = 5; break;
    case "none": global.sp_hotkey_code = 0; break;
    case "F1": global.sp_hotkey_code = 112; break;
    case "F2": global.sp_hotkey_code = 113; break;
    case "F3": global.sp_hotkey_code = 114; break;
    case "F4": global.sp_hotkey_code = 115; break;
    case "F5": global.sp_hotkey_code = 116; break;
    case "F6": global.sp_hotkey_code = 117; break;
    case "F7": global.sp_hotkey_code = 118; break;
    case "F8": global.sp_hotkey_code = 119; break;
    case "F9": global.sp_hotkey_code = 120; break;
    case "F10": global.sp_hotkey_code = 121; break;
    case "F11": global.sp_hotkey_code = 122; break;
    case "F12": global.sp_hotkey_code = 123; break;
    case "SPACE": global.sp_hotkey_code = 32; break;
    case "TAB": global.sp_hotkey_code = 9; break;
    case "ENTER": global.sp_hotkey_code = 13; break;
    default:
        global.sp_hotkey_code = 0;
        if (string_length(global.sp_panel_hotkey) == 1)
        {
            var _sp_ord = ord(global.sp_panel_hotkey);
            if ((_sp_ord >= 48 && _sp_ord <= 57) || (_sp_ord >= 65 && _sp_ord <= 90) || (_sp_ord >= 97 && _sp_ord <= 122))
            {
                global.sp_hotkey_code = _sp_ord;
            }
        }
        break;
}
// ---------- 键位中文显示名（面板与提示共用；游戏中文字形缺「回车」等字，故 TAB/ENTER/Esc 保留英文）----------
if (global.sp_hotkey_code <= 0)
{
    global.sp_hotkey_cn = "未设置";
}
else if (global.sp_hotkey_code == 1) { global.sp_hotkey_cn = "鼠标左键"; }
else if (global.sp_hotkey_code == 2) { global.sp_hotkey_cn = "鼠标右键"; }
else if (global.sp_hotkey_code == 3) { global.sp_hotkey_cn = "鼠标中键"; }
else if (global.sp_hotkey_code == 4) { global.sp_hotkey_cn = "鼠标后退键"; }
else if (global.sp_hotkey_code == 5) { global.sp_hotkey_cn = "鼠标前进键"; }
else if (global.sp_hotkey_code >= 112 && global.sp_hotkey_code <= 123)
{
    global.sp_hotkey_cn = "F" + string(global.sp_hotkey_code - 111);
}
else if (global.sp_hotkey_code == 32) { global.sp_hotkey_cn = "空格"; }
else if (global.sp_hotkey_code == 9) { global.sp_hotkey_cn = "TAB"; }
else if (global.sp_hotkey_code == 13) { global.sp_hotkey_cn = "ENTER"; }
else { global.sp_hotkey_cn = chr(global.sp_hotkey_code); }

// ---------- 面板几何（v1.1：绘制与鼠标判定共用同一组数值，房间 3840x2160）----------
global.sp_ui_w        = 2560;                        // 面板宽
global.sp_ui_h        = 1780;                        // 面板高（v1.4：12 行数值）
global.sp_ui_x        = (room_width  - global.sp_ui_w) / 2;
global.sp_ui_y        = (room_height - global.sp_ui_h) / 2;
global.sp_ui_row_h    = 112;                         // 行距
global.sp_ui_row_half = 52;                          // 行点击判定半高
global.sp_ui_row_y0   = global.sp_ui_y + 372;        // 第一行中心 y
global.sp_ui_label_x  = global.sp_ui_x + 70;         // 标签列左边界
global.sp_ui_label_w  = 900;                         // 标签列最大宽度（超出自动缩放）
global.sp_ui_value_r  = global.sp_ui_x + 1420;       // 数值列右对齐基准
global.sp_ui_note_x   = global.sp_ui_x + 1470;       // 说明列左边界
global.sp_ui_note_w   = 520;                         // 说明列最大宽度（超出自动缩放）
global.sp_ui_btn_w    = 96;                          // - / + 按钮方块宽
global.sp_ui_btn_h    = 76;                          // - / + 按钮方块高
global.sp_ui_minus_x  = global.sp_ui_x + 2160;       // - 按钮中心 x
global.sp_ui_plus_x   = global.sp_ui_x + 2320;       // + 按钮中心 x

// ---------- 面板滚动窗口（v1.5：15 行数值，一屏 12 行，滚轮上下）----------
global.sp_ui_rows_vis   = 12;                        // 一屏可见行数（几何与 v1.4 完全一致）
global.sp_ui_rows_total = 17;                        // 数值总行数（v1.6：+工具刷新 / 骰子刷新）
global.sp_ui_scroll_max = global.sp_ui_rows_total - global.sp_ui_rows_vis;
global.sp_ui_bar_x1     = global.sp_ui_x + global.sp_ui_w - 46;  // 滚动条槽左边界
global.sp_ui_bar_x2     = global.sp_ui_x + global.sp_ui_w - 34;  // 滚动条槽右边界
global.sp_ui_bar_y1     = global.sp_ui_row_y0 - global.sp_ui_row_half;
global.sp_ui_bar_y2     = global.sp_ui_row_y0 + ((global.sp_ui_rows_vis - 1) * global.sp_ui_row_h) + global.sp_ui_row_half;

// ---------- 商店刷新按钮几何（v1.6：绘制与鼠标判定共用同一组数值）----------
//  商店精灵 sShop 1756x1958、原点 (878,1958)，打开时 oShop 位于 (1919,2160)
//  实测（导出 sShop 贴图逐像素量）面板内区：x ∈ [1217, 2616]、y ∈ [557, 2082]（外圈是木框，压在框上很难看）
//  内区空档：工具列 x 1244..1334（精灵 110、原点 20,20，最多 5 格占到 y2035）、
//            骰子列 x 2491..2586（精灵 95、原点 47,47，最多 3 格占到 y1528）、
//            原版「新建筑」刷新按钮占 x 1972..2211 / y 1549..1759（点击掩码 = sShop_building_reroll 239x211）
//  v1.6.2：按钮背景改用游戏自带的木框金币徽章 sShop_building_reroll（239x211，原尺寸不缩放，
//          米色内区实测 147x123 且居中），两个徽章仍摆在原版那条「刷新」横行上（y = oShop.y-500）
global.sp_sb_tool_dx = 449;   // 工具刷新按钮中心 x = oShop.x - 该值 → 1470（徽章占 1350..1589）
global.sp_sb_tool_dy = 500;   // 工具刷新按钮中心 y = oShop.y - 该值 → 1660（与原版「新建筑」刷新同一横行）
global.sp_sb_dice_dx = 566;   // 骰子刷新按钮中心 x = oShop.x + 该值 → 2485（徽章占 2365..2604）
global.sp_sb_dice_dy = 500;   // 骰子刷新按钮中心 y = oShop.y - 该值 → 1660
global.sp_sb_half_w  = sprite_get_width(sShop_building_reroll) / 2;   // 119.5，点击判定半宽 = 徽章一半
global.sp_sb_half_h  = sprite_get_height(sShop_building_reroll) / 2;  // 105.5，点击判定半高 = 徽章一半

// ---------- 配置档切换控件几何（v1.2：绘制与鼠标判定共用）----------
global.sp_ui_prof_label_x = global.sp_ui_x + 70;     // 「配置档：」左边界
global.sp_ui_prof_name_x  = global.sp_ui_x + 320;    // 档名左边界（「配置档：」实测宽 212，留 38 间距）
global.sp_ui_prof_name_w  = 300;                     // 档名最大宽度（超出自动横向压缩）
global.sp_ui_prof_minus_x = global.sp_ui_x + 700;    // 上一档按钮中心 x
global.sp_ui_prof_plus_x  = global.sp_ui_x + 860;    // 下一档按钮中心 x
global.sp_ui_prof_step_x  = global.sp_ui_x + 940;    // (1/3) 位置指示左边界
global.sp_ui_prof_row_y   = global.sp_ui_y + 202;    // 切档控件垂直中心
global.sp_ui_hotkey_x     = global.sp_ui_x + 1400;   // 「按键：」左边界

// ---------- 配置档索引读取（ScorchpotProfiles.cfg，由 ScorchpotEasy.ps1 导出；游戏内只读）----------
//  只能由外部工具写入，游戏只负责读，避免两边同时写同一个文件互相覆盖。
global.sp_prof_file  = "ScorchpotProfiles.cfg";
global.sp_prof_max   = 12;
global.sp_prof_count = 0;
global.sp_prof_idx   = 0;
global.sp_prof_names = [];
global.sp_prof_ascii = [];
global.sp_prof_vals  = [];

for (var _pp_pre = 0; _pp_pre < global.sp_prof_max; _pp_pre++)
{
    array_push(global.sp_prof_names, "");
    array_push(global.sp_prof_ascii, "");
    // 数值顺序：0 饥饿 1 掷骰 2 建筑价 3 食谱价 4 其他价 5 刷新 6 饿怒 7 开局金币 8 激活 9 建筑上限 10 货位 11 骰子上限
    //           12 食谱栏上限 13 可激活食谱 14 每年季度（v1.5 新增；老索引文件缺键时按 0 处理）
    //           15 工具刷新 16 骰子刷新（v1.6 新增；缺键按 1 = 免费处理）
    array_push(global.sp_prof_vals, [1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1]);
}

if (file_exists(global.sp_prof_file))
{
    var _pp_fid = file_text_open_read(global.sp_prof_file);
    var _pp_guard = 0;
    while (!file_text_eof(_pp_fid) && _pp_guard < 400)
    {
        _pp_guard++;
        var _pp_tok = file_text_read_string(_pp_fid);
        file_text_readln(_pp_fid);
        if (string_length(_pp_tok) <= 0) { continue; }
        var _pp_eq = string_pos("=", _pp_tok);
        if (_pp_eq <= 1) { continue; }
        var _pp_key = string_copy(_pp_tok, 1, _pp_eq - 1);
        var _pp_val = string_copy(_pp_tok, _pp_eq + 1, string_length(_pp_tok) - _pp_eq);
        while (string_length(_pp_val) > 0 && ord(string_copy(_pp_val, string_length(_pp_val), 1)) <= 32)
        {
            _pp_val = string_delete(_pp_val, string_length(_pp_val), 1);
        }
        if (_pp_key == "count")
        {
            global.sp_prof_count = clamp(round(real(_pp_val)), 0, global.sp_prof_max);
        }
        else if (string_copy(_pp_key, 1, 1) == "p" && string_pos("_", _pp_key) > 2)
        {
            var _pp_us = string_pos("_", _pp_key);
            var _pp_ix = round(real(string_copy(_pp_key, 2, _pp_us - 2)));
            var _pp_f  = string_copy(_pp_key, _pp_us + 1, string_length(_pp_key) - _pp_us);
            if (_pp_ix >= 0 && _pp_ix < global.sp_prof_max)
            {
                if (_pp_f == "name") { global.sp_prof_names[_pp_ix] = _pp_val; }
                else if (_pp_f == "ascii") { global.sp_prof_ascii[_pp_ix] = _pp_val; }
                else
                {
                    var _pp_vi = -1;
                    if      (_pp_f == "hunger_mult")         { _pp_vi = 0; }
                    else if (_pp_f == "rolls_bonus")         { _pp_vi = 1; }
                    else if (_pp_f == "building_price_mult") { _pp_vi = 2; }
                    else if (_pp_f == "recipe_price_mult")   { _pp_vi = 3; }
                    else if (_pp_f == "price_mult")          { _pp_vi = 4; }
                    else if (_pp_f == "reroll_cost_mult")    { _pp_vi = 5; }
                    else if (_pp_f == "hanger_mode")         { _pp_vi = 6; }
                    else if (_pp_f == "start_gold")          { _pp_vi = 7; }
                    else if (_pp_f == "activation_mult")     { _pp_vi = 8; }
                    else if (_pp_f == "building_bonus")      { _pp_vi = 9; }
                    else if (_pp_f == "extra_slots")         { _pp_vi = 10; }
                    else if (_pp_f == "dice_bonus")          { _pp_vi = 11; }
                    else if (_pp_f == "recipe_store_bonus")  { _pp_vi = 12; }
                    else if (_pp_f == "active_recipe_bonus") { _pp_vi = 13; }
                    else if (_pp_f == "seasons_bonus")       { _pp_vi = 14; }
                    else if (_pp_f == "shop_tool_reroll")    { _pp_vi = 15; }
                    else if (_pp_f == "shop_dice_reroll")    { _pp_vi = 16; }
                    if (_pp_vi >= 0)
                    {
                        // 先取出来改再写回：不依赖「嵌套数组下标直接赋值」的版本差异
                        var _pp_tmp = global.sp_prof_vals[_pp_ix];
                        _pp_tmp[_pp_vi] = real(_pp_val);
                        global.sp_prof_vals[_pp_ix] = _pp_tmp;
                    }
                }
            }
        }
    }
    file_text_close(_pp_fid);
}

// 索引完整性检查：档名缺失（半截文件 / 空文件）时整体退回「只读档名」模式，绝不崩溃
for (var _pp_chk = 0; _pp_chk < global.sp_prof_count; _pp_chk++)
{
    if (string_length(global.sp_prof_names[_pp_chk]) <= 0)
    {
        global.sp_prof_count = 0;
        break;
    }
}

// 用配置文件里的档名定位当前索引档；匹配不到就从第 0 档开始
global.sp_prof_idx = 0;
for (var _pp_find = 0; _pp_find < global.sp_prof_count; _pp_find++)
{
    if (global.sp_prof_names[_pp_find] == global.sp_profile)
    {
        global.sp_prof_idx = _pp_find;
        break;
    }
}
// ===== ScorchpotEasy 配置读取结束 =====
