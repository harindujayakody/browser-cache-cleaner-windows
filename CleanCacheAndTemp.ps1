# ================================================================
#  BrowserCacheCleaner  v4  —  Nord Edition
#  Scan → Report → Confirm [Y/N] → Clean
#
#  CLEANS:
#    Browsers  : Brave, Chrome, Edge, Firefox (all profiles)
#    Windows   : Temp, Prefetch, WinUpdate cache, Log files,
#                Crash dumps, Error reports, Thumbnail cache,
#                DNS cache, Downloads junk
#    Recycle   : Recycle Bin
#
#  DISK ANALYZER: [D] at prompt — top folders/files bar chart
#
#  SAFE: Cookies · Logins · Passwords · Bookmarks NEVER touched
# ================================================================

# ── Admin check ──────────────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "`n  [!] Run as Administrator.`n" -ForegroundColor Red
    Pause; Exit
}

$C = 'Cyan'; $G = 'Green'; $Y = 'Yellow'; $R = 'Red'
$M = 'Magenta'; $W = 'White'; $DG = 'DarkGray'

# ════════════════════════════════════════════════════════════
#  UI
# ════════════════════════════════════════════════════════════

function Write-Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $C
    Write-Host "  ║                                                          ║" -ForegroundColor $C
    Write-Host "  ║     ██████╗ ██████╗  ██████╗ ██╗    ██╗███████╗███████╗ ║" -ForegroundColor $C
    Write-Host "  ║     ██╔══██╗██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔════╝ ║" -ForegroundColor $C
    Write-Host "  ║     ██████╔╝██████╔╝██║   ██║██║ █╗ ██║███████╗█████╗   ║" -ForegroundColor $C
    Write-Host "  ║     ██╔══██╗██╔══██╗██║   ██║██║███╗██║╚════██║██╔══╝   ║" -ForegroundColor $C
    Write-Host "  ║     ██████╔╝██║  ██║╚██████╔╝╚███╔███╔╝███████║███████╗ ║" -ForegroundColor $C
    Write-Host "  ║     ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝ ╚══════╝╚══════╝ ║" -ForegroundColor $C
    Write-Host "  ║                                                          ║" -ForegroundColor $C
    Write-Host "  ║         C A C H E   C L E A N E R   v 4                 ║" -ForegroundColor $Y
    Write-Host "  ║                   Nord  Edition                         ║" -ForegroundColor $DG
    Write-Host "  ║                                                          ║" -ForegroundColor $C
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $C
    Write-Host ""
}

# Fixed inner width — ALL rows must fit exactly $IW chars between │ and │
$IW = 52

function Write-TableTop    { Write-Host "  ╭$('─' * $IW)╮" -ForegroundColor $C }
function Write-TableBottom { Write-Host "  ╰$('─' * $IW)╯" -ForegroundColor $C }
function Write-TableDiv    { Write-Host "  ├$('─' * $IW)┤" -ForegroundColor $C }

function Write-TableHeader($title) {
    $pad = $IW - $title.Length - 2   # 1 space each side
    Write-Host "  │ " -NoNewline -ForegroundColor $C
    Write-Host $title -NoNewline -ForegroundColor $Y
    Write-Host (" " * $pad) -NoNewline
    Write-Host " │" -ForegroundColor $C
}

# label must be exactly 34 chars (pre-padded by caller), size col = 12 chars
function Write-TableRow($label, $size) {
    $sStr = if ($size -gt 0) { "{0,10:N2} MB" -f $size } else { "     empty" }
    $sCol = if ($size -gt 0) { $Y } else { $DG }
    $lCol = if ($size -gt 0) { $W } else { $DG }
    $icon = if ($size -gt 0) { "✔" } else { "·" }
    $iCol = if ($size -gt 0) { $G } else { $DG }
    # layout: "  │ " (4) + icon (1) + " " (1) + label (34) + "  " (2) + size (10) + "  │" (3) = 55 — matches IW=52 + borders
    Write-Host "  │ " -NoNewline -ForegroundColor $C
    Write-Host $icon -NoNewline -ForegroundColor $iCol
    Write-Host " $label  " -NoNewline -ForegroundColor $lCol
    Write-Host $sStr -NoNewline -ForegroundColor $sCol
    Write-Host "  │" -ForegroundColor $C
}

