.model tiny
.code
org 100h

start:		mov ax, 0b814h
		add ax, 78h
		mov es, ax

		xor bx, bx
		mov byte ptr es:[bx], 03h
		mov byte ptr es:[bx + 1], 0ceh

		mov bx, 80h
		mov cl, [bx]
		mov bx, 50h
		mov ch, 0h
		mov si, cx
		shr si, 1d
		sal si, 1d
		sub bx, si
		sub bx, 6h

		mov ah, 8eh		; color of table

		mov al, 0dah		; ul_ang
		mov di, bx
		stosw
		
		mov al, 0c4h		; upside
		mov di, bx		
		add di, 2h		
		mov si, cx		
		add cx, 4h
		rep stosw
		mov cx, si		

		mov al, 0bfh		; ur_ang
		mov di, bx
		add di, 2h
		mov si, cx
		sal si, 1d
		add si, 8h
		add di, si
		stosw

		mov al, 0b3h		; lside
		mov si, 9Eh
		mov di, bx
		add di, 2h
		add di, si
		stosw
		add di, si
		stosw
		add di, si
		stosw
		

prog_end:	mov ax, 4c00h
		int 21h

end start