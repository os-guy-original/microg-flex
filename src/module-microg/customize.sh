source "$MODPATH/common.sh"

#########################
# User Confirmation
#########################

ui_print ""
ui_print "*******************************"
ui_print " microG Flex"
ui_print "*******************************"
ui_print ""
ui_print "Welcome! This flexible installer lets you choose:"
ui_print "- Google Play Store (recommended)"
ui_print "- microG Companion (FakeStore)"
ui_print "- microG Companion + Aurora Store"
ui_print ""
ui_print "[?] Ready to start the installation?"
ui_print "[?] (Vol+ = Yes, Vol- = No)"

if ! chooseport; then
	ui_print ""
	ui_print "[-] Installation cancelled. See you next time!"
	abort
fi

ui_print ""
ui_print "[I] Awesome! Let's get going..."
ui_print ""

#########################
# Variant Selection
#########################

ui_print "================================================"
ui_print "[?] Which store do you want to use?"
ui_print "================================================"
ui_print ""
ui_print "  [1] Google Play Store (Vol+)"
ui_print "      - The official Store"
ui_print "      - Best app compatibility"
ui_print "      - (Note: May need Play Integrity Fix)"
ui_print ""
ui_print "  [2] microG Companion / FakeStore (Vol-)"
ui_print "      - Open source dummy store"
ui_print "      - Minimal, privacy-focused"
ui_print "      - You can choose Aurora Store later"
ui_print ""
ui_print "================================================"
ui_print "[?] Vol+ for Play Store, Vol- for Companion"
ui_print "================================================"

if chooseport; then
	STORE_VARIANT="playstore"
	INSTALL_AURORA="no"
	ui_print ""
	ui_print "[I] ✓ You picked: Google Play Store"
	ui_print ""
else
	STORE_VARIANT="companion"
	ui_print ""
	ui_print "[I] ✓ You picked: microG Companion"
	ui_print ""
	
	# Ask about Aurora Store
	ui_print "================================================"
	ui_print "[?] Want to add Aurora Store?"
	ui_print "================================================"
	ui_print ""
	ui_print "Aurora Store is an excellent open-source client"
	ui_print "allows you to download apps from Google Play."
	ui_print ""
	ui_print "[?] Install Aurora Store? (Vol+ = Yes, Vol- = No)"
	ui_print "================================================"
	
	if chooseport; then
		INSTALL_AURORA="yes"
		ui_print ""
		ui_print "[I] ✓ Aurora Store will be installed"
		ui_print ""
	else
		INSTALL_AURORA="no"
		ui_print ""
		ui_print "[I] ✓ Companion only (no Aurora Store)"
		ui_print ""
	fi
fi

#########################
# Check Dependencies
#########################

check_dependency() {
  local cmd=$1
  local name=$2
  
  if ! command -v "$cmd" >/dev/null 2>&1; then
    ui_print "[E] Missing dependency: $name ($cmd)"
    return 1
  fi
  return 0
}

ui_print "[P] Checking dependencies..."
MISSING_DEPS=0

check_dependency "unzip" "unzip" || MISSING_DEPS=1
check_dependency "curl" "curl" || MISSING_DEPS=1
check_dependency "grep" "grep" || MISSING_DEPS=1
check_dependency "sed" "sed" || MISSING_DEPS=1
check_dependency "cut" "cut" || MISSING_DEPS=1
check_dependency "find" "find" || MISSING_DEPS=1
check_dependency "mknod" "mknod" || MISSING_DEPS=1

if [ "$MISSING_DEPS" -eq 1 ]; then
  ui_print "[E] Missing required dependencies!"
  ui_print "[E] Installation cannot continue."
  abort
fi

ui_print "[I] All dependencies found!"
ui_print ""

#########################
# Check for KernelSU/KernelSU-Next Metamodule
#########################

