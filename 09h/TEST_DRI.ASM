.model tiny
.code
org 100h

START_KEY	equ 25h
STOP_KEY	equ 01h

start:
  @@first_loop:
		in al, 60h
		cmp al, START_KEY
		je @@set
		jmp @@first_loop

	@@set:	
		mov al, 0h
		mov ah, 1h
		mov bx, 200h
		mov cx, 300h
		mov dx, 400h

@@looop:
		in al, 60h
		cmp al, STOP_KEY
		je @@end_loop
		
		in al, 61h
		or al, 80h
		out 61h, al
		and al, not 80h
		out 61h, al
		jmp @@looop

@@end_loop:	in al, 61h
		or al, 80h
		out 61h, al
		and al, not 80h
		out 61h, al

end start
