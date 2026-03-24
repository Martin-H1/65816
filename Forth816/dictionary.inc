;==============================================================================
; dictionary.inc - Forward declarations and word name constants
;
; Included by forth.s and primitives.s so all files can reference
; CFA labels and constants without ordering dependencies.

.ifndef DICTIONARY_INC
DICTIONARY_INC = 1
;==============================================================================

;------------------------------------------------------------------------------
; Flag constants (also defined in forth.s but repeated here for includes)
;------------------------------------------------------------------------------
F_IMMEDIATE     = $80
F_HIDDEN        = $40
F_LENMASK       = $1F

;------------------------------------------------------------------------------
; Forward declarations for all CFA labels
; (Defined in primitives.s / dictionary.s)
;------------------------------------------------------------------------------

; Stack words
        .global DUP_CFA
        .global DROP_CFA
        .global SWAP_CFA
        .global OVER_CFA
        .global ROT_CFA
        .global NIP_CFA
        .global TUCK_CFA
        .global TWODROP_CFA
        .global TWODUP_CFA
        .global TWOSWAP_CFA
        .global TWOOVER_CFA
        .global DEPTH_CFA
        .global PICK_CFA

; Return stack words
        .global TOR_CFA
        .global RFROM_CFA
        .global RFETCH_CFA

; Arithmetic words
        .global PLUS_CFA
        .global MINUS_CFA
        .global STAR_CFA
        .global SLASH_CFA
        .global MOD_CFA
        .global SLASHMOD_CFA
        .global NEGATE_CFA
        .global ABS_CFA
        .global MAX_CFA
        .global MIN_CFA
        .global ONEPLUS_CFA
        .global ONEMINUS_CFA
        .global TWOSTAR_CFA
        .global TWOSLASH_CFA
        .global UMSTAR_CFA
        .global UMSLASHMOD_CFA

; Comparison words
        .global EQUAL_CFA
        .global NOTEQUAL_CFA
        .global LESS_CFA
        .global GREATER_CFA
        .global ULESS_CFA
        .global UGREATER_CFA
        .global ZEROEQ_CFA
        .global ZEROLESS_CFA
        .global ZEROGT_CFA

; Logic words
        .global AND_CFA
        .global OR_CFA
        .global XOR_CFA
        .global INVERT_CFA
        .global LSHIFT_CFA
        .global RSHIFT_CFA

; Memory words
        .global FETCH_CFA
        .global STORE_CFA
        .global CFETCH_CFA
        .global CSTORE_CFA
        .global TWOFETCH_CFA
        .global TWOSTORE_CFA
        .global MOVE_CFA
        .global FILL_CFA

; I/O words
        .global EMIT_CFA
        .global KEY_CFA
        .global KEYQ_CFA
        .global TYPE_CFA
        .global CR_CFA
        .global SPACE_CFA
        .global SPACES_CFA

; Dictionary/compile words
        .global HERE_CFA
        .global ALLOT_CFA
        .global COMMA_CFA
        .global CCOMMA_CFA
        .global LATEST_CFA
        .global EXECUTE_CFA
        .global EXIT_CFA
        .global LIT_CFA
        .global BRANCH_CFA
        .global ZBRANCH_CFA
        .global DODO_CFA
        .global DOLOOP_CFA
        .global DOPLUSLOOP_CFA
        .global UNLOOP_CFA
        .global I_CFA
        .global J_CFA

; System words
        .global QUIT_CFA
        .global QUIT_BODY
        .global ABORT_CFA
        .global ABORT_CODE
        .global ABORTQ_CFA
        .global DOABORTQ_CFA
        .global BYE_CFA

; String/parse words
        .global WORD_CFA
        .global FIND_CFA
        .global NUMBER_CFA
        .global COUNT_CFA
        .global DOTQUOTE_CFA
        .global SQUOTE_CFA

; Output words
        .global DOT_CFA
        .global UDOT_CFA
        .global DOTHEX_CFA
        .global DOTS_CFA
        .global WORDS_CFA

; Defining words
        .global COLON_CFA
        .global SEMICOLON_CFA
        .global CONSTANT_CFA
        .global VARIABLE_CFA
        .global CREATE_CFA
        .global DOES_CFA

; User area words
        .global BASE_CFA
        .global STATE_CFA
        .global TOIN_CFA
        .global SOURCE_CFA

; Last word in ROM dictionary (used by FORTH_INIT)
        .global LAST_WORD

; Inner interpreter entry points (defined in forth.s)
        .global DOCOL
        .global DOVAR
        .global DOCON
        .global DODOES

; Arithmetic helpers
        .global UMSLASHMOD_IMPL
        .global SLASHMOD_IMPL

; HAL functions (defined in hal.s)
        .global hal_putch
        .global hal_getch
        .global hal_kbhit
        .global hal_cputs
        .global hal_lpputs

.endif ; DICTIONARY_INC
