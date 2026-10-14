# 《喂龙高手》轻松游玩 Mod（Scorchpot Easy Mod）

[English](README.en.md) | **简体中文**

给 Steam 游戏 **《喂龙高手》（Feed the Scorchpot）** 做的**数值可调 Mod**：进游戏按 **F9** 打开中文控制面板，
随时调整饥饿、掷骰次数、价格、刷新费用、饿怒、开局金币、骰子上限、食谱栏上限、每年季度等 17 项数值，
可以存成多套命名配置档（预置「温和 / 标准 / 激进」）并在游戏面板里直接切换。

- 改的是**你自己电脑上**的游戏数据文件 `data.win`：不常驻后台、不改 exe、不动存档内容、不绕过正版验证、不改成就逻辑。
- 本仓库**不含任何游戏文件或素材**（美术 / 音频 / 文本都没有），只有补丁脚本与安装工具。
- **非官方粉丝项目**：与开发者 Moravian Games、发行方 Indieformer 无隶属关系。
  本项目已获发行方 Indieformer 邮件许可（2026-10-15），条件是**仅限非商业分享**、且**明确标注为非官方粉丝项目**。
- 完全免费、非商业：无付费项、无广告、无捐赠、无任何形式的收费。

> 支持版本：游戏 **1.03**（Windows / Steam）。游戏更新会覆盖 `data.win` 导致补丁失效，重打一次即可恢复。

## 一、需要准备什么

| 项目 | 要求 |
| --- | --- |
| 游戏 | Steam 版《喂龙高手》已安装且能正常启动（**需自备正版**） |
| 系统 | Windows 10 / 11（64 位） |
| 运行环境 | 系统自带的 Windows PowerShell 5.1；官方 CLI 自带 .NET 运行时，通常无需另装 |
| 磁盘 | 约 1 GB 空闲（原版 `data.win` 备份 + 补丁构建中间文件） |
| 网络 | 首次安装需下载 UndertaleModTool CLI（约 60 MB，来自其官方 GitHub Release） |

## 二、安装（约 1 分钟）

