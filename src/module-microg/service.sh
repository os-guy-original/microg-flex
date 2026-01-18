#!/system/bin/sh
# service.sh - Runs after boot is completed

MODDIR=${0%/*}
source "$MODDIR/common.sh"

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
