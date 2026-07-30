# Windows Fresh Setup - Application Installer
# Run this script after a factory reset or on a new Windows 11 machine.
# Usage: Right-click > "Run with PowerShell" or run from terminal:
#   powershell -ExecutionPolicy Bypass -File install-apps.ps1

# Require Administrator — auto-relaunch with elevation if needed
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges. Relaunching as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$apps = @(
    # Browser
    @{ Id = "Brave.Brave";                  Name = "Brave Browser" },

    # Security
    @{ Id = "Bitdefender.Bitdefender";       Name = "Bitdefender" },
    @{ Id = "NordSecurity.NordVPN";          Name = "NordVPN" },
    @{ Id = "tailscale.tailscale";           Name = "Tailscale" },
    @{ Id = "Bitwarden.Bitwarden";           Name = "Bitwarden" },
    @{ Id = "KeePassXCTeam.KeePassXC";      Name = "KeePassXC" },
    @{ Id = "Malwarebytes.Malwarebytes";     Name = "Malwarebytes" },
    @{ Id = "NextDNS.NextDNS";               Name = "NextDNS" },
    @{ Id = "token2.FIDO2Manager";           Name = "FIDO2 Token Manager (Token2)" },

    # Development
    @{ Id = "Git.Git";                       Name = "Git" },
    @{ Id = "Microsoft.VisualStudioCode";    Name = "Visual Studio Code" },
    @{ Id = "Microsoft.WindowsTerminal";     Name = "Windows Terminal" },
    @{ Id = "Python.Python.3.13";            Name = "Python 3.13" },
    @{ Id = "GitHub.GitHubDesktop";          Name = "GitHub Desktop" },

    # AI Tools
    @{ Id = "Anthropic.Claude";              Name = "Claude Desktop" },

    # Productivity
    # Microsoft 365 (Office) excluded — Click-to-Run installer does not support silent winget install.
    # Install manually from https://www.microsoft.com/microsoft-365 or via Microsoft 365 admin portal.
    @{ Id = "Greenshot.Greenshot";           Name = "Greenshot" },
    @{ Id = "Notepad++.Notepad++";           Name = "Notepad++" },
    @{ Id = "7zip.7zip";                     Name = "7-Zip" },
    @{ Id = "VideoLAN.VLC";                  Name = "VLC" },
    @{ Id = "Microsoft.PowerToys";           Name = "PowerToys" },

    # Remote Access
    @{ Id = "mRemoteNG.mRemoteNG";           Name = "mRemoteNG" },

    # Entertainment
    @{ Id = "Spotify.Spotify"; Name = "Spotify"; Source = "winget" }

    # Medical - uncomment below to install when needed
    # @{ Id = "MicroDicom.MicroDicomViewer";  Name = "MicroDicom" }

)

# Manual installs reminder - apps that cannot be installed via winget
$manualInstalls = @(
    "Microsoft 365 - https://www.microsoft.com/microsoft-365 (Click-to-Run installer does not support silent winget install)",
    "Perplexity    - https://www.perplexity.ai/downloads (no winget package available)",
    "MicroDicom    - https://www.microdicom.com (uncomment in script when needed)"
)

Write-Host "`nWindows Fresh Setup - Installing Applications" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$total = $apps.Count
$index = 0
$failed = @()

foreach ($app in $apps) {
    $index++
    Write-Host "`n[$index/$total] Installing $($app.Name)..." -ForegroundColor Yellow

    $sourceArg = if ($app.Source) { @("--source", $app.Source) } else { @() }
    $result = winget install --id $app.Id --silent --accept-package-agreements --accept-source-agreements @sourceArg 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK  $($app.Name) installed successfully." -ForegroundColor Green
    } elseif ($LASTEXITCODE -eq -1978335189) {
        Write-Host "  --  $($app.Name) is already installed. Skipping." -ForegroundColor DarkGray
    } else {
        Write-Host "  !!  $($app.Name) failed (exit code $LASTEXITCODE)." -ForegroundColor Red
        Write-Host "      $result" -ForegroundColor DarkRed
        $failed += $app.Name
    }
}

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "Installation Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if ($failed.Count -gt 0) {
    Write-Host "`nThe following apps failed and require manual installation:" -ForegroundColor Red
    foreach ($name in $failed) {
        Write-Host "  - $name" -ForegroundColor Red
    }
} else {
    Write-Host "`nAll apps installed successfully." -ForegroundColor Green
}

Write-Host "`nThe following apps always require manual installation:" -ForegroundColor Yellow
foreach ($item in $manualInstalls) {
    Write-Host "  - $item" -ForegroundColor Yellow
}

Write-Host ""