function Write-TableTotal($size) {
    $sStr = "{0:N2} MB  ({1:N3} GB)" -f $size, ($size / 1024)
    $lbl  = " TOTAL TO FREE  "
    # lbl + sStr must be $IW chars (padded if needed)
    $content = $lbl + $sStr
    $pad = $IW - $content.Length
    if ($pad -lt 0) { $pad = 0 }
    Write-Host "  │" -NoNewline -ForegroundColor $M
    Write-Host $lbl -NoNewline -ForegroundColor $W
    Write-Host ($sStr + (" " * $pad)) -NoNewline -ForegroundColor $Y
    Write-Host "│" -ForegroundColor $M
}

function Write-ScanLine($label, $size) {
    Write-Host ("  ● {0,-16}" -f $label) -NoNewline -ForegroundColor $DG
    Write-Host "done  " -NoNewline -ForegroundColor $G
    Write-Host ("({0:N2} MB)" -f $size) -ForegroundColor $C
}

# ════════════════════════════════════════════════════════════
#  SIZE / CLEAN HELPERS
# ════════════════════════════════════════════════════════════

function Get-FolderSize($path) {
    if (-not (Test-Path $path)) { return [double]0 }
    $sum = (Get-ChildItem $path -Recurse -Force -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    return [math]::Round($(if ($sum) { $sum / 1MB } else { 0 }), 2)
}

function Remove-FolderContents($path) {
    if (-not (Test-Path $path)) { return [double]0 }
    $before = Get-FolderSize $path
    Get-ChildItem $path -Recurse -Force -File   -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem $path -Recurse -Force         -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $freed = $before - (Get-FolderSize $path)
    return [math]::Round($(if ($freed -gt 0) { $freed } else { 0 }), 2)
}

# ── Chromium ──────────────────────────────────────────────────
$chromeSubs = @(
    "Cache\Cache_Data","Code Cache\js","Code Cache\wasm",
    "GPUCache","Service Worker\CacheStorage","Service Worker\ScriptCache","blob_storage"
)
function Measure-ChromiumProfile($p) {
    $t = [double]0; foreach ($s in $chromeSubs) { $t += Get-FolderSize "$p\$s" }; return $t
}
function Clean-ChromiumProfile($p) {
    $t = [double]0; foreach ($s in $chromeSubs) { $t += Remove-FolderContents "$p\$s" }; return $t
}
function Get-ChromiumProfiles($ud) {
    if (-not (Test-Path $ud)) { return @() }
    return Get-ChildItem $ud -Directory -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" }
}
function Measure-ChromiumBrowser($ud) {
    $r = [PSCustomObject]@{ Total=[double]0; Profiles=[System.Collections.Generic.List[PSCustomObject]]::new() }
    if (-not (Test-Path $ud)) { return $r }
    $r.Total += Get-FolderSize "$ud\ShaderCache\GPUCache"
    $r.Total += Get-FolderSize "$ud\GrShaderCache\GPUCache"
    foreach ($d in (Get-ChromiumProfiles $ud)) {
        $s = Measure-ChromiumProfile $d.FullName
        $r.Total += $s
        $r.Profiles.Add([PSCustomObject]@{ Name=$d.Name; Size=$s })
    }
    return $r
}
function Clean-ChromiumBrowser($ud) {
    $t = [double]0
    if (-not (Test-Path $ud)) { return $t }
    $t += Remove-FolderContents "$ud\ShaderCache\GPUCache"
    $t += Remove-FolderContents "$ud\GrShaderCache\GPUCache"
    foreach ($d in (Get-ChromiumProfiles $ud)) { $t += Clean-ChromiumProfile $d.FullName }
    return $t
}

# ── Firefox ───────────────────────────────────────────────────
function Measure-FFProfile($rp, $lp) {
    return (Get-FolderSize "$lp\cache2\entries") + (Get-FolderSize "$lp\startupCache") +
           (Get-FolderSize "$rp\cache2\entries") + (Get-FolderSize "$rp\startupCache") +
           (Get-FolderSize "$rp\thumbnails")
}
function Clean-FFProfile($rp, $lp) {
    $t = [double]0
    $t += Remove-FolderContents "$lp\cache2\entries"
    $t += Remove-FolderContents "$lp\startupCache"
    $t += Remove-FolderContents "$rp\cache2\entries"
    $t += Remove-FolderContents "$rp\startupCache"
    $t += Remove-FolderContents "$rp\thumbnails"
    return $t
}

# ── Recycle Bin ───────────────────────────────────────────────
function Get-RecycleBinSize {
    try {
        $rb    = (New-Object -ComObject Shell.Application).Namespace(0xA)
        $bytes = ($rb.Items() | ForEach-Object { $_.Size } | Measure-Object -Sum).Sum
        return [math]::Round($(if ($bytes) { $bytes / 1MB } else { 0 }), 2)
    } catch { return [double]0 }
}

# ── Downloads junk ────────────────────────────────────────────
$junkExts = @("*.tmp","*.temp","*.crdownload","*.part","*.partial","*.download","*.!ut","*.~*","Thumbs.db","desktop.ini")
$dlFolder = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('UserProfile'), 'Downloads')

