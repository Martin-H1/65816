; -----------------------------------------------------------------------------
; PBasic function definitions.
; This module is a set of PBasic like functions to use for pin I/O. The goal
; is to ease porting applications from the Basic Stamp to this platform.
; Register linkage is used for efficiency. For more information see:
; www.parallax.com/go/PBASICHelp/Content/LanguageTopics/Reference/AlphaRef.htm
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

__pbasic_asm__ = 1

        .include "constants.inc"
        .include "dictionary.inc"
	.include "macros.inc"
	.include "pbasic.inc"

; Import zero page variables from forth.s
; Using .importzp ensures ca65 uses direct page addressing
        .importzp       W
        .importzp       UP
        .importzp       RSP_INIT
        .importzp       SCRATCH0
        .importzp       SCRATCH1
        .importzp       TMPA
        .importzp       TMPB

;
; Aliases
;

; Processor Register Locations
BCR	= $DF40		; BUS CONTROL REGISTER
			; BIT 1-TONE GEN 0 ENABLE
			; BIT 2-TONE GEN 1 ENABLE

TER	= $DF43		; TIMER ENABLE REGISTER
			; BIT 0-TIMER 0  1 = ENABLE
			; BIT 1-TIMER 1  1 = ENABLE
			; BIT 2-TIMER 2  1 = ENABLE
			; BIT 3-TIMER 3  1 = ENABLE
			; BIT 4-TIMER 4  1 = ENABLE
			; BIT 5-TIMER 5  1 = ENABLE
			; BIT 6-TIMER 6  1 = ENABLE
			; BIT 7-TIMER 7  1 = ENABLE

T2IF 	= $20		; Timer 2 interupt flag bit
Bit1	= $02
Bit2	= $04
T5FLG	= $20
T6FLG	= $40
T5CL	= $DF6A		; TIMER 5 COUNTER LOW
T6CL	= $DF6C		; TIMER 6 COUNTER LOW

;
; Aliases
;

; Base address of the 6522 VIA chip and I/O registers offsets.
VIA_BASE	= $dfe0
VIA_PRB		= VIA_BASE+$00
VIA_PRA		= VIA_BASE+$01
VIA_DDRB	= VIA_BASE+$02
VIA_DDRA	= VIA_BASE+$03
VIA_T1CL	= VIA_BASE+$04
VIA_T1CH	= VIA_BASE+$05
VIA_T1LL	= VIA_BASE+$06
VIA_TALH	= VIA_BASE+$07
VIA_T2CL	= VIA_BASE+$08
VIA_T2CH	= VIA_BASE+$09
VIA_SR		= VIA_BASE+$0a
VIA_ACR		= VIA_BASE+$0b
VIA_PCR		= VIA_BASE+$0c
VIA_IFR		= VIA_BASE+$0d
VIA_IER		= VIA_BASE+$0e
VIA_PRA1	= VIA_BASE+$0f

;
; Macros
;

;
; Static data
;
bitsetMask:
         .word %0000000100000000 ; port 'A' masks.
         .word %0000001000000000
         .word %0000010000000000
         .word %0000100000000000
         .word %0001000000000000
         .word %0010000000000000
         .word %0100000000000000
         .word %1000000000000000

         .word %0000000000000001 ; port 'B' masks.
         .word %0000000000000010
         .word %0000000000000100
         .word %0000000000001000
         .word %0000000000010000
         .word %0000000000100000
         .word %0000000001000000
         .word %0000000010000000

;
; Functions
;

; Initializes via and requires no arguments.
;------------------------------------------------------------------------------
; PBINIT ( -- ) Inits the PBasic library.
;------------------------------------------------------------------------------
        HEADER  "PBINIT", PBINIT_ENTRY, PBINIT_CFA, 0, PBINIT_ENTRY
        CODEPTR PBINIT_CODE
        PUBLIC  PBINIT_CODE
        .a16
        .i16
                LDA     #FORTH_FALSE
                PHY
                OFF16MEM                ; enter byte transfer mode.
                LDA     #$00
                LDY     #VIA_PCR        ; zero out lower regsiters
