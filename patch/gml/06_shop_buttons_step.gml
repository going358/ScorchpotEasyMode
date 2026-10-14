// ===== ScorchpotEasy Mod v1.6：商店「工具刷新 / 骰子刷新」按钮输入（插在 oController Begin Step）=====
//  重掷写法完全照抄原版每年年初的商店分区重掷（oController Step_0 的 shop_lock 分支）：
//      with (oDie) { if (on_display == true) { instance_destroy(); } }  +  roll_dice_shop();
//      with (oToken) { if (on_display == true) { instance_destroy(); } } + roll_token_shop();
//  收费公式：本局已刷次数 + building_base_reroll_cost（原版 3，受公会特权 -2）——固定价，**不跟随**面板第 6 行「刷新费用倍率」
//  原因：那条倍率是给「建筑 / 食谱」两个原版刷新按钮用的总闸（默认档设 0 = 免费），若跟着它乘，
//        开着「刷新免费」时这两个新按钮的「2 收费」就永远是 0 金币，等于收费档失效（用户实测反馈）。
//  命中后清掉 global.in_mb_left_pressed，避免 oButton_shop 的「点商店外面关店」判定顺手把商店关了
if (room == rGame && global.shop == true && !global.sp_panel_open && instance_exists(oShop))
{
    // 价格每帧算一次，绘制块直接读（同一公式，避免两处漂移）
    global.sp_shop_tool_cost = round(global.sp_shop_tool_count + global.data.building_base_reroll_cost);
    global.sp_shop_dice_cost = round(global.sp_shop_dice_count + global.data.building_base_reroll_cost);

    var _sp_sb_ok = !instance_exists(oTutorial) && !global.codex && !instance_exists(oEndgame);
    var _sp_sb_click = global.in_mb_left_pressed;
    var _sp_sb_mx = mouse_x;
    var _sp_sb_my = mouse_y;

    // ---- 工具刷新 ----
    if (_sp_sb_click && _sp_sb_ok && global.sp_shop_tool_reroll > 0 && global.token_display_limit > 0)
    {
        var _sp_sb_cx = oShop.x - global.sp_sb_tool_dx;
        var _sp_sb_cy = oShop.y - global.sp_sb_tool_dy;
        if (_sp_sb_mx >= _sp_sb_cx - global.sp_sb_half_w && _sp_sb_mx <= _sp_sb_cx + global.sp_sb_half_w
            && _sp_sb_my >= _sp_sb_cy - global.sp_sb_half_h && _sp_sb_my <= _sp_sb_cy + global.sp_sb_half_h)
        {
            if (global.sp_shop_tool_reroll == 2 && global.sp_shop_tool_cost > global.data.ducats)
            {
                oSFX.sfx_menu_button_locked = true;
                oDucat_storage.shake_trigger = true;
            }
            else
            {
                if (global.sp_shop_tool_reroll == 2)
                {
                    global.data.ducats -= global.sp_shop_tool_cost;
                    if (global.sp_shop_tool_cost > 0) { global.sp_shop_tool_count++; }
                }
                with (oToken)
                {
                    if (on_display == true)
                    {
                        instance_destroy();
                    }
                }
                roll_token_shop();
                oSFX.sfx_reroll_buildings = true;
            }
            global.in_mb_left_pressed = false;
        }
    }

    // ---- 骰子刷新 ----
    if (_sp_sb_click && _sp_sb_ok && global.sp_shop_dice_reroll > 0 && global.dice_display_limit > 0)
    {
        var _sp_sb_cx = oShop.x + global.sp_sb_dice_dx;
        var _sp_sb_cy = oShop.y - global.sp_sb_dice_dy;
        if (_sp_sb_mx >= _sp_sb_cx - global.sp_sb_half_w && _sp_sb_mx <= _sp_sb_cx + global.sp_sb_half_w
            && _sp_sb_my >= _sp_sb_cy - global.sp_sb_half_h && _sp_sb_my <= _sp_sb_cy + global.sp_sb_half_h)
        {
            if (global.sp_shop_dice_reroll == 2 && global.sp_shop_dice_cost > global.data.ducats)
            {
                oSFX.sfx_menu_button_locked = true;
                oDucat_storage.shake_trigger = true;
            }
            else
            {
                if (global.sp_shop_dice_reroll == 2)
                {
                    global.data.ducats -= global.sp_shop_dice_cost;
                    if (global.sp_shop_dice_cost > 0) { global.sp_shop_dice_count++; }
                }
                with (oDie)
                {
                    if (on_display == true)
                    {
                        instance_destroy();
                    }
                }
                roll_dice_shop();
                oSFX.sfx_reroll_buildings = true;
            }
            global.in_mb_left_pressed = false;
        }
    }
}
// ===== ScorchpotEasy 商店刷新按钮输入结束 =====
