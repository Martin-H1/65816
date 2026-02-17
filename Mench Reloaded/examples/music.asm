; -----------------------------------------------------------------------------
; Uses pbFreqOut to generate square waves and play music.
; The circuit:
; - piezo buzzer anode is attached to VIA port A pin 0.
; - piezo buzzer cathode is attached to ground VIA header pin.
;
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "pbasic.inc"
.include "print.inc"
.include "via.inc"
.include "w65c265Monitor.inc"

; Tone generator register value
; N = (FCLK / (16 x F)) - 1
; F = desired frequency
; FCLK = FCLK input clock
; Hz values for musical notes scaled for CPU cycles.
NOTE_B0  = (FCLK / (16 * 31)) - 1
NOTE_C1  = (FCLK / (16 * 33)) - 1
NOTE_CS1 = (FCLK / (16 * 35)) - 1
NOTE_D1  = (FCLK / (16 * 37)) - 1
NOTE_DS1 = (FCLK / (16 * 39)) - 1
NOTE_E1  = (FCLK / (16 * 41)) - 1
NOTE_F1  = (FCLK / (16 * 44)) - 1
NOTE_FS1 = (FCLK / (16 * 46)) - 1
NOTE_G1  = (FCLK / (16 * 49)) - 1
NOTE_GS1 = (FCLK / (16 * 52)) - 1
NOTE_A1  = (FCLK / (16 * 55)) - 1
NOTE_AS1 = (FCLK / (16 * 58)) - 1
NOTE_B1  = (FCLK / (16 * 62)) - 1
NOTE_C2  = (FCLK / (16 * 65)) - 1
NOTE_CS2 = (FCLK / (16 * 69)) - 1
NOTE_D2  = (FCLK / (16 * 73)) - 1
NOTE_DS2 = (FCLK / (16 * 78)) - 1
NOTE_E2  = (FCLK / (16 * 82)) - 1
NOTE_F2  = (FCLK / (16 * 87)) - 1
NOTE_FS2 = (FCLK / (16 * 93)) - 1
NOTE_G2  = (FCLK / (16 * 98)) - 1
NOTE_GS2 = (FCLK / (16 * 104)) - 1
NOTE_A2  = (FCLK / (16 * 110)) - 1
NOTE_AS2 = (FCLK / (16 * 117)) - 1
NOTE_B2  = (FCLK / (16 * 123)) - 1
NOTE_C3  = (FCLK / (16 * 131)) - 1
NOTE_CS3 = (FCLK / (16 * 139)) - 1
NOTE_D3  = (FCLK / (16 * 147)) - 1
NOTE_DS3 = (FCLK / (16 * 156)) - 1
NOTE_E3  = (FCLK / (16 * 165)) - 1
NOTE_F3  = (FCLK / (16 * 175)) - 1
NOTE_FS3 = (FCLK / (16 * 185)) - 1
NOTE_G3  = (FCLK / (16 * 196)) - 1
NOTE_GS3 = (FCLK / (16 * 208)) - 1
NOTE_A3  = (FCLK / (16 * 220)) - 1
NOTE_AS3 = (FCLK / (16 * 233)) - 1
NOTE_B3  = (FCLK / (16 * 247)) - 1
NOTE_C4  = (FCLK / (16 * 262)) - 1
NOTE_CS4 = (FCLK / (16 * 277)) - 1
NOTE_D4  = (FCLK / (16 * 294)) - 1
NOTE_DS4 = (FCLK / (16 * 311)) - 1
NOTE_E4  = (FCLK / (16 * 330)) - 1
NOTE_F4  = (FCLK / (16 * 349)) - 1
NOTE_FS4 = (FCLK / (16 * 370)) - 1
NOTE_G4  = (FCLK / (16 * 392)) - 1
NOTE_GS4 = (FCLK / (16 * 415)) - 1
NOTE_A4  = (FCLK / (16 * 440)) - 1
NOTE_AS4 = (FCLK / (16 * 466)) - 1
NOTE_B4  = (FCLK / (16 * 494)) - 1
NOTE_C5  = (FCLK / (16 * 523)) - 1
NOTE_CS5 = (FCLK / (16 * 554)) - 1
NOTE_D5  = (FCLK / (16 * 587)) - 1
NOTE_DS5 = (FCLK / (16 * 622)) - 1
NOTE_E5  = (FCLK / (16 * 659)) - 1
NOTE_F5  = (FCLK / (16 * 698)) - 1
NOTE_FS5 = (FCLK / (16 * 740)) - 1
NOTE_G5  = (FCLK / (16 * 784)) - 1
NOTE_GS5 = (FCLK / (16 * 831)) - 1
NOTE_A5  = (FCLK / (16 * 880)) - 1
NOTE_AS5 = (FCLK / (16 * 932)) - 1
NOTE_B5  = (FCLK / (16 * 988)) - 1
NOTE_C6  = (FCLK / (16 * 1047)) - 1
NOTE_CS6 = (FCLK / (16 * 1109)) - 1
NOTE_D6  = (FCLK / (16 * 1175)) - 1
NOTE_DS6 = (FCLK / (16 * 1245)) - 1
NOTE_E6  = (FCLK / (16 * 1319)) - 1
NOTE_F6  = (FCLK / (16 * 1397)) - 1
NOTE_FS6 = (FCLK / (16 * 1480)) - 1
NOTE_G6  = (FCLK / (16 * 1568)) - 1
NOTE_GS6 = (FCLK / (16 * 1661)) - 1
NOTE_A6  = (FCLK / (16 * 1760)) - 1
NOTE_AS6 = (FCLK / (16 * 1865)) - 1
NOTE_B6  = (FCLK / (16 * 1976)) - 1
NOTE_C7  = (FCLK / (16 * 2093)) - 1
NOTE_CS7 = (FCLK / (16 * 2217)) - 1
NOTE_D7  = (FCLK / (16 * 2349)) - 1
NOTE_DS7 = (FCLK / (16 * 2489)) - 1
NOTE_E7  = (FCLK / (16 * 2637)) - 1
NOTE_F7  = (FCLK / (16 * 2794)) - 1
NOTE_FS7 = (FCLK / (16 * 2960)) - 1
NOTE_G7  = (FCLK / (16 * 3136)) - 1
NOTE_GS7 = (FCLK / (16 * 3322)) - 1
NOTE_A7  = (FCLK / (16 * 3520)) - 1
NOTE_AS7 = (FCLK / (16 * 3729)) - 1
NOTE_B7  = (FCLK / (16 * 3951)) - 1
NOTE_C8  = (FCLK / (16 * 4186)) - 1
NOTE_CS8 = (FCLK / (16 * 4435)) - 1
NOTE_D8  = (FCLK / (16 * 4699)) - 1
NOTE_DS8 = (FCLK / (16 * 4978)) - 1

