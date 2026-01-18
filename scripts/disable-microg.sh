#!/bin/sh

# Disable microg-flex module via ADB in case of bootloop

echo "[P] Disabling microg-flex module..."
echo "[P] Checking for connected device..."

if ! adb devices | grep -q "device$"; then
	echo "[E] No device connected via ADB!"
	echo "[E] Please connect your device and enable USB debugging."
	echo "[E] If you're in a bootloop, you may need to use recovery mode."
	exit 1
fi

echo "[I] Device found!"
echo "[P] Creating disable file..."

# Try different possible module locations
adb shell "su -c 'touch /data/adb/modules/microg-flex/disable'" 2>/dev/null && \
	echo "[I] Disabled microg-flex in /data/adb/modules" && \
	echo "[I] Rebooting device..." && \
	adb shell "su -c 'reboot'" && \
	exit 0

echo "[W] Module not found in standard location"
echo "[W] Trying legacy module IDs..."

# Try legacy IDs
for module_id in "microg-w-play" "noogle-microg"; do
	if adb shell "su -c 'test -d /data/adb/modules/$module_id && echo exists'" | grep -q "exists"; then
		echo "[I] Found $module_id, disabling..."
		adb shell "su -c 'touch /data/adb/modules/$module_id/disable'"
		echo "[I] Disabled $module_id"
		echo "[I] Rebooting device..."
		adb shell "su -c 'reboot'"
		exit 0
	fi
done

echo "[E] Could not find microg-flex or legacy modules"
echo "[E] You may need to disable modules manually in recovery or safe mode"
exit 1
