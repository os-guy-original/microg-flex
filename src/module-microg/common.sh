# Normalize MODPATH/MODDIR
if [ -z "$MODPATH" ] && [ -n "$MODDIR" ]; then
	MODPATH="$MODDIR"
fi

# Fallback for ui_print if not defined
if ! command -v ui_print >/dev/null 2>&1; then
	ui_print() {
		echo "$1"
	}
fi

# Default APK paths (may be overridden by customize.sh injection)
gms_dir="${gms_dir:-system/product/priv-app/GmsCoreMG}"
gms_path="${gms_path:-system/product/priv-app/GmsCoreMG/GmsCoreMG.apk}"
phonesky_path="${phonesky_path:-system/product/priv-app/PhoneskyMG/PhoneskyMG.apk}"
gsf_path="${gsf_path:-system/product/priv-app/com.google.android.gsfMG/com.google.android.gsfMG.apk}"
aurora_path="${aurora_path:-system/product/app/AuroraStore/AuroraStore.apk}"

#########################
# Helper Functions
#########################

# Volume key detection
chooseport() {
	# Keycheck binary by someone755 @Github, idea by zackptg5 @xda
	if [ -f "$MODPATH/keycheck" ]; then
		chmod 755 "$MODPATH/keycheck"
		"$MODPATH/keycheck" > /dev/null 2>&1
		"$MODPATH/keycheck"
		SEL=$?
		[ "$SEL" -eq 42 ] && return 0
		[ "$SEL" -eq 41 ] && return 1
	fi

	# Fallback to getevent
	[ -z "$TMPDIR" ] && TMPDIR="/dev/tmp"
	mkdir -p "$TMPDIR" 2>/dev/null
	while true; do
		/system/bin/getevent -lqc 1 2>/dev/null | /system/bin/grep KEY_VOLUME > "$TMPDIR/events" 2>/dev/null
		if [ -f "$TMPDIR/events" ] && /system/bin/grep -q KEY_VOLUMEUP "$TMPDIR/events" 2>/dev/null; then
			return 0
		elif [ -f "$TMPDIR/events" ] && /system/bin/grep -q KEY_VOLUMEDOWN "$TMPDIR/events" 2>/dev/null; then
			return 1
		fi
	done
}

# Set APK permissions and SELinux contexts
set_apk_permissions() {
	local apk_path="$1"
	local apk_name="$2"
	
	if [ -f "$MODPATH/$apk_path" ]; then
		chmod 644 "$MODPATH/$apk_path" 2>/dev/null || true
		chown root:root "$MODPATH/$apk_path" 2>/dev/null || true
		chcon u:object_r:system_file:s0 "$MODPATH/$apk_path" 2>/dev/null || true
		
		local apk_dir=$(dirname "$MODPATH/$apk_path")
		chmod 755 "$apk_dir" 2>/dev/null || true
		chown root:root "$apk_dir" 2>/dev/null || true
		chcon u:object_r:system_file:s0 "$apk_dir" 2>/dev/null || true
		
		ui_print "[I] $apk_name APK permissions set"
		return 0
	fi
	return 1
}

# Check if curl is available
check_curl() {
	if ! command -v curl >/dev/null 2>&1; then
		ui_print "[E] curl is not available!"
		ui_print "[E] Cannot download APKs without curl."
		abort
	fi
}

# Check GitHub API rate limit
check_rate_limit() {
	local response="$1"
	if echo "$response" | grep -q "API rate limit exceeded"; then
		ui_print ""
		ui_print "[E] GitHub API rate limit exceeded!"
		ui_print "[E] You have reached the limit of anonymous requests."
		ui_print "[E] Please wait a hour and try again."
		ui_print ""
		ui_print "[-] Installation cancelled."
		abort
	fi
}

# Robust download function with retry logic
download_file() {
	local url="$1"
	local out_path="$2"
	local description="$3"
	local critical="$4"
	
	while true; do
		ui_print "[I] Downloading $description..."
		ui_print "    $url"
		
		# Use curl with failure flag (-f), location (-L), silent but show errors (-sS)
		# and insecure (-k) for compatibility
		curl -f -L -k -sS -o "$out_path" "$url" 2>/proc/self/fd/$OUTFD
		local exit_code=$?
		
		if [ $exit_code -eq 0 ] && [ -f "$out_path" ]; then
			ui_print "[I] Got it!"
			return 0
		else
			ui_print "[E] Oops, download failed! (Code: $exit_code)"
			
			if [ "$critical" = "true" ]; then
				ui_print "[?] Try again? (Vol+ = Yes, Vol- = Cancel)"
			else
				ui_print "[?] Try again? (Vol+ = Yes, Vol- = Skip)"
			fi
			
			if chooseport; then
				ui_print "[I] Okay, trying again..."
				continue
			else
				if [ "$critical" = "true" ]; then
					ui_print "[-] Cancelled by request."
					rm -f "$out_path"
					abort
				else
					ui_print "[I] Skipping."
					rm -f "$out_path"
					return 1
				fi
			fi
		fi
	done
}

