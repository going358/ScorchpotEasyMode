# Scorchpot Easy Mod (unofficial)

**English** | [简体中文](README.md)

A **number-tweaking mod** for the Steam game **Feed the Scorchpot**. Press **F9** in game to open
an in-game panel and adjust hunger, extra rolls, prices, reroll costs, hanger years, starting gold, dice limit, recipe slots,
seasons per year and more — 17 settings in total, storable as named profiles (presets: Relaxed / Standard / Bold) that you can
switch right inside the game.

- It patches **your own copy's** game data file (`data.win`): no background process, no changes to the .exe, no save editing,
  no DRM bypass, no achievement logic changes.
- This repository contains **no game files or assets** (no art, audio, or text) — only patch scripts and the installer.
- **Unofficial fan project**: not affiliated with Moravian Games or Indieformer.
  It was shared with Indieformer's written permission (email, 2026-10-15), on the condition that it stays
  **non-commercial** and is **clearly labelled as an unofficial fan project**.
- Completely free and non-commercial: no paid tiers, no ads, no donations, no monetization of any kind.

> Supported game version: **1.03** (Windows / Steam). A game update overwrites `data.win` and disables the mod; re-running the
> patcher restores it.

## Requirements

| Item | Requirement |
| --- | --- |
| Game | An installed, working Steam copy of Feed the Scorchpot (**you must own the game**) |
| OS | Windows 10 / 11 (64-bit) |
| Runtime | Built-in Windows PowerShell 5.1; the official CLI is self-contained, so .NET usually needs no separate install |
| Disk | ~1 GB free (vanilla `data.win` backup + build artifacts) |
| Network | First install downloads UndertaleModTool CLI (~60 MB) from its official GitHub release |

Note: the in-game panel and its text are **Simplified Chinese only** (hard-coded), regardless of your game language.

## Install (about a minute)

