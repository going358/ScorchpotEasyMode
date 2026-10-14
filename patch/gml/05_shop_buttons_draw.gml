// ===== ScorchpotEasy Mod v1.6.2：商店「工具刷新 / 骰子刷新」按钮绘制（追加到 oTable_hanger Draw End）=====
//  完全照抄原版刷新按钮的做法（oReroll_buildings_Draw_0 / oReroll_recipe_Draw_0）：
//      背景 = 游戏自带木框金币徽章 sShop_building_reroll（239x211，原尺寸不缩放，米色内区实测 147x123 且居中）
//      文字 = scribble(文本) + starting_format(global.fonts.title_m.name, 924463) + align(1, 1)  ← 整块居中，横竖对称
//  这样字体、字号、颜色、金币图标（[sDucat_text] 标签）全部与游戏本体一致，不做手工对齐、不做单轴压缩
//  坐标全部相对 oShop.x / oShop.y，商店上下滑动时按钮跟着走；是否可点由 06_shop_buttons_step.gml 的 global.shop 把关
if (instance_exists(oShop) && !global.sp_panel_open)
{
    var _sp_sb_ok = !instance_exists(oTutorial) && !global.codex && !instance_exists(oEndgame);
    var _sp_sb_font = global.fonts.title_m.name;
    var _sp_sb_colour = 924463;   // 与原版刷新按钮/商店文字同一支颜色
    var _sp_sb_width = 140;       // 文字可用宽度（徽章米色内区 147 宽，留 7 px 余量）
    var _sp_sb_maxsc = 0.9;       // 文字缩放上限（0.9 时两行块高约 115 < 内区 123）

    // ---- 工具刷新 ----
    if (global.sp_shop_tool_reroll > 0 && global.token_display_limit > 0)
    {
        var _sp_sb_cx = oShop.x - global.sp_sb_tool_dx;
        var _sp_sb_cy = oShop.y - global.sp_sb_tool_dy;
        var _sp_sb_hover = _sp_sb_ok
            && mouse_x >= _sp_sb_cx - global.sp_sb_half_w && mouse_x <= _sp_sb_cx + global.sp_sb_half_w
            && mouse_y >= _sp_sb_cy - global.sp_sb_half_h && mouse_y <= _sp_sb_cy + global.sp_sb_half_h;
        var _sp_sb_scale = 1;
        var _sp_sb_alpha = 1;
        if (!_sp_sb_ok) { _sp_sb_alpha = 0.55; }
        else if (_sp_sb_hover) { _sp_sb_scale = 1.03; }

        draw_sprite_ext(sShop_building_reroll, 0, _sp_sb_cx, _sp_sb_cy, _sp_sb_scale, _sp_sb_scale, 0, c_white, _sp_sb_alpha);

        var _sp_sb_txt = "刷新工具";
        if (global.sp_shop_tool_reroll == 2)
        {
            _sp_sb_txt = "刷新工具" + "\n" + string(global.sp_shop_tool_cost) + "[sDucat_text]";
        }
        var _sp_sb_text = scribble(_sp_sb_txt);
        _sp_sb_text.starting_format(_sp_sb_font, _sp_sb_colour);
        _sp_sb_text.align(1, 1);
        _sp_sb_text.line_spacing("85%");
        var _sp_sb_fit = min(_sp_sb_maxsc, _sp_sb_width / max(1, _sp_sb_text.get_width()));
        _sp_sb_text.transform(_sp_sb_scale * _sp_sb_fit, _sp_sb_scale * _sp_sb_fit, 0);
        _sp_sb_text.blend(c_white, _sp_sb_alpha);
        _sp_sb_text.draw(_sp_sb_cx, _sp_sb_cy);
    }

    // ---- 骰子刷新 ----
    if (global.sp_shop_dice_reroll > 0 && global.dice_display_limit > 0)
    {
        var _sp_sb_cx = oShop.x + global.sp_sb_dice_dx;
        var _sp_sb_cy = oShop.y - global.sp_sb_dice_dy;
        var _sp_sb_hover = _sp_sb_ok
            && mouse_x >= _sp_sb_cx - global.sp_sb_half_w && mouse_x <= _sp_sb_cx + global.sp_sb_half_w
            && mouse_y >= _sp_sb_cy - global.sp_sb_half_h && mouse_y <= _sp_sb_cy + global.sp_sb_half_h;
        var _sp_sb_scale = 1;
        var _sp_sb_alpha = 1;
        if (!_sp_sb_ok) { _sp_sb_alpha = 0.55; }
        else if (_sp_sb_hover) { _sp_sb_scale = 1.03; }

        draw_sprite_ext(sShop_building_reroll, 0, _sp_sb_cx, _sp_sb_cy, _sp_sb_scale, _sp_sb_scale, 0, c_white, _sp_sb_alpha);

        var _sp_sb_txt = "刷新骰子";
        if (global.sp_shop_dice_reroll == 2)
        {
            _sp_sb_txt = "刷新骰子" + "\n" + string(global.sp_shop_dice_cost) + "[sDucat_text]";
        }
        var _sp_sb_text = scribble(_sp_sb_txt);
        _sp_sb_text.starting_format(_sp_sb_font, _sp_sb_colour);
        _sp_sb_text.align(1, 1);
        _sp_sb_text.line_spacing("85%");
        var _sp_sb_fit = min(_sp_sb_maxsc, _sp_sb_width / max(1, _sp_sb_text.get_width()));
        _sp_sb_text.transform(_sp_sb_scale * _sp_sb_fit, _sp_sb_scale * _sp_sb_fit, 0);
        _sp_sb_text.blend(c_white, _sp_sb_alpha);
        _sp_sb_text.draw(_sp_sb_cx, _sp_sb_cy);
    }

    // 还原绘制状态（后面还会画别的实例；面板块也在同一事件里）
    draw_set_colour(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
// ===== ScorchpotEasy 商店刷新按钮绘制结束 =====
