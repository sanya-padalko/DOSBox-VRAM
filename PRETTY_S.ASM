.model tiny
.code
org 100h

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

		mov ax, 05h
		call SkipStrings

		mov di, 6h 
		call PrintString

		push di
		push 0ah
		push 0ce03h
		call DrawHorLine
		pop di
		pop di
		pop di

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
; Entry:	[80h]     = lenght of string
;		[81h]     = space
;		[82h-...] = string
;		AH 	  = color of string's symbols
;		ES:[DI]   = index of memory, from which printing will start
; Result:	print string from command line (without first space) 
;		started from es:[di]
; Expected:	STRING ISN'T EMPTY and not too long ( < 126d symbols)
; Destruction:	DI, SI, AL, CL, BX
;=====================================================
PrintString	proc

		mov bx, 80h
		mov cl, [bx]
		dec cl
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
; Entry:	symb = symbol which will be printing
;		len = len of line
;		ind = index of memory, from which hor line will be drawing
;		(real index = es:[ind])
; Result:
; Expected: 	before returning adress in stack will be bp and before it will
;		be arguments	
; Destruction:	AX, BX, CX, DI
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