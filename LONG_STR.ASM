.model tiny
.code
org 100h

start:		mov ax, 0b814h
		mov es, ax
		mov di, 0h
		
		mov bx, offset string
		mov si, bx

		mov cx, 0eh

		rep movsb
		
		mov bx, 0h
		mov dl, es:[bx + 1]
		
		mov ax, 0h
		mov ah, 02h
		int 21h	
		
		mov ax, 4c00h
		int 21h

string 		db 'Hello, world', '!!'

end start