.model tiny
.code
org 100h

STRING_COLOR	equ 1eh
FRAME_HOR_COL	equ 0ah
FRAME_WALL_COL	equ 0eh
INT_FRAME_COL	equ 0ch		; color of internal frame
STR_BOUND_COL	equ 09h

BYTE_SHIFT	equ 8h
SYMB_OFFSET	equ 2d
ARGUE_SIZE	equ 2h
END_CODE	equ 4c00h
ES_STR_DELTA	equ 10d		; delta for ES to change string
VMEM_ADDRESS	equ 0b800h

NULL_CODE	equ 30h
ALPH_ADD_CODE	equ 37h

ADX_KEY		equ 57h			; F11
SEG_KEY		equ 58h			; F12
IND_KEY		equ 29h			; ` (OEM 3)
ALL_KEY		equ 2bh			; \ (OEM 5)
ESC_KEY		equ 36h			; RSHIFT
UP_ARR_KEY	equ 48h
DN_ARR_KEY	equ 50h
LT_ARR_KEY	equ 4bh
RT_ARR_KEY	equ 4dh
PRINT_REG_LEN	equ 9h

FRAME_WIDTH	equ 26d
FRAME_HEIGHT	equ 10h

FRAME_LODSB	macro		; AL = next frame symbol, and increase BX
		mov al, byte ptr cs:[bx]
		inc bx
		endm

REG_PRINT	macro reg	; saved reg value, [bx] = next reg, ax = reg
		push reg
		call PrintReg
		pop ax
		add bx, 9h
		endm

locals @@

;=====================================================
; Entry:	-
;
; Result:	In int[09] saved new address
;
; Expected:	Old int[09] = original int[09] (from DOS)
;
; Destruction:	AX, BX, ES, DI
;=====================================================
start:		mov bx, 81h
		call SkipSpaces
		call GetNumber
		mov FRAME_TYPE, ax		; setting FRAME_TYPE
		
		call DrawFrame
		mov ax, cs
       		mov es, ax
		mov di, offset Old09Ofs
		mov ax, 0h
		mov ds, ax
		mov si, 4 * 09h			; offset:segment -> 4 bytes
		movsw
		movsw				; saving Old 09 Address

		mov di, offset Old08Ofs
		mov si, 4 * 08h			; offset:segment -> 4 bytes
		movsw
		movsw				; saving Old 08 Address

		mov ax, 0h
		mov es, ax
		mov bx, 4 * 09h
		cli
		mov es:[bx], offset New09
		mov ax, cs
		mov es:[bx + 2], ax
		sti

		mov ax, 0h
		mov es, ax
		mov bx, 4 * 08h
		cli
		mov es:[bx], offset New08
		mov ax, cs
		mov es:[bx + 2], ax
		sti

		mov ax, 3100h
		mov dx, offset Eoppp
		shr dx, 4h
		inc dx
		int 21h
;-----------------------------------------------------



;=====================================================
; !!!NEW CODE FOR 08 INTERRUPTING !!!
;=====================================================
New08		proc

		push ax bx cx dx es ds si di
		push cs
		pop ds
		cmp cs:[IS_FRAME], 1h
		je @@redr
		jmp @@noth

  @@redr:
  		call GetIp
  save_ip:	call SavingRegs
		add sp, 1d * 2h
		call RedrawFrame

  @@noth:
		mov al, 20h
		out 20h, al

		pop di si ds es dx cx bx ax
		db 0eah
Old08Ofs	dw 0
Old08Seg	dw 0
		ret
		endp
;-----------------------------------------------------



;=====================================================
; !!! NEW CODE FOR 09 INTERRUPTING !!!
;
; Entry:	-
;
; Result:	printed value of register in frame (if al = ADX_KEY)
;		- (else)
;
; Expected:	-
;
; Destruction:	-
;=====================================================
New09		proc

		push ds es bx ax
		push cs
		pop ds
		jmp @@check

  @@frame:
  		mov [KEY_TYPE], al
  		cmp IS_FRAME, 0h
		je @@onfr
		jmp exit_09

  @@onfr:
  		call TurnOnFrame
		mov IS_FRAME, 1h
		jmp exit_09

  @@offfr:
  		call TurnOffFrame
		mov IS_FRAME, 0h
		jmp exit_09

  @@check:
  		in al, 60h
		cmp al, ADX_KEY
		je @@frame
		cmp al, ESC_KEY
		je @@offfr
		cmp al, UP_ARR_KEY
		je arrow
		cmp al, DN_ARR_KEY
		je arrow
		cmp al, LT_ARR_KEY
		je arrow
		cmp al, RT_ARR_KEY
		je arrow
		jmp @@not_s

  exit_09:
  		in al, 61h
		and al, not 80h
		out 61h, al
		or al, 80h
		out 61h, al

  @@not_s:
  		mov al, 20h
		out 20h, al

		pop ax bx es ds
		db 0eah
Old09Ofs	dw 0
Old09Seg	dw 0

		endp
;-----------------------------------------------------



;=====================================================
; Saving (ip value + 3) on the top of stack
;=====================================================
GetIp		proc

		jmp save_ip

		ret
		endp
;-----------------------------------------------------



;=====================================================
;=====================================================
ProcessArrow	proc


  @@up:		dec X_FRAME
		jmp @@back
  @@dn:		inc X_FRAME
		jmp @@back
  @@left:	dec Y_FRAME
		jmp @@back
  @@right:	inc Y_FRAME
		jmp @@back

  arrow:
  		cmp cs:[IS_FRAME], 1h
		jne exit_09

  		call TurnOffFrame
		in al, 60h
		cmp al, UP_ARR_KEY
		je @@up
		cmp al, DN_ARR_KEY
		je @@dn
		cmp al, LT_ARR_KEY
		je @@left
		cmp al, RT_ARR_KEY
		je @@right

  @@back:
		call TurnOnFrame
		jmp exit_09

		ret
		endp
;-----------------------------------------------------



;=====================================================
;=====================================================
TurnOnFrame	proc
		push ax bx cx

		mov ax, X_FRAME
		call SkipStrings
		mov di, Y_FRAME
		sal di, 1d				; set es:[di]
		mov bx, offset SAVE_BUF
		mov cx, FRAME_WIDTH * FRAME_HEIGHT
		call PrintFromMem			; VMEM -> SAVE

		call UpdateFrame			; DRAW

		mov ax, X_FRAME
		call SkipStrings
		mov di, Y_FRAME
		sal di, 1d				; set es:[di]
		mov bx, offset DRAW_BUF
		mov cx, FRAME_WIDTH * FRAME_HEIGHT	; DRAW -> VMEM
		call PrintToMem

		pop cx bx ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
;=====================================================
TurnOffFrame	proc
		push ax bx cx dx es di

		mov ax, X_FRAME
		call SkipStrings
		mov di, Y_FRAME
		sal di, 1d				; set es:[di]
		call SaveDiff				; VMEM - DRAW

		mov ax, X_FRAME
		call SkipStrings
		mov di, Y_FRAME
		sal di, 1d				; set es:[di]
		mov bx, offset SAVE_BUF
		mov cx, FRAME_WIDTH * FRAME_HEIGHT	; SAVE -> VMEM
		call PrintToMem

		pop di es dx cx bx ax

		ret
		endp
;-----------------------------------------------------



;=====================================================
;=====================================================
RedrawFrame	proc
		push ax bx dx es di

		mov ax, word ptr cs:[X_FRAME]
		call SkipStrings
		mov di, word ptr cs:[Y_FRAME]
		sal di, 1d				; set es:[di]
		call SaveDiff				; VMEM - DRAW

		call UpdateFrame			; DRAW

		mov ax, word ptr cs:[X_FRAME]
		call SkipStrings
		mov di, word ptr cs:[Y_FRAME]
		sal di, 1d				; set es:[di]
		mov bx, offset DRAW_BUF
		mov cx, FRAME_WIDTH * FRAME_HEIGHT	; DRAW -> VMEM
		call PrintToMem

		pop di es dx bx ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	-
;
; Result:	in video memory printed ESC_SAVE[]
;
; Expected:	ES:[DI] = right shift and offset
;
; Destruction:	-
;=====================================================
SaveDiff	proc
		push es ax cx bx si di

		mov ax, FRAME_WIDTH
		mov cx, FRAME_HEIGHT
		mov bx, -1h

  @@printing:
		inc bx
		push ax
		mov al, es:[di]
		cmp byte ptr cs:[DRAW_BUF + bx], al
		je @@cont
		mov byte ptr cs:[SAVE_BUF + bx], al

	@@cont:
		pop ax
		dec ax
		jne @@next
		dec cx
		je @@printed
		mov ax, 1d
		call ChangeString
		mov ax, FRAME_WIDTH
		pop di
		push di
		jmp @@printing

	@@next:	inc di
		jmp @@printing

  @@printed:
		pop di si bx cx ax es

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	CX	= count of symbols, which will be printed
;		BX	= index of string's begin
;
; Result:	string will be printed in VMEM
;
; Expected:	ES:[DI]	= right shift and offset
;
; Destruction:	BX, CX
;=====================================================
PrintToMem	proc
		push ax es si di
		mov si, di
		add si, FRAME_WIDTH

  @@loop:	mov al, cs:[bx]
  		mov es:[di], al
		inc bx
		dec cx
		je @@endPrint
		inc di
		cmp di, si
		jne @@loop
		mov ax, 1d
		call ChangeString
		pop di
		push di
		jmp @@loop

  @@endPrint:
		pop di si es ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
; The inverse PrintToMem function
;=====================================================
PrintFromMem	proc
		push ax es si di
		mov si, di
		add si, FRAME_WIDTH

  @@loop:	mov al, es:[di]
  		mov cs:[bx], al
		inc bx
		dec cx
		je @@endPrint
		inc di
		cmp di, si
		jne @@loop
		mov ax, 1d
		call ChangeString
		pop di
		push di
		jmp @@loop

  @@endPrint:
		pop di si es ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	-
;
; Result:	registers printed in REG_VIEWS
;
; Expected:	-
;
; Destruction:	-
;=====================================================
SavingRegs	proc

		push ax
		push bx
		mov bx, offset AX_VIEW
		push ax
		call PrintReg
		pop ax
		add bx, 9h

		call PrintReg		; old BX is already in stack
		add bx, 9h

		REG_PRINT cx
		REG_PRINT dx
		REG_PRINT si
		REG_PRINT di
		REG_PRINT bp
		mov ax, sp
		add ax, 3d * 2h
		REG_PRINT ax
		REG_PRINT ds
		REG_PRINT es
		REG_PRINT cs
		push bp
		mov bp, sp
		mov ax, [bp + 8]
		sub ax, 3d		; intstr. call size
		pop bp
		REG_PRINT ax

		pop bx
		pop ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:[stack]	value of register
;
; Result:	value will print in string
;	   !!!	VALUE WON'T DELETED FROM STACK !!!
;
; Expected:	(DS:)[BX] = index of output's start
;
; Destruction:	DL
;=====================================================
PrintReg	proc 	value
		push bp
		mov bp, sp

		push ax
		push dx
		mov ax, value
		mov dh, 4h
		add bx, 7h

	@@digit:
		mov dl, al
		and dl, 0fh
		cmp dl, 0ah
		jnl @@ab_9

		add dl, NULL_CODE
		jmp @@com_part
	@@ab_9:
		add dl, ALPH_ADD_CODE
@@com_part:
		mov byte ptr cs:[bx], dl
		shr ax, 4h
		dec bx
		dec dh
		jne @@digit

		add bx, -3h
		pop dx
		pop ax
		pop bp
		ret
		endp
;-----------------------------------------------------



;=====================================================
;=====================================================
UpdateFrame	proc
		push ax bx cx dx es di ds si

		push cs
		pop ds
		push cs
		pop es
		mov di, offset DRAW_BUF
		add di, FRAME_WIDTH
		add di, FRAME_WIDTH
		add di, 2d

		call RegSettings
		mov dx, bx		; [dx] = begin of first register from group

		;mov ax, X_FRAME
		;call SkipStrings
		;mov di, Y_FRAME
		;sal di, 1d		; setting es:[di]

		mov ax, cs:[FRAME_TYPE]
		mov bx, offset FRAME_TYPES
		add bx, ax
		sal ax, 4d
		add bx, ax
		add bx, 0fh		; [bx] = string's left bound symbol

		mov cl, PRINT_REG_LEN
		mov ch, 0h
		;add cl, 2d
		mov ax, REG_COUNT

  @@print_str:
		push ax
		call PrintBdString
		add dx, PRINT_REG_LEN
		dec bx			; return to string bound symbols
		dec bx			;
		add di, 4d
		pop ax
		dec ax
		jne @@print_str

		pop si ds di es dx cx bx ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	-
;
; Result:	frame will be drawn
;
; Expected:	-
;
; Destruction:	-
;==================================================
DrawFrame	proc
		push ax bx cx dx es di ds si

		push cs
		pop ds
		push cs
		pop es
		mov di, offset DRAW_BUF

		mov ax, cs:[FRAME_TYPE]
		mov bx, offset FRAME_TYPES
		add bx, ax
		sal ax, 4d
		add bx, ax		; setting type of frame

		mov cx, PRINT_REG_LEN + 2h

		call DrawExtFrame
		call DrawIntFrame

  @@end_draw:	pop si ds di es dx cx bx ax
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AL	  = pressed key
;
; Result:	BX	  = right offset (on the begin of reg's views)
;	[var]	REG_COUNT = right count of regs (from 1 to 4)
;
; Expected:	REG_COUNT - word variable
;
; Destruction:	BX
;=====================================================
RegSettings	proc

		jmp @@regALL
		cmp byte ptr cs:[KEY_TYPE], ADX_KEY
		je @@regADX
		cmp byte ptr cs:[KEY_TYPE], SEG_KEY
		je @@regSEG
		cmp byte ptr cs:[KEY_TYPE], IND_KEY
		je @@regIND
		cmp byte ptr cs:[KEY_TYPE], ALL_KEY
		je @@regALL
		jmp @@regALL

	@@regADX:
		mov word ptr cs:[REG_COUNT], 0ch
		mov bx, offset AX_VIEW
		jmp @@end

	@@regSEG:
		mov word ptr cs:[REG_COUNT], 4h
		mov bx, offset DS_VIEW
		jmp @@end

	@@regIND:
		mov word ptr cs:[REG_COUNT], 4h
		mov bx, offset SI_VIEW
		jmp @@end

	@@regALL:
		mov word ptr cs:[REG_COUNT], 0ch
		mov bx, offset AX_VIEW

@@end:		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	CX	= len of string
;		DX	= index of string's begin
;
; Result:	Printing bounded string
;
; Expected:	ES:[DI]	= right shift and offset
;
; Destruction:	AX, BX, CX, DI, SI
;=====================================================
PrintBdString	proc

		mov ah, STR_BOUND_COL
		FRAME_LODSB
		stosw
		push dx
		push bx
		mov ah, STRING_COLOR
		mov bx, dx
		call PrintString
		pop bx
		pop dx
		mov ah, STR_BOUND_COL
		FRAME_LODSB
		stosw

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
;		ES:[DI]	  = right shift and offset (on first symbol after string)
;		DS:[SI]	  = first symbol after string
;		DX	  = 0
;		AL	  = last string symbol
;
;
; Destruction:	DI, SI, AL, DX
;=====================================================
PrintString	proc
		push ds
		push cs
		pop ds
		mov si, bx
		mov dx, cx

       @@print:	lodsb
		stosw

		dec dx
		jne @@print

		pop ds
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	-
;
; Result:	External frame will be drawing
;		ES:[DI]	= old ES:[DI] shifted to the right down diagonally
;		CX	= len of string inside frame
;		[BX]	= upleft angle of internal frame
;
; Expected:	ES:[DI]	= right shift and offset
;		[BX]	= upleft angle of external frame
;
; Destruction:	AX, BX, CX, DX, DI, SI, ES
;=====================================================
DrawExtFrame	proc

		mov ax, word ptr [REG_COUNT]
		add ax, 2h
		push ax				; empty_strings
		push cx				; len of hor line
		mov ah, FRAME_HOR_COL
		FRAME_LODSB
		push ax
		FRAME_LODSB
		push ax
		mov cl, FRAME_HOR_COL
		call DrawHorLines		; external frame's upside and downside
		add di, FRAME_WIDTH

		mov ax, word ptr [REG_COUNT]
		add ax, 2h
		push cx
		push ax
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

		mov ah, INT_FRAME_COL
		push REG_COUNT
		push cx
		FRAME_LODSB
		push ax
		FRAME_LODSB
		push ax
		mov cl, INT_FRAME_COL
		call DrawHorLines		; internal frame
		add di, FRAME_WIDTH

		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX 		= wall's symbol
;	[stack]	len 		= length of skipped symbols between walls
;	[stack]	cnt		= count of walls
;
; Result:	BX 		= index of first unused frame symbol
;		(exp.: [BX] = upleft angle of int. frame)
;		SI 		= wall's symbol
;		BX 		= AX
;		CX 		= len
;
; Expected:	DI 		= right offset
;		[BX]	 	= wall's symbol
;		[BX + 1] 	= central right wall symbol
;		[BX + 2] 	= central left wall symbol
;
; Distruction:	BX, SI, CX
;=====================================================
DrawWalls	proc	cnt, len
		push bp
		mov bp, sp

		push dx
		mov ah, FRAME_WALL_COL
		FRAME_LODSB
		mov si, ax
		mov dx, cnt

	@@wall:
		mov ax, si
		mov cx, ax
		push len
		call DrawEmpWalls
		add di, FRAME_WIDTH
		dec dx
		jne @@wall

		mov ax, cnt
	@@rets:
		sub di, FRAME_WIDTH
		dec ax
		jne @@rets

		pop dx
		add bx, 2h

		pop bp
		pop ax
		pop cx
		pop cx
		push ax
		mov ax, dx
		ret
		endp
;-----------------------------------------------------



;=====================================================
; Entry:	AX 	= left wall symbol
;		CX 	= right wall symbol
;	[stack]	len 	= count of empty symbols between walls
;
; Result:	AX 	= returning address
; 		CX 	= 2 * len
;
; Expected:	DI	= right offset
;
; Destruction:	AX, CX
;=====================================================
DrawEmpWalls	proc len
		push bp
		mov bp, sp

		push di
		stosw			; left wall
		mov ax, cx
		mov cx, len
		sal cx, 1d
		add di, cx		; skip empty columns
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
; Entry:	CL 	= color of horisontal lines
;	[stack]	mid1	= symbol of middle of upside
;	[stack]	mid2	= symbol of middle of downside
;	[stack]	len	= len of middle part
;	[stack]	emp_str	= the count of string between horisontal lines
;
; Result:	AX 	= returning address
;		BX 	= first unused frame symbol
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

		mov ch, 0h
		mov si, cx

		mov ah, cl
		FRAME_LODSB
		push ax
		FRAME_LODSB
		push ax
		push mid1
		push len
		push di
		call BoundedHorLine	; first hotisontal line
		mov ax, emp_str
		inc ax

	@@loop:
		add di, FRAME_WIDTH	; skip empty strings
		dec ax
		jne @@loop

		mov ax, si
		sal ax, BYTE_SHIFT
		FRAME_LODSB
		push ax
		FRAME_LODSB
		push ax
		push mid2
		push len
		push di
		call BoundedHorLine
		mov ax, emp_str
		inc ax

	@@loop2:
		sub di, FRAME_WIDTH	; second hor line and returning to begin
		dec ax
		jne @@loop2
		mov cx, len

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
; Result:	AX	= number (or 0 if [BX] != digit)
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
		je @@enc
		cmp byte ptr [si], 0dh
		je @@enc
		jmp @@add_c

	@@enc:	mov bx, si
		jmp @@end

  @@not_num:	mov ah, 0h

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
;
; Result:	Program ended
;
; Expected:	-
;
; Destruction:	AX
;=====================================================
Exit		proc

		mov ax, END_CODE
		int 21h

		endp
;-----------------------------------------------------

FRAME_TYPES	db 'ÄÄ/\\/³Ã´ÄÄÚ¿ÀÙÄÄ'
		db '²²²²²²²²²°°°°°°²²'
		db 'ûûûûûûûûû        '
		db '±±±±±±±±±', 1eh, 1fh, 4 DUP(09h), 'ÎÎ'

AX_VIEW  	db '³AX:', 4 DUP (0h), '³'
BX_VIEW  	db '³BX:', 4 DUP (0h), '³'
CX_VIEW  	db '³CX:', 4 DUP (0h), '³'
DX_VIEW  	db '³DX:', 4 DUP (0h), '³'

SI_VIEW  	db '³SI:', 4 DUP (0h), '³'
DI_VIEW  	db '³DI:', 4 DUP (0h), '³'
BP_VIEW  	db '³BP:', 4 DUP (0h), '³'
SP_VIEW  	db '³SP:', 4 DUP (0h), '³'

DS_VIEW  	db '³DS:', 4 DUP (0h), '³'
ES_VIEW  	db '³ES:', 4 DUP (0h), '³'
CS_VIEW  	db '³CS:', 4 DUP (0h), '³'
IP_VIEW  	db '³IP:', 4 DUP (0h), '³'
REG_COUNT	dw 0ch

FRAME_TYPE	dw 0h
KEY_TYPE	db ADX_KEY
X_FRAME		dw 0h
Y_FRAME		dw 0h
IS_FRAME	db 0h

SAVE_BUF	db (FRAME_WIDTH * FRAME_HEIGHT) DUP (0h)
DRAW_BUF	db (FRAME_WIDTH * FRAME_HEIGHT) DUP (0h)

end_of_prog:				; for page navigation

Eoppp:

end start
