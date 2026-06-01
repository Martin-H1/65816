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
; Usage:
;   Generated code and vmachine.s both .include this file.
;   vmachine.s defines __vmachine_s__ = 1 before including, so the
;   .import directives below are skipped there (the symbols are defined,
;   not imported).  Every other translation unit gets the .imports.
;
; Register usage:
;   A  — scratch / TOS staging
;   X  — parameter stack pointer (points to current TOS)
;   Y  — scratch
; =============================================================================

.p816
.smart  off
.A16
.I16

; ---------------------------------------------------------------------------
; Stack-pointer initial value (must be even, in zero page)
; ---------------------------------------------------------------------------
PSTACK_INIT = $00FE                 ; empty stack: X starts here

; ---------------------------------------------------------------------------
; Conditionally import virtual machine runtime functions.
; Skipped when assembling vmachine.s itself (which exports them).
; ---------------------------------------------------------------------------
.ifndef __vmachine_s__
        .import vm_star
        .import vm_slash
        .import vm_mod
        .import vm_slashmod
        .import vm_and
        .import vm_or
        .import vm_xor
        .import vm_not
        .import vm_lshift
        .import vm_rshift
        .import vm_lt
        .import vm_gt
        .import vm_zeq
        .import vm_zlt
        .import vm_over
        .import vm_swap
        .import vm_rot
        .import vm_2dup
        .import vm_2drop
        .import vm_do_loop_step
        .import vm_i
        .import vm_j
        .import vm_emit
        .import vm_key
        .import vm_cputs
        .import vm_type
        .import vm_cr
        .import vm_space
        .import vm_spaces
        .import vm_dot
        .import vm_udot
        .import vm_allot
        .import vm_cells
        .import vm_cellplus
        .import vm_here
        .import vm_count
        .import vm_move
        .import vm_fill
        .import vm_sp_shadow
        .import vm_here_ptr
        .import vm_tmp1
        .import vm_tmp2
.endif

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
