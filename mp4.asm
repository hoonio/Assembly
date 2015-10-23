; ECE 291 Fall 2003 MP4
; -- Paint291 --
;
; Completed By:
;  Ki Chung
;  Seunghoon Kim
;  Gi Hyun Ko
;  Hyun J Jeong
;
; University of Illinois Urbana Champaign
; Dept. of Electrical & Computer Engineering
;
; Ver 1.0

%include "lib291.inc"
%include "libmp4.inc"

	BITS 32

	GLOBAL _main

;EXTERN	_LoadPNG

; Define Contstants

	DOWNARROW	EQU	80
	RIGHTARROW	EQU	77
	LEFTARROW	EQU	75
	UPARROW		EQU	72

	CANVAS_X	EQU	20
	CANVAS_Y	EQU	20

	NUM_MENU_ITEMS	EQU	11

	BKSP		EQU	8
	ESC		EQU	1
	ENTERKEY	EQU	13
	SPACE		EQU	57
	LSHIFT		EQU	42
	RSHIFT		EQU	54


	SECTION .bss

_GraphicsMode	resw	1	; Graphics mode #

_kbINT		resb	1	; Keyboard interrupt #
_kbIRQ		resb	1	; Keyboard IRQ
_kbPort		resw	1	; Keyboard port

_MouseSeg	resw	1       ; real mode segment for MouseCallback
_MouseOff	resw	1	; real mode offset for MouseCallback
_MouseX		resw	1       ; X coordinate position of mouse on screen
_MouseY		resw	1       ; Y coordinate position of mouse on screen

_ScreenOff	resd	1	; Screen image offset
_CanvasOff	resd	1	; Canvas image offset
_OverlayOff	resd	1	; Overlay image offset
_FontOff	resd	1	; Font image offset
_MenuOff	resd	1	; Menu image offset
_TitleOff	resd	1	; Title Bar image offset

_MPFlags	resb	1	; program flags
				; Bit 0 - Exit program
				; Bit 1 - Left mouse button (LMB) status: set if down, cleared if up
				; Bit 2 - Change in LMB status: set if button status
				;         moves from pressed->released or vice-versa
				; Bit 3 - Right shift key status: set if down, cleared if up
				; Bit 4 - Left shift key status: set if down, cleared if up
				; Bit 5 - Key other than shift was pressed
				; Bit 6 - Not Used Anymore
				; Bit 7 - Status of chosen color: set if obtained with user input,
                                ;         cleared if obtained with eyedrop (you do not have to deal
				;         with this - the library code uses it)

_MenuItem	resb	1	; selected menu item

; line algorithm variables
_x		resw	1
_y		resw	1
_dx		resw	1
_dy		resw	1
_lineerror	resw	1
_xhorizinc	resw	1
_xdiaginc	resw	1
_yvertinc	resw	1
_ydiaginc	resw	1
_errordiaginc	resw	1
_errornodiaginc	resw	1

; circle algorithm variables
_radius		resw	1
_circleerror	resw	1
_xdist		resw	1
_ydist		resw	1

; flood fill variables
_PointQueue	resd	1
_QueueHead	resd	1
_QueueTail	resd	1

_key		resb	1


	SECTION .data


; Required image files
_FontFN		db	'font.png',0
_MenuFN		db	'menu.png',0
_TitleFN	db	'title.png',0

; Defined color values
_CurrentColor	dd	0ffff0000h	; current color
_ColorBlue	dd	0ff0033ffh
_ColorWhite	dd	0ffffffffh
_ColorBlack	dd	0ff000000h
_ColorHalfBlack dd	0cc000000h

_buffer		db	'       ','$'

_ColorString1	db	'Enter numerical values for','$'
_ColorString2	db	'each channel (ARGB), and','$'
_ColorString3	db	'separate each number by a','$'
_ColorString4	db	'space (ex. 127 255 255 0).','$'

_QwertyNames
	db	0	; filler
	db	0,'1','2','3','4','5','6','7','8','9','0','-','=',BKSP
	db	0, 'q','w','e','r','t','y','u','i','o','p','[',']',ENTERKEY
	db	0,'a','s','d','f','g','h','j','k','l',';',"'","`"
	db	0,'\','z','x','c','v','b','n','m',",",'.','/',0,'*'
	db	0, ' ', 0, 0,0,0,0,0,0,0,0,0,0 ; F1-F10
	db	0,0	; numlock, scroll lock
	db	0, 0, 0, '-'
	db	0, 0, 0, '+'
	db	0, 0, 0, 0
	db	0, 0; sysrq
_QwertyNames_end resb 0

_QwertyShift
	db	0	; filler
	db	0,'!','@','#','$','%','^','&','*','(',')','_','+',BKSP
	db	0, 'Q','W','E','R','T','Y','U','I','O','P','{','}',ENTERKEY
	db	0,'A','S','D','F','G','H','J','K','L',':','"','~'
	db	0,'|','Z','X','C','V','B','N','M',"<",'>','?',0,'*'
	db	0, ' ', 0, 0,0,0,0,0,0,0,0,0,0 ; F1-F10
	db	0,0	; numlock, scroll lock
	db	0, 0, 0, '-'
	db	0, 0, 0, '+'
	db	0, 0, 0, 0
	db	0, 0; sysrq
_QwertyShift_end resb 0

_TextInputString	times 80 db 0,'$'
_ColorInputString	times 15 db 0,'$'

_RoundingFactor	dd	000800080h, 00000080h


	SECTION .text


