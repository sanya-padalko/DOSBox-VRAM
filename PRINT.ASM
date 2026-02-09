.model tiny
.code
org 100h

start:		mov ax, 0b814h
		mov es, ax

		mov di, 0h
		mov bx, offset string
		mov si, bx
		mov cx, 0eh		

whilye:		mov bx, ds:[si]
		inc si

		mov es:[di], bx
		inc di
		mov bl, 0ceh
		mov es:[di], bl
		inc di

		dec cx
		jne whilye

		mov ax, 4c00h
		int 21h


string 		db 'Hello, world', '!!'

end start