1. 下载 [Releases 里的 `ScorchpotEasy-v1.6.4.zip`](https://github.com/going358/ScorchpotEasyMode/releases/latest)
   （或点 `Code → Download ZIP` 下载整仓库），解压到任意目录（路径含中文也没问题）。
2. 双击 **`安装-Mod.bat`**。
3. 出现 `[完成] 安装成功` 后进游戏，按 **F9** 即可打开面板。

仓库里一共三个双击入口：

| 文件 | 用途 |
| --- | --- |
| `安装-Mod.bat` | 首次安装 / 修复安装（**不会覆盖**你已调好的配置数值） |
| `更新后重打.bat` | 游戏升级到**新版本**后重新打补丁（以新版本为基线刷新原版备份） |
| `还原原版.bat` | 还原原版 `data.win` 并删除 Mod 配置文件（卸载用） |

脚本会自动完成：定位游戏目录（读 Steam 注册表 + `libraryfolders.vdf`，支持装在任意盘）→ 备份原版 `data.win` →
下载并校验 UndertaleModTool CLI → 打补丁 → 反编译回读校验（4 组，任一不通过立即中止且**不改动游戏文件**）→ 写入默认配置档。

也可以直接用 PowerShell：

```powershell
.\ScorchpotEasy.ps1 -Install                                    # 安装 / 修复
.\ScorchpotEasy.ps1 -Status                                     # 查看安装状态
.\ScorchpotEasy.ps1 -Repatch                                    # 游戏更新后重打补丁
.\ScorchpotEasy.ps1 -Restore                                    # 还原原版 data.win
.\ScorchpotEasy.ps1 -Install -GameDir "D:\Steam\steamapps\common\Scorchpot"   # 手动指定游戏目录
.\ScorchpotEasy.ps1 -Install -BackupDir "D:\ScorchpotBackup"    # 手动指定备份目录
```

## 三、游戏内使用

| 操作 | 按键 |
| --- | --- |
| 打开 / 关闭面板 | `F9`（默认；面板内按 `B` 可改键，鼠标侧键 / 其它功能键也都支持） |
| 上下选择项目 | `↑` / `↓` |
| 左右调整数值 | `←` / `→` |
| 翻看整屏（共 17 行，一屏 12 行） | 鼠标滚轮 |
| 鼠标点击调整 | 点每行右侧 `-` / `+` |
| 切换配置档 | 点顶部档名 / 点档名右侧 `-` `+` / 键盘 `Q` `E` |
| 当前项恢复原版值 | `R` |
| 保存到配置文件 | `S` |
| 重新绑定开关面板的键 | `B`，再按任意键 / 侧键 |
| 关闭面板 | `Esc`（或再按一次开关键） |

面板只在**对局中**可用（主菜单按快捷键无效）。切换配置档立即生效，并且会顺手写回配置文件；
但面板快捷键与面板开关不随配置档切换。

## 四、可调项（17 项 + 快捷键）

| 键名 | 含义 | 范围 | 原版值（= 不修改） |
| --- | --- | --- | --- |
| `hunger_mult` | 巨龙饥饿需求倍率（越小越轻松） | 0.05 – 1 | 1 |
| `rolls_bonus` | 每季额外掷骰次数 | 0 – 10 | 0 |
| `building_price_mult` | 建筑价格倍率 | 0 – 2 | 1 |
| `recipe_price_mult` | 食谱价格倍率 | 0 – 2 | 1 |
| `price_mult` | 其他商店物品（骰子 / 工具）价格倍率 | 0 – 2 | 1 |
| `reroll_cost_mult` | 商店刷新费用倍率（金币 + 当季食材，0 = 全免费） | 0 – 2 | 1 |
| `hanger_mode` | 饿怒攻击：0 原版 / 1 减半 / 2 关闭 | 0 – 2 | 0 |
| `start_gold` | 新开局额外金币（仅新开一局生效） | 0 – 10000 | 0 |
| `activation_mult` | 食谱激活成本倍率 | 0 – 2 | 1 |
| `building_bonus` | 建筑上限额外 +N | 0 – 30 | 0 |
| `extra_slots` | 商店每类货位 +N | 0 – 3 | 0 |
| `dice_bonus` | 可拥有骰子总数上限 +N | 0 – 6 | 0 |
| `recipe_store_bonus` | 食谱栏上限 +N | 0 – 1 | 0 |
| `active_recipe_bonus` | 可同时激活的食谱数 +N | 0 – 1 | 0 |
| `seasons_bonus` | 每年季度数 +N | 0 – 2 | 0 |
| `shop_tool_reroll` | 商店「刷新工具」按钮：0 关闭 / 1 免费 / 2 收费 | 0 – 2 | 1 |
| `shop_dice_reroll` | 商店「刷新骰子」按钮：0 关闭 / 1 免费 / 2 收费 | 0 – 2 | 1 |
| `panel_enabled` | 是否启用控制面板 | 0 / 1 | 1 |
| `panel_hotkey` | 面板快捷键 | mouse_forward / mouse_back / mouse_middle / mouse_right / F1–F12 / 字母 / SPACE / TAB / ENTER / none | F9 |

**生效时机**：改配置文件后需**重启游戏**才重新读取。局内数值（饥饿、刷新、价格、建筑上限、货位）在新开局或下一次刷新时生效；
骰子上限、食谱栏上限、可激活食谱、每年季度按建筑数每 30 帧重算，约 0.5 秒生效；
两个「刷新」按钮开关立刻生效；`start_gold`、`activation_mult`、`hanger_mode` 只在新开一局时应用（读档继续的旧档不追溯）。

## 五、配置档与命令行

```powershell
.\ScorchpotEasy.ps1 -List                     # 列出全部配置档
.\ScorchpotEasy.ps1 -Use 标准                  # 应用某个配置档
.\ScorchpotEasy.ps1 -Set hunger_mult=0.4       # 修改当前档某项（可写多组）
.\ScorchpotEasy.ps1 -New 自定义 -From 标准      # 以某档为模板新建
.\ScorchpotEasy.ps1 -Rename 标准 -To 舒适       # 重命名
.\ScorchpotEasy.ps1 -SetDefault 标准           # 设为默认档
.\ScorchpotEasy.ps1 -Delete 自定义             # 删除
.\ScorchpotEasy.ps1 -Launch                    # 启动游戏
```

配置文件（每行一条 `key=value`，UTF-8 无 BOM）：

- `%LOCALAPPDATA%\Scorchpot\ScorchpotEasy.cfg` —— 当前生效的数值。**删掉它 = 完全原版行为**（补丁仍在但不生效）。
- `%LOCALAPPDATA%\Scorchpot\ScorchpotProfiles.cfg` —— 游戏面板里切档用的索引，由本工具自动重写，游戏只读。
- `profiles/*.json` —— 各配置档的数值。

游戏内最多循环 12 个配置档（超出按名称排序取前 12）。

> `-Install` 与 `-Repatch` **不会覆盖已有配置文件**：你在游戏面板里调好的数值会原样保留。
> 想把数值换成某个配置档，用 `-Use <档名>` 显式切换；只有第一次安装（还没有配置文件时）才会写入默认档。

## 六、常见问题

**游戏更新后 Mod 失效了？** 正常现象：Steam 更新会覆盖 `data.win`。重跑一次 `-Repatch`（或双击 `安装-Mod.bat`）即可。

- 如果游戏**版本没变**（只是文件被覆盖）：双击 `安装-Mod.bat` 或跑 `-Repatch` 就能恢复。
- 如果游戏**升级到了新版本**：脚本会打印「版本未确认」并自动中止（不会动你的游戏文件）。
  这时双击 **`更新后重打.bat`**（等价于 `-Repatch -RefreshBackup`）：它会把原版备份刷新成新版本、再重新打补丁。

**Steam「验证游戏文件完整性」之后失效？** 同样会把 `data.win` 还原成原版，`-Repatch` 即可。

**我装的是旧版，配置里还是鼠标前进侧键，怎么换成 F9？**（v1.6.4 起新安装的默认键就是 F9）
游戏内打开面板后按 `B`，再按 `F9` 即可重设；或者运行 `.\ScorchpotEasy.ps1 -Set panel_hotkey=F9`（重启游戏生效）。
旧配置**不会**被自动改写：你手动改过的键位始终原样保留。

**下载 UndertaleModTool 失败？** 脚本会打印官方下载地址；手动下载 `UTMT_CLI_v0.9.2.0-Windows.zip`，
放到工具目录的 `tools\_cache\` 下再重跑，脚本会校验 SHA256 后解压。

**怎么彻底卸载？** 双击 `还原原版.bat`（或 `-Restore`）：用备份覆盖回原版 `data.win` 并删除 Mod 配置文件。
之后把本工具的文件夹删掉即可，游戏恢复成完全原版。

**会不会影响成就？** 成就解锁逻辑没有被修改；但数值放宽当然会让成就更容易达成——这是使用 Mod 的必然结果，请自行判断。

**支持 Mac 版吗？** 不支持，本工具只处理 Windows 版。

## 七、已知限制（节选）

1. 游戏更新 / 校验完整性会覆盖 `data.win`，需要 `-Repatch`。
2. 面板文案使用游戏内置的简体中文字形（`fntHan_l/m/s`，各 1568 字形），少数汉字不在其中，
   面板用同义写法回避（构建时会做字形体检，缺字直接构建失败，不会出现方块）。
3. 配置档名同样受字形白名单限制；`-New/-Rename` 会拦截不可显示的名字（可用 `-Force` 强制，届时游戏内自动显示英文名）。
4. 面板与两个刷新按钮的文案是简体中文硬编码：把游戏语言切换成英文 / 日文时，它们仍显示中文。
5. 视觉层面的既有小瑕疵：骰子盒在第 7 颗起会有溢出（功能正常）；食谱栏第 7 张会略微超出托盘背景（仍在屏幕内）。
6. 加成不影响游戏自带的进度提示文案（例如「再建 N 座贸易站使食谱栏 +1」仍按原版显示）。
7. 单人离线使用，不涉及联机、反作弊，也不修改存档文件本身。

## 八、免责声明

本 Mod 是**非官方粉丝项目**，与《喂龙高手》的开发者 Moravian Games 及其发行方 Indieformer **无隶属关系**。
本项目在发布前已取得发行方 Indieformer 的书面（邮件）许可（2026-10-15），并遵守其提出的两项条件：
**仅限非商业分享**、**明确标注为非官方粉丝项目**（本仓库的 About、README 首屏与本声明均已明示）。

- 使用前请**自备正版游戏**；本仓库不包含、也不分发游戏的任何文件（`data.win`、美术、音频、文本均不包含）。
- 本 Mod 不修改游戏存档内容、不绕过任何正版验证或 DRM、不放宽成就解锁逻辑。
- 因游戏更新、文件校验或其它原因导致 Mod 失效、数值表现与预期不同，均属预期范围；请自行备份重要存档。
- 一切使用后果由使用者自行承担。若权利人对此项目有异议，请联系我，我会**立即下架**。

## 九、许可

本仓库自身代码以 **MIT License** 发布，见 [LICENSE](LICENSE)。
运行时依赖 UndertaleModTool（**GPL-3.0**，由脚本从官方发布页下载、不随本仓库分发），详见 [THIRD_PARTY.md](THIRD_PARTY.md)。

版本历史见 [CHANGELOG.md](CHANGELOG.md)。
