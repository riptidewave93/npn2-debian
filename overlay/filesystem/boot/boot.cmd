# Recompile with:
# mkimage -C none -A arm -T script -d boot.cmd boot.scr

# Set local vars
setenv load_addr "0x44000000"
setenv fsck.repair "yes"
setenv ramdisk "initramfs.cpio.gz"
setenv kernel "Image"
setenv extra "net.ifnames=0"

# Import and load any custom settings
if test -e mmc ${mmc_bootdev} config.txt; then
	fatload mmc ${mmc_bootdev} ${load_addr} config.txt
	env import -t ${load_addr} ${filesize}
fi

# If this is first boot, save our env
if test ! -e mmc ${mmc_bootdev} uboot.env; then
	saveenv
fi

# Load FDT
fatload mmc ${mmc_bootdev} ${fdt_addr_r} ${fdtfile}
fdt addr ${fdt_addr_r} ${filesize}
fdt resize 0x10000

# Set FDT variables
fdt set ethernet0 local-mac-address ${ethaddr}
fdt set / serial-number ${serial#}

# Set cmdline
setenv bootargs console=ttyS0,115200 earlyprintk root=/dev/mmcblk${mmc_bootdev}p2 rootfstype=ext4 rw rootwait fsck.repair=${fsck.repair} panic=10 ${extra}

# Dirty hack to allow the Plus2 board boot from onboard MMC
# This is due to the fact we don't expose MMC1 for wifi to U-Boot
# so it sees MMC2 as MMC1, causing boot issues once we enter linux
if test "${fdtfile}" = "allwinner/sun50i-h5-nanopi-neo-plus2.dtb"; then
	if test "${mmc_bootdev}" = "1"; then
		setenv bootargs console=ttyS0,115200 earlyprintk root=/dev/mmcblk2p2 rootfstype=ext4 rw rootwait fsck.repair=${fsck.repair} panic=10 ${extra}
	fi
fi

# Boot our image
fatload mmc ${mmc_bootdev} ${kernel_addr_r} ${kernel}
fatload mmc ${mmc_bootdev} ${ramdisk_addr_r} ${ramdisk}

# Boot the system
booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
