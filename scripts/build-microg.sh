#!/bin/sh

apk_dir=apk
src_dir=src
dist_dir=dist
module_dir=module-microg
destination_dir=system/product
suffix=MG

show_help() {
	echo "Usage: $0 [options]"
	echo "Options:"
	echo "  -h          Show this help message"
	echo "  -d <dir>    Specify the destination partition [system|product|system_ext] (default: product)"
	echo "  -s <suffix>  Specify the suffix to add to the directories and APK names (default: MG)"
	echo "  -n          No APKs - build self-downloader version (ignores APKs in apk/ folder)"
	exit 0
}

no_apks=0

while getopts "hd:s:n" opt; do
	case $opt in
		h)
			show_help
			;;
		d)
			case $OPTARG in
				system)
					destination_dir=system
					;;
				product)
					destination_dir=system/product
					;;
				system_ext)
					destination_dir=system/system_ext
					;;
				*)
					echo "[E] Invalid destination partition: $OPTARG"
					show_help
					;;
			esac
			;;
		s)
			suffix="$OPTARG"
			;;
		n)
			no_apks=1
			;;
		*)
			show_help
			;;
	esac
done

echo "[P] Building module microg-flex..."

rm -rf "$module_dir"
mkdir -p "$module_dir"

echo "[P] Checking for APK files..."

if [ "$no_apks" -eq 1 ]; then
	echo "[I] Building self-downloader version (-n flag)"
	apk_count=0
