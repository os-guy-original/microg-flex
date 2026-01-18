#!/bin/sh

# Build and install microg-flex module via ADB

echo "[P] Building microg-flex module..."
./scripts/build-microg.sh || exit 1

module_version="$(grep '^version=' src/module-microg/module.prop | cut -d'=' -f2)"
module_filename="microg-flex-$module_version.zip"

echo "[P] Checking for connected device..."
if ! adb devices | grep -q "device$"; then
	echo "[E] No device connected via ADB!"
	echo "[E] Please connect your device and enable USB debugging."
	exit 1
fi

echo "[I] Device found!"
echo "[P] Pushing module to device..."
adb push "dist/$module_filename" "/sdcard/$module_filename" || exit 1

echo "[I] Module pushed successfully!"
echo "[I] Now install the module from your root manager:"
echo "[I] - Magisk: Modules > Install from storage > /sdcard/$module_filename"
echo "[I] - KernelSU: Modules > Install from storage > /sdcard/$module_filename"
