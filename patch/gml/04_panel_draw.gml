// ===== ScorchpotEasy Mod v1.1：面板绘制（追加到 oTable_hanger Draw End 事件）=====
//  坐标全部来自 global.sp_ui_*（01_config.gml），与 02_panel_step.gml 的鼠标判定共用
//  配色取自游戏本体实测像素：深褐黑 #14110C / 青灰 #4A7787 / 羊皮纸 #F6E7B1 / 木棕 #593823 / 金 #C9A44C
//  注意：GML 颜色整数值按 BGR 存放，注释里写的是对应的 #RRGGBB
if (global.sp_panel_open && global.sp_panel_enabled == 1)
{
    var _c_back    = 0x0C1114; // #14110C 深褐黑底
    var _c_wood    = 0x233859; // #593823 木棕外框
    var _c_gold    = 0x4CA4C9; // #C9A44C 金色描边
    var _c_bar     = 0x3C3621; // #21363C 标题条 / 隔行底纹
    var _c_parch   = 0xB1E7F6; // #F6E7B1 羊皮纸米黄（标题 / 数值）
    var _c_cream   = 0xCFF0F9; // #F9F0CF 米白（正文）
    var _c_teal    = 0x87774A; // #4A7787 青灰（选中高亮）
    var _c_teal_lt = 0xAEA779; // #79A7AE 亮青（版本号 / 操作说明）
    var _c_line    = 0x524A2E; // #2E4A52 分隔线
    var _c_muted   = 0xA29A7E; // #7E9AA2 次要文字（说明 / 底部提示）
    var _c_btn     = 0x38311B; // #1B3138 按钮底
    var _c_btn_hot = 0x61522C; // #2C5261 按钮悬停

    var _px = global.sp_ui_x;
    var _py = global.sp_ui_y;
    var _pw = global.sp_ui_w;
    var _ph = global.sp_ui_h;

    // 明确对齐方式，避免继承游戏 Scribble 留下的居中/竖中对齐导致文字戳出面板
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // ---- 全屏压暗 ----
    draw_set_font(fntHan_m);
    draw_set_colour(c_black);
    draw_set_alpha(0.55);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);

    // ---- 面板主体 + 木棕外框 + 金色内框 ----
    draw_set_colour(_c_back);
    draw_set_alpha(0.96);
    draw_rectangle(_px, _py, _px + _pw, _py + _ph, false);
    draw_set_alpha(1);
    draw_set_colour(_c_wood);
    draw_rectangle(_px - 6, _py - 6, _px + _pw + 6, _py + _ph + 6, true);
    draw_set_colour(_c_gold);
    draw_rectangle(_px + 10, _py + 10, _px + _pw - 10, _py + _ph - 10, true);

    // ---- 标题条 ----
    draw_set_colour(_c_bar);
    draw_rectangle(_px + 10, _py + 10, _px + _pw - 10, _py + 150, false);
    draw_set_colour(_c_gold);
    draw_rectangle(_px + 10, _py + 150, _px + _pw - 10, _py + 155, false);

    draw_set_font(fntHan_l);
    draw_set_colour(_c_parch);
    draw_text(_px + 70, _py + 48, "喂龙高手 简易模式");

    var _ver = "v" + global.sp_version;
    draw_set_font(fntHan_m);
    draw_set_colour(_c_teal_lt);
    draw_text(_px + _pw - 70 - string_width(_ver), _py + 62, _ver);

    // ---- 信息行：配置档（可点击切换）+ - / + 按钮 + 位置指示 ----
    // 行高参考：fntHan_m 行高 79 / fntHan_s 行高 57（实测字体数据），故各行按行高留白排布
    var _sp_prof_on = (global.sp_prof_count > 0);
    var _sp_pname = global.sp_profile;
    if (_sp_prof_on) { _sp_pname = global.sp_prof_names[global.sp_prof_idx]; }

    draw_set_font(fntHan_m);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(_c_cream);
    draw_text(global.sp_ui_prof_label_x, _py + 162, "配置档：");

    // 档名（超宽自动横向压缩，绝不压到按钮上）
    draw_set_colour((_sp_prof_on ? _c_parch : _c_muted));
    var _sp_pnw = string_width(_sp_pname);
    if (_sp_pnw > global.sp_ui_prof_name_w)
    {
        draw_text_transformed(global.sp_ui_prof_name_x, _py + 162, _sp_pname, global.sp_ui_prof_name_w / _sp_pnw, 1, 0);
    }
    else
    {
        draw_text(global.sp_ui_prof_name_x, _py + 162, _sp_pname);
    }

    // 上一档 / 下一档按钮（与数值行同款方块 + 悬停变亮；无索引时置灰）
    var _sp_pbw2 = global.sp_ui_btn_w / 2;
    var _sp_pbh2 = global.sp_ui_btn_h / 2;
    for (var _sp_pb = 0; _sp_pb < 2; _sp_pb++)
    {
        var _sp_pcx = global.sp_ui_prof_minus_x;
        if (_sp_pb == 1) { _sp_pcx = global.sp_ui_prof_plus_x; }
        var _sp_px1 = _sp_pcx - _sp_pbw2;
        var _sp_px2 = _sp_pcx + _sp_pbw2;
        var _sp_py1 = global.sp_ui_prof_row_y - _sp_pbh2;
        var _sp_py2 = global.sp_ui_prof_row_y + _sp_pbh2;
        var _sp_phover = (_sp_prof_on && point_in_rectangle(mouse_x, mouse_y, _sp_px1, _sp_py1, _sp_px2, _sp_py2));

        draw_set_colour((_sp_prof_on ? _c_gold : _c_line));
        draw_rectangle(_sp_px1, _sp_py1, _sp_px2, _sp_py2, true);
        draw_set_colour((_sp_phover ? _c_btn_hot : _c_btn));
        draw_set_alpha((_sp_prof_on ? 1 : 0.45));
        draw_rectangle(_sp_px1 + 3, _sp_py1 + 3, _sp_px2 - 3, _sp_py2 - 3, false);
        draw_set_alpha(1);

        draw_set_font(fntHan_m);
        draw_set_colour((_sp_prof_on ? _c_parch : _c_muted));
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        if (_sp_pb == 0)
        {
            draw_text(_sp_pcx, global.sp_ui_prof_row_y, "-");
        }
        else
        {
            draw_text(_sp_pcx, global.sp_ui_prof_row_y, "+");
        }
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }

    // 位置指示 (1/3)
    if (_sp_prof_on)
    {
        draw_set_font(fntHan_s);
        draw_set_colour(_c_teal_lt);
        draw_text(global.sp_ui_prof_step_x, _py + 176, "(" + string(global.sp_prof_idx + 1) + "/" + string(global.sp_prof_count) + ")");
    }

    // 按键
    draw_set_font(fntHan_m);
    draw_set_colour(_c_teal_lt);
    draw_text(global.sp_ui_hotkey_x, _py + 162, "按键：" + global.sp_hotkey_cn);

    // ---- 操作说明行 ----
    draw_set_font(fntHan_s);
    draw_set_colour(_c_muted);
    draw_text(_px + 70, _py + 248, "上下键 选择 · 左右键 调整 · 滚轮 上下 · 鼠标点击 - + · Q/E 或点档名 换配置档 · B 重新设置按键 · S 保存 · R 复原 · Esc 关闭");

    // ---- 分隔线 ----
    draw_set_colour(_c_line);
    draw_rectangle(_px + 70, _py + 312, _px + _pw - 70, _py + 315, false);

    // ---- 15 行数值（一屏 12 行，滚轮上下；行序与配置档数值槽一一对应）----
    var _sp_labels = ["饥饿值倍率", "每季额外掷骰", "建筑价格倍率", "食谱价格倍率", "其他物品价格", "刷新费用倍率", "饿怒攻击", "开局金币", "食谱激活成本", "建筑上限", "商店货位", "骰子上限", "食谱栏上限", "可激活食谱", "每年季度", "工具刷新", "骰子刷新"];
    var _sp_values = [global.sp_hunger_mult, global.sp_rolls_bonus, global.sp_building_price_mult, global.sp_recipe_price_mult, global.sp_price_mult, global.sp_reroll_cost_mult, global.sp_hanger_mode, global.sp_start_gold, global.sp_activation_mult, global.sp_building_bonus, global.sp_extra_slots, global.sp_dice_bonus, global.sp_recipe_store_bonus, global.sp_active_recipe_bonus, global.sp_seasons_bonus, global.sp_shop_tool_reroll, global.sp_shop_dice_reroll];
    var _sp_notes  = ["原版 1", "原版 0", "原版 1", "原版 1", "原版 1", "原版 1 · 0 为免费（金币+食材）", "0 原版 / 1 减半 / 2 关闭", "下局开局生效", "原版 1", "原版 0", "原版 0", "原版 0 · 港口解锁 3-6", "原版 0 · 贸易站解锁 3-6", "原版 0 · 上限 1-4", "原版 0 · 农庄解锁 1-4", "0 关闭 / 1 免费 / 2 收费", "0 关闭 / 1 免费 / 2 收费"];

    draw_set_font(fntHan_m);
    var _sp_h_m = string_height("值");
    draw_set_font(fntHan_s);
    var _sp_h_s = string_height("值");

    var _sp_bw2 = global.sp_ui_btn_w / 2;
    var _sp_bh2 = global.sp_ui_btn_h / 2;
    var _sp_alt = 0;
    var _sp_vis = global.sp_ui_rows_vis;
    var _sp_scroll = global.sp_panel_scroll;

    // 只画滚动窗口内的 12 行；实际行号 = 滚动偏移 + 屏内下标（数值/标签/说明都按实际行号取）
    for (var _sp_vi = 0; _sp_vi < _sp_vis; _sp_vi++)
    {
        var _sp_i = _sp_scroll + _sp_vi;
        var _sp_ry = global.sp_ui_row_y0 + (_sp_vi * global.sp_ui_row_h);
        var _sp_y1 = _sp_ry - global.sp_ui_row_half;
        var _sp_y2 = _sp_ry + global.sp_ui_row_half;

        // 隔行底纹
        if (_sp_alt == 1)
        {
            draw_set_colour(_c_bar);
            draw_set_alpha(0.32);
            draw_rectangle(_px + 56, _sp_y1, _px + _pw - 56, _sp_y2, false);
            draw_set_alpha(1);
        }
        _sp_alt = 1 - _sp_alt;

        // 选中行：整条青灰高亮 + 左侧金色标记
        if (_sp_i == global.sp_panel_sel)
        {
            draw_set_colour(_c_teal);
            draw_set_alpha(0.32);
            draw_rectangle(_px + 56, _sp_y1, _px + _pw - 56, _sp_y2, false);
            draw_set_alpha(1);
            draw_set_colour(_c_gold);
            draw_rectangle(_px + 56, _sp_y1, _px + 70, _sp_y2, false);
        }

        // 数值文本
        var _sp_v = _sp_values[_sp_i];
        var _sp_num = string(round(_sp_v * 100) / 100);
        if (_sp_i == 1 || _sp_i == 6 || _sp_i == 7 || _sp_i == 9 || _sp_i == 10 || _sp_i == 11 || _sp_i == 12 || _sp_i == 13 || _sp_i == 14 || _sp_i == 15 || _sp_i == 16)
        {
            _sp_num = string(round(_sp_v));
        }
        var _sp_note = "（" + _sp_notes[_sp_i] + "）";

        // 标签（超宽自动横向压缩，绝不越界）
        draw_set_font(fntHan_m);
        if (_sp_i == global.sp_panel_sel)
        {
            draw_set_colour(_c_parch);
        }
        else
        {
            draw_set_colour(_c_cream);
        }
        var _sp_lbl = _sp_labels[_sp_i];
        var _sp_ty = _sp_ry - (_sp_h_m / 2);
        var _sp_lw = string_width(_sp_lbl);
        if (_sp_lw > global.sp_ui_label_w)
        {
            draw_text_transformed(global.sp_ui_label_x, _sp_ty, _sp_lbl, global.sp_ui_label_w / _sp_lw, 1, 0);
        }
        else
        {
            draw_text(global.sp_ui_label_x, _sp_ty, _sp_lbl);
        }

        // 数值（右对齐）
        draw_set_colour(_c_parch);
        draw_text(global.sp_ui_value_r - string_width(_sp_num), _sp_ty, _sp_num);

        // 说明（超宽自动横向压缩）
        draw_set_font(fntHan_s);
        draw_set_colour(_c_muted);
        var _sp_ny = _sp_ry - (_sp_h_s / 2);
        var _sp_nw = string_width(_sp_note);
        if (_sp_nw > global.sp_ui_note_w)
        {
            draw_text_transformed(global.sp_ui_note_x, _sp_ny, _sp_note, global.sp_ui_note_w / _sp_nw, 1, 0);
        }
        else
        {
            draw_text(global.sp_ui_note_x, _sp_ny, _sp_note);
        }

        // ---- - / + 按钮（方块 + 悬停变亮）----
        for (var _sp_b = 0; _sp_b < 2; _sp_b++)
        {
            var _sp_cx = global.sp_ui_minus_x;
            if (_sp_b == 1) { _sp_cx = global.sp_ui_plus_x; }
            var _sp_bx1 = _sp_cx - _sp_bw2;
            var _sp_bx2 = _sp_cx + _sp_bw2;
            var _sp_by1 = _sp_ry - _sp_bh2;
            var _sp_by2 = _sp_ry + _sp_bh2;
            var _sp_hover = point_in_rectangle(mouse_x, mouse_y, _sp_bx1, _sp_by1, _sp_bx2, _sp_by2);

            draw_set_colour(_c_gold);
            draw_rectangle(_sp_bx1, _sp_by1, _sp_bx2, _sp_by2, true);
            draw_set_colour((_sp_hover ? _c_btn_hot : _c_btn));
            draw_rectangle(_sp_bx1 + 3, _sp_by1 + 3, _sp_bx2 - 3, _sp_by2 - 3, false);

            draw_set_font(fntHan_m);
            draw_set_colour(_c_parch);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            if (_sp_b == 0)
            {
                draw_text(_sp_cx, _sp_ry, "-");
            }
            else
            {
                draw_text(_sp_cx, _sp_ry, "+");
            }
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        }

        // 行分隔线
        draw_set_colour(_c_line);
        draw_set_alpha(0.5);
        draw_rectangle(_px + 70, _sp_y2, _px + _pw - 70, _sp_y2 + 2, false);
        draw_set_alpha(1);
    }

    // ---- 滚动条（15 行 / 一屏 12 行；槽 + 滑块）----
    if (global.sp_ui_scroll_max > 0)
    {
        var _sp_bx1 = global.sp_ui_bar_x1;
        var _sp_bx2 = global.sp_ui_bar_x2;
        var _sp_by1 = global.sp_ui_bar_y1;
        var _sp_by2 = global.sp_ui_bar_y2;
        draw_set_colour(_c_line);
        draw_rectangle(_sp_bx1, _sp_by1, _sp_bx2, _sp_by2, false);
        var _sp_thumb_h = (_sp_by2 - _sp_by1) * (global.sp_ui_rows_vis / global.sp_ui_rows_total);
        var _sp_thumb_y = _sp_by1 + (((_sp_by2 - _sp_by1) - _sp_thumb_h) * (_sp_scroll / global.sp_ui_scroll_max));
        draw_set_colour(_c_gold);
        draw_rectangle(_sp_bx1, _sp_thumb_y, _sp_bx2, _sp_thumb_y + _sp_thumb_h, false);
    }

    // ---- 底部：保存提示 ----
    draw_set_colour(_c_line);
    draw_rectangle(_px + 70, _py + 1680, _px + _pw - 70, _py + 1683, false);

    draw_set_font(fntHan_s);
    if (global.sp_panel_msg != "")
    {
        draw_set_colour(_c_parch);
        draw_text(_px + 70, _py + 1692, global.sp_panel_msg);
    }
    draw_set_colour(_c_muted);
    var _sp_foot = "S 保存后重开游戏生效 · 局内数值在下一次刷新生效";
    draw_text(_px + _pw - 70 - string_width(_sp_foot), _py + 1692, _sp_foot);
    // 当前行号范围（如 1-12/15），与右侧提示并排
    var _sp_range = string(global.sp_panel_scroll + 1) + "-" + string(global.sp_panel_scroll + global.sp_ui_rows_vis) + "/" + string(global.sp_ui_rows_total);
    draw_set_colour(_c_teal_lt);
    draw_text(_px + _pw - 70 - string_width(_sp_foot) - string_width(_sp_range) - 60, _py + 1692, _sp_range);

    draw_set_colour(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
// ===== ScorchpotEasy 面板绘制结束 =====
