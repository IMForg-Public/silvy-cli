#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$FeedUrl = "https://pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/registry/"

Write-Host "Setting up silvy CLI..."

# Authenticate to the feed (if az CLI is available)
if (Get-Command az -ErrorAction SilentlyContinue) {
    Write-Host "Authenticating to Azure Artifacts..."
    try {
        az artifacts npm login --organization https://dev.azure.com/imf --feed silvy-feed 2>$null
    } catch {
        # Ignore auth errors, proceed with install
    }
}

# Install silvy globally from the Azure Artifacts feed
npm install -g silvy --registry $FeedUrl

Write-Host ""
Write-Host "v silvy CLI installed successfully!"
Write-Host "  Run 'silvy --help' to get started."