else
	# Check for GmsCore
	if ls "$apk_dir/com.google.android.gms"* 1> /dev/null 2>&1; then
		echo "[I] com.google.android.gms: PRESENT"
	else
		echo "[W] com.google.android.gms: MISSING"
	fi
	
	# Check for GSF
	if ls "$apk_dir/com.google.android.gsf"* 1> /dev/null 2>&1 || ls "$apk_dir/GsfProxy"* 1> /dev/null 2>&1; then
		echo "[I] com.google.android.gsf: PRESENT"
	else
		echo "[W] com.google.android.gsf: MISSING"
	fi
	
	# Check for either Play Store or Companion
	has_playstore=0
	has_companion=0
	has_aurora=0
	
	if ls "$apk_dir/Phonesky"* 1> /dev/null 2>&1 || ls "$apk_dir/PlayStore"* 1> /dev/null 2>&1; then
		echo "[I] Play Store: PRESENT"
		has_playstore=1
	fi
	
	# Companion uses com.android.vending but it's the microG version
	if ls "$apk_dir/com.android.vending"* 1> /dev/null 2>&1; then
		echo "[I] com.android.vending (Companion): PRESENT"
		has_companion=1
	fi
	
	# Check for Aurora Store
	if ls "$apk_dir/AuroraStore"* 1> /dev/null 2>&1; then
		echo "[I] Aurora Store: PRESENT"
		has_aurora=1
	fi
	
	if [ "$has_playstore" -eq 0 ] && [ "$has_companion" -eq 0 ]; then
		echo "[W] No store APK found (Play Store or Companion)"
	fi

	apk_count=$(ls "$apk_dir"/*.apk 2>/dev/null | wc -l)
	if [ "$apk_count" -lt 3 ]; then
		echo "[W] Missing one or more required APKs in $apk_dir/, they will need to be downloaded during installation."
	fi
fi

echo "[P] Setting up module directories..."
gms_dir="$destination_dir/priv-app/GmsCore$suffix"
phonesky_dir="$destination_dir/priv-app/Phonesky$suffix"
gsf_dir="$destination_dir/priv-app/com.google.android.gsf$suffix"
aurora_dir="$destination_dir/app/AuroraStore"
mkdir -p "$module_dir/$gms_dir"
mkdir -p "$module_dir/$phonesky_dir"
mkdir -p "$module_dir/$gsf_dir"
mkdir -p "$module_dir/$aurora_dir"

gms_path="$gms_dir/GmsCore$suffix.apk"
phonesky_path="$phonesky_dir/Phonesky$suffix.apk"
gsf_path="$gsf_dir/com.google.android.gsf$suffix.apk"
aurora_path="$aurora_dir/AuroraStore.apk"

if [ "$apk_count" -ge 3 ]; then
	echo "[P] Copying APKs to module directory..."
	
	# Copy GmsCore
	if ls "$apk_dir/com.google.android.gms"* 1> /dev/null 2>&1; then
		cp "$apk_dir"/com.google.android.gms* "$module_dir/$gms_path"
		echo "[I] Copied GmsCore APK"
	fi
	
	# Copy Store (prefer Play Store if both exist)
	if ls "$apk_dir/Phonesky"* 1> /dev/null 2>&1 || ls "$apk_dir/PlayStore"* 1> /dev/null 2>&1; then
		if ls "$apk_dir/PlayStore"* 1> /dev/null 2>&1; then
			cp "$apk_dir"/PlayStore* "$module_dir/$phonesky_path"
		else
			cp "$apk_dir"/Phonesky* "$module_dir/$phonesky_path"
		fi
		echo "[I] Copied Play Store APK"
	elif ls "$apk_dir/com.android.vending"* 1> /dev/null 2>&1; then
		cp "$apk_dir"/com.android.vending* "$module_dir/$phonesky_path"
		echo "[I] Copied Companion APK"
	fi
	
	# Copy GSF
	if ls "$apk_dir/com.google.android.gsf"* 1> /dev/null 2>&1; then
		cp "$apk_dir"/com.google.android.gsf* "$module_dir/$gsf_path"
		echo "[I] Copied GSF APK"
	elif ls "$apk_dir/GsfProxy"* 1> /dev/null 2>&1; then
		cp "$apk_dir"/GsfProxy* "$module_dir/$gsf_path"
		echo "[I] Copied GsfProxy APK"
	fi

	# Copy Aurora Store if present
	if ls "$apk_dir/AuroraStore"* 1> /dev/null 2>&1; then
		cp "$apk_dir"/AuroraStore* "$module_dir/$aurora_path"
		echo "[I] Copied Aurora Store APK"
	fi

	echo "[P] Extracting libraries..."
	# GmsCore libraries (always extract)
	unzip -q -o "$module_dir/$gms_path" 'lib/*' -d "$module_dir/$gms_dir" 2>/dev/null
	
	# Phonesky libraries (may or may not exist depending on variant)
	unzip -q -o "$module_dir/$phonesky_path" 'lib/*' -d "$module_dir/$phonesky_dir" 2>/dev/null || true

	# Rename architectures
	for dir in "$module_dir/$gms_dir" "$module_dir/$phonesky_dir"; do
		[ -d "$dir/lib/arm64-v8a" ] && mv "$dir/lib/arm64-v8a" "$dir/lib/arm64"
		[ -d "$dir/lib/armeabi-v7a" ] && mv "$dir/lib/armeabi-v7a" "$dir/lib/arm"
		[ -d "$dir/lib/x86_64" ] && mv "$dir/lib/x86_64" "$dir/lib/x64"
		# Clean up any other architectures we don't support explicitly or are empty
		rm -rf "$dir/lib/x86" "$dir/lib/mips" "$dir/lib/mips64" 2>/dev/null || true
	done
fi

echo "[P] Copying module files to module directory..."
cp -r "$src_dir/$module_dir"/* "$module_dir/"
mv "$module_dir/etc" "$module_dir/$destination_dir/"

echo "[P] Patching customize script..."
sed -i "1i aurora_path=$aurora_path" "$module_dir/customize.sh"
sed -i "1i phonesky_path=$phonesky_path" "$module_dir/customize.sh"
sed -i "1i gms_path=$gms_path" "$module_dir/customize.sh"
sed -i "1i gms_dir=$gms_dir" "$module_dir/customize.sh"
sed -i "1i gsf_path=$gsf_path" "$module_dir/customize.sh"

module_version="$(grep '^version=' "$src_dir/$module_dir/module.prop" | cut -d'=' -f2)"
echo "[I] Module version: $module_version"
module_filename="microg-flex-$module_version.zip"

echo "[P] Compressing module archive..."
mkdir -p "$dist_dir"
rm -f "$dist_dir/$module_filename"
cd "$module_dir"
zip -q -r "../$dist_dir/$module_filename" . -x **/.gitkeep
cd - > /dev/null

echo "[I] Module microg-flex built successfully!"
echo "[I] Output: $dist_dir/$module_filename"
