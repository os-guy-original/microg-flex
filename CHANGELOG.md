# Changelog

All notable changes to microG Flex will be documented in this file.

## [v1.1.0] - 2026-01-19

### Added

- **Aurora Services Integration**: Added support for Aurora Services as an optional privileged helper for Aurora Store.
  - Includes specialized priv-app permissions XML and automated permission granting.
- **Intelligent Fetcher**: The `fetch-apks.sh` script now supports:
  - **Dynamic Fetching**: Automatically parses the latest Aurora Services release from GitLab.
  - **Byte Size Verification**: Compares local files with remote versions to skip unnecessary downloads or warn about mismatches.
- **Action Script Update**: Automated runtime permission granting for both Aurora Store and Aurora Services via the module's Action button.
- **Full FOSS disclaimer**: Added note that Aurora Services is included for user freedom, despite being deprecated.


## [v1.0.0] - 2026-01-18

### Initial Release

**microG Flex** - The flexible microG installer is born!

#### Features

- **Flexible Installation**: Choose between Google Play Store, microG Companion, or Companion + Aurora Store during installation.
- **Unified Logic**: Replaces legacy `microg-w-play` and `noogle-magisk` modules with a single Codebase.
- **Robust Downloader**: Centralized download system with retries and smart cancellation; integrates F-Droid for Aurora Store.
- **Full Support**: Works on Magisk, KernelSU, and KernelSU-Next (with meta-overlayfs detection) on Android 11-16.
- **Smart Management**: Automatically handles Google app replacement and permission granting.
