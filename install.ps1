#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$FeedUrl   = "https://pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/registry/"
$FeedPath  = "//pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/registry/"
$NpmrcPath = Join-Path $env:USERPROFILE ".npmrc"
$SilvyDir  = Join-Path $env:USERPROFILE ".silvy"
$SilvyBin  = Join-Path $SilvyDir "bin" # npm --prefix puts binaries here on Windows: .silvy/bin

Write-Host "================================================"
Write-Host "  silvy CLI - Installer"
Write-Host "================================================"
Write-Host ""

# 1. Check prerequisites
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Node.js is required (>= 22). Install it from https://nodejs.org" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Azure CLI (az) is required. Install it from https://aka.ms/install-az" -ForegroundColor Red
    exit 1
}

# 2. Ensure user is logged in to Azure
$azAccount = az account show 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "You are not logged in to Azure. Launching login..."
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Azure login failed." -ForegroundColor Red
        exit 1
    }
}

# 3. Get an Azure DevOps access token (bearer token for Azure Artifacts)
Write-Host "Generating Azure Artifacts credentials..."
$Token = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv

if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Host "Error: Could not obtain access token. Make sure you have access to the imf organization." -ForegroundColor Red
    exit 1
}

# 4. Write feed config to user-level .npmrc (preserve existing entries)
# Remove any previous silvy-feed entries
if (Test-Path $NpmrcPath) {
    $existingLines = Get-Content $NpmrcPath | Where-Object {
        $_ -notmatch "pkgs\.dev\.azure\.com/imf/ITDEA\.AI\.DLC/_packaging/silvy-feed"
    }
    Set-Content -Path $NpmrcPath -Value $existingLines
}

# Use _authToken (bearer token) — correct format for Azure Artifacts
Add-Content -Path $NpmrcPath -Value "${FeedPath}:_authToken=${Token}"

Write-Host "Credentials written to $NpmrcPath"

# 5. Install silvy globally from the feed (user-level, no admin required)
Write-Host "Installing silvy from Azure Artifacts..."
npm install -g silvy --registry $FeedUrl --prefix $SilvyDir

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: npm install failed." -ForegroundColor Red
    exit 1
}

# 6. Add ~/.silvy to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$SilvyBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$SilvyBin;$currentPath", "User")
    Write-Host "Added $SilvyBin to user PATH."
}

# Make it available in the current session
$env:Path = "$SilvyBin;$env:Path"

Write-Host ""
Write-Host "================================================"
Write-Host "  silvy CLI installed successfully!" -ForegroundColor Green
Write-Host "    Run 'silvy --help' to get started."
Write-Host ""
Write-Host "    If 'silvy' is not found, restart your terminal"
Write-Host "    or run: `$env:Path = `"$SilvyBin;`$env:Path`""
Write-Host "================================================"