# KernelSU/KernelSU-Next requires meta-overlayfs to mount system modifications
# Magisk handles this natively, so we only check for KernelSU
if [ -n "$KSU" ] || [ -d "/data/adb/ksu" ]; then
	METAMODULE_FOUND=0
	MODULE_PATHS="/data/adb/modules /data/adb/ksu/modules /data/adb/modules_update"

	for mod_path in $MODULE_PATHS; do
		if [ -d "$mod_path" ]; then
			for meta in "meta_overlayfs" "meta-overlayfs" "zygisk_lsposed"; do
				meta_dir="$mod_path/$meta"
				if [ -d "$meta_dir" ] && [ ! -f "$meta_dir/disable" ] && [ ! -f "$meta_dir/remove" ]; then
					METAMODULE_FOUND=1
					ui_print "[I] Overlay module found: $meta"
					break 2
				fi
			done
		fi
	done

	if [ "$METAMODULE_FOUND" -eq 0 ]; then
		ui_print ""
		ui_print "[!] ============================================"
		ui_print "[!] WARNING: meta-overlayfs not detected!"
		ui_print "[!] ============================================"
		ui_print "[!] KernelSU/KernelSU-Next requires meta-overlayfs"
		ui_print "[!] to mount system modifications properly."
		ui_print "[!] Without it, apps will NOT work!"
		ui_print "[!] ============================================"
		ui_print "[!] Install meta-overlayfs from:"
		ui_print "[!] https://github.com/KernelSU-Modules-Repo/meta-overlayfs"
		ui_print "[!] ============================================"
		ui_print ""
	fi
fi

check_and_download_apks() {
	if [ ! -f "$MODPATH/$gms_path" ] || [ ! -f "$MODPATH/$phonesky_path" ] || [ ! -f "$MODPATH/$gsf_path" ]; then
		ui_print
		ui_print "[!] It looks like some required files are missing."
		ui_print "[?] Should I download them now? (Vol+ = Yes, Vol- = No)"
		ui_print "    (You'll need an internet connection for this)"

		if chooseport; then
			# Check for curl before attempting download
			check_curl
			
			ui_print "[I] Checking for updates..."
			
			# Fetch latest entry (potential prerelease)
			latest_entry_json=$(fetch_url_content "https://api.github.com/repos/microg/GmsCore/releases?per_page=1")
			check_rate_limit "$latest_entry_json"
			
			# Check for prerelease
			if echo "$latest_entry_json" | grep -q "\"prerelease\": true"; then
				pre_ver=$(echo "$latest_entry_json" | grep "\"tag_name\":" | head -n 1 | cut -d '"' -f 4)
				
				# Fetch stable for comparison
				stable_json=$(fetch_url_content "https://api.github.com/repos/microg/GmsCore/releases/latest")
				stable_ver=$(echo "$stable_json" | grep "\"tag_name\":" | head -n 1 | cut -d '"' -f 4)
				
				ui_print ""
				ui_print "[!] Found a prerelease version: $pre_ver"
				ui_print "[I] Latest Stable version:    $stable_ver"
				ui_print "[?] Do you want to try the prerelease? (Vol+ = Yes, Vol- = No)"
				
				if chooseport; then
					ui_print "[I] Okay, downloading prerelease $pre_ver..."
					release_json="$latest_entry_json"
				else
					ui_print "[I] Sticking with stable version $stable_ver..."
					release_json="$stable_json"
				fi
			else
				ui_print "[I] Fetching latest stable version..."
				release_json=$(fetch_url_content "https://api.github.com/repos/microg/GmsCore/releases/latest")
			fi

			gsf_release_json=$(fetch_url_content "https://api.github.com/repos/microg/GsfProxy/releases/latest")
			
			# Extract download URLs using grep and sed since jq might not be available
			gms_url=$(echo "$release_json" | grep "browser_download_url" | grep "com.google.android.gms" | grep -v "\-hw" | cut -d '"' -f 4 | head -n 1)
			gsf_url=$(echo "$gsf_release_json" | grep "browser_download_url" | grep "GsfProxy" | cut -d '"' -f 4 | head -n 1)

			# Variant-specific Phonesky download
			if [ "$STORE_VARIANT" = "playstore" ]; then
				vending_url="http://bnsmb.de/files/public/Android/PlayStore_for_MicroG_41.1.19-31-v1.0.0.zip"
				vending_name="Play Store"
			else
				vending_url=$(echo "$release_json" | grep "browser_download_url" | grep "com.android.vending" | grep -v "\-hw" | cut -d '"' -f 4 | head -n 1)
				vending_name="microG Companion"
			fi

			if [ -z "$gms_url" ] || [ -z "$vending_url" ] || [ -z "$gsf_url" ]; then
				ui_print "[E] Couldn't find the download links!"
				abort
			fi

			download_file "$gms_url" "$MODPATH/$gms_path" "microG Services" "true"
			
			if [ "$STORE_VARIANT" = "playstore" ]; then
				# Play Store comes in a ZIP, need to extract
				vending_zip="$MODPATH/vending.zip"
				download_file "$vending_url" "$vending_zip" "$vending_name" "true"

				if [ -f "$vending_zip" ]; then
					ui_print "[I] Unzipping Play Store..."
					# Find the APK in the ZIP (usually in system/product/priv-app/Phonesky/Phonesky.apk)
					unzip -o "$vending_zip" "system/product/priv-app/Phonesky/Phonesky.apk" -d "$MODPATH/vending_tmp" >/dev/null 2>&1
					if [ -f "$MODPATH/vending_tmp/system/product/priv-app/Phonesky/Phonesky.apk" ]; then
						mv "$MODPATH/vending_tmp/system/product/priv-app/Phonesky/Phonesky.apk" "$MODPATH/$phonesky_path"
					else
						# Fallback search if path is different
						apk_internal_path=$(unzip -l "$vending_zip" | grep "\.apk$" | awk '{print $NF}' | head -n 1)
						if [ -n "$apk_internal_path" ]; then
							unzip -o "$vending_zip" "$apk_internal_path" -d "$MODPATH/vending_tmp" >/dev/null 2>&1
							mv "$MODPATH/vending_tmp/$apk_internal_path" "$MODPATH/$phonesky_path"
						fi
					fi
					rm -rf "$MODPATH/vending_tmp"
					rm -f "$vending_zip"
				fi
			else
				# Companion is a direct APK download
				download_file "$vending_url" "$MODPATH/$phonesky_path" "$vending_name" "true"
			fi

			download_file "$gsf_url" "$MODPATH/$gsf_path" "Services Framework Proxy" "true"

			# Download Aurora Store if requested
			if [ "$INSTALL_AURORA" = "yes" ]; then
				ui_print "[I] Downloading Aurora Store..."
				ui_print "    (Grabbing from F-Droid)"
				
				# Fetch F-Droid page to get latest APK link
				ui_print "[I] Checking F-Droid for latest version..."
				fdroid_page=$(fetch_url_content "https://f-droid.org/en/packages/com.aurora.store/")
				aurora_url=$(echo "$fdroid_page" | grep -o 'https://f-droid.org/repo/com.aurora.store_[0-9]*\.apk' | head -n 1)
				
				if [ -n "$aurora_url" ]; then
					ui_print "    $aurora_url"
					# Pass false for critical flag (optional download)
					if download_file "$aurora_url" "$MODPATH/$aurora_path" "Aurora Store" "false"; then
						ui_print "[I] Aurora Store is ready!"
					else
						ui_print "[W] Couldn't grab Aurora Store. Skipping it."
						INSTALL_AURORA="no"
					fi
				else
					ui_print "[W] Weird, I couldn't find Aurora Store on F-Droid."
					INSTALL_AURORA="no"
				fi
			fi

			if [ ! -f "$MODPATH/$gms_path" ] || [ ! -f "$MODPATH/$phonesky_path" ] || [ ! -f "$MODPATH/$gsf_path" ]; then
				ui_print "[E] Downloads failed to save to disk."
				abort
			fi
			
			ui_print "[I] All downloads finished!"
		else
			ui_print "[-] Installation stopped."
			abort
		fi
	fi
}


