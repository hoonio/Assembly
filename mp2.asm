; MP2 - Sorting Efficiency
;  Seunghoon Kim
;  9/29/2003
;
; University of Illinois, Urbana-Champaign
; Dept. of Electrical and Computer Engineering
;
; Version 1.0

	BITS	16

;====== SECTION 1: Define constants =======================================

; Define general constants
        CR      	EQU     0Dh
        LF      	EQU     0Ah
	ESC		EQU	1Bh
	SPACE		EQU	20h
	BACKSPACE	EQU	08h
	MAXLENGTH	EQU	75
	MAXNUMBERS	EQU	20

;====== SECTION 2: Declare external routines ==============================

; Declare external library routines and variables
EXTERN kbdin, kbdine, dspmsg, ascbin, binasc, dosxit, dspout
EXTERN mp2xit, DisplayNumber, Test_CToF, Test_Factorial, Test_CalculateGrades, Grades
EXTERN libGetInput, libParseInput, libPrintArray, libHeapSort, libHeapify, libInsertionSort

GLOBAL CToF, Factorial, CalculateGrades, binascBuf, Heapify, CompareCount, SwapCount

;====== SECTION 3: Define stack segment ===================================

SEGMENT stkseg STACK                    ; *** STACK SEGMENT ***
        resb      64*8
stacktop:
        resb      0                     ; work around NASM bug

;====== SECTION 4: Define code segment ====================================

SEGMENT code                            ; *** CODE SEGMENT ***

;====== SECTION 5: Declare variables for main procedure ===================

IntroString	db	CR,LF
		db	0DAh
		times 31 db 0C4h
		db	0BFh,CR,LF
		db	0B3h, '     ', 228, 'C', 228, ' 291 Fall 2003 MP2     ', 0B3h, CR, LF
		db	0B3h, '           MAIN MENU           ', 0B3h, CR, LF
		db	0B3h
		times 31 db 0h
		db	0B3h,CR,LF
		db	0B3h, '   1. Run MP2                  ', 0B3h, CR, LF
		db	0B3h, '   2. Test CToF()              ', 0B3h, CR, LF
		db	0B3h, '   3. Test Factorial()         ', 0B3h, CR, LF
		db	0B3h, '   4. Test CalculateGrades()   ', 0B3h, CR, LF
		db	0C0h
		times 31 db 0C4h
		db	0D9h,CR,LF,CR,LF,'Please make your selection: $'

SortString	db	CR,LF
		db	0DAh
		times 31 db 0C4h
		db	0BFh,CR,LF
		db	0B3h, '     ', 228, 'C', 228, ' 291 Fall 2003 MP2     ', 0B3h, CR, LF
		db	0B3h, '      Sorting Efficiency       ', 0B3h, CR, LF
		db	0B3h
		times 31 db 0h
		db	0B3h,CR,LF
		db	0B3h, '       <H>eap Sort             ', 0B3h, CR, LF
		db	0B3h, '       <I>nsertion Sort        ', 0B3h, CR, LF
		db	0C0h
		times 31 db 0C4h
		db	0D9h,CR,LF,CR,LF,'$'

InputString	db	'Input format: <sort letter> <string of numbers, each separated by a space>',CR,LF,': $'
ErrorString	db	'Invalid Input: please reenter your input.',CR,LF,'$'
SortedString	db	CR,LF,'Sorted array:',CR,LF,'$'
CompareString	db	'Number of comparisons: ','$'
SwapString	db	'Number of swaps: ','$'
EnterString	db	CR,LF,'$'

NumberString	times MAXLENGTH+1 db 0
HeapArray	dw	0
NumberArray	times MAXNUMBERS  dw 0
NumberArrayLen	dw	0

CompareCount	dw	0
SwapCount	dw	0

FunctionTable	dw	MP2Main, Test_CToF, Test_Factorial, Test_CalculateGrades

binascBuf	times 	7 db 0

;====== SECTION 6: Program initialization =================================

