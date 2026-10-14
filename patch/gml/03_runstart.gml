// ===== ScorchpotEasy Mod v1：新开一局时应用配置（插入 new_run = false; 之前）=====
global.data.ducats += global.sp_start_gold;
global.data.recipe_activation_cost = max(0, round(global.data.recipe_activation_cost * global.sp_activation_mult));
if (global.sp_hanger_mode == 1)
{
    var _sp_half = [];
    for (var _sp_hi = 0; _sp_hi < array_length(global.data.hanger_years); _sp_hi += 2)
    {
        array_push(_sp_half, global.data.hanger_years[_sp_hi]);
    }
    global.data.hanger_years = _sp_half;
}
else if (global.sp_hanger_mode == 2)
{
    global.data.hanger_years = [];
}
// ===== ScorchpotEasy 开局配置结束 =====
