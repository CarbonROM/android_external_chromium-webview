# WARNING
# READ THIS BEFORE PUSHING
# WARNING
# READ THIS BEFORE PUSHINGN

Pushes to `external/chromium-webview` need to be done carefully. It doesn't track AOSP, it tracks Chromium stable, so pushes shouldn't be common, BUT any pushes not done properly will cost a significant amount money in AWS. If we want a new build of Chromium webview to be generated, push as normal, but if a build shouldn't trigger, like as a result of a README update, add [skip ci] or something similar to your commit title to avoid spinning up the servers to fire of a redundant build. The commit message doesn't have to include [skip ci] exactly, see <https://github.blog/changelog/2021-02-08-github-actions-skip-pull-request-and-push-workflows-with-skip-ci/>

------

Building the Chromium-based WebView in AOSP is no longer supported. WebView can
now be built entirely from the Chromium source code.

General instructions for building WebView from Chromium:
https://www.chromium.org/developers/how-tos/build-instructions-android-webview

Useful link for versions: https://chromiumdash.appspot.com/releases?platform=Android

------

ARM/ARM64

The prebuilt libwebviewchromium.so included in these APKs is built from Chromium
release tag 106.0.5249.126, using the GN build tool. To match our build settings, set:

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
android_default_version_name = "106.0.5249.126"
android_default_version_code = "5249126$$"

$$ depends on device ARCH
(00=arm, 50=arm64, 10=x86, 60=x64)

in your GN argument file before building.

------

X86/X86_64

The prebuilt libwebviewchromium.so included in these APKs is built from Chromium
release tag 106.0.5249.126, using the GN build tool. To match our build settings, set:

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
android_default_version_name = "106.0.5249.126"
android_default_version_code = "5249126$$"

$$ depends on device ARCH
(00=arm, 50=arm64, 10=x86, 60=x64)

in your GN argument file before building.

------

Replace webview icon:

From the chromium/src directory:

mkdir -p android_webview/apk/java/res/drawable-xxxhdpi
cp chrome/android/java/res_chromium/mipmap-mdpi/app_icon.png android_webview/apk/java/res/drawable-mdpi/icon_webview.png
cp chrome/android/java/res_chromium/mipmap-hdpi/app_icon.png android_webview/apk/java/res/drawable-hdpi/icon_webview.png
cp chrome/android/java/res_chromium/mipmap-xhdpi/app_icon.png android_webview/apk/java/res/drawable-xhdpi/icon_webview.png
cp chrome/android/java/res_chromium/mipmap-xxhdpi/app_icon.png android_webview/apk/java/res/drawable-xxhdpi/icon_webview.png
cp chrome/android/java/res_chromium/mipmap-xxxhdpi/app_icon.png android_webview/apk/java/res/drawable-xxxhdpi/icon_webview.png

------

Extra patches:
patches/chromium-theme-color.patch: Provides a callback when a theme color is set by the page

------

For questions about building WebView, please see
https://groups.google.com/a/chromium.org/forum/#!forum/android-webview-dev