..start:
        mov     ax, cs                  ; Initialize Default Segment register
        mov     ds, ax
        mov     ax, stkseg              ; Initialize Stack Segment register
        mov     ss, ax
        mov     sp, stacktop            ; Initialize Stack Pointer register

;====== SECTION 7: Main procedure =========================================

.SelectLoop
	mov	dx, IntroString
	call	dspmsg
	xor	ax, ax
	call	kbdin
	cmp	al, ESC
	je	.Done
	mov	dl, al
	call	dspout
	mov	dx, EnterString
	call	dspmsg
	sub	al, 31h
	cmp	al, 4
	jae	.SelectLoop

	mov	bx, ax
	shl	bx, 1
	call	[FunctionTable+bx]

.Done
	call	mp2xit

;--------------------------------------------------------------
;--                        MP2Main()                         --
;--------------------------------------------------------------
MP2Main
	mov	dx, SortString
	call	dspmsg
	mov	dx, InputString
	call	dspmsg

	push	word NumberString
	call	GetInput
	add	sp, 2
	test	ax, ax
	js	near .Done

	push	word NumberArrayLen
	push	word NumberArray
	push	word NumberString
	call	ParseInput
	add	sp, 6

	test	al, al
	jns	.ChooseSort
	mov	dx, ErrorString
	call	dspmsg
	jmp	MP2Main

.ChooseSort
	cmp	word [NumberArrayLen], 1
	je	.Print
	cmp	al, 'I'
	je	.InsertionSort

.HeapSort
	push	word [NumberArrayLen]
	push	word HeapArray
	call	HeapSort
	add	sp, 4
	jmp	.Print

.InsertionSort
	push	word [NumberArrayLen]
	push	word NumberArray
	call	InsertionSort
	add	sp, 4

.Print
	mov	dx, SortedString
	call	dspmsg
	push	word [NumberArrayLen]
	push	word NumberArray
	call	PrintArray
	add	sp, 4
	mov	dx, EnterString
	call	dspmsg
	call	dspmsg
	mov	dx, CompareString
	call	dspmsg
	mov	ax, [CompareCount]
	mov 	bx, binascBuf
	call	binasc
	mov	dx, bx
	call	dspmsg
	mov	dx, EnterString
	call	dspmsg
	mov	dx, SwapString
	call	dspmsg
	mov	ax, [SwapCount]
	mov 	bx, binascBuf
	call	binasc
	mov	dx, bx
	call	dspmsg
	mov	dx, EnterString
	call	dspmsg

.Done
	ret

;====== SECTION 8: Your subroutines =======================================

;--------------------------------------------------------------
;--          Replace library calls with your code!           --
;--          [Save all reg values that you modify]           --
;--          Do not forget to add function headers           --
;--------------------------------------------------------------


;--------------------------------------------------------------
;--                        GetInput()						 --
;--										                     --
;--	Obtains input from the user								 --
;--	Inputs: Buffer - Pointer to buffer in memory			 --
;--	Outputs: Input string written to Buffer					 --
;--	Returns: -1 if the user presses ESC to quit the program, --
;--		0 otherwise											 --
;--	Calls: kbdin, dspout									 --
;--------------------------------------------------------------
GetInput
	push	bp
	mov		bp, sp

;	push	word [bp+4]
;	call	libGetInput
;	add		sp, 2

	push	dx
	push	bx
	push	cx
	mov		bx, word[bp+4]				; bx points to the number string
	mov		cx, MAXLENGTH				; counter to limit number of characters to MAXLENGTH

.InputLoop
	call	kbdin
	cmp		al, 1Bh					; compare with Esc to escape
	je		.Escape
	cmp		al, 0Dh					; compare with Enter to end the string
	je		.EndString
	cmp		al, 08h					; compare with backapace
	je		.backspace
	cmp		cx, 0					; if MAXLENGTH is reached, keep running the loop until the user presses ESC, Enter, or backspace
	je		.InputLoop
	mov		byte[bx], al				; enter the character into the string
	mov		dl, al
	inc		bx
	call	dspout						; display the character user input
	loop	.InputLoop
	jmp		.InputLoop
