# ============================================================
#  《喂龙高手》轻松游玩 Mod —— 配置档管理 / 安装 / 还原工具
#  用法示例：
#    .\ScorchpotEasy.ps1 -Status
#    .\ScorchpotEasy.ps1 -List
#    .\ScorchpotEasy.ps1 -Use 标准
#    .\ScorchpotEasy.ps1 -Set hunger_mult=0.4 -Set rolls_bonus=3
#    .\ScorchpotEasy.ps1 -Install          # 备份原版 + 打补丁 + 应用默认配置
#    .\ScorchpotEasy.ps1 -Restore          # 还原原版 data.win
#    .\ScorchpotEasy.ps1 -Repatch          # 游戏更新后按原版备份重打补丁
#    .\ScorchpotEasy.ps1 -Repatch -RefreshBackup   # 游戏升级到新版本后：以新版本原版为基线重打
#    .\ScorchpotEasy.ps1 -FetchTools       # 只下载 UndertaleModTool CLI（首次安装会自动触发）
#    .\ScorchpotEasy.ps1 -GameDir <路径>   # 手动指定游戏目录（默认自动探测 Steam 库）
#    .\ScorchpotEasy.ps1 -RefreshBackup    # 以当前游戏文件为准重建原版备份（游戏更新后用）
#  v1.2：新增游戏内配置档索引导出（%LOCALAPPDATA%\Scorchpot\ScorchpotProfiles.cfg），
#        档名按 patch/font-glyphs-hans.txt 白名单校验，保证游戏面板能画出档名。
#  v1.6.3（公开版）：游戏目录改为自动探测（Steam 注册表 + libraryfolders.vdf），不再硬编码
#        安装路径；UndertaleModTool CLI 缺失时自动从官方 Release 下载并校验 SHA256。
#  v1.6.4：默认面板按键由「鼠标前进侧键」改为 F9（panel_hotkey=F9）；已装旧版的配置不会被
#        自动改写，想换键可在游戏内面板按 B 重设，或用 -Set panel_hotkey=F9 手动指定。
# ============================================================
[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Restore,
    [switch]$Repatch,
    [switch]$Status,
    [switch]$List,
    [string]$Show,
    [string]$New,
    [string]$From,
    [string]$Use,
    [string]$SetDefault,
    [string]$Rename,
    [string]$To,
    [string[]]$Set,
    [string]$Delete,
    [switch]$Launch,
    [switch]$Force,
    [switch]$FetchTools,
    [switch]$RefreshBackup,
    [string]$GameDir,
    [string]$BackupDir
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 统一错误出口：任何异常都只打印一行中文提示并以退出码 1 结束，方便双击 .bat 时阅读
trap {
    Write-Host ""
    Write-Host "[失败] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "如无法自行解决，请把上面这行原文发给我。" -ForegroundColor Red
    exit 1
}

$RepoDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProfilesDir = Join-Path $RepoDir 'profiles'
$PatchDir    = Join-Path $RepoDir 'patch'
$GmlDir      = Join-Path $PatchDir 'gml'
$ApplyScript = Join-Path $PatchDir 'apply_mod.csx'
$UtmtCli     = Join-Path $RepoDir 'tools\utmt-cli\UndertaleModCli.exe'
$LogsDir     = Join-Path $RepoDir 'logs'

$UtmtCliDir     = Split-Path -Parent $UtmtCli
$ToolsDir       = Join-Path $RepoDir 'tools'
$ToolCacheDir   = Join-Path $ToolsDir '_cache'
$UtmtCliVersion = '0.9.2.0'
$UtmtCliUrl     = 'https://github.com/UnderminersTeam/UndertaleModTool/releases/download/0.9.2.0/UTMT_CLI_v0.9.2.0-Windows.zip'
$UtmtCliSha256  = 'E7573E45D107BE34F81F955C6E4AFC3C7C8F2628E5A6F307A871E3825B3DFB40'
$UtmtCliSize    = 62585935

$KnownVanillaHashes = @(
    '85C7D65DC3AC241131745277DA563EA0CCF419424D1A66CDF112685925FDD265'
)

function Get-SteamLibraryRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    $steamPaths = New-Object System.Collections.Generic.List[string]
    foreach ($key in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam')) {
        try { $item = Get-ItemProperty -Path $key -ErrorAction Stop } catch { continue }
        foreach ($prop in @('SteamPath', 'InstallPath')) {
            $v = $item.$prop
            if ($v) { $steamPaths.Add(($v -replace '/', '\')) }
        }
    }
    foreach ($sp in $steamPaths) {
        if (-not (Test-Path $sp)) { continue }
        if (-not $roots.Contains($sp)) { $roots.Add($sp) }
        $vdf = Join-Path $sp 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw -ErrorAction SilentlyContinue), '"path"\s+"([^"]+)"')) {
                $lp = $m.Groups[1].Value -replace '\\\\', '\'
                if ((Test-Path $lp) -and -not $roots.Contains($lp)) { $roots.Add($lp) }
            }
        }
    }
    return $roots
}

