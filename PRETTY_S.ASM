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

		mov bx, 3h
		call PrintString

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
;		BX 	  = count of columns, will be skipped before printing
; Result:	print string from command line (without first space) 
;		started from es:[bx]
; Expected:	STRING ISN'T EMPTY and not too long ( < 126d symbols)
; Destruction:	ES, DI, DS, SI, AL, CL, BX
;=====================================================
PrintString	proc

		mov di, bx
		sal di, 1d
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