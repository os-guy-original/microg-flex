#!/system/bin/sh
# post-fs-data.sh - Runs early in boot before zygote starts
# Ensures correct permissions on module files

MODDIR=${0%/*}

# Set correct permissions on APK files and directories
for dir in "$MODDIR/system" "$MODDIR/system/product" "$MODDIR/system/product/priv-app" \
           "$MODDIR/system/product/priv-app/GmsCoreMG" "$MODDIR/system/product/priv-app/PhoneskyMG" \
           "$MODDIR/system/product/priv-app/com.google.android.gsfMG" \
           "$MODDIR/system/product/etc" "$MODDIR/system/product/etc/permissions" \
           "$MODDIR/system/product/etc/default-permissions" "$MODDIR/system/product/etc/sysconfig"; do
    [ -d "$dir" ] && chmod 755 "$dir" && chown root:root "$dir"
done

for apk in "$MODDIR/system/product/priv-app/GmsCoreMG/GmsCoreMG.apk" \
           "$MODDIR/system/product/priv-app/PhoneskyMG/PhoneskyMG.apk" \
           "$MODDIR/system/product/priv-app/com.google.android.gsfMG/com.google.android.gsfMG.apk"; do
    [ -f "$apk" ] && chmod 644 "$apk" && chown root:root "$apk"
done

for xml in "$MODDIR/system/product/etc/permissions"/*.xml \
           "$MODDIR/system/product/etc/default-permissions"/*.xml \
           "$MODDIR/system/product/etc/sysconfig"/*.xml; do
    [ -f "$xml" ] && chmod 644 "$xml" && chown root:root "$xml"
done
