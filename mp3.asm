;MP3 -Falling Alphabets
;  Seunghoon Kim
;  10/12/2003
;
; University of Illinois, Urbana-Champaign
; Dept. of Electrical and Computer Engineering
;
; Version 1.0

        BITS    16

;====== SECTION 1: Define constants =======================================
		Escape	EQU		1Bh
        CR      EQU     0Dh             ; Carriage return
        LF      EQU     0Ah             ; Line feed
        BS      EQU     08h             ; Backspace


        KVEC    EQU     0024h           ; Location of Keyboard Vector
        TVEC    EQU     0070h           ; Location of User Timer Vector
        ROWS    EQU     25              ; Number of rows on screen
        COLS    EQU     80              ; Number of columns on screen


	;the masks for various flags
	EXIT_FLAG		equ	000001b
	RIGHT_KEY_FLAG		equ	000010b
	LEFT_KEY_FLAG		equ	000100b
	RIGHT_BUTTON_FLAG	equ	001000b
	LEFT_BUTTON_FLAG	equ	010000b
	USE_PARPORT_FLAG	equ	100000b


	;length of array (in elements) use to store letters to
	FALLING_LETTER_ARRAY_LENGTH	equ	5
	CHAR		EQU		0
	ROW		equ		1
	COL		equ		2

	;The scancodes for various keys
	LEFT_SCANCODE	equ 	75	;scancode for left arrow
	RIGHT_SCANCODE	equ 	77	;scancode for right arrow
	EXIT_SCANCODE	equ	1	;scancode for esc key

;====== SECTION 2: Declare external procedures ============================

EXTERN  ascbin, binasc, kbdin, kbdine, dspout, dspmsg, mp3xit

EXTERN  libMain, libInstallISR, libRestoreISR, libInitVideo, libKbdISR
EXTERN	libOutputParport, libUpdateBucket, libDisplayLevel, libClearScreenBottom
EXTERN	libRandom, libAddNewLetter, libDisplayBucket, libFallLetters
EXTERN	libInitParport, libReadParport


GLOBAL	Main, InstallISR, RestoreISR, InitVideo
GLOBAL	TmrISR, KbdISR
GLOBAL	OutputParport, UpdateBucket, DisplayLevel, ClearScreenBottom
GLOBAL	Random, AddNewLetter, DisplayBucket, FallLetters
GLOBAL	InitParport, ReadParport


GLOBAL  SavKOff, SavKSeg, SavTOff, SavTSeg, TickCount
GLOBAL	StartMsg, Flags, Level, FallCount, WinMsg
GLOBAL	FallingLetterArray,  NumberTable, BucketPosition

;====== SECTION 3: Define stack segment ===================================

SEGMENT stkseg STACK                    ; *** STACK SEGMENT ***
        RESB    64*8
stacktop:
        RESB    0                       ; NASM bug workaround

;====== SECTION 4: Define code segment ====================================

SEGMENT code                            ; *** CODE SEGMENT ***

;====== SECTION 5: Declare variables for main procedure ===================
MP3Msg		db 'ECE 291 MP3 -- The Falling Letters Game','$'
WinMsg		db 'YOU WIN!!','$'
StartMsg	db "Do you want to enable the parallel port? (y/n)", '$'


TickCount	db	0	;Timer interupt counter
FallCount	db	0	;Counter to slow letter movement
Level		db	0	;Level of game, goes from 0 to 9
BucketPosition	db	40	;Column of left side of bucket
Flags		db 	0	;Storage for various flags used by the game


SavTSeg		RESW	1	;Segment of old timer interupt routine
SavTOff		RESW	1	;Offset of old timer interupt routine
SavKSeg		RESW	1	;Segment of old timer interupt routine
SavKOff		RESW	1	;Offset of old timer interupt routine


;array of infomation for falling letters
FallingLetterArray times FALLING_LETTER_ARRAY_LENGTH*3 db 0


;used by random function
seed		RESW	1
random		RESW	1



;
C	equ 0x01
D	equ 0x02
E	equ 0x04
G	equ 0x08
F	equ 0x10
A	equ 0x20
B	equ 0x40

;Lookup table used for turing on LED's
NumberTable:
zero		db A|B|C|D|E|F
one		db B|C
two		db A|B|D|E|G
three		db A|B|C|D|G
four		db B|C|F|G
five		db A|C|D|F|G
six		db A|C|D|E|F|G
seven		db A|B|C
eight		db A|B|C|D|E|F|G
nine		db A|B|C|F|G