_main
	call	_LibInit

	; Allocate Screen Image buffer
	invoke	_AllocMem, dword 640*480*4
	cmp	eax, -1
	je	near .memerror
	mov	[_ScreenOff], eax

	; Allocate Canvas Image buffer
	invoke	_AllocMem, dword 480*400*4
	cmp	eax, -1
	je	near .memerror
	mov	[_CanvasOff], eax

	; Allocate Overlay Image buffer
	invoke	_AllocMem, dword 480*400*4
	cmp	eax, -1
	je	near .memerror
	mov	[_OverlayOff], eax

	; Allocate Font Image buffer
	invoke	_AllocMem, dword 2048*16*4
	cmp	eax, -1
	je	near .memerror
	mov	[_FontOff], eax

	; Allocate Menu Image buffer
	invoke	_AllocMem, dword 400*100*4
	cmp	eax, -1
	je	near .memerror
	mov	[_MenuOff], eax

	; Allocate Title Bar Image buffer
	invoke	_AllocMem, dword 640*20*4
	cmp	eax, -1
	je	near .memerror
	mov	[_TitleOff], eax

	; Allocate Point Queue
	invoke	_AllocMem, dword 480*400*4*4
	cmp	eax, -1
	je	near .memerror
	mov	[_PointQueue], eax

	; Load image files
	invoke	_LoadPNG, dword _FontFN, dword [_FontOff], dword 0, dword 0
	invoke	_LoadPNG, dword _MenuFN, dword [_MenuOff], dword 0, dword 0
	invoke	_LoadPNG, dword _TitleFN, dword [_TitleOff], dword 0, dword 0

	; Graphics init
	invoke	_InitGraphics, dword _kbINT, dword _kbIRQ, dword _kbPort
	test	eax, eax
	jnz	near .graphicserror

	; Find graphics mode: 640x480x32, allow driver-emulated modes
	invoke	_FindGraphicsMode, word 640, word 480, word 32, dword 1
	mov	[_GraphicsMode], ax

	; Keyboard/Mouse init
	call	_InstallKeyboard
	test	eax, eax
	jnz	near .keyboarderror
	invoke	_SetGraphicsMode, word [_GraphicsMode]
	test	eax, eax
	jnz	.setgraphicserror
	call	_InstallMouse
	test	eax, eax
	jnz	.mouseerror

	; Show mouse cursor
	mov	dword [DPMI_EAX], 01h
	mov	bx, 33h
	call	DPMI_Int

	call	_MP4Main

	; Shutdown and cleanup

.mouseerror
	call	_RemoveMouse

.setgraphicserror
	call	_UnsetGraphicsMode

.keyboarderror
	call	_RemoveKeyboard

.graphicserror
	call	_ExitGraphics

.memerror
	call	_MP4LibExit
	call	_LibExit
	ret


;--------------------------------------------------------------
;--          Replace Library Calls with your Code!           --
;--          Do not forget to add Function Headers           --
;--------------------------------------------------------------


;------------------------------------------------------------------------------------------------------------------
;-- dword PointInBox(word X, word Y, word BoxULCornerX, word BoxULCornerY, word BoxLRCornerX, word BoxLRCornerY) --
;------------------------------------------------------------------------------------------------------------------
; Inputs : X - x coordinate of point in question
;          Y - y coordinate of point in question
;          BoxULCornerX - x coordinate of upper-left hand corner of box
;          BoxULCornerY - y coordinate of upper-left hand corner of box
;          BoxLRCornerX - x coordinate of lower-right hand corner of box
;          BoxLRCornerY - y coordinate of lower-right hand corner of box
; Outputs : -
; Returns : 1 if BoxULCornerX <= X <= BoxLRCornerX and BoxULCornerY <= Y <= BoxLRCornerY; 0 otherwise
; Calls : -
; - determines if the point (X, Y) is located in the box formed by the points (BoxULCornerX, BoxULCornerY) and
;   (BoxLRCornerX, BoxLRCornerY)
proc _PointInBox
.X		arg	2
.Y		arg	2
.BoxULCornerX	arg	2
.BoxULCornerY	arg	2
.BoxLRCornerX	arg	2
.BoxLRCornerY	arg	2

;	invoke	_libPointInBox, word [ebp+.X], word [ebp+.Y], word [ebp+.BoxULCornerX], word [ebp+.BoxULCornerY], word [ebp+.BoxLRCornerX], word [ebp+.BoxLRCornerY]

	mov	ax, [.X + ebp]			; check X if inside box
	cmp	ax, [.BoxULCornerX + ebp]	;
	jb	.outsideOfBox			;
	cmp	ax, [.BoxLRCornerX + ebp]	;
	ja	.outsideOfBox			;

	mov	ax, [.Y + ebp]			; check Y if inside box
	cmp	ax, [.BoxULCornerY + ebp]	;
	jb	.outsideOfBox			;
	cmp	ax, [.BoxLRCornerY + ebp]	;
	ja	.outsideOfBox			;

	mov	eax, 1
	jmp	.done

.outsideOfBox
	mov	eax, 0

.done
	ret

endproc
_PointInBox_arglen	EQU	12

;-------------------------------------------------------------------------------------
;-- dword GetPixel(dword *DestOff, word DestWidth, word DestHeight, word X, word Y) --
;-------------------------------------------------------------------------------------
; Inputs : DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          X - x coordinate of point
;          Y - y coordinate of point
; Outputs : -
; Returns : color of the pixel located at (X, Y) in the buffer; otherwise 0 if the
;           point (X, Y) is not within the boundary of the buffer
; Calls : _PointInBox
; - gets the color of the pixel located at the point (X, Y) in the buffer pointed by DestOff
proc _GetPixel
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2

;	invoke	_libGetPixel, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y]

	invoke	_PointInBox, word [.X + ebp], word [.Y + ebp], word 0, word 0, word [.DestWidth + ebp], word [.DestHeight + ebp]
	cmp	eax, 0
	je	.outsideBoundary

	movzx	eax, word [.DestWidth + ebp]
	movzx	ebx, word [.Y + ebp]
	mul	ebx				; (DestWidth * Y) + X
	movzx	ebx, word [.X + ebp]		;
	add	eax, ebx
	shl	eax, 2				; each pixel 4 byte
	add	eax, [.DestOff + ebp]
	mov	eax, [eax]

.outsideBoundary
	ret

endproc
_GetPixel_arglen	EQU	12

;--------------------------------------------------------------------------------------------------
;-- void DrawPixel(dword *DestOff, word DestWidth, word DestHeight, word X, word Y, dword Color) --
;--------------------------------------------------------------------------------------------------
; Inputs : DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          X - x coordinate of point
;          Y - y coordinate of point
;          Color - color of pixel to draw
; Outputs : pixel drawn to buffer
; Returns : -
; Calls : _PointInBox
; - draws a pixel with color Color at point (X, Y) in the buffer pointed to by DestOff
proc _DrawPixel
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
.Color		arg	4