# Check for unzip before extracting libraries
check_unzip() {
	if ! command -v unzip >/dev/null 2>&1; then
		ui_print "[E] unzip is not available!"
		ui_print "[E] Cannot extract libraries without unzip."
		abort
	fi
}

check_and_download_apks

# Set APK permissions and SELinux contexts
ui_print "[P] Setting APK permissions..."

set_apk_permissions "$gms_path" "GmsCore"

if [ "$STORE_VARIANT" = "playstore" ]; then
	set_apk_permissions "$phonesky_path" "Play Store"
else
	set_apk_permissions "$phonesky_path" "microG Companion"
fi

set_apk_permissions "$gsf_path" "Services Framework Proxy"

[ "$INSTALL_AURORA" = "yes" ] && set_apk_permissions "$aurora_path" "Aurora Store"

# Set permissions on entire system directory tree
ui_print "[P] Setting system directory permissions..."
set_perm_recursive "$MODPATH/system" 0 0 0755 0644

remove_package_updates google

echo
echo "[P] Processing files to remove..."
echo "-------------------------------------------"
echo "[M] FILE/DIR                         STATUS"
echo "-------------------------------------------"
for file in $remove_files; do
	# Remove leading slash to avoid double slashes with $MODPATH
	file_path="${file#/}"
	target_path="$MODPATH/$file_path"
	# Create parent directory if it doesn't exist
	target_dir=$(dirname "$target_path")
	mkdir -p "$target_dir" 2>/dev/null
	printf "%-40s %s\n" "[I] .../$(basename "$file")" "OK"
	mknod "$target_path" c 0 0 2>/dev/null || {
		# If mknod fails, try creating an empty file as fallback
		touch "$target_path" 2>/dev/null || true
	}