; You may declare additional variables here

;====== SECTION 6: Program initialization =================================

..start:
        MOV     AX, CS                  ; Initialize Default Segment register
        MOV     DS, AX
        MOV     AX, stkseg              ; Initialize Stack Segment register
        MOV     SS, AX
        MOV     SP, stacktop            ; Initialize Stack Pointer register

;====== SECTION 7: Your subroutines =======================================


;- Main ----------------------------------------------------
Main:
;	call 	libMain
;	call	mp3xit

	xor	bx, bx
	mov	dx, StartMsg
	call	dspmsg				; display StartMsg
	call	kbdine
	cmp	al, 79h
	je	.useParallel

.initialize
	call	InstallISR
	call	InitVideo

.mainLoop
	cmp	byte[Level], 9
	ja	.quit1				; loop until the game reaches past level 9
	cmp	byte[Flags], 01h
	je	.quit2				; loop stops when ESC is presssed
	cmp	byte[TickCount], 2
	jb	.mainLoop			; if (TickCount < 2), loop back to mainLoop
	sub	byte[TickCount], 2
	test	byte[Flags], 20h
	jnz	.parallelOn

.mainCheck1
	call	UpdateBucket
	call	DisplayLevel
	call	ClearScreenBottom
	call	DisplayBucket
	inc	byte[FallCount]
	cmp	byte[FallCount], 9		; if (FallCount >= 9), reset counter
	jae	.resetFallCount
.mainCheck2
	mov	cx, 100
	call	Random
	cmp	ax, 0
	jne	.mainLoop
	call	AddNewLetter			; randomly call AddNewLetter
	jmp	.mainLoop

.useParallel					; sets/resets USE_PARPORT_FLAG
	mov	byte[Flags], 20h
	call	InitParport
	jmp	.initialize

.parallelOn					; set of calls executed when parallel port is selected
	call	ReadParport
	call	OutputParport
	jmp	.mainCheck1

.resetFallCount
	mov	byte[FallCount], 0
	call	FallLetters
	jmp	.mainCheck2

.quit1
	mov	dx, WinMsg			; display WinMsg if game reaches past level 9
	call	dspmsg

.quit2
	call	RestoreISR
	call	mp3xit


;- InitParport ----------------------------------------------------
;- Initializes the parallel port so that it can be used
;- Inputs: None
;- Outputs: Control port (0x37a)
;- Calls: None
InitParport:
;	call libInitParport

	push	dx
	push	ax

	mov	dx, 037Ah		; set control port address to 037A
	mov	al, 02h			; set the ~Autofeed bit on the control port HIGH, everything else LOW
	out	dx, al			; output register AL to the control out latch

	pop	ax
	pop	dx
	ret


;- ReadParport ----------------------------------------------------
;- Reads in the input from the parallel port
;- Inputs: Parallel Port
;- Outputs: [Flags] - Movement Flags
;- Calls: NONE
ReadParport:
;	call libReadParport

	push	dx
	push	ax

	mov	dx, 0379h		; set status port address to 0379
	in	al, dx			; input into register AL via the status in buffer

	test	al, 110000b		; test if both keys are on
	jz	.release
	test	al, 100000b		; test if only right key is on
	jz	.updateRight
	test	al, 010000b		; test if only left key is on
	jz	.updateLeft
	test	al, 110000b		; test if neither keys are on
	jnz	.release
	jmp	.ReadDone

.updateRight
	or	byte[Flags], 08h	; set the RIGHT_BUTTON_FLAG (to 1) in [Flags]
	jmp	.ReadDone

.updateLeft
	or	byte[Flags], 10h	; set the LEFT_BUTTON_FLAG (to 1) in [Flags]
	jmp	.ReadDone

.release
	and	byte[Flags], 100110b	; clear both LEFT_BUTTON_FLAG and RIGHT_BUTTON_FLAG (to 0) in [Flags]

.ReadDone
	pop	ax
	pop	dx
	ret


;- OutputParport ----------------------------------------------------
;- Outputs the level onto the 7 segment LED on the parallel port.
;- Inputs: [Level] - current level of the game
;- 	   NumberTable - lookup table
;- Outputs: Writes to data port (0x378)
;- Calls: None
OutputParport:
;	call libOutputParport
;	ret

	push	bx
	push	ax
	push	dx

	xor	bx, bx
	mov	bl, byte[Level]
	mov	al, byte[NumberTable+bx]; set AL to a corresponding level value in numbertable
	mov	dx, 0378h		; set status port address to 0378
	out	dx, al			; output a byte from register aL to the Data Out Latch

	pop	dx
	pop	ax
	pop	bx

	ret