;	invoke	_libDrawPixel, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y], dword [ebp+.Color]

	invoke	_PointInBox, word [.X + ebp], word [.Y + ebp], word 0, word 0, word [.DestWidth + ebp], word [.DestHeight + ebp]
	test	eax, eax
	jz	.outsideBoundary

	movzx	eax, word [.DestWidth + ebp]
	movzx	ebx, word [.Y + ebp]
	mul	ebx				; (DestWidth * Y) + X
	movzx	ebx, word [.X + ebp]		;
	add	eax, ebx
	shl	eax, 2				; each pixel 4 byte
	add	eax, [.DestOff + ebp]
	mov	ebx, [.Color + ebp]
	mov	[eax], ebx

.outsideBoundary
	ret

endproc
_DrawPixel_arglen	EQU	16

;---------------------------------------------------------------------------------------------------------------------
;-- void DrawLine(dword *DestOff, word DestWidth, word DestHeight, word X1, word Y1, word X2, word Y2, dword Color) --
;---------------------------------------------------------------------------------------------------------------------
; Inputs : DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          X1 - x coordinate of start point
;          Y1 - y coordinate of start point
;          X2 - x coordinate of end point
;          Y2 - y coordinate of end point
;          Color - color of line to draw
; Outputs : line drawn to buffer
; Returns : -
; Calls : _DrawPixel
; - draws a line with color Color from point (X1, Y1) to (X2, Y2) in the buffer pointed to by DestOff
proc _DrawLine
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X1		arg	2
.Y1		arg	2
.X2		arg	2
.Y2		arg	2
.Color		arg	4

;	invoke	_libDrawLine, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X1], word [ebp+.Y1], word [ebp+.X2], word [ebp+.Y2], dword [ebp+.Color]

	mov	ax, [.X1 + ebp]		; abs(X2 - X1)
	mov	bx, [.X2 + ebp]		;
	cmp	ax, bx			;
	jl	.X2Greater		;
	sub	ax, bx			;
	mov	[_dx], ax		;
	jmp	.calc_dy		;
					;
.X2Greater				;
	sub	bx, ax			;
	mov	[_dx], bx		;

.calc_dy
	mov	ax, [.Y1 + ebp]		; abs(Y2 - Y1)
	mov	bx, [.Y2 + ebp]		;
	cmp	ax, bx			;
	jl	.Y2Greater		;
	sub	ax, bx			;
	mov	[_dy], ax		;
	jmp	.doneCalc_dx_dy		;
					;
.Y2Greater				;
	sub	bx, ax			;
	mov	[_dy], bx		;

.doneCalc_dx_dy
	mov	ax, [_dx]
	mov	bx, [_dy]
	cmp	ax, bx
	jb	._dxLessThan_dy
	movzx	ecx, ax			;
	inc	ecx			; numpixels = ecx = dx + 1
	shl	bx, 1			;
	mov	[_errornodiaginc], bx	; _errornodiaginc = 2 * dy
	sub	bx, ax			;
	mov	[_lineerror], bx	; _lineerror = (2 * dy) - dx
	mov	bx, [_dy]
	sub	bx, ax			;
	shl	bx, 1			;
	mov	[_errordiaginc], bx	; _errordiaginc = 2 * (dy - dx)
	mov	word [_xhorizinc], 1
	mov	word [_xdiaginc], 1
	mov	word [_yvertinc], 0
	mov	word [_ydiaginc], 1
	jmp	.correctVars

._dxLessThan_dy
	movzx	ecx, bx			;
	inc	ecx			; numpixels = ecx = dy + 1
	shl	ax, 1			;
	mov	[_errornodiaginc], ax	; _errornodiaginc = 2 * dx
	sub	ax, bx			;
	mov	[_lineerror], ax	; _lineerror = (2 * dx) - dy
	mov	ax, [_dx]
	sub	ax, bx			;
	shl	ax, 1			;
	mov	[_errordiaginc], ax	; _errordiaginc = 2 * (dx - dy)
	mov	word [_xhorizinc], 0
	mov	word [_xdiaginc], 1
	mov	word [_yvertinc], 1
	mov	word [_ydiaginc], 1

.correctVars
	mov	ax, [.X1 + ebp]
	cmp	ax, [.X2 + ebp]
	jle	.checkY
	neg	word [_xhorizinc]
	neg	word [_xdiaginc]

.checkY
	mov	ax, [.Y1 + ebp]
	cmp	ax, [.Y2 + ebp]
	jle	.draw
	neg	word [_yvertinc]
	neg	word [_ydiaginc]

.draw
	mov	ax, [.X1 + ebp]
	mov	bx, [.Y1 + ebp]
	mov	dx, [_lineerror]

.loopDraw
	push	ax
	push	bx
	push	dx
	invoke	_DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
	pop	dx
	pop	bx
	pop	ax
	cmp	dx, 0
	jge	.lineerrorNotNegative
	add	dx, [_errornodiaginc]	; update _lineerror
	add	ax, [_xhorizinc]	; update x
	add	bx, [_yvertinc]		; update y
	jmp	.done

.lineerrorNotNegative
	add	dx, [_errordiaginc]	; update _lineerror
	add	ax, [_xdiaginc]		; update x
	add	bx, [_ydiaginc]		; update y

.done
	loop	.loopDraw
	ret

endproc
_DrawLine_arglen	EQU	20

;-----------------------------------------------------------------------------------------------------------------------------------------
;-- void DrawRect(dword *DestOff, word DestWidth, word DestHeight, word X1, word Y1, word X2, word Y2, dword Color, dword FillRectFlag) --
;-----------------------------------------------------------------------------------------------------------------------------------------
; Inputs : DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          X1 - x coordinate of start point
;          Y1 - y coordinate of start point
;          X2 - x coordinate of end point
;          Y2 - y coordinate of end point
;          Color - color of rectangle to draw
;          FillRectFlag - flag to determine whether or not to fill the rectangle
; Outputs : rectangle drawn to buffer, filled if necessary
; Returns : -
; Calls : _DrawLine, _FloodFill
; - draws a rectangle with color Color from point (X1, Y1) to (X2, Y2) in the buffer pointed to by DestOff
proc _DrawRect
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X1		arg	2
.Y1		arg	2
.X2		arg	2
.Y2		arg	2
.Color		arg	4
.FillRectFlag	arg	4

