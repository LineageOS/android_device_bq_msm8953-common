#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# Load extractutils and do some sanity checks
MY_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

LINEAGE_ROOT="${MY_DIR}/../../.."
CLEANUP="$1"

HELPER="${LINEAGE_ROOT}/vendor/lineage/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
	echo "Unable to find helper script at $HELPER"
	exit 1
fi
. "${HELPER}"

# Initialize the helper for common
setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${LINEAGE_ROOT}" "true" "${CLEANUP}"

# Copyright headers and guards
write_headers "bardock bardockpro"

# The standard bardock-common blobs
write_makefiles "${MY_DIR}/proprietary-files.txt" true

if [ -f "${MY_DIR}/proprietary-files-twrp.txt" ]; then
	cat >> "${BOARDMK}" <<-EOF
		ifeq (\$(WITH_TWRP),true)
		TARGET_RECOVERY_DEVICE_DIRS += vendor/${VENDOR}/${DEVICE_COMMON}/proprietary
		endif
	EOF
fi

# We are done!
write_footers

# Reinitialize the helper for msm8953-common/${device}
(
	setup_vendor "${DEVICE}" "${VENDOR}/${DEVICE_COMMON}" "${LINEAGE_ROOT}" "false" "${CLEANUP}"

	# Copyright headers and guards
	write_headers

	# $1: The device-specific blobs
	# $2: Make treble compatible paths and put "$(TARGET_COPY_OUT_VENDOR)"
	#     in generated makefiles
	write_makefiles "${MY_DIR}/${DEVICE}/proprietary-files.txt" true

	if [ -f "${MY_DIR}/${DEVICE}/proprietary-files-twrp.txt" ]; then
		cat >> "${BOARDMK}" <<-EOF
			ifeq (\$(WITH_TWRP),true)
			TARGET_RECOVERY_DEVICE_DIRS += vendor/${VENDOR}/${DEVICE_COMMON}/${DEVICE}/proprietary
			endif
		EOF
	fi

	# We are done!
	write_footers
)