;- UpdateBucket ----------------------------------------------------
;- Updates the position of the bucket
;- Inputs: [Flags] - Movement Flags
;- Outputs: [BucketPosition] - current position of the bucket
;- Calls: NONE
UpdateBucket:
;	call libUpdateBucket

	push	ax
	mov	al, [Flags]

	test	al, 00010100b			; check the left flags
	jnz	.updateLeft
	test	al, 00001010b			; check the right flags
	jnz	.updateRight
	jmp	.updateBucketEnd

.updateLeft
	test	al, 00001010b			; if both left and right flags are on, no move
	jnz	.updateBucketEnd
	cmp	byte[BucketPosition], 5		; left boundary for the movement
	jbe	.updateBucketEnd
	dec	byte[BucketPosition]		; move to the left
	jmp	.updateBucketEnd

.updateRight
	cmp	byte[BucketPosition], 70	; right boundary for the movement
	jae	.updateBucketEnd
	inc	byte[BucketPosition]		; move to the right

.updateBucketEnd
	pop	ax
	ret


;- AddNewLetter ----------------------------------------------------
;- Adds a new letter on top of the screen
;- Inputs: None
;- Outputs: None
;- Calls: Random
AddNewLetter:
;	call 	libAddNewLetter

	push	ax
	push	bx
	push	cx

	mov	bx, FallingLetterArray
	mov	cx, FALLING_LETTER_ARRAY_LENGTH
.lp
	cmp	byte[bx], 41h			; see if any alphabet is stored in char
	jnb	.skip

	push	cx

	mov	cx, 26
	call	Random				; randomly generate an alphabet
	add	al, 41h
	mov	byte[bx+CHAR], al		; and store in char
	mov	byte[bx+ROW], 00h		; set row to 0

	mov	cx, 71
	call	Random				; randomly generate an integer between 0 and 70
	add	al, 5
	mov	byte[bx+COL], al		; and store in col

	pop	cx
	jmp	.AddNewLetterEnd		; ends if one is written
.skip
	add	bx, 3
	loop	.lp				; loops until it finally writes one or all arrays are filled

.AddNewLetterEnd
	pop	cx
	pop	bx
	pop	ax
	ret


;- FallLetters ----------------------------------------------------
;- Make the letter fall, and checks if the bucket catches the letter.
;- Inputs: [BucketPosition] - current position of the bucket
;- Outputs: [Level] - Game Level
;- Calls: NONE
FallLetters:
;	call libFallLetters
;	ret

	push	bx
	push	cx
	push	ax
	push	es
	push	bp
	push	dx

	mov	ax, 0B800h			; set the segment address for video memory
	mov	es, ax
	mov	bx, FallingLetterArray
	mov	cx, FALLING_LETTER_ARRAY_LENGTH
	inc	bx

.lp
	xor	ax, ax
	cmp	byte[bx-1], 41h			; check if any alphabet is stored in char
	jb	.fallEnd
	mov	al, byte[bx]
	mov	dl, 80				; set the position on the video memory
	mul	dl				; according to the row and col value in array
	xor	dx, dx
	mov	dl, byte[bx+1]
	add	ax, dx
	shl	ax, 1
	mov	bp, ax
	mov	word[es:bp], 0000h		; erase the original letter position
	inc	byte[bx]
	cmp	byte[bx], 19
	je	.checkIn			; if the letter is in green area, no need to redraw in updated position

	xor	ax, ax
	mov	al, byte[bx]
	mov	dl, 80				; set the position on the video memory
	mul	dl				; according to the row and col value in array
	xor	dx, dx
	mov	dl, byte[bx+1]
	add	ax, dx
	shl	ax, 1
	mov	bp, ax

	mov	al, byte[bx-1]
	mov	ah, 0Fh
	mov	word[es:bp], ax			; draw the letter in updated position
	jmp	.fallEnd

.checkIn
	xor	dx, dx				; if the ltter is in green area
	mov	dl, byte[bx+1]
	mov	byte[bx], 0			; reset row
	mov	byte[bx-1], 0			; reset char
	mov	byte[bx+1], 0			; reset column

	cmp	byte[BucketPosition], dl	; check if the letter is inside the bucket
	ja	.fallEnd
	mov	dh, byte[BucketPosition]
	add	dh, 6
	cmp	dh, dl
	jb	.fallEnd
	inc	byte[Level]			; increase the level if the letter is in the bucket

