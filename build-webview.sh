#!/bin/bash

set -e

chromium_version="107.0.5304.54"
chromium_code="5304054"
clean=0
gsync=0
skip_build=0
supported_archs=(arm arm64 x86 x64)

usage() {
    echo "Usage:"
    echo "  build_webview [ options ]"
    echo
    echo "  Options:"
    echo "    -a <arch> Build specified arch"
    echo "    -c Clean"
    echo "    -h Show this message"
    echo "    -r <release> Specify chromium release"
    echo "    -s Sync"
    echo "    -b Skip build"
    echo
    echo "  Example:"
    echo "    build_webview -c -r $chromium_version:$chromium_code"
    echo
    exit 1
}

build() {
    build_args=$args' target_cpu="'$1'"'

    code=$chromium_code
    if [ $1 '==' "arm" ]; then
        code+=00
    elif [ $1 '==' "arm64" ]; then
        code+=50
    elif [ $1 '==' "x86" ]; then
        code+=10
    elif [ $1 '==' "x64" ]; then
        code+=60
    fi
    build_args+=' android_default_version_code="'$code'"'

    gn gen "out/$1" --args="$build_args"
    ninja -C out/$1 system_webview_apk
    if [ "$?" -eq 0 ]; then
        [ "$1" '==' "x64" ] && android_arch="x86_64" || android_arch=$1
        xz -9 -c out/$1/apks/SystemWebView.apk -e -T 0 > ../prebuilt/$android_arch/webview.apk.xz
    fi
}

while getopts ":a:chr:sb" opt; do
    case $opt in
        a) for arch in ${supported_archs[@]}; do
               [ "$OPTARG" '==' "$arch" ] && build_arch="$OPTARG" || ((arch_try=arch_try+1))
           done
           if [ $arch_try -eq ${#supported_archs[@]} ]; then
               echo "Unsupported ARCH: $OPTARG"
               echo "Supported ARCHs: ${supported_archs[@]}"
               exit 1
           fi
           ;;
        c) clean=1 ;;
        h) usage ;;
        r) IFS=':' read -r -a version <<< "$OPTARG";
           if [ ${#version[@]} -ne 2 ]; then
               # Hardcode this version to serve as an example, the above can be overriden
               echo "Versions should be specificed like so: $0 -r 95.0.4638.74:4638074"
               exit 1
           fi
           chromium_version=${version[0]}
           chromium_code=${version[1]}
           ;;
        s) gsync=1 ;;
        b) skip_build=1 ;;
        :)
          echo "Option -$OPTARG requires an argument"
          echo
          usage
          ;;
        \?)
          echo "Invalid option:-$OPTARG"
          echo
          usage
          ;;
    esac
done
shift $((OPTIND-1))

# Add depot_tools to PATH
if [ ! -d depot_tools ]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi
export PATH="$(pwd -P)/depot_tools:$PATH"

if [ ! -d src ]; then
    fetch android
    yes | gclient sync -vvv -D -R -r $chromium_version
fi

if [ $gsync -eq 1 ]; then
    find src -name index.lock -delete
    yes | gclient sync -vvv -R -r $chromium_version
fi

cd src

./build/install-build-deps-android.sh
./build/install-build-deps.sh --no-prompt --arm --lib32 --no-chromeos-fonts --no-syms --no-backwards-compatible

# Replace webview icon
mkdir -p android_webview/nonembedded/java/res_icon/drawable-xxxhdpi
cp chrome/android/java/res_chromium_base/mipmap-mdpi/app_icon.png android_webview/nonembedded/java/res_icon/drawable-mdpi/icon_webview.png
cp chrome/android/java/res_chromium_base/mipmap-hdpi/app_icon.png android_webview/nonembedded/java/res_icon/drawable-hdpi/icon_webview.png
cp chrome/android/java/res_chromium_base/mipmap-xhdpi/app_icon.png android_webview/nonembedded/java/res_icon/drawable-xhdpi/icon_webview.png
cp chrome/android/java/res_chromium_base/mipmap-xxhdpi/app_icon.png android_webview/nonembedded/java/res_icon/drawable-xxhdpi/icon_webview.png
cp chrome/android/java/res_chromium_base/mipmap-xxxhdpi/app_icon.png android_webview/nonembedded/java/res_icon/drawable-xxxhdpi/icon_webview.png

# Apply our patches
if [ $gsync -eq 1 ]; then
    git am ../patches/*
fi

# Build args
args='target_os="android"'
args+=' is_debug=false'
args+=' is_official_build=true'
args+=' is_chrome_branded=false'
args+=' use_official_google_api_keys=false'
args+=' ffmpeg_branding="Chrome"'
args+=' proprietary_codecs=true'
args+=' enable_resource_allowlist_generation=false'
args+=' enable_remoting=false'
args+=' is_component_build=false'
args+=' symbol_level=0'
args+=' enable_nacl=false'
args+=' blink_symbol_level=0'
args+=' webview_devui_show_icon=false'
args+=' dfmify_dev_ui=false'
args+=' disable_autofill_assistant_dfm=true'
args+=' disable_tab_ui_dfm=true'
args+=' enable_gvr_services=false'
args+=' disable_fieldtrial_testing_config=true'
args+=' android_default_version_name="'$chromium_version'"'

# Setup environment
[ $clean -eq 1 ] && rm -rf out
. build/android/envsetup.sh

# Check target and build
if [ -n "$build_arch" ]; then
    build $build_arch
else
  if [ $skip_build -ne 1 ]; then
    build arm
    build arm64
    build x86
    build x64
  fi
fi
