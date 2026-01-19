#!/bin/sh

APK_DIR="apk"
mkdir -p "$APK_DIR"

# Helper for GitHub API
github_latest_release() {
    local repo=$1
    local filter=$2
    local url
    
    # Use GITHUB_TOKEN if available to avoid rate limits
    local auth_header=""
    if [ -n "$GITHUB_TOKEN" ]; then
        auth_header="-H \"Authorization: token $GITHUB_TOKEN\""
    fi
    
    local release_json
    release_json=$(eval "curl -s -L $auth_header https://api.github.com/repos/$repo/releases/latest")
    
    if echo "$release_json" | grep -q "API rate limit exceeded"; then
        echo "[E] GitHub API rate limit exceeded." >&2
        return 1
    fi
    
    url=$(echo "$release_json" | grep "browser_download_url" | grep "$filter" | grep -v "\-hw" | cut -d '"' -f 4 | head -n 1)
    echo "$url"
}

# Helper to check file size and download
check_and_download() {
    local url=$1
    local path=$2
    local name=$3
    
    if [ -z "$url" ]; then
        echo "[E] Missing URL for $name"
        return 1
    fi

    # Get remote size if possible
    # We follow redirects (-L) and fetch only headers (-I)
    local remote_size
    remote_size=$(curl -sL -I "$url" | grep -i "^Content-Length" | tail -n 1 | awk '{print $2}' | tr -d '\r\n')
    
    if [ -f "$path" ] && [ -n "$remote_size" ]; then
        local local_size
        local_size=$(stat -c %s "$path" 2>/dev/null || wc -c < "$path" | awk '{print $1}')
        
        if [ "$local_size" != "$remote_size" ]; then
            echo "[W] Local $name size ($local_size) differs from remote version ($remote_size)!"
            echo "[W] Updating existing file..."
        else
            echo "[I] Local $name is up to date ($local_size bytes). Skipping download."
            return 0
        fi
    fi

    echo "[I] Downloading $name..."
    curl -L "$url" -o "$path"
}

echo "microG Flex APK Fetcher"
echo "======================="
echo ""
echo "This script will download all APK variants:"
echo "  - microG GmsCore"
echo "  - microG GsfProxy"
echo "  - Google Play Store"
echo "  - microG Companion (FakeStore)"
echo ""

echo "[P] Fetching latest microG GmsCore..."
GMS_URL=$(github_latest_release "microg/GmsCore" "com.google.android.gms")
check_and_download "$GMS_URL" "$APK_DIR/com.google.android.gms.apk" "GmsCore"

echo ""
echo "[P] Fetching latest microG GsfProxy..."
GSF_URL=$(github_latest_release "microg/GsfProxy" "GsfProxy")
check_and_download "$GSF_URL" "$APK_DIR/com.google.android.gsf.apk" "GsfProxy"

echo ""
echo "[P] Fetching microG Companion (FakeStore)..."
COMPANION_URL=$(github_latest_release "microg/GmsCore" "com.android.vending")
check_and_download "$COMPANION_URL" "$APK_DIR/com.android.vending-companion.apk" "Companion"

echo ""
echo "[P] Fetching Google Play Store ZIP..."
VENDING_ZIP_URL="http://bnsmb.de/files/public/Android/PlayStore_for_MicroG_41.1.19-31-v1.0.0.zip"
VENDING_ZIP="$APK_DIR/playstore.zip"
echo "[I] Downloading Play Store ZIP from $VENDING_ZIP_URL"
curl -L "$VENDING_ZIP_URL" -o "$VENDING_ZIP"

if [ -f "$VENDING_ZIP" ]; then
    echo "[P] Extracting Phonesky.apk (Play Store)..."
    unzip -o "$VENDING_ZIP" "system/product/priv-app/Phonesky/Phonesky.apk" -d "$APK_DIR/tmp" > /dev/null
    if [ -f "$APK_DIR/tmp/system/product/priv-app/Phonesky/Phonesky.apk" ]; then
        mv "$APK_DIR/tmp/system/product/priv-app/Phonesky/Phonesky.apk" "$APK_DIR/PlayStore.apk"
        echo "[I] Play Store APK saved to $APK_DIR/PlayStore.apk"
    else
        echo "[E] Failed to extract Phonesky.apk from ZIP"
    fi
    rm -rf "$APK_DIR/tmp"
    rm -f "$VENDING_ZIP"
fi

echo ""
echo "[P] Fetching Aurora Store (from F-Droid)..."
AURORA_PAGE=$(curl -s -L "https://f-droid.org/en/packages/com.aurora.store/")
AURORA_URL=$(echo "$AURORA_PAGE" | grep -o 'https://f-droid.org/repo/com.aurora.store_[0-9]*\.apk' | head -n 1)

if [ -n "$AURORA_URL" ]; then
    check_and_download "$AURORA_URL" "$APK_DIR/AuroraStore.apk" "Aurora Store"
else
    echo "[E] Failed to find Aurora Store URL on F-Droid!"
fi

echo ""
echo "[P] Fetching Aurora Services (from GitLab)..."
# GitLab API to find the latest release
# The APK is usually linked in the description, not in assets
# We fetch the latest release JSON and parse the first /uploads/ link ending in .apk
AURORA_SERVICES_JSON=$(curl -sL "https://gitlab.com/api/v4/projects/AuroraOSS%2FAuroraServices/releases/permalink/latest")
# Extract the relative path (e.g., /uploads/xym.../AuroraServices.apk)
# GitLab puts these in the description as markdown links: [name](/uploads/path.apk)
AURORA_SERVICES_PATH=$(echo "$AURORA_SERVICES_JSON" | grep -o '/uploads/[^()"]*\.apk' | head -n 1)

if [ -n "$AURORA_SERVICES_PATH" ]; then
    AURORA_SERVICES_URL="https://gitlab.com/AuroraOSS/AuroraServices${AURORA_SERVICES_PATH}"
    check_and_download "$AURORA_SERVICES_URL" "$APK_DIR/AuroraServices.apk" "Aurora Services"
else
    echo "[E] Failed to parse Aurora Services URL from GitLab API!"
    # Try a desperate backup regex just in case
    AURORA_SERVICES_PATH=$(echo "$AURORA_SERVICES_JSON" | sed 's/\\//g' | grep -o '/uploads/[^"()]*\.apk' | head -n 1)
    if [ -n "$AURORA_SERVICES_PATH" ]; then
        AURORA_SERVICES_URL="https://gitlab.com/AuroraOSS/AuroraServices${AURORA_SERVICES_PATH}"
        check_and_download "$AURORA_SERVICES_URL" "$APK_DIR/AuroraServices.apk" "Aurora Services (Backup Regex)" "false"
    fi
fi

# End of Aurora Services block

echo ""
echo "=========================================="
echo "[I] Done. APKs downloaded to $APK_DIR/:"
echo "=========================================="
ls -lh "$APK_DIR"/*.apk 2>/dev/null || echo "[W] No APKs found!"
echo ""
echo "[I] Note: When building, include these required APKs:"
echo "[I]   - com.google.android.gms.apk"
echo "[I]   - com.google.android.gsf.apk"
echo "[I] Then choose a store:"
echo "[I]   - PlayStore.apk"
echo "[I]   OR"
echo "[I]   - com.android.vending-companion.apk (plus optionally AuroraStore.apk)"
