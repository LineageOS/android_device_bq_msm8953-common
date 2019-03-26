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
        vendor/lib/libcam.vidhance.so)
                patchelf --replace-needed "android.frameworks.sensorservice@1.0.so" "android.frameworks.sensorservice@1.0-v27.so" "${2}"
        ;;
        vendor/bin/mm-qcamera-app|vendor/lib/hw/camera.msm8953.so|vendor/lib/libmm-qcamera.so|vendor/lib/libmmcamera*|vendor/lib64/libmmcamera*)
                sed -i -e 's|/data/misc/camera|/data/vendor/qcam|g' "${2}"
        ;;
        vendor/etc/permissions/embms.xml)
                sed -i -e 's|/system/framework|/vendor/framework|g' "${2}"
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
