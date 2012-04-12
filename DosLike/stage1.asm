; asmsyntax=nasm

ORG 0x07C0
jmp _start 

;---------------------------------------------------------------------------
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
	
	mov ax, 544
	mov ss, ax
	
	mov ax, 4096
	mov sp, ax
	mov bp, ax
	.reset:
