bootloader.flp:bootloader.bin
	dd status=noxfer conv=notrunc if=bootloader.bin of=bootloader.flp

bootloader.bin:bootloader.asm
	nasm bootloader.asm -f bin -o bootloader.bin

clean:
	rm bootloader.flp bootloader.bin
