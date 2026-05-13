# 🧹 BrowserCacheCleaner

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-A3BE8C?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-3.0-88C0D0?style=for-the-badge)

**A Nord-themed terminal tool that scans, previews, and cleans browser cache and system temp files — without ever touching your cookies or logins.**

</div>

---

## ✨ Features

- 🔍 **Scan first, delete later** — shows exactly how much space will be freed before touching anything
- ✅ **Confirm prompt** — nothing is deleted until you type `Y`
- 🍪 **Cookies & logins are 100% safe** — only cache, temp, and junk files are removed
- 👤 **All profiles auto-detected** — handles 50+ Chrome profiles, multiple Brave profiles, and all Firefox profiles automatically
- 🖥️ **Opens in Windows Terminal** — with Nord colour scheme and JetBrainsMono Nerd Font
- 🎨 **Nord-themed UI** — box-drawing characters, colour-coded output, Oh-My-Posh style

---

## 🌐 Supported Browsers

| Browser | Profiles | Cache Types Cleaned |
|---|---|---|
| **Brave** | ✅ All profiles | Cache, Code Cache, GPU Cache, Shader Cache, Service Workers, Blob Storage |
| **Google Chrome** | ✅ All profiles | Cache, Code Cache, GPU Cache, Shader Cache, Service Workers, Blob Storage |
| **Microsoft Edge** | ✅ All profiles | Cache, Code Cache, GPU Cache, Shader Cache, Service Workers, Blob Storage |
| **Mozilla Firefox** | ✅ All profiles | cache2, startupCache, thumbnails |

## 🗂️ System Locations Cleaned

| Location | Path |
|---|---|
| User Temp | `%TEMP%` |
| Windows Temp | `C:\Windows\Temp` |
| Prefetch Cache | `C:\Windows\Prefetch` |
| Windows Update Cache | `C:\Windows\SoftwareDistribution\Download` |

---

## 📸 Preview

```
  ╔══════════════════════════════════════════════════════════════╗
  ║           CACHE CLEANER  v3  —  Nord Edition                 ║
  ╚══════════════════════════════════════════════════════════════╝

  ► Scanning your system...
  ► Cookies and logins will NOT be touched.

  ● Brave       done  (648.12 MB)
  ● Chrome      done  (1,204.37 MB)
  ● Edge        done  (31.48 MB)
  ● Firefox     done  (0.00 MB)
  ● System Temp done  (4,130.82 MB)

  ╭───  GOOGLE CHROME ─────────────────────────────────────────╮
  │  ➔  Total Chrome Cache                       1,204.37 MB   │
  │     ▸ Profile 100                              312.63 MB   │
  │     ▸ Profile 110                               41.23 MB   │
  │     ▸ Profile 111                               75.69 MB   │
  │     ▸ Profile 112                               ...        │
  ╰────────────────────────────────────────────────────────────╯

  ╭────────────────────────────────────────────────────────────╮
  │   ► TOTAL SPACE TO FREE:  6,014.79 MB  (5.874 GB)         │
  ╰────────────────────────────────────────────────────────────╯

  ● Cookies, saved passwords, and logins are NOT included.

  ► Proceed with cleaning? [Y] Yes   [N] No  :
```

---

## 🚀 Quick Start

### 1. Download

Clone the repo or download both files:

```
BrowserCacheCleaner/
├── CleanCacheAndTemp.ps1   ← main script
└── RunCleaner.bat          ← launcher (double-click this)
```

### 2. Run

> **Both files must be in the same folder.**

Double-click **`RunCleaner.bat`**

- It will auto-request Administrator privileges
- Opens in **Windows Terminal** (falls back to PowerShell window if WT is not installed)
- Scans everything first, shows the full report, then asks for confirmation

> ⚠️ Administrator is required to clean `C:\Windows\Temp`, `Prefetch`, and Windows Update cache.

---

## 🎨 Recommended Terminal Setup

For the best visual experience with the Nord UI and box-drawing characters:

### Font — JetBrains Mono Nerd Font

The script uses Unicode box-drawing characters and Nerd Font glyphs. Without a Nerd Font, some symbols may render as squares or question marks.

**Install:**