.fallEnd
	add	bx, 3
	loop	.lp

	pop	dx
	pop	bp
	pop	es
	pop	ax
	pop	cx
	pop	bx

	ret


;- DisplayLevel ----------------------------------------------------
;- Display the level on the top left corner of the screen
;- Inputs: [Level] - Game level
;- Outputs: Draws to screen
;- Calls:
DisplayLevel:
;	call libDisplayLevel

	push	ax
	push	es
	push	bx

	mov	ax, 0B800h		; set the segment address for video memory
	mov	es, ax
	mov	bx, 0000h		; set the offset address to 0

	mov	al, byte[Level]
	add	al, 30h			; convert the level value to ascii and store in al
	mov	ah, 9Fh			; set to blue backgound and white forground

	mov	word[es:bx], ax		; write the level number into the video memory

	pop	bx
	pop	es
	pop	ax

	ret


;- DisplayBucket ----------------------------------------------------
;- Draw image of bucket to correct part of the screen
;- Inputs: [BucketPosition] - current position of the bucket
;- Outputs: NONE
;- Calls: NONE
DisplayBucket:
;	call libDisplayBucket
;	ret
	push	ax
	push	bx
	push	cx
	push	es

	xor	bx, bx
	mov	bl, byte[BucketPosition]; set the offset addresss to the column value the BucketPosition holds
	shl	bl, 1
	add	bx, 80*19*2		; move the offset addresss to 20th line
	push	ax
	mov	ax, 0B800h		; set the segment address for video memory
	mov	es, ax
	pop	ax
	mov	cx, 5

.lp1
	mov	word[es:bx], 1C23h	; write the light red '#' letter with blue background
	add	bx, 12			; 7 characters wide, so move 6 spaces to the right
	mov	word[es:bx], 1C23h
	add	bx, 148			; move to the next line
	loop	.lp1			; finish drawing the first 5 lines

	mov	cx, 7
.lp2
	mov	word[es:bx], 1C23h	; draw the bottom part of the bucket
	add	bx, 2
	loop	.lp2

	pop	es
	pop	cx
	pop	bx
	pop	ax

	ret


;- ClearScreenBottom ----------------------------------------------------
;- Clears the bottom of the screen.
;- Inputs: None
;- Outputs: Draws to screen
;- Calls: NONE
ClearScreenBottom:
;	call libClearScreenBottom
;	ret

	push	bx
	push	cx
	push	ax
	push	es

	mov	bx, 80*19*2		; set the offset address to the start of the green area
	mov	cx, 80*6
	mov	ax, 0B800h		; set the segment address for video memory
	mov	es, ax

.lp
	mov	word[es:bx], 2200h	; clear the bottom area to a green background
	add	bx, 2
	loop	.lp

	pop	es
	pop	ax
	pop	cx
	pop	bx

	ret


;- KbdISR ----------------------------------------------------
;- Interrupt service routine to handle keyboard interrupt events
;- Inputs: Keyboard port
;- Outputs: [Flags] - Movement Flags
;- Calls: NONE
KbdISR:
;	jmp 	libKbdISR

	push	bx
	push 	ax 			; Save registers
	push 	ds 			;
	mov 	ax, cs 			; Make sure DS = CS
	mov 	ds, ax 			;
	in 	al, 60h 		; Get scan code

	cmp	al, 1			; compare with the scancodes for various keys
	je	.updateEsc
	cmp	al, 0CBh
	je	.releaseLeft
	cmp	al, 0CDh
	je	.releaseRight
	cmp	al, 75
	je	.updateLeft
	cmp	al, 77
	je	.updateRight

.Continue:
	in 	al, 61h 		; Send acknowledgment without
	or 	al, 10000000b 		; modifying the other bits.
	out 	61h, al 		;
	and 	al, 01111111b 		;
	out 	61h, al 		;
	mov 	al, 20h 		; Send End-of-Interrupt signal
	out 	20h, al 		;
	pop 	ds 			; Restore registers
	pop 	ax 			;
	pop	bx
	iret 				; End of handler

.updateLeft
	or	byte[Flags], 04h	; set the LEFT_KEY_FLAG (to 1) in [Flags]
	jmp	.Continue

.updateRight
	or	byte[Flags], 02h	; set the RIGHT_KEY_FLAG (to 1) in [Flags]
	jmp	.Continue

