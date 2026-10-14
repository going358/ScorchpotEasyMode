# 第三方组件 / Third-party components

本仓库**只包含补丁脚本与工具脚本**，不含《喂龙高手》（Feed the Scorchpot）的任何游戏文件或素材。
本仓库不打包任何第三方二进制；运行时所需的 UndertaleModTool CLI 由脚本从官方发布页下载。

This repository only ships patch/tool scripts. It contains **no game files or assets** from
Feed the Scorchpot, and it does not bundle any third-party binaries. The tool it needs at
runtime (UndertaleModTool CLI) is downloaded by the script from the official release page.

## UndertaleModTool（运行时下载，不随仓库分发）

- 项目：https://github.com/UnderminersTeam/UndertaleModTool
- 版本：0.9.2.0（CLI / Windows）
- 许可证：**GNU GPL-3.0**（详见其仓库中的 `LICENSE.txt`，下载解压后位于 `tools/utmt-cli/LICENSE.txt`）
- 用途：把本仓库的补丁脚本应用到玩家自己电脑上的游戏数据文件 `data.win`
- 分发方式：由 `ScorchpotEasy.ps1`（`-FetchTools`，或首次 `-Install`）从官方 GitHub Release 下载并校验 SHA256，
  解压到本地 `tools/utmt-cli/`（该目录已在 `.gitignore` 中排除，不进入本仓库）
- 说明：本仓库的脚本以独立程序的方式调用该工具，不修改、不链接其代码，因此本仓库自身按 MIT 许可发布

## .NET 运行时

官方 CLI 发行包为 self-contained 构建（自带 .NET 运行时），一般无需另行安装 .NET。

## 游戏本体

《喂龙高手》/ Feed the Scorchpot 的版权归其开发者与发行方所有（Moravian Games / Indieformer）。
本 Mod 是非官方项目，与上述公司无任何关联，也不包含其任何美术、音频、文本或代码资产。
