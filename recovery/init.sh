#!/sbin/busybox sh

# include device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# create device nodes
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 ${BOOTREC_EVENT_NODE}
busybox mknod -m 666 /dev/null c 1 3

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys

# trigger button-backlight
source /sbin/bootrec-led

# keycheck
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 3

# boot decision
if [ -s /dev/keycheck ] || busybox grep -q warmboot=0x5502 /proc/cmdline; then
	# recovery ramdisk
	load_image=/sbin/ramdisk-recovery.cpio
else
	# android ramdisk
	load_image=/sbin/ramdisk.cpio
fi

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

busybox umount /proc
busybox umount /sys

busybox rm -fr /dev/*

busybox rm /init

# unpack the ramdisk image
# -u should be used to replace the static busybox with dynamically linked one.
cd /
busybox cpio -ui < ${load_image}

exec /init
