.model tiny
.code
org 100h

Start:		mov ax, 0b814h
		mov es, ax
		mov ax, 0ce03h
		
		mov di, 0h
		mov cx, 100h
		rep stosw
		
		mov ax, 4c00h
		int 21h

end Start
