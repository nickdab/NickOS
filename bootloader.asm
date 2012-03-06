; asmsyntax=nasm
; ---------------------------------------------------------
; Nick Operating System Bootloader
; Copyright (C) Nick Birney GNU General Public License
; Created: 3/5/2012
; Updated: 3/5/2012
; ---------------------------------------------------------

	BITS 16

	jmp short _start;
	nop

; ----------------------------------------------------------
; Disk Description Table

OEMLabel		db "bootloader"	; Disk Label
BytesPerSector		dw 512		; Bytes per sector
SectorsPerCluster	db 1		; 1 sector in a cluster
ReservedForBoot		dw 1		; Reserved Sectors for boot record
NumberOfFats		db 2		; Number of copies of the FAT
RootDirEntries		dw 224		; Number of entries in root dir

LogicalSectors		dw 2880		; Number of Logical Sectors
MediumByte		db 0xF0		; Medium descripter byte
SectorsPerFat		dw 9		
SectorsPerTrack		dw 18		
Sides			dw 2		; number of sides/heads
HiddenSectors		dd 0		
LargeSectors		dd 0
DriveNo			dw 0
Signature		db 41		; 41=floppy 
VolumeID		dd 0x0		; it can be any number
VolumeLable		db "NickOS     "; volume label: any 11 chars
FileSystem		db "FAT12   "	; File System Type

; ----------------------------------------------------------

_start:
	mov ax, 0x07c0		; set up 4K stack space
	add ax, 288		; for the segment register --> 4096 (stack) + 512 (bootloader) / 16 bytes per paragraph 
	mov ss, ax		
	mov sp, 0x1000		
	mov bp, 0x1000

	mov ax, 0x07c0
	mov ds, ax		; point the data segment to the same place

	mov es, ax		; same thing with es

	mov ah, 0x00		; change video mode
	mov al, 0x10		; to graphics, 640x350 16 bit color
	int 0x10		; call the bios
	
	
	mov si, welcomeMsg
	mov bl, 0x03		; display it in cyan
	mov cx, welcomeMsgSize	; length of the message
	mov dx, 0		; top left corner
	call printString

	call newline
	call newline
	
	call console		

	jmp $

	welcomeMsg db "Welcome to Nick",39,"s Operating System.",0
	welcomeMsgSize equ $-welcomeMsg
	
	prompt db ">> "
	promptSize equ $-prompt

printTele:
	mov ah, 0x0E		; this tells the BIOS we want to teletype print a character

	.printChar:
		lodsb		; load the string into al
		cmp al, 0	; if al is 0, we're done
		je short .done
		;else
		int 0x10	;make the interrupt
		jmp short .printChar

	.done:
		ret

printString:
	mov ah, 0x13		; print string BIOS call
	mov al, 0x01		; update the cursor and make the attribute in bl apply to all characters

	push bp
	mov bp, si
	int 0x10		;make the call
	pop bp
	ret

newline:
	mov ah, 0x03		;read where the cursor is at
	int 0x10		;make the call

	cmp dh, 23		;last call put cursor row position in dh
	jg .scrollUp		;if we've gone over the amount of rows available on screen (23), we scroll up
	
	add dh, 1		;go down 1 row
	mov dl, 0		;back to the very left
	mov ah, 0x02		;change the cursor position
	int 0x10		;make the call
	ret
	
	.scrollUp:
		mov ah, 0x06	;scroll up
		mov al, 1	;scroll 1 line
		mov ch, 0	;0x0 is upper left corner
		mov cl, 0
		mov dh, 24	;24x79 is lower right corner
		mov dl, 79
		int 0x10
		
		mov ah, 0x02	;update the cursor to column 0
		mov dl, 0
		int 0x10	;make the call
		ret

printChars:
	mov ah, 0x09
	
	.printChar:
		lodsb
		cmp al, 0
		je short .done
		;else
		mov cx, 1
		int 0x10
		jmp short .printChar

	.done:
		ret

printChar:
	mov ah, 0x09
	mov cx, 1
	int 0x10
	ret
	
console:
	.printPrompt:
		mov si, prompt	;">>"
		mov bl, 0x0F	; print it in white
		mov cx, promptSize;
		call printString

		mov ah, 0x02	;change cursor position
		mov dl, 3	
		int 0x10
	
	.readStdIn:
		mov ah, 0x10	;wait for keyboard input
		int 0x16	;make the call to the bios

		cmp al, 13	; "enter" key
		je .carriageReturn
		cmp al, 8	; "backspace key"
		je .backspace
		
		call printChar	; write character
		
		mov ah, 0x02	; move cursor
		inc dl		; 1 column to the right
		int 0x10
		
		jmp short .readStdIn

		.carriageReturn:
			call newline
			jmp short .printPrompt

		.backspace:
			mov ah, 0x03	;read cursor position
			int 0x10	

			cmp dl, 3	; we don't want to overwrite the prompt
			je short .readStdIn			

			mov ah, 0x02	;move cursor
			dec dl		;one column to the left
			int 0x10

			mov al, 32	;space character
			call printChar	
			jmp short .readStdIn

			
	
	

times 510-($-$$) db 0		;pad the rest of the disk with 0's
dw 0xAA55			;This is the standard boot signature for floppy drives
