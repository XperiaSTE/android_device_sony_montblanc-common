LOCAL_PATH := $(call my-dir)

#device specific
BOOTREC_DEVICE := device/sony/$(TARGET_DEVICE)/config/bootrec-device
BOOTREC_LED    := device/sony/$(TARGET_DEVICE)/config/bootrec-led
CMDLINE		   := device/sony/$(TARGET_DEVICE)/config/cmdline

INSTALLED_BOOTIMAGE_TARGET := $(PRODUCT_OUT)/boot.img
$(INSTALLED_BOOTIMAGE_TARGET): $(PRODUCT_OUT)/kernel \
	$(PRODUCT_OUT)/utilities/busybox \
	$(MKBOOTIMG) \
	$(MINIGZIP) \
	$(INSTALLED_RAMDISK_TARGET) \
	$(INSTALLED_RECOVERYIMAGE_TARGET)

	$(call pretty,"Boot image: $@")

	$(hide) rm -rf $(PRODUCT_OUT)/combinedroot
	$(hide) mkdir -p $(PRODUCT_OUT)/combinedroot/sbin

	$(hide) cp $(LOCAL_PATH)/recovery/init.sh			$(PRODUCT_OUT)/combinedroot/sbin/
	$(hide) chmod 755									$(PRODUCT_OUT)/combinedroot/sbin/init.sh
	$(hide) ln -s sbin/init.sh							$(PRODUCT_OUT)/combinedroot/init

	$(hide) cp $(PRODUCT_OUT)/root/logo.rle				$(PRODUCT_OUT)/combinedroot/
	$(hide) cp $(PRODUCT_OUT)/utilities/busybox			$(PRODUCT_OUT)/combinedroot/sbin/
	$(hide) cp $(BOOTREC_DEVICE)						$(PRODUCT_OUT)/combinedroot/sbin/
	$(hide) cp $(BOOTREC_LED)							$(PRODUCT_OUT)/combinedroot/sbin/

	$(hide) $(MKBOOTFS) $(TARGET_ROOT_OUT) >			$(PRODUCT_OUT)/combinedroot/sbin/ramdisk.cpio
	$(hide) $(MKBOOTFS) $(TARGET_RECOVERY_ROOT_OUT) >	$(PRODUCT_OUT)/combinedroot/sbin/ramdisk-recovery.cpio

	$(hide) $(MKBOOTFS) $(PRODUCT_OUT)/combinedroot | $(MINIGZIP) > $(PRODUCT_OUT)/combinedroot.img

	$(hide) rm -rf $(PRODUCT_OUT)/system/bin/recovery
	$(hide) rm -rf $@

	$(hide) python $(LOCAL_PATH)/releasetools/mkelf.py -o $@ \
		$(PRODUCT_OUT)/kernel@$(BOARD_KERNEL_ADDRESS) \
		$(PRODUCT_OUT)/combinedroot.img@$(BOARD_RAMDISK_ADDRESS),ramdisk \
		$(CMDLINE)@cmdline

INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img
$(INSTALLED_RECOVERYIMAGE_TARGET): $(PRODUCT_OUT)/kernel \
	$(MKBOOTIMG) \
	$(recovery_ramdisk)

	@echo ----- Making recovery image ------

	$(hide) python $(LOCAL_PATH)/releasetools/mkelf.py -o $@ \
		$(PRODUCT_OUT)/kernel@$(BOARD_KERNEL_ADDRESS) \
		$(recovery_ramdisk)@$(BOARD_RAMDISK_ADDRESS),ramdisk \
		$(CMDLINE)@cmdline
