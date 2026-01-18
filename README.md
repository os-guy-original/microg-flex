<p align="center">
  <img src="assets/microg-flex.png" alt="microG Flex Logo" width="256">
</p>

# microG Flex

**Flexible Magisk/KernelSU module for microG Services - Choose your store during installation!**

## What is microG Flex?

microG Flex is a modular installer that replaces Google Services with microG on stock Android 11-16. During installation, you can choose between:

- **Google Play Store** - Official store with better app compatibility
- **microG Companion** - Minimal stub library (required for microG)
- **microG Companion + Aurora Store** - Adds a full-featured FOSS app store

## Supported Root Solutions

- **Magisk** (v20.4+)
- **KernelSU**
- **KernelSU-Next**

> **Note for KernelSU/KernelSU-Next users:** You must install [meta-overlayfs](https://github.com/KernelSU-Modules-Repo/meta-overlayfs) for the module to work properly.

## Features

- **Flexible Store Selection**: Choose between Play Store or Companion during installation
- **microG Services**: Replaces Google Services with microG GmsCore
- **GSF Proxy**: Replaces Google Services Framework with microG GsfProxy
- **Works on Stock ROMs**: Designed for stock Android; replaces existing Google apps without manual removal

## Installation Tutorial

### For Users (Easy Method)

**Recommended for most users.**

1. **Download the Module**: Get the latest `.zip` file from the [Releases page](https://github.com/os-guy-original/microg-flex/releases).

2. **Install the Module**:
   - **Magisk**: Open Magisk app → Modules → Install from Storage
   - **KernelSU/KernelSU-Next**: First install [meta-overlayfs](https://github.com/KernelSU-Modules-Repo/meta-overlayfs), then install this module

3. **Interactive Installation**:
   - **Initial Confirmation**: Press **Volume Up** to continue installation
   - **Store Variant Selection**:
     - Press **Volume Up** for Google Play Store (recommended for most users)
     - Press **Volume Down** for microG Companion (privacy-focused alternative)
   - **APK Download** (if needed): Press **Volume Up** to download missing files automatically
     - *Note: Requires an active internet connection*

4. **Reboot**: Restart your device.

5. **Grant Permissions**:
   - After reboot, open your root manager and click the **Action** button on the **microG Flex** module
   - Alternatively, open the microG Settings app, go to **Self-Check**, and tap the permission boxes to grant them

6. **Verify Permissions**:
   - Open microG Settings → **Self-Check**
   - Ensure all checkboxes are ticked
   - If "Signature Spoofing" is unchecked, see the [Troubleshooting](#troubleshooting) section

7. **Update Play Store** (Play Store variant only):
   - Open Play Store → **Settings**
   - Click on **About** → **Update Play Store**

### For Builders (Advanced Method)

**For developers or those who want to compile it themselves.**

1. **Prepare Environment**:
   - Use Linux, macOS, or WSL (Windows)
   - Install dependencies: `zip`, `curl`, `unzip`
     
     ```bash
     sudo apt install zip curl unzip  # Debian/Ubuntu
     ```

2. **Clone Repository**:
   
   ```bash
   git clone https://github.com/os-guy-original/microg-flex.git
   cd microg-flex
   ```

3. **(Optional) Pre-download APKs**:
   - You can use the fetcher script to pre-download all variants into the `apk/` folder:
     
     ```bash
     ./scripts/fetch-apks.sh
     ```
   - **Note**: Include only 3 APKs when building:
     - `com.google.android.gms.apk` (required)
     - `com.google.android.gsf.apk` (required)
     - *Either* `PlayStore.apk` *or* `com.android.vending-companion.apk`
     - *Optional:* `AuroraStore.apk` (if using Companion variant)
   - If APKs are missing, they'll be downloaded during installation on your phone

4. **Build**:
   
   ```bash
   ./scripts/build-microg.sh
   ```
   - The flashable zip will be created in the `dist/` folder
   - To build without bundled APKs (self-downloader): `./scripts/build-microg.sh -n`

5. **Install**:
   - Transfer the zip to your phone or use the helper script to build & install via ADB:
     
     ```bash
     ./scripts/install-microg.sh
     ```

## Tested Configurations

| Module/Type        | Notes                                                            |
|:------------------ | ---------------------------------------------------------------- |
| LSPosed + FakeGApps | Both official and from JingMatrix (for signature spoofing)      |
| Play Integrity Fix | Works with both variants; Play Store variant recommended         |
| User updates       | Play Store: self-updates; Companion: updates from F-Droid        |

## Tutorial: How To Get BASIC_INTEGRITY

To pass at least **BASIC_INTEGRITY**, you need to install these modules:

1. **[Tricky Store OSS](https://github.com/beakthoven/TrickyStoreOSS)**
2. **[TrickyAddon](https://github.com/KOWX712/Tricky-Addon-Update-List)**
3. **[PIF (Fork)](https://github.com/osm0sis/PlayIntegrityFork)**

After installing these modules:

1. Open the PIF module and run the **Action** script
2. Open Tricky Store:
   - Tap the 3 dots (top-right)
   - Select all → Deselect Unnecessary → Keybox → Valid
   - Set Security Patch → Get Security Patch Date → Save
   - Save everything using the bottom-right Save button

### Spoofing Bootloader Status

1. Download **[Key Attestation](https://github.com/vvb2060/KeyAttestation)** app
2. Open the app and find the **verifiedBootHash** string
3. Copy the hash value
4. Open Tricky Store:
   - Tap the 3 dots
   - Ensure necessary apps are selected
   - Set Verified Boot Hash → Paste the hash
   - Save everything

## Troubleshooting

### Signatures are not correct

In order for microG apps to have the correct signatures visible by Android, your ROM must allow for [signature spoofing](https://github.com/microg/GmsCore/wiki/Signature-Spoofing). If it does not (like any stock Android), follow these steps:

1. Enable Zygisk in Magisk's settings (or use Zygisk-Next for KernelSU)
2. Download and install LSPosed through your root manager:
   - [JingMatrix fork](https://github.com/JingMatrix/LSPosed/releases) - up to Android 16 (maintained)
   - [Official version](https://github.com/LSPosed/LSPosed/releases) - up to Android 14 (not maintained)
3. Download and install [FakeGApps](https://github.com/whew-inc/FakeGApps/releases) APK
4. Reboot and enable FakeGapps in LSPosed (select System Framework only)
5. Reboot and check microG Self-Check

### Apps not appearing (KernelSU/KernelSU-Next)

If you're using KernelSU or KernelSU-Next and the apps don't appear:

1. Make sure [meta-overlayfs](https://github.com/KernelSU-Modules-Repo/meta-overlayfs) is installed and enabled
2. Reboot your device
3. If still not working, check that meta-overlayfs doesn't have a `disable` file in its module folder

### microG crashing

If you want to use other modules interacting with microG (like Play Integrity Fix), it's recommended to install both microG Services and microG Companion from the [official GitHub releases](https://github.com/microg/GmsCore/releases) or add the [microG Repository](https://microg.org/fdroid/repo/) to your F-Droid client.

**Note**: Modules like [bindhosts](https://github.com/bindhosts/bindhosts) are known to crash microG.

### Bootloop

If you encounter a bootloop and have ADB enabled, run:

```bash
./scripts/disable-microg.sh
```

Alternatively, use Magisk safe mode (Power + Vol-) to disable all modules.

## Q&A

### Q: Why use this instead of other microG installers?

**A**: Most microG installers only support one store variant, so you need to download different modules depending on whether you want Play Store or Companion. With microG Flex, you choose which variant to install during the installation process itself, making it more convenient and flexible.

### Q: What's the difference between Play Store and Companion variants?

**A**: 
- **Play Store**: Uses the official Google Play Store app. This generally works better with most apps and provides the full Play Store experience. Some apps may require Play Integrity Fix to function properly.
- **Companion**: Minimal microG component for compatibility.
- **Companion + Aurora Store**: Aurora Store is a full-featured, open-source app store that lets you browse and install apps from Google Play while maintaining your privacy.

### Q: Can I switch between variants after installation?

**A**: Yes, you can switch variants. Just uninstall the module, reboot your device, then install the module again and choose the other variant during installation.

### Q: Does this work on stock Android?

**A**: Yes, this module is specifically designed for stock Android ROMs that come with Google apps pre-installed. It will replace the existing Google apps without requiring you to manually remove them first.

## Migration from Legacy Modules

If you're migrating from **microg-w-play** or **noogle-magisk**:

1. Uninstall your current module
2. Reboot
3. Install microG Flex
4. Choose your preferred variant during installation
5. Reboot and grant permissions

Your settings and app data will be preserved!

## Credits

- **os-guy-original**: Current maintainer and developer
- **SelfRef**: Original developer of noogle-magisk
- **microG Team**: For the amazing microG Services
- **Magisk/KernelSU Communities**: For root solutions and support

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See [LICENSE](LICENSE) file for details.

### Disclaimer regarding Google Apps

Featured Google Apps (Google Play Store, etc.) are proprietary software of Google LLC and are **NOT** included in this source repository. They are downloaded optionally by the user from third-party sources during installation for convenience. Use of these apps is subject to Google's Terms of Service.
