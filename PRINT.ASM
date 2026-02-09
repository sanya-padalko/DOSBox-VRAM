.model tiny
.code
org 100h

start:		mov ax, 0b814h
		mov es, ax

		mov di, 0h
		mov bx, offset string
		mov si, bx		

whilye:		mov bl, ds:[si]
		mov cl, bl
		inc si

		xor cl, '$'
		je end_whilye

		mov es:[di], bl
		inc di
		mov bl, 0ceh
		mov es:[di], bl
		inc di

		jmp whilye

end_whilye:	mov ax, 4c00h
		int 21h

string 		db 'Hello, world', '!!', '$'
	
end start