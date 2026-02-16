.model tiny
.code
org 100h

STR_BEF_FRAME	equ 0ah

STRING_COLOR	equ 09eh
STRING_LBOUND	equ 8ac4h
STRING_RBOUND	equ 8ac4h

FRAME_UP_SYMB	equ 8a03h
FRAME_DN_SYMB	equ 8ac4h
UPLEFT_ANGLE	equ 8a2fh
UPRIGH_ANGLE	equ 8a5ch
DNLEFT_ANGLE	equ 8a5ch
DNRIGH_ANGLE	equ 8a2fh

INT_UP_SYMB	equ 8cc4h	; internal frame constants
INT_DN_SYMB	equ 8cc4h
INT_UL_SYMB	equ 8cdah
INT_UR_SYMB	equ 8cbfh
INT_DL_SYMB	equ 8cc0h
INT_DR_SYMB	equ 8cd9h

WALL_SYMB	equ 8ab3h
CL_WALL_SYMB	equ 8ac3h	; left symbol of central wall
CR_WALL_SYMB	equ 8ab4h	; right symbol of central wall

SYMB_OFFSET	equ 2d
ARGUE_SIZE	equ 2h
END_CODE	equ 4c00h
ES_STR_DELTA	equ 10d		; delta for ES to change string
VMEM_ADDRESS	equ 0b800h

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

		mov bx, 81h
		call SkipSpaces
		call GetNumber		; AX = len of string
		call SkipSpaces
		mov cx, ax	
		
  		push bx			; save index of string's begin

		mov ax, STR_BEF_FRAME
		call SkipStrings
		add cl, 2d
		call CalcOffset

		call DrawExtFrame	
		call DrawIntFrame
		pop bx
		call PrintBdString

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	CX	= len of string
;		BX	= index of string's begin
;
; Result:	Printing bounded string
;
; Expected:	ES:[DI]	= right shift and offset
;
; Destruction:	AX, BX, CX, DI, SI
;=====================================================
PrintBdString	proc

		mov si, bx			; saving len of string

		mov ax, STRING_LBOUND
		mov bx, STRING_RBOUND
		push cx
		call DrawEmpWalls
		add di, SYMB_OFFSET
		mov ah, STRING_COLOR
		mov bx, si
		call PrintString

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	CX	  = lenght of string
;		BX    	  = index of first string symbol
;		AH 	  = color of string's symbols
;		ES:[DI]   = index of memory, from which printing will start
;
; Result:	print string from command line (without first space) 
;		started from es:[di]
;
; Expected:	STRING ISN'T EMPTY and not too long ( < 126d symbols)
;		ES:[DI]	  = right shift and offset
;		DS:[SI]	  = first symbol after string
;		DX	  = 0
;		AL	  = last string symbol
;		
;
; Destruction:	DI, SI, AL, DX
;=====================================================
PrintString	proc

		mov si, bx
		mov dx, cx

       @@print:	lodsb
		stosw

		dec dx
		jne @@print

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	-
;
; Result:	External frame will be drawing
;		ES:[DI]	= old ES:[DI] shifted to the right down diagonally
;		CX	= len of string inside frame
;
; Expected:	ES:[DI]	= right shift and offset
;
; Destruction:	AX, BX, CX, DX, DI, SI, ES
;=====================================================
DrawExtFrame	proc

		push 3h				; empty_strings
		push cx				; len of hor line
		push FRAME_DN_SYMB
		push FRAME_UP_SYMB
		mov ax, UPLEFT_ANGLE
		mov bx, UPRIGH_ANGLE
		mov cx, DNLEFT_ANGLE
		mov dx, DNRIGH_ANGLE
		call DrawHorLines		; external frame's upside and downside
		mov ax, 1d
		call ChangeString

		push cx
		mov ax, WALL_SYMB
		mov bx, CL_WALL_SYMB
		mov cx, CR_WALL_SYMB
		call DrawWalls			; external frame's walls
		sub cx, 2d
		add di, SYMB_OFFSET

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	-
;
; Result:	Internal frame will be drawing
;
; Expected:	ES:[DI]	= right shift and offset
;
; Destruction:	AX, BX, CX, DX, DI, ES
;=====================================================
DrawIntFrame	proc

		push 1h
		push cx
		push INT_UP_SYMB
		push INT_DN_SYMB
		mov ax, INT_UL_SYMB
		mov bx, INT_UR_SYMB
		mov cx, INT_DL_SYMB
		mov dx, INT_DR_SYMB
		call DrawHorLines		; internal frame
		mov ax, 1d
		call ChangeString

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX 	= wall's symbol
;		BX 	= left central wall's symbol
;		CX 	= right central wall's symbol
;	[stack]	len 	= length of skipped symbols between walls
;
; Result:	DX 	= AX
;		SI 	= BX
;		BX 	= AX
;		CX 	= len
;
; Expected:	DI 	= right offset
;
; Distruction:	DX, BX, SI, CX
;=====================================================
DrawWalls	proc	len
		push bp
		mov bp, sp

		mov dx, ax			; draw first walls
		mov si, bx
		mov bx, ax
		push len
		call DrawEmpWalls
		mov ax, 1d
		call ChangeString
		
		mov ax, si			; draw second walls
		mov bx, cx
		push len
		call DrawEmpWalls
		mov ax, 1d
		call ChangeString
		
		mov ax, dx			; draw third walls
		mov bx, ax
		push len
		call DrawEmpWalls
		mov ax, -2d
		call ChangeString
		
		pop bp				; stack clearing
		pop ax
		pop cx
		push ax
		mov ax, dx
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX 	= left wall symbol
;		BX 	= right wall symbol
;	[stack]	len 	= count of empty symbols between walls	
;
; Result:	AX 	= returning address
;		BX	= 2 * len
;
; Expected:	DI	= right offset
;
; Destruction:	AX, BX
;=====================================================
DrawEmpWalls	proc len
		push bp
		mov bp, sp

		push di
		stosw			; left wall
		mov ax, bx
		mov bx, len
		sal bx, 1d
		add di, bx			; skip empty columns
		stosw			; right wall
		pop di

		pop bp
		pop ax
		add sp, 1 * ARGUE_SIZE
		push ax
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
;	[stack]	len	= len of middle part
;	[stack]	emp_str	= the count of string between horisontal lines
;
; Result:	AX 	= returning address
;		BX 	= 80h
;		SI 	= old CX (from Entry)
;		CX 	= len
;
; Expected:	argument's direction -> CDECL, len >= 0
;		DI 	= right offset
;
; Destruction:	AX, BX, CX, DX, SI
;=====================================================
DrawHorLines	proc	mid1, mid2, len, emp_str
		push bp
		mov bp, sp

		mov si, cx

		push ax
		push bx
		push mid1
		push len
		push di
		call BoundedHorLine
		mov ax, emp_str
		add ax, 1d
		call ChangeString	; first hor line and skipped empty strings
		
		push si
		push dx
		push mid2
		push len
		push di
		call BoundedHorLine
		mov cx, len		
		mov ax, emp_str
		mov bx, -1d
		mul bx
		sub ax, 1d
		call ChangeString	; second hor line and returning to begin

		pop bp	
		pop ax
		add sp, 4h * ARGUE_SIZE	; stack clearing
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
		stosw			; left bound symbol
		mov ax, [bp + 8]
		push di
		push cx
		push ax
		call DrawHorLine		; horisontal line
		mov ax, [bp + 10]
		stosw			; right bound symbol

		pop di
		pop di
		pop di
		
		sub di, SYMB_OFFSET
		
		pop bp
		pop ax
		add sp, 5h * ARGUE_SIZE
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
; Entry:	AX 	= count of empty string before frame
;
; Result:	ES on begin of (AX + 1)th string
;
; Expected:	1 < AX < 21, also expect that 2 string will be entered
;
; Destruction:	AX, ES
;=====================================================
SkipStrings	proc

		push bx
		push dx

		add ax, 02h
		mov bx, ES_STR_DELTA
		mul bx
		add ax, VMEM_ADDRESS
		mov es, ax		

		pop dx
		pop bx

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX 	= the number of lines to change to
;
; Result: 	ES 	= old ES + AX strings
;		AX 	= ES
;
; Expected:	ES	= right shift
;
; Destruction:	ES, AX
;=====================================================
ChangeString	proc

		push bx
		push dx
		mov bx, ES_STR_DELTA
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
; Entry:	CX 	= length of string
;
; Result:	DI 	= right offset for string with len CX
;
; Expected:	0 <= CX < 76d
;
; Destruction:	DI
;=====================================================
CalcOffset	proc
		
		mov di, 76d
		sub di, cx
		shr di, 1d
		sal di, 1d

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry: 	[80h] 	= length of string
;
; Result:	CX 	= length of string
;		BX 	= 80h
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
; Entry:	[BX]	= first symbol of number
;
; Result:	AX	= number (or [80h] if [BX] != digit)
;		BX	= first index after number (or old BX if [BX] != digit)
;
; Expected:	[BX]	= digit
;		Number separates spaces
;
; Destruction: 	AX, BX, SI
;=====================================================
GetNumber	proc

		push dx
		mov ax, 0h

		cmp byte ptr [bx], '0'
		jb @@not_num
		cmp byte ptr [bx], '9'
		ja @@not_num
		
	@@base:	mov si, bx
		
	@@add_c:mov bx, 10d
		mul bx
		add al, byte ptr [si]
		sub al, '0'
		add si, 1h
		cmp byte ptr [si], ' '
		jne @@add_c

		mov bx, si
		jmp @@end

  @@not_num:	mov si, 80h
		mov al, byte ptr [si]
		sub al, 1d

	@@end:	pop dx		
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	BX	= starting index from which skipping spaces
;
; Result:	[BX]	!= symbol of space	
;
; Expected:	80h <= BX < 100h
;
; Destruction:	BX
;=====================================================
SkipSpaces	proc

		cmp byte ptr [bx], ' '
		jne @@not_space

	@@skip:	add bx, 1h
		cmp byte ptr [bx], ' '
		je @@skip
		
@@not_space:
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

		mov ax, END_CODE
		int 21h

		endp
;-----------------------------------------------------



end start