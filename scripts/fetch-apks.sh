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
if [ -n "$GMS_URL" ]; then
    echo "[I] Downloading GmsCore from $GMS_URL"
    curl -L "$GMS_URL" -o "$APK_DIR/com.google.android.gms.apk"
else
    echo "[E] Failed to find GmsCore download URL"
fi

echo ""
echo "[P] Fetching latest microG GsfProxy..."
GSF_URL=$(github_latest_release "microg/GsfProxy" "GsfProxy")
if [ -n "$GSF_URL" ]; then
    echo "[I] Downloading GsfProxy from $GSF_URL"
    curl -L "$GSF_URL" -o "$APK_DIR/com.google.android.gsf.apk"
else
    echo "[E] Failed to find GsfProxy download URL"
fi

echo ""
echo "[P] Fetching microG Companion (FakeStore)..."
COMPANION_URL=$(github_latest_release "microg/GmsCore" "com.android.vending")
if [ -n "$COMPANION_URL" ]; then
    echo "[I] Downloading Companion from $COMPANION_URL"
    curl -L "$COMPANION_URL" -o "$APK_DIR/com.android.vending-companion.apk"
else
    echo "[E] Failed to find Companion download URL"
fi

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
    echo "[I] Downloading Aurora Store from $AURORA_URL"
    curl -L "$AURORA_URL" -o "$APK_DIR/AuroraStore.apk"
else
    echo "[E] Failed to find Aurora Store URL on F-Droid!"
fi

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