done
echo "-------------------------------------------"
echo '[I] Done processing files.'



echo
echo "[P] Extracting libraries..."
# Check for unzip before extracting
check_unzip

# GmsCore libraries (always extract)
unzip -q -o "$MODPATH/$gms_path" 'lib/*' -d "$MODPATH/$gms_dir" 2>/dev/null || {
	ui_print "[W] Failed to extract libraries from GmsCore APK"
}

# Play Store libraries (only if Play Store variant)
if [ "$STORE_VARIANT" = "playstore" ]; then
	phonesky_dir=$(dirname "$phonesky_path")
	unzip -q -o "$MODPATH/$phonesky_path" 'lib/*' -d "$MODPATH/$phonesky_dir" 2>/dev/null || {
		ui_print "[W] Failed to extract libraries from Play Store APK"
	}
fi

# Rename architecture directories if they exist
for dir in "$MODPATH/$gms_dir" "$MODPATH/$phonesky_dir"; do
	[ -d "$dir/lib/arm64-v8a" ] && mv "$dir/lib/arm64-v8a" "$dir/lib/arm64" 2>/dev/null || true
	[ -d "$dir/lib/armeabi-v7a" ] && mv "$dir/lib/armeabi-v7a" "$dir/lib/arm" 2>/dev/null || true
	# x86 stays as x86 (no rename needed)
	[ -d "$dir/lib/x86_64" ] && mv "$dir/lib/x86_64" "$dir/lib/x64" 2>/dev/null || true
done

echo "-------------------------------------------"
echo "[M] FILE                             STATUS"
echo "-------------------------------------------"
for dir in "$MODPATH/$gms_dir" "$MODPATH/$phonesky_dir"; do
	if [ -d "$dir/lib/$ARCH" ]; then
		for file in $(find "$dir/lib/$ARCH" -type f 2>/dev/null); do
			[ -f "$file" ] && printf "%-40s %s\n" "[I] $(basename $file)" "OK"
		done
	else
		# Only warn if it's the GmsCore dir or Play Store variant
		if [ "$dir" = "$MODPATH/$gms_dir" ] || [ "$STORE_VARIANT" = "playstore" ]; then
			ui_print "[W] No libraries found in $(basename $dir) for architecture $ARCH"
		fi
	fi
done
echo "-------------------------------------------"
echo '[I] Done extracting libraries.'
echo
echo "============================================"
echo "[W] If this is fresh installation (not update),"
echo "after reboot, click Action to grant permissions."
echo "============================================"

# Final verification that APKs are in place
ui_print ""
ui_print "[P] Verifying APK installation..."
if [ -f "$MODPATH/$gms_path" ] && [ -f "$MODPATH/$phonesky_path" ] && [ -f "$MODPATH/$gsf_path" ]; then
	ui_print "[I] APKs are in place."
	ui_print ""
	ui_print "[I] ============================================"
	ui_print "[I] Installation Summary:"
	ui_print "[I] - microG Services: Installed"
	ui_print "[I] - GSF Proxy: Installed"
	if [ "$STORE_VARIANT" = "playstore" ]; then
		ui_print "[I] - Google Play Store: Installed"
	else
		ui_print "[I] - microG Companion: Installed"
		if [ "$INSTALL_AURORA" = "yes" ]; then
			if [ -f "$MODPATH/$aurora_path" ]; then
				ui_print "[I] - Aurora Store: Installed"
			else
				ui_print "[W] - Aurora Store: Download failed"
			fi
		fi
	fi
	ui_print "[I] ============================================"
	ui_print "[I] After reboot:"
	ui_print "[I] - Click Action button to grant permissions"
	ui_print "[I] - Or open microG Settings > Self-Check"
	if [ "$STORE_VARIANT" = "playstore" ]; then
		ui_print "[I] - Update Play Store from its settings"
	fi
	ui_print "[I] ============================================"
else
	ui_print "[E] APKs are missing! Installation may have failed."
fi
ui_print ""
