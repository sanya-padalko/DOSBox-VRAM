.model tiny
.code
org 100h

start:		mov ax, 0b81Eh
		mov es, ax

		mov ah, 0ah
		mov dx, offset buffer
		int 21h

		inc dx
		mov bx, dx
		mov cl, [bx]
		inc dx
		mov si, dx
		xor di, di
		
		mov ah, 0ceh

whilye:		lodsb
		stosw

		dec cl
		jne whilye

		mov ax, 4c00h
		int 21h

buffer		db 100d, 0h, 100d dup(0)

end start

