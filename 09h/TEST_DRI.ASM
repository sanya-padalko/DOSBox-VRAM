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
		push sp ds
		mov ah, 0fah
		mov bx, 200h
		mov cx, 300h
		mov dx, 400h
		push 0abbah
		pop ds
		mov ax, 0dadah
		mov es, ax
		mov si, 0eeeeh
		mov di, 0acdch
		mov bp, 0edah
		mov sp, 0dedh

@@looop:
		in al, 60h
		cmp al, STOP_KEY
		je @@end_loop
		jmp @@looop

@@end_loop:	in al, 61h
		or al, 80h
		out 61h, al
		and al, not 80h
		out 61h, al
		
		pop ds sp

		mov ax, 4c00h
		int 21h

end start
