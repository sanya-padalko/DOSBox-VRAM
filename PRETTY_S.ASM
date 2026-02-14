.model tiny
.code
org 100h

STR_LENGTH	equ 10d

locals @@

start: 		call Main
		call Exit


;=====================================================
; Entry:	-
; Result:	Program executed
; Expected:	-
; Destruction:	AX, BX, ES, DI, DS, SI, CL
;=====================================================
Main		proc

		mov ax, 0ch
		call SkipStrings

		call GetLength
		call CalcOffset

		add cl, 2d

		push 8a2fh			; upside
		push 8a5ch
		push 8ac4h
		push cx
		push di
		call BoundedHorLine

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX = count of empty string before frame
; Result:	ES on begin of (AX + 1)th string
; Expected:	1 < AX < 21, also expect that 2 string will be entered
; Destruction:	AX, ES, BX
;=====================================================
SkipStrings	proc

		add ax, 02h
		mov bx, 0ah
		mul bx
		add ax, 0b800h
		mov es, ax		

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	CX = length of string
;
; Result:	DI = right offset for string with len CX
;
; Expected:	0 <= CX < 76d
;
; Destruction:	DI
;=====================================================
CalcOffset	proc
		
		mov di, 76d
		sub di, cx
		shr di, 2d
		sal di, 1d

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	[80h]     = lenght of string
;		[81h]     = space
;		[82h-...] = string
;		AH 	  = color of string's symbols
;		ES:[DI]   = index of memory, from which printing will start
;
; Result:	print string from command line (without first space) 
;		started from es:[di]
;
; Expected:	STRING ISN'T EMPTY and not too long ( < 126d symbols)
;
; Destruction:	DI, SI, AL, CX, BX
;=====================================================
PrintString	proc

		call GetLength
		add bx, 02h
		mov si, bx

       @@print:	lodsb
		stosw

		dec cl
		jne @@print

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry: 	[80h] = length of string
;
; Result:	CX = length of string
;		BX = 80h
;
; Expected: 	-
;
; Destruction:	BX, CX
;=====================================================
GetLength	proc

		mov bx, 80h
		mov cl, [bx]
		mov ch, 0h
		
		ret
		endp
;-----------------------------------------------------



;=====================================================
; BoundedHorLine(lbound, rbound, symb, len, ind)
;
; Entry:	lbound	= symbol for line's start
;		rbound	= symbol for line's end
;		symb	= symbol of line's middle
;		len	= len of line's middle
;		ind	= index from which line will be printing (es:[ind])
;
; Result:	di	= ind
;		AX	= returing address
;		CX	= 0
;
; Expected:	argument direction -> Pascal, len >= 0
;
; Destruction:	AX, CX, DI
;=====================================================
BoundedHorLine	proc

		push bp
		mov bp, sp

		mov di, [bp + 4]
		mov cx, [bp + 6]
		mov ax, [bp + 12]
		
		stosw
		
		mov ax, [bp + 8]
		
		push di
		push cx
		push ax
		call DrawHorLine

		mov ax, [bp + 10]
		stosw

		pop di
		pop di
		pop di
		
		sub di, 2d
		
		pop bp
		pop ax
		add sp, 5h * 2h
		push ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
; DrawHorLine(symb, len, ind)
;
; Entry:	symb	= symbol which will be printing
;		len	= len of line
;		ind	= index of memory, from which hor line will be drawing
;		(real index = es:[ind])
;
; Result:	ES:[DI]	= index of first byte after horisontal line
;		CX	= 0
;		AX	= symb
;
; Expected: 	argument direction -> CDECL, len >= 0
;
; Destruction:	AX, CX, DI
;=====================================================
DrawHorLine	proc symb, len, ind

		push bp
		mov bp, sp

		mov ax, symb
		mov cx, len
		mov di, ind

		rep stosw

		pop bp
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	-
; Result:	Program ended
; Expected:	-
; Destruction:	AX
;=====================================================
Exit		proc

		mov ax, 4c00h
		int 21h

		ret
		endp
;-----------------------------------------------------



end start