@loop:          STA     VIA_BASE,Y
                DEY
                BPL     @loop
                LDA     #$7f            ; init two upper registers.
                STA     VIA_IFR
                STA     VIA_IER
                ON16MEM
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PBCOUNT ( i t -- n ) Counts the number of cycles (0-1-0 or 1-0-1) on the
;  specified pin during the duration time frame and returns that number.
; Inputs:
;   i - index (0-15) of the I/O pin to use. Pin is set to input mode.
;   t - unsigned quantity (1-65535) specifying the time in milliseconds.
; Outputs:
;   n - the number of transitions.
;------------------------------------------------------------------------------
        HEADER  "PBCOUNT", PBCOUNT_ENTRY, PBCOUNT_CFA, 0, PBINIT_ENTRY
        CODEPTR PBCOUNT_CODE
        PUBLIC  PBCOUNT_CODE
        .a16
        .i16
                COUNT = 5               ; stack offsets for local variables.
                PORT_MASK = 3
                LAST_VALUE = 1

                PHD                     ; save direct page register
                PHY                     ; preserve IP
                PEA     $0000           ; initialize count stack local
                LDA     NOS,X
                JSR     PBINPUT_IMPL    ; set pin to input, C has port mask
                PHA                     ; initialize port mask stack local
                AND     VIA_PRB         ; Get initial the value and set
                PHA                     ; initial value stack local
                POP
                TAY                     ; save time parameter to Y
                TSC                     ; x stack pointer to direct page reg
                TCD                     ; stack frame space is now direct page.

@while:         OFF16MEM                ; enter byte transfer mode.
                STZ     VIA_ACR         ; select one shot mode
                LDA     #<ONE_MS
                STA     VIA_T2CL        ; store a word in lower and upper latch.
                LDA     #>ONE_MS
                STA     VIA_T2CH        ; set upper latch
                ON16MEM

@loop:          LDA     PORT_MASK
                AND     VIA_PRB         ; get the current state
                EOR     LAST_VALUE      ; compare with previous state
                BEQ     @endif

                INC     COUNT           ; state changed increment the count

                LDA     PORT_MASK
                AND     VIA_PRB         ; update last value with current state
                STA     LAST_VALUE

@endif:         OFF16MEM
                LDA     #T2IF           ; timer 2 mask
                BIT     VIA_IFR         ; timed out?
                ON16MEM
                BEQ     @loop

                OFF16MEM
                LDA     VIA_T2CL        ; clear timer 2 interrupt flag
                ON16MEM
                DEY
                BPL     @while

                PLA                     ; drop last value
                PLA                     ; drop port mask
                PLA                     ; return count in A
                PLY                     ; restore IP
                PLD                     ; restore direct page

                STA     TOS,X           ; Save the results
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PBFREQOUT ( c u1 u2 -- ) outputs a sound of the specified frequency for the
; duration.
; 
; This API differs from the PBasic command because I use values compatible
; with the w65c265 tone generator. The caller computes this value using the
; formula from the datasheet formula.
; Inputs:
;   C - tone generator channel (0 or 1) to use.
;   u1 - unsigned quantity (1-65535) specifying the frequency of the wave.
;   u2 - unsigned quantity (1-65535) specifying the duration in MS.
; Outputs:
;   None
;------------------------------------------------------------------------------
        HEADER  "PBFREQOUT", PBFREQOUT_ENTRY, PBFREQOUT_CFA, 0, PBCOUNT_ENTRY
        CODEPTR PBFREQOUT_CODE
        PUBLIC  PBFREQOUT_CODE
        .a16
        .i16
                DURATION = 5
                FREQUENCY = 3
                CHANNEL = 1

                POP                     ; Move duration to the return stack
                PHA
                LDA     NOS,X
                CMP     #$00            ; channel 0 or 1?
                BNE     @channel1

                ; channel 0
                POP                     ; get the frequency
                OFF16MEM                ; enter byte transfer mode.
                BEQ     @skip1
                STA     T5CL
@skip1:         LDA     #T5FLG          ; Enable timer 5
                TSB     TER
                LDA     #Bit1           ; Enable TG0
                TSB     BCR
                ON16MEM
                BRA     @pause

@channel1:
                POP                     ; get the frequency
                OFF16MEM                ; enter byte transfer mode.
                BEQ     @skip2
                STA     T6CL
@skip2:         LDA     #T6FLG          ; enable timer 6
                TSB     TER
                LDA     #Bit2           ; enable TG1
                TSB     BCR
                ON16MEM
@pause:
                PLA
                BEQ     @return         ; A zero duration means indefinate
                JSR     PBPAUSE_IMPL

                OFF16MEM                ; enter byte transfer mode.
                LDA     #Bit1 | Bit2    ; Disable TG0 and TG1
                TRB     BCR
                LDA     #T5FLG | T6FLG  ; Disable timers 5 and 6.
                TRB     TER
                ON16MEM
