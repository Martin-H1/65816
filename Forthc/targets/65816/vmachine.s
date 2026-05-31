; =============================================================================
; vmachine.s  —  65816 runtime routines
;
; These implement the more complex VM operations that cannot be expressed
; as short inline macros.  They are called via JSR and return with RTS.
;
; Conventions:
;   X  = parameter stack pointer (TOS at 0,X)
;   All routines preserve X unless they explicitly push/pop stack items.
;   16-bit A and X throughout (REP #$30 assumed at entry).
; =============================================================================

.p816
.smart
.include "vmachine.inc"

; ---------------------------------------------------------------------------
; vm_star  —  ( n1 n2 -- n3 )   16×16 → 16 multiply
; ---------------------------------------------------------------------------
; 65816 has no multiply instruction; we use a shift-and-add loop.
; For a production system, replace with a hardware multiply if available.
; ---------------------------------------------------------------------------
vm_star:
        LDA  0,X                    ; multiplicand n2 (TOS)
        INX
        INX
        STA  vm_tmp1                ; save n2
        LDA  0,X                    ; multiplier n1
        LDY  #0                     ; accumulator
        LDX  #16                    ; 16 bits
@loop:
        LSR  A                      ; shift multiplier right
        BCC  @skip
        TYA
        CLC
        ADC  vm_tmp1                ; add multiplicand to accumulator
        TAY
@skip:
        ASL  vm_tmp1                ; shift multiplicand left
        DEX
        BNE  @loop
        ; Restore X (stack pointer was saved in outer context)
        ; We modified X as a loop counter above — reload it
        ; This is tricky: we need the stack pointer.
        ; Solution: use vm_sp shadow variable.
        LDX  vm_sp_shadow
        TYA
        STA  0,X                    ; store result
        RTS

; ---------------------------------------------------------------------------
; vm_slash  —  ( n1 n2 -- n3 )   signed 16/16 division
; ---------------------------------------------------------------------------
vm_slash:
        JSR  vm_divmod
        INX                         ; discard remainder
        INX
        RTS

; ---------------------------------------------------------------------------
; vm_mod  —  ( n1 n2 -- n3 )   modulo
; ---------------------------------------------------------------------------
vm_mod:
        JSR  vm_divmod
        LDA  2,X                    ; remainder → TOS
        STA  0,X
        INX
        INX
        RTS

; ---------------------------------------------------------------------------
; vm_slashmod  —  ( n1 n2 -- rem quot )
; ---------------------------------------------------------------------------
vm_slashmod:
        JMP  vm_divmod

; ---------------------------------------------------------------------------
; vm_divmod  — internal: ( n1 n2 -- rem quot )
; Uses repeated subtraction (replace with hardware-accelerated version
; for production use).
; ---------------------------------------------------------------------------
vm_divmod:
        LDA  0,X                    ; divisor
        BNE  @ok
        ; Division by zero — push 0 0
        STZ  0,X
        STZ  2,X
        RTS
@ok:
        ; Sign handling omitted for brevity; extend as needed.
        LDA  2,X                    ; dividend n1
        LDY  #0                     ; quotient
@loop:
        CMP  0,X                    ; dividend >= divisor?
        BCC  @done
        SEC
        SBC  0,X                    ; dividend -= divisor
        INY
        BRA  @loop
@done:
        ; A = remainder, Y = quotient
        STA  2,X                    ; remainder (NOS)
        TYA
        STA  0,X                    ; quotient (TOS)
        RTS

; ---------------------------------------------------------------------------
; Bitwise operations
; ---------------------------------------------------------------------------
vm_and:
        LDA  2,X
        AND  0,X
        INX
        INX
        STA  0,X
        RTS

vm_or:
        LDA  2,X
        ORA  0,X
        INX
        INX
        STA  0,X
        RTS

vm_xor:
        LDA  2,X
        EOR  0,X
        INX
        INX
        STA  0,X
        RTS

vm_not:
        LDA  0,X
        EOR  #$FFFF
        STA  0,X
        RTS

vm_lshift:
        LDA  2,X                    ; value
        LDY  0,X                    ; shift count
        INX
        INX
@loop:
        CPY  #0
        BEQ  @done
        ASL  A
        DEY
        BRA  @loop
@done:
        STA  0,X
        RTS

vm_rshift:
        LDA  2,X
        LDY  0,X
        INX
        INX
@loop:
        CPY  #0
        BEQ  @done
        LSR  A
        DEY
        BRA  @loop
@done:
        STA  0,X
        RTS

; ---------------------------------------------------------------------------
; Comparison  ( n1 n2 -- flag )
; ---------------------------------------------------------------------------
vm_lt:
        LDA  2,X
        CMP  0,X
        INX
        INX
        BCC  @true
        LDA  #0
        STA  0,X
        RTS
@true:  LDA  #$FFFF
        STA  0,X
        RTS

vm_gt:
        ; n1 > n2  ↔  n2 < n1 — swap args and call vm_lt logic
        LDA  0,X
        CMP  2,X
        INX
        INX
        BCC  @true
        LDA  #0
        STA  0,X
        RTS
@true:  LDA  #$FFFF
        STA  0,X
        RTS

vm_zeq:
        LDA  0,X
        BNE  @false
        LDA  #$FFFF
        STA  0,X
        RTS
@false: STZ  0,X
        RTS

vm_zlt:
        LDA  0,X
        BMI  @true
        STZ  0,X
        RTS
@true:  LDA  #$FFFF
        STA  0,X
        RTS

; ---------------------------------------------------------------------------
; Stack manipulation
; ---------------------------------------------------------------------------
vm_over:
        LDA  2,X
        DEX
        DEX
        STA  0,X
        RTS

vm_swap:
        LDA  0,X
        LDY  2,X
        STY  0,X
        STA  2,X
        RTS

vm_rot:         ; ( n1 n2 n3 -- n2 n3 n1 )
        LDA  4,X                    ; n1
        LDY  2,X                    ; n2
        STY  4,X
        LDY  0,X                    ; n3
        STY  2,X
        STA  0,X
        RTS

vm_2dup:        ; ( n1 n2 -- n1 n2 n1 n2 )
        LDA  2,X
        LDY  0,X
        DEX
        DEX
        DEX
        DEX
        STA  2,X
        STY  0,X
        RTS

vm_2drop:
        INX
        INX
        INX
        INX
        RTS

; ---------------------------------------------------------------------------
; DO-LOOP support
; vm_do_loop_step: increment top-of-return-stack index, compare to limit.
; Returns with TOS = 0 if loop should continue, non-zero if done.
; ---------------------------------------------------------------------------
vm_do_loop_step:
        ; The hardware stack has (top→bottom): return addr, limit, index
        ; We need to peek at index and limit.  Adjust offsets for 65816
        ; two-byte return address pushed by JSR.
        ;  SP+1,2  = return addr (already there from JSR)
        ;  SP+3,4  = index
        ;  SP+5,6  = limit
        TSX
        LDA  $0103,X                ; index (return stack is at $0100+)
        INC  A
        STA  $0103,X                ; incremented index
        CMP  $0105,X                ; compare to limit
        BNE  @continue
        ; Loop done: push non-zero (true) to P-stack
        DEX                         ; note: here X is hw stack ptr, not P-stack
        ; We need the P-stack pointer.  Use shadow.
        LDX  vm_sp_shadow
        LDA  #$FFFF
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS
@continue:
        LDX  vm_sp_shadow
        LDA  #0
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS

; ---------------------------------------------------------------------------
; I  — ( -- n )  copy loop index to parameter stack
; ---------------------------------------------------------------------------
vm_i:
        TSX
        LDA  $0103,X                ; index from return stack
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS

; ---------------------------------------------------------------------------
; J  — ( -- n )  outer loop index
; ---------------------------------------------------------------------------
vm_j:
        TSX
        LDA  $0109,X                ; outer index (2 frames deep)
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS

; ---------------------------------------------------------------------------
; I/O primitives  (platform-specific — stub implementations shown)
; Replace with actual hardware I/O for your target system.
; ---------------------------------------------------------------------------

vm_emit:        ; ( c -- )  output character
        LDA  0,X
        INX
        INX
        STX  vm_sp_shadow
        ; *** Platform I/O here ***
        ; Example: STA $C000 for Apple II, etc.
        JSR  platform_putc
        LDX  vm_sp_shadow
        RTS

vm_key:         ; ( -- c )  read character
        STX  vm_sp_shadow
        ; *** Platform I/O here ***
        JSR  platform_getc
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        RTS

vm_cputs:       ; ( addr -- )  print null-terminated string
        LDA  0,X
        INX
        INX
        TAY                         ; Y = address
@loop:
        LDA  0,Y
        BEQ  @done
        STX  vm_sp_shadow
        JSR  platform_putc
        LDX  vm_sp_shadow
        INY
        BRA  @loop
@done:
        RTS

vm_type:        ; ( addr u -- )
        LDA  0,X                    ; count
        INX
        INX
        TAY                         ; Y = count
        LDA  0,X                    ; addr
        INX
        INX
        TAX                         ; X temporarily = addr (save sp first!)
        ; Note: this shadows the P-stack pointer!  In a real implementation
        ; save vm_sp_shadow before entering the loop.
        STX  vm_tmp1
        LDA  vm_sp_shadow
        TAX                         ; restore P-stack pointer from shadow
@loop:
        CPY  #0
        BEQ  @done
        STX  vm_sp_shadow
        LDX  vm_tmp1
        LDA  0,X
        INX
        STX  vm_tmp1
        LDX  vm_sp_shadow
        JSR  platform_putc
        DEY
        BRA  @loop
@done:
        RTS

vm_cr:
        LDA  #$0D
        JSR  platform_putc
        LDA  #$0A
        JSR  platform_putc
        RTS

vm_space:
        LDA  #$20
        JMP  platform_putc

vm_spaces:      ; ( n -- )
        LDA  0,X
        INX
        INX
        TAY
@loop:
        CPY  #0
        BEQ  @done
        STX  vm_sp_shadow
        LDA  #$20
        JSR  platform_putc
        LDX  vm_sp_shadow
        DEY
        BRA  @loop
@done:
        RTS

vm_dot:         ; ( n -- )  print signed decimal  (stub: calls runtime formatter)
        JSR  vm_format_dec
        JSR  vm_cputs
        RTS

vm_udot:        ; ( u -- )  print unsigned decimal
        JSR  vm_format_udec
        JSR  vm_cputs
        RTS

; ---------------------------------------------------------------------------
; Memory operations
; ---------------------------------------------------------------------------
vm_allot:       ; ( n -- )  advance HERE by n bytes
        LDA  0,X
        INX
        INX
        CLC
        ADC  vm_here_ptr
        STA  vm_here_ptr
        RTS

vm_cells:       ; ( n -- n*2 )  multiply by cell size
        LDA  0,X
        ASL  A
        STA  0,X
        RTS

vm_cellplus:    ; ( addr -- addr+2 )
        LDA  0,X
        INC  A
        INC  A
        STA  0,X
        RTS

vm_here:        ; ( -- addr )
        DEX
        DEX
        LDA  vm_here_ptr
        STA  0,X
        RTS

vm_count:       ; ( addr -- addr+1 len )  counted string
        LDA  0,X                    ; addr
        TAY
        SEP  #$20
        LDA  0,Y                    ; length byte
        REP  #$20
        ; push addr+1
        LDA  0,X
        INC  A
        STA  0,X
        ; push len
        DEX
        DEX
        ; A still has length (zero-extended)
        STA  0,X
        RTS

vm_move:        ; ( src dst u -- )  copy u bytes from src to dst
        LDA  0,X                    ; u
        INX
        INX
        TAY
        LDA  0,X                    ; dst
        INX
        INX
        STA  vm_tmp2
        LDA  0,X                    ; src
        INX
        INX
        TAX                         ; X = src (temporarily)
@loop:
        CPY  #0
        BEQ  @done
        SEP  #$20
        LDA  0,X
        STA  (vm_tmp2)
        REP  #$20
        INX
        INC  vm_tmp2
        DEY
        BRA  @loop
@done:
        LDX  vm_sp_shadow
        RTS

vm_fill:        ; ( addr u b -- )  fill u bytes at addr with b
        LDA  0,X                    ; b
        INX
        INX
        STA  vm_tmp1
        LDA  0,X                    ; u
        INX
        INX
        TAY
        LDA  0,X                    ; addr
        INX
        INX
        STX  vm_sp_shadow
        TAX
@loop:
        CPY  #0
        BEQ  @done
        SEP  #$20
        LDA  vm_tmp1
        STA  0,X
        REP  #$20
        INX
        DEY
        BRA  @loop
@done:
        LDX  vm_sp_shadow
        RTS

; ---------------------------------------------------------------------------
; Number formatting stubs (replace with full implementations)
; ---------------------------------------------------------------------------
vm_format_dec:
        RTS                         ; TODO

vm_format_udec:
        RTS                         ; TODO

; ---------------------------------------------------------------------------
; Zero-page / RAM variables used by the runtime
; ---------------------------------------------------------------------------
.segment "ZEROPAGE"
vm_sp_shadow:   .word 0             ; shadow of X (P-stack pointer)
vm_here_ptr:    .word 0             ; HERE pointer
vm_tmp1:        .word 0             ; scratch
vm_tmp2:        .word 0             ; scratch

; ---------------------------------------------------------------------------
; Platform I/O stubs — replace with your platform's character I/O routines
; ---------------------------------------------------------------------------
.segment "CODE"
platform_putc:  ; ( A = char )
        RTS     ; *** REPLACE WITH REAL I/O ***

platform_getc:  ; ( → A = char )
        LDA  #0
        RTS     ; *** REPLACE WITH REAL I/O ***
