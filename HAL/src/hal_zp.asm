; =============================================================================
; hal_zp.asm — HAL zero page variable declarations
;
; The HAL owns $00–$0F (16 bytes) of page zero.
; Programs may use $10–$FF freely.
;
; These are .res declarations only — no code, no initialisation here.
; hal_init zeros this region at boot.
; =============================================================================

        .p816
        .smart  off

        .exportzp hal_tmp0, hal_tmp1, hal_tmp2, hal_tmp3
        .exportzp hal_tmp_ptr, hal_dp_save, hal_flags, hal_errflg

        .segment "ZEROPAGE"

hal_zp_base = $00           ; for documentation — first HAL ZP byte

hal_tmp0:   .res 1          ; $00 — general scratch byte A
hal_tmp1:   .res 1          ; $01 — general scratch byte B
hal_tmp2:   .res 1          ; $02 — general scratch byte C
hal_tmp3:   .res 1          ; $03 — general scratch byte D
hal_tmp_ptr:.res 2          ; $04–$05 — scratch 16-bit pointer (ZP indirect)
hal_dp_save:.res 2          ; $06–$07 — saves caller DP across HAL calls
hal_flags:  .res 1          ; $08 — internal HAL state flags
hal_errflg: .res 1          ; $09 — error flags (overrun, framing, etc.)
            .res 6          ; $0A–$0F — reserved for future HAL use

; End of HAL zero page region. Programs start at $10.
