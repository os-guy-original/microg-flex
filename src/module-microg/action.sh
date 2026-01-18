#!/system/bin/sh
MODDIR=${0%/*}
source "$MODDIR/common.sh"

grant_microg_permissions

# Check if Play Store is installed, grant permissions if it exists
if pm list packages | grep -q "^package:com.android.vending$"; then
    grant_playstore_permissions
fi
