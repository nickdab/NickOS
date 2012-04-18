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

allSysGo:			;we're ready for liftoff!
	mov ax, 19		;root dir starts at logical sector 19	
	call regSet13h		;set the registers to correct numbers	

	mov si, buffer
	
	mov bx, si
	
	mov ah, 2		;read sector from floppy
	mov al, 14		;read 14 sectors

	pusha

read_root_dir:
	
	stc
	int 0x13

	jc shutdown

search_dir:
	
	pusha
	mov si, dot
	call printTele	
	popa

	popa
	
	mov di, buffer
	mov cx, word [RootDirEntries] 	;search all entries
	mov ax, 0			;search at offset 0

nextRootEntry:
	xchg cx, dx		;we use cx in the inner loop
	
	mov si, stage2FileName
	mov cx, 11
	rep cmpsb
	je foundFileToLoad
	
	add ax, 32		;move to the next entry (32 bytes/entry)
	
	mov di, buffer		;point to next entry
	add di, ax

	xchg dx, cx
	loop nextRootEntry
	
	mov si, fileNotFound
	call printTele
	jmp $

foundFileToLoad:
	
	mov ax, word [es:di+0x0F]
	mov word [cluster], ax

	mov ax, 1	;sector 1 = first sector of first FAT
	call regSet13h

	mov di, buffer
	mov bx, di
	
	mov ah, 2
	mov al, 9

	pusha
	mov si, dot
	call printTele
	popa

	pusha

readFat:
	
	stc
	int 0x13

	jc shutdown

readFatOK:
	
	popa
	
	mov ax, 0x2000
	mov es, ax
	mov bx, 0
	
	mov ah, 2
	mov al, 1

	push ax

loadFileSector:
	mov ax, word [cluster]
	add ax, 31
	
	call regSet13h
	
	mov ax, 0x2000
	mov es, ax
	mov bx, word [pointer]
	
	pop ax
	push ax
	
	stc
	int 0x13
	
	jc shutdown
	
calcNextCluster:
	mov ax, [cluster]
	mov dx, 0
	mov bx, 3
	mul bx
	mov bx, 2
	div bx
	mov si, buffer
	add si, ax
	mov ax, word [ds:si]
	
	or dx, dx
	
	jz even

odd:
	shr ax, 4
	jmp short nextClusterCont

even:
	and ax, 0x0FFF

nextClusterCont:
	mov word [cluster], ax

	cmp ax, 0x0FF8
	jae done
	
	add word [pointer], 512
	jmp loadFileSector

done:
	pop ax
	mov dl, byte [bootdev]

	jmp 0x2000:0x0000
	;infinite loop
	jmp $	

	msg db "Loading...",0
	dot db ".",0
	errLoading db "ErrLoadingSecondStage",0
	discErrMsg db "diskerror.",0
	fileNotFound db "not found",0
	stage2FileName db "STAGE2  BIN"
	
	bootdev	db 0
	cluster dw 0
	pointer dw 0

regSet13h:

	;in: logical sector in AX, OUT: correct registers for int 13h	

	push bx
	push ax

	mov bx, ax	;save logical sector
	
	;first, we will calculate the proper sector 
	mov dx, 0
	div word [SectorsPerTrack]
	add dl, 0x01	;physical sectors start at 1
	mov cl, dl	;int 13h wants sectors in cl
	mov ax, bx

	mov dx, 0	;now calc for the head
	div word [SectorsPerTrack]
	mov dx, 0
	div word [Sides]
	mov dh, dl	;head/side
	mov ch, al	;track

	pop ax
	pop bx

	mov dl, byte [bootdev]

	ret

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
