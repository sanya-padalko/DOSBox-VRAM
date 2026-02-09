.model tiny
.code
org 100h

start:		mov ax, 0b814h
		mov es, ax
		mov ah, 4eh
		mov bx, offset string
		mov al, [bx + 15]

		mov di, 0
		stosw
		
		mov ax, 4c00h
		int 21h

string		db 'Hello, world!', '!'

end start	