@return:        DROP                    ; drop the channel
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PBHIGH ( i -- ) puts the specified pin in output mode and high state.
; Inputs:
;   i - index (0-15) of the I/O pin to use. Pin is set to output mode.
; PBHIGH_IMPL
; Outputs:
;   Port mask in C, mask table index in Y
;
; Notes:
;   PBHIGH_IMPL calls PBOUTPUT_IMPL, which results in A returning with the
;   required mask. Hence PBHIGH_IMPL doesn't need to reload it.
;------------------------------------------------------------------------------
        HEADER  "PBHIGH", PBHIGH_ENTRY, PBHIGH_CFA, 0, PBFREQOUT_ENTRY
        CODEPTR PBHIGH_CODE
        PUBLIC  PBHIGH_CODE
        .a16
        .i16
                POP                     ; pop i
                PHY                     ; Preserve IP
                JSR     PBHIGH_IMPL
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

        .proc   PBHIGH_IMPL
                JSR     PBOUTPUT_IMPL   ; set data direction...see above note
                TSB     VIA_PRB         ; use mask to set pin high
                RTS
        .endproc

;------------------------------------------------------------------------------
; PBINPUT ( i -- ) Sets pin i to input
; pbInput - puts the specified pin in input mode.
; Inputs:
;   C - index (0-15) of the I/O pin to use. Pin is set to input mode.
; Outputs:
;   Port mask in C, mask table index in Y
;------------------------------------------------------------------------------
        HEADER  "PBINPUT", PBINPUT_ENTRY, PBINPUT_CFA, 0, PBHIGH_ENTRY
        CODEPTR PBINPUT_CODE
        PUBLIC  PBINPUT_CODE
        .a16
        .i16
                POP                     ; pop i
                PHY                     ; Preserve IP
                JSR     PBINPUT_IMPL
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

        .proc   PBINPUT_IMPL
                AND     #%1111          ; constrain input to valid values.
                ASL     A               ; convert to word index.
                TAY
                LDA     bitsetMask,Y    ; transform the index into a bitmask.
                TRB     VIA_DDRB        ; set the corresponding pin's bit high.
                RTS
        .endproc

;------------------------------------------------------------------------------
; PBINX ( i -- f ) Sets the pin as input and returns the current state.
; Inputs:
;   i - index (0-15) of the I/O pin to read. Pin is set to input mode.
; Outputs:
;   f - boolean pin state
;------------------------------------------------------------------------------
        HEADER  "PBINX", PBINX_ENTRY, PBINX_CFA, 0, PBINPUT_ENTRY
        CODEPTR PBINX_CODE
        PUBLIC  PBINX_CODE
        .a16
        .i16
                LDA     TOS,X           ; peek i
                PHY                     ; preserve IP
                JSR     PBINPUT_IMPL    ; set pin to input, C contains mask.
                AND     VIA_PRB         ; Get initial the value
                BEQ     @return
                LDA     #FORTH_TRUE
@return:        STA     TOS,X           ; put to TOS
                PLY                     ; restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PBLOW ( i -- ) puts the specified pin in output mode and low state.
; Inputs:
;   i - index (0-15) of the I/O pin to use. Pin is set to output mode.
;
; PBLOW_IMPL
; Outputs:
;   Port mask in C, mask table index in Y
;
; Notes:
;   pbLow calls pbOutput, which results in A returning with the required
;   mask. Hence pbLow doesn't need to reload it.
;------------------------------------------------------------------------------
        HEADER  "PBLOW", PBLOW_ENTRY, PBLOW_CFA, 0, PBINX_ENTRY
        CODEPTR PBLOW_CODE
        PUBLIC  PBLOW_CODE
        .a16
        .i16
                POP                     ; pop i
                PHY                     ; Preserve IP
                JSR     PBLOW_IMPL
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

        .proc   PBLOW_IMPL
                JSR     PBOUTPUT_IMPL   ; set pin to output and get port mask.
                TRB     VIA_PRB         ; use mask to clear the bit.
                RTS
        .endproc

