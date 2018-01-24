# Recompile with:
# mkimage -C none -A arm -T script -d boot.cmd boot.scr

# Set local vars
setenv load_addr "0x44000000"
setenv fsck.repair "yes"
setenv ramdisk "initramfs.cpio.gz"
setenv kernel "Image"
setenv bootpath "/boot"

# Import and load any custom settings
if test -e mmc ${mmc_bootdev} ${bootpath}/config.txt; then
	ext4load mmc ${mmc_bootdev} ${load_addr} ${bootpath}/config.txt
	env import -t ${load_addr} ${filesize}
fi

# Load FDT
ext4load mmc ${mmc_bootdev} ${fdt_addr_r} ${bootpath}/${fdtfile}
fdt addr ${fdt_addr_r} ${filesize}
fdt resize 0x10000

# Set FDT variables
fdt set ethernet0 local-mac-address ${ethaddr}
fdt set / serial-number ${serial#}

# Set cmdline
setenv bootargs console=ttyS0,115200 earlyprintk root=/dev/mmcblk${mmc_bootdev}p1 rootfstype=ext4 rw rootwait fsck.repair=${fsck.repair} panic=10 ${extra}

# Boot our image
ext4load mmc ${mmc_bootdev} ${kernel_addr_r} ${bootpath}/${kernel}
ext4load mmc ${mmc_bootdev} ${ramdisk_addr_r} ${bootpath}/${ramdisk}

# Boot the system
booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