;	invoke	_libDrawRect, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X1], word [ebp+.Y1], word [ebp+.X2], word [ebp+.Y2], dword [ebp+.Color], dword [ebp+.FillRectFlag]

	invoke _DrawLine, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word [.X1 + ebp], word [.Y1 + ebp], word [.X2 + ebp], word [.Y1 + ebp], dword [.Color + ebp]
	invoke _DrawLine, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word [.X1 + ebp], word [.Y2 + ebp], word [.X2 + ebp], word [.Y2 + ebp], dword [.Color + ebp]
	invoke _DrawLine, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word [.X1 + ebp], word [.Y1 + ebp], word [.X1 + ebp], word [.Y2 + ebp], dword [.Color + ebp]
	invoke _DrawLine, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word [.X2 + ebp], word [.Y1 + ebp], word [.X2 + ebp], word [.Y2 + ebp], dword [.Color + ebp]
	cmp	dword [.FillRectFlag + ebp], 0
	je	.done
	mov	ax, [.X1 + ebp]
	add	ax, [.X2 + ebp]
	shr	ax, 1
	mov	bx, [.Y1 + ebp]
	add	bx, [.Y2 + ebp]
	shr	bx, 1
	invoke _FloodFill, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp], dword 0

.done
	ret

endproc
_DrawRect_arglen	EQU	24

;--------------------------------------------------------------------------------------------------------------------------------------
;-- void DrawCircle(dword *DestOff, word DestWidth, word DestHeight, word X, word Y, word Radius, dword Color, dword FillCircleFlag) --
;--------------------------------------------------------------------------------------------------------------------------------------
; Inputs : DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          X - x coordinate of center
;          Y - y coordinate of center
;          Radius - radius of circle
;          Color - color of line to draw
;          FillCircleFlag - flag to determine whether or not to fill the circle
; Outputs : circle drawn to buffer, filled if necessary
; Returns : -
; Calls : _DrawPixel, _FloodFill
; - draws a circle with center (X, Y), color Color, and radius Radius in the buffer pointed to by DestOff
proc _DrawCircle
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
.Radius		arg	2
.Color		arg	4
.FillCircleFlag	arg	4

;	invoke	_libDrawCircle, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y], word [ebp+.Radius], dword [ebp+.Color], dword [ebp+.FillCircleFlag]

	mov	word [_xdist], 0
	mov	ax, [.Radius + ebp]
	mov	word [_ydist], ax
	mov	word [_circleerror], 1
	sub	[_circleerror], ax

.loopDrawCircle
	mov	ax, [_xdist]
	cmp	ax, [_ydist]
	jg	near .fillCircle
	mov	ax, [.X + ebp]
	add	ax, [_xdist]		; x + xdist
	mov	bx, [.Y + ebp]
	add	bx, [_ydist]		; y + ydist
	invoke _DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
	mov	ax, [.X + ebp]
	sub	ax, [_xdist]		; x - xdist
	mov	bx, [.Y + ebp]
	add	bx, [_ydist]		; y + ydist
	invoke _DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
	mov	ax, [.X + ebp]
	add	ax, [_xdist]		; x + xdist
	mov	bx, [.Y + ebp]
	sub	bx, [_ydist]		; y + ydist
	invoke _DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
	mov	ax, [.X + ebp]
	sub	ax, [_xdist]		; x - xdist
	mov	bx, [.Y + ebp]
	sub	bx, [_ydist]		; y - ydist
	invoke _DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
	mov	ax, [.X + ebp]
	add	ax, [_ydist]		; x + ydist
	mov	bx, [.Y + ebp]
	add	bx, [_xdist]		; y + xdist
	invoke _DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
	mov	ax, [.X + ebp]
	sub	ax, [_ydist]		; x - ydist
	mov	bx, [.Y + ebp]
	add	bx, [_xdist]		; y + xdist
	invoke _DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
	mov	ax, [.X + ebp]
	add	ax, [_ydist]		; x + ydist
	mov	bx, [.Y + ebp]
	sub	bx, [_xdist]		; y - xdist
	invoke _DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]
	mov	ax, [.X + ebp]
	sub	ax, [_ydist]		; x - ydist
	mov	bx, [.Y + ebp]
	sub	bx, [_xdist]		; y - xdist
	invoke _DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], ax, bx, dword [.Color + ebp]

	inc	word [_xdist]

	cmp	word [_circleerror], 0
	jge	.circleerrorPositive
	mov	ax, [_xdist]
	shl	ax, 1			;
	inc	ax			;
	add	[_circleerror], ax	; _circleerror = (2 * _xdist) + 1
	jmp	.loopDrawCircle

.circleerrorPositive
	dec	word [_ydist]
	mov	ax, [_xdist]
	sub	ax, [_ydist]
	shl	ax, 1			;
	inc	ax			;
	add	[_circleerror], ax	; _circleerror = 2 * (_xdist - _ydist) + 1
	jmp	.loopDrawCircle

.fillCircle
	cmp	dword [.FillCircleFlag + ebp], 0
	je	.done
	invoke	_FloodFill, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word [.X + ebp], word [.Y + ebp], dword [.Color + ebp], dword 0

.done
	ret

endproc
_DrawCircle_arglen	EQU	22

;-------------------------------------------------------------------------------------------------------------------
;-- void DrawText(dword *StringOff, dword *DestOff, word DestWidth, word DestHeight, word X, word Y, dword Color) --
;-------------------------------------------------------------------------------------------------------------------
; Inputs : StringOff - offset of string to draw
;          DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          X - x coordinate of start point
;          Y - y coordinate of start point
;          Color - color of the string to draw
;          [_FontOff] - offset of font image data
; Outputs : string drawn to buffer
; Returns : -
; Calls : _PointInBox
; - draws a text string pointed to by StringOff with color Color at point (X, Y) in the buffer pointed to by DestOff
proc _DrawText
.StringOff	arg	4
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
.Color		arg	4

;	invoke	_libDrawText, dword [ebp+.StringOff], dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y], dword [ebp+.Color]

	push	esi
	push	edi

	xor	ebx, ebx

