export CROSS_COMPILE ?= /home/igal/android/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export ARCH ?= arm64
export ORIG_BOOT_IMG ?= /mnt/hgfs/igalg/Documents/projects/p2_bb/opensource/G930FD/G930FXXS1BPLO/ap/boot.img
export AIK_TAR_GZ ?= /mnt/hgfs/igalg/Documents/projects/p2_bb/misc/AIK-Linux-v3.3-ALL.tar.gz
export LINUX_IMAGE ?= ./arch/arm64/boot/Image

V ?=
HGFS_KERNEL_ROOT ?= /mnt/hgfs/igalg/Documents/projects/p2_bb/opensource/G930FD/kernel
RSYNC_ITEMS = \
		custom-kernel.mk \
		security/ \
		ramdisk/ \
		net/ipv4/ \
		arch/arm64/ \
		drivers/misc/modem_v1/ \
		drivers/misc/mcu_ipc/ \
		include/linux/ \
		fs/proc/

CPUS=$(shell grep -c "processor" /proc/cpuinfo)


.PHONY: def
def:
	export

.PHONY: clean
clean:
	make clean
	make distclean
	sudo rm -rf AIK-Linux

.PHONY: rsync
rsync:
	@for x in ${RSYNC_ITEMS}; do \
			echo RSYNC: $${x}; \
			rsync -r ${HGFS_KERNEL_ROOT}/$${x} $${x}; \
	done

.PHONY: config
config:
	make V=${V} ARCH=${ARCH} exynos8890-herolte_defconfig

.PHONY: kernel
kernel:
	make V=${V} ARCH=${ARCH} -j${CPUS}

.PHONY: AIK-Linux
AIK-Linux:
	sudo rm -rf AIK-Linux
	tar xzvf ${AIK_TAR_GZ}

.PHONY: zip
zip: AIK-Linux
	[ -e ${ORIG_BOOT_IMG} ] || exit 1
	./AIK-Linux/unpackimg.sh $(realpath ${ORIG_BOOT_IMG})
	cp ${LINUX_IMAGE} AIK-Linux/split_img/boot.img-zImage
	sudo bash -c "cat ./ramdisk/default.prop >> AIK-Linux/ramdisk/default.prop"
	sudo ./AIK-Linux/repackimg.sh
	sudo cp ./AIK-Linux/image-new.img ./ramdisk/flasher/boot.img
	sudo cp ./ramdisk/updater-script ./ramdisk/flasher/META-INF/com/google/android/updater-script # IG: addition
	sudo bash -c "cd ./ramdisk/flasher && zip -r -o /tmp/custom.zip *"

.PHONY: pushzip
pushzip:
	adb push -p /tmp/custom.zip /sdcard/custom.zip
	
