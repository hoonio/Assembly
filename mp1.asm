; MP1 - Maze
;  Seunghoon Kim
;  9/11/2003
;
; Version 1.0



	BITS 16

;====== SECTION 1: Define constants =======================================

DOWNARROW	EQU	80
RIGHTARROW	EQU	77
LEFTARROW	EQU	75
UPARROW		EQU	72

CR			EQU	0Dh
LF			EQU	0Ah


;====== SECTION 2: Declare external procedures ============================

; from the 291 library
EXTERN  kbdine, dspmsg

; these you will have to replace
EXTERN	 libDrawMaze, libGetChar, libUpdateMaze, libAttemptMove, libClearScreen, mp1xit

; to allow l.ibMP1 to work
GLOBAL	DrawMaze, GetChar, ClearScreen, AttemptMove, UpdateMaze
GLOBAL	maze, easyclear, PersonRow, PersonCol, Row, Col, Char, KeyPressed

;====== SECTION 3: Define stack segment ===================================

SEGMENT stkseg STACK                    ; *** STACK SEGMENT ***
        resb      64*8
stacktop:
        resb      0                     ; work around NASM bug


;====== SECTION 4: Define code segment ====================================

SEGMENT code                            ; *** CODE SEGMENT ***


;====== Declare variables for main procedure ===================

maze	db '##########',CR,LF,'$'	; the little person in the maze
		db '#*    ####',CR,LF,'$'	; is the asterisk
		db '####     #',CR,LF,'$'
		db '## ###  ##',CR,LF,'$'
		db '#     # ##',CR,LF,'$'
		db '#####    #',CR,LF,'$'
		db '#  ##### #',CR,LF,'$'
		db '##  ###  #',CR,LF,'$'
		db '###     ##',CR,LF,'$'
		db '##########',CR,LF,'$'

easyclear	db CR,LF,'$'		; you can print this out a bunch of times
					; to "clear" the screen (because we're not
					; yet working directly with the video
					; memory

PersonRow	db 1			; coordinates of the
PersonCol	db 1			; person

Row			db 0			; used to pass info
Col			db 0			; into DrawChar
Char		db 0			; and get info from
							; GetChar (see documentation)

KeyPressed	db 0			; you can use to store keypresses


;====== Program initialization =================================

..start:
        mov     ax, cs
        mov     ds, ax
        mov     ax, stkseg
        mov     ss, ax
        mov     sp, stacktop


;====== Main procedure =========================================
; this is the given skeleton of the program
; MazeLoop is where the program spends all of its time.

MAIN:
	mov	ax, 3
	int	10h

	call	MazeInit		; Draw maze for the first time
	call	MazeLoop		; Use this for the real program

	mov	ax, 3
	int	10h

	call    mp1xit			; exit to DOS

MazeInit:
	call	DrawMaze
	ret

MazeLoop:
	call 	kbdine
	mov		[KeyPressed], al
	cmp		byte [KeyPressed], 27
	jz		.done
	call	AttemptMove
	jmp		MazeLoop
.done
	ret


DrawMaze
	;call	libDrawMaze
	;ret

	call	ClearScreen		; clear the screen by using ClearScreen subroutine
	mov		dx, maze		; load maze to register dx
	mov		si, 0			; register si reset to count upto 13, the length of line
	pusha					; push to save all the register values
	call	DispMaze		; calls subroutine DispMaze
	popa					; load all the register values back
	ret

DispMaze
	call	dspmsg			; display a line of maze
	add		dx, 13			; move to the next line
	inc		si				; increment si value(count)
	cmp		si, 10			; compare si value to 10
	jb		DispMaze		; execute DispMaze again if < 10 lines
	ret

GetChar
	;call	libGetChar
	;ret

	mov		al, byte [Row]	; get row address
	mov		bl, 0Dh			; load 13
	mul		bl				; multiply number of rows with 13
	add		al, byte [Col]	; add number of columns to al
	add		ax, maze		; add maze address to offset
	mov		bx, ax			; move ax to the base
	mov		bl, byte[bx]	; load the variable in bx to bl
	mov		byte [Char], bl	; update char with bl
	ret

ClearScreen
	;call libClearScreen
	;ret

	mov		si, 0			; si value reset for loop count upto 25
	call	ClearLoop		; calls subroutine ClearLoop
	ret

ClearLoop
	mov		dx, easyclear	; load easyclear to dx
	pusha
	call	dspmsg			; clears one line
	popa
	inc		si				; increment si value(count)
	cmp		si, 25			; compare si value to 25
	jb		ClearLoop		; execute ClearLoop again if < 25 times
	ret


AttemptMove
	;call	libAttemptMove
	;ret


	mov		bh,	byte [PersonRow]			; get row address
	mov		bl,	byte [PersonCol]			; get column address
	cmp		byte [KeyPressed], DOWNARROW	; compare with down arrow
	je		IncRow							; jump to increment row function
	cmp		byte [KeyPressed], RIGHTARROW	; compare with right arrow
	je		IncCol							; jump to increment column function
	cmp		byte [KeyPressed], LEFTARROW	; compare with left arrow
	je		DecCol							; jump to decrement column function
	cmp		byte [KeyPressed], UPARROW		; compare with up arrow
	je		DecRow							; jump to decrement row function
	jmp		AttemptMove2					; jump to AttemptMove2

IncRow
	inc bh									; increment bh
	jmp		AttemptMove2					; jump to AttemptMove2

IncCol
	inc bl									; increment bl
	jmp		AttemptMove2					; jump to AttemptMove2

DecRow
	dec bh									; decrement bh
	jmp		AttemptMove2					; jump to AttemptMove2

DecCol
	dec bl									; decrement bl
	jmp		AttemptMove2					; jump to AttemptMove2

AttemptMove2
	mov		byte [Row], bh					; load the new row address from bh
	mov		byte [Col], bl					; load the new column address from bl
	call	GetChar							; call GetChar to check if the move is valid
	cmp		byte [Char], 20h				; compare Char to space character
	jne		AttemptMove3					; jump to AttemptMove3 if not equal to a space
	call	UpdateMaze						; update the mze

AttemptMove3
	call	DrawMaze						; clear and draw the maze again
	ret

UpdateMaze
	;call	libUpdateMaze
	;ret

	push	ax							; bakcup ax
	push	bx							; backup bx

	mov		al,	byte [PersonRow]		; get row address
	mov		bl, 0Dh						; load 13
	mul		bl							; multiply 13 to row address
	mov		bl, byte [PersonCol]		; add column address to bl
	mov		bh, 0						; reset bh to 0
	add		bx, ax
	mov		byte [bx + maze], 20h		; clears the old asterisk from the maze

	mov		al,	byte [Row]				; get row address
	mov		bl, 0Dh						; load 13
	mul		bl							; multiply 13 to row address
	mov		bl, byte [Col]				; add column address to bl
	mov		bh, 0						; reset bh to 0
	add		bx, ax
	mov		byte [bx + maze], '*'		; place the new asterisk in the maze

	mov		bh,	[Row]					; retrieve row address
	mov		bl,	[Col]					; retrieve column address
	mov		[PersonRow], bh				; update PersonRow
	mov		[PersonCol], bl				; update PersonCol

	pop		bx							; restore bx
	pop		ax							; restore ax

	ret