.loopDrawText
	mov	eax, [.StringOff + ebp]		; calculate source offset (locate in font image)
	add	eax, ebx			;
	movzx	esi, byte [eax]			;
	cmp	esi, '$'			;
	je	near .done			;
	shl	esi, 6				;
	add	esi, [_FontOff]			;

	movzx	eax, word [.DestWidth + ebp]	; calculate destination offset (locate in buffer)
	movsx	edi, word [.Y + ebp]		;
	imul	edi				;
	movsx	edi, word [.X + ebp]		;
	add	eax, edi			;
	mov	edi, ebx			;
	shl	edi, 4				;
	add	eax, edi			;
	shl	eax, 2				;
	add	eax, [.DestOff + ebp]		;
	mov	edi, eax

	xor	cx, cx

.loopBlit
	cmp	cl, 16				; if reaches end of 16th col
	jl	.keepCopying
	inc	ch
	cmp	ch, 16				; if reaches end of 16th row
	jge	.doneBlit
	xor	cl, cl
	add	esi, 2048 * 4 - 16 * 4		; move to next row, starting col (source)
	movzx	eax, word [.DestWidth + ebp]
	sub	eax, 16
	shl	eax, 2
	add	edi, eax			; move to next row, starting col (destination)

.keepCopying
	movzx	ax, cl
	add	ax, [.X + ebp]
	mov	dx, bx
	shl	dx, 4
	add	ax, dx

	movzx	dx, ch
	add	dx, [.Y + ebp]

	push	cx
	push	ebx
	invoke	_PointInBox, ax, dx, word 0, word 0, word [.DestWidth + ebp], word [.DestHeight + ebp]
	pop	ebx
	pop	cx
	test	eax, eax
	jz	.outsideBoundary
	mov	eax, [.Color + ebp]
	and	eax, 00ffffffh
	or	eax, [esi]
	mov	[edi], eax

.outsideBoundary
	add	esi, 4
	add	edi, 4
	inc	cl
	jmp	.loopBlit

.doneBlit
	inc	ebx
	jmp	.loopDrawText

.done
	pop	edi
	pop	esi
	ret

endproc
_DrawText_arglen	EQU	20

;------------------------------------------------------------------------------------
;-- void ClearBuffer(dword *DestOff, word DestWidth, word DestHeight, dword Color) --
;------------------------------------------------------------------------------------
; Inputs : DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          Color - color to make buffer
; Outputs : color copied to buffer
; Returns : -
; Calls : -
; - clears a buffer pointed to by DestOff by filling it with color Color
proc _ClearBuffer
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.Color		arg	4

;	invoke	_libClearBuffer, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], dword [ebp+.Color]

	push	edi

	mov	ax, ds
	mov	es, ax
	movzx	eax, word [.DestWidth + ebp]	;
	movzx	ecx, word [.DestHeight + ebp]	;
	mul	ecx				;
	mov	ecx, eax			; run (DestWidth * DestHeight) times
	mov	eax, [.Color + ebp]
	cld
	mov	edi, [.DestOff + ebp]
	rep	stosd

	pop	edi
	ret

endproc
_ClearBuffer_arglen	EQU	12

;------------------------------------------------------------------------------------------------------------------------------------
;-- void CopyBuffer(dword *ScrOff, word SrcWidth, word SrcHeight, dword *DestOff, word DestWidth, word DestHeight, word X, word Y) --
;------------------------------------------------------------------------------------------------------------------------------------
; Inputs : ScrOff - offset of source buffer
;          ScrWidth - width of source buffer
;          SrcHeight - height of source buffer
;          DestOff - offset of destination buffer
;          DestWidth - width of destination buffer
;          DestHeight - height of destination buffer
;          X - x coordinate of start point in destination buffer
;          Y - y coordinate of start point in destination buffer
; Outputs : source buffer copied onto destination buffer
; Returns : -
; Calls : -
; - copies a source buffer pointed to by ScrOff to a location (X, Y) in a destination buffer pointed to by DestOff
proc _CopyBuffer
.SrcOff		arg	4
.SrcWidth	arg	2
.SrcHeight	arg	2
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2

;	invoke	_libCopyBuffer, dword [ebp+.SrcOff], word [ebp+.SrcWidth], word [ebp+.SrcHeight], dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y]

	push	esi
	push	edi

	mov	ax, ds
	mov	es, ax

	mov	esi, [.SrcOff + ebp]
	movzx	eax, word [.DestWidth + ebp]	;
	movsx	edi, word [.Y + ebp]		;
	imul	edi				;
	movsx	edi, word [.X + ebp]		;
	add	eax, edi			;
	shl	eax, 2				;
	add	eax, [.DestOff + ebp]		;
	mov	edi, eax			; calculate destination offset
	cld
	mov	bx, word [.SrcHeight + ebp]

.loopCopy
	movzx	ecx, word [.SrcWidth + ebp]	; run SrcWidth times
	rep	movsd
	movzx	eax, word [.DestWidth + ebp]
	sub	ax, word [.SrcWidth + ebp]
	shl	eax, 2
	add	edi, eax
	dec	bx
	test	bx, bx
	jnz	.loopCopy

	pop	edi
	pop	esi
	ret

endproc
_CopyBuffer_arglen	EQU	20


;----------------------------------------------------------------------------------------------------------------------------------------
;-- void ComposeBuffers(dword *SrcOff, word SrcWidth, word SrcHeight, dword *DestOff, word DestWidth, word DestHeight, word X, word Y) --
;----------------------------------------------------------------------------------------------------------------------------------------
; Inputs : ScrOff - offset of source buffer
;          ScrWidth - width of source buffer
;          SrcHeight - height of source buffer
;          DestOff - offset of destination buffer
;          DestWidth - width of destination buffer
;          DestHeight - height of destination buffer
;          X - x coordinate of start point in destination buffer
;          Y - y coordinate of start point in destination buffer
; Outputs : source buffer alpha composed onto destination buffer
; Returns : -
; Calls : -
; - alpha composes a source buffer pointed to by ScrOff onto a destination buffer pointed to by DestOff at location (X, Y)
proc _ComposeBuffers
.SrcOff		arg	4
.SrcWidth	arg	2
.SrcHeight	arg	2
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X	        arg	2
.Y		arg	2

