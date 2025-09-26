; -----------------------------------------------------------------------------
; Boot and interrupt handlers.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Aliases
;

;
; Data segments
;
.segment "BSS"
BRKvector:	.res 3		; holds application break vector
RESvector:	.res 3		; holds application reset vector & checksum
INTvector:	.res 3		; holds application interrupt vector & checksum
NMIvector:	.res 3		; holds application NMI vector & checksum

.segment "CODE"

;
; Macros
;

;
; Functions
;
.import main

; Interrupt handler for RESET button, also boot sequence. 
resetv:
	sei		; diable interupts, until interupt vectors are set.
	cld		; clear decimal mode
	ldx #$FF	; reset stack pointer
	txs

	lda #$00	; clear all three registers
	tax
	tay

	pha		; clear all flags
	plp
	jmp main	; go to monitor or main program initialization.

irqv:	jmp (INTvector)

; redirect the NMI interrupt vector here to be safe, but this 
; should never be reached for py65mon.
nmiv:
panic:
	jmp (NMIvector)

; Interrupt vectors.
.org $FFFA

.word nmiv    ; NMI vector 
.word resetv  ; RESET vector
.word irqv    ; IRQ vector
