# ================================================================
#  CleanCacheAndTemp.ps1  v3
#  Nord-themed Oh-My-Posh style terminal UI
#  Scan → Preview → Confirm → Clean
#  Browsers: Brave, Chrome, Edge, Firefox (ALL profiles)
#  System: Temp, Prefetch, WinUpdate cache
#  Safe: Cookies, logins, passwords NEVER touched
# ================================================================

# ── Admin check ──────────────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host ""
    Write-Host "  [!] Run this script as Administrator." -ForegroundColor Red
    Pause; Exit
}

$C  = 'Cyan'; $G = 'Green'; $Y = 'Yellow'; $R = 'Red'
$M  = 'Magenta'; $W = 'White'; $DG = 'DarkGray'; $B = 'Blue'

# ── UI helpers ───────────────────────────────────────────────

function Write-Header($title) {
    $width = 62
    $inner = $title.PadLeft([math]::Floor(($width + $title.Length) / 2)).PadRight($width)
    $line  = [string][char]0x2550 * $width
    Write-Host ""
    Write-Host "  $([char]0x2554)$line$([char]0x2557)" -ForegroundColor $C
    Write-Host "  $([char]0x2551)$inner$([char]0x2551)" -ForegroundColor $W
    Write-Host "  $([char]0x255A)$line$([char]0x255D)" -ForegroundColor $C
}

function Write-SectionHeader($label) {
    Write-Host ""
    Write-Host "  $([char]0x256D)$([string][char]0x2500 * 3) " -NoNewline -ForegroundColor $C
    Write-Host $label -NoNewline -ForegroundColor $Y
    $rem = 54 - $label.Length
    if ($rem -lt 1) { $rem = 1 }
    Write-Host " $([string][char]0x2500 * $rem)$([char]0x256E)" -ForegroundColor $C
}

function Write-SectionFooter() {
    Write-Host "  $([char]0x2570)$([string][char]0x2500 * 60)$([char]0x256F)" -ForegroundColor $C
}

function Write-TotalRow($label, $size) {
    $sizeStr = if ($size -gt 0) { "{0,10:N2} MB" -f $size } else { "     empty" }
    $col     = if ($size -gt 0) { $Y } else { $DG }
    Write-Host "  $([char]0x2502)  $([char]0x2794) " -NoNewline -ForegroundColor $C
    Write-Host ("{0,-40}" -f $label) -NoNewline -ForegroundColor $C
    Write-Host $sizeStr -NoNewline -ForegroundColor $col
    Write-Host "  $([char]0x2502)" -ForegroundColor $C
}

function Write-ItemRow($label, $size) {
    $sizeStr = if ($size -gt 0) { "{0,10:N2} MB" -f $size } else { "     empty" }
    $col     = if ($size -gt 0) { $Y } else { $DG }
    Write-Host "  $([char]0x2502)     $([char]0x25B8) " -NoNewline -ForegroundColor $DG
    Write-Host ("{0,-37}" -f $label) -NoNewline -ForegroundColor $W
    Write-Host $sizeStr -NoNewline -ForegroundColor $col
    Write-Host "  $([char]0x2502)" -ForegroundColor $C
}

function Write-GrandTotal($size) {
    $sizeStr = "{0:N2} MB  ({1:N3} GB)" -f $size, ($size / 1024)
    $label   = "   $([char]0x25BA) TOTAL SPACE TO FREE:  "
    $inner   = "$label$sizeStr"
    $padded  = $inner.PadRight(60)
    Write-Host ""
    Write-Host "  $([char]0x256D)$([string][char]0x2500 * 60)$([char]0x256E)" -ForegroundColor $M
    Write-Host "  $([char]0x2502)" -NoNewline -ForegroundColor $M
    Write-Host $label -NoNewline -ForegroundColor $W
    Write-Host $sizeStr.PadRight(60 - $label.Length) -NoNewline -ForegroundColor $Y
    Write-Host "$([char]0x2502)" -ForegroundColor $M
    Write-Host "  $([char]0x2570)$([string][char]0x2500 * 60)$([char]0x256F)" -ForegroundColor $M
}

# ── Size helpers (files only — avoids Length error on dirs) ──