;	invoke	_libComposeBuffers, dword [ebp+.SrcOff], word [ebp+.SrcWidth], word [ebp+.SrcHeight], dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y]

	push	esi
	push	edi

	mov	esi, [.SrcOff + ebp]
	movzx	eax, word [.DestWidth + ebp]
	movsx	edi, word [.Y + ebp]
	imul	edi
	movsx	edi, word [.X + ebp]
	add	eax, edi
	shl	eax, 2
	add	eax, [.DestOff + ebp]
	mov	edi, eax

	mov	cx, [.SrcHeight + ebp]
	mov	dx, [.SrcWidth + ebp]
	shr	dx, 1

.loopCompose
	test	dx, dx
	jnz	.startMMX
	mov	dx, [.SrcWidth + ebp]
	shr	dx, 1
	movzx	eax, word [.DestWidth + ebp]
	sub	ax, word [.SrcWidth + ebp]
	shl	eax, 2
	add	edi, eax
	dec	cx
	test	cx, cx
	jz	near .done

.startMMX
	movq	mm0, [esi]		;
	movq	mm1, mm0		;
	pxor	mm7, mm7		;
	punpckhbw	mm1, mm7	; unpack high dword from mm0 into mm1 (source)

	mov	al, [esi + 7]		;
	mov	ah, al			;
	mov	bx, ax			;
	shl	ebx, 16			;
	mov	bx, ax			;
	movd	mm2, ebx		;
	punpcklbw	mm2, mm7	; copy out source alpha byte into ebx then to mm2

	pmullw	mm1, mm2		; alpha * source
	paddusw	mm1, [_RoundingFactor]
	psrlw	mm1, 8

	movq	mm4, [edi]		;
	movq	mm5, mm4		;
	punpckhbw	mm5, mm7	; unpack high dword from mm4 into mm5 (destination)

	paddusw	mm1, mm5		; alpha * source + destination

	pmullw	mm5, mm2		; alpha * destination
	paddusw	mm5, [_RoundingFactor]
	psrlw	mm5, 8

	psubusw	mm1, mm5		; (alpha * source) + destination - (alpha * destination)

	punpcklbw	mm0, mm7	; unpack low dword from mm0 into mm0 (source)

	mov	al, [esi + 3]		;
	mov	ah, al			;
	mov	bx, ax			;
	shl	ebx, 16			;
	mov	bx, ax			;
	movd	mm2, ebx		;
	punpcklbw	mm2, mm7	; copy out source alpha byte into ebx then to mm2

	pmullw	mm0, mm2		; alpha * source
	paddusw	mm0, [_RoundingFactor]
	psrlw	mm0, 8

	movq	mm5, mm4		;
	punpcklbw	mm5, mm7	; unpack low dword from mm4 into mm5 (destination)

	paddusw	mm0, mm5		; alpha * source + destination

	pmullw	mm5, mm2		; alpha * destination
	paddusw	mm5, [_RoundingFactor]
	psrlw	mm5, 8

	psubusw mm0, mm5		; (alpha * source) + destination - (alpha * destination)

	packuswb	mm0, mm1	; pack high and low words back into mm0

	movq	[edi], mm0
	dec	dx
	add	esi, 8
	add	edi, 8
	jmp	.loopCompose

.done
	pop	edi
	pop	esi
	ret

endproc
_ComposeBuffers_arglen	EQU	20

;-------------------------------------------------------------------------------------
;-- void BlurBuffer(dword *ScrOff, dword *DestOff, word DestWidth, word DestHeight) --
;-------------------------------------------------------------------------------------
; Inputs : ScrOff - offset of source buffer
;          DestOff - offset of destination buffer
;          DestWidth - width of destination buffer
;          DestHeight - height of destination buffer
; Outputs : string drawn to buffer
; Returns : -
; Calls : _GetPixel
; - blurs the buffer pointed to by ScrOff and writes the blurred buffer to the buffer pointed to by DestOff
proc _BlurBuffer
.SrcOff		arg	4
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2

;	invoke	_libBlurBuffer, dword [ebp+.SrcOff], dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight]

	push	esi
	push	edi

	mov	word [_y], 0
	xor	ebx, ebx
	mov	bx, word [ebp+.DestHeight]	; height counter

.rowLoop
	mov	word [_x], 0			; width counter
	movzx	ecx, word [ebp+.DestWidth]

.colLoop
	push	eax
	push	ebx
	push	ecx
	push	edx

	movzx	esi, word [_x]			; x and y pointers
	movzx	edi, word [_y]

						; take a weighted sum of the current pixel and its neighboring pixels
	dec	esi				; upper-left neighbor
	dec	edi
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm1, eax
	pxor	mm0, mm0
	punpcklbw	mm1, mm0

	inc	esi				; top neighbor
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm2, eax
	punpcklbw	mm2, mm0
	psllw	mm2, 1
	paddw	mm1, mm2

	inc	esi				; upper-right neighbor
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm2, eax
	punpcklbw	mm2, mm0
	paddw	mm1, mm2

	inc	edi				; left neighbor
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm2, eax
	punpcklbw	mm2, mm0
	psllw	mm2, 1
	paddw	mm1, mm2

	dec	esi				; current pixel
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm2, eax
	punpcklbw	mm2, mm0
	psllw	mm2, 2
	paddw	mm1, mm2

	dec	esi				; right neighbor
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm2, eax
	punpcklbw	mm2, mm0
	psllw	mm2, 1
	paddw	mm1, mm2

	inc	edi				; lower-left neighbor
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm2, eax
	punpcklbw	mm2, mm0
	paddw	mm1, mm2

	inc	esi				; bottom neighbor
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm2, eax
	punpcklbw	mm2, mm0
	psllw	mm2, 1
	paddw	mm1, mm2

	inc	esi				; lower-right neighbor
	invoke  _GetPixel, dword [ebp+.SrcOff], word [ebp+.DestWidth], word [ebp+.DestHeight], si, di
	movd	mm2, eax
	punpcklbw	mm2, mm0
	paddw	mm1, mm2

	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

