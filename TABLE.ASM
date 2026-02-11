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
		sub cl, 1h
		mov bx, 50h
		mov ch, 0h
		mov si, cx
		shr si, 1d
		sal si, 1d
		sub bx, si
		sub bx, 6h

		mov ah, 8ah    ; color of table

		mov al, 0dah    ; ul_ang
		mov di, bx
		stosw
    
		mov dx, 2h

hor_side:	mov al, 0c4h    ; upside and dside
		mov di, bx    
		add di, 2h    
		mov si, cx    
		add cx, 4h
		cmp dx, 1h
		jne notad
		add di, 640d  
	notad:  rep stosw
		mov cx, si
		dec dx
		jne hor_side    

		mov dx, cx    ; dx saves 2 * hor_side_size
		add dx, 4
		sal dx, 1d
		
		mov al, 0bfh    ; ur_ang
 		mov di, bx
		add di, dx
		add di, 2h
		stosw

		mov al, 0b3h    ; lside and rside
		mov si, 9eh    ; cnt bytes in string - 2
		mov di, bx
		add di, 2h
		add di, si
		stosw      ; first l wall
    
		mov ah, 08ch
		mov al, 0dah
		stosw

		mov al, 0c4h
		mov si, cx
		mov cx, dx
		shr cx, 1d
		sub cx, 2h
		rep stosw
		mov cx, si

		mov al, 0bfh
		stosw

		mov al, 0b3h
		mov ah, 8ah
		mov si, 9eh

		stosw      ; first r wall
		sub di, dx
		sub di, 2h    
		mov al, 0c3h
		add di, si
		stosw      ; second l wall
		mov al, 0b4h
		add di, dx
		stosw      ; second r wall
		sub di, dx
		sub di, 2h
		mov al, 0c4h
		stosw      ; l hor_line
		add di, dx
		sub di, 4h
		stosw      ; r hor_line
		sub di, dx
		add di, si
		mov al, 0b3h
		stosw      ; third l wall
    
		mov ah, 08ch
		mov al, 0c0h
		stosw

		mov al, 0c4h
		mov si, cx
		mov cx, dx
		shr cx, 1d
		sub cx, 2h
		rep stosw
		mov cx, si
		
		mov al, 0d9h
		stosw

		mov al, 0b3h
    		mov ah, 8ah
		mov si, 9eh

		stosw      ; third r wall

		mov al, 0c0h    ; ld_ang
		mov di, bx
		add di, 640d
		stosw

		mov al, 0d9h    ; rd_ang    
		add di, dx
		stosw

		add si, 2h
		mov di, bx
		add di, si
		add di, si
		add di, 6h
		mov bx, 82h
    
		mov ah, 08eh
		mov si, bx

whilye:		lodsb      ; print string
		stosw

 		dec cl
		jne whilye


		mov ax, 4c00h
		int 21h

end start