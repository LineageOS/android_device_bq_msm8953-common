#!/bin/bash
#
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=$1
VENDOR=bq

# Load extractutils and do some sanity checks
MY_DIR=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
LINEAGE_ROOT=$(readlink -f "${MY_DIR}/../../..")

HELPER="${LINEAGE_ROOT}/vendor/lineage/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true
KANG=

while [ "$1" != "" ]; do
    case $1 in
        -p | --path )           shift
                                SRC=$1
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        -k | --kang)            KANG="--kang"
                                ;;
        -n|--no-cleanup)        CLEAN_VENDOR=false
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

function blob_fixup() {
        case "${1}" in
        product/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml|product/etc/permissions/vendor.qti.hardware.data.connection-V1.1-java.xml)
                sed -i -e 's|xml version=\"2.0\"|xml version=\"1.0\"|g' "${2}"
        ;;
        lib64/libwfdnative.so)
                patchelf --remove-needed "android.hidl.base@1.0.so" "${2}"
        ;;
        lib64/liblocationservice_jni.so)
                patchelf --remove-needed "android.hidl.base@1.0.so" "${2}"
        ;;
        lib64/libxt_native.so)
                patchelf --remove-needed "android.hidl.base@1.0.so" "${2}"
        ;;
        vendor/lib/hw/camera.msm8953.so)
                patchelf --replace-needed "android.frameworks.sensorservice@1.0.so" "android.frameworks.sensorservice@1.0-v27.so" "${2}"
        ;;
        lib64/hw/fingerprint.default.so|lib64/hw/swfingerprint.default.so|lib64/libgoodixfingerprintd_binder.so)
                patchelfv08 --remove-needed "libunwind.so" "${2}"
                patchelfv08 --remove-needed "libkeymaster1.so" "${2}"
                patchelfv08 --remove-needed "libsoftkeymaster.so" "${2}"
        ;;
        vendor/lib/libmmcamera2_iface_modules.so)
                # Always set 0 (Off) as CDS mode in iface_util_set_cds_mode
                sed -i -e 's|\xfd\xb1\x20\x68|\xfd\xb1\x00\x20|g' "${2}"
                PATTERN_FOUND=$(hexdump -ve '1/1 "%.2x"' "${2}" | grep -E -o "fdb10020" | wc -l)
                if [ $PATTERN_FOUND != "1" ]; then
                   echo "Critical blob modification weren't applied on ${2}!"
                   exit;
                fi
        ;;
        vendor/bin/mm-qcamera-daemon|vendor/lib/hw/camera.msm8953.so|vendor/lib/libmm-qcamera.so|vendor/lib/libmmcamera*|vendor/lib64/libmmcamera*)
                sed -i -e 's|/data/misc/camera|/data/vendor/qcam|g' "${2}"
        ;;
        vendor/etc/izat.conf)
                sed -i -e 's|^GTP_CELL *=.*|GTP_CELL=BASIC|g' "${2}"
                sed -i -e 's|^GTP_WIFI *=.*|GTP_WIFI=BASIC|g' "${2}"
                sed -i -e 's|^NLP_MODE *=.*|NLP_MODE=4|g' "${2}"
        ;;
        vendor/bin/netmgrd)
                sed -i -e 's|qti_filter_ssdp_dropper|oem_filter_ssdp_dropper|g' "${2}"
        ;;
        vendor/lib64/hw/android.hardware.bluetooth@1.0-impl-qti.so)
                patchelf --add-needed "libbase_shim.so" "${2}"
        ;;
        product/framework/qti-telephony-common.jar)
                set -e
                APKTOOL_TMP_PATH=/tmp/apktool/qti-telephony-common.jar.out
                rm -rf "$APKTOOL_TMP_PATH"
                apktool d -o "$APKTOOL_TMP_PATH" "${2}"
                patch -d "$APKTOOL_TMP_PATH" -p1 -E << EOF
diff --git a/smali/com/qualcomm/qti/internal/telephony/QtiPhoneSwitcher.smali b/smali/com/qualcomm/qti/internal/telephony/QtiPhoneSwitcher.smali
index a6008e9..1980edc 100644
--- a/smali/com/qualcomm/qti/internal/telephony/QtiPhoneSwitcher.smali
+++ b/smali/com/qualcomm/qti/internal/telephony/QtiPhoneSwitcher.smali
@@ -2267,7 +2267,7 @@
     .line 319
     iget v10, v0, Lcom/qualcomm/qti/internal/telephony/QtiPhoneSwitcher;->mPreferredDataPhoneId:I
 
-    if-eq v8, v10, :cond_3
+    if-eq v8, v10, :cond_4
 
     .line 320
     const-string v10, " preferred phoneId "
@@ -2289,24 +2289,6 @@
     .line 323
     const/4 v5, 0x1
 
-    .line 326
-    :cond_3
-    invoke-virtual/range {p0 .. p0}, Lcom/qualcomm/qti/internal/telephony/QtiPhoneSwitcher;->isEmergency()Z
-
-    move-result v9
-
-    const/4 v10, 0x0
-
-    if-eqz v9, :cond_4
-
-    .line 327
-    const-string v9, "onEvalaute aborted due to Emergency"
-
-    invoke-virtual {v0, v9}, Lcom/qualcomm/qti/internal/telephony/QtiPhoneSwitcher;->log(Ljava/lang/String;)V
-
-    .line 329
-    return v10
-
     .line 332
     :cond_4
     if-eqz v5, :cond_f
--
EOF
               apktool b -o "${2}" "$APKTOOL_TMP_PATH"
        ;;
        esac
}
# Reinitialize the helper for ${device}
(
        source "${DEVICE}/extract-files.sh"
        setup_vendor "${DEVICE}" "${VENDOR}" "${LINEAGE_ROOT}" false "${CLEAN_VENDOR}"
        extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
                        ${KANG} --section "${SECTION}"
        if [ -s "${MY_DIR}/proprietary-files-twrp.txt" ]; then
                extract "${MY_DIR}/proprietary-files-twrp.txt" "$SRC" \
                        ${KANG} --section "${SECTION}"
        fi
)

"${MY_DIR}/setup-makefiles.sh" "${CLEAN_VENDOR}"
