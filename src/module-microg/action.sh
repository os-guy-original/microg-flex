#!/system/bin/sh
MODDIR=${0%/*}
source "$MODDIR/common.sh"

grant_microg_permissions

# Check if Play Store or Aurora Services are installed, grant permissions if they exist
if pm list packages | grep -q "^package:com.android.vending$"; then
    grant_playstore_permissions
fi

if [ "$(pm list packages | grep -q '^package:com.aurora.services$'; echo $?)" -eq 0 ]; then
    grant_aurora_services_permissions
fi

if [ "$(pm list packages | grep -q '^package:com.aurora.store$'; echo $?)" -eq 0 ]; then
    grant_aurora_store_permissions
fi