.backspace
	mov		dl, 08h
	call	dspout
	mov		dl, 00h
	call	dspout
	mov		dl, 08h
	call	dspout
	;mov		byte[bx], 00h
	dec		bx
	mov		byte[bx], 00h				; backspace, erases the previous string, and updates the cursor in windows
	inc		cx
	jmp		.InputLoop
.EndString
	mov		byte[bx], 24h				; inputs $ at the end of the string, and goto the end
	mov		ax, 0
	jmp		.Done
.Escape
	mov		ax, 0					; on Esc, FFFF is entered into ax
	dec		ax
	jmp		.Done
.Done:
	pop		cx
	pop		bx
	pop		dx
	pop		bp
	ret

;-------------------------------------------------------------------------
;--								ParseInput()							--
;--																		--
;--	Parses the input buffer and stores numbers to an array in memory	--
;--	Inputs: Buffer - Pointer to buffer in memory						--
;--			Array - Pointer to array in memory							--
;--			Length - Pointer to word-sized variable in memory			--
;--	Outputs: Array contains numbers parsed from Buffer					--
;--			Array length written to Length								--
;--	Returns: The ASCII character corresponding to the type of sort		--
;--			to be performed, or -1 if there is an error					--
;--			in parsing the input buffer									--
;--	Calls: ascbin														--
;-------------------------------------------------------------------------
ParseInput
	push	bp
	mov		bp, sp

;	push	word [bp+8]
;	push	word [bp+6]
;	push	word [bp+4]
;	call	libParseInput
;	add	sp, 6

	push	cx
	push	bx
	push	si
	push	di
	mov		cx, 0
	mov		bx, word[bp+4]				; bx points to the number string
	mov		di,	word[bp+6]				; di points to the number array
	xor		ax, ax
	mov		al,	byte[bx]
	cmp		al, 48h						; lower than h, invalid input
	jb		.parseError
	cmp		al,	49h						; higher than i, invalid input
	ja		.parseError
	push	ax
	inc		bx

.parseLoop
	cmp		cx, MAXNUMBERS				; if the number of values exceed MAXNUMBERS, then stop adding to the array
	je		.parseStore
	cmp		byte[bx], 24h				; if end of the string($) is reached, stop adding
	je		.parseStore
	call	ascbin						; converts string into the ascii characters
	cmp		dl, 0
	jne		.parseError					; if dl is non-zero, ascbin function is returning an error signal
	mov		word[di], ax				; store the ascii characters to the array
	add		di, 2
	inc		cx							; cx counts number of times the loop excuted, counting length of the array
	jmp		.parseLoop

.parseStore
	mov		si, cx
	mov		di,	word[bp+8]				; di points to the address holding length of the array
	mov		[di], si					; array length updated
	pop		ax
	jmp		.parseDone

.parseError
	pop		ax
	mov		al, -1						; returning al with FF triggers an error sign

.parseDone
	pop		di
	pop		si
	pop		bx
	pop		cx
	pop		bp
	ret



;--------------------------------------------------------------
;--                       PrintArray()                       --
;--															 --
;-- Displays an array in memory to the screen				 --
;-- Inputs:	Array - Pointer to an array in memory			 --
;--			Length - Length of the array					 --
;-- Outputs:  Array displayed to screen						 --
;-- Returns: None											 --
;-- Calls: binasc, dspmsg, dspout							 --
;--------------------------------------------------------------
PrintArray
	push	bp
	mov		bp, sp

;	push	word [bp+6]
;	push	word [bp+4]
;	call	libPrintArray
;	add	sp, 4

	push	si
	push	ax
	push	cx
	xor		cx, cx
	mov		si,	word[bp+4]					; si points to the number array
	mov		di,	word[bp+6]					; di holds length of the array

.loopBinasc
	mov		ax, word[si]					; ax hold the 16-bit signed integer to be converted
	call	binasc							; converts binary to ascii

