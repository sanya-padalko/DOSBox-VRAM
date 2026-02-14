.model tiny
.code
org 100h

STR_LENGTH	equ 10d

locals @@

start: 		call Main
		call Exit


;=====================================================
; Entry:	-
;
; Result:	Program executed
;
; Expected:	-
;
; Destruction:	AX, BX, ES, DI, DS, SI, CL
;=====================================================
Main		proc

		mov ax, 02h
		call SkipStrings

		mov ax, 8a2fh
		mov bx, 8a5ch
		mov cx, bx
		mov dx, ax
		push 8ac4h
		push 8a03h
		call DrawHorLines
		
		mov ax, 1d
		call ChangeString

		mov ax, 8ab3h
		mov bx, 8ac3h
		mov cx, 8ab4h
		call DrawWalls

		call GetLength
		add di, 2d
		push 8cdah
		push 8cbfh
		push 8cc4h
		push cx
		push di
		call BoundedHorLine

		mov ax, 2d
		call ChangeString

		call GetLength
		push 8cc0h
		push 8cd9h
		push 8cc4h
		push cx
		push di
		call BoundedHorLine

		mov ax, -1d
		call ChangeString

		mov ax, 8ac4h
		stosw
		
		mov ah, 0ceh
		call PrintString

		mov ax, 8ac4h
		stosw

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX = count of empty string before frame
;
; Result:	ES on begin of (AX + 1)th string
;
; Expected:	1 < AX < 21, also expect that 2 string will be entered
;
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
; Entry:	AX = the number of lines to change to
;		ES = ...
; Result: 	ES = old ES + AX strings
;		AX = ES
; Expected:	-
;
; Destruction:	ES, AX
;=====================================================
ChangeString	proc

		push bx
		push dx
		mov bx, 10d
		mul bx
		
		mov bx, es
		add ax, bx
		mov es, ax

		pop dx
		pop bx
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
		dec cl
		
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX = wall's symbol
;		BX = left central wall's symbol
;		CX = right central wall's symbol
;
; Result:	DX = CX
;		SI = AX
;
; Expected:	DI = right offset
;
; Distruction:	DX, SI
;=====================================================
DrawWalls	proc
		mov dx, cx
		mov si, bx
		call GetLength
		add cl, 2d
		sal cx, 1d

		mov bx, si
		mov si, ax
		
		stosw
		add di, cx
		stosw
		sub di, cx
		sub di, 4d

		mov ax, 1d
		call ChangeString
		
		mov ax, bx
		stosw
		add di, cx
		mov ax, dx
		stosw
		sub di, cx
		sub di, 4d

		mov ax, 1d
		call ChangeString
		
		mov ax, si
		stosw
		add di, cx
		stosw
		sub di, cx
		sub di, 4d

		mov cx, dx
		
		mov ax, -2d
		call ChangeString
		mov ax, si

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX 	= symbol of upleft angle
;		BX 	= symbol of upright angle
;		CX 	= symbol of downleft angle
;		DX 	= symbol of downright angle
;	[stack]	mid1	= symbol of middle of upside 
;	[stack]	mid2	= symbol of middle of downside
;
; Result:	AX = returning address
;		BX = 80h
;		SI = CX
;		DI = right offset
;
; Expected:	argument's direction -> Pascal
;
; Destruction:	AX, BX, SI, DI
;=====================================================
DrawHorLines	proc	mid1, mid2
		push bp
		mov bp, sp

		mov si, cx

		push ax
		push bx
		push mid1
		call GetLength
		call CalcOffset
		add cl, 2d
		push cx
		push di
		call BoundedHorLine

		call GetLength
		add cl, 2
		
		mov ax, 04h
		call ChangeString
		
		push si
		push dx
		push mid2
		push cx
		push di
		call BoundedHorLine
		
		mov ax, -4d
		call ChangeString

		mov cx, si
		pop bp	
		pop ax
		add sp, 4d
		push ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
; BoundedHorLine(lbound, rbound, symb, len, ind)
;
; Entry:[stack]	lbound	= symbol for line's start
;	[stack]	rbound	= symbol for line's end
;	[stack]	symb	= symbol of line's middle
;	[stack]	len	= len of line's middle
;	[stack]	ind	= index from which line will be printing (es:[ind])
;
; Result:	DI	= ind
;		AX	= returing address
;		CX	= 0
;
; Expected:	argument's direction -> Pascal, len >= 0
;
; Destruction:	AX, CX
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
; Entry:[stack]	symb	= symbol which will be printing
;	[stack]	len	= len of line
;	[stack]	ind	= index of memory, from which hor line will be drawing
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