1. Download `ScorchpotEasy-v1.6.4.zip` from [Releases](https://github.com/going358/ScorchpotEasyMode/releases/latest)
   (or `Code → Download ZIP` for the whole repo) and extract it anywhere.
2. Double-click **`安装-Mod.bat`** (the filename means "install mod").
3. When you see `[完成] 安装成功` / `[DONE] Installed`, launch the game and press **F9**.

Three double-click entry points:

| File | Purpose |
| --- | --- |
| `安装-Mod.bat` | Install / repair (**never overwrites** values you have already tuned) |
| `更新后重打.bat` | Re-apply after the game was updated to a **new version** (re-bases the vanilla backup) |
| `还原原版.bat` | Restore the vanilla `data.win` and delete the mod config (uninstall) |

The script will: locate your game folder (Steam registry + `libraryfolders.vdf`, works on any drive) → back up the vanilla
`data.win` → download and SHA256-verify UndertaleModTool CLI → apply the patch → verify the result by decompiling it back
(4 check groups; any failure aborts **without touching your game files**) → write the default profile.

Prefer PowerShell?

```powershell
.\ScorchpotEasy.ps1 -Install                                   # install / repair
.\ScorchpotEasy.ps1 -Status                                    # show status
.\ScorchpotEasy.ps1 -Repatch                                   # re-apply after a game update
.\ScorchpotEasy.ps1 -Restore                                   # restore vanilla data.win
.\ScorchpotEasy.ps1 -Install -GameDir "D:\Steam\steamapps\common\Scorchpot"   # custom game path
.\ScorchpotEasy.ps1 -Install -BackupDir "D:\ScorchpotBackup"                  # custom backup path
```

## In-game controls

| Action | Key |
| --- | --- |
| Open / close panel | `F9` (default; press `B` in the panel to rebind — mouse side buttons and other function keys also work) |
| Select row | `↑` / `↓` |
| Adjust value | `←` / `→` |
| Scroll the list (17 rows, 12 per screen) | Mouse wheel |
| Click to adjust | The `-` / `+` boxes on each row |
| Switch profile | Click the profile name / its `-` `+` boxes / keys `Q` `E` |
| Reset the selected row | `R` |
| Save to config file | `S` |
| Rebind the open key | `B`, then any key / side button |
| Close panel | `Esc` |

The panel works **during a run only** (not in the main menu). Profile switching applies immediately; the panel hotkey itself is
not switched together with a profile.

## Settings (17 + hotkey)

| Key | Meaning | Range | Vanilla value |
| --- | --- | --- | --- |
| `hunger_mult` | Dragon hunger demand multiplier (lower = easier) | 0.05 – 1 | 1 |
| `rolls_bonus` | Extra dice rolls per season | 0 – 10 | 0 |
| `building_price_mult` | Building price multiplier | 0 – 2 | 1 |
| `recipe_price_mult` | Recipe price multiplier | 0 – 2 | 1 |
| `price_mult` | Other shop items (dice / tools) price multiplier | 0 – 2 | 1 |
| `reroll_cost_mult` | Shop reroll cost multiplier (gold **and** seasonal ingredient, 0 = free) | 0 – 2 | 1 |
| `hanger_mode` | Hanger attack: 0 vanilla / 1 halved / 2 disabled | 0 – 2 | 0 |
| `start_gold` | Extra starting gold (new runs only) | 0 – 10000 | 0 |
| `activation_mult` | Recipe activation cost multiplier | 0 – 2 | 1 |
| `building_bonus` | Extra building limit +N | 0 – 30 | 0 |
| `extra_slots` | Extra shop slot per column +N | 0 – 3 | 0 |
| `dice_bonus` | Extra total dice limit +N | 0 – 6 | 0 |
| `recipe_store_bonus` | Extra recipe slots +N | 0 – 1 | 0 |
| `active_recipe_bonus` | Extra simultaneously active recipes +N | 0 – 1 | 0 |
| `seasons_bonus` | Extra seasons per year +N | 0 – 2 | 0 |
| `shop_tool_reroll` | Shop "reroll tools" button: 0 hidden / 1 free / 2 paid | 0 – 2 | 1 |
| `shop_dice_reroll` | Shop "reroll dice" button: 0 hidden / 1 free / 2 paid | 0 – 2 | 1 |
| `panel_enabled` | Enable the in-game panel | 0 / 1 | 1 |
| `panel_hotkey` | Panel hotkey | mouse_forward / mouse_back / mouse_middle / mouse_right / F1–F12 / letters / SPACE / TAB / ENTER / none | F9 |

**When changes apply:** the config file is read on game start (restart after editing). In-run numbers (hunger, reroll costs,
prices, building limit, slots) apply on a new run or the next reroll; dice / recipe-slot / active-recipe / seasons bonuses are
recomputed every 30 frames (~0.5 s); the two shop buttons apply immediately; `start_gold`, `activation_mult` and `hanger_mode`
apply to newly started runs only.

## Files

- `%LOCALAPPDATA%\Scorchpot\ScorchpotEasy.cfg` — active values. **Delete it to get vanilla behaviour back** (the patch stays but does nothing).
- `%LOCALAPPDATA%\Scorchpot\ScorchpotProfiles.cfg` — profile index used by the in-game panel (written by the tool, read-only for the game).
- `profiles/*.json` — the profiles themselves. Up to 12 profiles are cycled in game.

> `-Install` and `-Repatch` **never overwrite an existing config file**: values you tuned in the panel are kept.
> To switch to a profile explicitly, use `-Use <name>`. Only the very first install (no config yet) writes the default profile.

## FAQ

**The mod stopped working after a game update.** Expected: updates overwrite `data.win`. Run `-Repatch` (or `安装-Mod.bat`) again.

- Same game version (the file was just overwritten): run `-Repatch` or double-click `安装-Mod.bat`.
- The game moved to a **new version**: the tool prints "version unconfirmed" and aborts without touching your files.
  Double-click **`更新后重打.bat`** (same as `-Repatch -RefreshBackup`) to re-base the vanilla backup and re-apply the patch.

**"Verify integrity of game files" disabled it too.** Same cause, same fix.

**I installed an older version and the config still says the mouse forward side button — how do I switch to F9?**
(New installs since v1.6.4 default to F9.) Open the panel in game and press `B`, then press `F9`; or run
`.\ScorchpotEasy.ps1 -Set panel_hotkey=F9` (restart the game afterwards). Existing configs are **never** rewritten
automatically — a hotkey you changed yourself stays exactly as it is.

**The tool download failed.** The script prints the official URL; download `UTMT_CLI_v0.9.2.0-Windows.zip` manually, drop it in
`tools\_cache\`, and run again — it verifies SHA256 before extracting.

**Uninstall?** Run `还原原版.bat` (or `-Restore`): it restores the vanilla `data.win` from the backup and deletes the mod config.
Then delete this folder.

**Achievements?** Achievement logic is untouched, but easier numbers naturally make achievements easier. Use at your discretion.

**macOS?** Not supported — Windows only.

## Known limitations (selected)

1. Game updates and "verify integrity" restore `data.win`; re-run `-Repatch`.
2. Panel text uses the game's built-in Simplified Chinese glyph subset (1568 glyphs per font); a few characters are missing and
   are worked around with synonyms. The build fails loudly if a glyph is unavailable (no tofu boxes in game).
3. Profile names use the same whitelist; `-New` / `-Rename` reject un-drawable names (use `-Force` to override — the panel then
   shows an English name).
4. Panel and button labels are hard-coded Simplified Chinese.
5. Cosmetic: the dice box overflows from the 7th die onward (functionality unaffected); the 7th recipe card slightly exceeds its tray background.
6. Bonus values do not rewrite the game's own progress hints (e.g. "build N more trading posts").
7. Single-player, offline; no game files or saves are modified.

## Disclaimer

Unofficial fan project, **not affiliated** with Moravian Games or Indieformer.
It was published with Indieformer's written (email) permission dated 2026-10-15, under their two conditions:
**non-commercial sharing only**, and **clearly labelled as an unofficial fan project** (the repository description,
the top of both READMEs and this notice all say so).
You need to own the game; this repository ships no game files. It does not modify saves, bypass DRM, or change achievement
unlocking. Updates may break it. Use at your own risk. If a rights holder objects, contact me and I will **take it down immediately**.

## License

This repository is MIT-licensed — see [LICENSE](LICENSE).
It uses UndertaleModTool (**GPL-3.0**), downloaded at runtime from its official release and **not** redistributed here — see
[THIRD_PARTY.md](THIRD_PARTY.md). Changelog: [CHANGELOG.md](CHANGELOG.md).