;------------------------------------------------------------------------------
; PBOUPUT ( i -- ) puts the specified pin into output mode.
; Inputs:
;   i - index (0-15) of the I/O pin to use. Pin is set to output mode.
; PBOUTPUT_IMPL
; Outputs:
;   Port mask in C, mask table index in Y
;------------------------------------------------------------------------------
        HEADER  "PBOUTPUT", PBOUTPUT_ENTRY, PBOUTPUT_CFA, 0, PBLOW_ENTRY
        CODEPTR PBOUTPUT_CODE
        PUBLIC  PBOUTPUT_CODE
        .a16
        .i16
                POP                     ; pop i
                PHY                     ; Preserve IP
                JSR     PBOUTPUT_IMPL
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

        .proc   PBOUTPUT_IMPL
                AND     #%1111          ; constrain input to valid values...
                ASL     A               ; convert to word index.
                TAY
                LDA     bitsetMask,Y    ; transform the index into a bitmask.
                TSB     VIA_DDRB        ; set the corresponding pin's bit high.
                RTS
        .endproc

;------------------------------------------------------------------------------
; PBPAUSE ( u -- ) delays execution for the specified number of milliseconds.
; Inputs:
;   u - number of milliseconds to suspend execution.
;
; PBPAUSE_IMPL
; Outputs:
;   C - clobbered
;------------------------------------------------------------------------------
        HEADER  "PBPAUSE", PBPAUSE_ENTRY, PBPAUSE_CFA, 0, PBOUTPUT_ENTRY
        CODEPTR PBPAUSE_CODE
        PUBLIC  PBPAUSE_CODE
        .a16
        .i16
                POP                     ; pop u
                PHY                     ; Preserve IP
                PHY
                JSR     PBPAUSE_IMPL
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

        .proc   PBPAUSE_IMPL
                TAY
                OFF16MEM                ; enter byte transfer mode.
@while:         STZ     VIA_ACR         ; select one shot mode
                LDA     #<ONE_MS        ; one ms delay duration
                STA     VIA_T2CL        ; set lower latch
                LDA     #>ONE_MS
                STA     VIA_T2CH        ; set upper latch
                LDA     #T2IF           ; start mask
@loop:          BIT     VIA_IFR         ; time out?
                BEQ     @loop
                LDA     VIA_T2CL        ; clear timer 2 interrupt
                DEY
                BPL     @while
                ON16MEM
                RTS
        .endproc

;------------------------------------------------------------------------------
; PBPULSIN ( p f -- u ) measure the pulse width on a pin and return the results.
; Inputs:
;   p - index (0-15) of the I/O pin to use. Pin is set to input mode.
;   f - boolean that specifies whether the pulse to be measured is low or high.
; 	A low pulse begins with a true-to-false transition and a high pulse
;	begins with a false-to-high transition.
;	Both end with the reverse transition.
; Outputs:
;   u - the measured pulse duration in cpu cycles.
;------------------------------------------------------------------------------
        HEADER  "PBPULSIN", PBPULSIN_ENTRY, PBPULSIN_CFA, 0, PBPAUSE_ENTRY
        CODEPTR PBPLUSIN_CODE
        PUBLIC  PBPLUSIN_CODE
        .a16
        .i16
                IP_SAVE = 5
                INITIAL_VALUE = 3
                PORT_MASK = 1

                PHY                     ; preserve IP
	        PEA     $0000           ; reserve space for the initial value
                LDA     NOS,X           ; peek pin
                JSR     PBINPUT_IMPL    ; set pin to input and get port mask
                PHA                     ; initialize port mask stack local
                POP
                CMP     #FORTH_TRUE     ; test desired initial value
                BNE     @leading_edge
                STA     INITIAL_VALUE,S ; set initial value bit using port mask.
@leading_edge:
                LDA     PORT_MASK,S     ; wait for pulse leading edge.
                AND     VIA_PRB         ; get the current value.
                EOR     INITIAL_VALUE,S ; test for leading edge transition.
                BEQ     @leading_edge

                OFF16MEM                ; start VIA timer
                STZ     VIA_ACR         ; select one shot mode
                LDA     #$FF            ; load timer with maximum value.
                STA     VIA_T2CL        ; set lower latch
                STA     VIA_T2CH        ; set upper latch
                ON16MEM
@while:
                LDA     PORT_MASK,S
                AND     VIA_PRB         ; get the current value.
                EOR     INITIAL_VALUE,S ; test for edge transition.
                BEQ     @trailing_edge

                OFF16MEM                ; has timer reached zero?
                LDA     #T2IF           ; start mask
                BIT     VIA_IFR         ; time out?
                ON16MEM
                BEQ     @while

