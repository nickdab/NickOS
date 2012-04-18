; asmsyntax=nasm
; ---------------------------------------------------------
; Nick Operating System Bootloader
; Copyright (C) Nick Birney GNU General Public License
; Created: 3/5/2012
; Updated: 3/6/2012
; ---------------------------------------------------------

	BITS 16
	
	jmp stage2_start
	
stage2_start:	
	cli		
	mov ax, 0
	mov ss, ax
	mov sp, 0x0FFFF
	sti

	cld
	
	mov ax, 0x2000
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ah, 0x00 ; change video mode
	mov al, 0x10 ; to graphics, 640x350 16 bit color
	int 0x10 ; call the BIOS

	mov si, welcomeMsg
	mov bl, 0x03		; display it in cyan
	mov cx, welcomeMsgSize	; length of the message
	mov dx, 0		; top left corner
	call printString


	cli
	;put the APM into Real Mode	
	mov ah, 0x53		;Talk to the APM
	mov al, 0x01		;Real Mode
	xor bx,bx
	int 0x15		;make the call	

	sti			;interrupts can be called now

	mov ah, 0x00		; change video mode
	mov al, 0x10		; to graphics, 640x350 16 bit color
	int 0x10		; call the BIOS
	
	
	call newline
	call newline
	
	call console		

	jmp $

	welcomeMsg db "Welcome to Nick",39,"s Operating System!",0
	welcomeMsgSize equ $-welcomeMsg
	
	prompt db ">> "
	promptSize equ $-prompt

	shutdownCommand db "shutdown"
	SHTDWNSZ equ $-shutdownCommand
	
	helpCommand db "help"
	HLPSZ equ $-helpCommand

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

;printChars:
;	mov ah, 0x09
	
;	.printChar:
;		lodsb
;		cmp al, 0
;		je short .done
		;else
;		mov cx, 1
;		int 0x10
;		jmp short .printChar

;	.done:
;		ret

printChar:
	push cx
	push ax
	mov ah, 0x09
	mov cx, 1
	int 0x10
	pop ax
	pop cx
	
	mov di, buffer
	push dx
	xor dh, dh
	sub dx, 3
	add di, dx
	stosb
	pop dx

	ret
	
console:


	.printPrompt:
		;fill the buffer with spaces:
		mov di, buffer
		mov al, '*'
		mov cx, 64
		rep stosb

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
				
			.checkShutdown:

				mov cx, SHTDWNSZ
				mov si, shutdownCommand

				call cmpStrToBuf
			
				cmp ax, 0
				je short .newline
				call shutdown
			
		.newline:
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

cmpStrToBuf:
;in: string --> si, cx --> size
;out: ax--> 0 if ne, 1 if e
mov di, buffer
	.repeat:
		cmpsb
		jne short .notEqual
		dec cx
		cmp cx, 0
		jg short .repeat
		mov ax, 1
		ret 
		
		.notEqual:
			
			mov ax, 0
			ret 
	
shutdown:
	mov ah, 0x53
	mov al, 0x07
	mov bx, 0x0001
	mov cx, 0x03
	int 0x15
	ret


times 512-($-$$) db 0		;pad the rest of the disk with 0's		

section .bss
	buffer: resb 64
