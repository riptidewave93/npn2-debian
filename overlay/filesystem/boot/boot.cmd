# Recompile with:
# mkimage -C none -A arm -T script -d boot.cmd boot.scr

# Set local vars
setenv load_addr "0x44000000"
setenv fsck.repair "yes"
setenv ramdisk "initramfs.cpio.gz"
setenv kernel "Image"
setenv overlay_prefix "sun50i-h5"

# Import and load any custom settings
if test -e mmc 0 config.txt; then
	fatload mmc 0 ${load_addr} config.txt
	env import -t ${load_addr} ${filesize}
fi

# Load FDT
fatload mmc 0 ${fdt_addr_r} ${fdtfile}
fdt addr ${fdt_addr_r} ${filesize}
fdt resize 0x10000

# Apply FDT Overlays
#for overlay_file in ${overlays}; do
#	if fatload mmc 0 ${load_addr} allwinner/overlay/${overlay_prefix}-${overlay_file}.dtbo; then
#		echo "Applying DT overlay allwinner/overlay/${overlay_prefix}-${overlay_file}.dtbo"
#		fdt apply ${load_addr} || setenv overlay_error "true"
#	fi
#done

# Check for errors with Overlays
#if test "${overlay_error}" = "true"; then
#	echo "Error applying DT overlays, restoring original DT"
#	fatload mmc 0 ${fdt_addr_r} ${fdtfile}
#  fdt addr ${fdt_addr_r} ${filesize}
#  fdt resize 0x60000
#fi

# Set FDT variables
fdt set ethernet0 local-mac-address ${ethaddr}
fdt set / serial-number ${serial#}

# Set cmdline
setenv bootargs console=ttyS0,115200 earlyprintk root=/dev/mmcblk0p2 rootfstype=ext4 rw rootwait fsck.repair=${fsck.repair} panic=10 ${extra}

# Load kernel and ramdisk
fatload mmc 0 ${kernel_addr_r} ${kernel}
fatload mmc 0 ${ramdisk_addr_r} ${ramdisk}

# Boot the system
booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