@trailing_edge:
                LDA     #$FFFF          ; UINT_MAX
                SEC
                SBC     VIA_T2CL        ; get value and clear timer 2 interrupt
                STA     TOS,X           ; put to TOS
                PLA                     ; clean up stack
                PLA
                PLY                     ; restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PBPULSOUT ( p u -- ) generate a pulse on pin with a width of duration in uS.
; Inputs:
;   p - index (0-15) of the I/O pin to use. Pin is set to output mode.
;   u - specifies the duration (0-65535) of the pulse width in machine cycles.
; Outputs:
;   None
;------------------------------------------------------------------------------
        HEADER  "PBPULSOUT", PBPULSOUT_ENTRY, PBPULSOUT_CFA, 0, PBPULSIN_ENTRY
        CODEPTR PBPLUSOUT_CODE
        PUBLIC  PBPLUSOUT_CODE
        .a16
        .i16
                PHY                     ; Preserve IP
                LDA     NOS,X           ; get pin
                JSR     PBHIGH_IMPL     ; pulse high
                POP                     ; get the time required

                OFF16MEM                ; enter byte transfer mode.
@while:         STZ     VIA_ACR         ; select one shot mode
                STA     VIA_T2CL        ; set lower latch
                XBA
                STA     VIA_T2CH        ; set upper latch
                LDA     #T2IF           ; start mask
@loop:          BIT     VIA_IFR         ; time out?
                BEQ     @loop
                LDA     VIA_T2CL        ; clear timer 2 interrupt
                ON16MEM

                POP                     ; set the pin low.
                JSR     PBLOW_IMPL

                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PBPWM ( p u1 u2 -- ) converts a digital value (0-255) to analog output via
; pulse width modulation. This allows the generation of an analog voltage by
; emitting a burst of output high (5V) and low (0V) values whose ratio is
; proportional to the duty value specified. The duration is the amount of time
; the signal is generated to allow the analog device to average the voltage
; over time to duty/256* 5 volts.
;
; Inputs:
;   p  - index (0-15) of the I/O pin to set. Pin is initially set to output
;	then to input mode when the command finishes.
;   u1 - the duty (0-255) of analog output as the number of 256ths of 5V.
;   u2 - the duration of the PWM output in mS.
; Outputs:
;   None
;------------------------------------------------------------------------------
        HEADER  "PBPWM", PBPWM_ENTRY, PBPWM_CFA, 0, PBPULSOUT_ENTRY
        CODEPTR PBPWM_CODE
        PUBLIC  PBPWM_CODE
        .a16
        .i16
                PHY                     ; Preserve IP
                JSR     PBOUTPUT_IMPL
                STA     4,X             ; Save port mask
                POP
                TAY
                JSR     PBPWMMASK_IMPL
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PBPWMMASK ( m u1 u2 -- ) converts a digital value u1 to an analog output via
; pulse width modulation using a port mask m for a durations u2 (1-65535) ms
; pbPWMmask - implementation of PWM, but uses port mask instead of index.
; This allows a PWM signal to multipe pins concurrently. Useful for multi
; axis motor control. Caller is required to put all pins to output mode and 
; synthesize the port mask.
; Inputs:
;   m  - port mask
;   u1 - the duty (0-255) of analog output as the number of 256ths of 5V.
;   u2 - the duration of the PWM output in mS.
; Outputs:
;   None
;------------------------------------------------------------------------------
        HEADER  "PBPWMMASK", PBPWMMASK_ENTRY, PBPWMMASK_CFA, 0, PBPWM_ENTRY
        CODEPTR PBPWMMASK_CODE
        PUBLIC  PBPWMMASK_CODE
        .a16
        .i16
                PHY                     ; Preserve IP
                POP
                TAY
                JSR     PBPWMMASK_IMPL
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

        ; Note Y contains duration
        .proc   PBPWMMASK_IMPL
                PSP_SAVE = 5
                DUTY_CYCLE = 3
                PORT_MASK = 1
                PHD                     ; preserve direct page register
                PHX                     ; preserve PSP
                POP                     ; u1 duty cycle
                PHA                     ; initialize duty cycle stack local
                POP
                PHA                     ; initialize port mask stack local
                TSC                     ; point direct page to stack frame
                TCD

                LDA    DUTY_CYCLE       ; clamp the input to 1 to $ff
                AND    #$00FF
                BEQ    @return
                STA    DUTY_CYCLE
