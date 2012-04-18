NickOS.flp:stage1.bin stage2.bin
	mkdosfs -F 12 -C NickOS.flp 1440
	dd status=noxfer conv=notrunc if=stage1.bin of=NickOS.flp
	mkdir tmp-loop
	mount -o loop -t vfat NickOS.flp tmp-loop
	cp stage2.bin tmp-loop
	umount tmp-loop
	rm -rf tmp-loop

stage1.bin:stage1.asm stage2.bin
	nasm stage1.asm -f bin -o stage1.bin

stage2.bin:stage2.asm
	nasm stage2.asm -f bin -o stage2.bin

clean:
	rm NickOS.flp stage1.bin stage2.bin
