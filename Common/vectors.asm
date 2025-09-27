; -----------------------------------------------------------------------------
; Boot and interrupt handlers.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Set the assembler into 16 bit mode.
.include "common.inc"

;
; Aliases
;

;
; Data segments
;
.segment "BSS"
Abortvector:	.res 3		; holds application abort vector
BRKvector:	.res 3		; holds application break vector
COPvector:	.res 3		; holds application cop vector
RESvector:	.res 3		; holds application reset vector & checksum
INTvector:	.res 3		; holds application interrpt vector & checksum
NMIvector:	.res 3		; holds application NMI vector & checksum

.segment "CODE"

;
; Macros
;

;
; Functions
;
.import main

brkv:	jmp (BRKvector)
copv:	jmp (COPvector)
irqv:	jmp (INTvector)
nmiv:	jmp (NMIvector)
abortv:	jmp (Abortvector)

; Interrupt handler for RESET button, also boot sequence. 
resetv:
	sei		; diable interupts, until interupt vectors are set.
	cld		; clear decimal mode
	clc		; clear carry to enter 65816 native mode
	xce		; exchange carry with emulation flag
	rep #$30	; set 16-bit accumulator and index registers.
	ldx #$01FF	; reset stack pointer
	txs

	lda #$0000	; clear all three registers
	tax
	tay

	pha		; clear all flags
	plp
	jmp main	; go to ROM monitor or main program initialization.

eirqv:	jmp (INTvector)

eabortv:
	jmp (Abortvector)

; redirect the NMI interrupt vector here to be safe, but this 
; should never be reached for py65mon.
enmiv:
panic:
unused:
	jmp (NMIvector)

; Native Mode Interrupt vectors.
.org $FFE4
.word copv
.word brkv
.word abortv
.word nmiv
.word unused
.word irqv

; Emulation Mode Interrupt vectors.
.org $FFF8
.word eabortv
.word enmiv    ; NMI vector 
.word resetv  ; RESET vector
.word eirqv    ; IRQ vector