.calcBlur
	psrlw	mm1, 4

	packuswb	mm1, mm0

	movzx	edx, word [_y]
	movzx	eax, word [ebp+.DestWidth]	; calculate the offset of the current pixel
	mul	edx
	movzx	edx, word [_x]
	add	eax, edx
	shl	eax, 2				; take the average
	add	eax, dword [ebp+.DestOff]

	movd	edx, mm1
	mov	dword[eax], edx

	inc	word [_x]

	dec	ecx
	cmp	ecx, 0
	ja	NEAR	.colLoop		; end of the column loop

	inc	word [_y]

	dec	ebx
	cmp	ebx, 0
	ja	.rowLoop			; end of the row loop

.blurDone
	pop	edi
	pop	esi
	ret

endproc
_BlurBuffer_arglen	EQU	12

;---------------------------------------------------------------------------------------------------------------------
;-- void FloodFill(dword *DestOff, word DestWidth, word DestHeight, word X, word Y, dword Color, dword ComposeFlag) --
;---------------------------------------------------------------------------------------------------------------------
; Inputs : DestOff - offset of an image buffer in memory
;          DestWidth - width of the buffer
;          DestHeight - height of the buffer
;          X - x coordinate of point in the region
;          Y - y coordinate of point in the region
;          Color - new color for region
;          ComposeFlag - flag to determine whether or not to alpha compose the current color of the region with Color
; Outputs : region filled with color Color in buffer
; Returns : -
; Calls : _PointInBox, _GetPixel, _DrawPixel
; - performs a flood fill operation on a region in the buffer pointed to by DestOff
proc _FloodFill
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
.Color		arg	4
.ComposeFlag	arg	4

;	invoke	_libFloodFill, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y], dword [ebp+.Color], dword [ebp+.ComposeFlag]

	push	esi
	push	edi

	mov	edi, [_PointQueue]	;
	mov	[_QueueHead], edi	;
	mov	[_QueueTail], edi	; initialize _QueueHead and _QueueTail
	mov	ax, [.X + ebp]
	mov	[edi], ax
	mov	ax, [.Y + ebp]
	mov	[edi + 2], ax
	add	dword [_QueueTail], 4
	invoke	_GetPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word [.X + ebp], word [.Y + ebp]
	mov	esi, eax		; esi = old color

.loopFill
	mov	edi, [_QueueHead]
	cmp	edi, [_QueueTail]
	jae	near .done
	add	dword [_QueueHead], 4	; dequeue
	invoke	_PointInBox, word [edi], word [edi + 2], word 0, word 0, word [.DestWidth + ebp], word [.DestHeight + ebp]
	test	eax, eax
	jz	.loopFill
	invoke	_GetPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word [edi], word [edi + 2]
	cmp	esi, eax
	jne	.loopFill
	mov	ebx, [.Color + ebp]

	cmp	dword [.ComposeFlag + ebp], 0
	je	.noAlphaCompose
	movd	mm0, [.Color + ebp]	;
	pxor	mm7, mm7		;
	punpcklbw	mm0, mm7	; unpack .Color to mm0

	mov	dl, [.Color + ebp + 3]	;
	mov	dh, dl			;
	mov	bx, dx			;
	shl	ebx, 16			;
	mov	bx, dx			;
	movd	mm2, ebx		;
	punpcklbw	mm2, mm7	; copy out source alpha byte into ebx then to mm2

	pmullw	mm0, mm2		; alpha * source
	paddusw	mm0, [_RoundingFactor]
	psrlw	mm0, 8

	movd	mm4, eax
	punpcklbw	mm4, mm7	; unpack low dword from mm4 into mm5 (destination)

	paddusw	mm0, mm4		; alpha * source + destination

	pmullw	mm4, mm2		; alpha * destination
	paddusw	mm4, [_RoundingFactor]
	psrlw	mm4, 8

	psubusw mm0, mm4		; (alpha * source) + destination - (alpha * destination)

	packuswb	mm0, mm7	; pack into low word in mm0
	movd	ebx, mm0

.noAlphaCompose
	cmp	ebx, eax
	je	.loopFill
	invoke	_DrawPixel, dword [.DestOff + ebp], word [.DestWidth + ebp], word [.DestHeight + ebp], word [edi], word [edi + 2], ebx
	mov	ax, [edi]
	mov	bx, [edi + 2]
	mov	edi, [_QueueTail]

	inc	ax			;
	mov	[edi], ax		;
	mov	[edi + 2], bx		; enqueue (X + 1, Y)

	sub	ax, 2			;
	mov	[edi + 4], ax		;
	mov	[edi + 6], bx		; enqueue (X - 1, Y)

	inc	ax			;
	mov	[edi + 8], ax		;
	inc	bx			;
	mov	[edi + 10], bx		; enqueue (X, Y + 1)

	mov	[edi + 12], ax		;
	sub	bx, 2			;
	mov	[edi + 14], bx		; enqueue (X, Y - 1)

	add	dword [_QueueTail], 16
	jmp	.loopFill

.done
	pop	edi
	pop	esi
	ret

endproc
_FloodFill_arglen	EQU	20

;--------------------------------------------------------------
;-- dword InstallKeyboard(void)                              --
;--------------------------------------------------------------
; Inputs : -
; Outputs : -
; Returns : 1 on error; 0 otherwise
; Calls : _LockArea
; - installs teh keyboard ISR
_InstallKeyboard
;	call	_libInstallKeyboard

	invoke	_LockArea, ds, dword _kbINT, dword 1	;
	invoke	_LockArea, ds, dword _kbIRQ, dword 1	;
	invoke	_LockArea, ds, dword _kbIRQ, dword 2	;
	mov	eax, _KeyboardISR_end			;
	mov	eax, _KeyboardISR			;
	invoke	_LockArea, cs, dword _KeyboardISR, eax	; lock variables and handler

	movzx	eax, byte [_kbINT]
	invoke	_Install_Int, eax, dword _KeyboardISR
	test	eax, eax	; check for error
	jz	.done
	mov	eax, 1

.done
	ret

;--------------------------------------------------------------
;-- void RemoveKeyboard(void)                                --
;--------------------------------------------------------------
; Inputs : -
; Outputs : -
; Returns : -
; Calls : -
; - uninstalls the keyboard ISR
_RemoveKeyboard
;	call	_libRemoveKeyboard

	movzx	eax, byte [_kbINT]
	invoke	_Remove_Int, eax
	ret

