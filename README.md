# Chromium Android System Webview

## How can I find the current release branches?

The current release branches can be found at <https://chromiumdash.appspot.com/releases?platform=Android>

## How can I find the future release dates of stable versions?

The release dates of future Chromium versions is at <https://chromiumdash.appspot.com/schedule>. Stable Release is the date desired.

## Building with CI

### Cutting a new release

This repo contains the appropriate CI configuration to allow Chromium Webview to be built automatically. This requires some manual work, but the longest and hardest effort has been automated.

#### Expressing intent to build a new version

The current release branches can be found at <https://chromiumdash.appspot.com/releases?platform=Android>. Obtain the branch (expect a version number like `107.0.5304.54`), and the Chromium version shortcode (the last two sets of numbers without dots, e.g. `5304054`).

Place the new version and shortcode in the following places:

- `build-webview.sh` in `chromium_version` and `chromium_code`
- `README.md` twice each under the [ARM/ARM64](#armarm64) and [X86/X86_64](#x86x8664) sections
- `terraform-builder/variables.tf` in `chrome_version`

#### Actually building the new version

Commit these changes and push to Gerrit. After review and submission, return to the GitHub repository and navigate to Actions -> Terraform or use this direct link <https://github.com/CarbonROM/android_external_chromium-webview/actions/workflows/terraform.yaml>.

There will be a box that says

> This workflow has a `workflow_dispatch` event trigger.

There is a button that says `Run workflow` in the right side of this box. Click it and choose the appropriate Carbon branch, then click the green `Run workflow` button.

A Terraform job will be created that will create building infrastructure in AWS. After the Terraform run, the Build Waiter CI script will come up and wait for the Chromium Webview APK outputs and will send them as a commit to Gerrit. If the original Terraform run fails for any reason, Build Waiter will come up to destroy any infrastructure that happened to be made.

Once the Gerrit commit is pushed, merge it to update the prebuilt binaries.

As the Chromium Git history gets longer, the base AMI image that contains the source will need to be updated. This is because the base image pre-syncs Chromium in order to save time during the builds. To update the base AMI, see [CarbonROM/android_external_chromium-webview_packer](https://github.com/CarbonROM/android_external_chromium-webview_packer) which has it's own README and CI.

## Building Manually

### Note

Building the Chromium-based WebView in AOSP is no longer supported. WebView can now be built entirely from the Chromium source code.

General instructions for building WebView from Chromium:
<https://www.chromium.org/developers/how-tos/build-instructions-android-webview>

For questions about building WebView, please see
<https://groups.google.com/a/chromium.org/forum/#!forum/android-webview-dev>

### ARM/ARM64

The prebuilt `libwebviewchromium.so` included in these APKs is built from Chromium release tag `107.0.5304.54`, using the GN build tool. To match our build settings, set the following in your GN argument file before building:

```
target_os = "android"
is_debug = false
is_official_build = true
is_chrome_branded = false
use_official_google_api_keys = false
ffmpeg_branding = "Chrome"
proprietary_codecs = true
enable_resource_allowlist_generation = false
enable_remoting = false
is_component_build = false
symbol_level = 0
enable_nacl = false
blink_symbol_level = 0
webview_devui_show_icon = false
dfmify_dev_ui = false
disable_autofill_assistant_dfm = true
disable_tab_ui_dfm = true
enable_gvr_services = false
disable_fieldtrial_testing_config = true
android_default_version_name = "107.0.5304.54"
android_default_version_code = "5304054$$"
```

`$$` depends on device architecture:
(00=arm, 50=arm64, 10=x86, 60=x64)

### X86/X86_64

The prebuilt libwebviewchromium.so included in these APKs is built from Chromium
release tag 107.0.5304.54, using the GN build tool. To match our build settings, set the following in your GN argument file before building:

```
target_os = "android"
is_debug = false
is_official_build = true
is_chrome_branded = false
use_official_google_api_keys = false
ffmpeg_branding = "Chrome"
proprietary_codecs = true
enable_resource_allowlist_generation = false
enable_remoting = false
is_component_build = false
symbol_level = 0
enable_nacl = false
blink_symbol_level = 0
webview_devui_show_icon = false
dfmify_dev_ui = false
disable_autofill_assistant_dfm = true
disable_tab_ui_dfm = true
enable_gvr_services = false
disable_fieldtrial_testing_config = true
android_default_version_name = "107.0.5304.54"
android_default_version_code = "5304054$$"
```

`$$` depends on device architecture:
(00=arm, 50=arm64, 10=x86, 60=x64)

### Replace webview icon

From the `src` directory:

```bash
mkdir -p android_webview/apk/java/res/drawable-xxxhdpi
cp chrome/android/java/res_chromium/mipmap-mdpi/app_icon.png android_webview/apk/java/res/drawable-mdpi/icon_webview.png
cp chrome/android/java/res_chromium/mipmap-hdpi/app_icon.png android_webview/apk/java/res/drawable-hdpi/icon_webview.png
cp chrome/android/java/res_chromium/mipmap-xhdpi/app_icon.png android_webview/apk/java/res/drawable-xhdpi/icon_webview.png
cp chrome/android/java/res_chromium/mipmap-xxhdpi/app_icon.png android_webview/apk/java/res/drawable-xxhdpi/icon_webview.png
cp chrome/android/java/res_chromium/mipmap-xxxhdpi/app_icon.png android_webview/apk/java/res/drawable-xxxhdpi/icon_webview.png
```

### Apply patches

From the `src` directory:

```bash
git am ../patches/*
```

Then, you may build following Chromium's instructions.
