#!/usr/bin/env bash
set -euo pipefail

ORG="https://dev.azure.com/imf"
FEED_URL="https://pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/registry/"
NPMRC="$HOME/.npmrc"

echo "================================================"
echo "  silvy CLI — Installer"
echo "================================================"
echo ""

# 1. Check prerequisites
if ! command -v node &> /dev/null; then
  echo "Error: Node.js is required (>= 22). Install it from https://nodejs.org"
  exit 1
fi

if ! command -v az &> /dev/null; then
  echo "Error: Azure CLI (az) is required. Install it from https://aka.ms/install-az"
  exit 1
fi

# 2. Ensure user is logged in to Azure
if ! az account show &> /dev/null; then
  echo "You are not logged in to Azure. Launching login..."
  az login
fi

# 3. Generate a short-lived Azure DevOps PAT via Azure CLI
echo "Generating Azure Artifacts credentials..."
TOKEN=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)

if [ -z "$TOKEN" ]; then
  echo "Error: Could not obtain access token. Make sure you have access to the imf organization."
  exit 1
fi

# 4. Encode credentials (base64 of :TOKEN)
BASE64_TOKEN=$(printf ":%s" "$TOKEN" | base64 | tr -d '\n')

# 5. Write feed config to user-level .npmrc (preserve existing entries)
# Remove any previous silvy-feed entries
if [ -f "$NPMRC" ]; then
  grep -v "pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed" "$NPMRC" > "${NPMRC}.tmp" || true
  mv "${NPMRC}.tmp" "$NPMRC"
fi

cat >> "$NPMRC" << EOF
//pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/registry/:username=silvy-feed
//pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/registry/:_password=${BASE64_TOKEN}
//pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/registry/:email=not-used@example.com
//pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/:username=silvy-feed
//pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/:_password=${BASE64_TOKEN}
//pkgs.dev.azure.com/imf/ITDEA.AI.DLC/_packaging/silvy-feed/npm/:email=not-used@example.com
EOF

echo "Credentials written to $NPMRC"

# 6. Install silvy globally from the feed
echo "Installing silvy from Azure Artifacts..."
npm install -g silvy --registry "$FEED_URL"

echo ""
echo "================================================"
echo "  ✓ silvy CLI installed successfully!"
echo "    Run 'silvy --help' to get started."
echo "================================================"
