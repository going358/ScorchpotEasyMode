// ===== ScorchpotEasy Mod v1.1：面板输入处理（插入 oController Begin Step 的输入读取之后）=====
//       v1.6.3：滚轮只移动视窗（不再被「选中行跟随」钳位拽回），键盘导航才让视窗跟随
//  几何一律取自 global.sp_ui_*，与 04_panel_draw.gml 完全一致，避免「点不准」
if (room == rGame && global.sp_panel_enabled == 1)
{
    // --- 快捷键学习 ---
    if (global.sp_panel_learn)
    {
        if (global.sp_learn_wait > 0)
        {
            global.sp_learn_wait--;
        }
        else
        {
            var _sp_found = -1;
            var _sp_fname = "";
            var _sp_k = 0;
            for (_sp_k = 112; _sp_k <= 123; _sp_k++)
            {
                if (keyboard_check_pressed(_sp_k)) { _sp_found = _sp_k; _sp_fname = "F" + string(_sp_k - 111); break; }
            }
            if (_sp_found == -1)
            {
                for (_sp_k = 65; _sp_k <= 90; _sp_k++)
                {
                    if (keyboard_check_pressed(_sp_k)) { _sp_found = _sp_k; _sp_fname = chr(_sp_k); break; }
                }
            }
            if (_sp_found == -1)
            {
                for (_sp_k = 48; _sp_k <= 57; _sp_k++)
                {
                    if (keyboard_check_pressed(_sp_k)) { _sp_found = _sp_k; _sp_fname = chr(_sp_k); break; }
                }
            }
            if (_sp_found == -1 && keyboard_check_pressed(32)) { _sp_found = 32; _sp_fname = "SPACE"; }
            if (_sp_found == -1 && keyboard_check_pressed(9)) { _sp_found = 9; _sp_fname = "TAB"; }
            if (_sp_found == -1 && keyboard_check_pressed(13)) { _sp_found = 13; _sp_fname = "ENTER"; }
            if (_sp_found == -1)
            {
                var _sp_mnames = ["mouse_left", "mouse_right", "mouse_middle", "mouse_back", "mouse_forward"];
                for (_sp_k = 1; _sp_k <= 5; _sp_k++)
                {
                    if (mouse_check_button_pressed(_sp_k)) { _sp_found = _sp_k; _sp_fname = _sp_mnames[_sp_k - 1]; break; }
                }
            }
            if (_sp_found != -1)
            {
                global.sp_hotkey_code = _sp_found;
                global.sp_panel_hotkey = _sp_fname;
                // 同步中文键位显示名
                if (global.sp_hotkey_code == 1) { global.sp_hotkey_cn = "鼠标左键"; }
                else if (global.sp_hotkey_code == 2) { global.sp_hotkey_cn = "鼠标右键"; }
                else if (global.sp_hotkey_code == 3) { global.sp_hotkey_cn = "鼠标中键"; }
                else if (global.sp_hotkey_code == 4) { global.sp_hotkey_cn = "鼠标后退键"; }
                else if (global.sp_hotkey_code == 5) { global.sp_hotkey_cn = "鼠标前进键"; }
                else if (global.sp_hotkey_code >= 112 && global.sp_hotkey_code <= 123) { global.sp_hotkey_cn = "F" + string(global.sp_hotkey_code - 111); }
                else if (global.sp_hotkey_code == 32) { global.sp_hotkey_cn = "空格"; }
                else if (global.sp_hotkey_code == 9) { global.sp_hotkey_cn = "TAB"; }
                else if (global.sp_hotkey_code == 13) { global.sp_hotkey_cn = "ENTER"; }
                else { global.sp_hotkey_cn = chr(global.sp_hotkey_code); }
                global.sp_panel_learn = false;
                global.sp_panel_msg = "已重新设置：" + global.sp_hotkey_cn;
            }
        }
    }
    else if (global.sp_hotkey_code > 0 && !global.sp_panel_learn)
    {
        // --- 热键开关面板 ---
        var _sp_hit = false;
        if (global.sp_hotkey_code <= 5)
        {
            _sp_hit = mouse_check_button_pressed(global.sp_hotkey_code);
        }
        else
        {
            _sp_hit = keyboard_check_pressed(global.sp_hotkey_code);
        }
        if (_sp_hit && !global.sp_learn_wait)
        {
            global.sp_panel_open = !global.sp_panel_open;
            global.sp_panel_msg = "";
        }
    }

    // --- 面板打开时：屏蔽游戏输入 + 面板交互 ---
    if (global.sp_panel_open)
    {
        global.in_mb_left_pressed = false;
        global.in_mb_left_down = false;
        global.in_mb_left_released = false;
        global.in_mb_right_pressed = false;
        global.in_escape = false;
        global.in_shop = false;
        global.in_main = false;

        var _sp_rows = global.sp_ui_rows_total;
        var _sp_vis = global.sp_ui_rows_vis;
        var _sp_half = global.sp_ui_row_half;
        var _sp_bw2 = global.sp_ui_btn_w / 2;
        var _sp_bh2 = global.sp_ui_btn_h / 2;
        var _sp_do_save = false;

        // 滚轮：只移动视窗（v1.6.3；游戏本体完全不用滚轮，面板打开时独占）
        //   v1.5~v1.6.2 的写法是「滚轮改 scroll → 紧接着无条件执行选中行跟随钳位」，
        //   滚轮前进一格当场被拽回原位：刚开面板（sel=0）不点行就滚不动、
        //   点了屏内最后一栏（sel=scroll+11）又上滚不了。v1.6.3 把两类输入彻底分开。
        var _sp_wheel = 0;
        if (mouse_wheel_down()) { _sp_wheel = 1; }
        if (mouse_wheel_up()) { _sp_wheel = -1; }
        if (_sp_wheel != 0)
        {
            global.sp_panel_scroll = clamp(global.sp_panel_scroll + _sp_wheel, 0, global.sp_ui_scroll_max);
            // 高亮行始终留在视窗内：滚出视窗时贴到最近的边界行，
            // 这样 ←/→/R 永远作用在看得见的那一行上
            global.sp_panel_sel = clamp(global.sp_panel_sel, global.sp_panel_scroll, global.sp_panel_scroll + _sp_vis - 1);
        }

        // 键盘导航（上下键选择、左右键调整）——只有键盘真的改了选中行，视窗才跟随
        var _sp_sel_moved = false;
        if (keyboard_check_pressed(vk_up)) { global.sp_panel_sel--; _sp_sel_moved = true; }
        if (keyboard_check_pressed(vk_down)) { global.sp_panel_sel++; _sp_sel_moved = true; }
        if (global.sp_panel_sel < 0) { global.sp_panel_sel = _sp_rows - 1; }
        if (global.sp_panel_sel > _sp_rows - 1) { global.sp_panel_sel = 0; }
        if (_sp_sel_moved)
        {
            // 选中行越出视窗时把视窗挪到刚好能看到它（否则用方向键选到屏外看不到）
            if (global.sp_panel_sel < global.sp_panel_scroll) { global.sp_panel_scroll = global.sp_panel_sel; }
            if (global.sp_panel_sel > global.sp_panel_scroll + _sp_vis - 1) { global.sp_panel_scroll = global.sp_panel_sel - _sp_vis + 1; }
            global.sp_panel_scroll = clamp(global.sp_panel_scroll, 0, global.sp_ui_scroll_max);
        }

        var _sp_delta = 0;
        if (keyboard_check_pressed(vk_left)) { _sp_delta = -1; }
        if (keyboard_check_pressed(vk_right)) { _sp_delta = 1; }
        if (keyboard_check_pressed(82)) { _sp_delta = 99; } // R = 复原当前项

        // 鼠标：行选择 / 减 / 加（矩形与 04_panel_draw.gml 的绘制位置一致）
        //   v1.5：只循环可视窗口内的 12 行，实际行号 = 滚动偏移 + 屏内下标
        var _sp_click = mouse_check_button_pressed(mb_left);
        for (var _sp_vi = 0; _sp_vi < _sp_vis; _sp_vi++)
        {
            var _sp_i = global.sp_panel_scroll + _sp_vi;
            var _sp_ry = global.sp_ui_row_y0 + (_sp_vi * global.sp_ui_row_h);
            if (_sp_click
                && mouse_y >= _sp_ry - _sp_half && mouse_y <= _sp_ry + _sp_half
                && mouse_x >= global.sp_ui_x && mouse_x <= global.sp_ui_x + global.sp_ui_w)
            {
                if (mouse_x >= global.sp_ui_minus_x - _sp_bw2 && mouse_x <= global.sp_ui_minus_x + _sp_bw2
                    && mouse_y >= _sp_ry - _sp_bh2 && mouse_y <= _sp_ry + _sp_bh2)
                {
                    global.sp_panel_sel = _sp_i;
                    _sp_delta = -1;
                }
                else if (mouse_x >= global.sp_ui_plus_x - _sp_bw2 && mouse_x <= global.sp_ui_plus_x + _sp_bw2
                    && mouse_y >= _sp_ry - _sp_bh2 && mouse_y <= _sp_ry + _sp_bh2)
                {
                    global.sp_panel_sel = _sp_i;
                    _sp_delta = 1;
                }
                else
                {
                    global.sp_panel_sel = _sp_i;
                }
            }
        }

        if (_sp_delta != 0)
        {
            var _sp_step = 0.05;
            switch (global.sp_panel_sel)
            {
                case 0: global.sp_hunger_mult = clamp(global.sp_hunger_mult + (_sp_delta * _sp_step), 0.05, 1); break;
                case 1: global.sp_rolls_bonus = clamp(global.sp_rolls_bonus + _sp_delta, 0, 10); break;
                case 2: global.sp_building_price_mult = clamp(global.sp_building_price_mult + (_sp_delta * _sp_step), 0, 2); break;
                case 3: global.sp_recipe_price_mult = clamp(global.sp_recipe_price_mult + (_sp_delta * _sp_step), 0, 2); break;
                case 4: global.sp_price_mult = clamp(global.sp_price_mult + (_sp_delta * _sp_step), 0, 2); break;
                case 5: global.sp_reroll_cost_mult = clamp(global.sp_reroll_cost_mult + (_sp_delta * _sp_step), 0, 2); break;
                case 6: global.sp_hanger_mode = clamp(global.sp_hanger_mode + _sp_delta, 0, 2); break;
                case 7: global.sp_start_gold = clamp(global.sp_start_gold + (_sp_delta * 25), 0, 10000); break;
                case 8: global.sp_activation_mult = clamp(global.sp_activation_mult + (_sp_delta * _sp_step), 0, 2); break;
                case 9: global.sp_building_bonus = clamp(global.sp_building_bonus + _sp_delta, 0, 30); break;
                case 10: global.sp_extra_slots = clamp(global.sp_extra_slots + _sp_delta, 0, 3); break;
                case 11: global.sp_dice_bonus = clamp(global.sp_dice_bonus + _sp_delta, 0, 6); break;
                case 12: global.sp_recipe_store_bonus = clamp(global.sp_recipe_store_bonus + _sp_delta, 0, 1); break;
                case 13: global.sp_active_recipe_bonus = clamp(global.sp_active_recipe_bonus + _sp_delta, 0, 1); break;
                case 14: global.sp_seasons_bonus = clamp(global.sp_seasons_bonus + _sp_delta, 0, 2); break;
                case 15: global.sp_shop_tool_reroll = clamp(global.sp_shop_tool_reroll + _sp_delta, 0, 2); break;
                case 16: global.sp_shop_dice_reroll = clamp(global.sp_shop_dice_reroll + _sp_delta, 0, 2); break;
            }
            if (_sp_delta == 99)
            {
                // R 键：当前项复原为原版
                switch (global.sp_panel_sel)
                {
                    case 0: global.sp_hunger_mult = 1; break;
                    case 1: global.sp_rolls_bonus = 0; break;
                    case 2: global.sp_building_price_mult = 1; break;
                    case 3: global.sp_recipe_price_mult = 1; break;
                    case 4: global.sp_price_mult = 1; break;
                    case 5: global.sp_reroll_cost_mult = 1; break;
                    case 6: global.sp_hanger_mode = 0; break;
                    case 7: global.sp_start_gold = 0; break;
                    case 8: global.sp_activation_mult = 1; break;
                    case 9: global.sp_building_bonus = 0; break;
                    case 10: global.sp_extra_slots = 0; break;
                    case 11: global.sp_dice_bonus = 0; break;
                    case 12: global.sp_recipe_store_bonus = 0; break;
                    case 13: global.sp_active_recipe_bonus = 0; break;
                    case 14: global.sp_seasons_bonus = 0; break;
                    case 15: global.sp_shop_tool_reroll = 1; break;
                    case 16: global.sp_shop_dice_reroll = 1; break;
                }
                global.sp_panel_msg = "已复原为原版";
            }
        }

        // --- 配置档切换（顶部行：点 - / + 、点档名向后切一档、Q/E 前后切）---
        var _sp_pd = 0;
        if (keyboard_check_pressed(81)) { _sp_pd = -1; }
        if (keyboard_check_pressed(69)) { _sp_pd = 1; }
        var _sp_pc_click = false;
        if (_sp_click)
        {
            var _sp_pr_y = global.sp_ui_prof_row_y;
            var _sp_pbw2 = global.sp_ui_btn_w / 2;
            var _sp_pbh2 = global.sp_ui_btn_h / 2;
            if (mouse_y >= _sp_pr_y - _sp_pbh2 && mouse_y <= _sp_pr_y + _sp_pbh2)
            {
                if (mouse_x >= global.sp_ui_prof_minus_x - _sp_pbw2 && mouse_x <= global.sp_ui_prof_minus_x + _sp_pbw2)
                {
                    _sp_pd = -1;
                    _sp_pc_click = true;
                }
                else if (mouse_x >= global.sp_ui_prof_plus_x - _sp_pbw2 && mouse_x <= global.sp_ui_prof_plus_x + _sp_pbw2)
                {
                    _sp_pd = 1;
                    _sp_pc_click = true;
                }
                else if (mouse_x >= global.sp_ui_prof_name_x - 12 && mouse_x <= global.sp_ui_prof_name_x + global.sp_ui_prof_name_w + 12)
                {
                    _sp_pd = 1;
                    _sp_pc_click = true;
                }
            }
        }

        if (global.sp_prof_count > 0 && _sp_pd != 0)
        {
            global.sp_prof_idx += _sp_pd;
            if (global.sp_prof_idx < 0) { global.sp_prof_idx = global.sp_prof_count - 1; }
            if (global.sp_prof_idx >= global.sp_prof_count) { global.sp_prof_idx = 0; }

            // 整套覆盖 15 项数值（面板里手调过的值会被该档覆盖）
            var _sp_pv = global.sp_prof_vals[global.sp_prof_idx];
            global.sp_hunger_mult         = clamp(_sp_pv[0], 0.05, 1);
            global.sp_rolls_bonus         = clamp(round(_sp_pv[1]), 0, 10);
            global.sp_building_price_mult = clamp(_sp_pv[2], 0, 2);
            global.sp_recipe_price_mult   = clamp(_sp_pv[3], 0, 2);
            global.sp_price_mult          = clamp(_sp_pv[4], 0, 2);
            global.sp_reroll_cost_mult    = clamp(_sp_pv[5], 0, 2);
            global.sp_hanger_mode         = clamp(round(_sp_pv[6]), 0, 2);
            global.sp_start_gold          = clamp(round(_sp_pv[7]), 0, 10000);
            global.sp_activation_mult     = clamp(_sp_pv[8], 0, 2);
            global.sp_building_bonus      = clamp(round(_sp_pv[9]), 0, 30);
            global.sp_extra_slots         = clamp(round(_sp_pv[10]), 0, 3);
            global.sp_dice_bonus          = clamp(round(_sp_pv[11]), 0, 6);
            global.sp_recipe_store_bonus  = clamp(round(_sp_pv[12]), 0, 1);
            global.sp_active_recipe_bonus = clamp(round(_sp_pv[13]), 0, 1);
            global.sp_seasons_bonus       = clamp(round(_sp_pv[14]), 0, 2);
            global.sp_shop_tool_reroll    = clamp(round(_sp_pv[15]), 0, 2);
            global.sp_shop_dice_reroll    = clamp(round(_sp_pv[16]), 0, 2);

            global.sp_profile       = global.sp_prof_names[global.sp_prof_idx];
            global.sp_profile_ascii = global.sp_prof_ascii[global.sp_prof_idx];
            if (string_length(global.sp_profile_ascii) <= 0) { global.sp_profile_ascii = global.sp_profile; }

            // 立即落盘（不按 S 也已保存；按键与面板开关不随档切换）
            _sp_do_save = true;
            global.sp_panel_msg = "已切换到 " + global.sp_profile + "（" + string(global.sp_prof_idx + 1) + "/" + string(global.sp_prof_count) + "）";
        }
        else if (_sp_pc_click && global.sp_prof_count <= 0)
        {
            global.sp_panel_msg = "未找到配置档";
        }

        // B = 学习快捷键；S = 保存；Esc = 关闭
        if (keyboard_check_pressed(66))
        {
            global.sp_panel_learn = true;
            global.sp_learn_wait = 3;
            global.sp_panel_msg = "按下任意按键或鼠标键";
        }
        if (keyboard_check_pressed(83))
        {
            _sp_do_save = true;
            global.sp_panel_msg = "已保存";
        }
        if (_sp_do_save)
        {
            var _sp_save = file_text_open_write(global.sp_cfg_file);
            file_text_write_string(_sp_save, "profile=" + global.sp_profile);
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "profile_ascii=" + global.sp_profile_ascii);
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "hunger_mult=" + string(global.sp_hunger_mult));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "rolls_bonus=" + string(global.sp_rolls_bonus));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "building_price_mult=" + string(global.sp_building_price_mult));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "recipe_price_mult=" + string(global.sp_recipe_price_mult));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "price_mult=" + string(global.sp_price_mult));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "reroll_cost_mult=" + string(global.sp_reroll_cost_mult));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "hanger_mode=" + string(global.sp_hanger_mode));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "start_gold=" + string(global.sp_start_gold));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "activation_mult=" + string(global.sp_activation_mult));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "building_bonus=" + string(global.sp_building_bonus));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "extra_slots=" + string(global.sp_extra_slots));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "dice_bonus=" + string(global.sp_dice_bonus));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "recipe_store_bonus=" + string(global.sp_recipe_store_bonus));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "active_recipe_bonus=" + string(global.sp_active_recipe_bonus));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "seasons_bonus=" + string(global.sp_seasons_bonus));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "shop_tool_reroll=" + string(global.sp_shop_tool_reroll));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "shop_dice_reroll=" + string(global.sp_shop_dice_reroll));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "panel_enabled=" + string(global.sp_panel_enabled));
            file_text_writeln(_sp_save);
            file_text_write_string(_sp_save, "panel_hotkey=" + global.sp_panel_hotkey);
            file_text_writeln(_sp_save);
            file_text_close(_sp_save);
        }
        if (keyboard_check_pressed(vk_escape))
        {
            global.sp_panel_open = false;
        }
    }
}
// ===== ScorchpotEasy 面板输入结束 =====
