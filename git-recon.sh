#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 tesla.com"
    exit 1
fi

DOMAIN=$1
SUBDOMAINS_FILE="${DOMAIN}-subdomains_list.txt"
EXPOSURE_FILE="${DOMAIN}-git_exposure_results.txt"

echo "==============================="
echo "      GIT SEARCH TOOL"
echo "==============================="
echo

# Check if assetfinder is installed, if not, download it
if ! command -v assetfinder &> /dev/null; then
    echo "[!] Assetfinder not found. Downloading it..."
    wget -q -O assetfinder.tar.gz https://github.com/tomnomnom/assetfinder/releases/latest/download/assetfinder-linux-amd64.tar.gz
    tar -xzf assetfinder.tar.gz -C /usr/local/bin/
    chmod +x /usr/local/bin/assetfinder
    rm assetfinder.tar.gz
    echo "[+] Assetfinder installed successfully."
fi

echo "[+] Fetching subdomains for $DOMAIN and its assets from crt.sh..."

SUBDOMAINS=$(curl -s "https://crt.sh/?q=%25${DOMAIN}&output=json" | jq -r '.[].name_value' 2>/dev/null | sort -u)

if [ -z "$SUBDOMAINS" ]; then
    echo "[!] No subdomains found on crt.sh. Trying alternative tools (assetfinder)..."
    SUBDOMAINS=$(assetfinder --subs-only $DOMAIN | sort -u)
fi

if [ -z "$SUBDOMAINS" ]; then
    echo "[!] No subdomains found. Exiting."
    exit 1
fi

echo "[+] Total subdomains found: $(echo "$SUBDOMAINS" | wc -l)"
echo "$SUBDOMAINS" > "$SUBDOMAINS_FILE"

echo "[+] Scanning for Git exposure on subdomains..."
echo "$SUBDOMAINS" | \
    sed 's#$#.git/HEAD#' | \
    httpx_projectdiscovery -silent -no-color -content-length -status-code 200,301,302 \
    -ports 80,8000,443 -threads 500 -title \
    -timeout 3 -retries 0 | \
    anew "$EXPOSURE_FILE"

echo
echo "==============================="
echo "         SCAN COMPLETE"
echo "==============================="
echo "[+] Subdomains list saved to: $SUBDOMAINS_FILE"
echo "[+] Git exposure results saved to: $EXPOSURE_FILE"