NOTE_WHOLE = 4000
NOTE_HALF = NOTE_WHOLE / 2
NOTE_QUARTER = NOTE_WHOLE / 4
NOTE_EIGTH = NOTE_WHOLE / 8

TG0 = 0				; Tone generator 0
TG1 = 1				; Tone generator 1

PUBLIC main
	ON16MEM
	ON16X
	printcr			; start output on a newline
	jsr viaInit		; one time VIA initialization.

	pea $0000		; start with first note.
@while:	ply
	lda melody,y
	beq @return		; zero marks the end of the song.

	tax
	iny
	iny
	lda melody,y
	iny
	iny
	phy
	tay
	lda TG1
	jsr pbFreqOut
	bra @while
@return:
	rtl
ENDPUBLIC

; Pachelbel's Canon
; Note of the melody (in CPU cycles) followed by the duration.
; 2 means a half note, 4 a quarter note, 8 an eighteenth, 16 sixteenth, so on
; Duration is converted to machine cycles elsewhere
melody:
    .word NOTE_FS4,NOTE_HALF, NOTE_E4,NOTE_HALF
    .word NOTE_D4,NOTE_HALF,  NOTE_CS4,NOTE_HALF
    .word NOTE_B3,NOTE_HALF,  NOTE_A3,NOTE_HALF
    .word NOTE_B3,NOTE_HALF,  NOTE_CS4,NOTE_HALF
    .word NOTE_FS4,NOTE_HALF, NOTE_E4,NOTE_HALF
    .word NOTE_D4,NOTE_HALF,  NOTE_CS4,NOTE_HALF
    .word NOTE_B3,NOTE_HALF,  NOTE_A3,NOTE_HALF
    .word NOTE_B3,NOTE_HALF,  NOTE_CS4,NOTE_HALF
    .word NOTE_D4,NOTE_HALF,  NOTE_CS4,NOTE_HALF
    .word NOTE_B3,NOTE_HALF,  NOTE_A3,NOTE_HALF
    .word NOTE_G3,NOTE_HALF,  NOTE_FS3,NOTE_HALF
    .word NOTE_G3,NOTE_HALF,  NOTE_A3,NOTE_HALF
    .word NOTE_D4,NOTE_QUARTER, NOTE_FS4,NOTE_EIGTH, NOTE_G4,NOTE_EIGTH, NOTE_A4,NOTE_QUARTER, NOTE_FS4,NOTE_EIGTH, NOTE_G4,NOTE_EIGTH
    .word NOTE_A4,NOTE_QUARTER, NOTE_B3,NOTE_EIGTH, NOTE_CS4,NOTE_EIGTH, NOTE_D4,NOTE_EIGTH, NOTE_E4,NOTE_EIGTH, NOTE_FS4,NOTE_EIGTH, NOTE_G4,NOTE_EIGTH
    .word NOTE_FS4,NOTE_QUARTER, NOTE_D4,NOTE_EIGTH, NOTE_E4,NOTE_EIGTH, NOTE_FS4,NOTE_QUARTER, NOTE_FS3,NOTE_EIGTH, NOTE_G3,NOTE_EIGTH
    .word NOTE_A3,NOTE_EIGTH, NOTE_G3,NOTE_EIGTH, NOTE_FS3,NOTE_EIGTH, NOTE_G3,NOTE_EIGTH, NOTE_A3,NOTE_HALF
    .word NOTE_G3,NOTE_QUARTER, NOTE_B3,NOTE_EIGTH, NOTE_A3,NOTE_EIGTH, NOTE_G3,NOTE_QUARTER, NOTE_FS3,NOTE_EIGTH, NOTE_E3,NOTE_EIGTH
    .word NOTE_FS3,NOTE_QUARTER, NOTE_D3,NOTE_EIGTH, NOTE_E3,NOTE_EIGTH, NOTE_FS3,NOTE_EIGTH, NOTE_G3,NOTE_EIGTH, NOTE_A3,NOTE_EIGTH, NOTE_B3,NOTE_EIGTH
    .word NOTE_G3,NOTE_QUARTER, NOTE_B3,NOTE_EIGTH, NOTE_A3,NOTE_EIGTH, NOTE_B3,NOTE_QUARTER, NOTE_CS4,NOTE_EIGTH, NOTE_D4,NOTE_EIGTH
    .word NOTE_A3,NOTE_EIGTH, NOTE_B3,NOTE_EIGTH, NOTE_CS4,NOTE_EIGTH, NOTE_D4,NOTE_EIGTH, NOTE_E4,NOTE_EIGTH, NOTE_FS4,NOTE_EIGTH, NOTE_G4,NOTE_EIGTH, NOTE_A4,NOTE_HALF
    .word NOTE_A4,NOTE_QUARTER, NOTE_FS4,NOTE_EIGTH, NOTE_G4,NOTE_EIGTH, NOTE_A4,NOTE_QUARTER
    .word NOTE_FS4,NOTE_EIGTH, NOTE_G4,NOTE_EIGTH, NOTE_A4,NOTE_EIGTH, NOTE_A3,NOTE_EIGTH, NOTE_B3,NOTE_EIGTH, NOTE_CS4,NOTE_EIGTH
    .word NOTE_D4,NOTE_EIGTH, NOTE_E4,NOTE_EIGTH, NOTE_FS4,NOTE_EIGTH, NOTE_G4,NOTE_EIGTH, NOTE_FS4,NOTE_QUARTER, NOTE_D4,NOTE_EIGTH, NOTE_E4,NOTE_EIGTH
    .word NOTE_FS4,NOTE_EIGTH, NOTE_CS4,NOTE_EIGTH, NOTE_A3,NOTE_EIGTH, NOTE_A3,NOTE_EIGTH
    .word NOTE_CS4,NOTE_QUARTER, NOTE_B3,NOTE_QUARTER, NOTE_D4,NOTE_EIGTH, NOTE_CS4,NOTE_EIGTH, NOTE_B3,NOTE_QUARTER
    .word NOTE_A3,NOTE_EIGTH, NOTE_G3,NOTE_EIGTH, NOTE_A3,NOTE_QUARTER, NOTE_D3,NOTE_EIGTH, NOTE_E3,NOTE_EIGTH, NOTE_FS3,NOTE_EIGTH, NOTE_G3,NOTE_EIGTH
    .word NOTE_A3,NOTE_EIGTH, NOTE_B3,NOTE_QUARTER, NOTE_G3,NOTE_QUARTER, NOTE_B3,NOTE_EIGTH, NOTE_A3,NOTE_EIGTH, NOTE_B3,NOTE_QUARTER
    .word NOTE_CS4,NOTE_EIGTH, NOTE_D4,NOTE_EIGTH, NOTE_A3,NOTE_EIGTH, NOTE_B3,NOTE_EIGTH, NOTE_CS4,NOTE_EIGTH, NOTE_D4,NOTE_EIGTH, NOTE_E4,NOTE_EIGTH
    .word NOTE_FS4,NOTE_EIGTH, NOTE_G4,NOTE_EIGTH, NOTE_A4,NOTE_HALF
    .word 0,0