.updateEsc
	mov	byte[Flags], 01h	; set the the EXIT_FLAG in [Flags]
	jmp	.Continue

.releaseLeft
	and	byte[Flags], 111011b	; clear the LEFT_KEY_FLAG (to 0) in [Flags]
	jmp	.Continue

.releaseRight
	and	byte[Flags], 111101b	; clear the RIGHT_KEY_FLAG (to 0) in [Flags]
	jmp	.Continue


;- InstallISR ----------------------------------------------------
;- Saves the old interrupt service routines and installs the modified timer and keyboard service routines.
;- Inputs: cs, TmrISR, KbdISR, Interrupt vector table
;- Outputs: Interrupt Vector Table, SavKSeg,  SavKOff,  SavTSeg, SavTOff = addresses of old interrupt vector segments and offsets
;- Calls: None
InstallISR:
;	call libInstallISR
;	ret

	push	ax
	push	bx
	push	es

	cli						; disable interrupts

	mov	ax, 0000h
	mov	es, ax

	mov	bx, 0072h
	mov	ax, word[es:bx]
	mov	word[SavTSeg], ax			; write timer segment address to SavTSeg
	mov	bx, 0070h
	mov	ax, word[es:bx]
	mov	word[SavTOff], ax			; write timer offset address to SavTOff

	mov	bx, 0026h
	mov	ax, word[es:bx]
	mov	word[SavKSeg], ax			; write keyboard segment address to SavKSeg
	mov	bx, 0024h
	mov	ax, word[es:bx]
	mov	word[SavKOff], ax			; write keyboard offset address to SavKOff

	mov	ax, cs
	mov	bx, 0072h
	mov	word[es:bx], ax				; update timer segment address with cs
	mov	bx, 0026h
	mov	word[es:bx], ax				; update keyboard segment address with cs

	mov	ax, TmrISR
	mov	bx, 0070h
	mov	word[es:bx], ax				; update timer offset address with TmrISR
	mov	ax, KbdISR
	mov	bx, 0024h
	mov	word[es:bx], ax				; update keyboard offset address with KbdISR

	sti						; enable interrupts

	pop	es
	pop	bx
	pop	ax

	ret


;- RestoreISR ----------------------------------------------------
;- Restores the old keyboard and timer interrupt service routines.
;- Inputs: SavKSeg,  SavKOff,  SavTSeg, SavTOff = addresses of old interrupt vector segments and offsets
;- Outputs: Interrupt Vector Table
;- Calls: None
RestoreISR:
;	call libRestoreISR

	push	ax
	push	bx
	push	es

	cli						; disable interrupts

	mov	ax, 0000h
	mov	es, ax

	mov	bx, 0072h
	mov	ax, word[SavTSeg]
	mov	word[es:bx], ax				; restore timer segment address with SavTSeg
	mov	bx, 0026h
	mov	ax, word[SavKSeg]
	mov	word[es:bx], ax				; restore keyboard segment address with SavKSeg
	mov	bx, 0070h
	mov	ax, word[SavTOff]
	mov	word[es:bx], ax				; restore timer offset address with SavTOff
	mov	bx, 0024h
	mov	ax, word[SavKOff]
	mov	word[es:bx], ax				; restore keyboard offset address with SavKOff

	sti						; enable interrupts

	pop	es
	pop	bx
	pop	ax

	ret


;- InitVideo ----------------------------------------------------
;- Initialize mode 03h text mode video.
;- Inputs: NONE
;- Outputs: NONE
;- Calls: int 10h
InitVideo:
;	call libInitVideo

	mov	ah, 00h		; Clear screen to black background
	mov	al, 03h		; Set screen to 03h video mode
	int 	10h		; Set video mode
	ret


;- TmrISR ----------------------------------------------------
;- Inputs: NONE
;- Outputs: TickCount - interrupt counter
;- Calls: NONE
TmrISR:
	inc byte [cs:TickCount]  ;increment TickCount :-P
.done
	iret ;return from interupt :-)


;- Random ----------------------------------------------------
;- Inputs:	CX = Max value to return
;- Outputs: 	AX = random value in range from (CX-1) to 0
;- Calls:	NONE
Random
	push	dx
	push	bx
        mov     ax, word [seed]
        mov     bx, 37549

        mul     bx
        add     ax, 37747
        adc     dx, 0
        mov     bx, 65535
        div     bx
        mov     ax, dx
 	mov     word [seed], dx

        xor     dx, dx
        div     cx
        mov     ax, dx
	pop	bx
	pop	dx

        ret