function Get-FolderSize($path) {
    if (-not (Test-Path $path)) { return [double]0 }
    $sum = (Get-ChildItem -Path $path -Recurse -Force -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if (-not $sum) { return [double]0 }
    return [math]::Round($sum / 1MB, 2)
}

function Remove-FolderContents($path) {
    if (-not (Test-Path $path)) { return [double]0 }
    $before = Get-FolderSize $path
    Get-ChildItem -Path $path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $after = Get-FolderSize $path
    $freed = $before - $after
    if ($freed -lt 0) { $freed = 0 }
    return [math]::Round($freed, 2)
}

# ── Chromium helpers ─────────────────────────────────────────

$chromeSubs = @(
    "Cache\Cache_Data", "Code Cache\js", "Code Cache\wasm",
    "GPUCache", "Service Worker\CacheStorage",
    "Service Worker\ScriptCache", "blob_storage"
)

function Measure-ChromiumProfile($path) {
    $t = [double]0
    foreach ($s in $chromeSubs) { $t += Get-FolderSize "$path\$s" }
    return $t
}

function Clean-ChromiumProfile($path) {
    $t = [double]0
    foreach ($s in $chromeSubs) { $t += Remove-FolderContents "$path\$s" }
    return $t
}

function Get-ChromiumProfiles($userDataPath) {
    if (-not (Test-Path $userDataPath)) { return @() }
    return Get-ChildItem -Path $userDataPath -Directory -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" }
}

function Measure-ChromiumBrowser($userDataPath) {
    $result = [PSCustomObject]@{ Total = [double]0; Profiles = [System.Collections.Generic.List[PSCustomObject]]::new() }
    if (-not (Test-Path $userDataPath)) { return $result }
    $result.Total += Get-FolderSize "$userDataPath\ShaderCache\GPUCache"
    $result.Total += Get-FolderSize "$userDataPath\GrShaderCache\GPUCache"
    foreach ($d in (Get-ChromiumProfiles $userDataPath)) {
        $s = Measure-ChromiumProfile $d.FullName
        $result.Total += $s
        $result.Profiles.Add([PSCustomObject]@{ Name = $d.Name; Size = $s })
    }
    return $result
}

function Clean-ChromiumBrowser($userDataPath) {
    $t = [double]0
    if (-not (Test-Path $userDataPath)) { return $t }
    $t += Remove-FolderContents "$userDataPath\ShaderCache\GPUCache"
    $t += Remove-FolderContents "$userDataPath\GrShaderCache\GPUCache"
    foreach ($d in (Get-ChromiumProfiles $userDataPath)) { $t += Clean-ChromiumProfile $d.FullName }
    return $t
}

# ── Firefox helpers ──────────────────────────────────────────

function Measure-FFProfile($roamingP, $localP) {
    return  (Get-FolderSize "$localP\cache2\entries") +
            (Get-FolderSize "$localP\startupCache") +
            (Get-FolderSize "$roamingP\cache2\entries") +
            (Get-FolderSize "$roamingP\startupCache") +
            (Get-FolderSize "$roamingP\thumbnails")
}

function Clean-FFProfile($roamingP, $localP) {
    $t = [double]0
    $t += Remove-FolderContents "$localP\cache2\entries"
    $t += Remove-FolderContents "$localP\startupCache"
    $t += Remove-FolderContents "$roamingP\cache2\entries"
    $t += Remove-FolderContents "$roamingP\startupCache"
    $t += Remove-FolderContents "$roamingP\thumbnails"
    return $t
}

# ════════════════════════════════════════════════════════════
#  SCAN
# ════════════════════════════════════════════════════════════

$local   = $env:LOCALAPPDATA
$roaming = $env:APPDATA

Write-Header "  CACHE CLEANER  v3  —  Nord Edition  "
Write-Host ""
Write-Host "  $([char]0x25BA) " -NoNewline -ForegroundColor $C
Write-Host "Scanning your system..." -ForegroundColor $W
Write-Host "  $([char]0x25BA) " -NoNewline -ForegroundColor $C
Write-Host "Cookies and logins will " -NoNewline -ForegroundColor $W
Write-Host "NOT" -NoNewline -ForegroundColor $G
Write-Host " be touched." -ForegroundColor $W
Write-Host ""

Write-Host "  $([char]0x25CF) Brave      " -NoNewline -ForegroundColor $DG
$brave = Measure-ChromiumBrowser "$local\BraveSoftware\Brave-Browser\User Data"
Write-Host "done  ($("{0:N2}" -f $brave.Total) MB)" -ForegroundColor $G

Write-Host "  $([char]0x25CF) Chrome     " -NoNewline -ForegroundColor $DG
$chrome = Measure-ChromiumBrowser "$local\Google\Chrome\User Data"
Write-Host "done  ($("{0:N2}" -f $chrome.Total) MB)" -ForegroundColor $G

Write-Host "  $([char]0x25CF) Edge       " -NoNewline -ForegroundColor $DG
$edge = Measure-ChromiumBrowser "$local\Microsoft\Edge\User Data"
Write-Host "done  ($("{0:N2}" -f $edge.Total) MB)" -ForegroundColor $G

Write-Host "  $([char]0x25CF) Firefox    " -NoNewline -ForegroundColor $DG
$ffTotal    = [double]0
$ffProfiles = [System.Collections.Generic.List[PSCustomObject]]::new()
$ffRoaming  = "$roaming\Mozilla\Firefox\Profiles"
$ffLocal    = "$local\Mozilla\Firefox\Profiles"
if (Test-Path $ffRoaming) {
    foreach ($p in (Get-ChildItem $ffRoaming -Directory -ErrorAction SilentlyContinue)) {
        $s = Measure-FFProfile "$ffRoaming\$($p.Name)" "$ffLocal\$($p.Name)"
        $ffTotal += $s
        $ffProfiles.Add([PSCustomObject]@{ Name = $p.Name; Size = $s })
    }
}
Write-Host "done  ($("{0:N2}" -f $ffTotal) MB)" -ForegroundColor $G

Write-Host "  $([char]0x25CF) System Temp" -NoNewline -ForegroundColor $DG
$tempItems = [System.Collections.Generic.List[PSCustomObject]]::new()
$tempItems.Add([PSCustomObject]@{ Label = "User Temp (%TEMP%)";            Path = $env:TEMP })
$tempItems.Add([PSCustomObject]@{ Label = "Windows Temp";                  Path = "C:\Windows\Temp" })
$tempItems.Add([PSCustomObject]@{ Label = "Prefetch Cache";                Path = "C:\Windows\Prefetch" })
$tempItems.Add([PSCustomObject]@{ Label = "Windows Update Download Cache"; Path = "C:\Windows\SoftwareDistribution\Download" })
foreach ($t in $tempItems) { $t | Add-Member -NotePropertyName Size -NotePropertyValue (Get-FolderSize $t.Path) }
$tempTotal = [double]0; foreach ($t in $tempItems) { $tempTotal += $t.Size }
Write-Host " done  ($("{0:N2}" -f $tempTotal) MB)" -ForegroundColor $G

$grandTotal = $brave.Total + $chrome.Total + $edge.Total + $ffTotal + $tempTotal

# ════════════════════════════════════════════════════════════
#  REPORT
# ════════════════════════════════════════════════════════════

Write-SectionHeader " BRAVE"
Write-TotalRow "Total Brave Cache" $brave.Total
foreach ($p in $brave.Profiles) { Write-ItemRow $p.Name $p.Size }
Write-SectionFooter

Write-SectionHeader " GOOGLE CHROME"
Write-TotalRow "Total Chrome Cache" $chrome.Total
foreach ($p in $chrome.Profiles) { Write-ItemRow $p.Name $p.Size }
Write-SectionFooter

Write-SectionHeader " MICROSOFT EDGE"
Write-TotalRow "Total Edge Cache" $edge.Total
foreach ($p in $edge.Profiles) { Write-ItemRow $p.Name $p.Size }
Write-SectionFooter

Write-SectionHeader " MOZILLA FIREFOX"
Write-TotalRow "Total Firefox Cache" $ffTotal
foreach ($p in $ffProfiles) { Write-ItemRow $p.Name $p.Size }
Write-SectionFooter

Write-SectionHeader " SYSTEM TEMP"
foreach ($t in $tempItems) { Write-ItemRow $t.Label $t.Size }
Write-SectionFooter

Write-GrandTotal $grandTotal

# ════════════════════════════════════════════════════════════
#  CONFIRM
# ════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  $([char]0x25CF) " -NoNewline -ForegroundColor $Y
Write-Host "Cookies, saved passwords, and logins are " -NoNewline -ForegroundColor $W
Write-Host "NOT" -NoNewline -ForegroundColor $G
Write-Host " included." -ForegroundColor $W
Write-Host ""
Write-Host "  $([char]0x25BA) " -NoNewline -ForegroundColor $C
Write-Host "Proceed with cleaning? " -NoNewline -ForegroundColor $W
Write-Host "[Y] Yes   [N] No" -NoNewline -ForegroundColor $Y
Write-Host "  :  " -NoNewline -ForegroundColor $C
$confirm = Read-Host

if ($confirm -notmatch "^[Yy]$") {
    Write-Host ""
    Write-Host "  $([char]0x25CB) Cancelled. Nothing was deleted." -ForegroundColor $Y
    Write-Host ""
    Pause; Exit
}

# ════════════════════════════════════════════════════════════
#  CLEAN
# ════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  $([char]0x25BA) Cleaning..." -ForegroundColor $W
Write-Host ""

$totalFreed = [double]0

Write-Host "  $([char]0x25CF) Brave       " -NoNewline -ForegroundColor $DG
$f = Clean-ChromiumBrowser "$local\BraveSoftware\Brave-Browser\User Data"
$totalFreed += $f; Write-Host "$("{0:N2}" -f $f) MB freed" -ForegroundColor $G

Write-Host "  $([char]0x25CF) Chrome      " -NoNewline -ForegroundColor $DG
$f = Clean-ChromiumBrowser "$local\Google\Chrome\User Data"
$totalFreed += $f; Write-Host "$("{0:N2}" -f $f) MB freed" -ForegroundColor $G

Write-Host "  $([char]0x25CF) Edge        " -NoNewline -ForegroundColor $DG
$f = Clean-ChromiumBrowser "$local\Microsoft\Edge\User Data"
$totalFreed += $f; Write-Host "$("{0:N2}" -f $f) MB freed" -ForegroundColor $G

Write-Host "  $([char]0x25CF) Firefox     " -NoNewline -ForegroundColor $DG
$ff = [double]0
if (Test-Path $ffRoaming) {
    foreach ($p in (Get-ChildItem $ffRoaming -Directory -ErrorAction SilentlyContinue)) {
        $ff += Clean-FFProfile "$ffRoaming\$($p.Name)" "$ffLocal\$($p.Name)"
    }
}
$totalFreed += $ff; Write-Host "$("{0:N2}" -f $ff) MB freed" -ForegroundColor $G

Write-Host "  $([char]0x25CF) System Temp " -NoNewline -ForegroundColor $DG
$st = [double]0
foreach ($t in $tempItems) { $st += Remove-FolderContents $t.Path }
$totalFreed += $st; Write-Host "$("{0:N2}" -f $st) MB freed" -ForegroundColor $G

# ════════════════════════════════════════════════════════════
#  DONE
# ════════════════════════════════════════════════════════════

$sizeStr = "{0:N2} MB  ({1:N3} GB)" -f $totalFreed, ($totalFreed / 1024)
$label   = "   $([char]0x2714)  DONE! Freed:  "

Write-Host ""
Write-Host "  $([char]0x256D)$([string][char]0x2500 * 60)$([char]0x256E)" -ForegroundColor $G
Write-Host "  $([char]0x2502)" -NoNewline -ForegroundColor $G
Write-Host $label -NoNewline -ForegroundColor $W
Write-Host $sizeStr.PadRight(60 - $label.Length) -NoNewline -ForegroundColor $Y
Write-Host "$([char]0x2502)" -ForegroundColor $G
Write-Host "  $([char]0x2502)" -NoNewline -ForegroundColor $G
Write-Host "   $([char]0x2714)  Cookies and logins are untouched.".PadRight(60) -NoNewline -ForegroundColor $G
Write-Host "$([char]0x2502)" -ForegroundColor $G
Write-Host "  $([char]0x2570)$([string][char]0x2500 * 60)$([char]0x256F)" -ForegroundColor $G
Write-Host ""
Pause