.printJob
	mov		dl, byte[bx]					; bx holds offset of first nonblank character of the string
	mov		dh, 0
	call	dspout
	inc		bx								; to print out the next character on the string
	loop	.printJob						; binasc returns cl, number of nonblank characters generated, so print characters cl times
	mov		dl, 20h
	mov		dh, 0
	call	dspout

.continueLoop
	add		si, 2							; increment the word
	dec		di								; di is acting as a counter in loopBinasc
	cmp		di, 0
	ja		.loopBinasc
	je		.printDone

.printDone
	pop		cx
	pop		ax
	pop		si
	pop		bp
	ret

;--------------------------------------------------------------
;--                         HeapSort()                       --
;--									                         --
;--  Sorts an array in memory with the heap sort algorithm	 --
;--  Inputs: Array - Pointer to a heap(an array) in memory	 --
;--  		Length - Length of the array					 --
;--  Outputs:  CompareCount, SwapCount						 --
;--  Returns: None											 --
;--  Calls: Heapify											 --
;--------------------------------------------------------------
HeapSort
	push	bp
	mov		bp, sp
;	push	word [bp+6]
;	push	word [bp+4]
;	call	libHeapSort
;	add		sp, 4
;	pop		bp
;	ret
	pusha
	mov		word[SwapCount], 0
	mov		word[CompareCount], 0
	xor		bx, bx
	mov		di, word[bp+6]
	mov		bx, word[bp+4]
	mov		si, di
	shr		si, 1

.heapConvert
	push	di
	push	si
	push	bx
	call	Heapify						; Heapify(Array,i,length)
	pop		bx
	pop		si
	pop		di
	dec		si
	cmp		si, 0						; for i=Length/2 downto 1
	ja		.heapConvert
	mov		si, di

.reconstruct
	shl		di, 1
	mov		cx, word[bx+di]				; Array[i+1]
	mov		dx, word[bx+2]
	mov		word[bx+di], dx				; swap(Array[1], Array[i+1])
	mov		word[bx+2], cx
	inc		word[SwapCount]
	shr		di, 1
	dec		di
	mov		cx,	1
	push		di
	push		cx
	push		bx
	call		Heapify						; Heapify(Array,1,i)
	pop		bx
	pop		cx
	pop		di
	cmp		di, 1						; for i=length-1 downto 1
	ja		.reconstruct

.heapDone
	popa
	pop		bp
	ret


;--------------------------------------------------------------
;--                         Heapify()                        --
;--									                         --
;--  Converts an array to a heap							 --
;--  Inputs: Array - Pointer to a heap(an array) in memory	 --
;--  		Current - Current index in the heap				 --
;--  		Length - Length of the heap						 --
;--  Outputs:  Array is correctly converted to a heap,		 --
;--  CompareCount and SwapCount updated appropriately		 --
;--  Returns: None											 --
;--  Calls: Heapify											 --
;--------------------------------------------------------------
Heapify
	push	bp
	mov		bp, sp

;	push	word [bp+8]
;	push	word [bp+6]
;	push	word [bp+4]
;	call	libHeapify
;	add	sp, 6
	pusha

	mov		dx, [bp+8]
	mov		bp, [bp+6]
;	mov		bx, [bp+4]

	mov		si, bp
	add		si, si						; left = current*2

.Condi1
	inc		word[CompareCount]
	cmp		si, dx						; if left <= length
	ja		.heapElse
	shl		si, 1
	mov		cx, word[bx+si]
	mov		di, bp
	shl		di, 1
	mov		ax, word[bx+di]
	shr		si, 1
	cmp		cx, ax						; if Array[left] > Array[current]
	jle		.heapElse
	mov		di, si						; largest = left
	jmp		.Condi2

.heapElse
	mov		di, bp						; largest = current

.Condi2
	inc		si					; right = left + 1
	inc		word[CompareCount]			; just increment in memory
	cmp		si, dx						; if right <= length
	ja		.heapStop
	shl		si, 1
	mov		cx, word[bx+si]
	shl		di, 1
	mov		ax, word[bx+di]
	shr		si, 1
	shr		di, 1
	cmp		cx, ax
	jle		.heapStop
	mov		di, si						; largest = right