;--------------------------------------------------------------
;-- void KeyboardISR(void)                                   --
;--------------------------------------------------------------
; Inputs : keypress waiting at port [_kbPort], [_kbIRQ]
; Outputs : [_key], [_MPFlags]
; Returns : -
; Calls : -
; - handles keyboard input from the user
_KeyboardISR
;	call	_libKeyboardISR

	mov	dx, [_kbPort]
	in	ax, dx
	cmp	al, 1				;see if ESC was pressed
	je NEAR .Escape
	test	al, 10000000b			;test whether it's a press or a release
	jz	.Press
.Release
	and	al, 01111111b			;set MSB to 0
	cmp	al, 42				;compare with left shift
	jne	.RSRCheck
	and	byte[_MPFlags], 11101111b	;clear the left shift flag
	jmp	.Ack
.RSRCheck
	cmp	al, 54				;compare with right shift
	jne	NEAR .Ack
	and	byte[_MPFlags], 11110111b	;clear the right shift flag
	jmp	.Ack
.Press
	test	byte[_MPFlags], 00011000b	;check whether shift flag is set
	jnz	.shiftDown
	mov	ebx, 0
	mov	bl, al
	mov	dl, byte[_QwertyNames+ebx]	;if shift flag is 0, use _QwertyNames
	mov	[_key], dl
	cmp	al, 42
	je	.LSPress
	cmp	al, 54
	je	.RSPress
	or	byte[_MPFlags], 00100000b	;set bit 5 for key other than shift pressed
	jmp	.Ack
.shiftDown					;Shift flag is 1, so use _QwertyShift table
	mov	ebx, 0
	mov	bl, al
	mov	dl, byte[_QwertyShift+ebx]
	mov	[_key], dl
	or	byte[_MPFlags], 00100000b	;set bit 5 for key other than shift pressed
	jmp	.Ack
.LSPress
	or	byte[_MPFlags], 00010000b	;set the appropriate flags for shift pressed
	and	byte[_MPFlags], 11011111b	;
	jmp	.Ack			 	;
.RSPress					;
	or	byte[_MPFlags], 00001000b	;
	and	byte[_MPFlags], 11011111b	;
	jmp	.Ack				;
.Escape
	or	byte[_MPFlags], 00000001b
.Ack
	in	al, 61h
	or	al, 1000000b
	out	61h, al
	and	al, 0111111b
	out	61h, al
	mov	al, 20h
	out	20h, al
	cmp	byte[_kbIRQ], 8			;ACK with slave pic for [_kbIRQ]>=8
	jl	.Done
	mov	al, 20h
	out	0A0h, al
.Done
	ret
_KeyboardISR_end

;--------------------------------------------------------------
;-- dword InstallMouse(void)                                 --
;--------------------------------------------------------------
; Inputs : -
; Outputs : [_MouseSeg], [_MouseOff]
; Returns : 1 on error; 0 otherwise
; Calls : _LockArea, _Get_RMCB, DPMI_Int
; - installs the mouse callback
_InstallMouse
;	call	_libInstallMouse

	invoke	_LockArea, ds, _MouseX, dword 2
	invoke	_LockArea, ds, _MouseY, dword 2
	invoke	_LockArea, ds, _MPFlags, dword 1
	invoke	_LockArea, cs, _MouseCallback, _MouseCallback_end-_MouseCallback
	invoke  _Get_RMCB, _MouseSeg, _MouseOff, _MouseCallback, 1
	cmp		eax, 0
	jne		.Error
	mov		word [DPMI_EAX], 000Ch              ;function 000Ch
	mov		word [DPMI_ECX], 0007h              ;bits 0,1,2 for call mask
	mov		cx, [_MouseSeg]
	mov		word [DPMI_ES],cx                   ;segment address
	mov		cx, [_MouseOff]
	mov		word [DPMI_EDX], cx                 ;offset address
	mov		bx, 33h
	call	DPMI_Int
	jc		.Error
	mov		eax, 0
	jmp		.Done
.Error
	mov		eax, 1
.Done
        ret

;--------------------------------------------------------------
;-- void RemoveMouse(void)                                   --
;--------------------------------------------------------------
; Inputs : [_MouseSeg], [_MouseOff]
; Outputs : -
; Returns : -
; Calls : _Free_RMCB, DPMI_Int
; - removes the mouse callback
_RemoveMouse
;	call	_libRemoveMouse

	mov	word [DPMI_EAX], 000Ch	;function 000Ch
	mov	word [DPMI_ECX], 0007h	;bits 0,1,2 for call mask
	mov	word [DPMI_ES], 0	;0000:0000 for "no callback"
	mov	word [DPMI_EDX], 0
	mov	bx, 33h
	call	DPMI_Int
        invoke  _Free_RMCB, word[_MouseSeg], word[_MouseOff]
        ret

;--------------------------------------------------------------
;-- void MouseCallback(dword *DPMIRegsPtr)                   --
;--------------------------------------------------------------
; Inputs : DPMIRegsPtr - pointer to DPMI register structure
;          [_MouseX], [_MouseY], [_MPFlags]
; Outputs : [_MouseX], [_MouseY], [_MPFlags]
; Returns : -
; Calls : -
; - handles mouse input from user
proc _MouseCallback
.DPMIRegsPtr   arg     4

;	invoke	_libMouseCallback, dword [ebp+.DPMIRegsPtr]

	mov	eax, dword[ebp+.DPMIRegsPtr]
	mov	dx, [es:eax+DPMI_ECX_off]
	mov	[_MouseX], dx			;update YCoord
	mov	dx, [es:eax+DPMI_EDX_off]	;update XCoord
	mov	[_MouseY], dx
.TestButton
	mov	dx, [es:eax+DPMI_EBX_off]	;status reg
	and	dx, 0001h			;bit 0, button press
	cmp	dx, 0
	je	.ButtonUp
.ButtonDown
	test	byte[_MPFlags], 00000010b	;see if button was already down
	jnz	.Done
	or	byte[_MPFlags], 00000110b	;if it wasn't, update flags
	jmp	.Done
.ButtonUp
	test	byte[_MPFlags], 00000010b	;see if the button was already up
	jz	.Done
	or	byte[_MPFlags], 00000100b	;if it wasn't down, update flags
	and	byte[_MPFlags], 11111101b
.Done
	ret

endproc
_MouseCallback_end
_MouseCallback_arglen	EQU	4