@while:
                OFF16MEM                ; enter byte transfer mode.
                STZ    VIA_ACR          ; select one shot mode
                LDA    #<ONE_MS         ; one ms delay duration
                STA    VIA_T2CL         ; set lower latch
                LDA    #>ONE_MS
                STA    VIA_T2CH         ; set upper latch
                ON16MEM
@loop:          ; generate waveform here
                LDA    PORT_MASK
                TSB    VIA_PRB          ; use mask to set pin high
                LDX    DUTY_CYCLE       ; keep high during duty cycle
@duty_wait:
                DEX
                BNE    @duty_wait
                LDA    PORT_MASK
                TRB    VIA_PRB          ; use mask to set pin low

                LDA    #$0100           ; compute remainder
                SEC
                SBC    DUTY_CYCLE
                TAX
@remainder_wait:                        ; keep low during remainder
                DEX
                BNE    @remainder_wait

                OFF16MEM
                LDA    #T2IF            ; start mask
                BIT    VIA_IFR          ; time out?
                ON16MEM
                BEQ    @loop
                LDA    VIA_T2CL         ; clear timer 2 interrupt
                DEY
                BNE    @while           ; loop until no ms left

@return:                                ; clean up stack and return
                PLA                     ; clean off port mask
                PLA                     ; clean off duty cycle
                PLX                     ; restore PSP
                PLD
                RTS
        .endproc

;------------------------------------------------------------------------------
; PBRCTIME ( p f -- t ) measures the time a pin remains in its initial state.
; This allows  measurement of the charge/discharge time of resistor/capacitor
; (RC) circuit and indirectly an analog value via the RC circuit charge or
; discharge time.
; Commonly used with R or C sensors such as thermistors or potentiometers.
; Inputs:
;   p - index (0-15) of the I/O pin to set. Pin is set to input.
;   f - Initial state either FORTH_TRUE or FORTH_LOW to measure. Once Pin is
;	 not in State, the command ends and returns that time.
; Outputs:
;   t - time measured in cpu cycles.
;------------------------------------------------------------------------------
        HEADER  "PBRCTIME", PBRCTIME_ENTRY, PBRCTIME_CFA, 0, PBPWMMASK_ENTRY
        CODEPTR PBRCTIME_CODE
        PUBLIC  PBRCTIME_CODE
        .a16
        .i16
                SAVED_IP      = 5       ; saved IP
                INITIAL_VALUE = 3
                PORT_MASK     = 1
                PHY                     ; Preserve IP
                PEA     $0000           ; reserve space for the initial value.
                JSR     PBINPUT_IMPL    ; set pin to input and get port mask.
                PHA                     ; initialize port mask stack local
                LDY     TOS,X
                CPY     #FORTH_TRUE     ; test desired initial value
                BNE     @skip
                STA     INITIAL_VALUE,S	; set initial value bit using port mask.
@skip:
                OFF16MEM                ; start VIA timer
                STZ     VIA_ACR         ; select one shot mode
                LDA     #$FF            ; load timer with maximum value.
                STA     VIA_T2CL        ; set lower latch
                STA     VIA_T2CH        ; set upper latch
                ON16MEM
@while:
                LDA     PORT_MASK,S
                AND     VIA_PRB         ; get the current value.
                EOR     INITIAL_VALUE,S	; test for edge transition.
                BNE     @trailing_edge
                OFF16MEM                ; has timer reached zero?
                LDA     #T2IF           ; start mask
                BIT     VIA_IFR         ; time out?
                ON16MEM
                BEQ     @while
@trailing_edge:
                LDA     #$FFFF
                SEC
                SBC     VIA_T2CL        ; get value and clear timer 2 interrupt
                STA     TOS,X           ; Put to TOS
                PLA                     ; clean up stack
                PLA
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PBTOGGLE ( p -- ) inverts the state of an output pin.
; Inputs:
;   p - index (0-15) of the I/O pin to set. Pin is set to output mode.
; Outputs:
;   None, C clobbered
;------------------------------------------------------------------------------
        HEADER  "PBTOGGLE", PBTOGGLE_ENTRY, PBTOGGLE_CFA, 0, PBRCTIME_ENTRY
        CODEPTR PBTOGGLE_CODE
        PUBLIC  PBTOGGLE_CODE
        .a16
        .i16
                POP                     ; pop p
                PHY                     ; Preserve IP
                JSR     PBOUTPUT_IMPL   ; set pin to output and get port mask.
                EOR     VIA_PRB
                STA     VIA_PRB
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC
