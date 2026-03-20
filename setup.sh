#!/usr/bin/env bash
set -euo pipefail

FEED_URL="https://pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/registry/"

echo "Setting up silvy CLI..."

# Authenticate to the feed (if az CLI is available)
if command -v az &> /dev/null; then
  echo "Authenticating to Azure Artifacts..."
  az artifacts npm login --organization https://dev.azure.com/imf --feed silvy-feed 2>/dev/null || true
fi

# Install silvy globally from the Azure Artifacts feed
npm install -g silvy --registry "$FEED_URL"

echo ""
echo "✓ silvy CLI installed successfully!"
echo "  Run 'silvy --help' to get started."