function Resolve-GameDir {
    foreach ($root in @(Get-SteamLibraryRoots)) {
        $p = Join-Path $root 'steamapps\common\Scorchpot'
        if (Test-Path (Join-Path $p 'data.win')) { return $p }
    }
    return $null
}

if ($GameDir) {
    if (-not (Test-Path -LiteralPath $GameDir)) { throw "-GameDir 指定的游戏目录不存在：$GameDir" }
}
else { $GameDir = Resolve-GameDir }
$GameData = if ($GameDir) { Join-Path $GameDir 'data.win' } else { $null }
$GameExe  = if ($GameDir) { Join-Path $GameDir 'Scorchpot.exe' } else { $null }

if ($BackupDir -and (-not (Test-Path -LiteralPath (Split-Path -Parent $BackupDir)))) {
    throw "-BackupDir 指定的位置无效：$BackupDir（所在盘符或上级目录不存在）"
}
if (-not $BackupDir) {
    $legacyBackup = $null
    if ($GameDir) {
        $legacyBackup = Get-ChildItem -LiteralPath (Split-Path -Parent $GameDir) -Directory -Filter 'Scorchpot_backup*' -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName 'data.win.orig') } |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if ($legacyBackup) { $BackupDir = $legacyBackup }
    else { $BackupDir = Join-Path $env:LOCALAPPDATA 'ScorchpotEasyBackup' }
}
$BackupData = Join-Path $BackupDir 'data.win.orig'

$SaveDir    = Join-Path $env:LOCALAPPDATA 'Scorchpot'
$CfgPath    = Join-Path $SaveDir 'ScorchpotEasy.cfg'
$DefaultFile = Join-Path $ProfilesDir '_default.txt'
$WorkDir    = Join-Path $RepoDir 'work'
$ProfilesIndex = Join-Path $SaveDir 'ScorchpotProfiles.cfg'
$GlyphFile     = Join-Path $PatchDir 'font-glyphs-hans.txt'
$MaxProfiles   = 12

$OriginalHash = $KnownVanillaHashes[0]

$KeyOrder = @('hunger_mult','rolls_bonus','building_price_mult','recipe_price_mult','price_mult','reroll_cost_mult','hanger_mode','start_gold','activation_mult','building_bonus','extra_slots','dice_bonus','recipe_store_bonus','active_recipe_bonus','seasons_bonus','shop_tool_reroll','shop_dice_reroll','panel_enabled','panel_hotkey')

# 各项取值范围（数值项，与游戏内面板的 clamp 保持一致；-Set 时据此拦截）
$KeyRanges = @{
    hunger_mult         = @(0.05, 1)
    rolls_bonus         = @(0, 10)
    building_price_mult = @(0, 2)
    recipe_price_mult   = @(0, 2)
    price_mult          = @(0, 2)
    reroll_cost_mult    = @(0, 2)
    hanger_mode         = @(0, 2)
    start_gold          = @(0, 10000)
    activation_mult     = @(0, 2)
    building_bonus      = @(0, 30)
    extra_slots         = @(0, 3)
    dice_bonus          = @(0, 6)
    recipe_store_bonus  = @(0, 1)
    active_recipe_bonus = @(0, 1)
    seasons_bonus       = @(0, 2)
    shop_tool_reroll    = @(0, 2)
    shop_dice_reroll    = @(0, 2)
}

function Ensure-Dirs {
    foreach ($d in @($ProfilesDir, $LogsDir, $WorkDir, $SaveDir)) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    }
}

function Get-DefaultProfile {
    if (Test-Path $DefaultFile) {
        $n = (Get-Content $DefaultFile -Raw -Encoding UTF8).Trim()
        if ($n) { return $n }
    }
    return '标准'
}

function Get-ProfilePath([string]$Name) { Join-Path $ProfilesDir ("$Name.json") }

