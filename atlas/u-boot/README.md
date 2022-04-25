This device has a USB LTE key connected that has an SD card slot.

Frequently, the SD card slot on the LTE key gets enumerated before the interna
SD card. Therefore, the A64 is unable to boot properly, unless the key is
disconnected and inserted after the boot is complete.

I recompiled u-boot disabling USB support so that the A64 boot directly from the
internal SD card.

To compile and flash mainline u-boot I followed this guides:
 * https://source.denx.de/u-boot/u-boot/blob/master/board/sunxi/README.sunxi64
 * https://gitlab.com/pine64-org/linux/-/wikis/Bringing-up-a-distro-on-the-A64-devices

Now the only thing left is providing the appropiate .dtb file. On the SD card
root partition run:
	# cd /boot/dtbs/allwinner
	# ln -s sun50i-a64-pine64.dtb sun50i-a64-sunxi.dtb

Incdentally, since USB is not initialized and enumerated any more the boot phase
will be faster compared with the original bootloader.

Do not forget to remove the u-boot package installed with pacman:
	# pacman -Rs uboot-pine64
	# mv /boot/boot.scr.pacsave /boot/boot.scr
	# mv /boot/boot.txt.pacsave /boot/boot.txt

