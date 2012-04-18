; asmsyntax=nasm

BITS 16
[ORG 0]
jmp 0x07C0:_start 

;---------------------------------------------------------------------------
OEMLabel		db "NickOS"
BytesPerSector		dw 512
SectorsPerCluster	db 1
reservedForBoot         dw 1            ; Reserved Sectors for boot record
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
	
	add ax, 544
	mov ss, ax
	
	mov ax, 4096
	mov sp, ax
	mov bp, ax
	
	sti

	cmp dl, 0
	je noChange
	mov [bootdev], dl
	mov ah, 8
	int 0x13
	jc discErr	;shutdown the system
	and cx, 0x3F	;3F is max sector number
	mov [SectorsPerTrack], cx
	movzx dx, dh
	add dx, 1	;Head numbers start at 0, add 1 for total
	mov [Sides],dx
	
	noChange:
		mov ax, 0
		
	mov si, msg
	call printTele
	
	.reset:
		mov ah, 0
		mov dl, 0
		int 0x13
		jc short .reset
	
	mov si, dot
	call printTele

	
	
	mov si, dot
	call printTele

	;infinite loop
	jmp $	

	msg db "Loading...",0
	dot db ".",0
	errLoading db "There was an error loading the second stage.",0
	discErrMsg db "There was a fatal disk error.",0
	
	bootdev	db 0
	cluster dw 0
	pointer dw 0

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

discErr:
mov si, discErrMsg
call printTele
call shutdown
	
shutdown:
mov ah, 0x53
mov al, 0x07
mov bx, 0x0001
mov cx, 0x03
int 0x15
ret

times 510-($-$$) db 0
dw 0xAA55

buffer:			; So we can peak into the stage2 loader after the break