function Read-Profile([string]$Name) {
    $p = Get-ProfilePath $Name
    if (-not (Test-Path $p)) { throw "配置档不存在：$Name（可用 -List 查看）" }
    return (Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Write-Profile($Obj) {
    $p = Get-ProfilePath $Obj.name
    $json = $Obj | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($p, $json, (New-Object System.Text.UTF8Encoding($false)))
}

function Write-Cfg([string]$Name) {
    $o = Read-Profile $Name
    $ascii = if ($o.ascii) { $o.ascii } else { $o.name }
    $parts = @("profile=$($o.name)", "profile_ascii=$ascii")
    foreach ($k in $KeyOrder) {
        $v = $o.$k
        if ($null -eq $v) { continue }
        $parts += "$k=$v"
    }
    $line = ($parts -join "`n") + "`n"
    [System.IO.File]::WriteAllText($CfgPath, $line, (New-Object System.Text.UTF8Encoding($false)))
    return $CfgPath
}

# ---------- 配置档索引：游戏内切档的唯一数据来源（游戏只读，工具独写）----------
function Get-GlyphSet {
    if (-not (Test-Path $GlyphFile)) { return $null }
    $txt = Get-Content $GlyphFile -Raw -Encoding UTF8
    $set = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($ch in $txt.ToCharArray()) { $null = $set.Add([string]$ch) }
    return $set
}

function Get-MissingGlyphs([string]$Text, $GlyphSet) {
    if ($null -eq $GlyphSet) { return @() }
    $miss = @()
    foreach ($ch in $Text.ToCharArray()) {
        if (-not $GlyphSet.Contains([string]$ch)) { $miss += [string]$ch }
    }
    return @($miss | Select-Object -Unique)
}

function Resolve-DisplayName($Profile, [int]$Position, $GlyphSet) {
    if ($null -eq $GlyphSet) {
        if ($Profile.ascii) { return [string]$Profile.ascii }
        return "Profile $($Position + 1)"
    }
    $name = [string]$Profile.name
    if ((Get-MissingGlyphs $name $GlyphSet).Count -eq 0) { return $name }
    if ($Profile.ascii -and (Get-MissingGlyphs ([string]$Profile.ascii) $GlyphSet).Count -eq 0) { return [string]$Profile.ascii }
    return "Profile $($Position + 1)"
}

# 导出顺序：默认档排第 0 位，其余按名称升序
function Get-ProfileNames {
    $names = @(Get-ChildItem $ProfilesDir -Filter '*.json' -ErrorAction SilentlyContinue |
        ForEach-Object { (Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).name } |
        Where-Object { $_ } | Sort-Object -Unique)
    $def = Get-DefaultProfile
    $ordered = New-Object System.Collections.Generic.List[string]
    if ($names -contains $def) { $ordered.Add($def) }
    foreach ($n in $names) { if ($n -ne $def) { $ordered.Add($n) } }
    return $ordered.ToArray()
}

function Get-IndexPlan {
    $names = Get-ProfileNames
    $trimmed = $false
    if ($names.Count -gt $MaxProfiles) {
        $names = @($names[0..($MaxProfiles - 1)])
        $trimmed = $true
    }
    $glyphSet = Get-GlyphSet
    $displays = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $names.Count; $i++) {
        $displays.Add((Resolve-DisplayName (Read-Profile $names[$i]) $i $glyphSet))
    }
    return [pscustomobject]@{ Names = @($names); Displays = @($displays.ToArray()); GlyphSet = $glyphSet; Trimmed = $trimmed }
}

function Write-ProfilesIndex {
    Ensure-Dirs
    $plan = Get-IndexPlan
    if ($plan.Trimmed) {
        Write-Host "配置档数量超过游戏内上限 $MaxProfiles，只导出前 $MaxProfiles 档。" -ForegroundColor Yellow
    }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('version=1')
    $lines.Add("count=$($plan.Names.Count)")
    for ($i = 0; $i -lt $plan.Names.Count; $i++) {
        $o = Read-Profile $plan.Names[$i]
        $disp = $plan.Displays[$i]
        if ($disp -ne $o.name) {
            Write-Host "提示：配置档「$($o.name)」含游戏内无法显示的字符，面板里显示为「$disp」。" -ForegroundColor Yellow
        }
        $ascii = if ($o.ascii) { $o.ascii } else { $o.name }
        $lines.Add("p${i}_name=$disp")
        $lines.Add("p${i}_ascii=$ascii")
        foreach ($k in $KeyOrder) {
            if ($k -eq 'panel_hotkey' -or $k -eq 'panel_enabled') { continue }
            $v = $o.$k
            if ($null -eq $v) { continue }
            $lines.Add("p${i}_$k=$v")
        }
    }
    [System.IO.File]::WriteAllText($ProfilesIndex, (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    return $ProfilesIndex
}

function Assert-DrawableName([string]$Name) {
    $glyphSet = Get-GlyphSet
    if ($null -eq $glyphSet) { return }
    $miss = Get-MissingGlyphs $Name $glyphSet
    if ($miss.Count -gt 0 -and -not $Force) {
        throw "档名「$Name」含游戏内无法显示的字符：$($miss -join ' ')（游戏内置中文字形缺这些字，面板会画成方块）。换个名字，或加 -Force 强制使用（届时游戏内自动改显示英文名）。"
    }
}

function Get-GameState {
    if (-not (Test-Path $GameData)) { return 'missing' }
    $h = (Get-FileHash $GameData -Algorithm SHA256).Hash
    if ($h -eq $OriginalHash) { return 'original' }
    if (Test-Path $BackupData) {
        $hb = (Get-FileHash $BackupData -Algorithm SHA256).Hash
        if ($h -eq $hb) { return 'original' }
    }
    return 'patched-or-unknown'
}

function Assert-GameNotRunning {
    $p = Get-Process -Name Scorchpot -ErrorAction SilentlyContinue
    if ($p) { throw '《喂龙高手》正在运行，请先关闭游戏再执行该操作。' }
}

function New-ProfileObject([string]$Name, [string]$Desc) {
    return [pscustomobject]@{
        name = $Name
        ascii = $Name
        desc = $Desc
        hunger_mult = 1
        rolls_bonus = 0
        building_price_mult = 1
        recipe_price_mult = 1
        price_mult = 1
        reroll_cost_mult = 1
        hanger_mode = 0
        start_gold = 0
        activation_mult = 1
        building_bonus = 0
        extra_slots = 0
        dice_bonus = 0
        recipe_store_bonus = 0
        active_recipe_bonus = 0
        seasons_bonus = 0
        shop_tool_reroll = 1
        shop_dice_reroll = 1
        panel_enabled = 1
        panel_hotkey = 'F9'
    }
}

function Assert-GameDir {
    if (-not $GameDir) {
        throw '未找到《喂龙高手》安装目录。请确认游戏已通过 Steam 安装，或用 -GameDir "<游戏目录>" 手动指定（该目录下应有 data.win 与 Scorchpot.exe）。'
    }
    if (-not (Test-Path (Join-Path $GameDir 'data.win'))) {
        throw "指定目录里没有 data.win：$GameDir"
    }
}

function Assert-UtmtRuntime {
    if (Test-Path (Join-Path $UtmtCliDir 'coreclr.dll')) { return }   # 官方 CLI 自带运行时，无需另装 .NET
    $listed = $null
    try { $listed = & dotnet --list-runtimes 2>$null } catch { }
    if ($listed -match 'Microsoft\.WindowsDesktop\.App 8\.') { return }
    throw 'UndertaleModTool CLI 需要 .NET 8 桌面运行时。请先安装：winget install Microsoft.DotNet.DesktopRuntime.8（或到 https://dotnet.microsoft.com/download/dotnet/8.0 手动下载），然后重新运行本工具。'
}

# 下载官方 UndertaleModTool CLI（约 60 MB），校验大小与 SHA256 后解压到 tools\utmt-cli
function Install-UtmtCli {
    if (Test-Path $UtmtCli) { return $UtmtCli }
    New-Item -ItemType Directory -Force -Path $ToolCacheDir | Out-Null
    $zip  = Join-Path $ToolCacheDir "UTMT_CLI_v$UtmtCliVersion-Windows.zip"
    $part = "$zip.part"
    if (-not (Test-Path $zip)) {
        Write-Host "未检测到 UndertaleModTool CLI v$UtmtCliVersion，开始下载（约 60 MB，官方 GitHub Release）……" -ForegroundColor Cyan
        Write-Host "  来源：$UtmtCliUrl"
        Write-Host "  目标：$zip"
        try {
            Invoke-WebRequest -Uri $UtmtCliUrl -OutFile $part -UseBasicParsing
        } catch {
            throw "下载 UndertaleModTool CLI 失败：$($_.Exception.Message)`n可手动下载上述地址，把 zip 放到 $zip 后重新运行本工具。"
        }
        $partSize = (Get-Item $part).Length
        if ($partSize -ne $UtmtCliSize) { throw "下载文件大小不符（期望 $UtmtCliSize 字节，实际 $partSize 字节），已停止：$part" }
        $partHash = (Get-FileHash $part -Algorithm SHA256).Hash
        if ($partHash -ne $UtmtCliSha256) { throw "下载文件 SHA256 校验失败（期望 $UtmtCliSha256，实际 $partHash），已停止，未解压：$part" }
        Move-Item -LiteralPath $part -Destination $zip -Force
        Write-Host "  SHA256 校验通过（$UtmtCliSha256）" -ForegroundColor Green
    }
    Write-Host "正在解压到 $UtmtCliDir …" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $UtmtCliDir | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $UtmtCliDir -Force
    if (-not (Test-Path $UtmtCli)) { throw "解压后仍找不到 UndertaleModCli.exe：$UtmtCli" }
    Write-Host "UndertaleModTool CLI v$UtmtCliVersion 已就绪：$UtmtCli" -ForegroundColor Green
    return $UtmtCli
}

function Ensure-UtmtCli {
    if (-not (Test-Path $UtmtCli)) { $null = Install-UtmtCli }
    Assert-UtmtRuntime
}

function Invoke-PatchBuild([string]$SourceData, [string]$OutData) {
    Ensure-UtmtCli
    if (-not (Test-Path $SourceData)) { throw "缺少补丁源文件：$SourceData" }
    if (Test-Path $OutData) { Remove-Item -LiteralPath $OutData -Force }
    Write-Host "正在打补丁（约 10 秒）..." -ForegroundColor Cyan
    $env:SCORCHPOT_MOD_ROOT = $RepoDir
    & $UtmtCli load $SourceData -s $ApplyScript -o $OutData -f | Out-Null
    if (-not (Test-Path $OutData)) { throw '补丁构建失败：未生成输出文件。' }
    return (Get-FileHash $OutData -Algorithm SHA256).Hash
}

function Invoke-PatchVerify([string]$PatchedData) {
    Ensure-UtmtCli
    # 多个校验脚本依次执行，任一失败即中止（不覆盖游戏文件）
    $verifyJobs = @(
        [pscustomobject]@{ Script = (Join-Path $PatchDir 'verify_reroll.csx'); Report = (Join-Path $PatchDir 'last_verify_report.txt') },
        [pscustomobject]@{ Script = (Join-Path $PatchDir 'verify_dice.csx');   Report = (Join-Path $PatchDir 'last_verify_dice_report.txt') },
        [pscustomobject]@{ Script = (Join-Path $PatchDir 'verify_recipes_seasons.csx'); Report = (Join-Path $PatchDir 'last_verify_recipes_report.txt') }
        [pscustomobject]@{ Script = (Join-Path $PatchDir 'verify_shop_buttons.csx'); Report = (Join-Path $PatchDir 'last_verify_shop_buttons_report.txt') }
    )
    foreach ($job in $verifyJobs) {
        if (-not (Test-Path $job.Script)) { throw "缺少构建校验脚本：$($job.Script)" }
        if (Test-Path $job.Report) { Remove-Item -LiteralPath $job.Report -Force }
        Write-Host "正在校验补丁产物（$((Split-Path $job.Script -Leaf))）..." -ForegroundColor Cyan
        $env:SCORCHPOT_MOD_ROOT = $RepoDir
        & $UtmtCli load $PatchedData -s $job.Script | Out-Null
        $exit = $LASTEXITCODE
        if ($exit -ne 0) { throw "补丁校验失败（$((Split-Path $job.Script -Leaf))，退出码 $exit）——已中止安装，游戏 data.win 未改动。" }
        if (-not (Test-Path $job.Report)) { throw "补丁校验失败（未生成 $($job.Report)）——已中止安装，游戏 data.win 未改动。" }
        Write-Host (Get-Content $job.Report -Raw -Encoding UTF8).Trim() -ForegroundColor DarkCyan
    }
    return $verifyJobs[0].Report
}

function Install-Mod {
    Assert-GameNotRunning
    Assert-GameDir
    Ensure-UtmtCli
    Ensure-Dirs
    $gameHash = (Get-FileHash $GameData -Algorithm SHA256).Hash
    $isKnownVanilla = $KnownVanillaHashes -contains $gameHash
    $backupExists = Test-Path $BackupData
    $backupHash = if ($backupExists) { (Get-FileHash $BackupData -Algorithm SHA256).Hash } else { $null }
    $needBackup = -not $backupExists

    if ($RefreshBackup) {
        $needBackup = $true
        Write-Host '按 -RefreshBackup：以当前游戏文件为准重建原版备份。' -ForegroundColor Yellow
    }
    elseif ($isKnownVanilla -and $backupExists -and ($backupHash -ne $gameHash)) {
        # 当前文件是已知原版，但与旧备份不一致（Steam 更新或校验完整性还原过）→ 备份已过期
        $needBackup = $true
        Write-Host '检测到游戏文件已回到已知原版且与旧备份不一致，自动刷新原版备份。' -ForegroundColor Yellow
    }

    if ($needBackup) {
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        Copy-Item -LiteralPath $GameData -Destination $BackupData -Force
        $backupHash = (Get-FileHash $BackupData -Algorithm SHA256).Hash
        Write-Host "已备份原版 data.win -> $BackupData" -ForegroundColor Green
    }
    if (-not ($KnownVanillaHashes -contains $backupHash)) {
        Write-Host "注意：原版备份哈希不在已知版本列表内（$backupHash）。补丁按函数名+锚点定位，锚点对不上会立即中止且不改动游戏文件。" -ForegroundColor Yellow
    }
    $tmpPatched = Join-Path $WorkDir 'data.win.patched'
    $null = Invoke-PatchBuild -SourceData $BackupData -OutData $tmpPatched
    $null = Invoke-PatchVerify -PatchedData $tmpPatched
    $built = (Get-FileHash $tmpPatched -Algorithm SHA256).Hash

    # 版本确认：复用旧备份时，只有当「当前游戏文件」= 已知原版 / 原版备份 / 本次构建产物 之一才继续，
    # 否则说明游戏很可能已更新（旧备份过期）或被其他 Mod 改过 —— 此时继续会把游戏退回旧版本。
    if ((-not $needBackup) -and (-not $isKnownVanilla) -and ($gameHash -ne $backupHash) -and ($gameHash -ne $built) -and (-not $Force)) {
        Write-Host '== 版本未确认，已中止（游戏文件未被改动）==' -ForegroundColor Yellow
        Write-Host "  当前 data.win            ：$gameHash"
        Write-Host "  现有原版备份             ：$backupHash"
        Write-Host "  用现有备份打出的补丁版   ：$built"
        Write-Host '  当前游戏文件既不是已知原版、也不等于原版备份、也不是「用现有备份打出的补丁版」：' -ForegroundColor Yellow
        Write-Host '  可能是游戏已更新到新版本（旧备份过期），或该文件被其他工具改过。' -ForegroundColor Yellow
        Write-Host '  · 游戏更新过：.\ScorchpotEasy.ps1 -Repatch -RefreshBackup（以当前文件为新基线重新备份并重打）' -ForegroundColor Yellow
        Write-Host '                （或双击 更新后重打.bat 做同一件事）' -ForegroundColor Yellow
        Write-Host '  · 确认无碍  ：加 -Force 按现有备份继续（有把游戏退回旧版本的风险）' -ForegroundColor Yellow
        throw '版本未确认，已中止（未改动任何游戏文件）。'
    }

    Copy-Item -LiteralPath $tmpPatched -Destination $GameData -Force
    $installed = (Get-FileHash $GameData -Algorithm SHA256).Hash
    if ($installed -ne $built) { throw '安装校验失败：目标文件哈希与构建产物不一致。' }
    $def = Get-DefaultProfile
    $cfgState = "已按默认配置档「$def」写入"
    if (Test-Path $CfgPath) {
        # 已有配置文件时一律保留：不覆盖你在游戏面板里调好的数值（想换档请用 -Use <档名>）
        $cfg = $CfgPath
        $cfgState = '已保留原有数值（想换成某个配置档请用 -Use <档名>）'
    }
    else {
        $cfg = Write-Cfg $def
    }
    $idx = Write-ProfilesIndex
    Write-Host "补丁安装完成。`n  原版备份 SHA256: $backupHash`n  补丁版 SHA256 : $installed`n  配置文件       : $cfg（$cfgState）`n  配置档索引     : $idx" -ForegroundColor Green
    Write-Host '启动游戏后，按 F9 可打开 Mod 控制面板（面板内按 B 改键；点档名或 - + 或 Q/E 切配置档）。' -ForegroundColor Yellow
}

switch ($true) {
    $FetchTools {
        $null = Install-UtmtCli
        Assert-UtmtRuntime
        break
    }
    ($Install -or $Repatch -or $RefreshBackup) {
        Install-Mod
        break
    }
    $Restore {
        Assert-GameNotRunning
        if (-not (Test-Path $BackupData)) { throw "找不到原版备份：$BackupData" }
        Copy-Item -LiteralPath $BackupData -Destination $GameData -Force
        if (Test-Path $CfgPath) { Remove-Item -LiteralPath $CfgPath -Force }
        $h = (Get-FileHash $GameData -Algorithm SHA256).Hash
        Write-Host "已还原原版 data.win（SHA256=$h），并移除 ScorchpotEasy.cfg。" -ForegroundColor Green
        break
    }
    $Status {
        Ensure-Dirs
        $state = Get-GameState
        $h = if (Test-Path $GameData) { (Get-FileHash $GameData -Algorithm SHA256).Hash } else { '<无>' }
        $activeProfile = '<无>'
        $activeHotkey = '<无>'
        if (Test-Path $CfgPath) {
            $cfgText = Get-Content $CfgPath -Raw -Encoding UTF8
            if ($cfgText -match 'profile=(\S+)') { $activeProfile = $Matches[1] }
            if ($cfgText -match 'panel_hotkey=(\S+)') { $activeHotkey = $Matches[1] }
        }
        Write-Host '== 喂龙高手 轻松 Mod 状态 ==' -ForegroundColor Cyan
        Write-Host "  data.win      : $state ($h)"
        Write-Host "  原版哈希基准  : $OriginalHash"
        Write-Host "  当前配置档    : $activeProfile   默认档：$(Get-DefaultProfile)"
        Write-Host "  面板快捷键    : $activeHotkey"
        Write-Host "  游戏目录      : $(if ($GameDir) { $GameDir } else { '<未找到，可用 -GameDir 指定>' })"
        Write-Host "  原版备份      : $(if (Test-Path $BackupData) { $BackupData } else { '<尚未备份，首次 -Install 会自动创建>' })"
        Write-Host "  UTMT CLI      : $(if (Test-Path $UtmtCli) { "v$UtmtCliVersion 已就绪" } else { '未下载（首次 -Install 或 -FetchTools 自动下载）' })"
        $idxState = '未导出（游戏内切档不可用，跑一次 -Repatch 或 -Use 即可生成）'
        if (Test-Path $ProfilesIndex) {
            $plan = Get-IndexPlan
            $idxNames = @()
            foreach ($m in [regex]::Matches((Get-Content $ProfilesIndex -Raw -Encoding UTF8), '(?m)^p(\d+)_name=(.+)$')) {
                $idxNames += $m.Groups[2].Value.Trim()
            }
            if (($idxNames -join '|') -eq ($plan.Displays -join '|')) {
                $idxState = "已同步（$($idxNames.Count) 档：$($idxNames -join ' / ')）"
            }
            else {
                $idxState = "需重导（索引：$($idxNames -join ' / ') ；实际：$($plan.Displays -join ' / ')）"
            }
        }
        Write-Host "  配置档索引    : $idxState"
        Write-Host "  配置文件      : $CfgPath"
        Write-Host "  游戏进程      : $(if (Get-Process -Name Scorchpot -ErrorAction SilentlyContinue) { '运行中' } else { '未运行' })"
        break
    }
    $List {
        Ensure-Dirs
        $def = Get-DefaultProfile
        $files = Get-ChildItem $ProfilesDir -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object Name
        if (-not $files) { Write-Host '还没有任何配置档。' ; break }
        $plan = Get-IndexPlan
        $dispMap = @{}
        for ($pi = 0; $pi -lt $plan.Names.Count; $pi++) { $dispMap[$plan.Names[$pi]] = $plan.Displays[$pi] }
        Write-Host '== 配置档列表 ==' -ForegroundColor Cyan
        foreach ($f in $files) {
            $o = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $mark = if ($o.name -eq $def) { '*' } else { ' ' }
            $disp = if ($dispMap.ContainsKey($o.name)) {
                if ($dispMap[$o.name] -eq $o.name) { $o.name } else { "$($dispMap[$o.name])（档名不可绘制）" }
            } else { '未导出（超过 12 档上限）' }
            $rsb = if ($null -ne $o.recipe_store_bonus) { $o.recipe_store_bonus } else { 0 }
            $arb = if ($null -ne $o.active_recipe_bonus) { $o.active_recipe_bonus } else { 0 }
            $sbn = if ($null -ne $o.seasons_bonus) { $o.seasons_bonus } else { 0 }
            $str = if ($null -ne $o.shop_tool_reroll) { $o.shop_tool_reroll } else { 1 }
            $sdr = if ($null -ne $o.shop_dice_reroll) { $o.shop_dice_reroll } else { 1 }
            Write-Host ("{0} {1,-8} hunger={2} rolls+{3} 建筑价x{4} 食谱价x{5} 刷新x{6} 饿怒={7} 开局金+{8} 激活x{9} 建筑+{10} 货位+{11} 骰子+{12} 食谱栏+{13} 可激活+{14} 季度+{15} 工具刷={16} 骰子刷={17} 热键={18}" -f $mark, $o.name, $o.hunger_mult, $o.rolls_bonus, $o.building_price_mult, $o.recipe_price_mult, $o.reroll_cost_mult, $o.hanger_mode, $o.start_gold, $o.activation_mult, $o.building_bonus, $o.extra_slots, $o.dice_bonus, $rsb, $arb, $sbn, $str, $sdr, $o.panel_hotkey)
            Write-Host ("    游戏内显示：{0}" -f $disp)
        }
        Write-Host '（* = 默认档；-Use <名称> 应用某档，-SetDefault <名称> 设为默认；游戏内可按面板档名 - + 或 Q/E 切档）'
        break
    }
    (-not [string]::IsNullOrWhiteSpace($Show)) {
        $o = Read-Profile $Show
        $o | Format-List
        break
    }
    (-not [string]::IsNullOrWhiteSpace($New)) {
        Ensure-Dirs
        if (Test-Path (Get-ProfilePath $New)) { throw "配置档已存在：$New" }
        Assert-DrawableName $New
        $obj = if ($From) { $base = Read-Profile $From; $base.name = $New; $base } else { New-ProfileObject -Name $New -Desc '自定义配置' }
        Write-Profile $obj
        $idx = Write-ProfilesIndex
        Write-Host "已创建配置档：$New`n索引已刷新：$idx" -ForegroundColor Green
        break
    }
    (-not [string]::IsNullOrWhiteSpace($Use)) {
        Ensure-Dirs
        $p = Write-Cfg $Use
        $idx = Write-ProfilesIndex
        Write-Host "已应用配置档 '$Use' -> $p`n索引已刷新：$idx`n（修改后需重启游戏才会重新读取；局内数值会在新开局/下一次刷新时生效；游戏内也可直接点档名切档）" -ForegroundColor Green
        break
    }
    (-not [string]::IsNullOrWhiteSpace($SetDefault)) {
        Ensure-Dirs
        $null = Read-Profile $SetDefault
        [System.IO.File]::WriteAllText($DefaultFile, $SetDefault, (New-Object System.Text.UTF8Encoding($false)))
        $idx = Write-ProfilesIndex
        Write-Host "默认档已设为：$SetDefault（索引第 0 档）`n索引已刷新：$idx" -ForegroundColor Green
        break
    }
    (-not [string]::IsNullOrWhiteSpace($Rename)) {
        Ensure-Dirs
        if (-not $To) { throw '请同时提供 -To <新名称>，例如：-Rename 标准 -To 舒适' }
        Assert-DrawableName $To
        $old = Read-Profile $Rename
        if (Test-Path (Get-ProfilePath $To)) { throw "目标名称已存在：$To" }
        $old.name = $To
        Write-Profile $old
        Remove-Item -LiteralPath (Get-ProfilePath $Rename) -Force
        if ((Get-DefaultProfile) -eq $Rename) {
            [System.IO.File]::WriteAllText($DefaultFile, $To, (New-Object System.Text.UTF8Encoding($false)))
        }
        $idx = Write-ProfilesIndex
        Write-Host "已重命名：$Rename -> $To`n索引已刷新：$idx" -ForegroundColor Green
        break
    }
    ($Set -and $Set.Count -gt 0) {
        Ensure-Dirs
        $active = '<未指定>'
        if (Test-Path $CfgPath) {
            $cfgText = Get-Content $CfgPath -Raw -Encoding UTF8
            if ($cfgText -match 'profile=(\S+)') { $active = $Matches[1] }
        }
        if ($active -eq '<未指定>') { $active = Get-DefaultProfile }
        $obj = Read-Profile $active
        foreach ($pair in $Set) {
            $kv = $pair -split '=', 2
            if ($kv.Count -ne 2) { throw "参数格式应为 key=value：$pair" }
            $k = $kv[0].Trim(); $v = $kv[1].Trim()
            if ($KeyOrder -notcontains $k) { throw "未知配置项：$k（可用：$($KeyOrder -join ', ')）" }
            if ($k -eq 'panel_hotkey') { $obj.$k = $v }
            else {
                $num = [double]$v
                if ($KeyRanges.ContainsKey($k)) {
                    $lo = $KeyRanges[$k][0]; $hi = $KeyRanges[$k][1]
                    if ($num -lt $lo -or $num -gt $hi) { throw "「$k」超出范围：允许 $lo ~ $hi，收到 $v" }
                }
                $obj.$k = $num
            }
        }
        Write-Profile $obj
        $p = Write-Cfg $active
        $idx = Write-ProfilesIndex
        Write-Host "已更新配置档 '$active' 并写入：$p`n索引已刷新：$idx" -ForegroundColor Green
        break
    }
    (-not [string]::IsNullOrWhiteSpace($Delete)) {
        Ensure-Dirs
        $p = Get-ProfilePath $Delete
        if (-not (Test-Path $p)) { throw "配置档不存在：$Delete" }
        if ((Get-DefaultProfile) -eq $Delete) { throw "默认档不能删除，请先 -SetDefault 其他档。" }
        Remove-Item -LiteralPath $p -Force
        $idx = Write-ProfilesIndex
        Write-Host "已删除配置档：$Delete`n索引已刷新：$idx" -ForegroundColor Green
        break
    }
    $Launch {
        if (-not (Test-Path $GameExe)) { throw "找不到游戏程序：$GameExe" }
        Start-Process -FilePath $GameExe -WorkingDirectory $GameDir
        Write-Host '已启动《喂龙高手》。' -ForegroundColor Green
        break
    }
    default {
        Write-Host '《喂龙高手》轻松游玩 Mod 工具' -ForegroundColor Cyan
        Write-Host '常用命令：'
        Write-Host '  -Status                 查看安装状态与当前配置档'
        Write-Host '  -List                   列出全部配置档'
        Write-Host '  -Use <名称>             应用某个配置档'
        Write-Host '  -Set key=value [...]    修改当前配置档（如 -Set hunger_mult=0.4）'
        Write-Host '  -New <名称> [-From 模板] 新建配置档'
        Write-Host '  -Rename <旧名> -To <新名> 重命名配置档'
        Write-Host '  -SetDefault <名称>      设为默认配置档'
        Write-Host '  -Install / -Repatch     安装/重打补丁（自动备份原版）'
        Write-Host '  -FetchTools             只下载 UndertaleModTool CLI（首次安装会自动触发）'
        Write-Host '  -GameDir <路径>         手动指定游戏目录（默认自动探测 Steam 库）'
        Write-Host '  -RefreshBackup          以当前游戏文件为准重建原版备份（游戏更新后用；可单独执行）'
        Write-Host '  -Restore                还原原版 data.win'
        Write-Host '  -Launch                 启动游戏'
    }
}
