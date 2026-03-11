.model tiny
.code
org 100h

STOP_KEY	equ 01h

start:
		mov bx, 2222h
		mov cx, 3333h
		mov dx, 4444h
		mov si, 5555h
		mov di, 6666h
		mov bp, 7777h
		mov sp, 8888h
		push 9999h
		pop ds
		mov ax, 0deadh
		mov es, ax
		mov ax, 0c0ffh
		mov ss, ax
		mov ax, 1111h

@@looop:
		in al, 60h
		cmp al, STOP_KEY
		je @@end_loop
		mov al, 11h
		jmp @@looop

@@end_loop:	mov ax, 4c00h
		int 21h

end start