# Fetch content from URL (to stdout) because download_file writes to file
fetch_url_content() {
	local url="$1"
	# Use same robust flags but no output file
	# -sS: Silent but show errors
	# -L: Follow redirects
	# -k: Insecure (for compatibility)
	curl -s -L -k "$url" 2>/proc/self/fd/$OUTFD
}

remove_files="
/system/product/priv-app/GmsCore
/system/product/priv-app/PrebuiltGmsCore
/system/product/priv-app/GoogleServicesFramework
/system/product/priv-app/Phonesky
/system/system_ext/priv-app/GoogleServicesFramework
/system/product/etc/permissions/split-permissions-google.xml
"

remove_package_updates() {
	filter=${1}
	echo "[P] Checking package updates..."
	echo "-------------------------------------------"
	echo "[M] PACKAGE WITH UPDATE                TYPE"
	echo "-------------------------------------------"
	packages="com.google.android.gms com.android.vending com.google.android.gsf"
	for package in $packages; do
		# Check if package update from Google version is installed
		path=$(pm path "$package" | grep "/data/app/" | sed -E 's/package:(\/data\/app\/[^/]+).*/\1/' | uniq)
		microg_type=$(pm dump "$package" | grep -q 'FAKE_PACKAGE_SIGNATURE' && echo "true" || echo "false")
		if [ -n "$path" ]; then
			if [ "$microg_type" = "true" ]; then
				if [ "$filter" = "google" ]; then
					printf "%-32s %s\n" "[I] $package" "MICROG, OK"
				else
					printf "%-36s %s\n" "[W] $package" "MICROG"
				fi
			else
				printf "%-36s %s\n" "[W] $package" "GOOGLE"
			fi

			if [ "$filter" != "google" ] || [ "$microg_type" != "true" ]; then
				echo -n "|-[P] Removing package update...    "
				# Remove package update without uninstalling the app
				pm uninstall -k --user all "$package"
			fi
		else
			printf "%-29s %s\n" "[I] $package" "NOT FOUND, OK"
		fi
	done
	echo "-------------------------------------------"
	echo "[I] Done checking package updates."
}

grant_pkg_permissions() {
	local package=$1
	shift
	local permissions="$@"
	echo "[P] Checking permissions for $package..."
	echo "-------------------------------------------"
	echo "[M] PERMISSION                       STATUS"
	echo "-------------------------------------------"

	local warn=""

	# Cache dumpsys output to avoid multiple calls and broken pipes
	local dump_output=$(dumpsys package "$package" 2>/dev/null)

	for perm in $permissions; do
		if echo "$dump_output" | grep -q "android.permission.$perm: granted=true"; then
			printf "%-35s %s\n" "[I] $perm" "GRANTED"
		else
			printf "%-31s %s\n" "[W] $perm" "NOT GRANTED"
			echo -n "|-[P] Granting...                   "
			if pm grant "$package" "android.permission.$perm" >/dev/null 2>&1; then
				echo "SUCCESS"
			else
				echo " FAILED"
				warn="true"
			fi
		fi
	done
	echo "-------------------------------------------"
	
	if [ "$warn" ]; then
		echo "[W] Some permissions were not granted."
	else
		echo "[I] All permissions granted for $package!"
	fi
}

grant_microg_permissions() {
	local permissions="ACCESS_COARSE_LOCATION ACCESS_FINE_LOCATION ACCESS_BACKGROUND_LOCATION READ_EXTERNAL_STORAGE WRITE_EXTERNAL_STORAGE GET_ACCOUNTS POST_NOTIFICATIONS READ_PHONE_STATE RECEIVE_SMS SYSTEM_ALERT_WINDOW"
	grant_pkg_permissions "com.google.android.gms" $permissions
}

grant_playstore_permissions() {
	local permissions="ACCESS_COARSE_LOCATION ACCESS_FINE_LOCATION POST_NOTIFICATIONS READ_PHONE_STATE GET_ACCOUNTS"
	grant_pkg_permissions "com.android.vending" $permissions
}