.heapStop
	mov		si, bp
	cmp		di, si
	je		.heapDone
	shl		di, 1
	shl		si, 1
	mov		cx, word[bx+di]
	mov		ax, word[bx+si]
	inc		word[SwapCount]
	mov		word[bx+di], ax				; swap
	mov		word[bx+si], cx
	shr		di, 1
	shr		si, 1

.recursiveCall
	push	dx
	push	di
	push	bx
	call	Heapify						; recursive call
	pop		bx
	pop		di
	pop		dx

.heapDone
	popa
	pop		bp
	ret


;--------------------------------------------------------------
;--                      InsertionSort()                     --
;--										                     --
;--  Sorts an array with the insertion sort algorithm		 --
;--  Inputs: Array - Pointer to an array in memory			 --
;--			 Length - Length of the array					 --
;--  Outputs:  CompareCount, SwapCount						 --
;--  Returns: None											 --
;--  Calls: None											 --
;--------------------------------------------------------------
InsertionSort
	push	bp
	mov		bp, sp

;	push	word [bp+6]
;	push	word [bp+4]
;	call	libInsertionSort
;	add	sp, 4

	push	cx
	push	bx
	push	dx
	push	di
	push	si
	push	ax
	mov		cx, word[bp+6]
	mov		bx, word[bp+4]
	mov		dx, bx

.bigLoop
	mov		di, word[bx]				; for i to length-1
	push		bx

.smallLoop
	cmp		bx, dx						; while j>0
	jbe		.endBigLoop
	inc		word[CompareCount]
	cmp		word[bx-2], di				; while Array[j-1] > index
	jle		.endBigLoop
	inc		word[SwapCount]
	mov		si, word[bx-2]				; array[j] = array[j-1]
	mov		word[bx], si
	sub		bx, 2
	mov		si,	bx
	jmp		.smallLoop

.endBigLoop
	pop		bx
	mov		word[si], di				; array[j] = index
	inc		word[SwapCount]
	add		bx, 2
	dec		cx
	cmp		cx, 0
	ja		.bigLoop

	pop		ax
	pop		si
	pop		di
	pop		dx
	pop		bx
	pop		cx
	pop		bp
	ret

;====== SECTION 9: MP2 Debugging Exercises ================================

;--------------------------------------------------------------
;--                          CToF()                          --
;--------------------------------------------------------------
CToF
	push	bx
	mov	bx, 9
	imul	bx
	mov	bx, 5
	idiv	bx
	add	ax, 32
	pop	bx
	ret


;--------------------------------------------------------------
;--                       Factorial()                        --
;--------------------------------------------------------------
Factorial
	push	cx
	mov     cx, ax
	xor	ax, ax
	mov	ax, 1
	cmp	cx, 1
	jbe	.FactorialDone

.FactorialLoop
        mul     cx
        loop	.FactorialLoop

.FactorialDone
        pop	cx
        ret

;--------------------------------------------------------------
;--                    CalculateGrades()                     --
;--------------------------------------------------------------
CalculateGrades
	push	cx
	push	si

.StudentsLoop
	xor	ax, ax			; reset ax
	push	cx
	mov	cx, 10

.AddGradesLoop
	mov	bx, 0
	add	bl, [si]
	inc	si
	add	ax, bx
	loop	.AddGradesLoop
	pop	cx

	cmp	ax, 900
	jae	.A
	cmp	ax, 800
	jae	.B
	cmp	ax, 700
	jae	.C
	cmp	ax, 600
	jae	.D
	jmp	.F

	mov	ah, 0

.A
	mov	al, 'A'
	jmp	.StoreGrade

.B
	mov	al, 'B'
	jmp	.StoreGrade

.C
	mov	al, 'C'
	jmp	.StoreGrade

.D
	mov	al, 'D'
	jmp	.StoreGrade

.F
	mov	al, 'F'

.StoreGrade
	mov	[si], al
	inc	si
	loop	.StudentsLoop

	pop	si
	pop	cx
	ret
