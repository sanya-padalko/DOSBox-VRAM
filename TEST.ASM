.model tiny
.code
org 100h

Start:		mov ax, 0b800h
		mov es, ax
		xor bx, bx
		mov byte ptr es:[bx], 03h
		mov byte ptr es:[bx + 1], 0ceh

		mov ax, 4c00h
		int 21h

end Start