1. Go to [https://www.nerdfonts.com/font-downloads](https://www.nerdfonts.com/font-downloads)
2. Search for **JetBrainsMono** and download the zip
3. Extract → select all `.ttf` files → right-click → **Install for all users**

Or install via [Scoop](https://scoop.sh/):

```powershell
scoop bucket add nerd-fonts
scoop install JetBrainsMono-NF
```

Or install via [winget](https://learn.microsoft.com/en-us/windows/package-manager/):

```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont
```

### Windows Terminal — Nord Color Scheme

1. Open **Windows Terminal** → Settings (`Ctrl+,`)
2. Go to **Profiles → Defaults → Appearance**
3. Set **Font face** to `JetBrainsMono Nerd Font`
4. Set **Font size** to `11` or `12`
5. Under **Color scheme**, click **Add new** and paste the Nord theme below:

<details>
<summary>📋 Nord Color Scheme JSON (click to expand)</summary>

```json
{
    "name": "Nord",
    "black": "#3B4252",
    "red": "#BF616A",
    "green": "#A3BE8C",
    "yellow": "#EBCB8B",
    "blue": "#81A1C1",
    "purple": "#B48EAD",
    "cyan": "#88C0D0",
    "white": "#E5E9F0",
    "brightBlack": "#4C566A",
    "brightRed": "#BF616A",
    "brightGreen": "#A3BE8C",
    "brightYellow": "#EBCB8B",
    "brightBlue": "#81A1C1",
    "brightPurple": "#B48EAD",
    "brightCyan": "#8FBCBB",
    "brightWhite": "#ECEFF4",
    "background": "#2E3440",
    "foreground": "#D8DEE9",
    "selectionBackground": "#4C566A",
    "cursorColor": "#D8DEE9"
}
```

To apply: open `settings.json` (`Ctrl+Shift+,`) and add the above object inside the `"schemes": [ ... ]` array.

</details>

### Oh My Posh (Optional — for the full shell experience)

```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget
```

Then set a Nord-compatible theme:

```powershell
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\nordtron.omp.json" | Invoke-Expression
```

Add that line to your PowerShell profile (`$PROFILE`) to make it permanent.

---

## 🛡️ What Is NOT Deleted

| Data | Safe? |
|---|---|
| Cookies | ✅ Never touched |
| Saved passwords | ✅ Never touched |
| Login sessions | ✅ Never touched |
| Bookmarks | ✅ Never touched |
| Extensions | ✅ Never touched |
| Browser history | ✅ Never touched |
| Downloaded files | ✅ Never touched |

Only **cache**, **temp**, **GPU shader cache**, **service worker cache**, and **prefetch** data is removed — files that browsers and Windows regenerate automatically.

---

## 🔧 How It Works

```
RunCleaner.bat
    │
    ├── Requests Administrator privileges (UAC prompt)
    ├── Detects Windows Terminal (wt.exe) → opens there
    │   └── Falls back to PowerShell window if WT not found
    │
    └── CleanCacheAndTemp.ps1
            │
            ├── PHASE 1: SCAN
            │       Finds all browser profiles automatically
            │       Measures cache size per profile (files only)
            │
            ├── PHASE 2: REPORT
            │       Displays Nord-themed breakdown table
            │       Shows total space to be freed
            │
            ├── PHASE 3: CONFIRM
            │       Prompts [Y] Yes / [N] No
            │       Exits cleanly if user says No
            │
            └── PHASE 4: CLEAN
                    Deletes files only (not folder structure)
                    Reports MB freed per browser
                    Shows final total
```

---

## 📋 Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+ (built-in on Windows 10/11)
- Administrator privileges (for system temp folders)
- Windows Terminal *(optional, for best UI — falls back gracefully)*

---

## 📁 Files

| File | Description |
|---|---|
| `CleanCacheAndTemp.ps1` | Main PowerShell script — all logic, UI, scanning, and cleaning |
| `RunCleaner.bat` | Launcher — handles UAC elevation and opens Windows Terminal |

---

## 🤝 Contributing

Pull requests are welcome. If you find a cache path that isn't being cleaned, or a browser profile format not detected, feel free to open an issue with your browser version and profile path from `about:version`.

---

## 📄 License

MIT — free to use, modify, and distribute.

---

<div align="center">
Made with ☕ and too many browser profiles
</div>
