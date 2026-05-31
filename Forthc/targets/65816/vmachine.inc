; =============================================================================
; vmachine.inc  —  65816 target
; Virtual machine macros: translate VM instructions to 65816 native code.
;
; Stack model:
;   Parameter stack (P-stack) grows DOWN in page zero, indexed by X.
;   X points to the TOP of stack (TOS).
;   Cell size is 2 bytes (16-bit).
;   Calling convention: subroutine-threaded (CALL → JSR, EXIT → RTS).
;
;   Memory layout (example, adjust with .org):
;       $0000-$00FF  zero page: parameter stack (128 bytes = 64 cells max)
;       $0100-$01FF  hardware stack (return stack, used by JSR/RTS)
;       $0200+       code and data
;
; Usage in generated code:
;   .include "vmachine.inc"
;   .include "vmachine.s"        ; runtime routines
;
; Register usage:
;   A  — scratch / TOS staging
;   X  — parameter stack pointer (points to current TOS)
;   Y  — scratch
; =============================================================================

.p816                               ; 65816 mode directives (ca65 syntax)
.smart

; ---------------------------------------------------------------------------
; Stack-pointer initial value (must be even, in zero page)
; ---------------------------------------------------------------------------
PSTACK_INIT = $00FE                 ; empty stack: X starts here

; ---------------------------------------------------------------------------
; LIT  — push a literal value onto the parameter stack
; ---------------------------------------------------------------------------
.macro  LIT  val
        DEX                         ; X -= 2  (16-bit decrement)
        DEX
        LDA  #val
        STA  0,X
.endmacro

; ---------------------------------------------------------------------------
; EXIT  — return from word (subroutine return)
; ---------------------------------------------------------------------------
.macro  EXIT
        RTS
.endmacro

; ---------------------------------------------------------------------------
; CALL  — call a word (subroutine call)
; ---------------------------------------------------------------------------
.macro  CALL  addr
        JSR  addr
.endmacro

; ---------------------------------------------------------------------------
; FETCH  @  — ( addr -- n )   fetch cell at addr
; ---------------------------------------------------------------------------
.macro  FETCH
        LDA  0,X                    ; A = addr (TOS)
        TAY                         ; Y = addr
        LDA  0,Y                    ; A = value at addr
        STA  0,X                    ; replace TOS
.endmacro

; ---------------------------------------------------------------------------
; STORE  !  — ( n addr -- )   store n at addr
; ---------------------------------------------------------------------------
.macro  STORE
        LDA  0,X                    ; A = addr (TOS)
        TAY
        INX                         ; pop addr
        INX
        LDA  0,X                    ; A = n (new TOS)
        STA  0,Y                    ; store
        INX                         ; pop n
        INX
.endmacro

; ---------------------------------------------------------------------------
; BFETCH  C@  — ( addr -- b )
; ---------------------------------------------------------------------------
.macro  BFETCH
        LDA  0,X
        TAY
        LDA  #0
        SEP  #$20                   ; 8-bit A
        LDA  0,Y
        REP  #$20                   ; 16-bit A
        STA  0,X
.endmacro

; ---------------------------------------------------------------------------
; BSTORE  C!  — ( b addr -- )
; ---------------------------------------------------------------------------
.macro  BSTORE
        LDA  0,X                    ; addr
        TAY
        INX
        INX
        SEP  #$20
        LDA  0,X                    ; b (low byte)
        STA  0,Y
        REP  #$20
        INX
        INX
.endmacro

; ---------------------------------------------------------------------------
; TOR  >R  — ( n -- ) [R: -- n]
; ---------------------------------------------------------------------------
.macro  TOR
        LDA  0,X
        INX
        INX
        PHA                         ; push A onto hardware (return) stack
.endmacro

; ---------------------------------------------------------------------------
; RFROM  R>  — ( -- n ) [R: n -- ]
; ---------------------------------------------------------------------------
.macro  RFROM
        PLA
        DEX
        DEX
        STA  0,X
.endmacro

; ---------------------------------------------------------------------------
; DUP  — ( n -- n n )
; ---------------------------------------------------------------------------
.macro  DUP
        LDA  0,X
        DEX
        DEX
        STA  0,X
.endmacro

; ---------------------------------------------------------------------------
; DROP  — ( n -- )
; ---------------------------------------------------------------------------
.macro  DROP
        INX
        INX
.endmacro

; ---------------------------------------------------------------------------
; NIP  — ( n1 n2 -- n2 )
; ---------------------------------------------------------------------------
.macro  NIP
        LDA  0,X                    ; n2
        STA  2,X                    ; overwrite n1
        INX
        INX
.endmacro

; ---------------------------------------------------------------------------
; ADD  +  — ( n1 n2 -- n3 )
; ---------------------------------------------------------------------------
.macro  ADD
        LDA  2,X                    ; n1
        CLC
        ADC  0,X                    ; + n2
        INX
        INX
        STA  0,X                    ; result
.endmacro

; ---------------------------------------------------------------------------
; SUB  -  — ( n1 n2 -- n3 )
; ---------------------------------------------------------------------------
.macro  SUB
        LDA  2,X                    ; n1
        SEC
        SBC  0,X                    ; - n2
        INX
        INX
        STA  0,X
.endmacro

; ---------------------------------------------------------------------------
; STAR  *  — ( n1 n2 -- n3 )  (calls runtime)
; This is left as a CALL because 65816 has no MUL instruction.
; ---------------------------------------------------------------------------
.macro  STAR
        JSR  vm_star
.endmacro

; ---------------------------------------------------------------------------
; EQ  =  — ( n1 n2 -- flag )   flag = $FFFF if equal, 0 otherwise
; ---------------------------------------------------------------------------
.macro  EQ
        LDA  2,X                    ; n1
        CMP  0,X                    ; compare to n2
        INX
        INX
        BEQ  :+
        LDA  #0
        BRA  :++
:       LDA  #$FFFF
:       STA  0,X
.endmacro

; ---------------------------------------------------------------------------
; ZBRANCH  — ( flag -- )  branch if flag = 0
; ---------------------------------------------------------------------------
.macro  ZBRANCH  addr
        LDA  0,X
        INX
        INX
        BEQ  addr
.endmacro

; ---------------------------------------------------------------------------
; CLEAR  — ( ... -- )  reset parameter stack
; ---------------------------------------------------------------------------
.macro  CLEAR
        LDX  #PSTACK_INIT
.endmacro

; ---------------------------------------------------------------------------
; EMIT  — ( c -- )  output character
; ---------------------------------------------------------------------------
.macro  EMIT
        JSR  vm_emit
.endmacro

; ---------------------------------------------------------------------------
; KEY  — ( -- c )  read character
; ---------------------------------------------------------------------------
.macro  KEY
        JSR  vm_key
.endmacro

; ---------------------------------------------------------------------------
; TYPE  — ( addr u -- )  output u chars at addr
; ---------------------------------------------------------------------------
.macro  TYPE
        JSR  vm_type
.endmacro

; ---------------------------------------------------------------------------
; CPUTS  — ( addr -- )  output null-terminated string
; ---------------------------------------------------------------------------
.macro  CPUTS
        JSR  vm_cputs
.endmacro

; ---------------------------------------------------------------------------
; Initialization macro — call once at program entry
; ---------------------------------------------------------------------------
.macro  VM_INIT
        REP  #$30                   ; 16-bit A and X
        LDX  #PSTACK_INIT           ; initialise parameter stack pointer
.endmacro
