bootloader.flp:stage1.bin stage2.bin
	dd status=noxfer conv=notrunc if=stage1.bin of=bootloader.flp
	dd status=noxfer conv=notrunc bs=512 seek=1 if=stage2.bin of=bootloader.flp

stage1.bin:stage1.asm stage2.bin
	nasm stage1.asm -f bin -o stage1.bin

stage2.bin:stage2.asm
	nasm stage2.asm -f bin -o stage2.bin

clean:
	rm bootloader.flp stage1.bin stage2.bin
