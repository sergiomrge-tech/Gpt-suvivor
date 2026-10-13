#!/usr/bin/env bash
set -euo pipefail
# Dependencies: Godot 4.6.1 + matching Android templates, Java 17, Android SDK Build Tools.
# Godot editor settings must point at the Java SDK and Android SDK.
# Required environment: GODOT_BIN, ANDROID_SDK_ROOT, SURVIVOR_KEYSTORE, SURVIVOR_PASSWORD_FILE.
: "${GODOT_BIN:?Set GODOT_BIN}"
: "${ANDROID_SDK_ROOT:?Set ANDROID_SDK_ROOT}"
: "${SURVIVOR_KEYSTORE:?Set SURVIVOR_KEYSTORE}"
: "${SURVIVOR_PASSWORD_FILE:?Set SURVIVOR_PASSWORD_FILE}"
project_root="$(cd "$(dirname "$0")/../.." && pwd)"
output_dir="${1:?Pass an output directory outside the project}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
build_tools="$ANDROID_SDK_ROOT/build-tools/35.0.1"
build_temp="$(mktemp -d)"
trap 'rm -rf "$build_temp"' EXIT
"$GODOT_BIN" --headless --path "$project_root" --editor --import
"$GODOT_BIN" --headless --path "$project_root" --script res://tests/test_survivor.gd
python3 "$project_root/tests/audit_project.py"
python3 "$project_root/tests/audit_audio.py"
"$GODOT_BIN" --headless --path "$project_root" --export-release Android "$build_temp/unsigned.apk"
python3 "$project_root/tools/android/fix_android_manifest.py" "$build_temp/unsigned.apk" "$build_temp/fixed.apk"
"$build_tools/zipalign" -f -P 16 4 "$build_temp/fixed.apk" "$build_temp/aligned.apk"
output_apk="$output_dir/GPT_Survivor_v0_4_2_Android.apk"
"$build_tools/apksigner" sign --ks "$SURVIVOR_KEYSTORE" --ks-key-alias gpt-survivor --ks-pass "file:$SURVIVOR_PASSWORD_FILE" --out "$output_apk" "$build_temp/aligned.apk"
"$build_tools/apksigner" verify --verbose "$output_apk"
"$build_tools/zipalign" -c -P 16 4 "$output_apk"
python3 - "$output_apk" <<'PY_CRC'
import sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    assert z.testzip() is None
print('APK CRC passed')
PY_CRC
