.model tiny
.code
org 100h

start:		mov ax, cs
		mov es, ax
		mov di, offset Old09Ofs
		mov ax, 0h
		mov ds, ax
		mov si, 4 * 09h			; offset:segment -> 4 bytes
		movsw
		movsw				; saving Old 09 Address

		mov ax, 0h
		mov es, ax
		mov bx, 4 * 09h
		cli
		mov es:[bx], offset New09
		mov ax, cs
		mov es:[bx + 2], ax
		sti

		int 09h

		mov ax, 3100h
		mov dx, offset Eoppp
		shr dx, 4h
		inc dx
		int 21h

New09		proc
		push ax bx es

		call printing

		in al, 61h
		and al, not 80h
		out 61h, al
		or al, 80h
		out 61h, al

		mov al, 20h
		out 20h, al

		pop es bx ax
nxt_jmp		db 0eah
Old09Ofs	dw 0
Old09Seg	dw 0

		pop es bx ax
		endp

printing	proc
		push ax bx es

		mov ax, 0b800h
		mov es, ax
		in al, 60h
		mov ah, 0ceh
		mov bx, 320h
		mov es:[bx], ax

		pop es bx ax
		ret
		endp

Eoppp:

end start