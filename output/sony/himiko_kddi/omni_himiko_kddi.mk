#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Omni stuff.
$(call inherit-product, vendor/otwrp/config/common.mk)

# Inherit from himiko_kddi device
$(call inherit-product, device/sony/himiko_kddi/device.mk)

PRODUCT_DEVICE := himiko_kddi
PRODUCT_NAME := omni_himiko_kddi
PRODUCT_BRAND := Sony
PRODUCT_MODEL := Himiko_kddi
PRODUCT_MANUFACTURER := sony

PRODUCT_GMS_CLIENTID_BASE := android-sonymobile-rev1

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="himiko_kddi-user 9 GANGES2-2.0.0-KDDI-191122-0604 1 dev-keys"

BUILD_FINGERPRINT := Sony/himiko_kddi/himiko_kddi:9/GANGES2-2.0.0-KDDI-191122-0604/1:user/dev-keys
