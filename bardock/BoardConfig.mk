#
# Copyright (C) 2018-2019 The LineageOS Project
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

# inherit from the common version
-include device/bq/msm8953-common/BoardConfigCommon.mk

# Assert
TARGET_OTA_ASSERT_DEVICE := bardock,bardock

# Kernel
TARGET_KERNEL_CONFIG := bardock_defconfig

# Device path
DEVICE_PATH := $(COMMON_PATH)/bardock

# Bluetooth
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(DEVICE_PATH)/bluetooth

# Inherit from the proprietary version
-include vendor/bq/bardockpro/BoardConfigVendor.mk
