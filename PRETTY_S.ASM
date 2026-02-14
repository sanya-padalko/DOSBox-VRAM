.model tiny
.code
org 100h

start: 		call Main
		call Exit

;=====================================================
; Entry:	-
; Result:	Program executed
; Expected:	-
; Destruction:	AX
;=====================================================
Main		proc

		mov ax, 05h
		call SkipStrings

		mov bx, 0h
		mov es:[bx], 03h
		mov es:[bx + 1], 0ceh

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
; Result:	string from command line (without first space) will be printed
; Expected:	STRING ISN'T EMPTY and not too long ( < 126d symbols)
; Destruction:	ES, DI, DS, SI, AX, CX, BX
;=====================================================
PrintString	proc

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