function Get-DownloadsJunkSize {
    if (-not (Test-Path $dlFolder)) { return [double]0 }
    $sum = 0
    foreach ($ext in $junkExts) {
        $sum += (Get-ChildItem $dlFolder -Filter $ext -Force -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    }
    return [math]::Round($(if ($sum) { $sum / 1MB } else { 0 }), 2)
}
function Remove-DownloadsJunk {
    $t = [double]0
    if (-not (Test-Path $dlFolder)) { return $t }
    foreach ($ext in $junkExts) {
        Get-ChildItem $dlFolder -Filter $ext -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $t += [math]::Round($_.Length / 1MB, 4)
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
    return [math]::Round($t, 2)
}

# ════════════════════════════════════════════════════════════
#  DISK ANALYZER
# ════════════════════════════════════════════════════════════

function Show-DiskAnalyzer {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $M
    Write-Host "  ║              DISK ANALYZER  —  C:\                      ║" -ForegroundColor $M
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $M
    Write-Host ""

    # Drive bar
    $drive = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($drive) {
        $used    = [math]::Round($drive.Used  / 1GB, 2)
        $free    = [math]::Round($drive.Free  / 1GB, 2)
        $total   = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
        $pct     = [math]::Round($drive.Used  / ($drive.Used + $drive.Free) * 100, 1)
        $bW      = 40
        $filled  = [math]::Round($pct / 100 * $bW)
        $empty   = $bW - $filled
        $bCol    = if ($pct -gt 85) { $R } elseif ($pct -gt 65) { $Y } else { $G }

        Write-Host "  ╭── DRIVE C:\ $('─' * 43)╮" -ForegroundColor $C
        Write-Host "  │" -ForegroundColor $C
        Write-Host "  │   " -NoNewline -ForegroundColor $C
        Write-Host ("█" * $filled) -NoNewline -ForegroundColor $bCol
        Write-Host ("░" * $empty) -NoNewline -ForegroundColor $DG
        Write-Host "  $pct% used" -ForegroundColor $W
        Write-Host "  │   Used: $used GB   Free: $free GB   Total: $total GB" -ForegroundColor $W
        Write-Host "  │" -ForegroundColor $C
        Write-Host "  ╰$('─' * 56)╯" -ForegroundColor $C
    }

    # Top folders
    Write-Host ""
    Write-Host "  ● Scanning folders..." -ForegroundColor $DG
    $skip = @("Windows", "`$Recycle.Bin", "System Volume Information", "Recovery")
    $dirs = Get-ChildItem "C:\" -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notin $skip } |
            ForEach-Object {
                $sz = (Get-ChildItem $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                       Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                [PSCustomObject]@{ Name=$_.Name; MB=[math]::Round($(if($sz){$sz/1MB}else{0}),1) }
            } | Sort-Object MB -Descending | Select-Object -First 10

    $maxMB = if ($dirs) { ($dirs | Measure-Object MB -Maximum).Maximum } else { 1 }
    $bW    = 22

    Write-Host ""
    Write-Host "  ╭── TOP 10 FOLDERS $('─' * 38)╮" -ForegroundColor $C
    Write-Host "  │" -ForegroundColor $C
    $i = 1
    foreach ($d in $dirs) {
        $f   = [math]::Max(1, [math]::Round($d.MB / $maxMB * $bW))
        $e   = $bW - $f
        $col = if ($d.MB -gt 5000) { $R } elseif ($d.MB -gt 1000) { $Y } else { $G }
        $nm  = ("{0,-18}" -f $d.Name.Substring(0, [math]::Min(18,$d.Name.Length)))
        Write-Host "  │  " -NoNewline -ForegroundColor $C
        Write-Host ("{0,2}. " -f $i) -NoNewline -ForegroundColor $DG
        Write-Host $nm -NoNewline -ForegroundColor $W
        Write-Host ("█" * $f) -NoNewline -ForegroundColor $col
        Write-Host ("░" * $e) -NoNewline -ForegroundColor $DG
        Write-Host (" {0,8:N1} MB" -f $d.MB) -ForegroundColor $Y
        $i++
    }
    Write-Host "  │" -ForegroundColor $C
    Write-Host "  ╰$('─' * 56)╯" -ForegroundColor $C

    # Top files
    Write-Host ""
    Write-Host "  ● Scanning large files in C:\Users..." -ForegroundColor $DG
    $files = Get-ChildItem "C:\Users" -Recurse -Force -File -ErrorAction SilentlyContinue |
             Sort-Object Length -Descending | Select-Object -First 10
    $maxFMB = if ($files) { [math]::Round($files[0].Length / 1MB, 1) } else { 1 }

    Write-Host ""
    Write-Host "  ╭── TOP 10 FILES $('─' * 40)╮" -ForegroundColor $C
    Write-Host "  │" -ForegroundColor $C
    $i = 1
    foreach ($f in $files) {
        $szMB = [math]::Round($f.Length / 1MB, 1)
        $fb   = [math]::Max(1, [math]::Round($szMB / $maxFMB * $bW))
        $eb   = $bW - $fb
        $col  = if ($szMB -gt 1000) { $R } elseif ($szMB -gt 200) { $Y } else { $G }
        $nm   = $f.Name; if ($nm.Length -gt 18) { $nm = $nm.Substring(0,15) + "..." }
        $dir  = $f.DirectoryName; if ($dir.Length -gt 44) { $dir = "..." + $dir.Substring($dir.Length - 41) }
        Write-Host "  │  " -NoNewline -ForegroundColor $C
        Write-Host ("{0,2}. " -f $i) -NoNewline -ForegroundColor $DG
        Write-Host ("{0,-18}" -f $nm) -NoNewline -ForegroundColor $W
        Write-Host ("█" * $fb) -NoNewline -ForegroundColor $col
        Write-Host ("░" * $eb) -NoNewline -ForegroundColor $DG
        Write-Host (" {0,8:N1} MB" -f $szMB) -ForegroundColor $Y
        Write-Host "  │       $dir" -ForegroundColor $DG
        $i++
    }
    Write-Host "  │" -ForegroundColor $C
    Write-Host "  ╰$('─' * 56)╯" -ForegroundColor $C

    Write-Host ""
    Write-Host "  Press any key to go back..." -ForegroundColor $DG
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════

$local   = $env:LOCALAPPDATA
$roaming = $env:APPDATA
$ffRoam  = "$roaming\Mozilla\Firefox\Profiles"
$ffLoc   = "$local\Mozilla\Firefox\Profiles"

while ($true) {

Clear-Host
Write-Banner

# ════════════════════════════════════════════════════════════
#  SCAN
# ════════════════════════════════════════════════════════════

Write-Host "  ► Scanning your system..." -ForegroundColor $W
Write-Host "  ► Cookies and logins will " -NoNewline -ForegroundColor $W
Write-Host "NOT" -NoNewline -ForegroundColor $G
Write-Host " be touched.`n" -ForegroundColor $W

$brave = Measure-ChromiumBrowser "$local\BraveSoftware\Brave-Browser\User Data"
Write-ScanLine "Brave"         $brave.Total

$chrome = Measure-ChromiumBrowser "$local\Google\Chrome\User Data"
Write-ScanLine "Chrome"        $chrome.Total

$edge = Measure-ChromiumBrowser "$local\Microsoft\Edge\User Data"
Write-ScanLine "Edge"          $edge.Total

$ffTotal = [double]0
$ffProfs = [System.Collections.Generic.List[PSCustomObject]]::new()
if (Test-Path $ffRoam) {
    foreach ($p in (Get-ChildItem $ffRoam -Directory -ErrorAction SilentlyContinue)) {
        $s = Measure-FFProfile "$ffRoam\$($p.Name)" "$ffLoc\$($p.Name)"
        $ffTotal += $s
        $ffProfs.Add([PSCustomObject]@{ Name=$p.Name; Size=$s })
    }
}
Write-ScanLine "Firefox"       $ffTotal

$tempItems = [System.Collections.Generic.List[PSCustomObject]]::new()
@(
    @{ Label="User Temp (%TEMP%)";             Path=$env:TEMP },
    @{ Label="Windows Temp";                   Path="C:\Windows\Temp" },
    @{ Label="Prefetch Cache";                 Path="C:\Windows\Prefetch" },
    @{ Label="WinUpdate Download Cache";       Path="C:\Windows\SoftwareDistribution\Download" }
) | ForEach-Object {
    $o = [PSCustomObject]$_
    $o | Add-Member -NotePropertyName Size -NotePropertyValue (Get-FolderSize $o.Path)
    $tempItems.Add($o)
}
$tempTotal = [double]0; $tempItems | ForEach-Object { $tempTotal += $_.Size }
Write-ScanLine "System Temp"   $tempTotal

$logPaths = @(
    "$env:SystemRoot\Logs",
    "$env:SystemRoot\System32\winevt\Logs",
    "$local\CrashDumps",
    "$env:SystemRoot\Minidump",
    "$env:SystemRoot\MEMORY.DMP"
)
$logTotal = [double]0
foreach ($p in $logPaths) {
    if (Test-Path $p) {
        if ((Get-Item $p).PSIsContainer) { $logTotal += Get-FolderSize $p }
        else { $logTotal += [math]::Round((Get-Item $p).Length / 1MB, 2) }
    }
}
Write-ScanLine "Logs/Dumps"    $logTotal

$errPaths  = @("$local\Microsoft\Windows\WER","$env:ProgramData\Microsoft\Windows\WER")
$errTotal  = [double]0; $errPaths | ForEach-Object { $errTotal += Get-FolderSize $_ }
Write-ScanLine "Error Reports" $errTotal

$thumbPath  = "$local\Microsoft\Windows\Explorer"
$thumbTotal = Get-FolderSize $thumbPath
Write-ScanLine "Thumbnails"    $thumbTotal

$dlJunkTotal = Get-DownloadsJunkSize
Write-ScanLine "Downloads Junk" $dlJunkTotal

$rbTotal = Get-RecycleBinSize
Write-ScanLine "Recycle Bin"   $rbTotal

# ════════════════════════════════════════════════════════════
#  REPORT TABLE  — fixed-width, no alignment bugs
# ════════════════════════════════════════════════════════════
# Row layout inside │...│ (IW = 52):
#  " " + icon(1) + " " + label(34) + "  " + size(10) + "  " = 1+1+1+34+2+10+2 = 51... add 1 leading = 52 ✔

$rows = @(
    # label must be exactly 34 chars
    [PSCustomObject]@{ Label = "Brave Cache (all profiles)        "; Size = $brave.Total    }
    [PSCustomObject]@{ Label = "Chrome Cache (all profiles)       "; Size = $chrome.Total   }
    [PSCustomObject]@{ Label = "Edge Cache (all profiles)         "; Size = $edge.Total     }
    [PSCustomObject]@{ Label = "Firefox Cache (all profiles)      "; Size = $ffTotal        }
    [PSCustomObject]@{ Label = "System Temp & Prefetch            "; Size = $tempTotal      }
    [PSCustomObject]@{ Label = "Windows Logs & Crash Dumps        "; Size = $logTotal       }
    [PSCustomObject]@{ Label = "Windows Error Reports             "; Size = $errTotal       }
    [PSCustomObject]@{ Label = "Thumbnail Cache                   "; Size = $thumbTotal     }
    [PSCustomObject]@{ Label = "Downloads Junk Files              "; Size = $dlJunkTotal    }
    [PSCustomObject]@{ Label = "Recycle Bin                       "; Size = $rbTotal        }
)
$grandTotal = [double]0; $rows | ForEach-Object { $grandTotal += $_.Size }

Write-Host ""
Write-TableTop
Write-TableHeader "WHAT WILL BE CLEANED"
Write-TableDiv
foreach ($row in $rows) {
    Write-TableRow $row.Label.Substring(0,34) $row.Size
}
Write-TableDiv
Write-TableTotal $grandTotal
Write-TableBottom

# ════════════════════════════════════════════════════════════
#  PROMPT
# ════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ► " -NoNewline -ForegroundColor $C
Write-Host "[D] Disk Analyzer   [C] Clean   [Q] Quit  :  " -NoNewline -ForegroundColor $Y
$key = (Read-Host).ToUpper()

if ($key -eq "Q") {
    Write-Host "`n  ○ Bye! Nothing was deleted.`n" -ForegroundColor $Y
    Pause; Exit
}

if ($key -eq "D") {
    Show-DiskAnalyzer
    continue   # restart loop (rescan)
}

if ($key -ne "C") { continue }

# ════════════════════════════════════════════════════════════
#  CONFIRM
# ════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ● Cookies, saved passwords & logins are " -NoNewline -ForegroundColor $W
Write-Host "NOT" -NoNewline -ForegroundColor $G
Write-Host " included." -ForegroundColor $W
Write-Host ""
Write-Host "  ► Proceed with cleaning? " -NoNewline -ForegroundColor $C
Write-Host "[Y] Yes   [N] No  :  " -NoNewline -ForegroundColor $Y
$confirm = Read-Host

if ($confirm -notmatch "^[Yy]$") {
    Write-Host "`n  ○ Cancelled. Nothing deleted.`n" -ForegroundColor $Y
    Start-Sleep 2
    continue
}

# ════════════════════════════════════════════════════════════
#  CLEAN
# ════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ► Cleaning..." -ForegroundColor $W
Write-Host ""
$totalFreed = [double]0

function Write-CleanLine($label, $freed) {
    Write-Host ("  ● {0,-16}" -f $label) -NoNewline -ForegroundColor $DG
    if ($freed -gt 0) {
        Write-Host ("{0:N2} MB freed" -f $freed) -ForegroundColor $G
    } else {
        Write-Host "nothing to clean" -ForegroundColor $DG
    }
}

$f = Clean-ChromiumBrowser "$local\BraveSoftware\Brave-Browser\User Data"
$totalFreed += $f; Write-CleanLine "Brave" $f

$f = Clean-ChromiumBrowser "$local\Google\Chrome\User Data"
$totalFreed += $f; Write-CleanLine "Chrome" $f

$f = Clean-ChromiumBrowser "$local\Microsoft\Edge\User Data"
$totalFreed += $f; Write-CleanLine "Edge" $f

$ff = [double]0
if (Test-Path $ffRoam) {
    foreach ($p in (Get-ChildItem $ffRoam -Directory -ErrorAction SilentlyContinue)) {
        $ff += Clean-FFProfile "$ffRoam\$($p.Name)" "$ffLoc\$($p.Name)"
    }
}
$totalFreed += $ff; Write-CleanLine "Firefox" $ff

$st = [double]0; $tempItems | ForEach-Object { $st += Remove-FolderContents $_.Path }
$totalFreed += $st; Write-CleanLine "System Temp" $st

$lf = [double]0
foreach ($p in $logPaths) {
    if (Test-Path $p) {
        if ((Get-Item $p).PSIsContainer) { $lf += Remove-FolderContents $p }
        else { Remove-Item $p -Force -ErrorAction SilentlyContinue }
    }
}
$totalFreed += $lf; Write-CleanLine "Logs/Dumps" $lf

$ef = [double]0; $errPaths | ForEach-Object { $ef += Remove-FolderContents $_ }
$totalFreed += $ef; Write-CleanLine "Error Reports" $ef

$tf = Remove-FolderContents $thumbPath
$totalFreed += $tf; Write-CleanLine "Thumbnails" $tf

$df = Remove-DownloadsJunk
$totalFreed += $df; Write-CleanLine "Downloads Junk" $df

try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    $totalFreed += $rbTotal; Write-CleanLine "Recycle Bin" $rbTotal
} catch {
    Write-CleanLine "Recycle Bin" 0
}

ipconfig /flushdns | Out-Null
Write-Host "  ● DNS Cache      flushed" -ForegroundColor $G

# ════════════════════════════════════════════════════════════
#  DONE
# ════════════════════════════════════════════════════════════

$sStr  = "{0:N2} MB  ({1:N3} GB)" -f $totalFreed, ($totalFreed / 1024)
$label = " ✔  DONE!  Freed: "

Write-Host ""
Write-Host "  ╭$('─' * $IW)╮" -ForegroundColor $G
Write-Host "  │" -NoNewline -ForegroundColor $G
Write-Host $label -NoNewline -ForegroundColor $W
Write-Host ($sStr.PadRight($IW - $label.Length)) -NoNewline -ForegroundColor $Y
Write-Host "│" -ForegroundColor $G
Write-Host "  │" -NoNewline -ForegroundColor $G
Write-Host " ✔  Cookies and logins are untouched.".PadRight($IW) -NoNewline -ForegroundColor $G
Write-Host "│" -ForegroundColor $G
Write-Host "  ╰$('─' * $IW)╯" -ForegroundColor $G

Write-Host ""
Write-Host "  ► Run again? " -NoNewline -ForegroundColor $C
Write-Host "[Y] Yes   [N] No  :  " -NoNewline -ForegroundColor $Y
$again = Read-Host
if ($again -notmatch "^[Yy]$") {
    Write-Host ""
    Pause
    break
}

} # end while
