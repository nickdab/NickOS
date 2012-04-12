; asmsyntax=nasm

BITS 16
[ORG 0]
jmp 0x07C0:_start 

;---------------------------------------------------------------------------
reservedForBoot         dw 0            ; Reserved Sectors for boot record
NumberOfFats            db 2            ; Number of copies of the FAT
RootDirEntries          dw 224          ; Number of entries in root dir

LogicalSectors          dw 2880         ; Number of Logical Sectors
MediumByte              db 0xF0         ; Medium descripter byte
SectorsPerFat           dw 9
SectorsPerTrack         dw 18
Sides                   dw 2            ; number of sides/heads
HiddenSectors           dd 0
LargeSectors            dd 0
DriveNo                 dw 0
Signature               db 41           ; 41=floppy
VolumeID                dd 0x0          ; it can be any number
VolumeLable             db "NickOS     "; volume label: any 11 chars
FileSystem              db "FAT12   "   ; File System Type
;---------------------------------------------------------------------------

_start:
	cli
	
	mov ax, cs
	mov ds, ax
	mov es, ax
	
	mov ax, 544
	mov ss, ax
	
	mov ax, 4096
	mov sp, ax
	mov bp, ax
	
	sti
	
	mov si, msg
	call printTele
	
	.reset:
		mov ah, 0
		mov dl, 0
		int 0x13
		jc short .reset
	
	mov si, dot
	call printTele
	
	mov bx, 4097

	mov ah, 0x02
	mov al, 1
	mov ch, 1
	mov cl, 2
	mov dh, 0
	mov dl, 0
	int 0x13
	
	jc .loadErr
	
	mov si, dot
	call printTele

	jmp 4097
	
	.loadErr:
		mov si, errLoading
		call printTele
		cli
		hlt

	msg db "Loading...",0
	dot db ".",0
	errLoading db "There was an error loading the second stage.",0

printTele:
	.repeat:
		lodsb
		cmp al, 0
		je .end
		
		mov ah, 0x0E
		int 0x10
		jmp .repeat		

		.end:
			ret
	
	
	
times 510-($-$$) db 0
dw 0xAA55
