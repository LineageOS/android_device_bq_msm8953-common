#!/bin/bash
#
# Copyright (C) 2018-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common )
                ONLY_COMMON=true
                ;;
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
        case "${1}" in
        lib64/libdpmframework.so)
                patchelf --add-needed "libshim_dpmframework.so" "${2}"
        ;;
        system/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml|system/etc/permissions/vendor.qti.hardware.data.connection-V1.1-java.xml)
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
                sed -i -e 's|^GTP_MODE *=.*|GTP_MODE=SDK_WIFI|g' "${2}"
                sed -i -e 's|^NLP_MODE *=.*|NLP_MODE=4|g' "${2}"
        ;;
        vendor/bin/netmgrd)
                sed -i -e 's|qti_filter_ssdp_dropper|oem_filter_ssdp_dropper|g' "${2}"
        ;;
        vendor/lib/hw/android.hardware.bluetooth@1.0-impl-qti.so|vendor/lib64/hw/android.hardware.bluetooth@1.0-impl-qti.so)
                patchelf --add-needed "libbase_shim.so" "${2}"
        ;;
        vendor/bin/wcnss_service)
                patchelf --add-needed "libqmiservices_shim.so" "${2}"
                sed -i "s|dms_get_service_object_internal_v01|dms_get_service_object_shimshim_v01|g" "${2}"
        ;;
        vendor/lib64/libril-qc-hal-qmi.so)
                patchelf --replace-needed "android.hardware.radio.config@1.1.so" "android.hardware.radio.config@1.1_shim.so" "${2}"
                patchelf --replace-needed "libprotobuf-cpp-full.so" "libprotobuf-cpp-full-v28.so" "${2}"
        ;;
        vendor/lib/libsettings.so|vendor/lib64/libsettings.so)
                patchelf --replace-needed "libprotobuf-cpp-full.so" "libprotobuf-cpp-full-v28.so" "${2}"
        ;;
        vendor/lib/libwvhidl.so|vendor/lib64/libwvhidl.so)
                patchelf --replace-needed "libprotobuf-cpp-lite.so" "libprotobuf-cpp-lite-v28.so" "${2}"
        ;;
        vendor/lib64/android.hardware.radio.config@1.1_shim.so)
                patchelf --set-soname "android.hardware.radio.config@1.1_shim.so" "${2}"
                sed -i -e 's|android.hardware.radio.config@1.1::IRadioConfig\x00|android.hardware.radio.config@1.0::IRadioConfig\x00|g' "${2}"
        esac
}

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

COMMON_BLOB_ROOT="${ANDROID_ROOT}"/vendor/"${VENDOR}"/"${DEVICE_COMMON}"/proprietary

"${MY_DIR}"/setup-makefiles.sh
