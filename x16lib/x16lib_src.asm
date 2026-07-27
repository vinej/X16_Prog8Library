; 64tass
; =====================================================================
; x16lib :: x16.asm -- constants and macros (64tass edition). No code.
; =====================================================================
; The 64tass port mirrors the ACME tree file for file; src_acme/ is
; the reference implementation and this tree must behave identically
; -- the same test suite proves it.
;
;       .include "x16.asm"
;       X16_USE_VERA = 1            ; pick modules or a section gate
;       * = $0801
;       ...your code...
;       .include "x16_code.asm"     ; library routines land here
;
; Assemble CASE-SENSITIVE, ASCII, CBM output:
;       64tass -C -a --cbm-prg -I src_64tass -o PROG.PRG prog.asm
;
; -C is not optional: the jsrfar macro and the KERNAL's JSRFAR entry
; differ only in case.
;
; Include each file once (the ACME tree's include guards have no
; 64tass equivalent and were dropped).
; =====================================================================

.cpu "65c02"

; 64tass's default "none" encoding converts ASCII to PETSCII ('H'
; becomes $C8). The library's strings are raw bytes -- define an
; identity encoding so .text and character literals emit the source
; bytes unchanged, exactly as ACME's !text does.
.enc "raw"
.cdef " ~", $20

; --- inline core/const_zp.asm ---
;ACME
; =====================================================================
; x16lib :: core/const_zp.asm -- zero page and bank registers
; =====================================================================
; Pure symbol file. Safe to !source any number of times.
;
; X16 zero page (Programmer's Reference / x16-rom-r49 inc/regs.inc):
;   $00       RAM_BANK   - bank visible at $A000-$BFFF
;   $01       ROM_BANK   - bank visible at $C000-$FFFF
;   $02-$21   r0..r15    - KERNAL virtual registers (argument passing)
;   $22-$7F   free for user programs   <-- we claim 16 bytes here
;   $80-$FF   KERNAL / BASIC / DOS     <-- never touch
; =====================================================================

; (ACME include guard dropped: include this file once)

; (!addr block: plain assignments in 64tass)
RAM_BANK        = $00
ROM_BANK        = $01

; KERNAL virtual registers. Caller-save: the library uses r0..r5 freely.
r0  = $02
r0L  = $02
r0H  = $03
r1  = $04
r1L  = $04
r1H  = $05
r2  = $06
r2L  = $06
r2H  = $07
r3  = $08
r3L  = $08
r3H  = $09
r4  = $0A
r4L  = $0A
r4H  = $0B
r5  = $0C
r5L  = $0C
r5H  = $0D
r6  = $0E
r6L  = $0E
r6H  = $0F
r7  = $10
r7L  = $10
r7H  = $11
r8  = $12
r8L  = $12
r8H  = $13
r9  = $14
r9L  = $14
r9H  = $15
r10 = $16
r10L = $16
r10H = $17
r11 = $18
r11L = $18
r11H = $19
r12 = $1A
r12L = $1A
r12H = $1B
r13 = $1C
r13L = $1C
r13H = $1D
r14 = $1E
r14L = $1E
r14H = $1F
r15 = $20
r15L = $20
r15H = $21
; (end addr)

; ---------------------------------------------------------------------
; Library scratch block.
;
; Define X16_ZP yourself *before* sourcing x16.asm to relocate it, e.g.
;       X16_ZP = $60
;       .include "x16.asm"
; It must sit inside $22-$7F and needs X16_ZP_SIZE bytes.
; ---------------------------------------------------------------------
.weak
X16_ZP = $22
.endweak

X16_ZP_SIZE = 16

; (!addr block: plain assignments in 64tass)
; P0..P7: routine parameters (for calls that need more than A/X/Y).
X16_P0 = X16_ZP + 0
X16_P1 = X16_ZP + 1
X16_P2 = X16_ZP + 2
X16_P3 = X16_ZP + 3
X16_P4 = X16_ZP + 4
X16_P5 = X16_ZP + 5
X16_P6 = X16_ZP + 6
X16_P7 = X16_ZP + 7

; T0..T7: private scratch. Never live across a library call boundary.
X16_T0 = X16_ZP + 8
X16_T1 = X16_ZP + 9
X16_T2 = X16_ZP + 10
X16_T3 = X16_ZP + 11
X16_T4 = X16_ZP + 12
X16_T5 = X16_ZP + 13
X16_T6 = X16_ZP + 14
X16_T7 = X16_ZP + 15
; (end addr)

; 16-bit aliases over the same bytes.
; (!addr block: plain assignments in 64tass)
X16_PTR0 = X16_P0       ; P0/P1 as a pointer
X16_PTR1 = X16_P2       ; P2/P3 as a pointer
X16_PTR2 = X16_P4
X16_PTR3 = X16_P6
X16_TPTR0 = X16_T0
X16_TPTR1 = X16_T2
X16_TPTR2 = X16_T4
X16_TPTR3 = X16_T6
; (end addr)

.if X16_ZP < $22
    !error "X16_ZP must be >= $22 (below that is KERNAL r0..r15)"
.endif
.if (X16_ZP + X16_ZP_SIZE) > $80
    !error "X16_ZP block runs past $7F into KERNAL/BASIC zero page"
.endif
; --- inline core/const_vera.asm ---
;ACME
; =====================================================================
; x16lib :: core/const_vera.asm -- VERA registers, VRAM map, bitfields
; =====================================================================
; Pure symbol file. Safe to !source any number of times.
;
; Sources of truth:
;   doc/X16 Reference - 09 - VERA Programmer's Reference.md
;   doc/X16 Reference - 10 - VERA FX Reference.md
;   x16-rom-r49/inc/io.inc
; =====================================================================

; (ACME include guard dropped: include this file once)

VERA_BASE = $9F20

; (!addr block: plain assignments in 64tass)
VERA_ADDR_L       = VERA_BASE + $00
VERA_ADDR_M       = VERA_BASE + $01
VERA_ADDR_H       = VERA_BASE + $02   ; bank + increment index + DECR
VERA_DATA0        = VERA_BASE + $03
VERA_DATA1        = VERA_BASE + $04
VERA_CTRL         = VERA_BASE + $05   ; RESET | DCSEL(6) | ADDRSEL
VERA_IEN          = VERA_BASE + $06
VERA_ISR          = VERA_BASE + $07   ; bits 7:4 = sprite collisions
VERA_IRQ_LINE_L   = VERA_BASE + $08

; --- $9F29-$9F2C are banked by DCSEL -------------------------------
; DCSEL = 0
VERA_DC_VIDEO     = VERA_BASE + $09
VERA_DC_HSCALE    = VERA_BASE + $0A
VERA_DC_VSCALE    = VERA_BASE + $0B
VERA_DC_BORDER    = VERA_BASE + $0C
; DCSEL = 1
VERA_DC_HSTART    = VERA_BASE + $09
VERA_DC_HSTOP     = VERA_BASE + $0A
VERA_DC_VSTART    = VERA_BASE + $0B
VERA_DC_VSTOP     = VERA_BASE + $0C
; DCSEL = 2  (FX core)
VERA_FX_CTRL      = VERA_BASE + $09   ; R/W
VERA_FX_TILEBASE  = VERA_BASE + $0A   ; W
VERA_FX_MAPBASE   = VERA_BASE + $0B   ; W
VERA_FX_MULT      = VERA_BASE + $0C   ; W
; DCSEL = 3  (line/poly increments)
VERA_FX_X_INCR_L  = VERA_BASE + $09   ; W
VERA_FX_X_INCR_H  = VERA_BASE + $0A   ; W
VERA_FX_Y_INCR_L  = VERA_BASE + $0B   ; W
VERA_FX_Y_INCR_H  = VERA_BASE + $0C   ; W
; DCSEL = 4  (line/poly positions)
VERA_FX_X_POS_L   = VERA_BASE + $09   ; W
VERA_FX_X_POS_H   = VERA_BASE + $0A   ; W
VERA_FX_Y_POS_L   = VERA_BASE + $0B   ; W
VERA_FX_Y_POS_H   = VERA_BASE + $0C   ; W
; DCSEL = 5
VERA_FX_X_POS_S   = VERA_BASE + $09   ; W
VERA_FX_Y_POS_S   = VERA_BASE + $0A   ; W
VERA_FX_POLY_FILL_L = VERA_BASE + $0B ; R
VERA_FX_POLY_FILL_H = VERA_BASE + $0C ; R
; DCSEL = 6  (32-bit cache / accumulator)
VERA_FX_CACHE_L     = VERA_BASE + $09 ; W
VERA_FX_ACCUM_RESET = VERA_BASE + $09 ; R
VERA_FX_CACHE_M     = VERA_BASE + $0A ; W
VERA_FX_ACCUM       = VERA_BASE + $0A ; R
VERA_FX_CACHE_H     = VERA_BASE + $0B ; W
VERA_FX_CACHE_U     = VERA_BASE + $0C ; W
; DCSEL = 63 (version probe; DC_VER0 reads ASCII 'V')
VERA_DC_VER0      = VERA_BASE + $09   ; R
VERA_DC_VER1      = VERA_BASE + $0A   ; R  major
VERA_DC_VER2      = VERA_BASE + $0B   ; R  minor
VERA_DC_VER3      = VERA_BASE + $0C   ; R  build
; -------------------------------------------------------------------

VERA_L0_CONFIG    = VERA_BASE + $0D
VERA_L0_MAPBASE   = VERA_BASE + $0E
VERA_L0_TILEBASE  = VERA_BASE + $0F
VERA_L0_HSCROLL_L = VERA_BASE + $10
VERA_L0_HSCROLL_H = VERA_BASE + $11
VERA_L0_VSCROLL_L = VERA_BASE + $12
VERA_L0_VSCROLL_H = VERA_BASE + $13

VERA_L1_CONFIG    = VERA_BASE + $14
VERA_L1_MAPBASE   = VERA_BASE + $15
VERA_L1_TILEBASE  = VERA_BASE + $16
VERA_L1_HSCROLL_L = VERA_BASE + $17
VERA_L1_HSCROLL_H = VERA_BASE + $18
VERA_L1_VSCROLL_L = VERA_BASE + $19
VERA_L1_VSCROLL_H = VERA_BASE + $1A

VERA_AUDIO_CTRL   = VERA_BASE + $1B
VERA_AUDIO_RATE   = VERA_BASE + $1C
VERA_AUDIO_DATA   = VERA_BASE + $1D

VERA_SPI_DATA     = VERA_BASE + $1E
VERA_SPI_CTRL     = VERA_BASE + $1F

; YM2151 FM chip. NOT at $9FE0 -- see x16-rom-r49/inc/io.inc.
YM_REG            = $9F40
YM_DATA           = $9F41

; VERA_2 MiSTer SDRAM bitmap layer. This is a core-specific extension
; in the I/O expansion area, not part of stock VERA VRAM.
VERA2_CTRL        = $9F60
VERA2_ID          = $9F61
VERA2_ADDR_L      = $9F62
VERA2_ADDR_M      = $9F63
VERA2_ADDR_H      = $9F64
VERA2_DATA        = $9F65
VERA2_PAL_IDX     = $9F66
VERA2_PAL_LO      = $9F67
VERA2_PAL_HI      = $9F68
VERA2_BLIT_DST_L  = $9F69
VERA2_BLIT_DST_M  = $9F6A
VERA2_BLIT_DST_H  = $9F6B
VERA2_BLIT_LEN_L  = $9F6C
VERA2_BLIT_LEN_M  = $9F6D
VERA2_BLIT_LEN_H  = $9F6E
VERA2_BLIT_CTRL   = $9F6F
; (end addr)

; ---------------------------------------------------------------------
; CTRL bitfields.  DCSEL is SIX bits at 6:1, ADDRSEL is bit 0.
; Writing DCSEL naively clobbers ADDRSEL -- always use +vera_dcsel.
; Never set bit 7: it resets the whole chip.
; ---------------------------------------------------------------------
VERA_CTRL_ADDRSEL = %00000001
VERA_CTRL_DCSEL   = %01111110
VERA_CTRL_RESET   = %10000000

; ---------------------------------------------------------------------
; ADDR_H bitfields.  The increment field is an INDEX, not an amount.
; ---------------------------------------------------------------------
VERA_ADDR_H_BANK  = %00000001   ; VRAM address bit 16
VERA_ADDR_H_DECR  = %00001000   ; decrement instead of increment
VERA_ADDR_H_INCR  = %11110000   ; increment index, bits 7:4

VERA_INC_0   = 0
VERA_INC_1   = 1
VERA_INC_2   = 2
VERA_INC_4   = 3
VERA_INC_8   = 4
VERA_INC_16  = 5
VERA_INC_32  = 6
VERA_INC_64  = 7
VERA_INC_128 = 8
VERA_INC_256 = 9
VERA_INC_512 = 10
VERA_INC_40  = 11   ; one 40-column text row
VERA_INC_80  = 12   ; one 80-column text row
VERA_INC_160 = 13
VERA_INC_320 = 14   ; one 320-pixel bitmap row
VERA_INC_640 = 15

; ---------------------------------------------------------------------
; DC_VIDEO (DCSEL=0) bitfields.
; ---------------------------------------------------------------------
VERA_VIDEO_MODE_OFF   = 0
VERA_VIDEO_MODE_VGA   = 1
VERA_VIDEO_MODE_NTSC  = 2
VERA_VIDEO_MODE_RGB   = 3
VERA_VIDEO_CHROMA_DIS = %00000100
VERA_VIDEO_240P       = %00001000
VERA_VIDEO_LAYER0_EN  = %00010000
VERA_VIDEO_LAYER1_EN  = %00100000
VERA_VIDEO_SPRITES_EN = %01000000
VERA_VIDEO_FIELD      = %10000000   ; read-only

; ---------------------------------------------------------------------
; ISR / IEN bitfields.  ISR bits 7:4 report sprite collision groups.
; ---------------------------------------------------------------------
VERA_IRQ_VSYNC    = %00000001
VERA_IRQ_LINE     = %00000010
VERA_IRQ_SPRCOL   = %00000100
VERA_IRQ_AFLOW    = %00001000
VERA_ISR_COLLISION = %11110000

; ---------------------------------------------------------------------
; SPI_CTRL bitfields.
; ---------------------------------------------------------------------
VERA_SPI_SELECT   = %00000001   ; 1 asserts chip-select, 0 releases it
VERA_SPI_SLOWCLK  = %00000010   ; 1 = ~390 kHz, 0 = ~12.5 MHz
VERA_SPI_AUTOTX   = %00000100   ; reading SPI_DATA starts a $FF transfer
VERA_SPI_BUSY     = %10000000   ; read-only

; ---------------------------------------------------------------------
; FX_CTRL (DCSEL=2) bitfields.
; ---------------------------------------------------------------------
VERA_FX_ADDR1_NORMAL  = 0
VERA_FX_ADDR1_LINE    = 1
VERA_FX_ADDR1_POLY    = 2
VERA_FX_ADDR1_AFFINE  = 3
VERA_FX_4BIT_MODE     = %00000100
VERA_FX_16BIT_HOP     = %00001000
VERA_FX_CACHE_CYCLE   = %00010000
VERA_FX_CACHE_FILL    = %00100000
VERA_FX_CACHE_WRITE   = %01000000
VERA_FX_TRANSPARENT   = %10000000

; FX_MULT (DCSEL=2) bitfields.
VERA_FX_MULT_2BYTE_INCR = %00000001
VERA_FX_MULT_NIB_INDEX  = %00000010
VERA_FX_MULT_BYTE_INDEX = %00001100
VERA_FX_MULT_ENABLE     = %00010000
VERA_FX_MULT_SUBTRACT   = %00100000
VERA_FX_MULT_ACCUMULATE = %01000000
VERA_FX_MULT_RESET_ACC  = %10000000

VERA_DCSEL_FX_VERSION = 63
VERA_VERSION_MAGIC    = $56          ; 'V' in DC_VER0

; ---------------------------------------------------------------------
; Layer CONFIG bitfields.
; ---------------------------------------------------------------------
VERA_LAYER_BPP_1      = 0
VERA_LAYER_BPP_2      = 1
VERA_LAYER_BPP_4      = 2
VERA_LAYER_BPP_8      = 3
VERA_LAYER_T256C      = %00001000    ; 256-colour text
VERA_LAYER_BITMAP     = %00000100    ; bitmap instead of tile mode
; Map size, bits 7:6 = height, 5:4 = width (0=32,1=64,2=128,3=256 tiles)
VERA_LAYER_MAPW_32    = %00000000
VERA_LAYER_MAPW_64    = %00010000
VERA_LAYER_MAPW_128   = %00100000
VERA_LAYER_MAPW_256   = %00110000
VERA_LAYER_MAPH_32    = %00000000
VERA_LAYER_MAPH_64    = %01000000
VERA_LAYER_MAPH_128   = %10000000
VERA_LAYER_MAPH_256   = %11000000

; ---------------------------------------------------------------------
; VERA_2 MiSTer SDRAM bitmap layer bitfields.
; ---------------------------------------------------------------------
VERA2_ID_MAGIC         = $B5
VERA2_CTRL_ENABLE     = %00000001
VERA2_CTRL_MODE_8BPP  = %00000010
VERA2_CTRL_MODE_4BPP  = %00000100
VERA2_CTRL_PASSTHRU   = %00001000

VERA2_INC_1      = $0
VERA2_INC_0      = $1
VERA2_INC_2      = $2
VERA2_INC_4      = $3
VERA2_INC_8      = $4
VERA2_INC_16     = $5
VERA2_INC_32     = $6
VERA2_INC_64     = $7
VERA2_INC_128    = $8
VERA2_INC_256    = $9
VERA2_INC_320    = $A
VERA2_INC_640    = $B
VERA2_INC_NEG1   = $C
VERA2_INC_NEG2   = $D
VERA2_INC_NEG320 = $E
VERA2_INC_NEG640 = $F

; ---------------------------------------------------------------------
; VRAM map.  17-bit addresses: bit 16 is the "bank" in ADDR_H.
;
; NOTE: $1F9C0-$1FFFF (PSG, palette, sprite attributes) is WRITE-ONLY.
; Reads return the last value the host wrote, not the register's real
; state.  Reading back your own writes is fine; inferring hardware state
; after a reset is not.
; ---------------------------------------------------------------------
VRAM_BITMAP       = $00000       ; default 320x240x256 framebuffer
VRAM_SPRITE_DATA  = $13000       ; KERNAL's sprite image area
VRAM_TEXT         = $1B000       ; default text-mode tilemap
VRAM_CHARSET      = $1F000
VRAM_PSG          = $1F9C0       ; 16 voices x 4 bytes
VRAM_PALETTE      = $1FA00       ; 256 entries x 2 bytes
VRAM_SPRITE_ATTR  = $1FC00       ; 128 sprites x 8 bytes

; The FX multiplier writes its 32-bit result to VRAM rather than to a
; register, so it needs four scratch bytes. $1F800-$1F9BF is unused in
; the VERA memory map. Redefine before sourcing x16.asm to relocate.
.weak
VRAM_FX_SCRATCH = $1F800
.endweak

VERA_PSG_VOICE_SIZE   = 4
VERA_SPRITE_ATTR_SIZE = 8

; Sprite attribute byte offsets (see VERA reference "Sprite attributes").
SPRITE_ATTR_ADDR_L   = 0    ; image address bits 12:5
SPRITE_ATTR_ADDR_H   = 1    ; bit7 = mode (0=4bpp,1=8bpp), bits 3:0 = addr 16:13
SPRITE_ATTR_X_L      = 2
SPRITE_ATTR_X_H      = 3    ; bits 1:0 = X 9:8
SPRITE_ATTR_Y_L      = 4
SPRITE_ATTR_Y_H      = 5    ; bits 1:0 = Y 9:8
SPRITE_ATTR_FLAGS    = 6    ; collision mask 7:4 | Z 3:2 | vflip 1 | hflip 0
SPRITE_ATTR_SIZE_PAL = 7    ; height 7:6 | width 5:4 | palette offset 3:0

SPRITE_MODE_4BPP  = %00000000
SPRITE_MODE_8BPP  = %10000000

SPRITE_Z_DISABLED = %00000000
SPRITE_Z_BEHIND   = %00000100   ; between background and layer 0
SPRITE_Z_MIDDLE   = %00001000   ; between layer 0 and layer 1
SPRITE_Z_FRONT    = %00001100   ; in front of layer 1
SPRITE_HFLIP      = %00000001
SPRITE_VFLIP      = %00000010

SPRITE_SIZE_8     = 0
SPRITE_SIZE_16    = 1
SPRITE_SIZE_32    = 2
SPRITE_SIZE_64    = 3
; --- inline core/const_kernal.asm ---
;ACME
; =====================================================================
; x16lib :: core/const_kernal.asm -- the $FExx/$FFxx KERNAL jump table
; =====================================================================
; Pure symbol file. Safe to !source any number of times.
;
; Transcribed from x16-rom-r49/kernal/vectors.s (segment JMPTBL, which
; cfg/kernal-x16.cfgtpl places at $FEA8). These are the *stable public*
; entry points -- do not call the implementation addresses in the const_kernal_sym
; files, they move between ROM revisions.
;
; Every ROM bank carries a bridge stub for this table (see the ROM's
; kernsup/ directory), so `jsr CHROUT` works whatever ROM bank is active.
; =====================================================================

; (ACME include guard dropped: include this file once)

; (!addr block: plain assignments in 64tass)
; --- X16 extensions ($FEA8-$FF7D) ----------------------------------
EXTAPI16                = $FEA8
EXTAPI                  = $FEAB
MCIOUT                  = $FEB1
I2C_BATCH_READ          = $FEB4
I2C_BATCH_WRITE         = $FEB7
SAVEHL                  = $FEBA
KBDBUF_PEEK             = $FEBD
KBDBUF_GET_MODIFIERS    = $FEC0
KBDBUF_PUT              = $FEC3
I2C_READ_BYTE           = $FEC6
I2C_WRITE_BYTE          = $FEC9
MONITOR                 = $FECC
ENTROPY_GET             = $FECF
KEYMAP                  = $FED2
CONSOLE_SET_PAGING_MESSAGE = $FED5
CONSOLE_PUT_IMAGE       = $FED8
CONSOLE_INIT            = $FEDB
CONSOLE_PUT_CHAR        = $FEDE
CONSOLE_GET_CHAR        = $FEE1
MEMORY_FILL             = $FEE4
MEMORY_COPY             = $FEE7
MEMORY_CRC              = $FEEA
MEMORY_DECOMPRESS       = $FEED
SPRITE_SET_IMAGE        = $FEF0
SPRITE_SET_POSITION     = $FEF3

; Framebuffer API
FB_INIT                 = $FEF6
FB_GET_INFO             = $FEF9
FB_SET_PALETTE          = $FEFC
FB_CURSOR_POSITION      = $FEFF
FB_CURSOR_NEXT_LINE     = $FF02
FB_GET_PIXEL            = $FF05
FB_GET_PIXELS           = $FF08
FB_SET_PIXEL            = $FF0B
FB_SET_PIXELS           = $FF0E
FB_SET_8_PIXELS         = $FF11
FB_SET_8_PIXELS_OPAQUE  = $FF14
FB_FILL_PIXELS          = $FF17
FB_FILTER_PIXELS        = $FF1A
FB_MOVE_PIXELS          = $FF1D

; Graphics API (lives in BANK_GRAPH, reached through these stubs)
GRAPH_INIT              = $FF20
GRAPH_CLEAR             = $FF23
GRAPH_SET_WINDOW        = $FF26
GRAPH_SET_COLORS        = $FF29
GRAPH_DRAW_LINE         = $FF2C
GRAPH_DRAW_RECT         = $FF2F
GRAPH_MOVE_RECT         = $FF32
GRAPH_DRAW_OVAL         = $FF35
GRAPH_DRAW_IMAGE        = $FF38
GRAPH_SET_FONT          = $FF3B
GRAPH_GET_CHAR_SIZE     = $FF3E
GRAPH_PUT_CHAR          = $FF41

MACPTR                  = $FF44
ENTER_BASIC             = $FF47
CLOSE_ALL               = $FF4A
CLOCK_SET_DATE_TIME     = $FF4D
CLOCK_GET_DATE_TIME     = $FF50
JOYSTICK_SCAN           = $FF53
JOYSTICK_GET            = $FF56
LKUPLA                  = $FF59
LKUPSA                  = $FF5C
SCREEN_MODE             = $FF5F
SCREEN_SET_CHARSET      = $FF62
MOUSE_CONFIG            = $FF68
MOUSE_GET               = $FF6B
JSRFAR                  = $FF6E   ; jsr JSRFAR : .word addr : .byte bank
MOUSE_SCAN              = $FF71
INDFET                  = $FF74
STASH                   = $FF77
PRIMM                   = $FF7D

; --- classic C64-compatible table ($FF81-$FFF3) --------------------
CINT                    = $FF81   ; restore default text mode
IOINIT                  = $FF84
RAMTAS                  = $FF87
RESTOR                  = $FF8A
VECTOR                  = $FF8D
SETMSG                  = $FF90
SECOND                  = $FF93
TKSA                    = $FF96
MEMTOP                  = $FF99
MEMBOT                  = $FF9C
SCNKEY                  = $FF9F
SETTMO                  = $FFA2
ACPTR                   = $FFA5
CIOUT                   = $FFA8
UNTLK                   = $FFAB
UNLSN                   = $FFAE
LISTEN                  = $FFB1
TALK                    = $FFB4
READST                  = $FFB7
SETLFS                  = $FFBA
SETNAM                  = $FFBD
OPEN                    = $FFC0
CLOSE                   = $FFC3
CHKIN                   = $FFC6
CHKOUT                  = $FFC9
CLRCHN                  = $FFCC
CHRIN                   = $FFCF
CHROUT                  = $FFD2
LOAD                    = $FFD5
SAVE                    = $FFD8
SETTIM                  = $FFDB
RDTIM                   = $FFDE
STOP                    = $FFE1
GETIN                   = $FFE4
CLALL                   = $FFE7
UDTIM                   = $FFEA
SCREEN                  = $FFED
PLOT                    = $FFF0
IOBASE                  = $FFF3
; (end addr)

; ---------------------------------------------------------------------
; KERNAL editor variables.
;
; NOT part of the jump table -- these are internal addresses, verified
; against x16-rom-r49 (kernal/cbm/editor.s, kernal.sym). They can move
; between ROM revisions, unlike everything above.
; ---------------------------------------------------------------------
; (!addr block: plain assignments in 64tass)
KERNAL_COLOR = $0376    ; active text colour: fg | bg<<4
; (end addr)

; ---------------------------------------------------------------------
; KERNAL indirect vectors.
; ---------------------------------------------------------------------
; (!addr block: plain assignments in 64tass)
CINV  = $0314           ; IRQ handler vector
CBINV = $0316           ; BRK handler vector
NMINV = $0318           ; NMI handler vector
; (end addr)

; ---------------------------------------------------------------------
; Selected PETSCII / control codes.
; ---------------------------------------------------------------------
PETSCII_WHITE     = $05
PETSCII_RETURN    = $0D
PETSCII_LOWERCASE = $0E
PETSCII_CLS       = $93
PETSCII_HOME      = $13
PETSCII_UPPERCASE = $8E
; --- inline core/const_rom.asm ---
;ACME
; =====================================================================
; x16lib :: core/const_rom.asm -- ROM banks and their $C000 entry points
; =====================================================================
; Pure symbol file. Safe to !source any number of times.
;
; The audio and graphics APIs are NOT in the $FFxx KERNAL table. They
; live at $C000+ inside their own ROM bank and must be reached with
; +jsrfar (or +rom_call_fast). See core/macros.asm.
;
; Transcribed from x16-rom-r49/inc/banks.inc, audio.inc, graphics.inc.
; =====================================================================

; (ACME include guard dropped: include this file once)

BANK_KERNAL  = $00
BANK_KEYBD   = $01
BANK_CBDOS   = $02
BANK_FAT32   = $03
BANK_BASIC   = $04
BANK_MONITOR = $05
BANK_CHARSET = $06
BANK_DIAG    = $07
BANK_GRAPH   = $08
BANK_DEMO    = $09
BANK_AUDIO   = $0A
BANK_UTIL    = $0B
BANK_BANNEX  = $0C
BANK_X16EDIT = $0D          ; occupies two banks
BANK_BASLOAD = $0F

; ---------------------------------------------------------------------
; BANK_AUDIO entry points (x16-rom-r49/inc/audio.inc).
;
; ym_* / psg_* keep the ROM driver's volume and pan shadows coherent.
; Writing YM_REG/YM_DATA directly does not -- that is the AUDIOYM.TXT
; distinction between FMPOKE (via ROM) and YM! (raw).
; ---------------------------------------------------------------------
; (!addr block: plain assignments in 64tass)
rom_bas_fmfreq          = $C000
rom_bas_fmnote          = $C003
rom_bas_fmplaystring    = $C006
rom_bas_fmvib           = $C009
rom_bas_playstringvoice = $C00C
rom_bas_psgfreq         = $C00F
rom_bas_psgnote         = $C012
rom_bas_psgwav          = $C015
rom_bas_psgplaystring   = $C018
rom_notecon_bas2fm      = $C01B
rom_notecon_bas2midi    = $C01E
rom_notecon_bas2psg     = $C021
rom_notecon_fm2bas      = $C024
rom_notecon_fm2midi     = $C027
rom_notecon_fm2psg      = $C02A
rom_notecon_freq2bas    = $C02D
rom_notecon_freq2fm     = $C030
rom_notecon_freq2midi   = $C033
rom_notecon_freq2psg    = $C036
rom_notecon_midi2bas    = $C039
rom_notecon_midi2fm     = $C03C
rom_notecon_midi2psg    = $C03F
rom_notecon_psg2bas     = $C042
rom_notecon_psg2fm      = $C045
rom_notecon_psg2midi    = $C048
rom_psg_init            = $C04B
rom_psg_playfreq        = $C04E
rom_psg_read            = $C051
rom_psg_setatten        = $C054
rom_psg_setfreq         = $C057
rom_psg_setpan          = $C05A
rom_psg_setvol          = $C05D
rom_psg_write           = $C060
rom_ym_init             = $C063
rom_ym_loaddefpatches   = $C066
rom_ym_loadpatch        = $C069
rom_ym_loadpatchlfn     = $C06C
rom_ym_playdrum         = $C06F
rom_ym_playnote         = $C072
rom_ym_setatten         = $C075
rom_ym_setdrum          = $C078
rom_ym_setnote          = $C07B
rom_ym_setpan           = $C07E
rom_ym_read             = $C081
rom_ym_release          = $C084
rom_ym_trigger          = $C087
rom_ym_write            = $C08A
rom_bas_fmchordstring   = $C08D
rom_bas_psgchordstring  = $C090
rom_psg_getatten        = $C093
rom_psg_getpan          = $C096
rom_ym_getatten         = $C099
rom_ym_getpan           = $C09C
rom_audio_init          = $C09F
rom_psg_write_fast      = $C0A2
rom_ym_get_chip_type    = $C0A5
; (end addr)

; ---------------------------------------------------------------------
; BANK_BASIC floating-point jump table.
;
; The ROM ships a C128/C65-compatible FP library. Its jump table sits at
; $FE00 inside BANK_BASIC (cfg/basic-x16.cfgtpl: FPJMP start = $FE00)
; and is a stable ABI -- unlike the implementation addresses in
; basic.sym, which move between ROM revisions.
;
; 52 entries. The six after fp_poly are compiled out (`const_rom_if 0` in
; math/jumptab.s) and read back as $AA fill. Do not call them.
;
; Everything operates on FAC, the floating accumulator in zero page.
; Pointer arguments are A = low byte, Y = high byte.
;
; CAUTION: fp_fsub and fp_fdiv are the reverse of what the comments in
; jumptab.s claim. Each does `jsr conupk` (ARG = mem) and then falls into
; the ARG-first form, so what you actually get is
;       fp_fsub:  FAC = mem - FAC          (NOT FAC - mem)
;       fp_fdiv:  FAC = mem / FAC
;       fp_fsubt: FAC = ARG - FAC
;       fp_fdivt: FAC = ARG / FAC
; util/float.asm wraps these back into the intuitive direction.
; ---------------------------------------------------------------------
; (!addr block: plain assignments in 64tass)
fp_ayint  = $FE00       ; facmo:faclo = (s16)FAC, high byte first
fp_givayf = $FE03       ; FAC = (s16) A:Y        (A = high, Y = low)
fp_fout   = $FE06       ; FAC -> ASCIIZ at FP_FBUFFR; returns A/Y = ptr
fp_val    = $FE09       ; FAC = value of the string at X:Y, length A
fp_getadr = $FE0C       ; A:Y = (u16)FAC         (A = high, Y = low)
fp_floatc = $FE0F
fp_fsub   = $FE12       ; FAC = mem(A,Y) - FAC
fp_fsubt  = $FE15       ; FAC = ARG - FAC
fp_fadd   = $FE18       ; FAC = FAC + mem(A,Y)
fp_faddt  = $FE1B       ; FAC = FAC + ARG
fp_fmult  = $FE1E       ; FAC = FAC * mem(A,Y)
fp_fmultt = $FE21       ; FAC = FAC * ARG
fp_fdiv   = $FE24       ; FAC = mem(A,Y) / FAC
fp_fdivt  = $FE27       ; FAC = ARG / FAC
fp_log    = $FE2A       ; FAC = ln(FAC)
fp_int    = $FE2D       ; FAC = int(FAC)
fp_sqr    = $FE30       ; FAC = sqrt(FAC)
fp_negop  = $FE33       ; FAC = -FAC  (the real unary minus)
fp_fpwr   = $FE36       ; FAC = mem(A,Y) ^ FAC
fp_fpwrt  = $FE39       ; FAC = ARG ^ FAC
fp_exp    = $FE3C       ; FAC = e ^ FAC
fp_cos    = $FE3F       ; destroys ARG
fp_sin    = $FE42       ; destroys ARG
fp_tan    = $FE45       ; destroys ARG
fp_atn    = $FE48       ; destroys ARG
fp_round  = $FE4B
fp_abs    = $FE4E       ; FAC = |FAC|
fp_sign   = $FE51       ; A = sgn(FAC): $FF, 0 or 1
fp_fcomp  = $FE54       ; A = compare FAC with mem(A,Y): $FF, 0 or 1
fp_rnd    = $FE57
fp_conupk = $FE5A       ; ARG = mem(A,Y)
fp_movfm  = $FE60       ; FAC = mem(A,Y)
fp_movmf  = $FE66       ; mem(X,Y) = round(FAC)  (X = low, Y = high)
fp_movfa  = $FE69       ; FAC = ARG
fp_movaf  = $FE6C       ; ARG = round(FAC)
fp_faddh  = $FE6F       ; FAC += 0.5
fp_zerofc = $FE72       ; FAC = 0
fp_normal = $FE75
fp_negfac = $FE78       ; CAUTION: not a negate. Internal helper of the
                        ; add/subtract path: two's-complements the FAC
                        ; mantissa in place, denormalising a normal FAC.
                        ; Use fp_negop for -FAC.
fp_mul10  = $FE7B       ; FAC *= 10
fp_div10  = $FE7E       ; FAC /= 10
fp_movef  = $FE81       ; ARG = FAC
fp_sgn    = $FE84       ; FAC = sgn(FAC)
fp_float  = $FE87       ; FAC = (s8)A -- SIGNED: 200 comes out -56.
                        ; For an unsigned byte go through fp_givayf
                        ; with a zero high byte (util/float.asm does).
fp_floats = $FE8A       ; FAC = (s16) facho:facho+1
fp_qint   = $FE8D       ; facho..faclo = (u32)FAC, most significant first
fp_finlog = $FE90       ; FAC += (s8)A
fp_foutc  = $FE93
fp_polyx  = $FE96
fp_poly   = $FE99
; (end addr)

; ---------------------------------------------------------------------
; The floating accumulator and argument, in BASIC's zero page.
;
; A float packed in memory is 5 bytes; unpacked in FAC it is 6, with the
; sign broken out into its own byte. Safe to disturb from a SYSed
; program, because BASIC is dormant while it runs.
; ---------------------------------------------------------------------
; (!addr block: plain assignments in 64tass)
FP_FAC    = $C3
FP_FACEXP = $C3
FP_FACHO  = $C4         ; mantissa, most significant byte
FP_FACMOH = $C5
FP_FACMO  = $C6
FP_FACLO  = $C7         ; mantissa, least significant byte
FP_FACSGN = $C8
FP_ARG    = $CA
FP_ARGEXP = $CA
FP_ARGSGN = $CF
FP_FACOV  = $D1
FP_FBUFFR = $0100       ; fp_fout writes its ASCIIZ result here
; (end addr)

FP_SIZE = 5             ; bytes of a packed float in memory

; ---------------------------------------------------------------------
; BANK_GRAPH entry points (x16-rom-r49/inc/graphics.inc).
; Most of these are also reachable through the $FFxx stubs in
; core/const_kernal.asm, which is the preferred route.
; ---------------------------------------------------------------------
; (!addr block: plain assignments in 64tass)
gr_GRAPH_clear                = $C000
gr_GRAPH_draw_image           = $C003
gr_GRAPH_draw_line            = $C006
gr_GRAPH_draw_oval            = $C009
gr_GRAPH_draw_rect            = $C00C
gr_GRAPH_init                 = $C00F
gr_GRAPH_move_rect            = $C012
gr_GRAPH_set_colors           = $C015
gr_GRAPH_set_window           = $C018
gr_GRAPH_get_char_size        = $C01B
gr_GRAPH_put_char             = $C01E
gr_GRAPH_set_font             = $C021
gr_font_init                  = $C024
gr_console_init               = $C027
gr_console_put_char           = $C02A
gr_console_get_char           = $C02D
gr_console_put_image          = $C030
gr_console_set_paging_message = $C033
gr_set_window_fullscreen      = $C036
gr_FB_init                    = $C039
gr_FB_get_info                = $C03C
gr_FB_set_palette             = $C03F
gr_default_palette            = $C063
; (end addr)
; --- inline core/macros.asm ---
; 64tass
; =====================================================================
; x16lib :: core/macros.asm -- inlined plumbing (64tass edition)
; =====================================================================
; The same macro layer the dist bindings carry
; (dist/templates/64tass-macros.inc). Invoke with '#'.
; =====================================================================

; ---------------------------------------------------------------------
; x16lib macro layer, hand-ported from src/core/macros.asm for 64tass.
;
; Requires the 65C02 instruction set (trb/tsb):
;       .cpu "65c02"
;
; IMPORTANT: assemble with case-sensitive symbols (64tass -C). The
; jsrfar MACRO wraps the KERNAL's JSRFAR entry point CONSTANT, and the
; two names differ only in case.
;
; Invoke macros with '#':   #vera_addr 0, VRAM_TEXT, VERA_INC_1
; ---------------------------------------------------------------------

; select which data port the ADDR registers refer to (clobbers A).
; ADDRSEL is bit 0 of CTRL; a read-modify-write via trb/tsb keeps DCSEL.
vera_addrsel .macro port
        lda #VERA_CTRL_ADDRSEL
        .if \port == 0
        trb VERA_CTRL
        .else
        tsb VERA_CTRL
        .endif
        .endm

; select the $9F29-$9F2C register bank (0-63). Preserves ADDRSEL.
; Never writes bit 7 (that resets VERA).
vera_dcsel .macro n
        .cerror \n > 63, "DCSEL must be 0-63"
        lda VERA_CTRL
        and #VERA_CTRL_ADDRSEL
        ora #(\n << 1)
        sta VERA_CTRL
        .endm

; point a data port at a 17-bit VRAM address. `inc` is an INDEX, not a
; byte count -- use the VERA_INC_* constants.
vera_addr .macro port, addr, inc
        .cerror \addr > $1FFFF, "VRAM address must be 17-bit"
        .cerror \inc > 15, "use a VERA_INC_* constant, not a byte count"
        #vera_addrsel \port
        lda #<(\addr)
        sta VERA_ADDR_L
        lda #>(\addr)
        sta VERA_ADDR_M
        lda #(((\addr >> 16) & $01) | (\inc << 4))
        sta VERA_ADDR_H
        .endm

; the same, but decrementing.
vera_addr_decr .macro port, addr, inc
        #vera_addrsel \port
        lda #<(\addr)
        sta VERA_ADDR_L
        lda #>(\addr)
        sta VERA_ADDR_M
        lda #(((\addr >> 16) & $01) | VERA_ADDR_H_DECR | (\inc << 4))
        sta VERA_ADDR_H
        .endm

; one-off VRAM byte write. Clobbers A, flags.
vpoke .macro addr, value
        #vera_addr 0, \addr, VERA_INC_0
        lda #\value
        sta VERA_DATA0
        .endm

set_rambank .macro n
        lda #\n
        sta RAM_BANK
        .endm

set_rombank .macro n
        lda #\n
        sta ROM_BANK
        .endm

; call a routine in another ROM/RAM bank via the KERNAL's own $FF6E
; mechanism. Preserves A/X/Y and flags, reentrant. Do NOT hand-roll
; the bank switch -- see src/core/macros.asm for why.
jsrfar .macro addr, bank
        jsr JSRFAR
        .word \addr
        .byte \bank
        .endm

; ~40 cycles cheaper than jsrfar, but CLOBBERS A and leaves ROM_BANK
; set to `bank`. Not IRQ-safe.
rom_call_fast .macro bank, entry
        lda #\bank
        sta ROM_BANK
        jsr \entry
        .endm

; load a 16-bit literal into a 2-byte little-endian buffer (i16_a etc.)
i16_const .macro dest, value
        lda #<(\value)
        sta \dest
        lda #>(\value)
        sta \dest+1
        .endm

; load a 32-bit literal into a 4-byte little-endian buffer (i32_a etc.)
i32_const .macro dest, value
        lda #<(\value)
        sta \dest
        lda #>(\value)
        sta \dest+1
        lda #((\value >> 16) & $FF)
        sta \dest+2
        lda #((\value >> 24) & $FF)
        sta \dest+3
        .endm

; emit `10 SYS 2061` so the PRG autoruns. Must land at exactly $0801;
; machine code then begins at $080D (= 2061).
basic_stub .macro
        .word $080B             ; link to the end-of-program marker
        .word 10                ; line number
        .byte $9E               ; SYS token
        .text "2061"            ; = $080D
        .byte $00               ; end of line
        .word $0000             ; end of program
        .endm
; 64tass
; =====================================================================
; x16lib :: x16_code.asm -- the library routines (64tass edition)
; =====================================================================
; GENERATED from src_acme/x16_code.asm by tools/acme2tass.py -- do
; not edit by hand. 64tass selects modules by VALUE, not .ifdef
; definedness: each gate gets a .weak = 0 default, then xuse_*
; folds in the same dependency closure the ACME !ifdef gates
; encode. Add a gate in src_acme and it appears here on regen.
; =====================================================================

.weak
X16_USE_VERA = 0
X16_USE_VIDEO = 0
X16_USE_VERA_DC = 0
X16_USE_SCREEN = 0
X16_USE_PALETTE = 0
X16_USE_TILE = 0
X16_USE_SPRITE = 0
X16_USE_GRAPHICS = 0
X16_USE_BITMAP8L = 0
X16_USE_BITMAP8H = 0
X16_USE_BITMAP2H = 0
X16_USE_BITMAP2L = 0
X16_USE_BITMAP4L = 0
X16_USE_BITMAP4H = 0
X16_USE_FB = 0
X16_USE_GRAPH = 0
X16_USE_CONSOLE = 0
X16_USE_SHAPES = 0
X16_USE_SHAPES_POLY = 0
X16_USE_SHAPES_RRECT = 0
X16_USE_SHAPES_ARC = 0
X16_USE_SHAPES_PIE = 0
X16_USE_SHAPES_BEZIER = 0
X16_USE_VERAFX = 0
X16_USE_VERAFX_UTILS = 0
X16_USE_AUDIO = 0
X16_USE_PSG = 0
X16_USE_YM = 0
X16_USE_AUDIO_ROM = 0
X16_USE_ZSM = 0
X16_USE_ZSM_PCM = 0
X16_USE_PCM = 0
X16_USE_PCM_STREAM = 0
X16_USE_ADPCM = 0
X16_USE_WAV = 0
X16_USE_INPUT_DEVICES = 0
X16_USE_INPUT = 0
X16_USE_KEYBOARD = 0
X16_USE_MOUSE = 0
X16_USE_COMMUNICATIONS = 0
X16_USE_I2C = 0
X16_USE_VERA_SPI = 0
X16_USE_SERIAL = 0
X16_USE_SERIAL_ZIMODEM = 0
X16_USE_STORAGE = 0
X16_USE_BANK = 0
X16_USE_BANKALLOC = 0
X16_USE_STACK = 0
X16_USE_RINGBUFFER = 0
X16_USE_MEM = 0
X16_USE_FILEIO = 0
X16_USE_IEC = 0
X16_USE_LOAD = 0
X16_USE_DOS = 0
X16_USE_DIR = 0
X16_USE_FILEPICK = 0
X16_USE_BMX = 0
X16_USE_UTILITIES = 0
X16_USE_MATH = 0
X16_USE_CLIP = 0
X16_USE_BUFFERS = 0
X16_USE_ZX0 = 0
X16_USE_TSC = 0
X16_USE_FIXED = 0
X16_USE_BCD = 0
X16_USE_COLLIDE = 0
X16_USE_BITS = 0
X16_USE_NUMBER = 0
X16_USE_INT16 = 0
X16_USE_INT32 = 0
X16_USE_FLOAT = 0
X16_USE_DOUBLE = 0
X16_USE_SORT = 0
X16_USE_STRINGS = 0
X16_USE_STRING = 0
X16_USE_STRING_CTYPE = 0
X16_USE_STRING_CASE = 0
X16_USE_STRING_FIND = 0
X16_USE_STRING_SLICE = 0
X16_USE_STRING_SORT = 0
X16_USE_SYSTEM = 0
X16_USE_IRQ = 0
X16_USE_CLOCK = 0
X16_USE_FILEPICK_EDIT = 0
X16_USE_INPUT_KEYWAIT = 0
X16_USE_SCREEN_EXTRA = 0
X16_USE_SHP_LINE = 0
X16_USE_VERAFX_FILL = 0
X16_USE_VERAFX_MULT = 0
X16_USE_VERAFX_COPY = 0
X16_USE_VERAFX_TRANSP = 0
X16_USE_VERAFX_AFFINE = 0
X16_USE_VERAFX_LINE = 0
X16_USE_VERAFX_TRI = 0
X16_USE_VERAFX_LINETRI = 0
X16_USE_VERA_CORE = 0
X16_USE_VERA_COPY = 0
X16_USE_VERA_ADDR = 0
X16_USE_VERA_FILL = 0
X16_USE_VERA_FXPROBE = 0
X16_USE_IRQ_CORE = 0
X16_USE_IRQ_REMOVE = 0
X16_USE_IRQ_VSYNC = 0
X16_USE_IRQ_SPRCOL = 0
X16_USE_IRQ_SPRCOL_API = 0
X16_USE_INPUT_CORE = 0
X16_USE_SCREEN_CORE = 0
X16_BITMAP2L_NO_INIT = 0
X16_BITMAP4L_MIN = 0
X16_BITMAP4L_NO_INIT = 0
X16_BITMAP8L_MIN = 0
X16_BITMAP8L_NO_INIT = 0
X16_SKIP_BASE = 0
X16_SKIP_MATH = 0
X16_SKIP_SHAPES = 0
.endweak

; --- the dependency closure (generated from the ACME gates) ---
xuse_video = X16_USE_VIDEO != 0
xuse_graphics = X16_USE_GRAPHICS != 0
xuse_audio = X16_USE_AUDIO != 0
xuse_input_devices = X16_USE_INPUT_DEVICES != 0
xuse_communications = X16_USE_COMMUNICATIONS != 0
xuse_storage = X16_USE_STORAGE != 0
xuse_utilities = X16_USE_UTILITIES != 0
xuse_strings = X16_USE_STRINGS != 0
xuse_system = X16_USE_SYSTEM != 0
xuse_filepick_edit = X16_USE_FILEPICK_EDIT != 0
xuse_vera_dc = xuse_video || X16_USE_VERA_DC != 0
xuse_palette = xuse_video || X16_USE_PALETTE != 0
xuse_tile = xuse_video || X16_USE_TILE != 0
xuse_sprite = xuse_video || X16_USE_SPRITE != 0
xuse_bitmap8l = xuse_graphics || X16_USE_BITMAP8L != 0
xuse_bitmap8h = xuse_graphics || X16_USE_BITMAP8H != 0
xuse_bitmap2l = xuse_graphics || X16_USE_BITMAP2L != 0
xuse_bitmap4l = xuse_graphics || X16_USE_BITMAP4L != 0
xuse_bitmap4h = xuse_graphics || X16_USE_BITMAP4H != 0
xuse_fb = xuse_graphics || X16_USE_FB != 0
xuse_graph = xuse_graphics || X16_USE_GRAPH != 0
xuse_console = xuse_graphics || X16_USE_CONSOLE != 0
xuse_shapes_poly = xuse_graphics || X16_USE_SHAPES_POLY != 0
xuse_shapes_rrect = xuse_graphics || X16_USE_SHAPES_RRECT != 0
xuse_shapes_pie = xuse_graphics || X16_USE_SHAPES_PIE != 0
xuse_shapes_bezier = xuse_graphics || X16_USE_SHAPES_BEZIER != 0
xuse_verafx = xuse_graphics || X16_USE_VERAFX != 0
xuse_verafx_utils = xuse_graphics || X16_USE_VERAFX_UTILS != 0
xuse_psg = xuse_audio || X16_USE_PSG != 0
xuse_ym = xuse_audio || X16_USE_YM != 0
xuse_audio_rom = xuse_audio || X16_USE_AUDIO_ROM != 0
xuse_zsm_pcm = xuse_audio || X16_USE_ZSM_PCM != 0
xuse_adpcm = xuse_audio || X16_USE_ADPCM != 0
xuse_wav = xuse_audio || X16_USE_WAV != 0
xuse_keyboard = xuse_input_devices || X16_USE_KEYBOARD != 0
xuse_i2c = xuse_communications || X16_USE_I2C != 0
xuse_vera_spi = xuse_communications || X16_USE_VERA_SPI != 0
xuse_serial_zimodem = xuse_communications || X16_USE_SERIAL_ZIMODEM != 0
xuse_bankalloc = xuse_storage || X16_USE_BANKALLOC != 0
xuse_stack = xuse_storage || X16_USE_STACK != 0
xuse_ringbuffer = xuse_storage || X16_USE_RINGBUFFER != 0
xuse_mem = xuse_storage || X16_USE_MEM != 0
xuse_fileio = xuse_storage || X16_USE_FILEIO != 0 || xuse_filepick_edit
xuse_iec = xuse_storage || X16_USE_IEC != 0
xuse_load = xuse_storage || X16_USE_LOAD != 0
xuse_filepick = xuse_storage || X16_USE_FILEPICK != 0 || xuse_filepick_edit
xuse_bmx = xuse_storage || X16_USE_BMX != 0
xuse_clip = xuse_utilities || X16_USE_CLIP != 0
xuse_buffers = xuse_utilities || X16_USE_BUFFERS != 0
xuse_zx0 = xuse_utilities || X16_USE_ZX0 != 0
xuse_tsc = xuse_utilities || X16_USE_TSC != 0
xuse_fixed = xuse_utilities || X16_USE_FIXED != 0
xuse_bcd = xuse_utilities || X16_USE_BCD != 0
xuse_collide = xuse_utilities || X16_USE_COLLIDE != 0
xuse_bits = xuse_utilities || X16_USE_BITS != 0
xuse_int16 = xuse_utilities || X16_USE_INT16 != 0
xuse_int32 = xuse_utilities || X16_USE_INT32 != 0
xuse_float = xuse_utilities || X16_USE_FLOAT != 0
xuse_double = xuse_utilities || X16_USE_DOUBLE != 0
xuse_sort = xuse_utilities || X16_USE_SORT != 0
xuse_string_ctype = xuse_strings || X16_USE_STRING_CTYPE != 0
xuse_string_case = xuse_strings || X16_USE_STRING_CASE != 0
xuse_string_find = xuse_strings || X16_USE_STRING_FIND != 0
xuse_string_slice = xuse_strings || X16_USE_STRING_SLICE != 0
xuse_string_sort = xuse_strings || X16_USE_STRING_SORT != 0
xuse_screen = xuse_video || X16_USE_SCREEN != 0 || xuse_filepick || xuse_bitmap8l
xuse_shapes_arc = xuse_graphics || X16_USE_SHAPES_ARC != 0 || xuse_shapes_pie
xuse_zsm = xuse_audio || X16_USE_ZSM != 0 || xuse_zsm_pcm
xuse_pcm_stream = xuse_audio || X16_USE_PCM_STREAM != 0 || xuse_zsm_pcm
xuse_input = xuse_input_devices || X16_USE_INPUT != 0 || xuse_filepick
xuse_mouse = xuse_input_devices || X16_USE_MOUSE != 0 || xuse_filepick
xuse_serial = xuse_communications || X16_USE_SERIAL != 0 || xuse_serial_zimodem
xuse_bank = xuse_storage || X16_USE_BANK != 0 || xuse_filepick
xuse_dos = xuse_storage || X16_USE_DOS != 0 || xuse_filepick
xuse_dir = xuse_storage || X16_USE_DIR != 0 || xuse_filepick
xuse_number = xuse_utilities || X16_USE_NUMBER != 0 || xuse_int16
xuse_string = xuse_strings || X16_USE_STRING != 0 || xuse_string_sort
xuse_clock = xuse_system || X16_USE_CLOCK != 0 || xuse_filepick
xuse_verafx_mult = xuse_verafx || X16_USE_VERAFX_MULT != 0
xuse_verafx_copy = xuse_verafx || X16_USE_VERAFX_COPY != 0
xuse_verafx_transp = xuse_verafx || X16_USE_VERAFX_TRANSP != 0
xuse_verafx_affine = xuse_verafx || X16_USE_VERAFX_AFFINE != 0
xuse_verafx_line = xuse_verafx || X16_USE_VERAFX_LINE != 0
xuse_verafx_tri = xuse_verafx || X16_USE_VERAFX_TRI != 0
xuse_pcm = xuse_audio || X16_USE_PCM != 0 || xuse_pcm_stream
xuse_math = xuse_utilities || X16_USE_MATH != 0 || xuse_shapes_poly || xuse_shapes_arc
xuse_irq = xuse_system || X16_USE_IRQ != 0 || xuse_pcm_stream
xuse_input_keywait = xuse_filepick_edit || X16_USE_INPUT_KEYWAIT != 0 || xuse_input
xuse_screen_extra = xuse_filepick || X16_USE_SCREEN_EXTRA != 0 || xuse_screen
xuse_shp_line = xuse_shapes_arc || X16_USE_SHP_LINE != 0 || xuse_shapes_bezier
xuse_verafx_linetri = xuse_verafx_line || X16_USE_VERAFX_LINETRI != 0 || xuse_verafx_tri
xuse_input_core = xuse_input || X16_USE_INPUT_CORE != 0
xuse_screen_core = xuse_screen || X16_USE_SCREEN_CORE != 0
xuse_shapes = xuse_graphics || X16_USE_SHAPES != 0 || xuse_shapes_poly || xuse_shapes_pie || xuse_shapes_arc || xuse_shapes_rrect || xuse_shapes_bezier || xuse_shp_line
xuse_irq_core = xuse_irq || X16_USE_IRQ_CORE != 0
xuse_irq_remove = xuse_irq || X16_USE_IRQ_REMOVE != 0
xuse_irq_vsync = xuse_irq || X16_USE_IRQ_VSYNC != 0
xuse_irq_sprcol_api = xuse_irq || X16_USE_IRQ_SPRCOL_API != 0
xuse_input_any = xuse_input_core || xuse_input_keywait
xuse_screen_any = xuse_screen_core || xuse_screen_extra
xuse_bitmap2h = xuse_graphics || X16_USE_BITMAP2H != 0 || xuse_shapes
xuse_irq_sprcol = xuse_irq || X16_USE_IRQ_SPRCOL != 0 || xuse_irq_sprcol_api
xuse_vera = xuse_video || X16_USE_VERA != 0 || xuse_sprite || xuse_psg || xuse_bitmap8l || xuse_bitmap2h || xuse_bitmap2l || xuse_bitmap4l
xuse_verafx_fill = xuse_bitmap2h || X16_USE_VERAFX_FILL != 0 || xuse_bitmap2l || xuse_verafx
xuse_irq_any = xuse_irq_core || xuse_irq_remove || xuse_irq_vsync || xuse_irq_sprcol
xuse_verafx_any = xuse_verafx_mult || xuse_verafx_fill || xuse_verafx_copy || xuse_verafx_transp || xuse_verafx_affine || xuse_verafx_line || xuse_verafx_tri
xuse_vera_core = xuse_vera || X16_USE_VERA_CORE != 0
xuse_vera_copy = xuse_vera || X16_USE_VERA_COPY != 0 || xuse_screen_extra
xuse_vera_addr = xuse_vera_core || X16_USE_VERA_ADDR != 0
xuse_vera_fill = xuse_vera_core || X16_USE_VERA_FILL != 0
xuse_vera_fxprobe = xuse_vera_core || X16_USE_VERA_FXPROBE != 0
xuse_vera_any = xuse_vera_addr || xuse_vera_fill || xuse_vera_fxprobe || xuse_vera_copy

; --- modules (the ACME tree's order) ---
.if xuse_vera_any
; --- inline video/vera.asm ---
;ACME
; =====================================================================
; x16lib :: video/vera.asm -- VRAM data-port access
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Register contract: A, X, Y and flags are clobbered unless a routine
; says otherwise. Scratch is X16_T0..T2.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; vera_set_addr0 / vera_set_addr1
;   in:  A = ADDR_L, X = ADDR_M, Y = ADDR_H (bank | DECR | incr<<4)
;   out: the chosen port points at that address
;
; The runtime equivalent of +vera_addr, for addresses not known at
; assembly time. Compose Y yourself, or use vera_set_addr0_inc below.
;
; A program that only fills does not need these, so they are behind
; X16_USE_VERA_ADDR (X16_USE_VERA / X16_USE_VERA_CORE still pull them in).
; ---------------------------------------------------------------------
.if xuse_vera_addr
vera_set_addr0
    pha
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL               ; ADDRSEL = 0
    pla
    sta VERA_ADDR_L
    stx VERA_ADDR_M
    sty VERA_ADDR_H
    rts

vera_set_addr1
    pha
    lda #VERA_CTRL_ADDRSEL
    tsb VERA_CTRL               ; ADDRSEL = 1
    pla
    sta VERA_ADDR_L
    stx VERA_ADDR_M
    sty VERA_ADDR_H
    rts
.endif

; ---------------------------------------------------------------------
; vera_fill
;   in:  A = byte value
;        X = count low, Y = count high   (16-bit, 0 means write nothing)
;   pre: caller has pointed port 0 at the destination, with the
;        increment it wants (VERA_INC_1 for a linear run, VERA_INC_320
;        to stripe down a bitmap column, etc.)
;
; The tight `sta VERA_DATA0` loop -- far faster than a per-byte address
; reload. This is GAME.TXT's VFILL.
;
; Behind X16_USE_VERA_FILL (X16_USE_VERA / X16_USE_VERA_CORE still pull it).
; ---------------------------------------------------------------------
.if xuse_vera_fill
vera_fill
    sta X16_T0                  ; value
    stx X16_T1                  ; count lo
    sty X16_T2                  ; count hi

    txa
    ora X16_T2
    beq _done                   ; count == 0

    ldx X16_T1
    ldy X16_T2
    txa
    beq _full                   ; low byte 0 -> exactly hi*256 bytes
    iny                         ; otherwise one extra partial page
_full
    lda X16_T0
_loop
    sta VERA_DATA0
    dex
    bne _loop
    dey
    bne _loop
_done
    rts
.endif

; ---------------------------------------------------------------------
; vera_copy
;   in:  X = count low, Y = count high
;   pre: port 0 points at the SOURCE (read), port 1 at the DESTINATION
;        (write), each with its own increment.
;
; DATA0 always reads port 0 and DATA1 always writes port 1, whatever
; ADDRSEL says -- so the inner loop never touches CTRL and never
; reloads an address. Two bytes per iteration, both auto-incrementing.
;
;   +vera_addr 0, src, VERA_INC_1
;   +vera_addr 1, dst, VERA_INC_1
;   ldx #<len : ldy #>len : jsr vera_copy
;
; A VERA->VERA blit; a program that only fills does not need it, so it is
; behind X16_USE_VERA_COPY (X16_USE_VERA still pulls it, for compat).
; ---------------------------------------------------------------------
.if xuse_vera_copy
vera_copy
    stx X16_T1
    sty X16_T2

    txa
    ora X16_T2
    beq _done

    ldx X16_T1
    ldy X16_T2
    txa
    beq _full
    iny
_full
_loop
    lda VERA_DATA0
    sta VERA_DATA1
    dex
    bne _loop
    dey
    bne _loop
_done
    rts
.endif

; ---------------------------------------------------------------------
; vera_has_fx
;   out: carry set if VERA firmware supports the FX register set
;        A = major version (only meaningful when carry is set)
;
; Probes DCSEL=63, where DC_VER0 reads back ASCII 'V' on FX-capable
; VERA. Restores DCSEL to 0 on the way out.
;
; Behind X16_USE_VERA_FXPROBE (X16_USE_VERA / X16_USE_VERA_CORE still pull it).
; ---------------------------------------------------------------------
.if xuse_vera_fxprobe
vera_has_fx
    #vera_dcsel VERA_DCSEL_FX_VERSION
    lda VERA_DC_VER0
    cmp #VERA_VERSION_MAGIC
    bne _no
    lda VERA_DC_VER1            ; major release
    pha
    #vera_dcsel 0
    pla
    sec
    rts
_no
    #vera_dcsel 0
    lda #0
    clc
    rts
.endif

; (end zone)
.endif
.if xuse_vera_dc
; --- inline video/vdc.asm ---
;ACME
; =====================================================================
; x16lib :: video/vdc.asm -- VERA display composer helpers
; =====================================================================
; Gate: X16_USE_VERA_DC
;
; The display composer is the DCSEL=0/1 view of $9F29-$9F2C:
; output mode, layer enables, scaling, border colour, active display
; window, and bitstream version registers.
;
; Routines leave DCSEL = 0. A/X/Y and flags are clobbered unless the
; routine documents a return value.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; vdc_get_video / vdc_set_video
;   get out: A = DC_VIDEO
;   set in:  A = DC_VIDEO value, bit 7 ignored
; ---------------------------------------------------------------------
vdc_get_video
    #vera_dcsel 0
    lda VERA_DC_VIDEO
    rts

vdc_set_video
    pha
    #vera_dcsel 0
    pla
    and #%01111111
    sta VERA_DC_VIDEO
    rts

; ---------------------------------------------------------------------
; vdc_set_output
;   in: A = VERA_VIDEO_MODE_* value, preserving other DC_VIDEO bits
; ---------------------------------------------------------------------
vdc_set_output
    and #%00000011
    sta X16_T0
    #vera_dcsel 0
    lda VERA_DC_VIDEO
    and #%01111100
    ora X16_T0
    sta VERA_DC_VIDEO
    rts

; ---------------------------------------------------------------------
; vdc_set_layers
;   in: A = any mix of VERA_VIDEO_LAYER0_EN/LAYER1_EN/SPRITES_EN
; ---------------------------------------------------------------------
vdc_set_layers
    and #(VERA_VIDEO_LAYER0_EN | VERA_VIDEO_LAYER1_EN | VERA_VIDEO_SPRITES_EN)
    sta X16_T0
    #vera_dcsel 0
    lda VERA_DC_VIDEO
    and #%00001111
    ora X16_T0
    sta VERA_DC_VIDEO
    rts

; ---------------------------------------------------------------------
; vdc_layer_on / vdc_layer_off
;   in: A = layer/sprite enable mask
; ---------------------------------------------------------------------
vdc_layer_on
    and #(VERA_VIDEO_LAYER0_EN | VERA_VIDEO_LAYER1_EN | VERA_VIDEO_SPRITES_EN)
    pha
    #vera_dcsel 0
    pla
    tsb VERA_DC_VIDEO
    rts

vdc_layer_off
    and #(VERA_VIDEO_LAYER0_EN | VERA_VIDEO_LAYER1_EN | VERA_VIDEO_SPRITES_EN)
    pha
    #vera_dcsel 0
    pla
    trb VERA_DC_VIDEO
    rts

; ---------------------------------------------------------------------
; vdc_get_scale / vdc_set_scale
;   get out: A = HSCALE, X = VSCALE
;   set in:  A = HSCALE, X = VSCALE
;            $80 means one output pixel per input pixel.
; ---------------------------------------------------------------------
vdc_get_scale
    #vera_dcsel 0
    lda VERA_DC_HSCALE
    ldx VERA_DC_VSCALE
    rts

vdc_set_scale
    sta X16_T0
    stx X16_T1
    #vera_dcsel 0
    lda X16_T0
    sta VERA_DC_HSCALE
    lda X16_T1
    sta VERA_DC_VSCALE
    rts

; ---------------------------------------------------------------------
; vdc_get_border / vdc_set_border
;   get out: A = border palette index
;   set in:  A = border palette index
; ---------------------------------------------------------------------
vdc_get_border
    #vera_dcsel 0
    lda VERA_DC_BORDER
    rts

vdc_set_border
    pha
    #vera_dcsel 0
    pla
    sta VERA_DC_BORDER
    rts

; ---------------------------------------------------------------------
; vdc_get_active_raw
;   out: A = HSTART, X = HSTOP, Y = VSTART, r0L = VSTOP
;
; Raw registers are native display coordinates with low bits omitted:
; HSTART/HSTOP = pixel / 4, VSTART/VSTOP = pixel / 2.
; ---------------------------------------------------------------------
vdc_get_active_raw
    #vera_dcsel 1
    lda VERA_DC_HSTART
    sta X16_T0
    lda VERA_DC_HSTOP
    sta X16_T1
    lda VERA_DC_VSTART
    sta X16_T2
    lda VERA_DC_VSTOP
    sta r0L
    #vera_dcsel 0
    lda X16_T0
    ldx X16_T1
    ldy X16_T2
    rts

; ---------------------------------------------------------------------
; vdc_set_active_raw
;   in: A = HSTART, X = HSTOP, Y = VSTART, r0L = VSTOP
; ---------------------------------------------------------------------
vdc_set_active_raw
    sta X16_T0
    stx X16_T1
    sty X16_T2
    lda r0L
    sta X16_T3
    jmp _vdc_store_active_t

; ---------------------------------------------------------------------
; vdc_set_active
;   in: X16_P0/P1 = HSTART pixels, X16_P2/P3 = HSTOP pixels
;       X16_P4/P5 = VSTART pixels, X16_P6/P7 = VSTOP pixels
;
; Pixel values are converted to composer register values:
; horizontal / 4, vertical / 2.
; ---------------------------------------------------------------------
vdc_set_active
    lda X16_P0
    lsr
    lsr
    sta X16_T0
    lda X16_P1
    and #%00000011
    asl
    asl
    asl
    asl
    asl
    asl
    ora X16_T0
    sta X16_T0

    lda X16_P2
    lsr
    lsr
    sta X16_T1
    lda X16_P3
    and #%00000011
    asl
    asl
    asl
    asl
    asl
    asl
    ora X16_T1
    sta X16_T1

    lda X16_P4
    lsr
    sta X16_T2
    lda X16_P5
    and #%00000001
    asl
    asl
    asl
    asl
    asl
    asl
    asl
    ora X16_T2
    sta X16_T2

    lda X16_P6
    lsr
    sta X16_T3
    lda X16_P7
    and #%00000001
    asl
    asl
    asl
    asl
    asl
    asl
    asl
    ora X16_T3
    sta X16_T3
    jmp _vdc_store_active_t

; ---------------------------------------------------------------------
; vdc_fullscreen -- active area = 0,0 to 640,480
; ---------------------------------------------------------------------
vdc_fullscreen
    stz X16_T0
    lda #160
    sta X16_T1
    stz X16_T2
    lda #240
    sta X16_T3
    jmp _vdc_store_active_t

_vdc_store_active_t
    #vera_dcsel 1
    lda X16_T0
    sta VERA_DC_HSTART
    lda X16_T1
    sta VERA_DC_HSTOP
    lda X16_T2
    sta VERA_DC_VSTART
    lda X16_T3
    sta VERA_DC_VSTOP
    #vera_dcsel 0
    rts

; ---------------------------------------------------------------------
; vdc_get_version
;   out: carry set if version is valid
;        A = major, X = minor, Y = build
;        carry clear and A/X/Y = 0 if DC_VER0 is not 'V'
; ---------------------------------------------------------------------
vdc_get_version
    #vera_dcsel VERA_DCSEL_FX_VERSION
    lda VERA_DC_VER0
    cmp #VERA_VERSION_MAGIC
    bne _no
    lda VERA_DC_VER1
    sta X16_T0
    lda VERA_DC_VER2
    sta X16_T1
    lda VERA_DC_VER3
    sta X16_T2
    #vera_dcsel 0
    lda X16_T0
    ldx X16_T1
    ldy X16_T2
    sec
    rts
_no
    #vera_dcsel 0
    lda #0
    tax
    tay
    clc
    rts

; (end zone)
.endif
.if xuse_screen_any
; --- inline video/screen.asm ---
;ACME
; =====================================================================
; x16lib :: video/screen.asm -- screen mode, text output, cursor
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; ---------------------------------------------------------------------
; THE KERNAL REQUIRES ADDRSEL = 0.
;
; Several KERNAL screen routines write VERA_ADDR_L/M/H *before* they set
; ADDRSEL, taking it on faith that port 0 is already selected. The screen
; scroller is the clearest case (x16-rom-r49 kernal/drivers/x16/screen.s):
;
;       lda pnt : sta VERA_ADDR_L   ; destination -- ADDRSEL assumed 0
;       ...
;       lda #1  : sta VERA_CTRL     ; only now switch to port 1
;       lda sal : sta VERA_ADDR_L   ; source
;
; Call that with ADDRSEL = 1 and the destination lands in port 1, where
; the source promptly overwrites it. The screen corrupts.
;
; screen_set_char is worse still: it writes all three ADDR registers and
; then `sta VERA_DATA0` without ever touching VERA_CTRL. With ADDRSEL = 1
; the address goes to port 1 while the character goes out of port 0, at
; whatever stale address port 0 happened to hold.
;
; So every routine here that enters a KERNAL routine which touches VERA
; forces ADDRSEL = 0 first. If you call CHROUT / CINT yourself after
; touching port 1 -- and +vera_addr 1 and vera_copy both leave it
; selected -- either go through screen_chrout, or emit +vera_addrsel 0
; beforehand.
;
; Note also that the KERNAL leaves DCSEL = 0, so do not expect a DCSEL
; selection to survive a call into it.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; screen_set_mode
;   in:  A = mode  ($00 80x60, $01 80x30, $02 40x60, $03 40x30,
;                   $04 40x15, $05 20x30, $06 20x15, $07 22x23,
;                   $08 64x50, $09 64x25, $0A 32x50, $0B 32x25,
;                   $80 320x240@256c + 40x30 text)
;   out: carry clear on success, set if the mode is unsupported
;
; KERNAL SCREEN_MODE takes carry clear to mean "set".
; ---------------------------------------------------------------------
screen_set_mode
    pha
    #vera_addrsel 0
    pla
    clc
    jmp SCREEN_MODE

; The query/border/cursor/charset/puts helpers below are behind
; X16_USE_SCREEN_EXTRA: a program that just sets a mode and prints does
; not need them, so the core (set_mode/reset/cls/chrout/color/locate)
; can stand alone. X16_USE_SCREEN pulls them, for compat.
.if xuse_screen_extra
; ---------------------------------------------------------------------
; screen_get_mode
;   out: A = current mode
; ---------------------------------------------------------------------
screen_get_mode
    #vera_addrsel 0
    sec
    jmp SCREEN_MODE

; ---------------------------------------------------------------------
; screen_get_size -- the live text grid, after any screen_set_mode
;   out: X = columns, Y = rows
; ---------------------------------------------------------------------
screen_get_size
    jmp SCREEN
.endif

; ---------------------------------------------------------------------
; screen_reset -- restore the default text mode (KERNAL CINT)
; ---------------------------------------------------------------------
screen_reset
    #vera_addrsel 0
    jmp CINT

; ---------------------------------------------------------------------
; screen_cls -- clear the text screen
; ---------------------------------------------------------------------
screen_cls
    #vera_addrsel 0
    lda #PETSCII_CLS
    jmp CHROUT

; ---------------------------------------------------------------------
; screen_chrout -- CHROUT with the ADDRSEL precondition established
;   in:  A = character
; ---------------------------------------------------------------------
screen_chrout
    pha
    #vera_addrsel 0
    pla
    jmp CHROUT

; ---------------------------------------------------------------------
; screen_color
;   in:  A = foreground (0-15), X = background (0-15)
;
; Sets the colour used by every subsequent CHROUT. Writes the KERNAL's
; editor colour byte directly -- there is no jump-table entry for this.
; Touches no VERA state.
; ---------------------------------------------------------------------
screen_color
    and #$0F
    sta X16_T0
    txa
    and #$0F
    asl
    asl
    asl
    asl                         ; background into the high nibble
    ora X16_T0
    sta KERNAL_COLOR
    rts

.if xuse_screen_extra
; ---------------------------------------------------------------------
; screen_border
;   in:  A = colour (0-15)
;
; DC_BORDER is only visible when DCSEL = 0, so select that bank first.
; Does not enter the KERNAL.
; ---------------------------------------------------------------------
screen_border
    pha
    #vera_dcsel 0
    pla
    sta VERA_DC_BORDER
    rts
.endif

; ---------------------------------------------------------------------
; screen_locate -- move the text cursor
;   in:  X = row, Y = column
; screen_get_cursor -- read it back
;   out: X = row, Y = column
;
; KERNAL PLOT takes carry clear to mean "set".
;
; No ADDRSEL guard here: PLOT only moves the cursor variables (it lands
; in screen_set_position, which just writes `pnt`) and never touches
; VERA. Adding one would cost a clobbered A for nothing.
; ---------------------------------------------------------------------
screen_locate
    clc
    jmp PLOT

; ---------------------------------------------------------------------
; screen_get_cursor -- where the cursor is
;   out: X/Y = row and column
;
; PLOT with the carry SET reads rather than writes, which is the whole
; difference between this and screen_locate above.
; ---------------------------------------------------------------------
.if xuse_screen_extra
screen_get_cursor
    sec
    jmp PLOT

; ---------------------------------------------------------------------
; screen_charset
;   in:  A = charset (1 = ISO, 2 = PET upper/graphics,
;                     3 = PET upper/lower, ... 12 = Katakana)
; ---------------------------------------------------------------------
screen_charset
    pha
    #vera_addrsel 0
    pla
    jmp SCREEN_SET_CHARSET

; ---------------------------------------------------------------------
; Direct text-map access.
;
; CHROUT costs several hundred cycles a character once the editor's
; scroll checks, colour handling and cursor bookkeeping are paid for.
; A program that repaints a whole text screen -- a spreadsheet, a file
; browser, any full-screen TUI -- cannot afford that, so these three
; write VERA's tile map itself: screen_addr points port 0 at a cell with
; auto-increment 1, and each following pair of bytes is one character
; and its colour. The address walks the row on its own, so a whole line
; costs one set-up and two stores per column.
;
; The KERNAL is not involved and neither is its cursor: these do not
; scroll, do not wrap, and do not move the CHROUT cursor. Do not print
; past the end of a row.
;
; Text is PETSCII on the way in -- the same bytes you would give CHROUT
; -- and is folded to screen codes here, so the caller never has to know
; the difference.
;
; The colour byte is foreground | background << 4, the same layout
; screen_color builds.
; ---------------------------------------------------------------------

; ---------------------------------------------------------------------
; screen_addr -- point VERA port 0 at a character cell
;   in:  X = row, Y = column
;
; Reads L1_MAPBASE and L1_CONFIG, so it follows whatever screen_set_mode
; left behind rather than assuming the 80x60 default. Leaves ADDRSEL = 0
; and the increment set to 1.
; ---------------------------------------------------------------------
screen_addr
    jsr screen_addr_calc
    #vera_addrsel 0
    jmp screen_addr_store

; ---------------------------------------------------------------------
; screen_addr1 -- the same, for VERA port 1
;   in:  X = row, Y = column
;
; Port 1 is what you point at the destination when moving text around
; with vera_copy; screen_scroll below is the usual reason to want it.
; ---------------------------------------------------------------------
screen_addr1
    jsr screen_addr_calc
    #vera_addrsel 1
screen_addr_store
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda X16_T2
    and #$01                    ; bit 16 of the address
    ora #$10                    ; increment 1
    sta VERA_ADDR_H
    rts

; address of (X = row, Y = column) into X16_T0/T1/T2, port untouched
screen_addr_calc
    sty X16_T5                  ; column
    stx X16_T6                  ; row

    lda VERA_L1_MAPBASE         ; map base = MAPBASE << 9
    asl                         ; carry = bit 16
    sta X16_T1                  ; mid
    lda #0
    rol
    sta X16_T2                  ; high
    stz X16_T0                  ; low

    lda VERA_L1_CONFIG          ; MAP_WIDTH: 0=32 1=64 2=128 3=256 tiles
    lsr
    lsr
    lsr
    lsr
    and #3
    clc
    adc #6                      ; bytes per row = 2 << (5 + width)
    tay

    lda X16_T6                  ; row << Y
    sta X16_T3
    stz X16_T4
_shift
    asl X16_T3
    rol X16_T4
    dey
    bne _shift

    clc                         ; base += row * stride
    lda X16_T0
    adc X16_T3
    sta X16_T0
    lda X16_T1
    adc X16_T4
    sta X16_T1
    bcc _nocarry1
    inc X16_T2
_nocarry1
    lda X16_T5                  ; base += column * 2
    asl
    tax
    lda #0
    rol
    tay
    txa
    clc
    adc X16_T0
    sta X16_T0
    tya
    adc X16_T1
    sta X16_T1
    bcc _nocarry2
    inc X16_T2
_nocarry2
    rts

; ---------------------------------------------------------------------
; screen_scode -- PETSCII to screen code
;   in:  A = PETSCII, out: A = screen code
;
; The standard CBM folding. Exposed because a caller building its own
; tile data occasionally wants it.
; ---------------------------------------------------------------------
screen_scode
    cmp #$20
    bcc _plus80                 ; $00-$1F
    cmp #$40
    bcc _same                   ; $20-$3F
    cmp #$60
    bcc _minus40                ; $40-$5F
    cmp #$80
    bcc _minus20                ; $60-$7F
    cmp #$A0
    bcc _plus40                 ; $80-$9F
    cmp #$C0
    bcc _minus40                ; $A0-$BF
_minus80                        ; $C0-$FF
    sec
    sbc #$80
_same
    rts
_plus80
    clc
    adc #$80
    rts
_minus40
    sec
    sbc #$40
    rts
_minus20
    sec
    sbc #$20
    rts
_plus40
    clc
    adc #$40
    rts

; ---------------------------------------------------------------------
; screen_blit -- write a run of characters, all one colour
;   in:  X16_P0/P1 = source, A = count (1-255), X = colour byte
;
; Port 0 must already point at the first cell (screen_addr); it is left
; pointing just past the last one, so runs can be chained.
; ---------------------------------------------------------------------
screen_blit
    sta X16_T7                  ; count
    stx X16_T3                  ; colour
    ldy #0
_loop
    lda (X16_P0),y
    jsr screen_scode
    sta VERA_DATA0
    lda X16_T3
    sta VERA_DATA0
    iny
    cpy X16_T7
    bne _loop
    rts

; ---------------------------------------------------------------------
; screen_blitfill -- write a run of one repeated character
;   in:  A = count (1-255), X = colour byte, Y = character (PETSCII)
;
; Same contract as screen_blit; the usual way to blank part of a line.
; ---------------------------------------------------------------------
screen_blitfill
    sta X16_T7                  ; count
    stx X16_T3                  ; colour
    tya
    jsr screen_scode
    sta X16_T4                  ; screen code, converted once
    ldy #0
_loop
    lda X16_T4
    sta VERA_DATA0
    lda X16_T3
    sta VERA_DATA0
    iny
    cpy X16_T7
    bne _loop
    rts

; ---------------------------------------------------------------------
; screen_scroll -- slide a rectangle of the text screen up or down
;   in:  X16_P0 = top row of the region
;        X16_P1 = left column
;        X16_P2 = height, in rows
;        X16_P3 = width, in columns
;        X16_P4 = distance to move, in rows
;        A      = 0 to move the picture up (toward row 0), 1 for down
;
; The point of this is not to save typing: a full-screen program that
; re-renders its whole grid to scroll one line pays for every cell it
; draws, and for a spreadsheet or a directory listing most of that cost
; is formatting the contents, not the drawing. Moving the picture inside
; VRAM and rendering only the row that appears costs one row instead of
; a screenful, whatever the contents happen to be.
;
; The rows uncovered at the trailing edge keep their old contents -- the
; caller draws what belongs there. Nothing happens when the distance is
; zero, or when it is large enough that nothing would survive, so the
; caller can simply repaint in that case.
;
; Vertical only. Scrolling sideways would move a row onto itself, and
; vera_copy walks forward, so the two would overlap.
; ---------------------------------------------------------------------
screen_scroll
    sta X16_P7                  ; direction
    lda X16_P4
    beq _done                   ; nothing to do
    cmp X16_P2
    bcs _done                   ; nothing would survive: let the caller repaint

    sec
    lda X16_P2
    sbc X16_P4
    sta X16_P5                  ; rows to copy
    stz X16_P6                  ; index
_loop
    lda X16_P7
    bne _down
    lda X16_P0                  ; up: dst = top + i, src = dst + distance
    clc
    adc X16_P6
    sta X16_T7
    clc
    adc X16_P4
    tax
    bra _move
_down
    lda X16_P0                  ; down: dst = bottom - i, src = dst - distance
    clc
    adc X16_P2
    sec
    sbc #1
    sec
    sbc X16_P6
    sta X16_T7
    sec
    sbc X16_P4
    tax
_move
    phx                         ; port 1 = destination
    ldx X16_T7
    ldy X16_P1
    jsr screen_addr1
    plx                         ; port 0 = source
    ldy X16_P1
    jsr screen_addr
    lda X16_P3                  ; width in cells -> bytes
    asl
    tax
    lda #0
    rol
    tay
    jsr vera_copy
    inc X16_P6
    lda X16_P6
    cmp X16_P5
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; screen_puts -- print a NUL-terminated string
;   in:  A = address low, X = address high
;   Strings longer than 255 bytes are truncated at 255.
; ---------------------------------------------------------------------
screen_puts
    sta X16_TPTR0
    stx X16_TPTR0+1
    #vera_addrsel 0
    ldy #0
_loop
    lda (X16_TPTR0),y
    beq _done
    jsr CHROUT
    iny
    bne _loop
_done
    rts
.endif

; (end zone)
.endif
.if xuse_palette
; --- inline video/palette.asm ---
;ACME
; =====================================================================
; x16lib :: video/palette.asm -- VERA palette
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; 256 entries of two bytes at $1FA00:
;       byte 0 = Green<<4 | Blue
;       byte 1 = Red             (high nibble unused)
;
; So a 12-bit $0RGB colour stores little-endian exactly as written:
; $0F00 is pure red, $00F0 pure green, $000F pure blue.
;
; Caution: $1F9C0-$1FFFF is write-only. Reading an entry returns the
; last value the host wrote there, not what the hardware holds -- fine
; for reading back your own writes, useless for discovering the state
; after a reset.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; pal_set
;   in:  X = palette index (0-255)
;        A = low byte  (Green<<4 | Blue)
;        Y = high byte (Red)
;
;   To set entry 1 to pure red ($0F00):
;       ldx #1 : lda #$00 : ldy #$0F : jsr pal_set
; ---------------------------------------------------------------------
pal_set
    sta X16_T0                  ; colour low
    sty X16_T1                  ; colour high

    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL               ; ADDRSEL = 0 (leaves DCSEL alone)

    txa
    asl                         ; entry index * 2; carry = address bit 8
    tax
    lda #>VRAM_PALETTE          ; $FA
    adc #0                      ; carry from the asl rolls it to $FB
    stx VERA_ADDR_L
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))   ; $1FA00 is in bank 1
    sta VERA_ADDR_H

    lda X16_T0
    sta VERA_DATA0
    lda X16_T1
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; pal_load -- bulk-load palette entries from RAM.
;   in:  X16_PTR0 = source address (2 bytes per entry, low byte first)
;        A = first palette index
;        X = entry count (1-128; 0 loads nothing)
; ---------------------------------------------------------------------
pal_load
    cpx #0                      ; count 0 loads nothing -- without this
    beq _done                   ; guard the loop would run 256 times and
    stx X16_T2                  ; shred the whole palette

    tax                         ; X = first index
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    txa
    asl
    tax
    lda #>VRAM_PALETTE
    adc #0
    stx VERA_ADDR_L
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))
    sta VERA_ADDR_H

    ldy #0
_loop
    lda (X16_PTR0),y
    sta VERA_DATA0              ; low byte
    iny
    lda (X16_PTR0),y
    sta VERA_DATA0              ; high byte
    iny
    dec X16_T2
    bne _loop
_done
    rts

; (end zone)
.endif
.if xuse_tile
; --- inline video/tile.asm ---
;ACME
; =====================================================================
; x16lib :: video/tile.asm -- tilemap cells and layer configuration
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The tile_* routines address layer 1, which in the default text modes
; is the text screen. They read L1_CONFIG and L1_MAPBASE at run time
; rather than assuming a screen mode, so they keep working after
; screen_set_mode.
;
; The KERNAL's default text setup is L1_CONFIG = $60 (map 128x64, 1bpp)
; with MAPBASE = $D8, i.e. the map at $1B000. A cell is two bytes:
; screen code, then colour attribute (fg | bg<<4).
;
; tile_setptr leaves ADDRSEL = 0, so it is safe to call the KERNAL
; afterwards -- see the note in video/screen.asm.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; layer_index -- turn a layer number into the register offset.
;   in:  X = layer (0 or 1)
;   out: X = 0 or 7   (L1_CONFIG is 7 bytes past L0_CONFIG)
;   Preserves A.
; ---------------------------------------------------------------------
layer_index
    cpx #0
    beq _zero
    ldx #(VERA_L1_CONFIG - VERA_L0_CONFIG)
    rts
_zero
    ldx #0
    rts

; ---------------------------------------------------------------------
; layer_on / layer_off
;   in:  A = layer (0 or 1)
; ---------------------------------------------------------------------
layer_on
    tax
    #vera_dcsel 0
    lda #VERA_VIDEO_LAYER0_EN
    cpx #0
    beq _go
    lda #VERA_VIDEO_LAYER1_EN
_go
    tsb VERA_DC_VIDEO
    rts

layer_off
    tax
    #vera_dcsel 0
    lda #VERA_VIDEO_LAYER0_EN
    cpx #0
    beq _go
    lda #VERA_VIDEO_LAYER1_EN
_go
    trb VERA_DC_VIDEO
    rts

; ---------------------------------------------------------------------
; layer_set_config  -- in: X = layer, A = config byte
;   map height (7:6) | map width (5:4) | T256C (3) | bitmap (2) | bpp (1:0)
; layer_set_mapbase -- in: X = layer, A = VRAM address >> 9  (512-aligned)
; layer_set_tilebase-- in: X = layer, A = base>>11<<2 | tile size bits
; ---------------------------------------------------------------------
layer_set_config
    pha
    jsr layer_index
    pla
    sta VERA_L0_CONFIG,x
    rts

layer_set_mapbase
    pha
    jsr layer_index
    pla
    sta VERA_L0_MAPBASE,x
    rts

layer_set_tilebase
    pha
    jsr layer_index
    pla
    sta VERA_L0_TILEBASE,x
    rts

; ---------------------------------------------------------------------
; layer_scroll_x / layer_scroll_y -- 12-bit hardware scroll
;   in:  X = layer, X16_P0/P1 = value (0-4095)
; ---------------------------------------------------------------------
layer_scroll_x
    jsr layer_index
    lda X16_P0
    sta VERA_L0_HSCROLL_L,x
    lda X16_P1
    and #$0F
    sta VERA_L0_HSCROLL_H,x
    rts

layer_scroll_y
    jsr layer_index
    lda X16_P0
    sta VERA_L0_VSCROLL_L,x
    lda X16_P1
    and #$0F
    sta VERA_L0_VSCROLL_H,x
    rts

; ---------------------------------------------------------------------
; tile_setptr -- point data port 0 at a layer-1 tilemap cell.
;   in:  X = column, Y = row
;
; address = (L1_MAPBASE << 9) + (row * mapwidth + col) * 2
;
; mapwidth is 32 << ((L1_CONFIG >> 4) & 3), always a power of two, so
; (row * mapwidth) * 2 is just row shifted left by 6 + that field. The
; product needs 17 bits, hence the three-byte shift.
; ---------------------------------------------------------------------
tile_setptr
    stx X16_T4                  ; column
    sty X16_T5                  ; row

    lda VERA_L1_CONFIG
    lsr
    lsr
    lsr
    lsr
    and #$03                    ; map width code 0..3
    clc
    adc #6
    tax                         ; shift count 6..9

    stz X16_T1
    stz X16_T2
    lda X16_T5
    sta X16_T0
_shift
    asl X16_T0
    rol X16_T1
    rol X16_T2
    dex
    bne _shift

    ; + column * 2  (up to 9 bits)
    lda X16_T4
    asl
    sta X16_T6
    lda #0
    rol
    sta X16_T7

    clc
    lda X16_T0
    adc X16_T6
    sta X16_T0
    lda X16_T1
    adc X16_T7
    sta X16_T1
    lda X16_T2
    adc #0
    sta X16_T2

    ; + mapbase, which is (register << 9): low byte is always zero.
    lda VERA_L1_MAPBASE
    asl                         ; carry = VRAM address bit 16
    sta X16_T6
    lda #0
    rol
    sta X16_T7

    clc
    lda X16_T1
    adc X16_T6
    sta X16_T1
    lda X16_T2
    adc X16_T7
    sta X16_T2

    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL               ; ADDRSEL = 0, DCSEL untouched
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda X16_T2
    and #VERA_ADDR_H_BANK
    ora #(VERA_INC_1 << 4)
    sta VERA_ADDR_H
    rts

; ---------------------------------------------------------------------
; tile_put -- write one cell
;   in:  X = column, Y = row, X16_P0 = screen code, X16_P1 = attribute
; ---------------------------------------------------------------------
tile_put
    jsr tile_setptr
    lda X16_P0
    sta VERA_DATA0
    lda X16_P1
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; tile_get -- read one cell
;   in:  X = column, Y = row
;   out: A = screen code, X = attribute
; ---------------------------------------------------------------------
tile_get
    jsr tile_setptr
    lda VERA_DATA0
    tay
    lda VERA_DATA0
    tax
    tya
    rts

; (end zone)
.endif
.if xuse_sprite
; --- inline sprite/sprite.asm ---
;ACME
; =====================================================================
; x16lib :: sprite/sprite.asm -- VERA hardware sprites
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; 128 sprites, an 8-byte attribute record each, at $1FC00:
;   0  image address bits 12:5
;   1  mode(7) | image address bits 16:13
;   2  X bits 7:0
;   3  X bits 9:8
;   4  Y bits 7:0
;   5  Y bits 9:8
;   6  collision mask(7:4) | Z-depth(3:2) | vflip(1) | hflip(0)
;   7  height(7:6) | width(5:4) | palette offset(3:0)
;
; That region is write-only: reads return the last value the host wrote.
; Read-modify-write therefore only works on records this program has
; already initialised. sprite_init_all does that.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; sprite_setptr -- point data port 0 at one byte of a sprite record.
;   in:  X = sprite number (0-127), A = byte offset within the record
;   Leaves the port on auto-increment, so consecutive fields stream.
; ---------------------------------------------------------------------
sprite_setptr
    sta X16_T2                  ; byte offset
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL               ; ADDRSEL = 0, DCSEL untouched

    stz X16_T1
    txa
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1                  ; T1:A = sprite * 8

    clc
    adc X16_T2
    sta VERA_ADDR_L
    lda X16_T1
    adc #>VRAM_SPRITE_ATTR      ; $FC, plus any carry from the offset
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))
    sta VERA_ADDR_H
    rts

; ---------------------------------------------------------------------
; sprites_on / sprites_off -- the sprite renderer as a whole
; ---------------------------------------------------------------------
sprites_on
    #vera_dcsel 0
    lda #VERA_VIDEO_SPRITES_EN
    tsb VERA_DC_VIDEO
    rts

sprites_off
    #vera_dcsel 0
    lda #VERA_VIDEO_SPRITES_EN
    trb VERA_DC_VIDEO
    rts

; ---------------------------------------------------------------------
; sprite_pos -- set a sprite's 10-bit position
;   in:  X = sprite
;        X16_P0/P1 = x, X16_P2/P3 = y
; ---------------------------------------------------------------------
sprite_pos
    lda #SPRITE_ATTR_X_L
    jsr sprite_setptr
    lda X16_P0
    sta VERA_DATA0
    lda X16_P1
    and #$03
    sta VERA_DATA0
    lda X16_P2
    sta VERA_DATA0
    lda X16_P3
    and #$03
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; sprite_get_pos -- read it back
;   in:  X = sprite
;   out: X16_P0/P1 = x, X16_P2/P3 = y
; ---------------------------------------------------------------------
sprite_get_pos
    lda #SPRITE_ATTR_X_L
    jsr sprite_setptr
    lda VERA_DATA0
    sta X16_P0
    lda VERA_DATA0
    and #$03
    sta X16_P1
    lda VERA_DATA0
    sta X16_P2
    lda VERA_DATA0
    and #$03
    sta X16_P3
    rts

; ---------------------------------------------------------------------
; sprite_image -- point a sprite at its pixel data in VRAM
;   in:  X = sprite
;        X16_P0 = addr low, X16_P1 = addr mid, X16_P2 = addr bit 16
;        A = SPRITE_MODE_4BPP or SPRITE_MODE_8BPP
;
; The record stores address bits 16:5, so the data must be 32-byte
; aligned; the low five bits are simply dropped.
; ---------------------------------------------------------------------
sprite_image
    sta X16_T3                  ; mode flag
    lda #SPRITE_ATTR_ADDR_L
    jsr sprite_setptr

    lda X16_P0
    lsr
    lsr
    lsr
    lsr
    lsr                         ; addr bits 7:5 -> 2:0
    sta X16_T4
    lda X16_P1
    asl
    asl
    asl                         ; addr bits 12:8 -> 7:3
    ora X16_T4
    sta VERA_DATA0              ; byte 0 = addr 12:5

    lda X16_P1
    lsr
    lsr
    lsr
    lsr
    lsr                         ; addr bits 15:13 -> 2:0
    sta X16_T4
    lda X16_P2
    and #$01
    asl
    asl
    asl                         ; addr bit 16 -> bit 3
    ora X16_T4
    ora X16_T3                  ; mode in bit 7
    sta VERA_DATA0              ; byte 1
    rts

; ---------------------------------------------------------------------
; sprite_flags -- byte 6: collision mask, Z-depth, flips
;   in:  X = sprite, A = collision<<4 | Z | vflip | hflip
;   e.g. lda #(SPRITE_Z_FRONT | SPRITE_HFLIP)
; ---------------------------------------------------------------------
sprite_flags
    sta X16_T3
    lda #SPRITE_ATTR_FLAGS
    jsr sprite_setptr
    lda X16_T3
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; sprite_z -- change only the Z-depth, preserving the other bits
;   in:  X = sprite, A = SPRITE_Z_DISABLED/BEHIND/MIDDLE/FRONT
;
; Read-modify-write. Only valid once the record has been written at
; least once (see the note at the top of this file).
; ---------------------------------------------------------------------
sprite_z
    sta X16_T3
    lda #SPRITE_ATTR_FLAGS
    jsr sprite_setptr
    lda VERA_DATA0              ; read advances the port past byte 6
    and #%11110011
    ora X16_T3
    sta X16_T4
    lda #SPRITE_ATTR_FLAGS
    jsr sprite_setptr           ; point at byte 6 again to write it
    lda X16_T4
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; sprite_size -- byte 7: size codes and palette offset
;   in:  X = sprite
;        A = width code (SPRITE_SIZE_8/16/32/64)
;        Y = height code
;        X16_P0 = palette offset (0-15)
; ---------------------------------------------------------------------
sprite_size
    and #$03
    asl
    asl
    asl
    asl                         ; width into bits 5:4
    sta X16_T3
    tya
    and #$03
    asl
    asl
    asl
    asl
    asl
    asl                         ; height into bits 7:6
    ora X16_T3
    sta X16_T3
    lda X16_P0
    and #$0F                    ; an offset >15 must not corrupt the size bits
    ora X16_T3
    sta X16_T3

    lda #SPRITE_ATTR_SIZE_PAL
    jsr sprite_setptr
    lda X16_T3
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; sprite_init_all -- zero all 128 attribute records.
;
; Disables every sprite and, more importantly, gives the write-only
; attribute RAM a known host-side shadow so sprite_z's read-modify-write
; is meaningful.
; ---------------------------------------------------------------------
sprite_init_all
    #vera_addr 0, VRAM_SPRITE_ATTR, VERA_INC_1
    lda #0
    ldx #<(128 * 8)
    ldy #>(128 * 8)
    jmp vera_fill

; (end zone)
.endif
.if xuse_bitmap8l
; --- inline gfx/bitmap8l.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/bitmap8l.asm -- 320x240x256 bitmap drawing
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; Requires X16_USE_VERA (uses vera_fill).
;
; The framebuffer is 8bpp at VRAM $00000, one byte per pixel, rows of
; 320. A pixel is at y*320 + x.
;
; gfx8l_pset clips. The line/rect primitives do NOT: they assume
; their arguments are on screen. Clipping every span would cost more
; than it saves for a caller that already knows its geometry.
;
; Nothing here changes the screen mode. Call gfx8l_init once to switch the
; display to bitmap mode; the drawing routines only touch VRAM, so they
; also work on an off-screen buffer.
; =====================================================================

; (zone: file scope in 64tass)

GFX8L_WIDTH  = 320
GFX8L_HEIGHT = 240

; ---------------------------------------------------------------------
; gfx8l_init  -- 320x240@256c bitmap on layer 0, 40x30 text on layer 1
; gfx8l_clear -- in: A = colour
; X16_BITMAP8L_NO_INIT leaves gfx8l_init out: a caller that programs the
; display mode on bare VERA registers itself does not want the KERNAL
; screen editor (screen_set_mode) pulled in behind it.
; ---------------------------------------------------------------------
.if !X16_BITMAP8L_NO_INIT != 0
gfx8l_init
    lda #$80
    jmp screen_set_mode
.endif

; 320*240 = 76800 bytes does not fit vera_fill's 16-bit count (passing
; it naively truncates to $2C00 and clears only the top 35 rows), so
; clear in two halves; port 0 keeps auto-incrementing between calls.
gfx8l_clear
    pha
    #vera_addr 0, VRAM_BITMAP, VERA_INC_1
    pla
    pha
    ldx #<(GFX8L_WIDTH * GFX8L_HEIGHT / 2)
    ldy #>(GFX8L_WIDTH * GFX8L_HEIGHT / 2)
    jsr vera_fill
    pla
    ldx #<(GFX8L_WIDTH * GFX8L_HEIGHT / 2)
    ldy #>(GFX8L_WIDTH * GFX8L_HEIGHT / 2)
    jmp vera_fill

; ---------------------------------------------------------------------
; gfx8l_setptr -- point data port 0 at pixel (x,y)
;   in:  A = increment index (VERA_INC_*)
;        X16_P0/P1 = x, X16_P2 = y
;
; y*320 = (y<<8) + (y<<6), so no multiply is needed. Result is 17-bit.
; Stepping by VERA_INC_320 then walks straight down a column.
; ---------------------------------------------------------------------
gfx8l_setptr
    asl
    asl
    asl
    asl
    sta X16_T5                  ; increment field, pre-shifted

    lda X16_P2                  ; y << 6
    stz X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    sta X16_T4                  ; T4/T3 = y*64

    clc                         ; + y<<8, whose low byte is zero
    lda X16_T4
    sta X16_T0
    lda X16_P2
    adc X16_T3
    sta X16_T1
    lda #0
    adc #0
    sta X16_T2                  ; T2:T1:T0 = y*320

    clc                         ; + x
    lda X16_T0
    adc X16_P0
    sta X16_T0
    lda X16_T1
    adc X16_P1
    sta X16_T1
    lda X16_T2
    adc #0
    sta X16_T2

    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda X16_T2
    and #VERA_ADDR_H_BANK
    ora X16_T5
    sta VERA_ADDR_H
    rts

; ---------------------------------------------------------------------
; gfx8l_pset -- set one pixel, clipped
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour
; ---------------------------------------------------------------------
gfx8l_pset
    lda X16_P2
    cmp #GFX8L_HEIGHT
    bcs _off                    ; y >= 240

    lda X16_P1                  ; x high byte
    beq _on                     ; x < 256, always on screen
    cmp #1
    bne _off                    ; x >= 512
    lda X16_P0
    cmp #<GFX8L_WIDTH             ; 320 = $140, so x low must be < $40
    bcs _off
_on
    lda #VERA_INC_0
    jsr gfx8l_setptr
    lda X16_P3
    sta VERA_DATA0
_off
    rts

; ---------------------------------------------------------------------
; gfx8l_hline -- in: X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;                  X16_P4/P5 = length
; ---------------------------------------------------------------------
gfx8l_hline
    lda #VERA_INC_1
    jsr gfx8l_setptr
    lda X16_P3
    ldx X16_P4
    ldy X16_P5
    jmp vera_fill

; ---------------------------------------------------------------------
; gfx8l_vline -- in: X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;                  X16_P4 = length (1-255)
;
; VERA_INC_320 is one of the hardware's odd increments, so a vertical
; line is the same tight loop as a horizontal one.
; ---------------------------------------------------------------------
gfx8l_vline
    lda #VERA_INC_320
    jsr gfx8l_setptr
    lda X16_P3
    ldx X16_P4
    ldy #0
    jmp vera_fill

; ---------------------------------------------------------------------
; gfx8l_rect -- filled rectangle
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;        X16_P4/P5 = width, X16_P6 = height
; ---------------------------------------------------------------------
gfx8l_rect
_row
    lda X16_P6
    beq _done
    jsr gfx8l_hline               ; leaves P0..P5 alone
    inc X16_P2
    dec X16_P6
    bra _row
_done
    rts

; ---------------------------------------------------------------------
; gfx8l_frame -- rectangle outline
;   same arguments as gfx8l_rect
; ---------------------------------------------------------------------
gfx8l_frame
    ; Take a private copy of everything: gfx8l_vline reuses P4 as its
    ; length, which is where the caller's width lives. The gb block is
    ; laid out in P0..P6 order, so one loop does it.
    ldx #6
_take
    lda X16_P0,x
    sta gb8l_x,x
    dex
    bpl _take

    jsr bitmap8l_restore_span           ; top edge
    jsr gfx8l_hline

    jsr bitmap8l_restore_span           ; bottom edge, y + h - 1
    clc
    lda gb8l_y
    adc gb8l_h
    sec
    sbc #1
    sta X16_P2
    jsr gfx8l_hline

    jsr bitmap8l_restore_col            ; left edge
    jsr gfx8l_vline

    jsr bitmap8l_restore_col            ; right edge, x + w - 1
    clc
    lda gb8l_x
    adc gb8l_w
    sta X16_P0
    lda gb8l_x+1
    adc gb8l_w+1
    sta X16_P1
    lda X16_P0
    bne _no_borrow
    dec X16_P1
_no_borrow
    dec X16_P0
    jsr gfx8l_vline

    rts

; x, y, colour, width -- arguments for gfx8l_hline (gb bytes 0-5)
bitmap8l_restore_span
    ldx #5
bitmap8l_rsp_l
    lda gb8l_x,x
    sta X16_P0,x
    dex
    bpl bitmap8l_rsp_l
    rts

; x, y, colour, height -- arguments for gfx8l_vline
bitmap8l_restore_col
    ldx #3
bitmap8l_rcl_l
    lda gb8l_x,x
    sta X16_P0,x
    dex
    bpl bitmap8l_rcl_l
    lda gb8l_h
    sta X16_P4
    rts

; ---------------------------------------------------------------------
; gfx8l_read -- read one pixel
;   in:  X16_P0/P1 = x, X16_P2 = y
;   out: A = the colour
; ---------------------------------------------------------------------
gfx8l_read
	lda #0                      ; VERA_INC_0: a lone read
	jsr gfx8l_setptr
	lda VERA_DATA0
	rts

; ---------------------------------------------------------------------
; the 2bpp module's stencil-and-blit family, at 8bpp. One byte is one
; pixel here, which makes every one of these simpler than its 2bpp
; sibling: no sub-byte phases, and a masked blit is a colour key.
;
; The rows walk the P block itself (x stays in P0/P1, y steps in P2)
; and aim port 0 through gfx8l_setptr -- the same y*320+x math is not
; repeated here. gfx8l_setptr leaves the address in T0..T2 and the
; shifted increment in T5, which is all bitmap8l_ld1 needs to aim the read
; port for the RMW ops.
; ---------------------------------------------------------------------
bitmap8l_ld1
	lda #VERA_CTRL_ADDRSEL
	tsb VERA_CTRL
	lda X16_T0
	sta VERA_ADDR_L
	lda X16_T1
	sta VERA_ADDR_M
	lda X16_T2
	and #VERA_ADDR_H_BANK
	ora X16_T5
	sta VERA_ADDR_H
	rts

; ---------------------------------------------------------------------
; gfx8l_pattern_set -- cache an 8x8 1bpp pattern for gfx8l_pattern_rect
;   in:  A = pattern low, X = pattern high (8 row bytes, top first;
;            bit 7 is the leftmost pixel)
;        X16_P4 = background colour, X16_P5 = foreground colour
;
; The full-colour pair is the one deliberate departure from the 2bpp
; signature, whose Y packs two 2-bit colours; 8bpp colours need bytes.
; ---------------------------------------------------------------------
gfx8l_pattern_set
	sta X16_T0
	stx X16_T0+1
	ldy #7
bitmap8l_gp8l_cp
	lda (X16_T0),y
	sta gp8l_pat,y
	dey
	bpl bitmap8l_gp8l_cp
	lda X16_P4
	sta gp8l_bg
	lda X16_P5
	sta gp8l_fg
	rts

; ---------------------------------------------------------------------
; gfx8l_pattern_rect -- fill a rectangle with the cached pattern
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P4/P5 = width, X16_P6 = height
;   (P2 and P6 are consumed)
;
; Tiles from the screen origin, like the 2bpp module: the pattern cell
; under a pixel depends only on the pixel, not the rectangle.
; ---------------------------------------------------------------------
gfx8l_pattern_rect
	lda X16_P4                  ; zero width or height: draw nothing
	ora X16_P5
	beq bitmap8l_gp8l_done
	lda X16_P6
	beq bitmap8l_gp8l_done
	lda X16_P0                  ; the column phase: x & 7, fixed for
	and #7                      ; every row
	sta gp8l_rot
bitmap8l_gp8l_row
	lda #VERA_INC_1
	jsr gfx8l_setptr
	lda X16_P2                  ; the pattern row: y & 7
	and #7
	tay
	lda gp8l_pat,y
	ldy gp8l_rot                 ; pre-rotate to the column phase
	beq bitmap8l_gp8l_go
bitmap8l_gp8l_pre
	asl
	adc #0                      ; circular left: bit 7 wraps to bit 0
	dey
	bne bitmap8l_gp8l_pre
bitmap8l_gp8l_go
	sta gp8l_cur
	lda X16_P4                  ; the width countdown, 16-bit
	sta gb8l_t
	lda X16_P5
	sta gb8l_t+1
bitmap8l_gp8l_px
	lda gp8l_cur                 ; bit 7 = this pixel
	bmi bitmap8l_gp8l_fg
	lda gp8l_bg
	bra bitmap8l_gp8l_out
bitmap8l_gp8l_fg
	lda gp8l_fg
bitmap8l_gp8l_out
	sta VERA_DATA0
	lda gp8l_cur                 ; rotate to the next column
	asl
	adc #0
	sta gp8l_cur
	lda gb8l_t                   ; width--
	bne +
	dec gb8l_t+1
+	dec gb8l_t
	lda gb8l_t
	ora gb8l_t+1
	bne bitmap8l_gp8l_px
	inc X16_P2                  ; the next row
	dec X16_P6
	bne bitmap8l_gp8l_row
bitmap8l_gp8l_done
	rts

; ---------------------------------------------------------------------
; gfx8l_blit -- rows of pixel bytes from RAM to the framebuffer
;   in:  A = raster op: 0 copy, 1 OR, 2 AND, 3 XOR
;        X16_P0/P1 = x, X16_P2 = y, X16_P4 = width in PIXELS (1-255),
;        X16_P5 = height in rows, X16_P6/P7 = source (row-major)
;
; The source pointer is X16_PTR3 -- P6/P7 double as real zero page, the
; 2bpp module's own trick. No clipping. P2 and P5 are consumed.
;
; The three RMW ops share one loop: the opcode of the instruction at
; bitmap8l_gb8l_opcode is patched from bitmap8l_gb8l_optab (ora/and/eor abs), the gfx8l_text trick
; one byte earlier.
; ---------------------------------------------------------------------
gfx8l_blit
	and #3
	sta gb8l_op
	beq bitmap8l_gb8l_row                  ; copy: no opcode to patch
	tax
	lda bitmap8l_gb8l_optab-1,x
	sta bitmap8l_gb8l_opcode
bitmap8l_gb8l_row
	lda #VERA_INC_1
	jsr gfx8l_setptr
	lda gb8l_op
	beq bitmap8l_gb8l_copy
	jsr bitmap8l_ld1                    ; the RMW ops read through port 1
	ldy #0
bitmap8l_gb8l_oploop
	lda (X16_PTR3),y
bitmap8l_gb8l_opcode
	ora VERA_DATA1              ; opcode patched: op 1/2/3 = ora/and/eor
	sta VERA_DATA0
	iny
	cpy X16_P4
	bne bitmap8l_gb8l_oploop
	bra bitmap8l_gb8l_next
bitmap8l_gb8l_copy
	ldy #0
bitmap8l_gb8l_copyloop
	lda (X16_PTR3),y
	sta VERA_DATA0
	iny
	cpy X16_P4
	bne bitmap8l_gb8l_copyloop
bitmap8l_gb8l_next
	clc                         ; the next source row
	lda X16_PTR3
	adc X16_P4
	sta X16_PTR3
	bcc +
	inc X16_PTR3+1
+	inc X16_P2
	dec X16_P5
	bne bitmap8l_gb8l_row
	rts

bitmap8l_gb8l_optab
    .byte $0D, $2D, $4D     ; ora / and / eor absolute

; ---------------------------------------------------------------------
; gfx8l_blitm -- a masked blit: byte $00 is transparent
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P4 = width in PIXELS (1-255),
;        X16_P5 = height, X16_P6/P7 = source (row-major)
;
; At 8bpp the mask IS the data: colour 0 means "leave the screen
; alone" (a read still advances the port, which is the whole trick).
; The 2bpp module needs interleaved mask bytes; one byte per pixel
; does not. P2 and P5 are consumed.
; ---------------------------------------------------------------------
gfx8l_blitm
bitmap8l_gm8l_row
	lda #VERA_INC_1
	jsr gfx8l_setptr
	ldy #0
bitmap8l_gm8l_px
	lda (X16_PTR3),y
	beq bitmap8l_gm8l_skip
	sta VERA_DATA0
	bra bitmap8l_gm8l_next
bitmap8l_gm8l_skip
	lda VERA_DATA0              ; advance without writing
bitmap8l_gm8l_next
	iny
	cpy X16_P4
	bne bitmap8l_gm8l_px
	clc
	lda X16_PTR3
	adc X16_P4
	sta X16_PTR3
	bcc +
	inc X16_PTR3+1
+	inc X16_P2
	dec X16_P5
	bne bitmap8l_gm8l_row
	rts

gp8l_pat .fill 8, 0
gp8l_bg  .byte 0
gp8l_fg  .byte 0
gp8l_rot .byte 0
gp8l_cur .byte 0
gb8l_op  .byte 0
gb8l_t   .word 0

; ---------------------------------------------------------------------
; gfx8l_line -- Bresenham, any direction
;   in:  X16_P0/P1 = x0, X16_P2 = y0
;        X16_P3/P4 = x1, X16_P5 = y1
;        X16_P6    = colour
;
; Works entirely from its own variables, because gfx8l_pset wants the
; colour in X16_P3 -- which is where x1 lives on entry.
; ---------------------------------------------------------------------
gfx8l_line
    ldx #6                      ; P0..P6 -> gl8l_x0..gl8l_color, which are
_take                           ; laid out in the same order
    lda X16_P0,x
    sta gl8l_x0,x
    dex
    bpl _take

    ; dx = |x1 - x0|, sx = sign
    sec
    lda gl8l_x1
    sbc gl8l_x0
    sta gl8l_dx
    lda gl8l_x1+1
    sbc gl8l_x0+1
    sta gl8l_dx+1
    bpl _dx_pos
    sec
    lda #0
    sbc gl8l_dx
    sta gl8l_dx
    lda #0
    sbc gl8l_dx+1
    sta gl8l_dx+1
    lda #$FF
    sta gl8l_sx
    sta gl8l_sx+1                 ; -1, sign extended
    bra _dx_done
_dx_pos
    lda #$01
    sta gl8l_sx
    stz gl8l_sx+1
_dx_done

    ; dy = -|y1 - y0|, sy = sign
    sec
    lda gl8l_y1
    sbc gl8l_y0
    bpl _dy_pos
    eor #$FF
    clc
    adc #1                      ; absolute value
    sta gl8l_tmp
    lda #$FF
    sta gl8l_sy
    bra _dy_done
_dy_pos
    sta gl8l_tmp
    lda #$01
    sta gl8l_sy
_dy_done
    sec
    lda #0
    sbc gl8l_tmp
    sta gl8l_dy
    lda #0
    sbc #0
    sta gl8l_dy+1                 ; gl8l_dy = -|dy|, 16-bit signed

    clc                         ; err = dx + dy
    lda gl8l_dx
    adc gl8l_dy
    sta gl8l_err
    lda gl8l_dx+1
    adc gl8l_dy+1
    sta gl8l_err+1

_loop
    jsr bitmap8l_plot

    lda gl8l_x0                   ; reached the end point?
    cmp gl8l_x1
    bne _step
    lda gl8l_x0+1
    cmp gl8l_x1+1
    bne _step
    lda gl8l_y0
    cmp gl8l_y1
    bne _step
    rts

_step
    lda gl8l_err                  ; e2 = err * 2
    asl
    sta gl8l_e2
    lda gl8l_err+1
    rol
    sta gl8l_e2+1

    ; if e2 >= dy  ->  err += dy, x0 += sx
    sec
    lda gl8l_e2
    sbc gl8l_dy
    lda gl8l_e2+1
    sbc gl8l_dy+1
    bvc _nv1
    eor #$80                    ; signed compare: fold overflow into sign
_nv1
    bmi _skip_x
    clc
    lda gl8l_err
    adc gl8l_dy
    sta gl8l_err
    lda gl8l_err+1
    adc gl8l_dy+1
    sta gl8l_err+1
    clc
    lda gl8l_x0
    adc gl8l_sx
    sta gl8l_x0
    lda gl8l_x0+1
    adc gl8l_sx+1
    sta gl8l_x0+1
_skip_x

    ; if e2 <= dx  ->  err += dx, y0 += sy
    sec
    lda gl8l_dx
    sbc gl8l_e2
    lda gl8l_dx+1
    sbc gl8l_e2+1
    bvc _nv2
    eor #$80
_nv2
    bmi _skip_y
    clc
    lda gl8l_err
    adc gl8l_dx
    sta gl8l_err
    lda gl8l_err+1
    adc gl8l_dx+1
    sta gl8l_err+1
    clc
    lda gl8l_y0
    adc gl8l_sy
    sta gl8l_y0
_skip_y
    jmp _loop

; plot (gl8l_x0, gl8l_y0) in gl8l_color
bitmap8l_plot
    lda gl8l_x0
    sta X16_P0
    lda gl8l_x0+1
    sta X16_P1
    lda gl8l_y0
    sta X16_P2
    lda gl8l_color
    sta X16_P3
    jmp gfx8l_pset

; --- X16_BITMAP8L_MIN: core-only build ---------------------------------
; The gfx8l_char / gfx8l_text glyph drawing below is optional. Define
; X16_BITMAP8L_MIN to leave it out: init/clear/read/pset/lines/rect/
; frame/pattern/blit only. CXRF's 8bpp overlay image uses it to fit
; its fixed region; a full build is unchanged.
;
; Circle, disc and flood are NOT here -- they live in gfx/shapes.asm,
; which draws through any engine's pset/hline/read and so serves this
; module and gfx2 alike (source it and bind SHP_* to gfx8l_* to draw them
; at 8bpp). One copy, not one per engine.
.if !X16_BITMAP8L_MIN != 0

; ---------------------------------------------------------------------
; gfx8l_char -- draw one glyph from the VRAM charset into the bitmap
;   in:  A = screen code (0-255)
;        X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour
;
; Reads the 8-byte 1bpp glyph from the charset the KERNAL keeps at
; VRAM $1F000; set bits become colour pixels through gfx8l_pset (so text
; clips), clear bits stay transparent. Preserves X16_P0..P3.
;
; gfx8l_text -- a NUL-terminated string, 8 pixels per character
;   in:  A = string low, X = string high; X16_P0..P3 as above.
;   ASCII letters are converted to screen codes ('A'-'Z' work as
;   expected); X16_P0/P1 are left one past the final character.
; ---------------------------------------------------------------------
gfx8l_char
    ; glyph address = VRAM_CHARSET + code * 8  (17-bit)
    sta gt8l_code
    stz gt8l_hi
    asl
    rol gt8l_hi
    asl
    rol gt8l_hi
    asl
    rol gt8l_hi                   ; gt8l_hi:A = code * 8
    pha
    #vera_addrsel 1
    pla
    sta VERA_ADDR_L
    lda gt8l_hi
    clc
    adc #<(VRAM_CHARSET >> 8)
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))   ; $1F000 is in bank 1
    sta VERA_ADDR_H
    ldx #0
_fetch
    lda VERA_DATA1
    sta gt8l_glyph,x
    inx
    cpx #8
    bne _fetch
    #vera_addrsel 0

    lda X16_P0                  ; park the caller's position
    sta gt8l_bx
    lda X16_P1
    sta gt8l_bx+1
    lda X16_P2
    sta gt8l_by

    stz gt8l_row
_rows
    ldx gt8l_row
    lda gt8l_glyph,x
    sta gt8l_bits
    beq _next_row               ; a blank row: nothing to plot
    stz gt8l_col
_cols
    asl gt8l_bits                 ; leftmost pixel first
    bcc _next_col
    clc
    lda gt8l_bx
    adc gt8l_col
    sta X16_P0
    lda gt8l_bx+1
    adc #0
    sta X16_P1
    clc
    lda gt8l_by
    adc gt8l_row
    bcs _next_col               ; wrapped past 255: off screen
    sta X16_P2
    jsr gfx8l_pset
_next_col
    inc gt8l_col
    lda gt8l_col
    cmp #8
    bne _cols
_next_row
    inc gt8l_row
    lda gt8l_row
    cmp #8
    bne _rows

    lda gt8l_bx                   ; restore the caller's block
    sta X16_P0
    lda gt8l_bx+1
    sta X16_P1
    lda gt8l_by
    sta X16_P2
    rts

gfx8l_text
    sta bitmap8l_gt8l_lda+1               ; the string pointer lives in the lda's
    stx bitmap8l_gt8l_lda+2               ; own operand (no zero page needed)
gtx8l_tloop
bitmap8l_gt8l_lda
    lda $FFFF                   ; operand patched above and stepped below
    beq gtx8l_tdone
    ; ASCII -> screen code: bit 6 set means letters/at-sign block
    bit #%01000000
    beq gtx8l_code_ok
    and #$1F
gtx8l_code_ok
    jsr gfx8l_char
    clc                         ; advance the pen 8 pixels
    lda X16_P0
    adc #8
    sta X16_P0
    lda X16_P1
    adc #0
    sta X16_P1
    inc bitmap8l_gt8l_lda+1
    bne gtx8l_tloop
    inc bitmap8l_gt8l_lda+2
    bra gtx8l_tloop
gtx8l_tdone
    rts

gt8l_code  .byte 0
gt8l_hi    .byte 0
gt8l_glyph .fill 8, 0
gt8l_bx    .word 0
gt8l_by    .byte 0
gt8l_row   .byte 0
gt8l_col   .byte 0
gt8l_bits  .byte 0


; ---------------------------------------------------------------------
; Module variables. Kept out of zero page: these are only touched by
; the routine that owns them, never across a call boundary.
; ---------------------------------------------------------------------
.endif

; gfx8l_frame's private block, laid out in X16_P0..P6 order so the take
; and restore copies can loop
gb8l_x    .word 0
gb8l_y    .byte 0
gb8l_c    .byte 0
gb8l_w    .word 0
gb8l_h    .byte 0

gl8l_x0    .word 0
gl8l_y0    .byte 0
gl8l_x1    .word 0
gl8l_y1    .byte 0
gl8l_color .byte 0
gl8l_dx    .word 0
gl8l_dy    .word 0
gl8l_err   .word 0
gl8l_e2    .word 0
gl8l_sx    .word 0
gl8l_sy    .byte 0
gl8l_tmp   .byte 0

; (end zone)
.endif
.if xuse_bitmap8h
; --- inline gfx/bitmap8h.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/bitmap8h.asm -- VERA_2 640x480x256 SDRAM bitmap drawing
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Requires the MiSTer VERA_2 bitmap layer. The framebuffer is NOT VERA
; VRAM: it is the VERA_2 20-bit SDRAM byte address space behind $9F60-
; $9F6F. Feature-detect with gfx8h_has before relying on it.
;
; The framebuffer is 8bpp, one byte per pixel, rows of 640 bytes:
;   offset = y*640 + x, size = 307,200 bytes ($4B000).
;
; Calling convention follows the high-res engines:
;   X16_P0/P1 = x, X16_P2/P3 = y, colour in A.
; =====================================================================

; (zone: file scope in 64tass)

GFX8H_WIDTH       = 640
GFX8H_HEIGHT      = 480
GFX8H_STRIDE      = 640
GFX8H_FRAME_PAGES = 1200       ; 307200 / 256

; ---------------------------------------------------------------------
; gfx8h_has -- feature-detect the VERA_2 bitmap layer
;   out: carry set if present, carry clear otherwise
; ---------------------------------------------------------------------
gfx8h_has
    lda VERA2_ID
    cmp #VERA2_ID_MAGIC
    beq _yes
    clc
    rts
_yes
    sec
    rts

; ---------------------------------------------------------------------
; gfx8h_init -- select 640x480@8bpp and load a grayscale palette
; gfx8h_off  -- disable the VERA_2 bitmap layer
; ---------------------------------------------------------------------
gfx8h_init
    jsr gfx8h_pal_gray
    lda #(VERA2_CTRL_ENABLE | VERA2_CTRL_MODE_8BPP)
    sta VERA2_CTRL
    rts

gfx8h_off
    stz VERA2_CTRL
    rts

gfx8h_passthru_on
    lda VERA2_CTRL
    ora #VERA2_CTRL_PASSTHRU
    sta VERA2_CTRL
    rts

gfx8h_passthru_off
    lda #$FF - VERA2_CTRL_PASSTHRU
    and VERA2_CTRL
    sta VERA2_CTRL
    rts

; ---------------------------------------------------------------------
; gfx8h_pal_set -- set one VERA_2 palette entry
;   in: X = index, A = low byte (G<<4 | B), Y = high byte (R)
; gfx8h_pal_load -- load entries from RAM
;   in: X16_PTR0 = source, A = first index, X = count (0 loads nothing)
; ---------------------------------------------------------------------
gfx8h_pal_set
    sta g8h_t
    sty g8h_t2
    stx VERA2_PAL_IDX
    lda g8h_t
    sta VERA2_PAL_LO
    lda g8h_t2
    sta VERA2_PAL_HI
    rts

gfx8h_pal_load
    cpx #0
    beq _done
    sta VERA2_PAL_IDX
    stx g8h_n
    ldy #0
_loop
    lda (X16_PTR0),y
    sta VERA2_PAL_LO
    iny
    lda (X16_PTR0),y
    sta VERA2_PAL_HI
    iny
    dec g8h_n
    bne _loop
_done
    rts

gfx8h_pal_gray
    stz VERA2_PAL_IDX
    ldx #0
_loop
    txa
    lsr
    lsr
    lsr
    lsr
    sta g8h_t                   ; v = index >> 4
    asl
    asl
    asl
    asl
    ora g8h_t
    sta VERA2_PAL_LO            ; G = B = v
    lda g8h_t
    sta VERA2_PAL_HI            ; R = v
    inx
    bne _loop
    rts

; ---------------------------------------------------------------------
; gfx8h_setptr -- point VERA_2 DATA at pixel (x,y)
;   in: A = VERA2_INC_* stride index, X16_P0/P1 = x, X16_P2/P3 = y
; ---------------------------------------------------------------------
gfx8h_setptr
    asl
    asl
    asl
    asl
    sta g8h_inc
    jsr bitmap8h_addr_calc
    lda g8h_a0
    sta VERA2_ADDR_L
    lda g8h_a1
    sta VERA2_ADDR_M
    lda g8h_a2
    and #$0F
    ora g8h_inc
    sta VERA2_ADDR_H
    rts

; ---------------------------------------------------------------------
; gfx8h_clear -- fill the whole framebuffer with one colour
;   in: A = colour
; ---------------------------------------------------------------------
gfx8h_clear
    sta g8h_c
    stz VERA2_ADDR_L
    stz VERA2_ADDR_M
    stz VERA2_ADDR_H            ; ptr 0, stride +1
    lda #<GFX8H_FRAME_PAGES
    sta g8h_n
    lda #>GFX8H_FRAME_PAGES
    sta g8h_n+1
    lda g8h_c
    jmp bitmap8h_fill_pages

; ---------------------------------------------------------------------
; gfx8h_pset / gfx8h_read -- clipped pixel access
;   pset in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y
;   read out: carry clear, A = colour; carry set if off screen
; ---------------------------------------------------------------------
gfx8h_pset
    sta g8h_c
    jsr bitmap8h_onscreen
    bcs _off
    lda #VERA2_INC_1
    jsr gfx8h_setptr
    lda g8h_c
    sta VERA2_DATA
_off
    rts

gfx8h_read
    jsr bitmap8h_onscreen
    bcs _off
    lda #VERA2_INC_0
    jsr gfx8h_setptr
    lda VERA2_DATA
    clc
_off
    rts

; ---------------------------------------------------------------------
; gfx8h_hline / gfx8h_vline -- spans, no clipping
;   in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = length
; ---------------------------------------------------------------------
gfx8h_hline
    sta g8h_c
    lda X16_P4
    sta g8h_n
    lda X16_P5
    sta g8h_n+1
    ora g8h_n
    beq _done
    lda #VERA2_INC_1
    jsr gfx8h_setptr
    lda g8h_c
    jsr bitmap8h_fill_count
_done
    rts

gfx8h_vline
    sta g8h_c
    lda X16_P4
    sta g8h_n
    lda X16_P5
    sta g8h_n+1
    ora g8h_n
    beq _done
    lda #VERA2_INC_640
    jsr gfx8h_setptr
    lda g8h_c
    jsr bitmap8h_fill_count
_done
    rts

; ---------------------------------------------------------------------
; gfx8h_rect / gfx8h_frame -- rectangles, no clipping
;   in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y,
;       X16_P4/P5 = width, X16_P6/P7 = height
; ---------------------------------------------------------------------
gfx8h_rect
    sta g8h_rc
_row
    lda X16_P6
    ora X16_P7
    beq _done
    lda g8h_rc
    jsr gfx8h_hline
    inc X16_P2
    bne +
    inc X16_P3
+   lda X16_P6
    bne +
    dec X16_P7
+   dec X16_P6
    bra _row
_done
    rts

gfx8h_frame
    sta g8h_rc
    ldx #7
_take
    lda X16_P0,x
    sta g8h_fx,x
    dex
    bpl _take

    jsr bitmap8h_frame_span
    lda g8h_rc
    jsr gfx8h_hline

    jsr bitmap8h_frame_span
    clc
    lda g8h_fy
    adc g8h_rh
    sta X16_P2
    lda g8h_fy+1
    adc g8h_rh+1
    sta X16_P3
    lda X16_P2
    bne +
    dec X16_P3
+   dec X16_P2
    lda g8h_rc
    jsr gfx8h_hline

    jsr bitmap8h_frame_col
    lda g8h_rc
    jsr gfx8h_vline

    jsr bitmap8h_frame_col
    clc
    lda g8h_fx
    adc g8h_rw
    sta X16_P0
    lda g8h_fx+1
    adc g8h_rw+1
    sta X16_P1
    lda X16_P0
    bne +
    dec X16_P1
+   dec X16_P0
    lda g8h_rc
    jmp gfx8h_vline

bitmap8h_frame_span
    ldx #5
_s
    lda g8h_fx,x
    sta X16_P0,x
    dex
    bpl _s
    rts

bitmap8h_frame_col
    ldx #3
_c
    lda g8h_fx,x
    sta X16_P0,x
    dex
    bpl _c
    lda g8h_rh
    sta X16_P4
    lda g8h_rh+1
    sta X16_P5
    rts

; ---------------------------------------------------------------------
; gfx8h_line -- Bresenham line, clipped by gfx8h_pset
;   in: A = colour, P0/P1=x0, P2/P3=y0, P4/P5=x1, P6/P7=y1
; ---------------------------------------------------------------------
gfx8h_line
    sta g8h_lc
    ldx #7
_take
    lda X16_P0,x
    sta g8h_lx0,x
    dex
    bpl _take

    sec
    lda g8h_lx1
    sbc g8h_lx0
    sta g8h_ldx
    lda g8h_lx1+1
    sbc g8h_lx0+1
    sta g8h_ldx+1
    bpl _dx_pos
    sec
    lda #0
    sbc g8h_ldx
    sta g8h_ldx
    lda #0
    sbc g8h_ldx+1
    sta g8h_ldx+1
    lda #$FF
    sta g8h_lsx
    sta g8h_lsx+1
    bra _dx_done
_dx_pos
    lda #1
    sta g8h_lsx
    stz g8h_lsx+1
_dx_done

    sec
    lda g8h_ly1
    sbc g8h_ly0
    sta g8h_ldy
    lda g8h_ly1+1
    sbc g8h_ly0+1
    sta g8h_ldy+1
    bpl _dy_pos
    sec
    lda #0
    sbc g8h_ldy
    sta g8h_ldy
    lda #0
    sbc g8h_ldy+1
    sta g8h_ldy+1
    lda #$FF
    sta g8h_lsy
    sta g8h_lsy+1
    bra _dy_done
_dy_pos
    lda #1
    sta g8h_lsy
    stz g8h_lsy+1
_dy_done
    sec
    lda #0
    sbc g8h_ldy
    sta g8h_ldy
    lda #0
    sbc g8h_ldy+1
    sta g8h_ldy+1

    clc
    lda g8h_ldx
    adc g8h_ldy
    sta g8h_lerr
    lda g8h_ldx+1
    adc g8h_ldy+1
    sta g8h_lerr+1

_loop
    lda g8h_lc
    jsr bitmap8h_plot
    lda g8h_lx0
    cmp g8h_lx1
    bne _step
    lda g8h_lx0+1
    cmp g8h_lx1+1
    bne _step
    lda g8h_ly0
    cmp g8h_ly1
    bne _step
    lda g8h_ly0+1
    cmp g8h_ly1+1
    bne _step
    rts

_step
    lda g8h_lerr
    asl
    sta g8h_le2
    lda g8h_lerr+1
    rol
    sta g8h_le2+1

    sec
    lda g8h_le2
    sbc g8h_ldy
    lda g8h_le2+1
    sbc g8h_ldy+1
    bvc _nv1
    eor #$80
_nv1
    bmi _skip_x
    clc
    lda g8h_lerr
    adc g8h_ldy
    sta g8h_lerr
    lda g8h_lerr+1
    adc g8h_ldy+1
    sta g8h_lerr+1
    clc
    lda g8h_lx0
    adc g8h_lsx
    sta g8h_lx0
    lda g8h_lx0+1
    adc g8h_lsx+1
    sta g8h_lx0+1
_skip_x
    sec
    lda g8h_ldx
    sbc g8h_le2
    lda g8h_ldx+1
    sbc g8h_le2+1
    bvc _nv2
    eor #$80
_nv2
    bmi _skip_y
    clc
    lda g8h_lerr
    adc g8h_ldx
    sta g8h_lerr
    lda g8h_lerr+1
    adc g8h_ldx+1
    sta g8h_lerr+1
    clc
    lda g8h_ly0
    adc g8h_lsy
    sta g8h_ly0
    lda g8h_ly0+1
    adc g8h_lsy+1
    sta g8h_ly0+1
_skip_y
    jmp _loop

bitmap8h_plot
    sta g8h_c
    lda g8h_lx0
    sta X16_P0
    lda g8h_lx0+1
    sta X16_P1
    lda g8h_ly0
    sta X16_P2
    lda g8h_ly0+1
    sta X16_P3
    lda g8h_c
    jmp gfx8h_pset

; ---------------------------------------------------------------------
; gfx8h_pattern_set / gfx8h_pattern_rect
; ---------------------------------------------------------------------
gfx8h_pattern_set
    sta X16_T0
    stx X16_T0+1
    ldy #7
_copy
    lda (X16_T0),y
    sta gp8h_pat,y
    dey
    bpl _copy
    lda X16_P4
    sta gp8h_bg
    lda X16_P5
    sta gp8h_fg
    rts

gfx8h_pattern_rect
    lda X16_P4
    ora X16_P5
    ora X16_P6
    ora X16_P7
    bne +
    jmp _done
+
    lda X16_P2
    sta gp8h_by
    lda X16_P3
    sta gp8h_by+1
    lda X16_P0
    sta gp8h_bx
    lda X16_P1
    sta gp8h_bx+1
_row
    lda X16_P6
    ora X16_P7
    bne +
    jmp _done
+
    lda gp8h_bx
    sta gp8h_x
    lda gp8h_bx+1
    sta gp8h_x+1
    lda X16_P4
    sta gp8h_n
    lda X16_P5
    sta gp8h_n+1
    lda X16_P2
    and #7
    tay
    lda gp8h_pat,y
    sta gp8h_bits
_col
    lda gp8h_n
    ora gp8h_n+1
    beq _next_row
    lda gp8h_bits
    bmi _fg
    lda gp8h_bg
    bra _plot
_fg
    lda gp8h_fg
_plot
    sta gp8h_c
    lda gp8h_x
    sta X16_P0
    lda gp8h_x+1
    sta X16_P1
    lda gp8h_by
    sta X16_P2
    lda gp8h_by+1
    sta X16_P3
    lda gp8h_c
    jsr gfx8h_pset
    lda gp8h_bits
    asl
    adc #0
    sta gp8h_bits
    inc gp8h_x
    bne +
    inc gp8h_x+1
+   lda gp8h_n
    bne +
    dec gp8h_n+1
+   dec gp8h_n
    jmp _col
_next_row
    inc gp8h_by
    bne +
    inc gp8h_by+1
+   lda gp8h_by
    sta X16_P2
    lda gp8h_by+1
    sta X16_P3
    lda X16_P6
    bne +
    dec X16_P7
+   dec X16_P6
    jmp _row
_done
    rts

; ---------------------------------------------------------------------
; gfx8h_blit / gfx8h_blitm -- RAM to framebuffer, row-major source
;   blit in: A = op (0 copy, 1 OR, 2 AND, 3 XOR)
;   common: P0/P1=x, P2/P3=y, P4=width (1-255), P5=height, P6/P7=source
; ---------------------------------------------------------------------
gfx8h_blit
    and #3
    sta g8h_op
    bra bitmap8h_blit_common

gfx8h_blitm
    lda #$80
    sta g8h_op
bitmap8h_blit_common
    lda X16_P6
    sta X16_PTR3
    lda X16_P7
    sta X16_PTR3+1
_row
    lda X16_P5
    beq _done
    ldy #0
_col
    cpy X16_P4
    beq _next_row
    lda (X16_PTR3),y
    sta g8h_ink
    lda g8h_op
    bmi _masked
    beq _copy
    lda #VERA2_INC_0
    jsr gfx8h_setptr
    lda VERA2_DATA
    sta g8h_t
    lda g8h_op
    cmp #1
    beq _or
    cmp #2
    beq _and
    lda g8h_ink
    eor g8h_t
    bra _store
_and
    lda g8h_ink
    and g8h_t
    bra _store
_or
    lda g8h_ink
    ora g8h_t
    bra _store
_masked
    lda g8h_ink
    beq _advance
_copy
    lda g8h_ink
_store
    jsr gfx8h_pset
_advance
    inc X16_P0
    bne +
    inc X16_P1
+   iny
    jmp _col
_next_row
    sec
    lda X16_P0
    sbc X16_P4
    sta X16_P0
    bcs +
    dec X16_P1
+   clc
    lda X16_PTR3
    adc X16_P4
    sta X16_PTR3
    bcc +
    inc X16_PTR3+1
+   inc X16_P2
    bne +
    inc X16_P3
+   dec X16_P5
    jmp _row
_done
    rts

; ---------------------------------------------------------------------
; gfx8h_copy -- VERA_2 SDRAM-to-SDRAM hardware copy, then wait
;   in: P0/P1/P2 = source, P3/P4/P5 = destination, A/X/Y = length
; ---------------------------------------------------------------------
gfx8h_copy
    sta VERA2_BLIT_LEN_L
    stx VERA2_BLIT_LEN_M
    sty VERA2_BLIT_LEN_H
    lda X16_P0
    sta VERA2_ADDR_L
    lda X16_P1
    sta VERA2_ADDR_M
    lda X16_P2
    and #$0F
    sta VERA2_ADDR_H            ; source pointer, stride +1
    lda X16_P3
    sta VERA2_BLIT_DST_L
    lda X16_P4
    sta VERA2_BLIT_DST_M
    lda X16_P5
    and #$0F
    sta VERA2_BLIT_DST_H
    lda #1
    sta VERA2_BLIT_CTRL
gfx8h_copy_wait
    lda VERA2_BLIT_CTRL
    and #1
    bne gfx8h_copy_wait
    rts

; ---------------------------------------------------------------------
; private helpers
; ---------------------------------------------------------------------
bitmap8h_onscreen
    lda X16_P1
    cmp #>GFX8H_WIDTH
    bcc _xok
    bne _bad
    lda X16_P0
    cmp #<GFX8H_WIDTH
    bcs _bad
_xok
    lda X16_P3
    cmp #>GFX8H_HEIGHT
    bcc _ok
    bne _bad
    lda X16_P2
    cmp #<GFX8H_HEIGHT
    bcs _bad
_ok
    clc
    rts
_bad
    sec
    rts

bitmap8h_addr_calc
    lda X16_P2                  ; y*640 = y*512 + y*128, in ~30 cycles:
    lsr                         ; lo = (y & 1) << 7
    tax                         ; md/hi = (y << 1) + (y >> 1)
    lda #0
    ror
    sta g8h_a0
    lda X16_P2
    asl
    sta g8h_a1
    lda #0
    rol
    sta g8h_a2
    txa
    clc
    adc g8h_a1
    sta g8h_a1
    bcc +
    inc g8h_a2
+
    lda X16_P3                  ; y >= 256: + 256*640 = $28000
    beq _addx
    clc
    lda g8h_a1
    adc #$80
    sta g8h_a1
    lda g8h_a2
    adc #$02
    sta g8h_a2
_addx
    clc                         ; + x
    lda g8h_a0
    adc X16_P0
    sta g8h_a0
    lda g8h_a1
    adc X16_P1
    sta g8h_a1
    bcc +
    inc g8h_a2
+   rts

bitmap8h_fill_count
    ldy g8h_n+1                 ; high byte first, so beq tests the LOW byte:
    ldx g8h_n                  ; a partial low byte needs one extra dey pass,
    beq _full                  ; a zero low byte does not (testing the high
    iny                        ; byte made every width < 256 write 64K)
_full
_loop
    sta VERA2_DATA
    dex
    bne _loop
    dey
    bne _loop
    rts

bitmap8h_fill_pages
    ldy g8h_n+1
_outer
    ldx #0
_inner
    sta VERA2_DATA
    dex
    bne _inner
    lda g8h_n
    bne +
    dec g8h_n+1
+   dec g8h_n
    lda g8h_n
    ora g8h_n+1
    beq _done
    lda g8h_c
    bra _outer
_done
    rts

; ---------------------------------------------------------------------
; data
; ---------------------------------------------------------------------
g8h_a0  .byte 0
g8h_a1  .byte 0
g8h_a2  .byte 0
g8h_inc .byte 0
g8h_c   .byte 0
g8h_t   .byte 0
g8h_t2  .byte 0
g8h_n   .word 0
g8h_op  .byte 0
g8h_ink .byte 0

g8h_fx  .word 0
g8h_fy  .word 0
g8h_rw  .word 0
g8h_rh  .word 0
g8h_rc  .byte 0

gp8h_pat  .fill 8, 0
gp8h_bg   .byte 0
gp8h_fg   .byte 0
gp8h_bits .byte 0
gp8h_bx   .word 0
gp8h_x    .word 0
gp8h_by   .word 0
gp8h_n    .word 0
gp8h_c    .byte 0

g8h_lc   .byte 0
g8h_lx0  .word 0
g8h_ly0  .word 0
g8h_lx1  .word 0
g8h_ly1  .word 0
g8h_ldx  .word 0
g8h_ldy  .word 0
g8h_lerr .word 0
g8h_le2  .word 0
g8h_lsx  .word 0
g8h_lsy  .word 0

; (end zone)
.endif
.if xuse_bitmap2h
; --- inline gfx/bitmap2h.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/bitmap2h.asm -- 640x480x4 bitmap drawing (2bpp)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; Requires X16_USE_VERA (vera_fill) and X16_USE_VERAFX (fx_fill).
;
; The framebuffer is 2bpp at VRAM $00000: 4 pixels per byte packed
; MSB-first (the leftmost pixel is bits 7:6), rows of 160 bytes,
; 76,800 bytes in all. A pixel byte is at y*160 + (x>>2); its position
; within the byte is x & 3. VERA renders it as layer-0 bitmap, 2bpp,
; 640 wide, HSCALE = VSCALE = $80 -- gfx2h_init programs exactly that
; (there is no KERNAL screen mode for it).
;
; Colours are 0-3 out of the first four palette entries. gfx2h_init
; loads a paper-and-ink default: 0 white, 1 light gray, 2 dark gray,
; 3 black. pal_set/pal_load re-colour without touching the pixels.
;
; gfx2h_pset and gfx2h_read clip. The span/rect/line/blit primitives do
; NOT: they assume their arguments are on screen (the 8bpp module's
; policy, for the same reason -- a caller that knows its geometry
; should not pay for a clip on every span).
;
; Sub-byte pixels make 2bpp spans three-phase: a partial head byte, a
; run of whole bytes, a partial tail byte. The partial bytes are
; read-modify-write through data port 0 with INC_0; the middle run is
; a plain vera_fill. Column walks (vline, blitm) pair port 1 (read)
; with port 0 (write), both stepping VERA_INC_160.
; =====================================================================

; (zone: file scope in 64tass)

GFX2H_WIDTH  = 640
GFX2H_HEIGHT = 480
GFX2H_STRIDE = 160

; ---------------------------------------------------------------------
; gfx2h_init -- program the 640x480@2bpp mode on bare VERA registers.
;
; Layer 0 becomes the bitmap and is enabled; layer 1 (the text screen,
; which would overlay garbage) is disabled; sprites are left as the
; caller had them. Palette entries 0-3 get the default ramp. The
; framebuffer contents are NOT cleared -- call gfx2h_clear.
; ---------------------------------------------------------------------
gfx2h_init
    #vera_dcsel 0
    lda #$80                    ; 1:1 scale -> full 640x480
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    stz VERA_DC_BORDER

    lda #(VERA_LAYER_BITMAP | VERA_LAYER_BPP_2)
    sta VERA_L0_CONFIG
    lda #$01                    ; bitmap base $00000, 640 pixels wide
    sta VERA_L0_TILEBASE
    stz VERA_L0_HSCROLL_L
    stz VERA_L0_HSCROLL_H       ; bits 3:0 = bitmap palette offset
    stz VERA_L0_VSCROLL_L
    stz VERA_L0_VSCROLL_H

    ; palette 0-3: white paper, two grays, black ink
    #vera_addr 0, VRAM_PALETTE, VERA_INC_1
    ldx #0
_pal
    lda bitmap2h_defpal,x
    sta VERA_DATA0
    inx
    cpx #8
    bne _pal

    lda #VERA_VIDEO_LAYER1_EN   ; layer 1 off, layer 0 on
    trb VERA_DC_VIDEO
    lda #VERA_VIDEO_LAYER0_EN
    tsb VERA_DC_VIDEO
    rts

bitmap2h_defpal
    .byte $FF, $0F, $AA, $0A, $55, $05, $00, $00

; ---------------------------------------------------------------------
; gfx2h_clear -- fill the whole framebuffer with one colour
;   in:  A = colour (0-3)
;
; Uses the FX 32-bit cache write (~4x a CPU byte loop; measured 1.25
; frames per full screen against 5.25). Clobbers X16_P0..P4.
; ---------------------------------------------------------------------
gfx2h_clear
    and #3
    tax
    lda bitmap2h_colbyte,x
    pha
    stz X16_P0                  ; first half: $00000, 38,400 bytes
    stz X16_P1
    stz X16_P2
    lda #<(GFX2H_STRIDE * GFX2H_HEIGHT / 2)
    sta X16_P3
    lda #>(GFX2H_STRIDE * GFX2H_HEIGHT / 2)
    sta X16_P4
    pla
    pha
    jsr fx_fill
    lda #<(GFX2H_STRIDE * GFX2H_HEIGHT / 2)
    sta X16_P0                  ; second half starts at $09600
    sta X16_P3
    lda #>(GFX2H_STRIDE * GFX2H_HEIGHT / 2)
    sta X16_P1
    sta X16_P4
    stz X16_P2
    pla
    jmp fx_fill

; ---------------------------------------------------------------------
; gfx2h_setptr -- point data port 0 at the byte holding pixel (x,y)
;   in:  A = increment index (VERA_INC_*)
;        X16_P0/P1 = x, X16_P2/P3 = y
;   out: A = x & 3 (the pixel's position within the byte)
;
; y*160 = (y<<5) + (y<<5)<<2, so no multiply is needed; the result is
; 17-bit. Stepping by VERA_INC_160 then walks straight down a column.
; ---------------------------------------------------------------------
gfx2h_setptr
    pha
    jsr bitmap2h_addr_calc
    pla
    jsr bitmap2h_aim0
    lda X16_P0
    and #3
    rts

; ---------------------------------------------------------------------
; gfx2h_pset -- set one pixel, clipped
;   in:  A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y
; ---------------------------------------------------------------------
gfx2h_pset
    and #3
    sta g2h_c
    jsr bitmap2h_onscreen
    bcs _off

    jsr bitmap2h_addr_calc
    lda #VERA_INC_0
    jsr bitmap2h_aim0

    lda X16_P0
    and #3
    tax
    lda VERA_DATA0              ; INC_0: the read does not move the port
    and bitmap2h_keep,x
    sta g2h_t
    ldy g2h_c
    lda bitmap2h_colbyte,y
    and bitmap2h_pix,x
    ora g2h_t
    sta VERA_DATA0
_off
    rts

; ---------------------------------------------------------------------
; gfx2h_read -- read one pixel
;   in:  X16_P0/P1 = x, X16_P2/P3 = y
;   out: carry clear, A = colour (0-3); carry set if (x,y) is off
;        screen (A undefined)
; ---------------------------------------------------------------------
gfx2h_read
    jsr bitmap2h_onscreen
    bcs _roff

    jsr bitmap2h_addr_calc
    lda #VERA_INC_0
    jsr bitmap2h_aim0

    lda X16_P0
    and #3
    tax
    lda VERA_DATA0
_shift
    cpx #3                      ; pixel 3 sits in bits 1:0 already
    beq _done
    lsr
    lsr
    inx
    bra _shift
_done
    and #3
    clc
_roff
    rts

; ---------------------------------------------------------------------
; gfx2h_hline -- horizontal span (no clipping)
;   in:  A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y,
;        X16_P4/P5 = length in pixels
;
; Head and tail partials are read-modify-write; the middle whole bytes
; are one vera_fill.
; ---------------------------------------------------------------------
gfx2h_hline
    and #3
    tax
    lda bitmap2h_colbyte,x
    sta g2h_cb

    lda X16_P4
    sta g2h_n
    ora X16_P5
    bne _hgo                    ; zero length: nothing to draw
    rts
_hgo
    lda X16_P5
    sta g2h_n+1

    jsr bitmap2h_addr_calc

    lda X16_P0
    and #3
    sta g2h_p                    ; phase = x & 3
    bne _head
    ; phase 0: a head byte only exists when the span is shorter than
    ; one whole byte
    lda g2h_n+1
    bne _middle
    lda g2h_n
    cmp #4
    bcs _middle

_head
    jsr bitmap2h_headmask               ; mask -> A, head pixel count -> g2h_t
    jsr bitmap2h_rmw                    ; ink = colour byte through this mask
    jsr bitmap2h_headadv                ; n -= head pixels, on to the whole bytes

_middle
    jsr bitmap2h_quadcount              ; m = n >> 2 whole bytes
    beq _tail

    lda #VERA_INC_1
    jsr bitmap2h_aim0
    lda g2h_cb
    ldx g2h_m
    ldy g2h_m+1
    jsr vera_fill               ; clobbers X16_T0..T2, not g2h_*
    jsr bitmap2h_a_addm                 ; addr += m

_tail
    jsr bitmap2h_tailmask
    beq _hdone
    jsr bitmap2h_rmw
_hdone
    rts

; ---------------------------------------------------------------------
; gfx2h_vline -- vertical span (no clipping)
;   in:  A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y,
;        X16_P4/P5 = length in pixels
;
; One column of read-modify-writes: port 1 reads, port 0 writes, both
; stepping a whole row per access.
; ---------------------------------------------------------------------
gfx2h_vline
    and #3
    tax
    lda bitmap2h_colbyte,x
    sta g2h_cb

    lda X16_P4
    sta g2h_n
    ora X16_P5
    beq _vdone
    lda X16_P5
    sta g2h_n+1

    jsr bitmap2h_addr_calc
    lda #VERA_INC_160
    jsr bitmap2h_aim1
    lda #VERA_INC_160
    jsr bitmap2h_aim0

    lda X16_P0
    and #3
    tax
    lda g2h_cb
    and bitmap2h_pix,x
    sta g2h_ink                  ; ink and keep are loop-invariant
    lda bitmap2h_keep,x
    sta g2h_msk

    ldx g2h_n                    ; vera_fill's page-count idiom
    ldy g2h_n+1
    txa
    beq _vfull                  ; low byte 0 -> exactly hi*256 rows
    iny                         ; otherwise one extra partial page
_vfull
_vloop
    lda VERA_DATA1
    and g2h_msk
    ora g2h_ink
    sta VERA_DATA0
    dex
    bne _vloop
    dey
    bne _vloop
_vdone
    rts

; ---------------------------------------------------------------------
; gfx2h_rect -- filled rectangle (no clipping)
;   in:  A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y,
;        X16_P4/P5 = width, X16_P6/P7 = height
; ---------------------------------------------------------------------
gfx2h_rect
    sta g2h_rc
    lda X16_P4
    sta g2h_rw
    lda X16_P5
    sta g2h_rw+1
    lda X16_P6
    sta g2h_rh
    lda X16_P7
    sta g2h_rh+1
_rrow
    lda g2h_rh
    ora g2h_rh+1
    beq _rdone
    lda g2h_rw                   ; hline consumes the length: reload
    sta X16_P4
    lda g2h_rw+1
    sta X16_P5
    lda g2h_rc
    jsr gfx2h_hline              ; leaves P0..P3 alone
    inc X16_P2                  ; y += 1
    bne _ry_ok
    inc X16_P3
_ry_ok
    lda g2h_rh
    bne _rh_ok
    dec g2h_rh+1
_rh_ok
    dec g2h_rh
    bra _rrow
_rdone
    rts

; ---------------------------------------------------------------------
; gfx2h_frame -- rectangle outline (no clipping)
;   same arguments as gfx2h_rect
; ---------------------------------------------------------------------
gfx2h_frame
    sta g2h_rc
    ldx #7                      ; private copies: the edges reuse the
_take                           ; parameter block as they go; g2h_fx..
    lda X16_P0,x                ; g2h_rh are laid out in P0..P7 order
    sta g2h_fx,x
    dex
    bpl _take

    jsr bitmap2h_f_span                 ; top edge
    jsr gfx2h_hline

    jsr bitmap2h_f_span                 ; bottom edge: y + h - 1
    clc
    lda g2h_fy
    adc g2h_rh
    sta X16_P2
    lda g2h_fy+1
    adc g2h_rh+1
    sta X16_P3
    lda X16_P2
    bne _f_nb1
    dec X16_P3
_f_nb1
    dec X16_P2
    lda g2h_rc
    jsr gfx2h_hline

    jsr bitmap2h_f_col                  ; left edge
    jsr gfx2h_vline

    jsr bitmap2h_f_col                  ; right edge: x + w - 1
    clc
    lda g2h_fx
    adc g2h_rw
    sta X16_P0
    lda g2h_fx+1
    adc g2h_rw+1
    sta X16_P1
    lda X16_P0
    bne _f_nb2
    dec X16_P1
_f_nb2
    dec X16_P0
    lda g2h_rc
    jmp gfx2h_vline

; x, y, width in the block, colour in A -- arguments for gfx2h_hline
bitmap2h_f_span
    ldx #5
bitmap2h_fsp_l
    lda g2h_fx,x
    sta X16_P0,x
    dex
    bpl bitmap2h_fsp_l
    lda g2h_rc
    rts

; x, y, height in the block, colour in A -- arguments for gfx2h_vline
bitmap2h_f_col
    ldx #3
bitmap2h_fcl_l
    lda g2h_fx,x
    sta X16_P0,x
    dex
    bpl bitmap2h_fcl_l
    lda g2h_rh
    sta X16_P4
    lda g2h_rh+1
    sta X16_P5
    lda g2h_rc
    rts

; ---------------------------------------------------------------------
; gfx2h_line -- Bresenham, any direction; plots through gfx2h_pset so
; the line clips at the screen edges
;   in:  A = colour (0-3)
;        X16_P0/P1 = x0, X16_P2/P3 = y0
;        X16_P4/P5 = x1, X16_P6/P7 = y1
; ---------------------------------------------------------------------
gfx2h_line
    sta g2h_lc
    ldx #7                      ; P0..P7 -> g2h_lx0..g2h_ly1, which are
_take                           ; laid out in the same order
    lda X16_P0,x
    sta g2h_lx0,x
    dex
    bpl _take

    ; dx = |x1 - x0|, sx = sign
    sec
    lda g2h_lx1
    sbc g2h_lx0
    sta g2h_ldx
    lda g2h_lx1+1
    sbc g2h_lx0+1
    sta g2h_ldx+1
    bpl _dx_pos
    sec
    lda #0
    sbc g2h_ldx
    sta g2h_ldx
    lda #0
    sbc g2h_ldx+1
    sta g2h_ldx+1
    lda #$FF
    sta g2h_lsx
    sta g2h_lsx+1
    bra _dx_done
_dx_pos
    lda #$01
    sta g2h_lsx
    stz g2h_lsx+1
_dx_done

    ; dy = -|y1 - y0|, sy = sign
    sec
    lda g2h_ly1
    sbc g2h_ly0
    sta g2h_lt
    lda g2h_ly1+1
    sbc g2h_ly0+1
    sta g2h_lt+1
    bpl _dy_pos
    sec
    lda #0
    sbc g2h_lt
    sta g2h_lt
    lda #0
    sbc g2h_lt+1
    sta g2h_lt+1
    lda #$FF
    sta g2h_lsy
    sta g2h_lsy+1
    bra _dy_done
_dy_pos
    lda #$01
    sta g2h_lsy
    stz g2h_lsy+1
_dy_done
    sec                         ; g2h_ldy = -|dy|
    lda #0
    sbc g2h_lt
    sta g2h_ldy
    lda #0
    sbc g2h_lt+1
    sta g2h_ldy+1

    clc                         ; err = dx + dy
    lda g2h_ldx
    adc g2h_ldy
    sta g2h_lerr
    lda g2h_ldx+1
    adc g2h_ldy+1
    sta g2h_lerr+1

_loop
    lda g2h_lx0                  ; plot (x0, y0)
    sta X16_P0
    lda g2h_lx0+1
    sta X16_P1
    lda g2h_ly0
    sta X16_P2
    lda g2h_ly0+1
    sta X16_P3
    lda g2h_lc
    jsr gfx2h_pset

    lda g2h_lx0                  ; reached the end point?
    cmp g2h_lx1
    bne _step
    lda g2h_lx0+1
    cmp g2h_lx1+1
    bne _step
    lda g2h_ly0
    cmp g2h_ly1
    bne _step
    lda g2h_ly0+1
    cmp g2h_ly1+1
    bne _step
    rts

_step
    lda g2h_lerr                 ; e2 = err * 2
    asl
    sta g2h_le2
    lda g2h_lerr+1
    rol
    sta g2h_le2+1

    ; if e2 >= dy  ->  err += dy, x0 += sx
    sec
    lda g2h_le2
    sbc g2h_ldy
    lda g2h_le2+1
    sbc g2h_ldy+1
    bvc _nv1
    eor #$80                    ; signed compare: fold overflow into sign
_nv1
    bmi _skip_x
    clc
    lda g2h_lerr
    adc g2h_ldy
    sta g2h_lerr
    lda g2h_lerr+1
    adc g2h_ldy+1
    sta g2h_lerr+1
    clc
    lda g2h_lx0
    adc g2h_lsx
    sta g2h_lx0
    lda g2h_lx0+1
    adc g2h_lsx+1
    sta g2h_lx0+1
_skip_x

    ; if e2 <= dx  ->  err += dx, y0 += sy
    sec
    lda g2h_ldx
    sbc g2h_le2
    lda g2h_ldx+1
    sbc g2h_le2+1
    bvc _nv2
    eor #$80
_nv2
    bmi _skip_y
    clc
    lda g2h_lerr
    adc g2h_ldx
    sta g2h_lerr
    lda g2h_lerr+1
    adc g2h_ldx+1
    sta g2h_lerr+1
    clc
    lda g2h_ly0
    adc g2h_lsy
    sta g2h_ly0
    lda g2h_ly0+1
    adc g2h_lsy+1
    sta g2h_ly0+1
_skip_y
    jmp _loop

; ---------------------------------------------------------------------
; gfx2h_pattern_set -- expand an 8x8 1bpp pattern for gfx2h_pattern_rect
;   in:  A = pattern low, X = pattern high (8 row bytes, top first;
;            bit 7 is the leftmost pixel)
;        Y = colours: (background << 2) | foreground
;
; Patterns tile from the screen origin, so each row expands to exactly
; two 2bpp bytes (16 bits); which of the pair a framebuffer byte uses
; is the parity of its address. The expansion is cached in g2h_pat.
; ---------------------------------------------------------------------
gfx2h_pattern_set
    sta X16_T6                  ; T6/T7 = pattern pointer
    stx X16_T7
    tya
    and #3
    tax
    lda bitmap2h_colbyte,x              ; replicated foreground
    sta g2h_pfg
    tya
    lsr
    lsr
    and #3
    tax
    lda bitmap2h_colbyte,x              ; replicated background
    sta g2h_pbg

    ldx #0                      ; cache index (2 bytes per row)
    ldy #0                      ; pattern row
_prow
    sty g2h_t
    lda (X16_T6),y
    sta g2h_pr                   ; the row's 8 bits, consumed by asl
    jsr bitmap2h_p_half                 ; pixels 0-3 -> even byte
    sta g2h_pat,x
    inx
    jsr bitmap2h_p_half                 ; pixels 4-7 -> odd byte
    sta g2h_pat,x
    inx
    ldy g2h_t
    iny
    cpy #8
    bne _prow
    rts

; expand the next 4 bits of g2h_pr (MSB first) into one 2bpp byte:
; a set bit becomes the foreground colour, a clear one the background
bitmap2h_p_half
    stz g2h_t2
    ldy #0                      ; pixel 0..3 within the byte
_pbit
    asl g2h_pr
    bcs _pfg
    lda g2h_pbg
    bra _pmix
_pfg
    lda g2h_pfg
_pmix
    and bitmap2h_pix,y                  ; keep just this pixel's two bits
    ora g2h_t2
    sta g2h_t2
    iny
    cpy #4
    bne _pbit
    lda g2h_t2
    rts

; ---------------------------------------------------------------------
; gfx2h_pattern_rect -- fill a rectangle with the current pattern
;   in:  X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = width,
;        X16_P6/P7 = height   (no clipping)
; ---------------------------------------------------------------------
gfx2h_pattern_rect
    lda X16_P4
    sta g2h_rw
    lda X16_P5
    sta g2h_rw+1
    lda X16_P6
    sta g2h_rh
    lda X16_P7
    sta g2h_rh+1
_yrow
    lda g2h_rh
    ora g2h_rh+1
    beq _ydone
    jsr bitmap2h_p_row
    inc X16_P2
    bne _py_ok
    inc X16_P3
_py_ok
    lda g2h_rh
    bne _ph_ok
    dec g2h_rh+1
_ph_ok
    dec g2h_rh
    bra _yrow
_ydone
    rts

; one pattern row at (P0..P3), width g2h_rw
bitmap2h_p_row
    lda g2h_rw
    sta g2h_n
    ora g2h_rw+1
    bne _prgo
    rts
_prgo
    lda g2h_rw+1
    sta g2h_n+1

    jsr bitmap2h_addr_calc

    ; the row's two pattern bytes, in address-parity order
    lda X16_P2
    and #7
    asl
    tax
    lda g2h_a0
    and #1
    beq _even
    inx                         ; an odd start address uses the odd
    lda g2h_pat,x                ; byte first
    sta g2h_pb0
    dex
    lda g2h_pat,x
    sta g2h_pb1
    bra _parity_done
_even
    lda g2h_pat,x
    sta g2h_pb0
    inx
    lda g2h_pat,x
    sta g2h_pb1
_parity_done

    lda X16_P0
    and #3
    sta g2h_p
    bne _phead
    lda g2h_n+1
    bne _pmiddle
    lda g2h_n
    cmp #4
    bcs _pmiddle

_phead
    jsr bitmap2h_headmask               ; mask -> A, head pixel count -> g2h_t
    tax                         ; mask in X for bitmap2h_rmwp
    lda g2h_pb0
    jsr bitmap2h_rmwp
    jsr bitmap2h_headadv
    lda g2h_pb0                  ; next byte has the other parity
    ldx g2h_pb1
    sta g2h_pb1
    stx g2h_pb0

_pmiddle
    jsr bitmap2h_quadcount
    beq _ptail

    lda #VERA_INC_1
    jsr bitmap2h_aim0
    ldx g2h_m                    ; vera_fill's page-count idiom
    ldy g2h_m+1
    txa
    beq _pfull
    iny
_pfull
_ploop
    lda g2h_pb0
    sta VERA_DATA0
    lda g2h_pb0                  ; swap the parity pair
    pha
    lda g2h_pb1
    sta g2h_pb0
    pla
    sta g2h_pb1
    dex
    bne _ploop
    dey
    bne _ploop
    jsr bitmap2h_a_addm                 ; addr += m

_ptail
    jsr bitmap2h_tailmask
    beq _prdone
    tax
    lda g2h_pb0
    jsr bitmap2h_rmwp
_prdone
    rts

; ---------------------------------------------------------------------
; gfx2h_blit -- copy a byte-aligned image from CPU RAM into the bitmap
;   in:  A = raster op: 0 copy, 1 OR, 2 AND, 3 XOR
;        X16_P0/P1 = x (bits 1:0 ignored: byte-aligned),
;        X16_P2/P3 = y, X16_P4 = width in BYTES (4-pixel units),
;        X16_P5 = height in rows, X16_P6/P7 = source (row-major)
;
; The source pointer is X16_PTR3 -- P6/P7 double as real zero page, so
; (PTR3),y addressing costs nothing extra. No clipping.
; ---------------------------------------------------------------------
; The three RMW ops share one loop whose opcode at bitmap2h_g2h_blit_op is patched
; from bitmap2h_g2h_optab (ora/and/eor (zp),y) -- the 8bpp module's gfx8l_blit
; does the same.
gfx2h_blit
    and #3
    sta g2h_op                   ; copy (op 0) needs no opcode patch
    beq +
    tax
    lda bitmap2h_g2h_optab-1,x
    sta bitmap2h_g2h_blit_op
+   jsr bitmap2h_addr_calc
    lda X16_P5
    sta g2h_h
bitmap2h_g2h_blit_row
    lda #VERA_INC_1
    jsr bitmap2h_aim1                   ; ops read through port 1...
    lda #VERA_INC_1
    jsr bitmap2h_aim0                   ; ...and everything writes port 0
    ldy #0
    lda g2h_op
    beq bitmap2h_g2h_blit_copy
bitmap2h_g2h_blit_rmw
    lda VERA_DATA1
bitmap2h_g2h_blit_op
    ora (X16_PTR3),y            ; opcode patched: op 1/2/3 = ora/and/eor
    sta VERA_DATA0
    iny
    cpy X16_P4
    bne bitmap2h_g2h_blit_rmw
    bra bitmap2h_g2h_blit_done
bitmap2h_g2h_blit_copy
    lda (X16_PTR3),y
    sta VERA_DATA0
    iny
    cpy X16_P4
    bne bitmap2h_g2h_blit_copy
bitmap2h_g2h_blit_done
    clc                         ; src += width
    lda X16_PTR3
    adc X16_P4
    sta X16_PTR3
    bcc +
    inc X16_PTR3+1
+   jsr bitmap2h_a_row                  ; dest += one row
    dec g2h_h
    bne bitmap2h_g2h_blit_row
    rts

; ---------------------------------------------------------------------
; gfx2h_blitm -- masked blit of pre-shifted column-major data
;   in:  X16_P0/P1 = x (any pixel position), X16_P2/P3 = y,
;        X16_P4 = height in rows (1-127), X16_P5 = width in COLUMNS
;        (framebuffer bytes), X16_P6/P7 = source
;
; The source holds, for each of the P5 columns, P4 (mask, data) byte
; PAIRS walking down the rows: fb' = (fb AND mask) OR data. The caller
; supplies data already shifted for this x's pixel phase (x & 3) --
; pre-shifted glyph caches are the whole point: at 833 cycles per 8x8
; glyph this is what makes proportional text affordable (spike-proven;
; see the CXRF project). No clipping.
; ---------------------------------------------------------------------
gfx2h_blitm
    jsr bitmap2h_addr_calc
    lda X16_P5
    sta g2h_w
_mcol
    lda #VERA_INC_160
    jsr bitmap2h_aim1
    lda #VERA_INC_160
    jsr bitmap2h_aim0
    ldy #0
    ldx X16_P4
_mrow
    lda VERA_DATA1
    and (X16_PTR3),y            ; mask byte
    iny
    ora (X16_PTR3),y            ; data byte
    iny
    sta VERA_DATA0
    dex
    bne _mrow

    clc                         ; src += 2 * height (one column)
    tya
    adc X16_PTR3
    sta X16_PTR3
    bcc _msrc_ok
    inc X16_PTR3+1
_msrc_ok
    jsr bitmap2h_a_inc                  ; dest: next byte column
    dec g2h_w
    bne _mcol
    rts

; ---------------------------------------------------------------------
; module plumbing
; ---------------------------------------------------------------------

; carry clear if (P0/P1, P2/P3) is on screen
bitmap2h_onscreen
    lda X16_P1                  ; x < 640?
    cmp #>GFX2H_WIDTH
    bcc _x_ok
    bne _bad
    lda X16_P0
    cmp #<GFX2H_WIDTH
    bcs _bad
_x_ok
    lda X16_P3                  ; y < 480?
    cmp #>GFX2H_HEIGHT
    bcc _ok
    bne _bad
    lda X16_P2
    cmp #<GFX2H_HEIGHT
    bcs _bad
_ok
    clc
    rts
_bad
    sec
    rts

; g2h_a2:a1:a0 = y*160 + (x>>2)   (from X16_P0..P3; clobbers T0..T2)
bitmap2h_addr_calc
    lda X16_P2                  ; t = y << 5
    sta g2h_a0
    lda X16_P3
    sta g2h_a1
    asl g2h_a0
    rol g2h_a1
    asl g2h_a0
    rol g2h_a1
    asl g2h_a0
    rol g2h_a1
    asl g2h_a0
    rol g2h_a1
    asl g2h_a0
    rol g2h_a1

    lda g2h_a0                   ; T2:T1:T0 = t << 2
    sta X16_T0
    lda g2h_a1
    sta X16_T1
    stz X16_T2
    asl X16_T0
    rol X16_T1
    rol X16_T2
    asl X16_T0
    rol X16_T1
    rol X16_T2

    clc                         ; y*160 = t + (t << 2)
    lda g2h_a0
    adc X16_T0
    sta g2h_a0
    lda g2h_a1
    adc X16_T1
    sta g2h_a1
    lda #0
    adc X16_T2
    sta g2h_a2

    lda X16_P1                  ; + x >> 2
    sta X16_T1
    lda X16_P0
    lsr X16_T1
    ror
    lsr X16_T1
    ror
    clc
    adc g2h_a0
    sta g2h_a0
    lda X16_T1
    adc g2h_a1
    sta g2h_a1
    lda #0
    adc g2h_a2
    sta g2h_a2
    rts

; point port 0 (write side) at g2h_a; A = increment index.
; Scratch is g2h_inc, NOT g2h_t: hline/pattern hold a pixel count in
; g2h_t across the bitmap2h_rmw call, and bitmap2h_rmw aims through here.
bitmap2h_aim0
    asl
    asl
    asl
    asl
    sta g2h_inc
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    bra bitmap2h_aimgo

; point port 1 (read side) at g2h_a; A = increment index
bitmap2h_aim1
    asl
    asl
    asl
    asl
    sta g2h_inc
    lda #VERA_CTRL_ADDRSEL
    tsb VERA_CTRL
bitmap2h_aimgo
    lda g2h_a0
    sta VERA_ADDR_L
    lda g2h_a1
    sta VERA_ADDR_M
    lda g2h_a2
    and #VERA_ADDR_H_BANK
    ora g2h_inc
    sta VERA_ADDR_H
    rts

; the three-phase span geometry, shared by gfx2h_hline and bitmap2h_p_row:
;   bitmap2h_headmask:  from phase g2h_p and count g2h_n, the head pixel count
;               -> g2h_t and the pixel mask (from[p] AND upto[q]) -> A
;   bitmap2h_headadv:   n -= the head pixels; step g2h_a to the whole bytes
;   bitmap2h_quadcount: g2h_m = n >> 2 whole bytes; Z set when there are none
;   bitmap2h_a_addm:    g2h_a += m (skip what vera_fill / the pair loop wrote)
;   bitmap2h_tailmask:  the pixels 0..n-1 tail mask -> A; Z set when no tail
bitmap2h_headmask
    lda g2h_n+1                  ; q = last head pixel = min(3, p+n-1)
    bne bitmap2h_hmqmax                 ; a long span always reaches pixel 3
    clc
    lda g2h_p
    adc g2h_n
    bcs bitmap2h_hmqmax                 ; p + n carried: certainly past pixel 3
    dec a
    cmp #4
    bcc bitmap2h_hmqgot
bitmap2h_hmqmax
    lda #3
bitmap2h_hmqgot
    tay                         ; Y = q
    sec                         ; head pixel count = q - p + 1
    iny
    tya
    sbc g2h_p
    sta g2h_t
    ldx g2h_p
    lda bitmap2h_from,x
    dey
    and bitmap2h_upto,y
    rts

bitmap2h_headadv
    sec                         ; n -= head pixels
    lda g2h_n
    sbc g2h_t
    sta g2h_n
    lda g2h_n+1
    sbc #0
    sta g2h_n+1
    jmp bitmap2h_a_inc                  ; step to the first whole byte

bitmap2h_quadcount
    lda g2h_n+1
    sta g2h_m+1
    lda g2h_n
    lsr g2h_m+1
    ror
    lsr g2h_m+1
    ror
    sta g2h_m
    ora g2h_m+1
    rts

bitmap2h_a_addm
    clc
    lda g2h_a0
    adc g2h_m
    sta g2h_a0
    lda g2h_a1
    adc g2h_m+1
    sta g2h_a1
    lda g2h_a2
    adc #0
    sta g2h_a2
    rts

bitmap2h_tailmask
    lda g2h_n
    and #3
    beq bitmap2h_tmnone
    tay
    dey                         ; tail covers pixels 0..n-1
    lda bitmap2h_upto,y                 ; never zero, so Z stays clear
bitmap2h_tmnone
    rts

; read-modify-write the byte at g2h_a through a pixel mask:
; fb' = (fb AND NOT mask) OR (ink AND mask). INC_0 keeps the port in
; place, so one aim serves both the read and the write.
;   bitmap2h_rmw:  A = mask, ink is the solid colour byte g2h_cb
;   bitmap2h_rmwp: A = ink byte, X = mask (the pattern-row variant)
bitmap2h_rmw
    tax
    lda g2h_cb
bitmap2h_rmwp
    sta g2h_ink
    stx g2h_msk
    lda #VERA_INC_0
    jsr bitmap2h_aim0
    lda g2h_msk
    eor #$FF
    and VERA_DATA0
    sta g2h_t2
    lda g2h_ink
    and g2h_msk
    ora g2h_t2
    sta VERA_DATA0
    rts

; g2h_a += 1 (24-bit)
bitmap2h_a_inc
    inc g2h_a0
    bne _ai_done
    inc g2h_a1
    bne _ai_done
    inc g2h_a2
_ai_done
    rts

; g2h_a += one framebuffer row
bitmap2h_a_row
    clc
    lda g2h_a0
    adc #GFX2H_STRIDE
    sta g2h_a0
    lda g2h_a1
    adc #0
    sta g2h_a1
    lda g2h_a2
    adc #0
    sta g2h_a2
    rts

; ---------------------------------------------------------------------
; module variables (never live across a call boundary)
; ---------------------------------------------------------------------
g2h_a0  .byte 0
g2h_a1  .byte 0
g2h_a2  .byte 0
g2h_c   .byte 0
g2h_cb  .byte 0
g2h_p   .byte 0
g2h_n   .word 0
g2h_m   .word 0
g2h_t   .byte 0
g2h_t2  .byte 0
g2h_inc .byte 0
g2h_msk .byte 0
g2h_ink .byte 0
g2h_op  .byte 0
g2h_h   .byte 0
g2h_w   .byte 0

; g2h_fx..g2h_rh are laid out in X16_P0..P7 order so gfx2h_frame can take
; and restore the block with a loop
g2h_fx  .word 0
g2h_fy  .word 0
g2h_rw  .word 0
g2h_rh  .word 0
g2h_rc  .byte 0

g2h_pfg .byte 0
g2h_pbg .byte 0
g2h_pr  .byte 0
g2h_pb0 .byte 0
g2h_pb1 .byte 0
g2h_pat .fill 16, 0

g2h_lc   .byte 0
g2h_lx0  .word 0
g2h_ly0  .word 0
g2h_lx1  .word 0
g2h_ly1  .word 0
g2h_ldx  .word 0
g2h_ldy  .word 0
g2h_lerr .word 0
g2h_le2  .word 0
g2h_lsx  .word 0
g2h_lsy  .word 0
g2h_lt   .word 0

bitmap2h_colbyte
    .byte $00, $55, $AA, $FF   ; a colour in all four pixels
bitmap2h_pix
    .byte $C0, $30, $0C, $03   ; the bits of pixel 0..3
bitmap2h_keep
    .byte $3F, $CF, $F3, $FC   ; everything but pixel 0..3
bitmap2h_from
    .byte $FF, $3F, $0F, $03   ; pixels p..3
bitmap2h_upto
    .byte $C0, $F0, $FC, $FF   ; pixels 0..q
bitmap2h_g2h_optab
    .byte $11, $31, $51        ; ora/and/eor (zp),y, for gfx2h_blit

; (end zone)
.endif
.if xuse_bitmap2l
; --- inline gfx/bitmap2l.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/bitmap2l.asm -- 320x240x4 bitmap drawing (2bpp)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; Requires X16_USE_VERA (vera_fill) and X16_USE_VERAFX (fx_fill).
;
; The framebuffer is 2bpp at VRAM $00000: 4 pixels per byte packed
; MSB-first (the leftmost pixel is bits 7:6), rows of 80 bytes,
; 19,200 bytes in all. A pixel byte is at y*80 + (x>>2); its position
; within the byte is x & 3. VERA renders it as layer-0 bitmap, 2bpp,
; 320 wide, HSCALE = VSCALE = $80 -- gfx2l_init programs exactly that
; (there is no KERNAL screen mode for it).
;
; Colours are 0-3 out of the first four palette entries. gfx2l_init
; loads a paper-and-ink default: 0 white, 1 light gray, 2 dark gray,
; 3 black. pal_set/pal_load re-colour without touching the pixels.
;
; gfx2l_pset and gfx2l_read clip. The span/rect/line/blit primitives do
; NOT: they assume their arguments are on screen (the 8bpp module's
; policy, for the same reason -- a caller that knows its geometry
; should not pay for a clip on every span).
;
; Sub-byte pixels make 2bpp spans three-phase: a partial head byte, a
; run of whole bytes, a partial tail byte. The partial bytes are
; read-modify-write through data port 0 with INC_0; the middle run is
; a plain vera_fill. Column walks (vline, blitm) pair port 1 (read)
; with port 0 (write), both stepping VERA_INC_80.
; =====================================================================

; (zone: file scope in 64tass)

GFX2L_WIDTH  = 320
GFX2L_HEIGHT = 240
GFX2L_STRIDE = 80

; ---------------------------------------------------------------------
; gfx2l_init -- program the 320x240@2bpp mode on bare VERA registers.
;
; Layer 0 becomes the bitmap and is enabled; layer 1 (the text screen,
; which would overlay garbage) is disabled; sprites are left as the
; caller had them. Palette entries 0-3 get the default ramp. The
; framebuffer contents are NOT cleared -- call gfx2l_clear.
; ---------------------------------------------------------------------
.if !X16_BITMAP2L_NO_INIT != 0
gfx2l_init
    #vera_dcsel 0
    lda #$80                    ; 1:1 scale -> 1:1 scale
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    stz VERA_DC_BORDER

    lda #(VERA_LAYER_BITMAP | VERA_LAYER_BPP_2)
    sta VERA_L0_CONFIG
    lda #$00                    ; bitmap base $00000, 320 pixels wide
    sta VERA_L0_TILEBASE
    stz VERA_L0_HSCROLL_L
    stz VERA_L0_HSCROLL_H       ; bits 3:0 = bitmap palette offset
    stz VERA_L0_VSCROLL_L
    stz VERA_L0_VSCROLL_H

    ; palette 0-3: white paper, two grays, black ink
    #vera_addr 0, VRAM_PALETTE, VERA_INC_1
    ldx #0
_pal
    lda bitmap2l_defpal,x
    sta VERA_DATA0
    inx
    cpx #8
    bne _pal

    lda #VERA_VIDEO_LAYER1_EN   ; layer 1 off, layer 0 on
    trb VERA_DC_VIDEO
    lda #VERA_VIDEO_LAYER0_EN
    tsb VERA_DC_VIDEO
    rts
.endif

bitmap2l_defpal
    .byte $FF, $0F, $AA, $0A, $55, $05, $00, $00

; ---------------------------------------------------------------------
; gfx2l_clear -- fill the whole framebuffer with one colour
;   in:  A = colour (0-3)
;
; Uses the FX 32-bit cache write (~4x a CPU byte loop; measured 1.25
; frames per full screen against 5.25). Clobbers X16_P0..P4.
; ---------------------------------------------------------------------
gfx2l_clear
    and #3
    tax
    lda bitmap2l_colbyte,x
    pha
    stz X16_P0                  ; first half: $00000, 9,600 bytes
    stz X16_P1
    stz X16_P2
    lda #<(GFX2L_STRIDE * GFX2L_HEIGHT / 2)
    sta X16_P3
    lda #>(GFX2L_STRIDE * GFX2L_HEIGHT / 2)
    sta X16_P4
    pla
    pha
    jsr fx_fill
    lda #<(GFX2L_STRIDE * GFX2L_HEIGHT / 2)
    sta X16_P0                  ; second half starts at $02580
    sta X16_P3
    lda #>(GFX2L_STRIDE * GFX2L_HEIGHT / 2)
    sta X16_P1
    sta X16_P4
    stz X16_P2
    pla
    jmp fx_fill

; ---------------------------------------------------------------------
; gfx2l_setptr -- point data port 0 at the byte holding pixel (x,y)
;   in:  A = increment index (VERA_INC_*)
;        X16_P0/P1 = x, X16_P2/P3 = y
;   out: A = x & 3 (the pixel's position within the byte)
;
; y*80 = (y<<4) + (y<<4)<<2, so no multiply is needed; the result is
; 17-bit. Stepping by VERA_INC_80 then walks straight down a column.
; ---------------------------------------------------------------------
gfx2l_setptr
    pha
    jsr bitmap2l_addr_calc
    pla
    jsr bitmap2l_aim0
    lda X16_P0
    and #3
    rts

; ---------------------------------------------------------------------
; gfx2l_pset -- set one pixel, clipped
;   in:  A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y
; ---------------------------------------------------------------------
gfx2l_pset
    and #3
    sta g2l_c
    jsr bitmap2l_onscreen
    bcs _off

    jsr bitmap2l_addr_calc
    lda #VERA_INC_0
    jsr bitmap2l_aim0

    lda X16_P0
    and #3
    tax
    lda VERA_DATA0              ; INC_0: the read does not move the port
    and bitmap2l_keep,x
    sta g2l_t
    ldy g2l_c
    lda bitmap2l_colbyte,y
    and bitmap2l_pix,x
    ora g2l_t
    sta VERA_DATA0
_off
    rts

; ---------------------------------------------------------------------
; gfx2l_read -- read one pixel
;   in:  X16_P0/P1 = x, X16_P2/P3 = y
;   out: carry clear, A = colour (0-3); carry set if (x,y) is off
;        screen (A undefined)
; ---------------------------------------------------------------------
gfx2l_read
    jsr bitmap2l_onscreen
    bcs _roff

    jsr bitmap2l_addr_calc
    lda #VERA_INC_0
    jsr bitmap2l_aim0

    lda X16_P0
    and #3
    tax
    lda VERA_DATA0
_shift
    cpx #3                      ; pixel 3 sits in bits 1:0 already
    beq _done
    lsr
    lsr
    inx
    bra _shift
_done
    and #3
    clc
_roff
    rts

; ---------------------------------------------------------------------
; gfx2l_hline -- horizontal span (no clipping)
;   in:  A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y,
;        X16_P4/P5 = length in pixels
;
; Head and tail partials are read-modify-write; the middle whole bytes
; are one vera_fill.
; ---------------------------------------------------------------------
gfx2l_hline
    and #3
    tax
    lda bitmap2l_colbyte,x
    sta g2l_cb

    lda X16_P4
    sta g2l_n
    ora X16_P5
    bne _hgo                    ; zero length: nothing to draw
    rts
_hgo
    lda X16_P5
    sta g2l_n+1

    jsr bitmap2l_addr_calc

    lda X16_P0
    and #3
    sta g2l_p                    ; phase = x & 3
    bne _head
    ; phase 0: a head byte only exists when the span is shorter than
    ; one whole byte
    lda g2l_n+1
    bne _middle
    lda g2l_n
    cmp #4
    bcs _middle

_head
    jsr bitmap2l_headmask               ; mask -> A, head pixel count -> g2l_t
    jsr bitmap2l_rmw                    ; ink = colour byte through this mask
    jsr bitmap2l_headadv                ; n -= head pixels, on to the whole bytes

_middle
    jsr bitmap2l_quadcount              ; m = n >> 2 whole bytes
    beq _tail

    lda #VERA_INC_1
    jsr bitmap2l_aim0
    lda g2l_cb
    ldx g2l_m
    ldy g2l_m+1
    jsr vera_fill               ; clobbers X16_T0..T2, not g2l_*
    jsr bitmap2l_a_addm                 ; addr += m

_tail
    jsr bitmap2l_tailmask
    beq _hdone
    jsr bitmap2l_rmw
_hdone
    rts

; ---------------------------------------------------------------------
; gfx2l_vline -- vertical span (no clipping)
;   in:  A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y,
;        X16_P4/P5 = length in pixels
;
; One column of read-modify-writes: port 1 reads, port 0 writes, both
; stepping a whole row per access.
; ---------------------------------------------------------------------
gfx2l_vline
    and #3
    tax
    lda bitmap2l_colbyte,x
    sta g2l_cb

    lda X16_P4
    sta g2l_n
    ora X16_P5
    beq _vdone
    lda X16_P5
    sta g2l_n+1

    jsr bitmap2l_addr_calc
    lda #VERA_INC_80
    jsr bitmap2l_aim1
    lda #VERA_INC_80
    jsr bitmap2l_aim0

    lda X16_P0
    and #3
    tax
    lda g2l_cb
    and bitmap2l_pix,x
    sta g2l_ink                  ; ink and keep are loop-invariant
    lda bitmap2l_keep,x
    sta g2l_msk

    ldx g2l_n                    ; vera_fill's page-count idiom
    ldy g2l_n+1
    txa
    beq _vfull                  ; low byte 0 -> exactly hi*256 rows
    iny                         ; otherwise one extra partial page
_vfull
_vloop
    lda VERA_DATA1
    and g2l_msk
    ora g2l_ink
    sta VERA_DATA0
    dex
    bne _vloop
    dey
    bne _vloop
_vdone
    rts

; ---------------------------------------------------------------------
; gfx2l_rect -- filled rectangle (no clipping)
;   in:  A = colour (0-3), X16_P0/P1 = x, X16_P2/P3 = y,
;        X16_P4/P5 = width, X16_P6/P7 = height
; ---------------------------------------------------------------------
gfx2l_rect
    sta g2l_rc
    lda X16_P4
    sta g2l_rw
    lda X16_P5
    sta g2l_rw+1
    lda X16_P6
    sta g2l_rh
    lda X16_P7
    sta g2l_rh+1
_rrow
    lda g2l_rh
    ora g2l_rh+1
    beq _rdone
    lda g2l_rw                   ; hline consumes the length: reload
    sta X16_P4
    lda g2l_rw+1
    sta X16_P5
    lda g2l_rc
    jsr gfx2l_hline              ; leaves P0..P3 alone
    inc X16_P2                  ; y += 1
    bne _ry_ok
    inc X16_P3
_ry_ok
    lda g2l_rh
    bne _rh_ok
    dec g2l_rh+1
_rh_ok
    dec g2l_rh
    bra _rrow
_rdone
    rts

; ---------------------------------------------------------------------
; gfx2l_frame -- rectangle outline (no clipping)
;   same arguments as gfx2l_rect
; ---------------------------------------------------------------------
gfx2l_frame
    sta g2l_rc
    ldx #7                      ; private copies: the edges reuse the
_take                           ; parameter block as they go; g2l_fx..
    lda X16_P0,x                ; g2l_rh are laid out in P0..P7 order
    sta g2l_fx,x
    dex
    bpl _take

    jsr bitmap2l_f_span                 ; top edge
    jsr gfx2l_hline

    jsr bitmap2l_f_span                 ; bottom edge: y + h - 1
    clc
    lda g2l_fy
    adc g2l_rh
    sta X16_P2
    lda g2l_fy+1
    adc g2l_rh+1
    sta X16_P3
    lda X16_P2
    bne _f_nb1
    dec X16_P3
_f_nb1
    dec X16_P2
    lda g2l_rc
    jsr gfx2l_hline

    jsr bitmap2l_f_col                  ; left edge
    jsr gfx2l_vline

    jsr bitmap2l_f_col                  ; right edge: x + w - 1
    clc
    lda g2l_fx
    adc g2l_rw
    sta X16_P0
    lda g2l_fx+1
    adc g2l_rw+1
    sta X16_P1
    lda X16_P0
    bne _f_nb2
    dec X16_P1
_f_nb2
    dec X16_P0
    lda g2l_rc
    jmp gfx2l_vline

; x, y, width in the block, colour in A -- arguments for gfx2l_hline
bitmap2l_f_span
    ldx #5
bitmap2l_fsp_l
    lda g2l_fx,x
    sta X16_P0,x
    dex
    bpl bitmap2l_fsp_l
    lda g2l_rc
    rts

; x, y, height in the block, colour in A -- arguments for gfx2l_vline
bitmap2l_f_col
    ldx #3
bitmap2l_fcl_l
    lda g2l_fx,x
    sta X16_P0,x
    dex
    bpl bitmap2l_fcl_l
    lda g2l_rh
    sta X16_P4
    lda g2l_rh+1
    sta X16_P5
    lda g2l_rc
    rts

; ---------------------------------------------------------------------
; gfx2l_line -- Bresenham, any direction; plots through gfx2l_pset so
; the line clips at the screen edges
;   in:  A = colour (0-3)
;        X16_P0/P1 = x0, X16_P2/P3 = y0
;        X16_P4/P5 = x1, X16_P6/P7 = y1
; ---------------------------------------------------------------------
gfx2l_line
    sta g2l_lc
    ldx #7                      ; P0..P7 -> g2l_lx0..g2l_ly1, which are
_take                           ; laid out in the same order
    lda X16_P0,x
    sta g2l_lx0,x
    dex
    bpl _take

    ; dx = |x1 - x0|, sx = sign
    sec
    lda g2l_lx1
    sbc g2l_lx0
    sta g2l_ldx
    lda g2l_lx1+1
    sbc g2l_lx0+1
    sta g2l_ldx+1
    bpl _dx_pos
    sec
    lda #0
    sbc g2l_ldx
    sta g2l_ldx
    lda #0
    sbc g2l_ldx+1
    sta g2l_ldx+1
    lda #$FF
    sta g2l_lsx
    sta g2l_lsx+1
    bra _dx_done
_dx_pos
    lda #$01
    sta g2l_lsx
    stz g2l_lsx+1
_dx_done

    ; dy = -|y1 - y0|, sy = sign
    sec
    lda g2l_ly1
    sbc g2l_ly0
    sta g2l_lt
    lda g2l_ly1+1
    sbc g2l_ly0+1
    sta g2l_lt+1
    bpl _dy_pos
    sec
    lda #0
    sbc g2l_lt
    sta g2l_lt
    lda #0
    sbc g2l_lt+1
    sta g2l_lt+1
    lda #$FF
    sta g2l_lsy
    sta g2l_lsy+1
    bra _dy_done
_dy_pos
    lda #$01
    sta g2l_lsy
    stz g2l_lsy+1
_dy_done
    sec                         ; g2l_ldy = -|dy|
    lda #0
    sbc g2l_lt
    sta g2l_ldy
    lda #0
    sbc g2l_lt+1
    sta g2l_ldy+1

    clc                         ; err = dx + dy
    lda g2l_ldx
    adc g2l_ldy
    sta g2l_lerr
    lda g2l_ldx+1
    adc g2l_ldy+1
    sta g2l_lerr+1

_loop
    lda g2l_lx0                  ; plot (x0, y0)
    sta X16_P0
    lda g2l_lx0+1
    sta X16_P1
    lda g2l_ly0
    sta X16_P2
    lda g2l_ly0+1
    sta X16_P3
    lda g2l_lc
    jsr gfx2l_pset

    lda g2l_lx0                  ; reached the end point?
    cmp g2l_lx1
    bne _step
    lda g2l_lx0+1
    cmp g2l_lx1+1
    bne _step
    lda g2l_ly0
    cmp g2l_ly1
    bne _step
    lda g2l_ly0+1
    cmp g2l_ly1+1
    bne _step
    rts

_step
    lda g2l_lerr                 ; e2 = err * 2
    asl
    sta g2l_le2
    lda g2l_lerr+1
    rol
    sta g2l_le2+1

    ; if e2 >= dy  ->  err += dy, x0 += sx
    sec
    lda g2l_le2
    sbc g2l_ldy
    lda g2l_le2+1
    sbc g2l_ldy+1
    bvc _nv1
    eor #$80                    ; signed compare: fold overflow into sign
_nv1
    bmi _skip_x
    clc
    lda g2l_lerr
    adc g2l_ldy
    sta g2l_lerr
    lda g2l_lerr+1
    adc g2l_ldy+1
    sta g2l_lerr+1
    clc
    lda g2l_lx0
    adc g2l_lsx
    sta g2l_lx0
    lda g2l_lx0+1
    adc g2l_lsx+1
    sta g2l_lx0+1
_skip_x

    ; if e2 <= dx  ->  err += dx, y0 += sy
    sec
    lda g2l_ldx
    sbc g2l_le2
    lda g2l_ldx+1
    sbc g2l_le2+1
    bvc _nv2
    eor #$80
_nv2
    bmi _skip_y
    clc
    lda g2l_lerr
    adc g2l_ldx
    sta g2l_lerr
    lda g2l_lerr+1
    adc g2l_ldx+1
    sta g2l_lerr+1
    clc
    lda g2l_ly0
    adc g2l_lsy
    sta g2l_ly0
    lda g2l_ly0+1
    adc g2l_lsy+1
    sta g2l_ly0+1
_skip_y
    jmp _loop

; ---------------------------------------------------------------------
; gfx2l_pattern_set -- expand an 8x8 1bpp pattern for gfx2l_pattern_rect
;   in:  A = pattern low, X = pattern high (8 row bytes, top first;
;            bit 7 is the leftmost pixel)
;        Y = colours: (background << 2) | foreground
;
; Patterns tile from the screen origin, so each row expands to exactly
; two 2bpp bytes (16 bits); which of the pair a framebuffer byte uses
; is the parity of its address. The expansion is cached in g2l_pat.
; ---------------------------------------------------------------------
gfx2l_pattern_set
    sta X16_T6                  ; T6/T7 = pattern pointer
    stx X16_T7
    tya
    and #3
    tax
    lda bitmap2l_colbyte,x              ; replicated foreground
    sta g2l_pfg
    tya
    lsr
    lsr
    and #3
    tax
    lda bitmap2l_colbyte,x              ; replicated background
    sta g2l_pbg

    ldx #0                      ; cache index (2 bytes per row)
    ldy #0                      ; pattern row
_prow
    sty g2l_t
    lda (X16_T6),y
    sta g2l_pr                   ; the row's 8 bits, consumed by asl
    jsr bitmap2l_p_half                 ; pixels 0-3 -> even byte
    sta g2l_pat,x
    inx
    jsr bitmap2l_p_half                 ; pixels 4-7 -> odd byte
    sta g2l_pat,x
    inx
    ldy g2l_t
    iny
    cpy #8
    bne _prow
    rts

; expand the next 4 bits of g2l_pr (MSB first) into one 2bpp byte:
; a set bit becomes the foreground colour, a clear one the background
bitmap2l_p_half
    stz g2l_t2
    ldy #0                      ; pixel 0..3 within the byte
_pbit
    asl g2l_pr
    bcs _pfg
    lda g2l_pbg
    bra _pmix
_pfg
    lda g2l_pfg
_pmix
    and bitmap2l_pix,y                  ; keep just this pixel's two bits
    ora g2l_t2
    sta g2l_t2
    iny
    cpy #4
    bne _pbit
    lda g2l_t2
    rts

; ---------------------------------------------------------------------
; gfx2l_pattern_rect -- fill a rectangle with the current pattern
;   in:  X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = width,
;        X16_P6/P7 = height   (no clipping)
; ---------------------------------------------------------------------
gfx2l_pattern_rect
    lda X16_P4
    sta g2l_rw
    lda X16_P5
    sta g2l_rw+1
    lda X16_P6
    sta g2l_rh
    lda X16_P7
    sta g2l_rh+1
_yrow
    lda g2l_rh
    ora g2l_rh+1
    beq _ydone
    jsr bitmap2l_p_row
    inc X16_P2
    bne _py_ok
    inc X16_P3
_py_ok
    lda g2l_rh
    bne _ph_ok
    dec g2l_rh+1
_ph_ok
    dec g2l_rh
    bra _yrow
_ydone
    rts

; one pattern row at (P0..P3), width g2l_rw
bitmap2l_p_row
    lda g2l_rw
    sta g2l_n
    ora g2l_rw+1
    bne _prgo
    rts
_prgo
    lda g2l_rw+1
    sta g2l_n+1

    jsr bitmap2l_addr_calc

    ; the row's two pattern bytes, in address-parity order
    lda X16_P2
    and #7
    asl
    tax
    lda g2l_a0
    and #1
    beq _even
    inx                         ; an odd start address uses the odd
    lda g2l_pat,x                ; byte first
    sta g2l_pb0
    dex
    lda g2l_pat,x
    sta g2l_pb1
    bra _parity_done
_even
    lda g2l_pat,x
    sta g2l_pb0
    inx
    lda g2l_pat,x
    sta g2l_pb1
_parity_done

    lda X16_P0
    and #3
    sta g2l_p
    bne _phead
    lda g2l_n+1
    bne _pmiddle
    lda g2l_n
    cmp #4
    bcs _pmiddle

_phead
    jsr bitmap2l_headmask               ; mask -> A, head pixel count -> g2l_t
    tax                         ; mask in X for bitmap2l_rmwp
    lda g2l_pb0
    jsr bitmap2l_rmwp
    jsr bitmap2l_headadv
    lda g2l_pb0                  ; next byte has the other parity
    ldx g2l_pb1
    sta g2l_pb1
    stx g2l_pb0

_pmiddle
    jsr bitmap2l_quadcount
    beq _ptail

    lda #VERA_INC_1
    jsr bitmap2l_aim0
    ldx g2l_m                    ; vera_fill's page-count idiom
    ldy g2l_m+1
    txa
    beq _pfull
    iny
_pfull
_ploop
    lda g2l_pb0
    sta VERA_DATA0
    lda g2l_pb0                  ; swap the parity pair
    pha
    lda g2l_pb1
    sta g2l_pb0
    pla
    sta g2l_pb1
    dex
    bne _ploop
    dey
    bne _ploop
    jsr bitmap2l_a_addm                 ; addr += m

_ptail
    jsr bitmap2l_tailmask
    beq _prdone
    tax
    lda g2l_pb0
    jsr bitmap2l_rmwp
_prdone
    rts

; ---------------------------------------------------------------------
; gfx2l_blit -- copy a byte-aligned image from CPU RAM into the bitmap
;   in:  A = raster op: 0 copy, 1 OR, 2 AND, 3 XOR
;        X16_P0/P1 = x (bits 1:0 ignored: byte-aligned),
;        X16_P2/P3 = y, X16_P4 = width in BYTES (4-pixel units),
;        X16_P5 = height in rows, X16_P6/P7 = source (row-major)
;
; The source pointer is X16_PTR3 -- P6/P7 double as real zero page, so
; (PTR3),y addressing costs nothing extra. No clipping.
; ---------------------------------------------------------------------
; The three RMW ops share one loop whose opcode at bitmap2l_g2l_blit_op is patched
; from bitmap2l_g2l_optab (ora/and/eor (zp),y) -- the 8bpp module's gfx8l_blit
; does the same.
gfx2l_blit
    and #3
    sta g2l_op                   ; copy (op 0) needs no opcode patch
    beq +
    tax
    lda bitmap2l_g2l_optab-1,x
    sta bitmap2l_g2l_blit_op
+   jsr bitmap2l_addr_calc
    lda X16_P5
    sta g2l_h
bitmap2l_g2l_blit_row
    lda #VERA_INC_1
    jsr bitmap2l_aim1                   ; ops read through port 1...
    lda #VERA_INC_1
    jsr bitmap2l_aim0                   ; ...and everything writes port 0
    ldy #0
    lda g2l_op
    beq bitmap2l_g2l_blit_copy
bitmap2l_g2l_blit_rmw
    lda VERA_DATA1
bitmap2l_g2l_blit_op
    ora (X16_PTR3),y            ; opcode patched: op 1/2/3 = ora/and/eor
    sta VERA_DATA0
    iny
    cpy X16_P4
    bne bitmap2l_g2l_blit_rmw
    bra bitmap2l_g2l_blit_done
bitmap2l_g2l_blit_copy
    lda (X16_PTR3),y
    sta VERA_DATA0
    iny
    cpy X16_P4
    bne bitmap2l_g2l_blit_copy
bitmap2l_g2l_blit_done
    clc                         ; src += width
    lda X16_PTR3
    adc X16_P4
    sta X16_PTR3
    bcc +
    inc X16_PTR3+1
+   jsr bitmap2l_a_row                  ; dest += one row
    dec g2l_h
    bne bitmap2l_g2l_blit_row
    rts

; ---------------------------------------------------------------------
; gfx2l_blitm -- masked blit of pre-shifted column-major data
;   in:  X16_P0/P1 = x (any pixel position), X16_P2/P3 = y,
;        X16_P4 = height in rows (1-127), X16_P5 = width in COLUMNS
;        (framebuffer bytes), X16_P6/P7 = source
;
; The source holds, for each of the P5 columns, P4 (mask, data) byte
; PAIRS walking down the rows: fb' = (fb AND mask) OR data. The caller
; supplies data already shifted for this x's pixel phase (x & 3) --
; pre-shifted glyph caches are the whole point: at 833 cycles per 8x8
; glyph this is what makes proportional text affordable (spike-proven;
; see the CXRF project). No clipping.
; ---------------------------------------------------------------------
gfx2l_blitm
    jsr bitmap2l_addr_calc
    lda X16_P5
    sta g2l_w
_mcol
    lda #VERA_INC_80
    jsr bitmap2l_aim1
    lda #VERA_INC_80
    jsr bitmap2l_aim0
    ldy #0
    ldx X16_P4
_mrow
    lda VERA_DATA1
    and (X16_PTR3),y            ; mask byte
    iny
    ora (X16_PTR3),y            ; data byte
    iny
    sta VERA_DATA0
    dex
    bne _mrow

    clc                         ; src += 2 * height (one column)
    tya
    adc X16_PTR3
    sta X16_PTR3
    bcc _msrc_ok
    inc X16_PTR3+1
_msrc_ok
    jsr bitmap2l_a_inc                  ; dest: next byte column
    dec g2l_w
    bne _mcol
    rts

; ---------------------------------------------------------------------
; module plumbing
; ---------------------------------------------------------------------

; carry clear if (P0/P1, P2/P3) is on screen
bitmap2l_onscreen
    lda X16_P1                  ; x < 320?
    cmp #>GFX2L_WIDTH
    bcc _x_ok
    bne _bad
    lda X16_P0
    cmp #<GFX2L_WIDTH
    bcs _bad
_x_ok
    lda X16_P3                  ; y < 240?
    cmp #>GFX2L_HEIGHT
    bcc _ok
    bne _bad
    lda X16_P2
    cmp #<GFX2L_HEIGHT
    bcs _bad
_ok
    clc
    rts
_bad
    sec
    rts

; g2l_a2:a1:a0 = y*80 + (x>>2)   (from X16_P0..P3; clobbers T0..T2)
bitmap2l_addr_calc
    lda X16_P2                  ; t = y << 4
    sta g2l_a0
    lda X16_P3
    sta g2l_a1
    asl g2l_a0
    rol g2l_a1
    asl g2l_a0
    rol g2l_a1
    asl g2l_a0
    rol g2l_a1
    asl g2l_a0
    rol g2l_a1

    lda g2l_a0                   ; T2:T1:T0 = t << 2
    sta X16_T0
    lda g2l_a1
    sta X16_T1
    stz X16_T2
    asl X16_T0
    rol X16_T1
    rol X16_T2
    asl X16_T0
    rol X16_T1
    rol X16_T2

    clc                         ; y*80 = t + (t << 2)
    lda g2l_a0
    adc X16_T0
    sta g2l_a0
    lda g2l_a1
    adc X16_T1
    sta g2l_a1
    lda #0
    adc X16_T2
    sta g2l_a2

    lda X16_P1                  ; + x >> 2
    sta X16_T1
    lda X16_P0
    lsr X16_T1
    ror
    lsr X16_T1
    ror
    clc
    adc g2l_a0
    sta g2l_a0
    lda X16_T1
    adc g2l_a1
    sta g2l_a1
    lda #0
    adc g2l_a2
    sta g2l_a2
    rts

; point port 0 (write side) at g2l_a; A = increment index.
; Scratch is g2l_inc, NOT g2l_t: hline/pattern hold a pixel count in
; g2l_t across the bitmap2l_rmw call, and bitmap2l_rmw aims through here.
bitmap2l_aim0
    asl
    asl
    asl
    asl
    sta g2l_inc
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    bra bitmap2l_aimgo

; point port 1 (read side) at g2l_a; A = increment index
bitmap2l_aim1
    asl
    asl
    asl
    asl
    sta g2l_inc
    lda #VERA_CTRL_ADDRSEL
    tsb VERA_CTRL
bitmap2l_aimgo
    lda g2l_a0
    sta VERA_ADDR_L
    lda g2l_a1
    sta VERA_ADDR_M
    lda g2l_a2
    and #VERA_ADDR_H_BANK
    ora g2l_inc
    sta VERA_ADDR_H
    rts

; the three-phase span geometry, shared by gfx2l_hline and bitmap2l_p_row:
;   bitmap2l_headmask:  from phase g2l_p and count g2l_n, the head pixel count
;               -> g2l_t and the pixel mask (from[p] AND upto[q]) -> A
;   bitmap2l_headadv:   n -= the head pixels; step g2l_a to the whole bytes
;   bitmap2l_quadcount: g2l_m = n >> 2 whole bytes; Z set when there are none
;   bitmap2l_a_addm:    g2l_a += m (skip what vera_fill / the pair loop wrote)
;   bitmap2l_tailmask:  the pixels 0..n-1 tail mask -> A; Z set when no tail
bitmap2l_headmask
    lda g2l_n+1                  ; q = last head pixel = min(3, p+n-1)
    bne bitmap2l_hmqmax                 ; a long span always reaches pixel 3
    clc
    lda g2l_p
    adc g2l_n
    bcs bitmap2l_hmqmax                 ; p + n carried: certainly past pixel 3
    dec a
    cmp #4
    bcc bitmap2l_hmqgot
bitmap2l_hmqmax
    lda #3
bitmap2l_hmqgot
    tay                         ; Y = q
    sec                         ; head pixel count = q - p + 1
    iny
    tya
    sbc g2l_p
    sta g2l_t
    ldx g2l_p
    lda bitmap2l_from,x
    dey
    and bitmap2l_upto,y
    rts

bitmap2l_headadv
    sec                         ; n -= head pixels
    lda g2l_n
    sbc g2l_t
    sta g2l_n
    lda g2l_n+1
    sbc #0
    sta g2l_n+1
    jmp bitmap2l_a_inc                  ; step to the first whole byte

bitmap2l_quadcount
    lda g2l_n+1
    sta g2l_m+1
    lda g2l_n
    lsr g2l_m+1
    ror
    lsr g2l_m+1
    ror
    sta g2l_m
    ora g2l_m+1
    rts

bitmap2l_a_addm
    clc
    lda g2l_a0
    adc g2l_m
    sta g2l_a0
    lda g2l_a1
    adc g2l_m+1
    sta g2l_a1
    lda g2l_a2
    adc #0
    sta g2l_a2
    rts

bitmap2l_tailmask
    lda g2l_n
    and #3
    beq bitmap2l_tmnone
    tay
    dey                         ; tail covers pixels 0..n-1
    lda bitmap2l_upto,y                 ; never zero, so Z stays clear
bitmap2l_tmnone
    rts

; read-modify-write the byte at g2l_a through a pixel mask:
; fb' = (fb AND NOT mask) OR (ink AND mask). INC_0 keeps the port in
; place, so one aim serves both the read and the write.
;   bitmap2l_rmw:  A = mask, ink is the solid colour byte g2l_cb
;   bitmap2l_rmwp: A = ink byte, X = mask (the pattern-row variant)
bitmap2l_rmw
    tax
    lda g2l_cb
bitmap2l_rmwp
    sta g2l_ink
    stx g2l_msk
    lda #VERA_INC_0
    jsr bitmap2l_aim0
    lda g2l_msk
    eor #$FF
    and VERA_DATA0
    sta g2l_t2
    lda g2l_ink
    and g2l_msk
    ora g2l_t2
    sta VERA_DATA0
    rts

; g2l_a += 1 (24-bit)
bitmap2l_a_inc
    inc g2l_a0
    bne _ai_done
    inc g2l_a1
    bne _ai_done
    inc g2l_a2
_ai_done
    rts

; g2l_a += one framebuffer row
bitmap2l_a_row
    clc
    lda g2l_a0
    adc #GFX2L_STRIDE
    sta g2l_a0
    lda g2l_a1
    adc #0
    sta g2l_a1
    lda g2l_a2
    adc #0
    sta g2l_a2
    rts

; ---------------------------------------------------------------------
; module variables (never live across a call boundary)
; ---------------------------------------------------------------------
g2l_a0  .byte 0
g2l_a1  .byte 0
g2l_a2  .byte 0
g2l_c   .byte 0
g2l_cb  .byte 0
g2l_p   .byte 0
g2l_n   .word 0
g2l_m   .word 0
g2l_t   .byte 0
g2l_t2  .byte 0
g2l_inc .byte 0
g2l_msk .byte 0
g2l_ink .byte 0
g2l_op  .byte 0
g2l_h   .byte 0
g2l_w   .byte 0

; g2l_fx..g2l_rh are laid out in X16_P0..P7 order so gfx2l_frame can take
; and restore the block with a loop
g2l_fx  .word 0
g2l_fy  .word 0
g2l_rw  .word 0
g2l_rh  .word 0
g2l_rc  .byte 0

g2l_pfg .byte 0
g2l_pbg .byte 0
g2l_pr  .byte 0
g2l_pb0 .byte 0
g2l_pb1 .byte 0
g2l_pat .fill 16, 0

g2l_lc   .byte 0
g2l_lx0  .word 0
g2l_ly0  .word 0
g2l_lx1  .word 0
g2l_ly1  .word 0
g2l_ldx  .word 0
g2l_ldy  .word 0
g2l_lerr .word 0
g2l_le2  .word 0
g2l_lsx  .word 0
g2l_lsy  .word 0
g2l_lt   .word 0

bitmap2l_colbyte
    .byte $00, $55, $AA, $FF   ; a colour in all four pixels
bitmap2l_pix
    .byte $C0, $30, $0C, $03   ; the bits of pixel 0..3
bitmap2l_keep
    .byte $3F, $CF, $F3, $FC   ; everything but pixel 0..3
bitmap2l_from
    .byte $FF, $3F, $0F, $03   ; pixels p..3
bitmap2l_upto
    .byte $C0, $F0, $FC, $FF   ; pixels 0..q
bitmap2l_g2l_optab
    .byte $11, $31, $51        ; ora/and/eor (zp),y, for gfx2l_blit

; (end zone)
.endif
.if xuse_bitmap4l
; --- inline gfx/bitmap4l.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/bitmap4l.asm -- 320x240x16 bitmap drawing
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; Requires X16_USE_VERA (uses vera_fill).
;
; The framebuffer is 4bpp at VRAM $00000: 2 pixels per byte packed
; MSB-first (the leftmost pixel is bits 7:4), rows of 160 bytes,
; 38,400 bytes in all. A pixel byte is at y*160 + (x>>1); the left
; pixel is the high nibble, the right pixel is the low nibble.
;
; gfx4l_pset and gfx4l_read clip. The span/rect/line primitives do NOT:
; they assume their arguments are on screen. Clipping every span would
; cost more than it saves for a caller that already knows its geometry.
;
; Nothing here changes the screen mode. Call gfx4l_init once to switch
; the display to 320x240@4bpp; the drawing routines only touch VRAM.
; =====================================================================

; (zone: file scope in 64tass)

GFX4L_WIDTH  = 320
GFX4L_HEIGHT = 240
GFX4L_STRIDE = 160

; ---------------------------------------------------------------------
; gfx4l_init -- program 320x240@4bpp on bare VERA registers.
; ---------------------------------------------------------------------
.if !X16_BITMAP4L_NO_INIT != 0
gfx4l_init
    #vera_dcsel 0
    lda #$80
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    stz VERA_DC_BORDER

    lda #(VERA_LAYER_BITMAP | VERA_LAYER_BPP_4)
    sta VERA_L0_CONFIG
    lda #$01
    sta VERA_L0_TILEBASE
    stz VERA_L0_HSCROLL_L
    stz VERA_L0_HSCROLL_H
    stz VERA_L0_VSCROLL_L
    stz VERA_L0_VSCROLL_H

    ; Default palette entries 0-15: a simple grayscale ramp.
    #vera_addr 0, VRAM_PALETTE, VERA_INC_1
    ldx #0
_pal
    lda bitmap4l_defpal,x
    sta VERA_DATA0
    inx
    cpx #32
    bne _pal

    lda #VERA_VIDEO_LAYER1_EN   ; layer 1 off, layer 0 on
    trb VERA_DC_VIDEO
    lda #VERA_VIDEO_LAYER0_EN
    tsb VERA_DC_VIDEO
    rts
.endif

; ---------------------------------------------------------------------
; gfx4l_clear -- fill the whole framebuffer with one colour
;   in:  A = colour (0-15)
; ---------------------------------------------------------------------
gfx4l_clear
    and #$0F
    tay
    lda bitmap4l_colbyte,y
    pha
    #vera_addr 0, VRAM_BITMAP, VERA_INC_1
    pla
    ldx #<(GFX4L_STRIDE * GFX4L_HEIGHT)
    ldy #>(GFX4L_STRIDE * GFX4L_HEIGHT)
    jmp vera_fill

; ---------------------------------------------------------------------
; gfx4l_setptr -- point data port 0 at the byte holding pixel (x,y)
;   in:  A = increment index (VERA_INC_*)
;        X16_P0/P1 = x, X16_P2 = y
; ---------------------------------------------------------------------
gfx4l_setptr
    asl
    asl
    asl
    asl
    sta X16_T5                  ; increment field, pre-shifted

    lda X16_P2                  ; y << 5
    stz X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    sta X16_T4                  ; T4:T3 = y*32

    lda X16_T4                  ; T2:T1:T0 = y*128
    sta X16_T0
    lda X16_T3
    sta X16_T1
    stz X16_T2
    asl X16_T0
    rol X16_T1
    rol X16_T2
    asl X16_T0
    rol X16_T1
    rol X16_T2

    clc                         ; y*160 = y*32 + y*128
    lda X16_T4
    adc X16_T0
    sta X16_T0
    lda X16_T3
    adc X16_T1
    sta X16_T1
    lda #0
    adc X16_T2
    sta X16_T2

    lda X16_P1                  ; + x >> 1
    lsr
    sta X16_T4
    lda X16_P0
    ror
    sta X16_T3
    clc
    lda X16_T0
    adc X16_T3
    sta X16_T0
    lda X16_T1
    adc X16_T4
    sta X16_T1
    lda X16_T2
    adc #0
    sta X16_T2

    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda X16_T2
    and #VERA_ADDR_H_BANK
    ora X16_T5
    sta VERA_ADDR_H
    rts

; ---------------------------------------------------------------------
; gfx4l_pset -- set one pixel, clipped
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour
; ---------------------------------------------------------------------
gfx4l_pset
    lda X16_P2
    cmp #GFX4L_HEIGHT
    bcs _off

    lda X16_P1
    beq _on
    cmp #1
    bne _off
    lda X16_P0
    cmp #<GFX4L_WIDTH
    bcs _off
_on
    lda #VERA_INC_0
    jsr gfx4l_setptr
    lda VERA_DATA0
    sta g4l_t
    lda X16_P0
    and #1
    beq _even
    lda g4l_t
    and #$F0
    sta g4l_t
    lda X16_P3
    and #$0F
    ora g4l_t
    sta VERA_DATA0
    rts
_even
    lda g4l_t
    and #$0F
    sta g4l_t
    lda X16_P3
    and #$0F
    asl
    asl
    asl
    asl
    ora g4l_t
    sta VERA_DATA0
    rts
_off
    rts

; ---------------------------------------------------------------------
; gfx4l_read -- read one pixel
;   in:  X16_P0/P1 = x, X16_P2 = y
;   out: A = the colour
; ---------------------------------------------------------------------
gfx4l_read
    lda X16_P2
    cmp #GFX4L_HEIGHT
    bcs _off

    lda X16_P1
    beq _on
    cmp #1
    bne _off
    lda X16_P0
    cmp #<GFX4L_WIDTH
    bcs _off
_on
    lda #VERA_INC_0
    jsr gfx4l_setptr
    lda VERA_DATA0
    sta g4l_t
    lda X16_P0
    and #1
    beq _even
    lda g4l_t
    and #$0F
    rts
_even
    lda g4l_t
    and #$F0
    lsr
    lsr
    lsr
    lsr
    rts
_off
    rts

; ---------------------------------------------------------------------
; gfx4l_hline -- horizontal span (no clipping)
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;        X16_P4/P5 = length in pixels
; ---------------------------------------------------------------------
gfx4l_hline
    lda X16_P4
    sta g4l_n
    lda X16_P5
    sta g4l_n+1
    ora g4l_n
    beq _done
_gh4l_loop
    jsr gfx4l_pset
    inc X16_P0
    bne _nextx
    inc X16_P1
_nextx
    sec
    lda g4l_n
    sbc #1
    sta g4l_n
    lda g4l_n+1
    sbc #0
    sta g4l_n+1
    ora g4l_n
    bne _gh4l_loop
_done
    rts

; ---------------------------------------------------------------------
; gfx4l_vline -- vertical span (no clipping)
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;        X16_P4 = length (1-255)
; ---------------------------------------------------------------------
gfx4l_vline
    lda X16_P4
    beq _done
_gv4l_loop
    jsr gfx4l_pset
    inc X16_P2
    dec X16_P4
    bne _gv4l_loop
_done
    rts

; ---------------------------------------------------------------------
; gfx4l_rect -- filled rectangle
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P3 = colour,
;        X16_P4/P5 = width, X16_P6 = height
; ---------------------------------------------------------------------
gfx4l_rect
_row
    lda X16_P6
    beq _done
    jsr gfx4l_hline             ; advances P0/P1 by the width -- reset it,
    sec                        ; or every row starts where the last ended
    lda X16_P0                 ; (a staircase instead of a filled rect)
    sbc X16_P4
    sta X16_P0
    lda X16_P1
    sbc X16_P5
    sta X16_P1
    inc X16_P2
    dec X16_P6
    bra _row
_done
    rts

; ---------------------------------------------------------------------
; gfx4l_frame -- rectangle outline
;   same arguments as gfx4l_rect
; ---------------------------------------------------------------------
gfx4l_frame
    ldx #6
_gf4l_take
    lda X16_P0,x
    sta gb4l_x,x
    dex
    bpl _gf4l_take

    jsr bitmap4l_gf4l_restore_span
    jsr gfx4l_hline

    jsr bitmap4l_gf4l_restore_span
    clc
    lda gb4l_y
    adc gb4l_h
    sec
    sbc #1
    sta X16_P2
    jsr gfx4l_hline

    jsr bitmap4l_gf4l_restore_col
    jsr gfx4l_vline

    jsr bitmap4l_gf4l_restore_col
    clc
    lda gb4l_x
    adc gb4l_w
    sta X16_P0
    lda gb4l_x+1
    adc gb4l_w+1
    sta X16_P1
    lda X16_P0
    bne _gf4l_no_borrow
    dec X16_P1
_gf4l_no_borrow
    dec X16_P0
    jsr gfx4l_vline
    rts

bitmap4l_gf4l_restore_span
    ldx #5
bitmap4l_gf4l_rsp_l
    lda gb4l_x,x
    sta X16_P0,x
    dex
    bpl bitmap4l_gf4l_rsp_l
    rts

bitmap4l_gf4l_restore_col
    ldx #3
bitmap4l_gf4l_rcl_l
    lda gb4l_x,x
    sta X16_P0,x
    dex
    bpl bitmap4l_gf4l_rcl_l
    lda gb4l_h
    sta X16_P4
    rts

; ---------------------------------------------------------------------
; gfx4l_blit -- rows of pixels from RAM to the framebuffer
;   in:  A = raster op: 0 copy, 1 OR, 2 AND, 3 XOR
;        X16_P0/P1 = x, X16_P2 = y, X16_P4 = width in pixels (1-255),
;        X16_P5 = height in rows, X16_P6/P7 = source (row-major)
; ---------------------------------------------------------------------
gfx4l_blit
    and #3
    sta g4l_op
    lda X16_P4
    sta g4l_w
    lda X16_P5
    sta g4l_h
    lda X16_P6
    sta g4l_src
    lda X16_P7
    sta g4l_src+1
    lda g4l_w
    bne _gb4l_nonzero
    rts

_gb4l_nonzero
    clc
    lda g4l_w
    adc #1
    lsr
    sta g4l_rowbytes

    lda X16_P0
    sta g4l_x0
    lda X16_P1
    sta g4l_x0+1
    lda X16_P2
    sta g4l_y0

_gb4l_row
    lda g4l_x0
    sta X16_P0
    lda g4l_x0+1
    sta X16_P1
    lda g4l_y0
    sta X16_P2
    lda g4l_src
    sta X16_PTR3
    lda g4l_src+1
    sta X16_PTR3+1
    lda #0
    sta g4l_phase
    lda g4l_w
    sta g4l_n
_gb4l_col
    ldy #0
    lda (X16_PTR3),y
    sta g4l_ink
    lda g4l_phase
    beq _gb4l_bit_even
    lda g4l_ink
    and #$0F
    bra _gb4l_bit_done
_gb4l_bit_even
    lda g4l_ink
    and #$F0
    lsr
    lsr
    lsr
    lsr
_gb4l_bit_done
    sta g4l_ink
    jsr gfx4l_read
    sta g4l_t
    lda g4l_op
    beq _gb4l_copy
    cmp #1
    beq _gb4l_or
    cmp #2
    beq _gb4l_and
_gb4l_xor
    lda g4l_ink
    eor g4l_t
    bra _gb4l_store
_gb4l_and
    lda g4l_ink
    and g4l_t
    bra _gb4l_store
_gb4l_or
    lda g4l_ink
    ora g4l_t
_gb4l_store
    sta X16_P3
    jsr gfx4l_pset
    bra _gb4l_next_x
_gb4l_copy
    lda g4l_ink
    sta X16_P3
    jsr gfx4l_pset
    bra _gb4l_next_x
_gb4l_next_x
    inc X16_P0
    bne _gb4l_carry1
    inc X16_P1
_gb4l_carry1
    lda g4l_phase
    and #1
    beq _gb4l_flip_phase
    inc X16_PTR3
    bne _gb4l_flip_phase
    inc X16_PTR3+1
_gb4l_flip_phase
    eor #1
    sta g4l_phase
    dec g4l_n
    beq _gb4l_end_row
    jmp _gb4l_col
_gb4l_end_row
    lda g4l_src
    clc
    adc g4l_rowbytes
    sta g4l_src
    lda g4l_src+1
    adc #0
    sta g4l_src+1
    lda g4l_y0
    inc a
    sta g4l_y0
    dec g4l_h
    beq _gb4l_done
    jmp _gb4l_row
_gb4l_done
    rts

; ---------------------------------------------------------------------
; gfx4l_blitm -- a masked blit: colour 0 is transparent
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P4 = width (1-255),
;        X16_P5 = height, X16_P6/P7 = source (row-major)
; ---------------------------------------------------------------------
gfx4l_blitm
    lda X16_P4
    sta g4l_w
    lda X16_P5
    sta g4l_h
    lda X16_P6
    sta g4l_src
    lda X16_P7
    sta g4l_src+1
    lda g4l_w
    bne _gm4l_nonzero
    rts

_gm4l_nonzero
    clc
    lda g4l_w
    adc #1
    lsr
    sta g4l_rowbytes

    lda X16_P0
    sta g4l_x0
    lda X16_P1
    sta g4l_x0+1
    lda X16_P2
    sta g4l_y0

_gm4l_row
    lda g4l_x0
    sta X16_P0
    lda g4l_x0+1
    sta X16_P1
    lda g4l_y0
    sta X16_P2
    lda g4l_src
    sta X16_PTR3
    lda g4l_src+1
    sta X16_PTR3+1
    lda #0
    sta g4l_phase
    lda g4l_w
    sta g4l_n
_gm4l_col
    ldy #0
    lda (X16_PTR3),y
    sta g4l_ink
    lda g4l_phase
    beq _gm4l_px_even
    lda g4l_ink
    and #$0F
    bra _gm4l_px_done
_gm4l_px_even
    lda g4l_ink
    and #$F0
    lsr
    lsr
    lsr
    lsr
_gm4l_px_done
    beq _gm4l_skip
    sta X16_P3
    jsr gfx4l_pset
_gm4l_skip
    inc X16_P0
    bne _gm4l_carry1
    inc X16_P1
_gm4l_carry1
    lda g4l_phase
    and #1
    beq _gm4l_flip_phase
    inc X16_PTR3
    bne _gm4l_flip_phase
    inc X16_PTR3+1
_gm4l_flip_phase
    eor #1
    sta g4l_phase
    dec g4l_n
    bne _gm4l_col
    lda g4l_src
    clc
    adc g4l_rowbytes
    sta g4l_src
    lda g4l_src+1
    adc #0
    sta g4l_src+1
    lda g4l_y0
    inc a
    sta g4l_y0
    dec g4l_h
    beq _gm4l_done
    jmp _gm4l_row
_gm4l_done
    rts

; ---------------------------------------------------------------------
; gfx4l_pattern_set -- cache an 8x8 1bpp pattern for gfx4l_pattern_rect
;   in:  A = pattern low, X = pattern high
;        X16_P4 = background colour, X16_P5 = foreground colour
; ---------------------------------------------------------------------
gfx4l_pattern_set
    sta X16_T0
    stx X16_T0+1
    ldy #7
bitmap4l_gp4l_copy
    lda (X16_T0),y
    sta gp4l_pat,y
    dey
    bpl bitmap4l_gp4l_copy
    lda X16_P4
    and #$0F
    sta gp4l_bg
    lda X16_P5
    and #$0F
    sta gp4l_fg
    rts

; ---------------------------------------------------------------------
; gfx4l_pattern_rect -- fill a rectangle with the cached pattern
;   in:  X16_P0/P1 = x, X16_P2 = y, X16_P4/P5 = width, X16_P6 = height
; ---------------------------------------------------------------------
gfx4l_pattern_rect
    lda X16_P4
    ora X16_P5
    bne +
    rts
+
    lda X16_P6
    bne +
    rts
+
    lda X16_P0
    and #7
    sta gp4l_rot
    lda X16_P0
    sta gp4l_bx
    lda X16_P1
    sta gp4l_bx+1
    lda X16_P2
    sta gp4l_by
bitmap4l_gp4l_row
    lda X16_P2
    and #7
    tay
    lda gp4l_pat,y
    sta gp4l_cur
    lda gp4l_rot
    beq bitmap4l_gp4l_rot_ok
    tay
    lda gp4l_cur
bitmap4l_gp4l_rot
    asl
    adc #0
    dey
    bne bitmap4l_gp4l_rot
    sta gp4l_cur
bitmap4l_gp4l_rot_ok
    lda X16_P0
    sta g4l_x0
    lda X16_P1
    sta g4l_x0+1
    lda X16_P4
    sta g4l_n
    lda X16_P5
    sta g4l_n+1
bitmap4l_gp4l_col
    lda gp4l_cur
    bmi bitmap4l_gp4l_use_fg
    lda gp4l_bg
    bra bitmap4l_gp4l_out
bitmap4l_gp4l_use_fg
    lda gp4l_fg
bitmap4l_gp4l_out
    sta X16_P3
    lda g4l_x0
    sta X16_P0
    lda g4l_x0+1
    sta X16_P1
    lda X16_P2
    sta X16_P2
    jsr gfx4l_pset
    inc g4l_x0
    bne bitmap4l_gp4l_tail
    inc g4l_x0+1
bitmap4l_gp4l_tail
    lda gp4l_cur
    asl
    adc #0
    sta gp4l_cur
    lda g4l_n
    bne +
    dec g4l_n+1
+   dec g4l_n
    lda g4l_n
    ora g4l_n+1
    bne bitmap4l_gp4l_col
    lda gp4l_bx
    sta X16_P0
    lda gp4l_bx+1
    sta X16_P1
    inc X16_P2
    dec X16_P6
    beq bitmap4l_gp4l_done
    jmp bitmap4l_gp4l_row
bitmap4l_gp4l_done
    rts

; ---------------------------------------------------------------------
; gfx4l_line -- Bresenham, any direction
;   in:  X16_P0/P1 = x0, X16_P2 = y0
;        X16_P4/P5 = x1, y1 in P6/P7?  (compatible with gfx4l_line macros)
;        X16_P6 = colour
; ---------------------------------------------------------------------
gfx4l_line
    ldx #6
_gl4l_take
    lda X16_P0,x
    sta gl4l_x0,x
    dex
    bpl _gl4l_take

    sec
    lda gl4l_x1
    sbc gl4l_x0
    sta gl4l_dx
    lda gl4l_x1+1
    sbc gl4l_x0+1
    sta gl4l_dx+1
    bpl _gl4l_dx_pos
    sec
    lda #0
    sbc gl4l_dx
    sta gl4l_dx
    lda #0
    sbc gl4l_dx+1
    sta gl4l_dx+1
    lda #$FF
    sta gl4l_sx
    sta gl4l_sx+1
    bra _gl4l_dx_done
_gl4l_dx_pos
    lda #$01
    sta gl4l_sx
    stz gl4l_sx+1
_gl4l_dx_done

    sec                         ; dy = -|y1 - y0|, sy = sign (y is 8-bit)
    lda gl4l_y1
    sbc gl4l_y0
    bpl _gl4l_dy_pos
    eor #$FF
    clc
    adc #1                      ; absolute value
    sta gl4l_ldy
    lda #$FF
    sta gl4l_sy
    bra _gl4l_dy_done
_gl4l_dy_pos
    sta gl4l_ldy
    lda #$01
    sta gl4l_sy
_gl4l_dy_done
    sec
    lda #0
    sbc gl4l_ldy
    sta gl4l_dy
    lda #0
    sbc #0
    sta gl4l_dy+1               ; gl4l_dy = -|dy|, 16-bit signed

    clc
    lda gl4l_dx
    adc gl4l_dy
    sta gl4l_err
    lda gl4l_dx+1
    adc gl4l_dy+1
    sta gl4l_err+1

_gl4l_loop
    jsr bitmap4l_gl4l_plot
    lda gl4l_x0
    cmp gl4l_x1
    bne _gl4l_step
    lda gl4l_x0+1
    cmp gl4l_x1+1
    bne _gl4l_step
    lda gl4l_y0
    cmp gl4l_y1
    bne _gl4l_step
    rts

_gl4l_step
    lda gl4l_err
    asl
    sta gl4l_e2
    lda gl4l_err+1
    rol
    sta gl4l_e2+1
    sec
    lda gl4l_e2
    sbc gl4l_dy
    lda gl4l_e2+1
    sbc gl4l_dy+1
    bvc _gl4l_nv1
    eor #$80
_gl4l_nv1
    bmi _gl4l_skip_x
    clc
    lda gl4l_err
    adc gl4l_dy
    sta gl4l_err
    lda gl4l_err+1
    adc gl4l_dy+1
    sta gl4l_err+1
    clc
    lda gl4l_x0
    adc gl4l_sx
    sta gl4l_x0
    lda gl4l_x0+1
    adc gl4l_sx+1
    sta gl4l_x0+1
_gl4l_skip_x
    sec
    lda gl4l_dx
    sbc gl4l_e2
    lda gl4l_dx+1
    sbc gl4l_e2+1
    bvc _gl4l_nv2
    eor #$80
_gl4l_nv2
    bmi _gl4l_skip_y
    clc
    lda gl4l_err
    adc gl4l_dx
    sta gl4l_err
    lda gl4l_err+1
    adc gl4l_dx+1
    sta gl4l_err+1
    clc
    lda gl4l_y0
    adc gl4l_sy
    sta gl4l_y0
_gl4l_skip_y
    jmp _gl4l_loop

bitmap4l_gl4l_plot
    lda gl4l_x0
    sta X16_P0
    lda gl4l_x0+1
    sta X16_P1
    lda gl4l_y0
    sta X16_P2
    lda gl4l_color
    sta X16_P3
    jmp gfx4l_pset

.if !X16_BITMAP4L_MIN != 0
; ---------------------------------------------------------------------
; gfx4l_char / gfx4l_text
; ---------------------------------------------------------------------
gfx4l_char
    sta gt4l_code
    stz gt4l_hi
    asl
    rol gt4l_hi
    asl
    rol gt4l_hi
    asl
    rol gt4l_hi
    pha
    #vera_addrsel 1
    pla
    sta VERA_ADDR_L
    lda gt4l_hi
    clc
    adc #<(VRAM_CHARSET >> 8)
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))
    sta VERA_ADDR_H
    ldx #0
_gt4l_fetch
    lda VERA_DATA1
    sta gt4l_glyph,x
    inx
    cpx #8
    bne _gt4l_fetch
    #vera_addrsel 0

    lda X16_P0
    sta gt4l_bx
    lda X16_P1
    sta gt4l_bx+1
    lda X16_P2
    sta gt4l_by
    stz gt4l_row
_gt4l_rows
    ldx gt4l_row
    lda gt4l_glyph,x
    sta gt4l_bits
    beq _gt4l_next_row
    stz gt4l_col
_gt4l_cols
    asl gt4l_bits
    bcc _gt4l_next_col
    clc
    lda gt4l_bx
    adc gt4l_col
    sta X16_P0
    lda gt4l_bx+1
    adc #0
    sta X16_P1
    clc
    lda gt4l_by
    adc gt4l_row
    bcs _gt4l_next_col
    sta X16_P2
    jsr gfx4l_pset
_gt4l_next_col
    inc gt4l_col
    lda gt4l_col
    cmp #8
    bne _gt4l_cols
_gt4l_next_row
    inc gt4l_row
    lda gt4l_row
    cmp #8
    bne _gt4l_rows
    lda gt4l_bx
    sta X16_P0
    lda gt4l_bx+1
    sta X16_P1
    lda gt4l_by
    sta X16_P2
    rts

gfx4l_text
    sta bitmap4l_gt4l_lda+1
    stx bitmap4l_gt4l_lda+2
gtx4l_gt4l_loop
bitmap4l_gt4l_lda
    lda $FFFF
    beq gtx4l_gt4l_done
    bit #%01000000
    beq gtx4l_gt4l_code_ok
    and #$1F
gtx4l_gt4l_code_ok
    jsr gfx4l_char
    clc
    lda X16_P0
    adc #8
    sta X16_P0
    lda X16_P1
    adc #0
    sta X16_P1
    inc bitmap4l_gt4l_lda+1
    bne gtx4l_gt4l_loop
    inc bitmap4l_gt4l_lda+2
    bra gtx4l_gt4l_loop
gtx4l_gt4l_done
    rts
.endif

; ---------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------
bitmap4l_defpal
    .byte $FF, $0F, $AA, $0A, $55, $05, $00, $00
        .byte $F0, $00, $0F, $00, $F8, $08, $88, $00
        .byte $8F, $00, $0F, $0F, $F0, $0F, $FF, $00
        .byte $0F, $0F, $F0, $00, $99, $09, $66, $06

bitmap4l_colbyte
    .byte $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF

gp4l_pat .fill 8, 0
gp4l_bg  .byte 0
gp4l_fg  .byte 0
gp4l_rot .byte 0
gp4l_cur .byte 0
gp4l_bx  .word 0
gp4l_by  .byte 0

g4l_t    .byte 0

g4l_n    .word 0
g4l_w    .byte 0
g4l_h    .byte 0

g4l_rowbytes .byte 0

g4l_src .word 0

g4l_x0 .word 0

g4l_y0 .byte 0

g4l_phase .byte 0

g4l_op .byte 0
g4l_ink .byte 0

; Line helpers
gb4l_x   .word 0
gb4l_y   .byte 0
gb4l_c   .byte 0
gb4l_w   .word 0
gb4l_h   .byte 0

gl4l_x0  .word 0
gl4l_y0  .byte 0
gl4l_x1  .word 0
gl4l_y1  .byte 0
gl4l_color .byte 0
gl4l_dx  .word 0
gl4l_ldy .word 0
gl4l_dy  .word 0
gl4l_err .word 0
gl4l_e2  .word 0
gl4l_sx  .word 0
gl4l_sy  .byte 0

gt4l_code .byte 0
gt4l_hi   .byte 0
gt4l_glyph .fill 8, 0
gt4l_bx  .word 0
gt4l_by  .byte 0
gt4l_row .byte 0
gt4l_col .byte 0
gt4l_bits .byte 0

; (end zone)
.endif
.if xuse_bitmap4h
; --- inline gfx/bitmap4h.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/bitmap4h.asm -- VERA_2 640x480x16 SDRAM bitmap drawing
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Requires the MiSTer VERA_2 bitmap layer. The framebuffer is NOT VERA
; VRAM: it is the VERA_2 20-bit SDRAM byte address space behind $9F60-
; $9F6F. Feature-detect with gfx4h_has before relying on it.
;
; The framebuffer is 4bpp, two pixels per byte, rows of 320 bytes:
;   offset = y*320 + (x>>1), size = 153,600 bytes ($25800).
; High nibble is the left/even pixel, low nibble is the right/odd pixel.
;
; Calling convention follows the high-res engines:
;   X16_P0/P1 = x, X16_P2/P3 = y, colour in A.
; =====================================================================

; (zone: file scope in 64tass)

GFX4H_WIDTH       = 640
GFX4H_HEIGHT      = 480
GFX4H_STRIDE      = 320
GFX4H_FRAME_PAGES = 600        ; 153600 / 256

; ---------------------------------------------------------------------
; gfx4h_has -- feature-detect the VERA_2 bitmap layer
;   out: carry set if present, carry clear otherwise
; ---------------------------------------------------------------------
gfx4h_has
    lda VERA2_ID
    cmp #VERA2_ID_MAGIC
    beq _yes
    clc
    rts
_yes
    sec
    rts

; ---------------------------------------------------------------------
; gfx4h_init -- select 640x480@4bpp and load a 16-colour gray palette
; gfx4h_off  -- disable the VERA_2 bitmap layer
; ---------------------------------------------------------------------
gfx4h_init
    jsr gfx4h_pal_gray
    lda #(VERA2_CTRL_ENABLE | VERA2_CTRL_MODE_4BPP)
    sta VERA2_CTRL
    rts

gfx4h_off
    stz VERA2_CTRL
    rts

gfx4h_passthru_on
    lda VERA2_CTRL
    ora #VERA2_CTRL_PASSTHRU
    sta VERA2_CTRL
    rts

gfx4h_passthru_off
    lda #$FF - VERA2_CTRL_PASSTHRU
    and VERA2_CTRL
    sta VERA2_CTRL
    rts

; ---------------------------------------------------------------------
; gfx4h_pal_set -- set one VERA_2 palette entry
;   in: X = index, A = low byte (G<<4 | B), Y = high byte (R)
; gfx4h_pal_load -- load entries from RAM
;   in: X16_PTR0 = source, A = first index, X = count (0 loads nothing)
; ---------------------------------------------------------------------
gfx4h_pal_set
    sta g4h_t
    sty g4h_t2
    stx VERA2_PAL_IDX
    lda g4h_t
    sta VERA2_PAL_LO
    lda g4h_t2
    sta VERA2_PAL_HI
    rts

gfx4h_pal_load
    cpx #0
    beq _done
    sta VERA2_PAL_IDX
    stx g4h_n
    ldy #0
_loop
    lda (X16_PTR0),y
    sta VERA2_PAL_LO
    iny
    lda (X16_PTR0),y
    sta VERA2_PAL_HI
    iny
    dec g4h_n
    bne _loop
_done
    rts

gfx4h_pal_gray
    stz VERA2_PAL_IDX
    ldx #0
_loop
    txa
    asl
    asl
    asl
    asl
    stx g4h_t
    ora g4h_t
    sta VERA2_PAL_LO
    stx VERA2_PAL_HI
    inx
    cpx #16
    bne _loop
    rts

; ---------------------------------------------------------------------
; gfx4h_setptr -- point VERA_2 DATA at byte holding pixel (x,y)
;   in: A = VERA2_INC_* stride index, X16_P0/P1 = x, X16_P2/P3 = y
; ---------------------------------------------------------------------
gfx4h_setptr
    asl
    asl
    asl
    asl
    sta g4h_inc
    jsr bitmap4h_addr_calc
    lda g4h_a0
    sta VERA2_ADDR_L
    lda g4h_a1
    sta VERA2_ADDR_M
    lda g4h_a2
    and #$0F
    ora g4h_inc
    sta VERA2_ADDR_H
    rts

; ---------------------------------------------------------------------
; gfx4h_clear -- fill the whole framebuffer with one colour
;   in: A = colour (0-15)
; ---------------------------------------------------------------------
gfx4h_clear
    and #$0F
    tax
    lda bitmap4h_colbyte,x
    sta g4h_c
    stz VERA2_ADDR_L
    stz VERA2_ADDR_M
    stz VERA2_ADDR_H            ; ptr 0, stride +1
    lda #<GFX4H_FRAME_PAGES
    sta g4h_n
    lda #>GFX4H_FRAME_PAGES
    sta g4h_n+1
    lda g4h_c
    jmp bitmap4h_fill_pages

; ---------------------------------------------------------------------
; gfx4h_pset / gfx4h_read -- clipped pixel access
;   pset in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y
;   read out: carry clear, A = colour; carry set if off screen
; ---------------------------------------------------------------------
gfx4h_pset
    and #$0F
    sta g4h_c
    jsr bitmap4h_onscreen
    bcs _off
    lda #VERA2_INC_0            ; hold: read and write the same byte
    jsr gfx4h_setptr
    lda VERA2_DATA
    sta g4h_t
    lda X16_P0
    and #1
    bne _odd
    lda g4h_c
    asl
    asl
    asl
    asl
    sta g4h_t2
    lda g4h_t
    and #$0F
    ora g4h_t2
    sta VERA2_DATA
    rts
_odd
    lda g4h_t
    and #$F0
    ora g4h_c
    sta VERA2_DATA
_off
    rts

gfx4h_read
    jsr bitmap4h_onscreen
    bcs _off
    lda #VERA2_INC_0
    jsr gfx4h_setptr
    lda VERA2_DATA
    sta g4h_t
    lda X16_P0
    and #1
    beq _even
    lda g4h_t
    and #$0F
    clc
    rts
_even
    lda g4h_t
    and #$F0
    lsr
    lsr
    lsr
    lsr
    clc
    rts
_off
    rts

; ---------------------------------------------------------------------
; gfx4h_hline / gfx4h_vline -- spans, no clipping
;   in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y, X16_P4/P5 = length
; ---------------------------------------------------------------------
; hline: RMW the odd leading/trailing nibbles, STREAM the interior as
; whole two-pixel bytes through DATA at stride +1 -- one sta per two
; pixels instead of a full pset (address calc + RMW) per pixel.
gfx4h_hline
    and #$0F
    sta g4h_c
    tax
    lda bitmap4h_colbyte,x
    sta g4h_t2                  ; the both-nibbles fill byte
    lda X16_P4
    sta g4h_n
    lda X16_P5
    sta g4h_n+1
    ora g4h_n
    bne +
    rts
+   lda X16_P0
    and #1
    beq _aligned
    lda #VERA2_INC_0            ; leading odd pixel: RMW the low nibble
    jsr gfx4h_setptr
    lda VERA2_DATA
    and #$F0
    ora g4h_c
    sta VERA2_DATA
    inc X16_P0
    bne +
    inc X16_P1
+   lda g4h_n
    bne +
    dec g4h_n+1
+   dec g4h_n
    lda g4h_n
    ora g4h_n+1
    bne _aligned
    rts
_aligned
    lsr g4h_n+1                 ; n -> full bytes, carry = trailing pixel
    ror g4h_n
    bcc +
    lda #1
    sta g4h_phase               ; remember the trailing odd-width pixel
    bra ++
+   stz g4h_phase
++  lda g4h_n
    ora g4h_n+1
    beq _nofull
    lda #VERA2_INC_1
    jsr gfx4h_setptr
    lda g4h_t2
    jsr bitmap4h_fill_count
    lda g4h_phase
    beq _done
    lda VERA2_ADDR_H            ; the +1 stride left the pointer ON the
    and #$0F                    ; trailing byte: just switch it to hold
    ora #(VERA2_INC_0 << 4)
    sta VERA2_ADDR_H
    bra _rmwhi
_nofull
    lda g4h_phase
    beq _done
    lda #VERA2_INC_0
    jsr gfx4h_setptr
_rmwhi
    lda VERA2_DATA              ; trailing even pixel: RMW the high nibble
    and #$0F
    sta g4h_t
    lda g4h_t2
    and #$F0
    ora g4h_t
    sta VERA2_DATA
_done
    rts

; vline: one address calc, then per row an RMW at hold stride and a
; 24-bit +320 on the cached address (three pointer stores) -- the same
; nibble mask the whole way down, no per-pixel pset.
gfx4h_vline
    and #$0F
    sta g4h_c
    lda X16_P4
    sta g4h_n
    lda X16_P5
    sta g4h_n+1
    ora g4h_n
    beq _done
    jsr bitmap4h_addr_calc              ; g4h_a0..a2 = the column's first byte
    lda X16_P0
    and #1
    bne _odd
    lda #$0F                    ; even x: keep low nibble, or in col<<4
    sta g4h_t2
    lda g4h_c
    asl
    asl
    asl
    asl
    sta g4h_t
    bra _row
_odd
    lda #$F0                    ; odd x: keep high nibble, or in col
    sta g4h_t2
    lda g4h_c
    sta g4h_t
_row
    lda g4h_a0
    sta VERA2_ADDR_L
    lda g4h_a1
    sta VERA2_ADDR_M
    lda g4h_a2
    and #$0F
    ora #(VERA2_INC_0 << 4)     ; hold: read and write the same byte
    sta VERA2_ADDR_H
    lda VERA2_DATA
    and g4h_t2
    ora g4h_t
    sta VERA2_DATA
    clc                         ; address += 320, one row down
    lda g4h_a0
    adc #$40
    sta g4h_a0
    lda g4h_a1
    adc #$01
    sta g4h_a1
    bcc +
    inc g4h_a2
+   lda g4h_n
    bne +
    dec g4h_n+1
+   dec g4h_n
    lda g4h_n
    ora g4h_n+1
    bne _row
_done
    rts

; ---------------------------------------------------------------------
; gfx4h_rect / gfx4h_frame -- rectangles, no clipping
;   in: A = colour, X16_P0/P1 = x, X16_P2/P3 = y,
;       X16_P4/P5 = width, X16_P6/P7 = height
; ---------------------------------------------------------------------
gfx4h_rect
    and #$0F
    sta g4h_rc
    lda X16_P0
    sta g4h_rx
    lda X16_P1
    sta g4h_rx+1
_row
    lda X16_P6
    ora X16_P7
    beq _done
    lda g4h_rc
    jsr gfx4h_hline
    lda g4h_rx                  ; hline may nudge x for alignment: restore
    sta X16_P0
    lda g4h_rx+1
    sta X16_P1
    inc X16_P2
    bne +
    inc X16_P3
+   lda X16_P6
    bne +
    dec X16_P7
+   dec X16_P6
    bra _row
_done
    rts

gfx4h_frame
    and #$0F
    sta g4h_rc
    ldx #7
_take
    lda X16_P0,x
    sta g4h_fx,x
    dex
    bpl _take

    jsr bitmap4h_frame_span
    lda g4h_rc
    jsr gfx4h_hline

    jsr bitmap4h_frame_span
    clc
    lda g4h_fy
    adc g4h_rh
    sta X16_P2
    lda g4h_fy+1
    adc g4h_rh+1
    sta X16_P3
    lda X16_P2
    bne +
    dec X16_P3
+   dec X16_P2
    lda g4h_rc
    jsr gfx4h_hline

    jsr bitmap4h_frame_col
    lda g4h_rc
    jsr gfx4h_vline

    jsr bitmap4h_frame_col
    clc
    lda g4h_fx
    adc g4h_rw
    sta X16_P0
    lda g4h_fx+1
    adc g4h_rw+1
    sta X16_P1
    lda X16_P0
    bne +
    dec X16_P1
+   dec X16_P0
    lda g4h_rc
    jmp gfx4h_vline

bitmap4h_frame_span
    ldx #5
_s
    lda g4h_fx,x
    sta X16_P0,x
    dex
    bpl _s
    rts

bitmap4h_frame_col
    ldx #3
_c
    lda g4h_fx,x
    sta X16_P0,x
    dex
    bpl _c
    lda g4h_rh
    sta X16_P4
    lda g4h_rh+1
    sta X16_P5
    rts

; ---------------------------------------------------------------------
; gfx4h_line -- Bresenham line, clipped by gfx4h_pset
;   in: A = colour, P0/P1=x0, P2/P3=y0, P4/P5=x1, P6/P7=y1
; ---------------------------------------------------------------------
gfx4h_line
    and #$0F
    sta g4h_lc
    ldx #7
_take
    lda X16_P0,x
    sta g4h_lx0,x
    dex
    bpl _take

    sec
    lda g4h_lx1
    sbc g4h_lx0
    sta g4h_ldx
    lda g4h_lx1+1
    sbc g4h_lx0+1
    sta g4h_ldx+1
    bpl _dx_pos
    sec
    lda #0
    sbc g4h_ldx
    sta g4h_ldx
    lda #0
    sbc g4h_ldx+1
    sta g4h_ldx+1
    lda #$FF
    sta g4h_lsx
    sta g4h_lsx+1
    bra _dx_done
_dx_pos
    lda #1
    sta g4h_lsx
    stz g4h_lsx+1
_dx_done

    sec
    lda g4h_ly1
    sbc g4h_ly0
    sta g4h_ldy
    lda g4h_ly1+1
    sbc g4h_ly0+1
    sta g4h_ldy+1
    bpl _dy_pos
    sec
    lda #0
    sbc g4h_ldy
    sta g4h_ldy
    lda #0
    sbc g4h_ldy+1
    sta g4h_ldy+1
    lda #$FF
    sta g4h_lsy
    sta g4h_lsy+1
    bra _dy_done
_dy_pos
    lda #1
    sta g4h_lsy
    stz g4h_lsy+1
_dy_done
    sec
    lda #0
    sbc g4h_ldy
    sta g4h_ldy
    lda #0
    sbc g4h_ldy+1
    sta g4h_ldy+1

    clc
    lda g4h_ldx
    adc g4h_ldy
    sta g4h_lerr
    lda g4h_ldx+1
    adc g4h_ldy+1
    sta g4h_lerr+1

_loop
    lda g4h_lc
    jsr bitmap4h_plot
    lda g4h_lx0
    cmp g4h_lx1
    bne _step
    lda g4h_lx0+1
    cmp g4h_lx1+1
    bne _step
    lda g4h_ly0
    cmp g4h_ly1
    bne _step
    lda g4h_ly0+1
    cmp g4h_ly1+1
    bne _step
    rts

_step
    lda g4h_lerr
    asl
    sta g4h_le2
    lda g4h_lerr+1
    rol
    sta g4h_le2+1

    sec
    lda g4h_le2
    sbc g4h_ldy
    lda g4h_le2+1
    sbc g4h_ldy+1
    bvc _nv1
    eor #$80
_nv1
    bmi _skip_x
    clc
    lda g4h_lerr
    adc g4h_ldy
    sta g4h_lerr
    lda g4h_lerr+1
    adc g4h_ldy+1
    sta g4h_lerr+1
    clc
    lda g4h_lx0
    adc g4h_lsx
    sta g4h_lx0
    lda g4h_lx0+1
    adc g4h_lsx+1
    sta g4h_lx0+1
_skip_x
    sec
    lda g4h_ldx
    sbc g4h_le2
    lda g4h_ldx+1
    sbc g4h_le2+1
    bvc _nv2
    eor #$80
_nv2
    bmi _skip_y
    clc
    lda g4h_lerr
    adc g4h_ldx
    sta g4h_lerr
    lda g4h_lerr+1
    adc g4h_ldx+1
    sta g4h_lerr+1
    clc
    lda g4h_ly0
    adc g4h_lsy
    sta g4h_ly0
    lda g4h_ly0+1
    adc g4h_lsy+1
    sta g4h_ly0+1
_skip_y
    jmp _loop

bitmap4h_plot
    sta g4h_c
    lda g4h_lx0
    sta X16_P0
    lda g4h_lx0+1
    sta X16_P1
    lda g4h_ly0
    sta X16_P2
    lda g4h_ly0+1
    sta X16_P3
    lda g4h_c
    jmp gfx4h_pset

; ---------------------------------------------------------------------
; gfx4h_pattern_set / gfx4h_pattern_rect
; ---------------------------------------------------------------------
gfx4h_pattern_set
    sta X16_T0
    stx X16_T0+1
    ldy #7
_copy
    lda (X16_T0),y
    sta gp4h_pat,y
    dey
    bpl _copy
    lda X16_P4
    and #$0F
    sta gp4h_bg
    lda X16_P5
    and #$0F
    sta gp4h_fg
    rts

gfx4h_pattern_rect
    lda X16_P4
    ora X16_P5
    ora X16_P6
    ora X16_P7
    bne +
    jmp _done
+
    lda X16_P2
    sta gp4h_by
    lda X16_P3
    sta gp4h_by+1
    lda X16_P0
    sta gp4h_bx
    lda X16_P1
    sta gp4h_bx+1
_row
    lda X16_P6
    ora X16_P7
    bne +
    jmp _done
+
    lda gp4h_bx
    sta gp4h_x
    lda gp4h_bx+1
    sta gp4h_x+1
    lda X16_P4
    sta gp4h_n
    lda X16_P5
    sta gp4h_n+1
    lda X16_P2
    and #7
    tay
    lda gp4h_pat,y
    sta gp4h_bits
_col
    lda gp4h_n
    ora gp4h_n+1
    beq _next_row
    lda gp4h_bits
    bmi _fg
    lda gp4h_bg
    bra _plot
_fg
    lda gp4h_fg
_plot
    sta gp4h_c
    lda gp4h_x
    sta X16_P0
    lda gp4h_x+1
    sta X16_P1
    lda gp4h_by
    sta X16_P2
    lda gp4h_by+1
    sta X16_P3
    lda gp4h_c
    jsr gfx4h_pset
    lda gp4h_bits
    asl
    adc #0
    sta gp4h_bits
    inc gp4h_x
    bne +
    inc gp4h_x+1
+   lda gp4h_n
    bne +
    dec gp4h_n+1
+   dec gp4h_n
    jmp _col
_next_row
    inc gp4h_by
    bne +
    inc gp4h_by+1
+   lda gp4h_by
    sta X16_P2
    lda gp4h_by+1
    sta X16_P3
    lda X16_P6
    bne +
    dec X16_P7
+   dec X16_P6
    jmp _row
_done
    rts

; ---------------------------------------------------------------------
; gfx4h_blit / gfx4h_blitm -- packed RAM pixels to framebuffer
;   blit in: A = op (0 copy, 1 OR, 2 AND, 3 XOR)
;   common: P0/P1=x, P2/P3=y, P4=width (1-255), P5=height, P6/P7=source
; ---------------------------------------------------------------------
gfx4h_blit
    and #3
    sta g4h_op
    bra bitmap4h_blit_common

gfx4h_blitm
    lda #$80
    sta g4h_op
bitmap4h_blit_common
    lda X16_P6
    sta g4h_src
    lda X16_P7
    sta g4h_src+1
    lda X16_P4
    clc
    adc #1
    lsr
    sta g4h_rowbytes
_row
    lda X16_P5
    bne +
    jmp _done
+
    lda g4h_src
    sta X16_PTR3
    lda g4h_src+1
    sta X16_PTR3+1
    stz g4h_phase
    lda X16_P4
    sta g4h_w
_col
    lda g4h_w
    beq _next_row
    ldy #0
    lda (X16_PTR3),y
    ldy g4h_phase
    bne _low
    and #$F0
    lsr
    lsr
    lsr
    lsr
    bra _got
_low
    and #$0F
_got
    sta g4h_ink
    lda g4h_op
    bmi _masked
    beq _copy
    jsr gfx4h_read
    sta g4h_t
    lda g4h_op
    cmp #1
    beq _or
    cmp #2
    beq _and
    lda g4h_ink
    eor g4h_t
    bra _store
_and
    lda g4h_ink
    and g4h_t
    bra _store
_or
    lda g4h_ink
    ora g4h_t
    bra _store
_masked
    lda g4h_ink
    beq _advance
_copy
    lda g4h_ink
_store
    jsr gfx4h_pset
_advance
    inc X16_P0
    bne +
    inc X16_P1
+   lda g4h_phase
    eor #1
    sta g4h_phase
    bne +
    inc X16_PTR3
    bne +
    inc X16_PTR3+1
+   dec g4h_w
    jmp _col
_next_row
    sec
    lda X16_P0
    sbc X16_P4
    sta X16_P0
    bcs +
    dec X16_P1
+   clc
    lda g4h_src
    adc g4h_rowbytes
    sta g4h_src
    lda g4h_src+1
    adc #0
    sta g4h_src+1
    inc X16_P2
    bne +
    inc X16_P3
+   dec X16_P5
    jmp _row
_done
    rts

; ---------------------------------------------------------------------
; gfx4h_copy -- VERA_2 SDRAM-to-SDRAM hardware copy, then wait
;   in: P0/P1/P2 = source, P3/P4/P5 = destination, A/X/Y = length
; ---------------------------------------------------------------------
gfx4h_copy
    sta VERA2_BLIT_LEN_L
    stx VERA2_BLIT_LEN_M
    sty VERA2_BLIT_LEN_H
    lda X16_P0
    sta VERA2_ADDR_L
    lda X16_P1
    sta VERA2_ADDR_M
    lda X16_P2
    and #$0F
    sta VERA2_ADDR_H            ; source pointer, stride +1
    lda X16_P3
    sta VERA2_BLIT_DST_L
    lda X16_P4
    sta VERA2_BLIT_DST_M
    lda X16_P5
    and #$0F
    sta VERA2_BLIT_DST_H
    lda #1
    sta VERA2_BLIT_CTRL
gfx4h_copy_wait
    lda VERA2_BLIT_CTRL
    and #1
    bne gfx4h_copy_wait
    rts

; ---------------------------------------------------------------------
; private helpers
; ---------------------------------------------------------------------
bitmap4h_onscreen
    lda X16_P1
    cmp #>GFX4H_WIDTH
    bcc _xok
    bne _bad
    lda X16_P0
    cmp #<GFX4H_WIDTH
    bcs _bad
_xok
    lda X16_P3
    cmp #>GFX4H_HEIGHT
    bcc _ok
    bne _bad
    lda X16_P2
    cmp #<GFX4H_HEIGHT
    bcs _bad
_ok
    clc
    rts
_bad
    sec
    rts

bitmap4h_addr_calc
    lda X16_P2                  ; y*320 = y*256 + y*64, in ~25 cycles:
    ror                         ; lo = (y & 3) << 6
    ror                         ; md = y + (y >> 2)
    ror                         ; hi = carry out of the md add
    and #$C0
    sta g4h_a0
    lda X16_P2
    lsr
    lsr
    clc
    adc X16_P2
    sta g4h_a1
    lda #0
    rol
    sta g4h_a2
    lda X16_P3                  ; y >= 256: + 256*320 = $14000
    beq _addx
    clc
    lda g4h_a1
    adc #$40
    sta g4h_a1
    bcc +
    inc g4h_a2
+   inc g4h_a2
_addx
    lda X16_P1                  ; + x >> 1
    lsr
    sta X16_T1
    lda X16_P0
    ror
    clc
    adc g4h_a0
    sta g4h_a0
    lda g4h_a1
    adc X16_T1
    sta g4h_a1
    bcc +
    inc g4h_a2
+   rts

bitmap4h_fill_count
    ldy g4h_n+1                 ; high byte first, so beq tests the LOW
    ldx g4h_n                   ; byte (same shape as bitmap8h)
    beq _full
    iny
_full
_loop
    sta VERA2_DATA
    dex
    bne _loop
    dey
    bne _loop
    rts

bitmap4h_fill_pages
_outer
    ldx #0
_inner
    sta VERA2_DATA
    dex
    bne _inner
    lda g4h_n
    bne +
    dec g4h_n+1
+   dec g4h_n
    lda g4h_n
    ora g4h_n+1
    beq _done
    lda g4h_c
    bra _outer
_done
    rts

; ---------------------------------------------------------------------
; data
; ---------------------------------------------------------------------
g4h_a0  .byte 0
g4h_a1  .byte 0
g4h_a2  .byte 0
g4h_inc .byte 0
g4h_c   .byte 0
g4h_t   .byte 0
g4h_t2  .byte 0
g4h_n   .word 0
g4h_w   .byte 0
g4h_op  .byte 0
g4h_ink .byte 0
g4h_src .word 0
g4h_rowbytes .byte 0
g4h_phase .byte 0

g4h_rx  .word 0
g4h_fx  .word 0
g4h_fy  .word 0
g4h_rw  .word 0
g4h_rh  .word 0
g4h_rc  .byte 0

gp4h_pat  .fill 8, 0
gp4h_bg   .byte 0
gp4h_fg   .byte 0
gp4h_bits .byte 0
gp4h_bx   .word 0
gp4h_x    .word 0
gp4h_by   .word 0
gp4h_n    .word 0
gp4h_c    .byte 0

g4h_lc   .byte 0
g4h_lx0  .word 0
g4h_ly0  .word 0
g4h_lx1  .word 0
g4h_ly1  .word 0
g4h_ldx  .word 0
g4h_ldy  .word 0
g4h_lerr .word 0
g4h_le2  .word 0
g4h_lsx  .word 0
g4h_lsy  .word 0

bitmap4h_colbyte
    .byte $00, $11, $22, $33, $44, $55, $66, $77
         .byte $88, $99, $AA, $BB, $CC, $DD, $EE, $FF


; (end zone)
.endif
.if xuse_fb
; --- inline gfx/fb.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/fb.asm -- KERNAL framebuffer wrappers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; These are thin wrappers over the stable Commander X16 KERNAL
; framebuffer jump table. The default ROM driver is 320x240 at 8bpp, but
; the KERNAL GRAPH layer can install a different FB driver.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; fb_init -- initialize the active framebuffer driver
; ---------------------------------------------------------------------
fb_init
    jmp FB_INIT

; ---------------------------------------------------------------------
; fb_get_info -- get framebuffer geometry
;   out: r0 = width, r1 = height, A = color depth
; ---------------------------------------------------------------------
fb_get_info
    jmp FB_GET_INFO

; ---------------------------------------------------------------------
; fb_set_palette -- set one or more VERA palette entries
;   in: r0 = palette data pointer, A = start index, X = count (0 = 256)
; ---------------------------------------------------------------------
fb_set_palette
    jmp FB_SET_PALETTE

; ---------------------------------------------------------------------
; fb_cursor_position -- position the framebuffer cursor
;   in: r0 = x, r1 = y
; ---------------------------------------------------------------------
fb_cursor_position
    jmp FB_CURSOR_POSITION

; ---------------------------------------------------------------------
; fb_cursor_next_line -- move framebuffer cursor to the next scanline
; ---------------------------------------------------------------------
fb_cursor_next_line
    jmp FB_CURSOR_NEXT_LINE

; ---------------------------------------------------------------------
; fb_get_pixel -- read pixel at current framebuffer cursor
;   out: A = color
; ---------------------------------------------------------------------
fb_get_pixel
    jmp FB_GET_PIXEL

; ---------------------------------------------------------------------
; fb_get_pixels -- read pixels from cursor into memory
;   in: r0 = destination pointer, r1 = count
; ---------------------------------------------------------------------
fb_get_pixels
    jmp FB_GET_PIXELS

; ---------------------------------------------------------------------
; fb_set_pixel -- write pixel at current framebuffer cursor
;   in: A = color
; ---------------------------------------------------------------------
fb_set_pixel
    jmp FB_SET_PIXEL

; ---------------------------------------------------------------------
; fb_set_pixels -- write pixels from memory to cursor
;   in: r0 = source pointer, r1 = count
; ---------------------------------------------------------------------
fb_set_pixels
    jmp FB_SET_PIXELS

; ---------------------------------------------------------------------
; fb_set_8_pixels -- draw an 8-bit pattern at cursor
;   in: A = pattern, X = foreground color
; ---------------------------------------------------------------------
fb_set_8_pixels
    jmp FB_SET_8_PIXELS

; ---------------------------------------------------------------------
; fb_set_8_pixels_opaque -- draw an 8-bit masked pattern at cursor
;   in: A = mask, r0L = pattern, X = foreground, Y = background
; ---------------------------------------------------------------------
fb_set_8_pixels_opaque
    jmp FB_SET_8_PIXELS_OPAQUE

; ---------------------------------------------------------------------
; fb_fill_pixels -- fill from cursor
;   in: r0 = pixel count, r1 = step size, A = color
; ---------------------------------------------------------------------
fb_fill_pixels
    jmp FB_FILL_PIXELS

; ---------------------------------------------------------------------
; fb_filter_pixels -- filter pixels from cursor
;   in: r0 = pixel count, r1 = filter routine pointer
;        filter: A = old color, returns A = new color
; ---------------------------------------------------------------------
fb_filter_pixels
    jmp FB_FILTER_PIXELS

; ---------------------------------------------------------------------
; fb_move_pixels -- move a horizontal pixel span
;   in: r0 = source x, r1 = source y, r2 = target x,
;       r3 = target y, r4 = pixel count
; ---------------------------------------------------------------------
fb_move_pixels
    jmp FB_MOVE_PIXELS

; (end zone)
.endif
.if xuse_graph
; --- inline gfx/graph.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/graph.asm -- KERNAL GRAPH wrappers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; These are thin wrappers over the stable Commander X16 KERNAL GRAPH API.
; GRAPH is the ROM's higher-level drawing layer on top of the active
; framebuffer driver.
; =====================================================================

; (zone: file scope in 64tass)

; --- character style bits used by graph_get_char_size ----------------
GRAPH_STYLE_UNDERLINE = %00000001
GRAPH_STYLE_BOLD      = %00000010
GRAPH_STYLE_ITALIC    = %00000100

; ---------------------------------------------------------------------
; graph_init -- initialize GRAPH and active framebuffer driver
;   in: r0 = FB_* driver vector pointer, or 0 for default 320x240@8bpp
; ---------------------------------------------------------------------
graph_init
    jmp GRAPH_INIT

; ---------------------------------------------------------------------
; graph_clear -- clear current GRAPH window to background color
; ---------------------------------------------------------------------
graph_clear
    jmp GRAPH_CLEAR

; ---------------------------------------------------------------------
; graph_set_window -- set clipping/window rectangle
;   in: r0 = x, r1 = y, r2 = width, r3 = height
;       0/0/0/0 resets to full screen
; ---------------------------------------------------------------------
graph_set_window
    jmp GRAPH_SET_WINDOW

; ---------------------------------------------------------------------
; graph_set_colors -- set drawing colors
;   in: A = primary/stroke, X = secondary/fill, Y = background
; ---------------------------------------------------------------------
graph_set_colors
    jmp GRAPH_SET_COLORS

; ---------------------------------------------------------------------
; graph_draw_line -- draw line
;   in: r0 = x1, r1 = y1, r2 = x2, r3 = y2
; ---------------------------------------------------------------------
graph_draw_line
    jmp GRAPH_DRAW_LINE

; ---------------------------------------------------------------------
; graph_draw_rect -- draw rectangle
;   in: r0 = x, r1 = y, r2 = width, r3 = height, r4 = corner radius
;       C clear = outline, C set = fill
; ---------------------------------------------------------------------
graph_draw_rect
    jmp GRAPH_DRAW_RECT

; ---------------------------------------------------------------------
; graph_move_rect -- move rectangle
;   in: r0 = sx, r1 = sy, r2 = tx, r3 = ty, r4 = width, r5 = height
; ---------------------------------------------------------------------
graph_move_rect
    jmp GRAPH_MOVE_RECT

; ---------------------------------------------------------------------
; graph_draw_oval -- draw oval
;   in: r0 = x, r1 = y, r2 = width, r3 = height
;       C clear = outline, C set = fill
; ---------------------------------------------------------------------
graph_draw_oval
    jmp GRAPH_DRAW_OVAL

; ---------------------------------------------------------------------
; graph_draw_image -- draw image bytes
;   in: r0 = x, r1 = y, r2 = image pointer, r3 = width, r4 = height
; ---------------------------------------------------------------------
graph_draw_image
    jmp GRAPH_DRAW_IMAGE

; ---------------------------------------------------------------------
; graph_set_font -- set current GRAPH font
;   in: r0 = font pointer, or 0 for system font
; ---------------------------------------------------------------------
graph_set_font
    jmp GRAPH_SET_FONT

; ---------------------------------------------------------------------
; graph_get_char_size -- get character metrics
;   in:  A = character, X = GRAPH_STYLE_* bits
;   out: printable: C clear, A = baseline, X = width, Y = height
;        control:   C set, X = new style
; ---------------------------------------------------------------------
graph_get_char_size
    jmp GRAPH_GET_CHAR_SIZE

; ---------------------------------------------------------------------
; graph_put_char -- draw a character and update position
;   in:  A = character, r0 = x, r1 = y
;   out: r0/r1 = updated position, carry set if outside bounds
; ---------------------------------------------------------------------
graph_put_char
    jmp GRAPH_PUT_CHAR

; (end zone)
.endif
.if xuse_console
; --- inline gfx/console.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/console.asm -- KERNAL console API wrappers
; =====================================================================
; Gate: X16_USE_CONSOLE
;
; Thin wrappers around the Commander X16 KERNAL console API. The console
; renders through GRAPH, but this gate is intentionally separate so callers
; can opt into only the ROM entry points they want to use.

; PETSCII control codes accepted by con_put_char for GRAPH font styling.
CON_ATTR_UNDERLINE = $04
CON_ATTR_BOLD      = $06
CON_ATTR_ITALICS   = $0b
CON_ATTR_OUTLINE   = $0c
CON_ATTR_RESET     = $92

; con_set_paging_message
;   in: r0 = pointer to a zero-terminated paging prompt
con_set_paging_message
    jmp CONSOLE_SET_PAGING_MESSAGE

; con_disable_paging
;   disables the pause prompt between console pages
con_disable_paging
    stz r0L
    stz r0H
    jmp CONSOLE_SET_PAGING_MESSAGE

; con_put_image
;   in: r0 = image pointer, r1 = width, r2 = height
;       image data uses the GRAPH_draw_image format
con_put_image
    jmp CONSOLE_PUT_IMAGE

; con_init
;   in: r0 = x, r1 = y, r2 = width, r3 = height
;       use all zeroes for the full GRAPH window
con_init
    jmp CONSOLE_INIT

; con_put_char
;   in: A = character, C clear = character wrap, C set = word wrap
con_put_char
    jmp CONSOLE_PUT_CHAR

; con_get_char
;   out: A = character
con_get_char
    jmp CONSOLE_GET_CHAR
.endif
.if xuse_shapes && X16_SKIP_SHAPES == 0
; --- inline gfx/shapes.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/shapes.asm -- circle, disc, flood fill (any bitmap)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does,
; under X16_USE_SHAPES).
;
; The shapes are ENGINE-AGNOSTIC and live here ONCE, not per engine:
; they draw through three entry symbols and read the canvas bounds
; through two, all overridable BEFORE this file is sourced. Left alone
; they bind to the 2bpp high-res module (bitmap2h). Any engine with the same call
; shapes can sit behind them:
;   - bitmap2h (2bpp): the default, no work.
;   - bitmap8l (8bpp): predefine SHP_PSET / SHP_HLINE to small shims that
;     move the colour from A into X16_P3 (where gfx8l_pset wants it), then
;     jmp gfx8l_pset / gfx8l_hline; SHP_READ = gfx8l_read; SHP_W/H = 320/240.
;   - CXRF points them at its graphics port and gets every mode at once.
;
;   SHP_PSET   pset:  P0/P1 = x, P2/P3 = y, A = colour (must clip)
;   SHP_READ   read:  P0/P1 = x, P2/P3 = y -> A = the pixel
;   SHP_HLINE  hline: P0/P1 = x, P2/P3 = y, P4/P5 = len, A = colour
;   SHP_W/H    the ADDRESS of a little-endian word: canvas w / h
;
; The P block is reloaded before every call, so the bound routines may
; clobber it freely; X16_T0..T7 are never touched here.
;
;   shape_circle  in: P0/P1 = cx, P2/P3 = cy, P4 = r (0-255), A = colour
;                 An outline, by the midpoint walk, plotted with
;                 SHP_PSET -- so it clips wherever pset clips.
;   shape_disc    same arguments, filled with spans. SHP_HLINE does not
;                 clip (the module policy), so keep a disc on screen.
;   shape_ellipse in: P0/P1 = cx, P2/P3 = cy, P4 = rx, P5 = ry (each
;                 0-255), A = colour. An axis-aligned outline by the
;                 midpoint walk, plotted with SHP_PSET -- so it clips
;                 wherever pset clips.
;   shape_fellipse same arguments, filled with spans. Like shape_disc
;                 it draws with SHP_HLINE, so keep it on screen.
;   shape_flood   in: P0/P1 = x, P2/P3 = y, A = colour. Scanline seed
;                 fill of the region containing (x,y). Bounds-checked
;                 against SHP_W/SHP_H, so it never reads off canvas.
;                 Carry set if the seed stack overflowed -- a very
;                 tortured region may come back incomplete.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; shape_circle / shape_disc -- one walk for both, like the ellipse:
; shapes_efl routes each plot through shapes_eplot to the octant points (outline)
; or the spans (fill).
; ---------------------------------------------------------------------
; CXRF: X16_SKIP_BASE lets this file be !source'd a 2nd time for the extra
; shapes only (base + defaults in bank 17, extras in bank 19). Upstream-safe.
.if !X16_SKIP_BASE != 0
shape_circle
	sta shapes_col
	stz shapes_efl                    ; outline: the octant point pairs
	bra shapes_cgo
shape_disc
	sta shapes_col
	lda #1                      ; filled: spans at cy +/- b instead
	sta shapes_efl
shapes_cgo
	jsr shapes_take_cxy               ; cx/cy out of the P block, x=r, y=0
shapes_cloop
	lda shapes_y                      ; while y <= x
	cmp shapes_x
	beq shapes_cplot                  ; the diagonal point still plots
	bcs shapes_cdone
shapes_cplot
	lda shapes_x                      ; the (x,y) octant pair...
	sta shapes_a
	lda shapes_y
	sta shapes_b
	jsr shapes_eplot
	lda shapes_y                      ; ...and the (y,x) pair
	sta shapes_a
	lda shapes_x
	sta shapes_b
	jsr shapes_eplot
	jsr shapes_step                   ; the midpoint error walk
	bra shapes_cloop
shapes_cdone
	rts

; --- shared circle/disc/ellipse machinery -------------------------------
shapes_take_cxy
	lda X16_P0
	sta shapes_cx
	lda X16_P1
	sta shapes_cx+1
	lda X16_P2
	sta shapes_cy
	lda X16_P3
	sta shapes_cy+1
	lda X16_P4
	sta shapes_x
	lda #0
	sta shapes_y
	sec                         ; err = 1 - r, signed 16-bit
	lda #1
	sbc shapes_x
	sta shapes_err
	lda #0
	sbc #0
	sta shapes_err+1
	rts

shapes_step
	inc shapes_y                      ;      else x--, err += 2(y-x)+1
	bit shapes_err+1
	bmi shapes_grow
	dec shapes_x
	sec                         ; t = y - x, sign-extended
	lda shapes_y
	sbc shapes_x
	sta shapes_t
	lda #0
	sbc #0
	sta shapes_t+1
	bra shapes_apply
shapes_grow
	lda shapes_y                      ; t = y (positive)
	sta shapes_t
	lda #0
	sta shapes_t+1
shapes_apply
	asl shapes_t                      ; err += 2t + 1
	rol shapes_t+1
	inc shapes_t
	bne +
	inc shapes_t+1
+	clc
	lda shapes_err
	adc shapes_t
	sta shapes_err
	lda shapes_err+1
	adc shapes_t+1
	sta shapes_err+1
	rts

shapes_pair4
	lda #0
	sta shapes_sx
	sta shapes_sy
shapes_p4go
	jsr shapes_emit1
	lda shapes_sx                     ; walk ++, -+, +-, -- via two flags
	eor #1
	sta shapes_sx
	bne shapes_p4go
	lda shapes_sy
	eor #1
	sta shapes_sy
	bne shapes_p4go
	rts

shapes_emit1
	lda shapes_sx
	bne shapes_e1xm
	clc                         ; x = cx + a
	lda shapes_cx
	adc shapes_a
	sta X16_P0
	lda shapes_cx+1
	adc #0
	sta X16_P1
	bra shapes_e1y
shapes_e1xm
	jsr shapes_subx                   ; x = cx - a
shapes_e1y
	jsr shapes_sety
	lda shapes_col
	jmp SHP_PSET

shapes_span2
	lda #0
	sta shapes_sy
	jsr shapes_espan
	lda #1
	sta shapes_sy
	; fall through
shapes_espan
	jsr shapes_subx                   ; x = cx - a
	jsr shapes_sety
	lda shapes_a                      ; len = 2a + 1
	sta X16_P4
	lda #0
	sta X16_P5
	asl X16_P4
	rol X16_P5
	inc X16_P4
	bne +
	inc X16_P5
+	lda shapes_col
	jmp SHP_HLINE

shapes_subx
	sec
	lda shapes_cx
	sbc shapes_a
	sta X16_P0
	lda shapes_cx+1
	sbc #0
	sta X16_P1
	rts

shapes_sety
	lda shapes_sy
	bne shapes_sym
	clc
	lda shapes_cy
	adc shapes_b
	sta X16_P2
	lda shapes_cy+1
	adc #0
	sta X16_P3
	rts
shapes_sym
	sec
	lda shapes_cy
	sbc shapes_b
	sta X16_P2
	lda shapes_cy+1
	sbc #0
	sta X16_P3
	rts

; ---------------------------------------------------------------------
; shape_ellipse / shape_fellipse
; ---------------------------------------------------------------------
; One walk serves both: the error-form midpoint ellipse (Zingl),
; quadrant II from (-rx, 0) up to (0, ry), mirrored 4 ways by the
; circle's own shapes_pair4 / shapes_span2. The decision terms reach 2*rx*ry`2
; (about 33M at 255/255), so the arithmetic is 32-bit; the one setup
; product rx * 2ry`2 is a repeated subtract, a few thousand cycles at
; the very worst -- noise against the drawing itself.
;   dx = ry`2 - rx*2ry`2, dy = rx`2, err = dx + dy
;   each step: e2 = 2*err;
;     e2 >= dx ?  x++, err += dx += 2ry`2
;     e2 <= dy ?  y++, err += dy += 2rx`2
;   while x <= 0; then a centre column finishes the flat tips (small
;   rx). A row's widest span always lands before its narrower echoes,
;   so the fill's overdraw is harmless, same as the disc's.
; ---------------------------------------------------------------------
shape_ellipse
	sta shapes_col
	stz shapes_efl
	bra shapes_etake
shape_fellipse
	sta shapes_col
	lda #1
	sta shapes_efl
shapes_etake
	lda X16_P0                  ; centre out of the P block
	sta shapes_cx
	lda X16_P1
	sta shapes_cx+1
	lda X16_P2
	sta shapes_cy
	lda X16_P3
	sta shapes_cy+1
	lda X16_P4
	sta shapes_ew
	lda X16_P5
	sta shapes_eh

	lda shapes_eh                     ; shapes_sq = ry`2
	jsr shapes_sq16
	lda shapes_sq                     ; dx = ry`2 (the rx*2ry`2 comes off below)
	sta shapes_edx
	lda shapes_sq+1
	sta shapes_edx+1
	stz shapes_edx+2
	stz shapes_edx+3
	lda shapes_sq                     ; shapes_e2b = 2ry`2
	sta shapes_e2b
	lda shapes_sq+1
	sta shapes_e2b+1
	stz shapes_e2b+2
	stz shapes_e2b+3
	asl shapes_e2b
	rol shapes_e2b+1
	rol shapes_e2b+2
	ldx shapes_ew                     ; dx -= rx * 2ry`2, one 2ry`2 at a time
	beq shapes_exset
shapes_emul
	sec
	lda shapes_edx
	sbc shapes_e2b
	sta shapes_edx
	lda shapes_edx+1
	sbc shapes_e2b+1
	sta shapes_edx+1
	lda shapes_edx+2
	sbc shapes_e2b+2
	sta shapes_edx+2
	lda shapes_edx+3
	sbc shapes_e2b+3
	sta shapes_edx+3
	dex
	bne shapes_emul
shapes_exset
	lda shapes_ew                     ; shapes_sq = rx`2
	jsr shapes_sq16
	lda shapes_sq                     ; dy = rx`2
	sta shapes_edy
	lda shapes_sq+1
	sta shapes_edy+1
	stz shapes_edy+2
	stz shapes_edy+3
	lda shapes_sq                     ; shapes_e2a = 2rx`2
	sta shapes_e2a
	lda shapes_sq+1
	sta shapes_e2a+1
	stz shapes_e2a+2
	stz shapes_e2a+3
	asl shapes_e2a
	rol shapes_e2a+1
	rol shapes_e2a+2
	clc                         ; err = dx + dy
	lda shapes_edx
	adc shapes_edy
	sta shapes_eerr
	lda shapes_edx+1
	adc shapes_edy+1
	sta shapes_eerr+1
	lda shapes_edx+2
	adc shapes_edy+2
	sta shapes_eerr+2
	lda shapes_edx+3
	adc shapes_edy+3
	sta shapes_eerr+3
	sec                         ; x = -rx (16-bit signed), y = 0
	lda #0
	sbc shapes_ew
	sta shapes_ex
	lda #0
	sbc #0
	sta shapes_ex+1
	stz shapes_ey

shapes_eloop
	sec                         ; this step's quadrant point: (|x|, y)
	lda #0
	sbc shapes_ex
	sta shapes_a
	lda shapes_ey
	sta shapes_b
	jsr shapes_eplot
	lda shapes_eerr                   ; e2 = 2*err, copied with the shift
	asl
	sta shapes_ee2
	lda shapes_eerr+1
	rol
	sta shapes_ee2+1
	lda shapes_eerr+2
	rol
	sta shapes_ee2+2
	lda shapes_eerr+3
	rol
	sta shapes_ee2+3
	sec                         ; e2 >= dx?  sign of e2 - dx decides
	lda shapes_ee2
	sbc shapes_edx
	lda shapes_ee2+1
	sbc shapes_edx+1
	lda shapes_ee2+2
	sbc shapes_edx+2
	lda shapes_ee2+3
	sbc shapes_edx+3
	bmi shapes_noxstep
	inc shapes_ex                     ; x++
	bne shapes_exdx
	inc shapes_ex+1
shapes_exdx
	clc                         ; err += dx += 2ry`2
	lda shapes_edx
	adc shapes_e2b
	sta shapes_edx
	lda shapes_edx+1
	adc shapes_e2b+1
	sta shapes_edx+1
	lda shapes_edx+2
	adc shapes_e2b+2
	sta shapes_edx+2
	lda shapes_edx+3
	adc shapes_e2b+3
	sta shapes_edx+3
	clc
	lda shapes_eerr
	adc shapes_edx
	sta shapes_eerr
	lda shapes_eerr+1
	adc shapes_edx+1
	sta shapes_eerr+1
	lda shapes_eerr+2
	adc shapes_edx+2
	sta shapes_eerr+2
	lda shapes_eerr+3
	adc shapes_edx+3
	sta shapes_eerr+3
shapes_noxstep
	sec                         ; e2 <= dy?  sign of dy - e2 decides
	lda shapes_edy
	sbc shapes_ee2
	lda shapes_edy+1
	sbc shapes_ee2+1
	lda shapes_edy+2
	sbc shapes_ee2+2
	lda shapes_edy+3
	sbc shapes_ee2+3
	bmi shapes_noystep
	inc shapes_ey                     ; y++
	clc                         ; err += dy += 2rx`2
	lda shapes_edy
	adc shapes_e2a
	sta shapes_edy
	lda shapes_edy+1
	adc shapes_e2a+1
	sta shapes_edy+1
	lda shapes_edy+2
	adc shapes_e2a+2
	sta shapes_edy+2
	lda shapes_edy+3
	adc shapes_e2a+3
	sta shapes_edy+3
	clc
	lda shapes_eerr
	adc shapes_edy
	sta shapes_eerr
	lda shapes_eerr+1
	adc shapes_edy+1
	sta shapes_eerr+1
	lda shapes_eerr+2
	adc shapes_edy+2
	sta shapes_eerr+2
	lda shapes_eerr+3
	adc shapes_edy+3
	sta shapes_eerr+3
shapes_noystep
	lda shapes_ex+1                   ; while x <= 0
	bmi shapes_econt
	ora shapes_ex
	bne shapes_etip
shapes_econt
	jmp shapes_eloop
shapes_etip
	lda shapes_ey                     ; flat tip: the centre column on to ry
	cmp shapes_eh
	bcs shapes_edone
	inc shapes_ey
	stz shapes_a
	lda shapes_ey
	sta shapes_b
	jsr shapes_eplot
	bra shapes_etip
shapes_edone
	rts

shapes_eplot
	lda shapes_efl
	beq shapes_eout
	jmp shapes_span2
shapes_eout
	jmp shapes_pair4

shapes_sq16
	sta shapes_sm
	stz shapes_sq
	stz shapes_sq+1
	tax
	beq shapes_sqdone
shapes_sqlp
	clc
	lda shapes_sq
	adc shapes_sm
	sta shapes_sq
	bcc shapes_sqnc
	inc shapes_sq+1
shapes_sqnc
	dex
	bne shapes_sqlp
shapes_sqdone
	rts

; ---------------------------------------------------------------------
; shape_flood
; ---------------------------------------------------------------------
; Pop a seed, widen it into a span of the target colour, fill the span,
; then scan the rows above and below for runs of target and push one
; seed per run. The stack holds seeds as x.w y.w; when it is full a
; seed is dropped and the overflow is remembered in the carry.
; ---------------------------------------------------------------------
FLOOD_MAX = 96                  ; seeds; 4 bytes each

shape_flood
	sta shapes_col
	lda #0
	sta shapes_ovf
	sta shapes_sp
	jsr SHP_READ                ; the target = the seed's own colour
	                            ; (read at the CALLER's P block)
	sta shapes_tgt
	cmp shapes_col                    ; filling with itself never ends: done
	bne shapes_fseed
	clc                         ; (no overflow could have happened yet)
	rts
shapes_fseed
	lda X16_P0                  ; push the seed
	sta shapes_qx
	lda X16_P1
	sta shapes_qx+1
	lda X16_P2
	sta shapes_qy
	lda X16_P3
	sta shapes_qy+1
	jsr shapes_push
shapes_floop
	lda shapes_sp                     ; stack empty: finished
	bne shapes_fbody
	jmp shapes_fexit
shapes_fbody
	jsr shapes_pop                    ; seed -> shapes_qx/shapes_qy
	jsr shapes_rd_q                   ; still target? (may have been filled)
	cmp shapes_tgt
	bne shapes_floop

	lda shapes_qx                     ; widen left: xl = leftmost target
	sta shapes_xl
	lda shapes_qx+1
	sta shapes_xl+1
shapes_wleft
	lda shapes_xl
	ora shapes_xl+1
	beq shapes_wldone                 ; at column 0
	sec                         ; probe xl-1
	lda shapes_xl
	sbc #1
	sta shapes_qx
	lda shapes_xl+1
	sbc #0
	sta shapes_qx+1
	jsr shapes_rd_q
	cmp shapes_tgt
	bne shapes_wldone
	lda shapes_qx
	sta shapes_xl
	lda shapes_qx+1
	sta shapes_xl+1
	bra shapes_wleft
shapes_wldone
	lda shapes_xl                     ; widen right: xr = rightmost target
	sta shapes_xr                     ; (qy already holds the row)
	lda shapes_xl+1
	sta shapes_xr+1
shapes_wright
	clc                         ; probe xr+1, stop at SHP_W-1
	lda shapes_xr
	adc #1
	sta shapes_qx
	lda shapes_xr+1
	adc #0
	sta shapes_qx+1
	lda shapes_qx                     ; qx == W? off the right edge
	cmp SHP_W
	bne shapes_wrprobe
	lda shapes_qx+1
	cmp SHP_W+1
	beq shapes_wrdone
shapes_wrprobe
	jsr shapes_rd_q
	cmp shapes_tgt
	bne shapes_wrdone
	lda shapes_qx
	sta shapes_xr
	lda shapes_qx+1
	sta shapes_xr+1
	bra shapes_wright
shapes_wrdone
	lda shapes_xl                     ; fill the span: hline(xl, y, xr-xl+1)
	sta X16_P0
	lda shapes_xl+1
	sta X16_P1
	lda shapes_qy
	sta X16_P2
	lda shapes_qy+1
	sta X16_P3
	sec
	lda shapes_xr
	sbc shapes_xl
	sta X16_P4
	lda shapes_xr+1
	sbc shapes_xl+1
	sta X16_P5
	inc X16_P4
	bne +
	inc X16_P5
+	lda shapes_col
	jsr SHP_HLINE

	lda shapes_qy                     ; shapes_scanrow clobbers shapes_qy, so keep the filled
	sta shapes_row                    ; row here for BOTH neighbour scans
	lda shapes_qy+1
	sta shapes_row+1

	lda shapes_row                    ; the row above...
	sta shapes_ry
	lda shapes_row+1
	sta shapes_ry+1
	lda shapes_ry
	ora shapes_ry+1
	beq shapes_below                  ; row 0 has nothing above
	sec
	lda shapes_ry
	sbc #1
	sta shapes_ry
	lda shapes_ry+1
	sbc #0
	sta shapes_ry+1
	jsr shapes_scanrow
shapes_below
	clc                         ; ...and the row below
	lda shapes_row
	adc #1
	sta shapes_ry
	lda shapes_row+1
	adc #0
	sta shapes_ry+1
	lda shapes_ry                     ; ry == H? off the bottom
	cmp SHP_H
	bne shapes_bscan
	lda shapes_ry+1
	cmp SHP_H+1
	beq shapes_fnext
shapes_bscan
	jsr shapes_scanrow
shapes_fnext
	jmp shapes_floop
shapes_fexit
	lsr shapes_ovf                    ; overflow -> carry
	rts

; scan shapes_xl...xr on row shapes_ry for runs of target; push one seed per run
shapes_scanrow
	lda #0
	sta shapes_run
	lda shapes_xl
	sta shapes_tx
	lda shapes_xl+1
	sta shapes_tx+1
shapes_srloop
	lda shapes_tx                     ; read (tx, ry)
	sta shapes_qx
	lda shapes_tx+1
	sta shapes_qx+1
	lda shapes_ry
	sta shapes_qy
	lda shapes_ry+1
	sta shapes_qy+1
	jsr shapes_rd_q
	cmp shapes_tgt
	bne shapes_srmiss
	lda shapes_run                    ; entering a run: one seed
	bne shapes_srnext
	lda #1
	sta shapes_run
	jsr shapes_push
	bra shapes_srnext
shapes_srmiss
	lda #0
	sta shapes_run
shapes_srnext
	lda shapes_tx                     ; tx == xr? done
	cmp shapes_xr
	bne shapes_srinc
	lda shapes_tx+1
	cmp shapes_xr+1
	beq shapes_srdone
shapes_srinc
	inc shapes_tx
	bne shapes_srloop
	inc shapes_tx+1
	bra shapes_srloop
shapes_srdone
	rts

shapes_rd_q
	ldx #3
shapes_rq_l
	lda shapes_qx,x
	sta X16_P0,x
	dex
	bpl shapes_rq_l
	jmp SHP_READ

shapes_push
	lda shapes_sp
	cmp #FLOOD_MAX
	bcc +
	lda #1                      ; remembered; lsr at exit -> carry
	sta shapes_ovf
	rts
+	asl                         ; sp * 4
	asl
	tax
	lda shapes_qx
	sta shapes_stk,x
	lda shapes_qx+1
	sta shapes_stk+1,x
	lda shapes_qy
	sta shapes_stk+2,x
	lda shapes_qy+1
	sta shapes_stk+3,x
	inc shapes_sp
	rts

shapes_pop
	dec shapes_sp
	lda shapes_sp
	asl
	asl
	tax
	lda shapes_stk,x
	sta shapes_qx
	lda shapes_stk+1,x
	sta shapes_qx+1
	lda shapes_stk+2,x
	sta shapes_qy
	lda shapes_stk+3,x
	sta shapes_qy+1
	rts

; --- the state ---------------------------------------------------------
shapes_col
    .byte 0
shapes_cx
    .word 0
shapes_cy
    .word 0
shapes_x
    .byte 0
shapes_y
    .byte 0
shapes_a
    .byte 0
shapes_b
    .byte 0
shapes_sx
    .byte 0
shapes_sy
    .byte 0
shapes_err
    .word 0
shapes_t
    .word 0

shapes_efl
    .byte 0
shapes_ew
    .byte 0
shapes_eh
    .byte 0
shapes_ex
    .word 0
shapes_ey
    .byte 0
shapes_sm
    .byte 0
shapes_sq
    .word 0
shapes_edx
    .fill 4, 0
shapes_edy
    .fill 4, 0
shapes_eerr
    .fill 4, 0
shapes_ee2
    .fill 4, 0
shapes_e2a
    .fill 4, 0
shapes_e2b
    .fill 4, 0

shapes_tgt
    .byte 0
shapes_ovf
    .byte 0
shapes_sp
    .byte 0
shapes_qx
    .word 0
shapes_qy
    .word 0
shapes_xl
    .word 0
shapes_xr
    .word 0
shapes_ry
    .word 0
shapes_row
    .word 0
shapes_tx
    .word 0
shapes_run
    .byte 0
shapes_stk
    .fill FLOOD_MAX * 4, 0

; ---------------------------------------------------------------------
; shape_polygon / shape_fpolygon -- regular convex polygons (X16_USE_SHAPES_POLY)
; ---------------------------------------------------------------------
; A regular N-gon: N vertices evenly spaced on a circle of radius r about
; (cx, cy), the first at byte-angle `rotation` (0 = east, 64 = south, the
; sin8/cos8 convention). shape_polygon draws the outline through SHP_PSET
; (so it clips like shape_circle); shape_fpolygon fills it with SHP_HLINE
; spans (so it does NOT clip -- keep it on screen, like shape_disc).
;
;   in: P0/P1 = cx, P2/P3 = cy, P4 = radius (0-255),
;       P5 = sides (3..POLY_MAX; fewer draws nothing, more is clamped),
;       P6 = rotation (byte angle), A = colour
;
; Vertices come from sin8/cos8 (hence the X16_USE_MATH dependency) scaled
; by r and rounded. The fill is a per-scanline convex span fill: for each
; row it finds the two edge crossings and draws between them, half-open at
; the bottom row so tiled polygons do not double-paint a shared edge. It
; is a one-shot primitive (cost ~ sides * height), not a per-frame filler.
;
; House style, as everywhere in this file: all labels are zone-locals with
; unique names (ACME's _cheap locals do not reset at a zone-local routine
; label, so two routines could not each own an _loop), and the work is cut
; into small routines so no branch reaches past its 127-byte range.
; ---------------------------------------------------------------------
.endif

.if xuse_shapes_poly

POLY_MAX = 24                   ; vertices; the buffers below are 2 bytes each

shape_polygon
	sta poly_col
	stz poly_efl                ; outline
	jmp shapes_poly_begin
shape_fpolygon
	sta poly_col
	lda #1                      ; filled
	sta poly_efl
	; fall through
shapes_poly_begin
	lda X16_P5                  ; clamp the side count to 3..POLY_MAX
	cmp #3
	bcc shapes_pg_bret                ; fewer than 3: not a polygon
	cmp #(POLY_MAX + 1)
	bcc shapes_pg_bnok
	lda #POLY_MAX
shapes_pg_bnok
	sta poly_n
	lda X16_P0
	sta poly_cx
	lda X16_P1
	sta poly_cx+1
	lda X16_P2
	sta poly_cy
	lda X16_P3
	sta poly_cy+1
	lda X16_P4
	sta poly_r
	stz poly_acc                ; angle accumulator = rotation << 8
	lda X16_P6
	sta poly_acc+1
	jsr shapes_poly_verts
	lda poly_efl
	bne shapes_pg_bfill
	jmp shapes_poly_outline
shapes_pg_bfill
	jmp shapes_poly_fill
shapes_pg_bret
	rts

; compute the N vertices into poly_vx[]/poly_vy[]
shapes_poly_verts
	jsr shapes_poly_step              ; poly_step = 65536 / n
	stz poly_i
shapes_pg_vloop
	lda poly_i
	cmp poly_n
	beq shapes_pg_vend
	lda poly_acc+1              ; this vertex's byte angle
	pha
	jsr cos8                    ; A = cos * 127 (signed)
	jsr shapes_poly_scale             ; poly_off = round(r * A / 128), signed
	lda poly_i
	asl
	tax                         ; 2*i
	clc
	lda poly_cx
	adc poly_off
	sta poly_vx,x
	lda poly_cx+1
	adc poly_off+1
	sta poly_vx+1,x
	pla                         ; the angle again
	jsr sin8                    ; A = sin * 127 (signed)
	jsr shapes_poly_scale
	lda poly_i
	asl
	tax
	clc
	lda poly_cy
	adc poly_off
	sta poly_vy,x
	lda poly_cy+1
	adc poly_off+1
	sta poly_vy+1,x
	clc                         ; acc += step
	lda poly_acc
	adc poly_step
	sta poly_acc
	lda poly_acc+1
	adc poly_step+1
	sta poly_acc+1
	inc poly_i
	bra shapes_pg_vloop
shapes_pg_vend
	rts

; poly_off = round(poly_r * |A| / 128) with A's sign, A a signed byte
shapes_poly_scale
	stz poly_sgn
	pha
	and #$80
	beq shapes_pg_spos
	inc poly_sgn
	pla
	eor #$FF
	clc
	adc #1
	bra shapes_pg_smul
shapes_pg_spos
	pla
shapes_pg_smul
	jsr shapes_poly_mul8              ; poly_p16 = poly_r * |A|
	clc
	lda poly_p16                ; + 0.5 LSB, so >>7 rounds
	adc #64
	sta poly_p16
	lda poly_p16+1
	adc #0
	sta poly_p16+1
	lda poly_p16                ; >>7 (product < 32768, so one byte out)
	asl
	lda poly_p16+1
	rol
	sta poly_off
	stz poly_off+1
	lda poly_sgn
	beq shapes_pg_sdone
	sec                         ; negate
	lda #0
	sbc poly_off
	sta poly_off
	lda #0
	sbc poly_off+1
	sta poly_off+1
shapes_pg_sdone
	rts

; poly_p16 = poly_r * A  (8x8 -> 16, unsigned)
shapes_poly_mul8
	sta poly_t
	lda #0
	ldx #8
shapes_pg_mloop
	lsr poly_t
	bcc shapes_pg_mskip
	clc
	adc poly_r
shapes_pg_mskip
	ror
	ror poly_p16
	dex
	bne shapes_pg_mloop
	sta poly_p16+1
	rts

; poly_step = floor(65536 / poly_n), by restoring division of $010000
shapes_poly_step
	stz poly_dvd
	stz poly_dvd+1
	lda #1
	sta poly_dvd+2
	stz poly_rem
	stz poly_step
	stz poly_step+1
	ldx #24
shapes_pg_dloop
	asl poly_dvd
	rol poly_dvd+1
	rol poly_dvd+2
	rol poly_rem                ; carry = the remainder's 9th bit
	bcs shapes_pg_dsub                ; overflowed 8 bits: certainly >= n
	lda poly_rem
	cmp poly_n
	bcc shapes_pg_dnoq
shapes_pg_dsub
	lda poly_rem                ; carry is set on both paths here
	sbc poly_n
	sta poly_rem
	sec                         ; quotient bit = 1
	bra shapes_pg_dbit
shapes_pg_dnoq
	clc                         ; quotient bit = 0
shapes_pg_dbit
	rol poly_step
	rol poly_step+1
	dex
	bne shapes_pg_dloop
	rts

; --- outline ---------------------------------------------------------
shapes_poly_outline
	stz poly_i
shapes_pg_oloop
	lda poly_i                  ; endpoint 0 = vertex i
	asl
	tax
	lda poly_vx,x
	sta poly_lx0
	lda poly_vx+1,x
	sta poly_lx0+1
	lda poly_vy,x
	sta poly_ly0
	lda poly_vy+1,x
	sta poly_ly0+1
	lda poly_i                  ; endpoint 1 = vertex (i+1) mod n
	clc
	adc #1
	cmp poly_n
	bne shapes_pg_ojok
	lda #0
shapes_pg_ojok
	asl
	tax
	lda poly_vx,x
	sta poly_lx1
	lda poly_vx+1,x
	sta poly_lx1+1
	lda poly_vy,x
	sta poly_ly1
	lda poly_vy+1,x
	sta poly_ly1+1
	jsr shapes_poly_line
	inc poly_i
	lda poly_i
	cmp poly_n
	bne shapes_pg_oloop
	rts

; 16-bit Bresenham from (lx0,ly0) to (lx1,ly1), plotting through SHP_PSET
; (the gfx2h_line algorithm, engine-agnostic and clipping via the binding)
shapes_poly_line
	sec                         ; dx = |x1 - x0|, sx = direction
	lda poly_lx1
	sbc poly_lx0
	sta poly_ldx
	lda poly_lx1+1
	sbc poly_lx0+1
	sta poly_ldx+1
	bpl shapes_pg_ldxp
	sec
	lda #0
	sbc poly_ldx
	sta poly_ldx
	lda #0
	sbc poly_ldx+1
	sta poly_ldx+1
	lda #$FF
	sta poly_lsx
	sta poly_lsx+1
	bra shapes_pg_ldxd
shapes_pg_ldxp
	lda #1
	sta poly_lsx
	stz poly_lsx+1
shapes_pg_ldxd
	sec                         ; dy = -|y1 - y0|, sy = direction
	lda poly_ly1
	sbc poly_ly0
	sta poly_lt
	lda poly_ly1+1
	sbc poly_ly0+1
	sta poly_lt+1
	bpl shapes_pg_ldyp
	sec
	lda #0
	sbc poly_lt
	sta poly_lt
	lda #0
	sbc poly_lt+1
	sta poly_lt+1
	lda #$FF
	sta poly_lsy
	sta poly_lsy+1
	bra shapes_pg_ldyd
shapes_pg_ldyp
	lda #1
	sta poly_lsy
	stz poly_lsy+1
shapes_pg_ldyd
	sec                         ; ldy = -|dy|
	lda #0
	sbc poly_lt
	sta poly_ldy
	lda #0
	sbc poly_lt+1
	sta poly_ldy+1
	clc                         ; err = dx + dy
	lda poly_ldx
	adc poly_ldy
	sta poly_lerr
	lda poly_ldx+1
	adc poly_ldy+1
	sta poly_lerr+1
shapes_pg_lloop
	lda poly_lx0
	sta X16_P0
	lda poly_lx0+1
	sta X16_P1
	lda poly_ly0
	sta X16_P2
	lda poly_ly0+1
	sta X16_P3
	lda poly_col
	jsr SHP_PSET
	lda poly_lx0                ; reached the endpoint?
	cmp poly_lx1
	bne shapes_pg_lstep
	lda poly_lx0+1
	cmp poly_lx1+1
	bne shapes_pg_lstep
	lda poly_ly0
	cmp poly_ly1
	bne shapes_pg_lstep
	lda poly_ly0+1
	cmp poly_ly1+1
	bne shapes_pg_lstep
	rts
shapes_pg_lstep
	lda poly_lerr               ; e2 = 2 * err
	asl
	sta poly_le2
	lda poly_lerr+1
	rol
	sta poly_le2+1
	sec                         ; e2 >= dy ?  err += dy, x0 += sx
	lda poly_le2
	sbc poly_ldy
	lda poly_le2+1
	sbc poly_ldy+1
	bvc shapes_pg_lnv1
	eor #$80
shapes_pg_lnv1
	bmi shapes_pg_lskx
	clc
	lda poly_lerr
	adc poly_ldy
	sta poly_lerr
	lda poly_lerr+1
	adc poly_ldy+1
	sta poly_lerr+1
	clc
	lda poly_lx0
	adc poly_lsx
	sta poly_lx0
	lda poly_lx0+1
	adc poly_lsx+1
	sta poly_lx0+1
shapes_pg_lskx
	sec                         ; e2 <= dx ?  err += dx, y0 += sy
	lda poly_ldx
	sbc poly_le2
	lda poly_ldx+1
	sbc poly_le2+1
	bvc shapes_pg_lnv2
	eor #$80
shapes_pg_lnv2
	bmi shapes_pg_lsky
	clc
	lda poly_lerr
	adc poly_ldx
	sta poly_lerr
	lda poly_lerr+1
	adc poly_ldx+1
	sta poly_lerr+1
	clc
	lda poly_ly0
	adc poly_lsy
	sta poly_ly0
	lda poly_ly0+1
	adc poly_lsy+1
	sta poly_ly0+1
shapes_pg_lsky
	jmp shapes_pg_lloop

; --- fill ------------------------------------------------------------
; one scanline at a time; shapes_poly_scanline gathers the row's span and draws
; it, shapes_poly_edge does the per-edge crossing. Kept apart so every branch
; stays in range and each routine owns its own zone-local labels.
shapes_poly_fill
	jsr shapes_poly_ybounds           ; poly_ymin / poly_ymax over all vertices
	lda poly_ymin
	sta poly_y
	lda poly_ymin+1
	sta poly_y+1
shapes_pg_floop
	lda poly_ymax               ; y > ymax ? done
	cmp poly_y
	lda poly_ymax+1
	sbc poly_y+1
	bvc shapes_pg_fl1
	eor #$80
shapes_pg_fl1
	bmi shapes_pg_fret                ; ymax < y
	jsr shapes_poly_scanline
	inc poly_y
	bne shapes_pg_floop
	inc poly_y+1
	bra shapes_pg_floop
shapes_pg_fret
	rts

; fill row poly_y: find the span (xl..xr) across the edges, draw it
shapes_poly_scanline
	stz poly_found
	lda #$FF                    ; xl = +32767, xr = -32768
	sta poly_xl
	lda #$7F
	sta poly_xl+1
	stz poly_xr
	lda #$80
	sta poly_xr+1
	stz poly_i
shapes_pg_slloop
	lda poly_i
	cmp poly_n
	beq shapes_pg_sldraw
	jsr shapes_poly_edge
	inc poly_i
	bra shapes_pg_slloop
shapes_pg_sldraw
	lda poly_found
	beq shapes_pg_slret
	lda poly_xl                 ; span (xl .. xr) on row y
	sta X16_P0
	lda poly_xl+1
	sta X16_P1
	lda poly_y
	sta X16_P2
	lda poly_y+1
	sta X16_P3
	sec                         ; len = xr - xl + 1
	lda poly_xr
	sbc poly_xl
	sta X16_P4
	lda poly_xr+1
	sbc poly_xl+1
	sta X16_P5
	inc X16_P4
	bne shapes_pg_sllen
	inc X16_P5
shapes_pg_sllen
	lda poly_col
	jmp SHP_HLINE
shapes_pg_slret
	rts

; edge poly_i crossing row poly_y: if it spans the row, fold its x into
; poly_xl (min) / poly_xr (max) and set poly_found
shapes_poly_edge
	lda poly_i                  ; vertex a = i
	asl
	tax
	lda poly_i                  ; vertex b = (i+1) mod n
	clc
	adc #1
	cmp poly_n
	bne shapes_pg_ejok
	lda #0
shapes_pg_ejok
	asl
	tay
	lda poly_vx,x
	sta poly_xa
	lda poly_vx+1,x
	sta poly_xa+1
	lda poly_vy,x
	sta poly_ya
	lda poly_vy+1,x
	sta poly_ya+1
	lda poly_vx,y
	sta poly_xb
	lda poly_vx+1,y
	sta poly_xb+1
	lda poly_vy,y
	sta poly_yb
	lda poly_vy+1,y
	sta poly_yb+1
	lda poly_ya                 ; top = the smaller-y endpoint
	cmp poly_yb
	lda poly_ya+1
	sbc poly_yb+1
	bvc shapes_pg_escab
	eor #$80
shapes_pg_escab
	bmi shapes_pg_eatop               ; ya < yb
	lda poly_xb                 ; b on top
	sta poly_xtop
	lda poly_xb+1
	sta poly_xtop+1
	lda poly_yb
	sta poly_ytop
	lda poly_yb+1
	sta poly_ytop+1
	lda poly_xa
	sta poly_xbot
	lda poly_xa+1
	sta poly_xbot+1
	lda poly_ya
	sta poly_ybot
	lda poly_ya+1
	sta poly_ybot+1
	bra shapes_pg_eedge
shapes_pg_eatop
	lda poly_xa                 ; a on top
	sta poly_xtop
	lda poly_xa+1
	sta poly_xtop+1
	lda poly_ya
	sta poly_ytop
	lda poly_ya+1
	sta poly_ytop+1
	lda poly_xb
	sta poly_xbot
	lda poly_xb+1
	sta poly_xbot+1
	lda poly_yb
	sta poly_ybot
	lda poly_yb+1
	sta poly_ybot+1
shapes_pg_eedge
	lda poly_y                  ; y < ytop ? out (also skips horizontals)
	cmp poly_ytop
	lda poly_y+1
	sbc poly_ytop+1
	bvc shapes_pg_esct
	eor #$80
shapes_pg_esct
	bmi shapes_pg_eout
	lda poly_y                  ; y >= ybot ? out (half-open bottom)
	cmp poly_ybot
	lda poly_y+1
	sbc poly_ybot+1
	bvc shapes_pg_escb
	eor #$80
shapes_pg_escb
	bpl shapes_pg_eout
	bra shapes_pg_ein
shapes_pg_eout
	rts
shapes_pg_ein
	sec                         ; md3 = dy = ybot - ytop  (> 0)
	lda poly_ybot
	sbc poly_ytop
	sta poly_md3
	lda poly_ybot+1
	sbc poly_ytop+1
	sta poly_md3+1
	sec                         ; md2 = t = y - ytop
	lda poly_y
	sbc poly_ytop
	sta poly_md2
	lda poly_y+1
	sbc poly_ytop+1
	sta poly_md2+1
	sec                         ; md1 = dx = xbot - xtop (signed)
	lda poly_xbot
	sbc poly_xtop
	sta poly_md1
	lda poly_xbot+1
	sbc poly_xtop+1
	sta poly_md1+1
	stz poly_dxs
	lda poly_md1+1
	bpl shapes_pg_edxpos
	inc poly_dxs                ; dx < 0: take |dx|, remember the sign
	sec
	lda #0
	sbc poly_md1
	sta poly_md1
	lda #0
	sbc poly_md1+1
	sta poly_md1+1
shapes_pg_edxpos
	jsr shapes_poly_umuldiv           ; poly_mdq = |dx| * t / dy
	lda poly_dxs
	bne shapes_pg_exneg
	clc                         ; x = xtop + mdq
	lda poly_xtop
	adc poly_mdq
	sta poly_x
	lda poly_xtop+1
	adc poly_mdq+1
	sta poly_x+1
	bra shapes_pg_egotx
shapes_pg_exneg
	sec                         ; x = xtop - mdq
	lda poly_xtop
	sbc poly_mdq
	sta poly_x
	lda poly_xtop+1
	sbc poly_mdq+1
	sta poly_x+1
shapes_pg_egotx
	lda #1
	sta poly_found
	lda poly_x                  ; xl = min(xl, x)
	cmp poly_xl
	lda poly_x+1
	sbc poly_xl+1
	bvc shapes_pg_escl
	eor #$80
shapes_pg_escl
	bpl shapes_pg_enoxl               ; x >= xl
	lda poly_x
	sta poly_xl
	lda poly_x+1
	sta poly_xl+1
shapes_pg_enoxl
	lda poly_xr                 ; xr = max(xr, x)
	cmp poly_x
	lda poly_xr+1
	sbc poly_x+1
	bvc shapes_pg_escr
	eor #$80
shapes_pg_escr
	bpl shapes_pg_enoxr               ; xr >= x
	lda poly_x
	sta poly_xr
	lda poly_x+1
	sta poly_xr+1
shapes_pg_enoxr
	rts

; poly_ymin / poly_ymax = the y extent of the vertices
shapes_poly_ybounds
	lda poly_vy
	sta poly_ymin
	sta poly_ymax
	lda poly_vy+1
	sta poly_ymin+1
	sta poly_ymax+1
	lda #1
	sta poly_i
shapes_pg_ybloop
	lda poly_i
	cmp poly_n
	beq shapes_pg_ybend
	asl
	tax
	lda poly_vy,x               ; vy[i] < ymin ?
	cmp poly_ymin
	lda poly_vy+1,x
	sbc poly_ymin+1
	bvc shapes_pg_ybc1
	eor #$80
shapes_pg_ybc1
	bpl shapes_pg_ybnmin
	lda poly_vy,x
	sta poly_ymin
	lda poly_vy+1,x
	sta poly_ymin+1
shapes_pg_ybnmin
	lda poly_ymax               ; vy[i] > ymax ?
	cmp poly_vy,x
	lda poly_ymax+1
	sbc poly_vy+1,x
	bvc shapes_pg_ybc2
	eor #$80
shapes_pg_ybc2
	bpl shapes_pg_ybnmax
	lda poly_vy,x
	sta poly_ymax
	lda poly_vy+1,x
	sta poly_ymax+1
shapes_pg_ybnmax
	inc poly_i
	bra shapes_pg_ybloop
shapes_pg_ybend
	rts

; poly_mdq = poly_md1 * poly_md2 / poly_md3, all unsigned (16x16->32, /16)
shapes_poly_umuldiv
	stz poly_prod+2
	stz poly_prod+3
	ldx #16
shapes_pg_uml
	lsr poly_md2+1
	ror poly_md2
	bcc shapes_pg_unoadd
	lda poly_prod+2
	clc
	adc poly_md1
	sta poly_prod+2
	lda poly_prod+3
	adc poly_md1+1
	bra shapes_pg_urot
shapes_pg_unoadd
	lda poly_prod+3
shapes_pg_urot
	ror
	sta poly_prod+3
	ror poly_prod+2
	ror poly_prod+1
	ror poly_prod
	dex
	bne shapes_pg_uml
	stz poly_rem
	stz poly_rem+1
	ldx #32
shapes_pg_udv
	asl poly_prod
	rol poly_prod+1
	rol poly_prod+2
	rol poly_prod+3
	rol poly_rem
	rol poly_rem+1
	sec
	lda poly_rem
	sbc poly_md3
	tay
	lda poly_rem+1
	sbc poly_md3+1
	bcc shapes_pg_udvno
	sta poly_rem+1
	sty poly_rem
	inc poly_prod
shapes_pg_udvno
	dex
	bne shapes_pg_udv
	lda poly_prod
	sta poly_mdq
	lda poly_prod+1
	sta poly_mdq+1
	rts

; --- polygon state ---------------------------------------------------
poly_col   .byte 0
poly_efl   .byte 0
poly_cx    .word 0
poly_cy    .word 0
poly_r     .byte 0
poly_n     .byte 0
poly_i     .byte 0
poly_acc   .word 0
poly_step  .word 0
poly_off   .word 0
poly_sgn   .byte 0
poly_p16   .word 0
poly_t     .byte 0
poly_dvd   .fill 3, 0
poly_rem   .word 0
poly_vx    .fill POLY_MAX * 2, 0
poly_vy    .fill POLY_MAX * 2, 0

poly_lx0   .word 0
poly_ly0   .word 0
poly_lx1   .word 0
poly_ly1   .word 0
poly_ldx   .word 0
poly_ldy   .word 0
poly_lerr  .word 0
poly_le2   .word 0
poly_lsx   .word 0
poly_lsy   .word 0
poly_lt    .word 0

poly_ymin  .word 0
poly_ymax  .word 0
poly_y     .word 0
poly_found .byte 0
poly_xa    .word 0
poly_ya    .word 0
poly_xb    .word 0
poly_yb    .word 0
poly_xtop  .word 0
poly_ytop  .word 0
poly_xbot  .word 0
poly_ybot  .word 0
poly_x     .word 0
poly_xl    .word 0
poly_xr    .word 0
poly_dxs   .byte 0
poly_md1   .word 0
poly_md2   .word 0
poly_md3   .word 0
poly_mdq   .word 0
poly_prod  .fill 4, 0

.endif

; ---------------------------------------------------------------------
; shp_line -- shared 16-bit Bresenham (X16_USE_SHP_LINE)
; ---------------------------------------------------------------------
; The curve shapes (arc, bezier) sample a handful of points and join
; them; this is the join. It is the same engine-agnostic gfx2h_line walk
; the polygon carries privately (shapes_poly_line), lifted out so arc and
; bezier share ONE copy behind their own gate. A program that wants only
; the polygon still pays nothing for this; one that wants an arc pays for
; it once, not once per curve.
;
;   in: shl_x0/shl_y0 -> shl_x1/shl_y1 (signed words), shl_col = colour
;       draws through SHP_PSET, so it clips wherever pset clips.
; ---------------------------------------------------------------------
.if xuse_shp_line

shp_line
	sec                         ; dx = |x1 - x0|, sx = direction
	lda shl_x1
	sbc shl_x0
	sta shl_dx
	lda shl_x1+1
	sbc shl_x0+1
	sta shl_dx+1
	bpl shapes_sl_dxp
	sec
	lda #0
	sbc shl_dx
	sta shl_dx
	lda #0
	sbc shl_dx+1
	sta shl_dx+1
	lda #$FF
	sta shl_sx
	sta shl_sx+1
	bra shapes_sl_dxd
shapes_sl_dxp
	lda #1
	sta shl_sx
	stz shl_sx+1
shapes_sl_dxd
	sec                         ; dy = -|y1 - y0|, sy = direction
	lda shl_y1
	sbc shl_y0
	sta shl_t
	lda shl_y1+1
	sbc shl_y0+1
	sta shl_t+1
	bpl shapes_sl_dyp
	sec
	lda #0
	sbc shl_t
	sta shl_t
	lda #0
	sbc shl_t+1
	sta shl_t+1
	lda #$FF
	sta shl_sy
	sta shl_sy+1
	bra shapes_sl_dyd
shapes_sl_dyp
	lda #1
	sta shl_sy
	stz shl_sy+1
shapes_sl_dyd
	sec                         ; dy stored negative
	lda #0
	sbc shl_t
	sta shl_dy
	lda #0
	sbc shl_t+1
	sta shl_dy+1
	clc                         ; err = dx + dy
	lda shl_dx
	adc shl_dy
	sta shl_err
	lda shl_dx+1
	adc shl_dy+1
	sta shl_err+1
shapes_sl_loop
	lda shl_x0
	sta X16_P0
	lda shl_x0+1
	sta X16_P1
	lda shl_y0
	sta X16_P2
	lda shl_y0+1
	sta X16_P3
	lda shl_col
	jsr SHP_PSET
	lda shl_x0                  ; reached the endpoint?
	cmp shl_x1
	bne shapes_sl_step
	lda shl_x0+1
	cmp shl_x1+1
	bne shapes_sl_step
	lda shl_y0
	cmp shl_y1
	bne shapes_sl_step
	lda shl_y0+1
	cmp shl_y1+1
	bne shapes_sl_step
	rts
shapes_sl_step
	lda shl_err                 ; e2 = 2 * err
	asl
	sta shl_e2
	lda shl_err+1
	rol
	sta shl_e2+1
	sec                         ; e2 >= dy ?  err += dy, x0 += sx
	lda shl_e2
	sbc shl_dy
	lda shl_e2+1
	sbc shl_dy+1
	bvc shapes_sl_nv1
	eor #$80
shapes_sl_nv1
	bmi shapes_sl_skx
	clc
	lda shl_err
	adc shl_dy
	sta shl_err
	lda shl_err+1
	adc shl_dy+1
	sta shl_err+1
	clc
	lda shl_x0
	adc shl_sx
	sta shl_x0
	lda shl_x0+1
	adc shl_sx+1
	sta shl_x0+1
shapes_sl_skx
	sec                         ; e2 <= dx ?  err += dx, y0 += sy
	lda shl_dx
	sbc shl_e2
	lda shl_dx+1
	sbc shl_e2+1
	bvc shapes_sl_nv2
	eor #$80
shapes_sl_nv2
	bmi shapes_sl_sky
	clc
	lda shl_err
	adc shl_dx
	sta shl_err
	lda shl_err+1
	adc shl_dx+1
	sta shl_err+1
	clc
	lda shl_y0
	adc shl_sy
	sta shl_y0
	lda shl_y0+1
	adc shl_sy+1
	sta shl_y0+1
shapes_sl_sky
	jmp shapes_sl_loop

shl_x0  .word 0
shl_y0  .word 0
shl_x1  .word 0
shl_y1  .word 0
shl_col .byte 0
shl_dx  .word 0
shl_dy  .word 0
shl_sx  .word 0
shl_sy  .word 0
shl_err .word 0
shl_e2  .word 0
shl_t   .word 0

.endif

; ---------------------------------------------------------------------
; shape_rrect / shape_frrect -- rounded rectangle (X16_USE_SHAPES_RRECT)
; ---------------------------------------------------------------------
; A rectangle with quarter-circle corners. Self-contained: the corners
; come from a midpoint circle walk (no trig, no MATH dependency), the
; straight runs from SHP_HLINE / SHP_PSET.
;
;   in: rr_x/rr_y = top-left corner (signed words),
;       rr_w/rr_h = width / height (words, >= 1),
;       rr_r      = corner radius (0-255, clamped to min(w,h)/2),
;       A         = colour
;
; shape_rrect draws the outline through SHP_PSET (so it clips like
; shape_circle); shape_frrect fills it with SHP_HLINE spans (so it does
; NOT clip -- keep it on screen, like shape_disc). r = 0 degenerates to
; a plain rectangle.
;
; The fill precomputes rr_ext[d] = the corner's horizontal half-extent at
; vertical offset d (0..r) once, then draws one span per row: full width
; in the straight middle band, inset by rr_ext[d] through the rounded
; top and bottom bands.
; ---------------------------------------------------------------------
.if xuse_shapes_rrect

shape_rrect
	sta rr_col
	stz rr_fl
	jmp shapes_rr_begin
shape_frrect
	sta rr_col
	lda #1
	sta rr_fl
shapes_rr_begin
	lda rr_x                    ; corner reference points:
	sta rr_x0                   ;   x0 = x, x1 = x + w - 1
	lda rr_x+1
	sta rr_x0+1
	clc
	lda rr_x
	adc rr_w
	sta rr_x1
	lda rr_x+1
	adc rr_w+1
	sta rr_x1+1
	lda rr_x1                   ; x1 -= 1
	bne +
	dec rr_x1+1
+	dec rr_x1
	lda rr_y                    ;   y0 = y, y1 = y + h - 1
	sta rr_y0
	lda rr_y+1
	sta rr_y0+1
	clc
	lda rr_y
	adc rr_h
	sta rr_y1
	lda rr_y+1
	adc rr_h+1
	sta rr_y1+1
	lda rr_y1                   ; y1 -= 1
	bne +
	dec rr_y1+1
+	dec rr_y1

	jsr shapes_rr_clampr              ; rr_r = min(rr_r, min(w,h)/2)
	lda rr_x0                   ; corner centres:
	clc                         ;   cxl = x0 + r, cxr = x1 - r
	adc rr_r
	sta rr_cxl
	lda rr_x0+1
	adc #0
	sta rr_cxl+1
	sec
	lda rr_x1
	sbc rr_r
	sta rr_cxr
	lda rr_x1+1
	sbc #0
	sta rr_cxr+1
	lda rr_y0                   ;   cyt = y0 + r, cyb = y1 - r
	clc
	adc rr_r
	sta rr_cyt
	lda rr_y0+1
	adc #0
	sta rr_cyt+1
	sec
	lda rr_y1
	sbc rr_r
	sta rr_cyb
	lda rr_y1+1
	sbc #0
	sta rr_cyb+1

	lda rr_fl
	beq shapes_rr_out
	jmp shapes_rr_fill
shapes_rr_out
	jmp shapes_rr_outline

; rr_r = min(rr_r, min(rr_w, rr_h) / 2)
shapes_rr_clampr
	lda rr_w                    ; m = min(w, h)  (16-bit unsigned)
	sta rr_m
	lda rr_w+1
	sta rr_m+1
	lda rr_h+1
	cmp rr_m+1
	bcc shapes_rr_cmh
	bne shapes_rr_cmok
	lda rr_h
	cmp rr_m
	bcs shapes_rr_cmok
shapes_rr_cmh
	lda rr_h
	sta rr_m
	lda rr_h+1
	sta rr_m+1
shapes_rr_cmok
	lsr rr_m+1                  ; m /= 2
	ror rr_m
	lda rr_m+1                  ; m >= 256 ? radius already fits any byte
	bne shapes_rr_crok
	lda rr_r                    ; r > m ? clamp to m
	cmp rr_m
	bcc shapes_rr_crok
	lda rr_m
	sta rr_r
shapes_rr_crok
	rts

; --- outline ---------------------------------------------------------
shapes_rr_outline
	jsr shapes_rr_corners             ; the four quarter-circle corners
	; top edge: (cxl, y0) .. (cxr, y0)
	lda rr_cxl
	sta X16_P0
	lda rr_cxl+1
	sta X16_P1
	lda rr_y0
	sta X16_P2
	lda rr_y0+1
	sta X16_P3
	jsr shapes_rr_hspan               ; pset run from P0 to cxr on row P2/P3
	; bottom edge: (cxl, y1) .. (cxr, y1)
	lda rr_cxl
	sta X16_P0
	lda rr_cxl+1
	sta X16_P1
	lda rr_y1
	sta X16_P2
	lda rr_y1+1
	sta X16_P3
	jsr shapes_rr_hspan
	; left edge: column x0, rows cyt..cyb
	lda rr_x0
	sta X16_P0
	lda rr_x0+1
	sta X16_P1
	jsr shapes_rr_vspan
	; right edge: column x1, rows cyt..cyb
	lda rr_x1
	sta X16_P0
	lda rr_x1+1
	sta X16_P1
	jsr shapes_rr_vspan
	rts

; pset a horizontal run from (P0/P1) to x=rr_cxr on the row in P2/P3
shapes_rr_hspan
	sec                         ; empty run when cxr < cxl (r reaches w/2):
	lda rr_cxr                  ; the rounded ends meet, no straight top/bottom
	sbc rr_cxl
	lda rr_cxr+1
	sbc rr_cxl+1
	bvc +
	eor #$80
+	bmi shapes_rr_hsd
	lda X16_P2                  ; hold the row (pset reloads P0..P3)
	sta rr_ry
	lda X16_P3
	sta rr_ry+1
shapes_rr_hsl
	lda rr_ry
	sta X16_P2
	lda rr_ry+1
	sta X16_P3
	lda rr_col
	jsr SHP_PSET
	lda X16_P0                  ; at cxr ?
	cmp rr_cxr
	bne shapes_rr_hsn
	lda X16_P1
	cmp rr_cxr+1
	beq shapes_rr_hsd
shapes_rr_hsn
	inc X16_P0
	bne shapes_rr_hsl
	inc X16_P1
	bra shapes_rr_hsl
shapes_rr_hsd
	rts

; pset a vertical run on column (P0/P1) from y=rr_cyt to y=rr_cyb
shapes_rr_vspan
	sec                         ; empty run when cyb < cyt (r reaches h/2):
	lda rr_cyb                  ; the rounded ends meet, no straight sides
	sbc rr_cyt
	lda rr_cyb+1
	sbc rr_cyt+1
	bvc +
	eor #$80
+	bmi shapes_rr_vsd
	lda X16_P0
	sta rr_rx
	lda X16_P1
	sta rr_rx+1
	lda rr_cyt
	sta X16_P2
	lda rr_cyt+1
	sta X16_P3
shapes_rr_vsl
	lda rr_rx
	sta X16_P0
	lda rr_rx+1
	sta X16_P1
	lda rr_col
	jsr SHP_PSET
	lda X16_P2                  ; at cyb ?
	cmp rr_cyb
	bne shapes_rr_vsn
	lda X16_P3
	cmp rr_cyb+1
	beq shapes_rr_vsd
shapes_rr_vsn
	inc X16_P2
	bne shapes_rr_vsl
	inc X16_P3
	bra shapes_rr_vsl
shapes_rr_vsd
	rts

; walk the quarter circle once; each octant point plots at all 4 corners
shapes_rr_corners
	lda rr_r                    ; x = r, y = 0, err = 1 - r
	sta rr_wx
	stz rr_wy
	sec
	lda #1
	sbc rr_r
	sta rr_werr
	lda #0
	sbc #0
	sta rr_werr+1
shapes_rr_cwl
	lda rr_wy                   ; while y <= x
	cmp rr_wx
	beq shapes_rr_cwp
	bcs shapes_rr_cwd
shapes_rr_cwp
	lda rr_wx                   ; plot (a,b) = (x,y) and (y,x) at 4 corners
	sta rr_ca
	lda rr_wy
	sta rr_cb
	jsr shapes_rr_c4
	lda rr_wy
	sta rr_ca
	lda rr_wx
	sta rr_cb
	jsr shapes_rr_c4
	jsr shapes_rr_wstep
	bra shapes_rr_cwl
shapes_rr_cwd
	rts

; plot (a,b) offsets at the four corner centres
shapes_rr_c4
	sec                         ; TL: (cxl - a, cyt - b)
	lda rr_cxl
	sbc rr_ca
	sta X16_P0
	lda rr_cxl+1
	sbc #0
	sta X16_P1
	sec
	lda rr_cyt
	sbc rr_cb
	sta X16_P2
	lda rr_cyt+1
	sbc #0
	sta X16_P3
	lda rr_col
	jsr SHP_PSET
	clc                         ; TR: (cxr + a, cyt - b)
	lda rr_cxr
	adc rr_ca
	sta X16_P0
	lda rr_cxr+1
	adc #0
	sta X16_P1
	sec
	lda rr_cyt
	sbc rr_cb
	sta X16_P2
	lda rr_cyt+1
	sbc #0
	sta X16_P3
	lda rr_col
	jsr SHP_PSET
	sec                         ; BL: (cxl - a, cyb + b)
	lda rr_cxl
	sbc rr_ca
	sta X16_P0
	lda rr_cxl+1
	sbc #0
	sta X16_P1
	clc
	lda rr_cyb
	adc rr_cb
	sta X16_P2
	lda rr_cyb+1
	adc #0
	sta X16_P3
	lda rr_col
	jsr SHP_PSET
	clc                         ; BR: (cxr + a, cyb + b)
	lda rr_cxr
	adc rr_ca
	sta X16_P0
	lda rr_cxr+1
	adc #0
	sta X16_P1
	clc
	lda rr_cyb
	adc rr_cb
	sta X16_P2
	lda rr_cyb+1
	adc #0
	sta X16_P3
	lda rr_col
	jmp SHP_PSET

; midpoint error walk shared by shapes_rr_corners and the fill's table build
shapes_rr_wstep
	inc rr_wy
	bit rr_werr+1
	bmi shapes_rr_wgrow
	dec rr_wx
	sec                         ; t = y - x
	lda rr_wy
	sbc rr_wx
	sta rr_wt
	lda #0
	sbc #0
	sta rr_wt+1
	bra shapes_rr_wap
shapes_rr_wgrow
	lda rr_wy                   ; t = y
	sta rr_wt
	lda #0
	sta rr_wt+1
shapes_rr_wap
	asl rr_wt                   ; err += 2t + 1
	rol rr_wt+1
	inc rr_wt
	bne +
	inc rr_wt+1
+	clc
	lda rr_werr
	adc rr_wt
	sta rr_werr
	lda rr_werr+1
	adc rr_wt+1
	sta rr_werr+1
	rts

; --- fill ------------------------------------------------------------
shapes_rr_fill
	jsr shapes_rr_build               ; rr_ext[0..r] = corner half-extents
	lda rr_y0                   ; row = y0
	sta rr_ry
	lda rr_y0+1
	sta rr_ry+1
shapes_rr_fl
	lda rr_y1                   ; row > y1 ? done
	cmp rr_ry
	lda rr_y1+1
	sbc rr_ry+1
	bvc +
	eor #$80
+	bmi shapes_rr_fld
	jsr shapes_rr_row
	inc rr_ry
	bne shapes_rr_fl
	inc rr_ry+1
	bra shapes_rr_fl
shapes_rr_fld
	rts

; draw the one span for row rr_ry: full width in the middle band, inset
; by rr_ext[d] in the rounded top/bottom bands
shapes_rr_row
	lda rr_ry                   ; row < cyt ?  top rounded band, d = cyt-row
	cmp rr_cyt
	lda rr_ry+1
	sbc rr_cyt+1
	bvc +
	eor #$80
+	bmi shapes_rr_rtop
	lda rr_cyb                  ; row > cyb ?  bottom band, d = row-cyb
	cmp rr_ry
	lda rr_cyb+1
	sbc rr_ry+1
	bvc +
	eor #$80
+	bmi shapes_rr_rbot
	ldx #0                      ; middle band: d = 0, ext[0] = r -> full width
	beq shapes_rr_inset               ; (always: ldx #0 set Z)
shapes_rr_rtop
	sec                         ; d = cyt - row (1..r)
	lda rr_cyt
	sbc rr_ry
	tax
	bra shapes_rr_inset
shapes_rr_rbot
	sec                         ; d = row - cyb (1..r)
	lda rr_ry
	sbc rr_cyb
	tax
shapes_rr_inset
	lda rr_ext,x                ; ins = rr_ext[d]
	sta rr_ins
	stz rr_ins+1
	sec                         ; P0 = left = cxl - ins
	lda rr_cxl
	sbc rr_ins
	sta X16_P0
	lda rr_cxl+1
	sbc #0
	sta X16_P1
	lda rr_ry                   ; row
	sta X16_P2
	lda rr_ry+1
	sta X16_P3
	clc                         ; right = cxr + ins  -> T0
	lda rr_cxr
	adc rr_ins
	sta X16_T0
	lda rr_cxr+1
	adc rr_ins+1
	sta X16_T0+1
	sec                         ; len = right - left + 1
	lda X16_T0
	sbc X16_P0
	sta X16_P4
	lda X16_T0+1
	sbc X16_P1
	sta X16_P5
	inc X16_P4
	bne +
	inc X16_P5
+	lda rr_col
	jmp SHP_HLINE

; rr_ext[d] = corner half-extent at vertical offset d, for d = 0..r
shapes_rr_build
	ldx #0                      ; zero rr_ext[0..255]
	lda #0
shapes_rr_bz
	sta rr_ext,x
	inx
	bne shapes_rr_bz
	lda rr_r                    ; ext[0] = r
	sta rr_ext
	lda rr_r                    ; walk the quarter circle
	sta rr_wx
	stz rr_wy
	sec
	lda #1
	sbc rr_r
	sta rr_werr
	lda #0
	sbc #0
	sta rr_werr+1
shapes_rr_bwl
	lda rr_wy                   ; while y <= x
	cmp rr_wx
	beq shapes_rr_bwp
	bcs shapes_rr_bwd
shapes_rr_bwp
	ldx rr_wy                   ; ext[y] = max(ext[y], x)
	lda rr_wx
	cmp rr_ext,x
	bcc +
	sta rr_ext,x
+	ldx rr_wx                   ; ext[x] = max(ext[x], y)
	lda rr_wy
	cmp rr_ext,x
	bcc +
	sta rr_ext,x
+	jsr shapes_rr_wstep
	bra shapes_rr_bwl
shapes_rr_bwd
	rts

; --- rounded-rect state ----------------------------------------------
rr_x    .word 0
rr_y    .word 0
rr_w    .word 0
rr_h    .word 0
rr_r    .byte 0
rr_col  .byte 0
rr_fl   .byte 0
rr_x0   .word 0
rr_y0   .word 0
rr_x1   .word 0
rr_y1   .word 0
rr_cxl  .word 0
rr_cxr  .word 0
rr_cyt  .word 0
rr_cyb  .word 0
rr_m    .word 0
rr_ry   .word 0
rr_rx   .word 0
rr_ins  .word 0
rr_ca   .byte 0
rr_cb   .byte 0
rr_wx   .byte 0
rr_wy   .byte 0
rr_werr .word 0
rr_wt   .word 0
rr_ext  .fill 256, 0

.endif

; ---------------------------------------------------------------------
; shape_arc -- a portion of a circle outline (X16_USE_SHAPES_ARC)
; ---------------------------------------------------------------------
; The arc runs from byte-angle `start` to `end`, increasing (0 = east,
; 64 = south, 128 = west, 192 = north -- the sin8/cos8, screen-y-down
; convention shared with the polygon). It is sampled every ~4 byte-angle
; units and the samples are joined with shp_line, so the chord error is
; under a third of a pixel even at r = 255 and the arc clips wherever
; SHP_PSET clips. When start == end the whole circle is drawn.
;
;   in: P0/P1 = cx, P2/P3 = cy, P4 = r (0-255),
;       P5 = start angle, P6 = end angle, A = colour
;
; shapes_arc_point / shapes_arc_scale place a sample the same way the polygon places
; a vertex (r * cos8/sin8 / 128, rounded); shape_pie reuses them, which
; is why they live in this gate and PIE depends on ARC.
; ---------------------------------------------------------------------
.if xuse_shapes_arc

ARC_STEP = 4                    ; byte-angle units between samples

shape_arc
	sta shl_col                 ; shp_line draws in this colour
	lda X16_P0
	sta arc_cx
	lda X16_P1
	sta arc_cx+1
	lda X16_P2
	sta arc_cy
	lda X16_P3
	sta arc_cy+1
	lda X16_P4
	sta arc_r
	lda X16_P5
	sta arc_a0
	sec                         ; span = (end - start) & 255; 0 -> 256
	lda X16_P6
	sbc arc_a0
	sta arc_span
	stz arc_span+1
	lda arc_span
	bne shapes_ar_have
	inc arc_span+1
shapes_ar_have
	lda arc_a0                  ; first sample -> shl_x0/y0 (prev point)
	jsr shapes_arc_point
	lda arc_px
	sta shl_x0
	lda arc_px+1
	sta shl_x0+1
	lda arc_py
	sta shl_y0
	lda arc_py+1
	sta shl_y0+1
	lda arc_a0
	sta arc_ang
shapes_ar_loop
	lda arc_span+1              ; step = min(ARC_STEP, span)
	bne shapes_ar_full
	lda arc_span
	cmp #ARC_STEP
	bcc shapes_ar_last
shapes_ar_full
	lda #ARC_STEP
	sta arc_step
	bra shapes_ar_adv
shapes_ar_last
	lda arc_span
	sta arc_step
shapes_ar_adv
	clc                         ; ang = (ang + step) mod 256
	lda arc_ang
	adc arc_step
	sta arc_ang
	sec                         ; span -= step
	lda arc_span
	sbc arc_step
	sta arc_span
	lda arc_span+1
	sbc #0
	sta arc_span+1
	lda arc_ang                 ; this sample -> shl_x1/y1
	jsr shapes_arc_point
	lda arc_px
	sta shl_x1
	lda arc_px+1
	sta shl_x1+1
	lda arc_py
	sta shl_y1
	lda arc_py+1
	sta shl_y1+1
	jsr shp_line
	lda shl_x1                  ; cur -> prev for the next segment
	sta shl_x0
	lda shl_x1+1
	sta shl_x0+1
	lda shl_y1
	sta shl_y0
	lda shl_y1+1
	sta shl_y0+1
	lda arc_span                ; span exhausted ? done
	ora arc_span+1
	bne shapes_ar_loop
	rts

; sample at byte-angle A -> (arc_px, arc_py)
shapes_arc_point
	pha
	jsr cos8                    ; A = cos * 127 (signed)
	jsr shapes_arc_scale              ; arc_off = round(r * A / 128)
	clc
	lda arc_cx
	adc arc_off
	sta arc_px
	lda arc_cx+1
	adc arc_off+1
	sta arc_px+1
	pla
	jsr sin8                    ; A = sin * 127 (signed)
	jsr shapes_arc_scale
	clc
	lda arc_cy
	adc arc_off
	sta arc_py
	lda arc_cy+1
	adc arc_off+1
	sta arc_py+1
	rts

; arc_off = round(arc_r * |A| / 128) with A's sign (A a signed byte)
shapes_arc_scale
	stz arc_sgn
	pha
	and #$80
	beq shapes_as_pos
	inc arc_sgn
	pla
	eor #$FF
	clc
	adc #1
	bra shapes_as_mul
shapes_as_pos
	pla
shapes_as_mul
	jsr shapes_arc_mul8               ; arc_p16 = arc_r * |A|
	clc
	lda arc_p16                 ; + 0.5 LSB so >>7 rounds
	adc #64
	sta arc_p16
	lda arc_p16+1
	adc #0
	sta arc_p16+1
	lda arc_p16                 ; >>7 (product < 32768, one byte out)
	asl
	lda arc_p16+1
	rol
	sta arc_off
	stz arc_off+1
	lda arc_sgn
	beq shapes_as_done
	sec                         ; negate
	lda #0
	sbc arc_off
	sta arc_off
	lda #0
	sbc arc_off+1
	sta arc_off+1
shapes_as_done
	rts

; arc_p16 = arc_r * A  (8x8 -> 16, unsigned)
shapes_arc_mul8
	sta arc_t
	lda #0
	ldx #8
shapes_am_loop
	lsr arc_t
	bcc shapes_am_skip
	clc
	adc arc_r
shapes_am_skip
	ror
	ror arc_p16
	dex
	bne shapes_am_loop
	sta arc_p16+1
	rts

; --- arc state (shared with shape_pie) -------------------------------
arc_cx   .word 0
arc_cy   .word 0
arc_r    .byte 0
arc_a0   .byte 0
arc_ang  .byte 0
arc_step .byte 0
arc_span .word 0
arc_px   .word 0
arc_py   .word 0
arc_off  .word 0
arc_sgn  .byte 0
arc_p16  .word 0
arc_t    .byte 0

.endif

; ---------------------------------------------------------------------
; shape_pie -- a filled wedge from the centre to the arc (X16_USE_SHAPES_PIE)
; ---------------------------------------------------------------------
; Same arguments and angle convention as shape_arc; the region swept
; between the two radii and the arc is filled. It is built as a fan of
; thin triangles (centre, sample_i, sample_i+1) so ANY span works,
; including the reflex (> 180-degree) case a single convex scan cannot
; do; start == end fills the whole disc. The triangles share their radial
; edges, so like shape_disc it draws with SHP_HLINE (no clipping) and its
; overdraw on the shared edges is harmless. It reuses ARC's shapes_arc_point.
;
;   in: P0/P1 = cx, P2/P3 = cy, P4 = r (0-255),
;       P5 = start angle, P6 = end angle, A = colour
; ---------------------------------------------------------------------
.if xuse_shapes_pie

shape_pie
	sta pie_col
	lda X16_P0
	sta arc_cx
	lda X16_P1
	sta arc_cx+1
	lda X16_P2
	sta arc_cy
	lda X16_P3
	sta arc_cy+1
	lda X16_P4
	sta arc_r
	lda X16_P5
	sta arc_a0
	sec                         ; span = (end - start) & 255; 0 -> 256
	lda X16_P6
	sbc arc_a0
	sta arc_span
	stz arc_span+1
	lda arc_span
	bne shapes_pie_have
	inc arc_span+1
shapes_pie_have
	lda arc_a0                  ; prev = sample(start)
	jsr shapes_arc_point
	lda arc_px
	sta pie_prevx
	lda arc_px+1
	sta pie_prevx+1
	lda arc_py
	sta pie_prevy
	lda arc_py+1
	sta pie_prevy+1
	lda arc_a0
	sta arc_ang
shapes_pie_loop
	lda arc_span+1              ; step = min(ARC_STEP, span)
	bne shapes_pie_full
	lda arc_span
	cmp #ARC_STEP
	bcc shapes_pie_last
shapes_pie_full
	lda #ARC_STEP
	sta arc_step
	bra shapes_pie_adv
shapes_pie_last
	lda arc_span
	sta arc_step
shapes_pie_adv
	clc
	lda arc_ang
	adc arc_step
	sta arc_ang
	sec
	lda arc_span
	sbc arc_step
	sta arc_span
	lda arc_span+1
	sbc #0
	sta arc_span+1
	lda arc_ang                 ; cur = sample(ang)
	jsr shapes_arc_point
	lda arc_cx                  ; triangle A = centre
	sta tf_ax
	lda arc_cx+1
	sta tf_ax+1
	lda arc_cy
	sta tf_ay
	lda arc_cy+1
	sta tf_ay+1
	lda pie_prevx               ; B = prev sample
	sta tf_bx
	lda pie_prevx+1
	sta tf_bx+1
	lda pie_prevy
	sta tf_by
	lda pie_prevy+1
	sta tf_by+1
	lda arc_px                  ; C = cur sample
	sta tf_cx
	lda arc_px+1
	sta tf_cx+1
	lda arc_py
	sta tf_cy
	lda arc_py+1
	sta tf_cy+1
	jsr shapes_tf_fill
	lda arc_px                  ; prev = cur
	sta pie_prevx
	lda arc_px+1
	sta pie_prevx+1
	lda arc_py
	sta pie_prevy
	lda arc_py+1
	sta pie_prevy+1
	lda arc_span                ; span exhausted ? done
	ora arc_span+1
	beq shapes_pie_done
	jmp shapes_pie_loop
shapes_pie_done
	rts

; --- triangle scanline fill (fan primitive) --------------------------
; Fills triangle (tf_ax/ay, tf_bx/by, tf_cx/cy) in pie_col with SHP_HLINE
; spans. Sorts the vertices by y, then walks the long edge and the two
; short edges by scanline with a division-free DDA (err += |dx|; while
; err >= dy: x += sign, err -= dy). A zero-height triangle has no area
; and is skipped. Edge state is two-wide: index 0 = long, 2 = short.
shapes_tf_fill
	jsr shapes_tf_sort                ; ay <= by <= cy
	lda tf_ay                   ; ay == cy ? zero height, nothing to fill
	cmp tf_cy
	bne shapes_tf_go
	lda tf_ay+1
	cmp tf_cy+1
	bne shapes_tf_go
	rts
shapes_tf_go
	lda tf_ax                   ; long edge a -> c  (index 0)
	sta tf_isx
	lda tf_ax+1
	sta tf_isx+1
	lda tf_ay
	sta tf_isy
	lda tf_ay+1
	sta tf_isy+1
	lda tf_cx
	sta tf_iex
	lda tf_cx+1
	sta tf_iex+1
	lda tf_cy
	sta tf_iey
	lda tf_cy+1
	sta tf_iey+1
	ldx #0
	jsr shapes_tf_init
	lda tf_ay                   ; y = ay
	sta tf_y
	lda tf_ay+1
	sta tf_y+1
	sec                         ; phase 1 only if ay < by
	lda tf_ay
	sbc tf_by
	lda tf_ay+1
	sbc tf_by+1
	bvc +
	eor #$80
+	bpl shapes_tf_p2init              ; ay >= by (flat top): skip to phase 2
	lda tf_ax                   ; short edge a -> b  (index 2)
	sta tf_isx
	lda tf_ax+1
	sta tf_isx+1
	lda tf_ay
	sta tf_isy
	lda tf_ay+1
	sta tf_isy+1
	lda tf_bx
	sta tf_iex
	lda tf_bx+1
	sta tf_iex+1
	lda tf_by
	sta tf_iey
	lda tf_by+1
	sta tf_iey+1
	ldx #2
	jsr shapes_tf_init
shapes_tf_p1loop
	sec                         ; y >= by ? phase 1 done
	lda tf_y
	sbc tf_by
	lda tf_y+1
	sbc tf_by+1
	bvc +
	eor #$80
+	bmi shapes_tf_p1do
	jmp shapes_tf_p2init
shapes_tf_p1do
	jsr shapes_tf_emitrow
	ldx #0
	jsr shapes_tf_adv
	ldx #2
	jsr shapes_tf_adv
	inc tf_y
	bne +
	inc tf_y+1
+	jmp shapes_tf_p1loop
shapes_tf_p2init
	lda tf_bx                   ; short edge b -> c  (index 2)
	sta tf_isx
	lda tf_bx+1
	sta tf_isx+1
	lda tf_by
	sta tf_isy
	lda tf_by+1
	sta tf_isy+1
	lda tf_cx
	sta tf_iex
	lda tf_cx+1
	sta tf_iex+1
	lda tf_cy
	sta tf_iey
	lda tf_cy+1
	sta tf_iey+1
	ldx #2
	jsr shapes_tf_init
shapes_tf_p2loop
	jsr shapes_tf_emitrow
	lda tf_y                    ; y == cy ? done (last row)
	cmp tf_cy
	bne shapes_tf_p2do
	lda tf_y+1
	cmp tf_cy+1
	bne shapes_tf_p2do
	rts
shapes_tf_p2do
	ldx #0
	jsr shapes_tf_adv
	ldx #2
	jsr shapes_tf_adv
	inc tf_y
	bne +
	inc tf_y+1
+	jmp shapes_tf_p2loop

; sort tf_a/tf_b/tf_c by y ascending (each slot is x.w then y.w)
shapes_tf_sort
	jsr shapes_tf_cmp_ab
	bpl +
	jsr shapes_tf_swap_ab
+	jsr shapes_tf_cmp_bc
	bpl +
	jsr shapes_tf_swap_bc
+	jsr shapes_tf_cmp_ab
	bpl +
	jsr shapes_tf_swap_ab
+	rts
shapes_tf_cmp_ab
	sec
	lda tf_by
	sbc tf_ay
	lda tf_by+1
	sbc tf_ay+1
	bvc +
	eor #$80
+	rts
shapes_tf_cmp_bc
	sec
	lda tf_cy
	sbc tf_by
	lda tf_cy+1
	sbc tf_by+1
	bvc +
	eor #$80
+	rts
shapes_tf_swap_ab
	ldx #3
shapes_tsab
	lda tf_ax,x
	ldy tf_bx,x
	sta tf_bx,x
	tya
	sta tf_ax,x
	dex
	bpl shapes_tsab
	rts
shapes_tf_swap_bc
	ldx #3
shapes_tsbc
	lda tf_bx,x
	ldy tf_cx,x
	sta tf_cx,x
	tya
	sta tf_bx,x
	dex
	bpl shapes_tsbc
	rts

; init edge X (0 long / 2 short) from (tf_isx,tf_isy) to (tf_iex,tf_iey)
shapes_tf_init
	lda tf_isx
	sta e_curx,x
	lda tf_isx+1
	sta e_curx+1,x
	sec                         ; dy = iey - isy  (>= 0)
	lda tf_iey
	sbc tf_isy
	sta e_dy,x
	lda tf_iey+1
	sbc tf_isy+1
	sta e_dy+1,x
	sec                         ; dx = iex - isx  (signed)
	lda tf_iex
	sbc tf_isx
	sta tf_edx
	lda tf_iex+1
	sbc tf_isx+1
	sta tf_edx+1
	bpl shapes_ti_pos
	sec                         ; adx = -dx, sx = -1
	lda #0
	sbc tf_edx
	sta e_adx,x
	lda #0
	sbc tf_edx+1
	sta e_adx+1,x
	lda #$FF
	sta e_sx,x
	sta e_sx+1,x
	bra shapes_ti_err
shapes_ti_pos
	lda tf_edx                  ; adx = dx, sx = +1
	sta e_adx,x
	lda tf_edx+1
	sta e_adx+1,x
	lda #1
	sta e_sx,x
	stz e_sx+1,x
shapes_ti_err
	stz e_err,x
	stz e_err+1,x
	rts

; advance edge X by one scanline (dy for this edge must be > 0)
shapes_tf_adv
	clc                         ; err += adx
	lda e_err,x
	adc e_adx,x
	sta e_err,x
	lda e_err+1,x
	adc e_adx+1,x
	sta e_err+1,x
shapes_ta_w
	sec                         ; err >= dy ?
	lda e_err,x
	sbc e_dy,x
	tay
	lda e_err+1,x
	sbc e_dy+1,x
	bcc shapes_ta_done                ; err < dy
	sta e_err+1,x               ; err -= dy
	tya
	sta e_err,x
	clc                         ; x += sx
	lda e_curx,x
	adc e_sx,x
	sta e_curx,x
	lda e_curx+1,x
	adc e_sx+1,x
	sta e_curx+1,x
	bra shapes_ta_w
shapes_ta_done
	rts

; HLINE on row tf_y between the long (index 0) and short (index 2) x's
shapes_tf_emitrow
	sec                         ; diff = short_x - long_x
	lda e_curx+2
	sbc e_curx
	sta tf_tmp
	lda e_curx+3
	sbc e_curx+1
	sta tf_tmp+1
	bpl shapes_te_pos                 ; short >= long: left = long, len = diff+1
	lda e_curx+2                ; short < long: left = short, len = -diff+1
	sta X16_P0
	lda e_curx+3
	sta X16_P1
	sec
	lda #0
	sbc tf_tmp
	sta X16_P4
	lda #0
	sbc tf_tmp+1
	sta X16_P5
	bra shapes_te_len
shapes_te_pos
	lda e_curx
	sta X16_P0
	lda e_curx+1
	sta X16_P1
	lda tf_tmp
	sta X16_P4
	lda tf_tmp+1
	sta X16_P5
shapes_te_len
	inc X16_P4                  ; len = |diff| + 1
	bne +
	inc X16_P5
+	lda tf_y
	sta X16_P2
	lda tf_y+1
	sta X16_P3
	lda pie_col
	jsr SHP_HLINE
	rts

; --- pie / triangle-fill state ---------------------------------------
pie_col   .byte 0
pie_prevx .word 0
pie_prevy .word 0
tf_ax  .word 0
tf_ay  .word 0
tf_bx  .word 0
tf_by  .word 0
tf_cx  .word 0
tf_cy  .word 0
tf_y   .word 0
tf_isx .word 0
tf_isy .word 0
tf_iex .word 0
tf_iey .word 0
tf_edx .word 0
tf_tmp .word 0
e_curx .fill 4, 0
e_err  .fill 4, 0
e_adx  .fill 4, 0
e_dy   .fill 4, 0
e_sx   .fill 4, 0

.endif

; ---------------------------------------------------------------------
; shape_bezier -- cubic Bezier curve (X16_USE_SHAPES_BEZIER)
; ---------------------------------------------------------------------
; The curve through four control points P0 (on the curve), P1, P2
; (handles), P3 (on the curve), by de Casteljau at a handful of t and
; shp_line between the samples. The sample count adapts to the control
; polygon's size (its Manhattan perimeter / 8, clamped to 4..64), so a
; small curve is cheap and a large one stays smooth. Clips wherever
; SHP_PSET clips.
;
;   in: bez_x0/bez_y0 .. bez_x3/bez_y3 = the four control points
;       (signed words, set by the caller), A = colour
;
; t is an 8-bit fraction (0..255); the endpoints P0 and P3 are emitted
; exactly rather than evaluated, so the curve meets its anchors.
; ---------------------------------------------------------------------
.if xuse_shapes_bezier

shape_bezier
	sta shl_col
	jsr shapes_bz_nseg                ; bez_n = clamp(perimeter/8, 4, 64)
	lda bez_x0                  ; prev = P0 (emitted exactly)
	sta shl_x0
	lda bez_x0+1
	sta shl_x0+1
	lda bez_y0
	sta shl_y0
	lda bez_y0+1
	sta shl_y0+1
	lda #1
	sta bez_i
	stz bez_tb
	stz bez_rem
	stz bez_rem+1
shapes_bz_loop
	lda bez_i                   ; i == n ? last segment goes to P3
	cmp bez_n
	beq shapes_bz_last
	inc bez_rem+1               ; rem += 256; while rem >= n: tb++, rem -= n
shapes_bz_tw
	lda bez_rem+1
	bne shapes_bz_tsub
	lda bez_rem
	cmp bez_n
	bcc shapes_bz_tdone
shapes_bz_tsub
	sec
	lda bez_rem
	sbc bez_n
	sta bez_rem
	lda bez_rem+1
	sbc #0
	sta bez_rem+1
	inc bez_tb
	bra shapes_bz_tw
shapes_bz_tdone
	jsr shapes_bz_eval                ; (bez_rx, bez_ry) = B(tb)
	lda bez_rx
	sta shl_x1
	lda bez_rx+1
	sta shl_x1+1
	lda bez_ry
	sta shl_y1
	lda bez_ry+1
	sta shl_y1+1
	jsr shp_line
	lda shl_x1                  ; cur -> prev
	sta shl_x0
	lda shl_x1+1
	sta shl_x0+1
	lda shl_y1
	sta shl_y0
	lda shl_y1+1
	sta shl_y0+1
	inc bez_i
	jmp shapes_bz_loop
shapes_bz_last
	lda bez_x3                  ; final sample = P3, exact
	sta shl_x1
	lda bez_x3+1
	sta shl_x1+1
	lda bez_y3
	sta shl_y1
	lda bez_y3+1
	sta shl_y1+1
	jmp shp_line

; bez_n = clamp(Manhattan perimeter of the control polygon / 8, 4, 64)
shapes_bz_nseg
	stz bez_per
	stz bez_per+1
	ldx #0                      ; X = 4*k over the three control segments
shapes_bn_loop
	sec                         ; dx = pts[k+1]shapes_x - pts[k]shapes_x
	lda bez_x0+4,x
	sbc bez_x0,x
	sta bez_tmp
	lda bez_x0+5,x
	sbc bez_x0+1,x
	sta bez_tmp+1
	jsr shapes_bz_absacc
	sec                         ; dy = pts[k+1]shapes_y - pts[k]shapes_y
	lda bez_x0+6,x
	sbc bez_x0+2,x
	sta bez_tmp
	lda bez_x0+7,x
	sbc bez_x0+3,x
	sta bez_tmp+1
	jsr shapes_bz_absacc
	inx
	inx
	inx
	inx
	cpx #12
	bne shapes_bn_loop
	ldx #3                      ; per >>= 3
shapes_bn_sh
	lsr bez_per+1
	ror bez_per
	dex
	bne shapes_bn_sh
	lda bez_per+1               ; clamp high -> 64
	bne shapes_bn_hi
	lda bez_per
	cmp #64
	bcs shapes_bn_hi
	cmp #4
	bcs shapes_bn_ok                  ; 4..63
	lda #4
shapes_bn_ok
	sta bez_n
	rts
shapes_bn_hi
	lda #64
	sta bez_n
	rts

; bez_per += |bez_tmp|  (signed word magnitude)
shapes_bz_absacc
	lda bez_tmp+1
	bpl shapes_ba_pos
	sec
	lda #0
	sbc bez_tmp
	sta bez_tmp
	lda #0
	sbc bez_tmp+1
	sta bez_tmp+1
shapes_ba_pos
	clc
	lda bez_per
	adc bez_tmp
	sta bez_per
	lda bez_per+1
	adc bez_tmp+1
	sta bez_per+1
	rts

; (bez_rx, bez_ry) = cubic B(bez_tb) by de Casteljau
shapes_bz_eval
	ldx #0                      ; copy control points into the work arrays
	ldy #0
shapes_be_cp
	lda bez_x0,y
	sta bez_wx,x
	lda bez_x0+1,y
	sta bez_wx+1,x
	lda bez_x0+2,y
	sta bez_wy,x
	lda bez_x0+3,y
	sta bez_wy+1,x
	inx
	inx
	tya
	clc
	adc #4
	tay
	cpx #8
	bne shapes_be_cp
	lda #3
	sta bez_cnt
shapes_be_lvl
	lda bez_cnt                 ; inner loop j = 0 .. cnt-1  (index j*2)
	asl
	sta bez_lim
	stz bez_jx
shapes_be_jx
	ldx bez_jx                  ; wx[j] = lerp(wx[j], wx[j+1], t)
	lda bez_wx,x
	sta bez_p
	lda bez_wx+1,x
	sta bez_p+1
	lda bez_wx+2,x
	sta bez_q
	lda bez_wx+3,x
	sta bez_q+1
	jsr shapes_bz_lerp
	ldx bez_jx
	lda bez_r
	sta bez_wx,x
	lda bez_r+1
	sta bez_wx+1,x
	lda bez_wy,x                ; wy[j] = lerp(wy[j], wy[j+1], t)
	sta bez_p
	lda bez_wy+1,x
	sta bez_p+1
	lda bez_wy+2,x
	sta bez_q
	lda bez_wy+3,x
	sta bez_q+1
	jsr shapes_bz_lerp
	ldx bez_jx
	lda bez_r
	sta bez_wy,x
	lda bez_r+1
	sta bez_wy+1,x
	lda bez_jx
	clc
	adc #2
	sta bez_jx
	cmp bez_lim
	bne shapes_be_jx
	dec bez_cnt
	bne shapes_be_lvl
	lda bez_wx                  ; result = work[0]
	sta bez_rx
	lda bez_wx+1
	sta bez_rx+1
	lda bez_wy
	sta bez_ry
	lda bez_wy+1
	sta bez_ry+1
	rts

; bez_r = bez_p + round((bez_q - bez_p) * bez_tb / 256)   (signed)
shapes_bz_lerp
	sec                         ; d = q - p
	lda bez_q
	sbc bez_p
	sta bez_d
	lda bez_q+1
	sbc bez_p+1
	sta bez_d+1
	stz bez_dsgn
	lda bez_d+1                 ; take |d|, remember the sign
	bpl shapes_bl_pos
	inc bez_dsgn
	sec
	lda #0
	sbc bez_d
	sta bez_d
	lda #0
	sbc bez_d+1
	sta bez_d+1
shapes_bl_pos
	jsr shapes_bz_mul                 ; bez_prod = |d| * t (24-bit)
	clc                         ; + 128 (round), then take bytes 1..2 (>>8)
	lda bez_prod
	adc #128
	lda bez_prod+1
	adc #0
	sta bez_m
	lda bez_prod+2
	adc #0
	sta bez_m+1
	lda bez_dsgn
	beq shapes_bl_add
	sec                         ; re-apply the sign
	lda #0
	sbc bez_m
	sta bez_m
	lda #0
	sbc bez_m+1
	sta bez_m+1
shapes_bl_add
	clc                         ; r = p + m
	lda bez_p
	adc bez_m
	sta bez_r
	lda bez_p+1
	adc bez_m+1
	sta bez_r+1
	rts

; bez_prod (24-bit) = bez_d (16-bit) * bez_tb (8-bit), unsigned
shapes_bz_mul
	stz bez_prod
	stz bez_prod+1
	stz bez_prod+2
	lda bez_tb
	sta bez_mt
	ldx #8
shapes_bm_loop
	asl bez_prod
	rol bez_prod+1
	rol bez_prod+2
	asl bez_mt
	bcc shapes_bm_skip
	clc
	lda bez_prod
	adc bez_d
	sta bez_prod
	lda bez_prod+1
	adc bez_d+1
	sta bez_prod+1
	lda bez_prod+2
	adc #0
	sta bez_prod+2
shapes_bm_skip
	dex
	bne shapes_bm_loop
	rts

; --- bezier state ----------------------------------------------------
bez_x0 .word 0
bez_y0 .word 0
bez_x1 .word 0
bez_y1 .word 0
bez_x2 .word 0
bez_y2 .word 0
bez_x3 .word 0
bez_y3 .word 0
bez_n    .byte 0
bez_i    .byte 0
bez_tb   .byte 0
bez_rem  .word 0
bez_per  .word 0
bez_tmp  .word 0
bez_rx   .word 0
bez_ry   .word 0
bez_wx   .fill 8, 0
bez_wy   .fill 8, 0
bez_cnt  .byte 0
bez_lim  .byte 0
bez_jx   .byte 0
bez_p    .word 0
bez_q    .word 0
bez_d    .word 0
bez_dsgn .byte 0
bez_prod .fill 3, 0
bez_mt   .byte 0
bez_m    .word 0
bez_r    .word 0

.endif

; --- the default binding: the 2bpp module ------------------------------
; (evaluated here, at the END, so an overrider defines its symbols
; before sourcing the file and these !ifdefs stay quiet)
; The default-bound words are emitted UNCONDITIONALLY -- data inside an
; !ifndef would appear in pass 1 and vanish in pass 2 (the symbol exists
; by then), shifting every later address into a phase error.
.if !X16_SKIP_BASE != 0
shp_wdef .word 640
shp_hdef .word 480

.weak
SHP_PSET = gfx2h_pset
.endweak
.weak
SHP_READ = gfx2h_read
.endweak
.weak
SHP_HLINE = gfx2h_hline
.endweak
.weak
SHP_W = shp_wdef
.endweak
.weak
SHP_H = shp_hdef
.endweak
.endif

; (end zone)
.endif
.if xuse_verafx_any
; --- inline gfx/verafx.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/verafx.asm -- VERA FX: hardware multiply, fast fills
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Requires VERA firmware v0.3.1+ (emulator R44+). Probe with vera_has_fx
; before calling anything here; on older VERA these routines write to
; registers that do not exist and quietly do the wrong thing.
;
; The FX registers are $9F29-$9F2C banked behind DCSEL 2..6. Always
; select the bank with +vera_dcsel, which preserves ADDRSEL -- writing
; VERA_CTRL directly (as the reference manual's examples do) would
; deselect whatever data port the caller had chosen.
;
; Every routine here leaves FX disabled (FX_CTRL = 0, Addr1 Mode 0) and
; DCSEL back at 0. Leaving Addr1 Mode set would silently change how
; ordinary VRAM addressing behaves for everyone downstream.
; =====================================================================

; (zone: file scope in 64tass)


; --- fx_off: every part of this module leaves FX through it, so it
; --- is here whenever any of them is.
.if xuse_verafx_any
; ---------------------------------------------------------------------
; fx_off -- disable FX; leave DCSEL = 0 and ADDRSEL = 0.
; Safe to call whether or not FX was ever enabled.
;
; ADDRSEL is forced back to port 0 because the line and polygon
; helpers work through port 1: returning with port 1 selected would
; hand the next CHROUT the exact ADDRSEL trap video/screen.asm warns
; about.
; ---------------------------------------------------------------------
fx_off
    #vera_dcsel 2
    stz VERA_FX_CTRL            ; cache off, transparency off, Addr1 mode 0
    stz VERA_FX_MULT            ; multiplier off
    #vera_dcsel 0
    #vera_addrsel 0
    rts

.endif

.if xuse_verafx_mult
; ---------------------------------------------------------------------
; fx_mult -- signed 16 x 16 -> 32 in hardware
;   in:  X16_P0/P1 = a, X16_P2/P3 = b
;   out: X16_P4..P7 = product, low byte first
;
; The two operands go into the halves of the 32-bit cache. The result
; is not readable from a register: triggering the multiply writes four
; bytes to VRAM, so we park them at VRAM_FX_SCRATCH and read them back.
;
; Only ADDR0/DATA0 is used. VERA pre-fetches whenever an address pointer
; changes or increments -- even with increment 0 -- so touching the same
; VRAM through the other port here would risk reading a stale latch.
; ---------------------------------------------------------------------
fx_mult
    #vera_dcsel 2
    stz VERA_FX_CTRL            ; Addr1 Mode 0
    lda #VERA_FX_MULT_ENABLE
    sta VERA_FX_MULT

    #vera_dcsel 6
    lda VERA_FX_ACCUM_RESET     ; a *read* clears the accumulator
    lda X16_P0
    sta VERA_FX_CACHE_L
    lda X16_P1
    sta VERA_FX_CACHE_M         ; cache 15:0  = a
    lda X16_P2
    sta VERA_FX_CACHE_H
    lda X16_P3
    sta VERA_FX_CACHE_U         ; cache 31:16 = b

    #vera_dcsel 2
    lda #VERA_FX_CACHE_WRITE
    sta VERA_FX_CTRL            ; with multiplier on, writes the product

    ; Trigger: any store to DATA0 emits the 32-bit result. The stored
    ; value itself is ignored.
    #vera_addr 0, VRAM_FX_SCRATCH, VERA_INC_0
    stz VERA_DATA0

    ; Read it back, now advancing one byte at a time.
    #vera_addr 0, VRAM_FX_SCRATCH, VERA_INC_1
    lda VERA_DATA0
    sta X16_P4
    lda VERA_DATA0
    sta X16_P5
    lda VERA_DATA0
    sta X16_P6
    lda VERA_DATA0
    sta X16_P7

    jmp fx_off

.endif

.if xuse_verafx_fill
; ---------------------------------------------------------------------
; fx_fill -- fill VRAM through the 32-bit write cache (~4x a byte loop)
;   in:  A = byte value
;        X16_P0/P1/P2 = destination VRAM address (17-bit)
;        X16_P3/P4    = byte count
;
; With Cache Write Enable set, one store to DATA0 writes all four cache
; bytes. Stepping the port by 4 covers the region a quad at a time; any
; remaining 1-3 bytes are written normally with FX switched back off.
; ---------------------------------------------------------------------
fx_fill
    sta X16_T0                  ; fill value

    #vera_dcsel 2
    stz VERA_FX_MULT            ; multiplier off: write the cache itself
    lda #VERA_FX_CACHE_WRITE
    sta VERA_FX_CTRL

    #vera_dcsel 6
    lda X16_T0
    sta VERA_FX_CACHE_L
    sta VERA_FX_CACHE_M
    sta VERA_FX_CACHE_H
    sta VERA_FX_CACHE_U
    #vera_dcsel 0

    ; Point port 0 at the destination, stepping 4 bytes per write.
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    lda X16_P0
    sta VERA_ADDR_L
    lda X16_P1
    sta VERA_ADDR_M
    lda X16_P2
    and #VERA_ADDR_H_BANK
    ora #(VERA_INC_4 << 4)
    sta VERA_ADDR_H

    ; quads = count >> 2, remainder = count & 3
    lda X16_P3
    and #$03
    sta X16_T3
    lda X16_P4
    sta X16_T2
    lda X16_P3
    sta X16_T1
    lsr X16_T2
    ror X16_T1
    lsr X16_T2
    ror X16_T1

    lda X16_T1
    ora X16_T2
    beq _tail                   ; fewer than four bytes

    ldx X16_T1
    ldy X16_T2
    txa
    beq _full
    iny
_full
_loop
    stz VERA_DATA0              ; writes the four cache bytes
    dex
    bne _loop
    dey
    bne _loop

_tail
    ; FX off first: the leftover bytes must be written singly.
    #vera_dcsel 2
    stz VERA_FX_CTRL
    #vera_dcsel 0

    lda X16_T3
    beq _done

    ; Port 0 already sits just past the quads. Keep its bank and DECR
    ; bits, switch the increment back to 1.
    lda VERA_ADDR_H
    and #$0F
    ora #(VERA_INC_1 << 4)
    sta VERA_ADDR_H

    ldx X16_T3
    lda X16_T0
_rest
    sta VERA_DATA0
    dex
    bne _rest
_done
    rts

; ---------------------------------------------------------------------
; fx_clear -- zero a VRAM region
;   in:  X16_P0/P1/P2 = address, X16_P3/P4 = byte count
; ---------------------------------------------------------------------
fx_clear
    lda #0
    jmp fx_fill

.endif

.if xuse_verafx_copy
; ---------------------------------------------------------------------
; fx_copy -- VRAM to VRAM through the 32-bit cache (~4x a byte loop)
;   in:  X16_P0/P1/P2 = source address (17-bit)
;        X16_P3/P4/P5 = destination address, 4-BYTE ALIGNED
;        X16_P6/P7    = byte count
;
; With Cache Fill enabled, each DATA1 read latches a byte into the
; cache; after four, one DATA0 write (mask 0) flushes all four to the
; aligned destination. The 0-3 leftover bytes are copied singly with
; FX off. The source needs no alignment.
; ---------------------------------------------------------------------
fx_copy
    #vera_dcsel 2
    stz VERA_FX_CTRL            ; mode 0 while the ports are aimed
    stz VERA_FX_MULT            ; multiplier off, cache index to 0

    #vera_addrsel 1             ; port 1 reads the source
    lda X16_P0
    sta VERA_ADDR_L
    lda X16_P1
    sta VERA_ADDR_M
    lda X16_P2
    and #VERA_ADDR_H_BANK
    ora #(VERA_INC_1 << 4)
    sta VERA_ADDR_H
    #vera_addrsel 0             ; port 0 writes quads
    lda X16_P3
    sta VERA_ADDR_L
    lda X16_P4
    sta VERA_ADDR_M
    lda X16_P5
    and #VERA_ADDR_H_BANK
    ora #(VERA_INC_4 << 4)
    sta VERA_ADDR_H

    #vera_dcsel 2
    lda #(VERA_FX_CACHE_FILL | VERA_FX_CACHE_WRITE)
    sta VERA_FX_CTRL

    ; quads = count >> 2, remainder = count & 3
    lda X16_P6
    and #$03
    sta X16_T3
    lda X16_P7
    sta X16_T2
    lda X16_P6
    sta X16_T1
    lsr X16_T2
    ror X16_T1
    lsr X16_T2
    ror X16_T1

    lda X16_T1
    ora X16_T2
    beq _tail

    ldx X16_T1
    ldy X16_T2
    txa
    beq _full
    iny
_full
_quad
    lda VERA_DATA1              ; four reads fill the cache...
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
    stz VERA_DATA0              ; ...one write flushes it (mask 0)
    dex
    bne _quad
    dey
    bne _quad

_tail
    #vera_dcsel 2
    stz VERA_FX_CTRL            ; leftovers are plain byte copies
    #vera_dcsel 0

    lda X16_T3
    beq _done
    lda VERA_ADDR_H             ; port 0 sits just past the quads:
    and #$0F                    ; step it by 1 for the tail
    ora #(VERA_INC_1 << 4)
    sta VERA_ADDR_H
    ldx X16_T3
_rest
    lda VERA_DATA1
    sta VERA_DATA0
    dex
    bne _rest
_done
    #vera_addrsel 0
    rts

.endif

.if xuse_verafx_transp
; ---------------------------------------------------------------------
; fx_transp_on / fx_transp_off -- transparent VRAM writes
;
; While on, a ZERO byte written to DATA0/DATA1 (or sitting in a flushed
; cache) leaves the target byte alone -- colour 0 acts as transparency
; for blits done with plain writes or fx_copy-style cache flushes.
;
; NOTE: the other fx_* helpers reset FX_CTRL on exit, which turns
; transparency off again. Enable it, do your writes, disable it.
; ---------------------------------------------------------------------
fx_transp_on
    #vera_dcsel 2
    lda VERA_FX_CTRL
    ora #VERA_FX_TRANSPARENT
    sta VERA_FX_CTRL
    #vera_dcsel 0
    rts

fx_transp_off
    #vera_dcsel 2
    lda VERA_FX_CTRL
    and #($FF - VERA_FX_TRANSPARENT)
    sta VERA_FX_CTRL
    #vera_dcsel 0
    rts

; =====================================================================
; FX affine helper (Addr1 Mode 3) -- the rotozoom/mode-7 sampler.
;
; VERA turns port 1's reads into texture fetches: an 8x8-tile map
; (one byte per tile, no attributes) defines a square texture, and
; two fixed-point counters walk a sampling ray across it. Every
; DATA1 read returns the texel under the ray and steps it. A rotated,
; scaled scanline is then just:
;
;       jsr fx_affine_ray               ; start + direction
;       +vera_addr 0, dest, VERA_INC_1
;       ... X16_P0/P1 = pixel count ...
;       jsr fx_affine_span              ; DATA1 -> DATA0, that's mode 7
;
; with the ray's dx/dy per scanline coming from sin8/cos8 and the
; zoom factor. Tiles are 8 bpp here (64 bytes each, up to 256 tiles).
; =====================================================================

.endif

.if xuse_verafx_affine
; ---------------------------------------------------------------------
; fx_affine_on -- enter affine mode and describe the texture
;   in:  X16_P0/P1/P2 = tile data VRAM address (2 KB aligned)
;        X16_P3/P4/P5 = tile map VRAM address (2 KB aligned)
;        X16_P6 = map size code: 0=2x2, 1=8x8, 2=32x32, 3=128x128 tiles
;        X16_P7 = bit 0: 1 = clip (outside the map reads tile 0),
;                        0 = wrap around the map edges
; ---------------------------------------------------------------------
fx_affine_on
    #vera_dcsel 2
    lda #VERA_FX_ADDR1_AFFINE
    sta VERA_FX_CTRL

    ; FX_TILEBASE: bits 7:2 = address 16:11, bit 1 = clip enable
    lda X16_P1
    lsr
    lsr
    lsr                         ; address bits 15:11 -> 4:0
    sta X16_T0
    lda X16_P2
    and #$01
    beq _tb_low
    lda #%00100000              ; address bit 16 -> value bit 5
_tb_low
    ora X16_T0
    asl
    asl                         ; the register wants them in bits 7:2
    sta X16_T0
    lda X16_P7
    and #$01
    asl                         ; clip enable is bit 1
    ora X16_T0
    sta VERA_FX_TILEBASE

    ; FX_MAPBASE: bits 7:2 = address 16:11, bits 1:0 = map size
    lda X16_P4
    lsr
    lsr
    lsr
    sta X16_T0
    lda X16_P5
    and #$01
    beq _mb_low
    lda #%00100000
_mb_low
    ora X16_T0
    asl
    asl
    sta X16_T0
    lda X16_P6
    and #$03
    ora X16_T0
    sta VERA_FX_MAPBASE
    #vera_dcsel 0
    rts

; ---------------------------------------------------------------------
; fx_affine_ray -- aim the sampler
;   in:  X16_P0/P1 = starting x texel (0-1023)
;        X16_P2/P3 = starting y texel
;        X16_P4/P5 = dx per read, X16_P6/P7 = dy per read
;                    (signed, 1/512 texel units: 512 = one texel per
;                    read; bit 15 = x32, the line/poly encoding)
;
; Samples from texel centres (the subpixel part starts at 0.5).
; Requires fx_affine_on first. Every DATA1 read afterwards returns a
; texel and advances the ray.
; ---------------------------------------------------------------------
fx_affine_ray
    #vera_dcsel 3
    lda X16_P4
    sta VERA_FX_X_INCR_L
    lda X16_P5
    sta VERA_FX_X_INCR_H
    lda X16_P6
    sta VERA_FX_Y_INCR_L
    lda X16_P7
    sta VERA_FX_Y_INCR_H
    #vera_dcsel 5
    lda #$80                    ; subpixel 0.5: sample texel centres
    sta VERA_FX_X_POS_S
    sta VERA_FX_Y_POS_S
    #vera_dcsel 4
    lda X16_P0                  ; positions last: writing them makes
    sta VERA_FX_X_POS_L         ; VERA prefetch the first texel
    lda X16_P1
    and #$07
    sta VERA_FX_X_POS_H
    lda X16_P2
    sta VERA_FX_Y_POS_L
    lda X16_P3
    and #$07
    sta VERA_FX_Y_POS_H
    #vera_dcsel 0
    rts

; ---------------------------------------------------------------------
; fx_affine_span -- fetch texels along the ray into VRAM
;   in:  X16_P0/P1 = texel count (>= 1)
;   pre: fx_affine_ray aimed; the caller pointed port 0 at the
;        destination with the increment it wants
;
; The mode-7 inner loop: one read, one write per pixel.
; ---------------------------------------------------------------------
fx_affine_span
    ldx X16_P0
    ldy X16_P1
    txa
    beq _full
    iny
_full
_span
    lda VERA_DATA1
    sta VERA_DATA0
    dex
    bne _span
    dey
    bne _span
    rts

; =====================================================================
; FX line draw helper (Addr1 Mode 1)
;
; VERA tracks the Bresenham error internally: ADDR1 steps one pixel
; along the major axis on every DATA1 write, and a 9.9 fixed-point
; accumulator (seeded to half a pixel) carries it one step along the
; minor axis whenever the slope fraction overflows. The CPU's whole
; job is one `sta VERA_DATA1` per pixel.
;
; Increment registers hold 15-bit signed 6.9 fixed point: write the
; value in 1/512ths, low byte to INCR_L, high 7 bits to INCR_H (bit 7
; of INCR_H multiplies by 32 -- not needed for a line's 0.0..1.0).
; =====================================================================

; ---------------------------------------------------------------------
; fx_line -- hardware-assisted line draw
;   in:  X16_P0/P1 = x0, X16_P2 = y0
;        X16_P3/P4 = x1, X16_P5 = y1
;        X16_P6    = colour
;
; Same arguments and endpoints as gfx8l_line, drawn by the FX helper.
; Assumes the 320x240@8bpp framebuffer at VRAM $00000 (gfx8l_init's
; mode). Does NOT clip; keep both endpoints on screen. Probe
; vera_has_fx before relying on any fx_* routine.
.endif

.if xuse_verafx_line
; ---------------------------------------------------------------------
fx_line
    ; |dx| and the x direction
    stz fxl_sx
    sec
    lda X16_P3
    sbc X16_P0
    sta fxl_dx
    lda X16_P4
    sbc X16_P1
    sta fxl_dx+1
    bpl _dx_done
    inc fxl_sx                  ; x runs right to left
    sec
    lda #0
    sbc fxl_dx
    sta fxl_dx
    lda #0
    sbc fxl_dx+1
    sta fxl_dx+1
_dx_done

    ; |dy| and the y direction, in 16 bits (239 - 0 overflows a byte)
    stz fxl_sy
    sec
    lda X16_P5
    sbc X16_P2
    sta fxl_dy
    lda #0
    sbc #0
    sta fxl_dy+1
    bpl _dy_done
    inc fxl_sy
    sec
    lda #0
    sbc fxl_dy
    sta fxl_dy
    lda #0
    sbc fxl_dy+1
    sta fxl_dy+1
_dy_done

    ; Encode the two step bytes once, as if Y-major: h1 = a row per
    ; step (ADDR1, down or up), h0 = a pixel (ADDR0, right or left).
    ; An X-major line swaps their roles below.
    lda #(VERA_INC_320 << 4)
    ldx fxl_sy
    beq _e320
    ora #VERA_ADDR_H_DECR
_e320
    sta fxl_h1
    lda #(VERA_INC_1 << 4)
    ldx fxl_sx
    beq _e1
    ora #VERA_ADDR_H_DECR
_e1
    sta fxl_h0

    ; pick the octant: ADDR1 steps the major axis every pixel, ADDR0's
    ; increment is borrowed for the sometimes-step along the minor axis
    lda fxl_dy+1
    cmp fxl_dx+1
    bne _which
    lda fxl_dy
    cmp fxl_dx
_which
    bcc _x_major

    lda fxl_dy                  ; Y-major: major = dy, minor = dx
    sta fxl_major
    lda fxl_dy+1
    sta fxl_major+1
    lda fxl_dx
    sta fxl_minor
    lda fxl_dx+1
    sta fxl_minor+1
    bra _slope

_x_major
    lda fxl_dx                  ; X-major: major = dx, minor = dy...
    sta fxl_major
    lda fxl_dx+1
    sta fxl_major+1
    lda fxl_dy
    sta fxl_minor
    lda fxl_dy+1
    sta fxl_minor+1
    lda fxl_h1                  ; ...and the step bytes swap roles
    ldx fxl_h0
    stx fxl_h1
    sta fxl_h0

_slope
    ; slope = minor/major in 1/512ths (0..512); a point has no slope
    stz fxl_v
    stz fxl_v+1
    lda fxl_major
    ora fxl_major+1
    beq _program
    stz fxd_num                 ; dividend = minor * 512
    lda fxl_minor
    asl
    sta fxd_num+1
    lda fxl_minor+1
    rol
    sta fxd_num+2
    lda fxl_major
    sta fxd_den
    lda fxl_major+1
    sta fxd_den+1
    jsr verafx_udiv24
    lda fxd_num
    sta fxl_v
    lda fxd_num+1
    sta fxl_v+1

_program
    jsr verafx_pix_addr               ; fxa = address of (P0/P1, P2)

    ; An axis-aligned line (minor delta 0) is just a run along port
    ; 1's increment -- no FX needed.
    lda fxl_minor
    ora fxl_minor+1
    beq _plain

    ; ORDER IS LOAD-BEARING. Every ADDRx register write makes VERA
    ; prefetch, and with line mode already enabled a prefetch steps
    ; the helper using whatever slope happens to be lingering in the
    ; increment registers -- bending the first pixels of the line. So:
    ; all addresses while the mode is still off, then the mode, and
    ; the slope very last (writing X_INCR_H seeds the subpixel
    ; accumulator to half a pixel).
    #vera_dcsel 2
    stz VERA_FX_CTRL            ; addr1 mode 0 while addressing
    jsr verafx_set_addr1
    #vera_addrsel 0             ; only ADDR0's increment matters here
    lda fxl_h0
    sta VERA_ADDR_H
    #vera_dcsel 2
    lda #VERA_FX_ADDR1_LINE
    sta VERA_FX_CTRL
    #vera_dcsel 3
    lda fxl_v
    sta VERA_FX_X_INCR_L
    lda fxl_v+1
    sta VERA_FX_X_INCR_H        ; seeds the fraction to 0.5...
    #vera_dcsel 4
    stz VERA_FX_X_POS_L         ; ...but NOT the integer/carry bits: a
    stz VERA_FX_X_POS_H         ; leftover carry from an earlier FX op
    bra _count                  ; would eat the line's first minor-step

_plain
    jsr verafx_set_addr1

_count

    ; draw major+1 pixels
    clc
    lda fxl_major
    adc #1
    tax
    lda fxl_major+1
    adc #0
    tay
    txa
    beq _full
    iny
_full
    lda X16_P6
_draw
    sta VERA_DATA1
    dex
    bne _draw
    dey
    bne _draw
    jmp fx_off

; point port 1 at the start pixel with the major-axis increment
verafx_set_addr1
    #vera_addrsel 1
    lda fxa
    sta VERA_ADDR_L
    lda fxa+1
    sta VERA_ADDR_M
    lda fxa+2
    and #VERA_ADDR_H_BANK
    ora fxl_h1
    sta VERA_ADDR_H
    rts

fxl_dx    .word 0
fxl_dy    .word 0
fxl_major .word 0
fxl_minor .word 0
fxl_v     .word 0
fxl_sx    .byte 0
fxl_sy    .byte 0
fxl_h1    .byte 0
fxl_h0    .byte 0

; =====================================================================
; FX polygon filler (Addr1 Mode 2)
;
; VERA walks two edges at once: the X and Y/X2 position registers
; carry the left and right x, each advanced by its own signed slope
; twice per row (hence: program HALF the per-row increment). Reading
; DATA1 latches the row -- VERA points ADDR1 at the left edge and
; computes the span width, read back from POLY_FILL_L/H. The CPU
; fills that many pixels and a DATA0 read advances to the next row.
; =====================================================================

.endif

.if xuse_verafx_tri
; ---------------------------------------------------------------------
; fx_triangle -- filled triangle via the polygon helper
;   in:  tri_x0/tri_y0, tri_x1/tri_y1, tri_x2/tri_y2 = vertices
;        (x 0-319, y 0-239; written directly, like collide16's block)
;        tri_color = fill colour
;
; Vertices may come in any order. The rasterisation is half-open: the
; bottom row (max y) is not drawn, so triangles sharing an edge do not
; double-paint it. Assumes the 320x240@8bpp framebuffer at $00000.
; Does NOT clip.
; ---------------------------------------------------------------------
fx_triangle
    ; sort the vertices by y (three compare-swaps; X names the pair)
    lda tri_y1
    cmp tri_y0
    bcs _s1
    ldx #0
    jsr verafx_swapv
_s1
    lda tri_y2
    cmp tri_y1
    bcs _s2
    ldx #3
    jsr verafx_swapv
_s2
    lda tri_y1
    cmp tri_y0
    bcs _s3
    ldx #0
    jsr verafx_swapv
_s3
    sec                         ; row counts of the two parts
    lda tri_y1
    sbc tri_y0
    sta fxt_n1
    sec
    lda tri_y2
    sbc tri_y1
    sta fxt_n2
    lda fxt_n1
    ora fxt_n2
    bne _go
    rts                         ; a single row: nothing (half-open)
_go
    ; slope of the long edge v0 -> v2 (always needed)
    lda fxt_n1
    clc
    adc fxt_n2
    sta fxs_dy
    sec
    lda tri_x2
    sbc tri_x0
    sta fxs_dxl
    lda tri_x2+1
    sbc tri_x0+1
    sta fxs_dxh
    jsr verafx_slope
    jsr verafx_save_a                 ; edge A = the long edge

    lda fxt_n1
    bne _two_parts
    jmp _flat_top               ; out of branch range from here
_two_parts

    ; slope of the top short edge v0 -> v1
    lda fxt_n1
    sta fxs_dy
    sec
    lda tri_x1
    sbc tri_x0
    sta fxs_dxl
    lda tri_x1+1
    sbc tri_x0+1
    sta fxs_dxh
    jsr verafx_slope                  ; edge B, still in fxs_*

    jsr verafx_cmp_b_lt_a             ; carry set: B is the left edge
    bcs _b_left
    jsr verafx_a_x_b_y                ; A (long) left in the X slot,
    lda #1                      ; B right in the Y/X2 slot
    sta fxt_swap                ; part 2 replaces the Y/X2 slot
    bra _pos
_b_left
    jsr verafx_b_x_a_y                ; B left, A (long) right
    stz fxt_swap                ; part 2 replaces the X slot
_pos
    lda tri_x0                  ; both edges start at the apex
    sta fxt_px
    sta fxt_py
    lda tri_x0+1
    sta fxt_px+1
    sta fxt_py+1
    jsr verafx_poly_setup
    lda fxt_n1
    jsr verafx_poly_rows

    lda fxt_n2
    bne _have_part2
    jmp fx_off                  ; flat bottom: one part was the triangle
_have_part2

    ; part 2: the finished short edge becomes v1 -> v2
    lda fxt_n2
    sta fxs_dy
    sec
    lda tri_x2
    sbc tri_x1
    sta fxs_dxl
    lda tri_x2+1
    sbc tri_x1+1
    sta fxs_dxh
    jsr verafx_slope
    #vera_dcsel 3
    lda fxt_swap
    beq _repl_x
    lda fxs_el
    sta VERA_FX_Y_INCR_L
    lda fxs_eh
    sta VERA_FX_Y_INCR_H        ; resets that edge's subpixel to 0.5
    #vera_dcsel 4
    lda tri_x1
    sta VERA_FX_Y_POS_L
    lda tri_x1+1
    and #$07
    sta VERA_FX_Y_POS_H
    bra _part2
_repl_x
    lda fxs_el
    sta VERA_FX_X_INCR_L
    lda fxs_eh
    sta VERA_FX_X_INCR_H
    #vera_dcsel 4
    lda tri_x1
    sta VERA_FX_X_POS_L
    lda tri_x1+1
    and #$07
    sta VERA_FX_X_POS_H
_part2
    #vera_dcsel 5               ; back to the fill-length window
    lda fxt_n2
    jsr verafx_poly_rows
_finish
    jmp fx_off

_flat_top
    ; v0 and v1 share the top row; the second edge is v1 -> v2
    lda fxt_n2
    sta fxs_dy
    sec
    lda tri_x2
    sbc tri_x1
    sta fxs_dxl
    lda tri_x2+1
    sbc tri_x1+1
    sta fxs_dxh
    jsr verafx_slope                  ; edge B = v1 -> v2

    lda tri_x0+1                ; the leftmost vertex owns the X slot
    cmp tri_x1+1
    bne _ft_pick
    lda tri_x0
    cmp tri_x1
_ft_pick
    bcc _ft_v0_left
    jsr verafx_b_x_a_y                ; v1 left: B in X at x1, A in Y at x0
    lda tri_x1
    sta fxt_px
    lda tri_x1+1
    sta fxt_px+1
    lda tri_x0
    sta fxt_py
    lda tri_x0+1
    sta fxt_py+1
    bra _ft_run
_ft_v0_left
    jsr verafx_a_x_b_y                ; v0 left: A in X at x0, B in Y at x1
    lda tri_x0
    sta fxt_px
    lda tri_x0+1
    sta fxt_px+1
    lda tri_x1
    sta fxt_py
    lda tri_x1+1
    sta fxt_py+1
_ft_run
    jsr verafx_poly_setup
    lda fxt_n2
    jsr verafx_poly_rows
    jmp fx_off

; Box A, box B... the triangle's vertices and fill colour, written by
; the caller (see collide16 for the same convention).
tri_x0    .word 0
tri_y0    .byte 0
tri_x1    .word 0
tri_y1    .byte 0
tri_x2    .word 0
tri_y2    .byte 0
tri_color .byte 0

fxt_n1    .byte 0
fxt_n2    .byte 0
fxt_swap  .byte 0
fxt_xl    .byte 0               ; encoded increments for the two slots
fxt_xh    .byte 0
fxt_yl    .byte 0
fxt_yh    .byte 0
fxt_px    .word 0               ; starting x of each edge
fxt_py    .word 0
fxt_a_l   .byte 0               ; the long edge, parked
fxt_a_h   .byte 0
fxt_a_sgn .byte 0
fxt_a_mag .fill 3, 0

; program the polygon helper: mode, both slopes, both positions,
; ADDR0 at the top row (+320/row), ADDR1 stepping +1, DCSEL left at 5.
verafx_poly_setup
    #vera_dcsel 2
    lda #VERA_FX_ADDR1_POLY
    sta VERA_FX_CTRL
    #vera_dcsel 3
    lda fxt_xl
    sta VERA_FX_X_INCR_L
    lda fxt_xh
    sta VERA_FX_X_INCR_H        ; seeds the subpixel to 0.5
    lda fxt_yl
    sta VERA_FX_Y_INCR_L
    lda fxt_yh
    sta VERA_FX_Y_INCR_H
    #vera_dcsel 4
    lda fxt_px
    sta VERA_FX_X_POS_L
    lda fxt_px+1
    and #$07
    sta VERA_FX_X_POS_H
    lda fxt_py
    sta VERA_FX_Y_POS_L
    lda fxt_py+1
    and #$07
    sta VERA_FX_Y_POS_H

    stz X16_P0                  ; ADDR0 = row base of the top row
    stz X16_P1
    lda tri_y0
    sta X16_P2
    jsr verafx_pix_addr
    #vera_addrsel 0
    lda fxa
    sta VERA_ADDR_L
    lda fxa+1
    sta VERA_ADDR_M
    lda fxa+2
    and #VERA_ADDR_H_BANK
    ora #(VERA_INC_320 << 4)
    sta VERA_ADDR_H
    #vera_addrsel 1             ; ADDR1: VERA sets the address, we set +1
    lda #(VERA_INC_1 << 4)
    sta VERA_ADDR_H
    #vera_dcsel 5
    rts

fxt_rows  .byte 0
fxt_fl    .byte 0
fxt_fh    .byte 0
fxt_len   .word 0

; draw A rows. DCSEL must be 5 (poly_setup leaves it there).
verafx_poly_rows
    sta fxt_rows
_prow
    lda fxt_rows
    beq _pdone
    lda VERA_DATA1              ; latch: half-step edges, point ADDR1
    lda VERA_FX_POLY_FILL_L
    sta fxt_fl
    bmi _plong
    lsr                         ; short row: length is bits 4:1
    and #$0F
    sta fxt_len
    stz fxt_len+1
    bra _pdraw
_plong
    lda VERA_FX_POLY_FILL_H
    sta fxt_fh
    and #$C0
    cmp #$C0
    beq _pskip                  ; bits 9+8 set: negative width, no row
    lda fxt_fl
    lsr
    and #$0F
    sta fxt_len
    stz fxt_len+1
    lda fxt_fh
    lsr                         ; H bits 7:1 are length bits 9:3
    asl                         ; ...so shift them up by 3 in 16 bits
    rol fxt_len+1
    asl
    rol fxt_len+1
    asl
    rol fxt_len+1
    ora fxt_len
    sta fxt_len
_pdraw
    ldx fxt_len
    ldy fxt_len+1
    txa
    ora fxt_len+1
    beq _pskip                  ; zero-width row
    txa
    beq _pfull
    iny
_pfull
    lda tri_color
_ploop
    sta VERA_DATA1
    dex
    bne _ploop
    dey
    bne _ploop
_pskip
    lda VERA_DATA0              ; second half-step, ADDR0 to the next row
    dec fxt_rows
    bra _prow
_pdone
    rts

fxs_dxl   .byte 0
fxs_dxh   .byte 0
fxs_dy    .byte 0
fxs_sgn   .byte 0
fxs_32    .byte 0
fxs_mag   .fill 3, 0
fxs_el    .byte 0
fxs_eh    .byte 0

; signed (fxs_dxl/h * 256) / fxs_dy -> the 15-bit (+32x) register
; format in fxs_el/eh, with sign and 24-bit magnitude kept for the
; left/right comparison. *256, not *512: the poly filler wants HALF
; the per-row increment because it steps each edge twice per row.
verafx_slope
    stz fxs_sgn
    lda fxs_dxh
    bpl _sl_abs
    inc fxs_sgn
    sec
    lda #0
    sbc fxs_dxl
    sta fxs_dxl
    lda #0
    sbc fxs_dxh
    sta fxs_dxh
_sl_abs
    stz fxd_num                 ; dividend = |dx| * 256
    lda fxs_dxl
    sta fxd_num+1
    lda fxs_dxh
    sta fxd_num+2
    lda fxs_dy
    sta fxd_den
    stz fxd_den+1
    jsr verafx_udiv24

    lda fxd_num                 ; keep the magnitude for verafx_cmp_b_lt_a
    sta fxs_mag
    lda fxd_num+1
    sta fxs_mag+1
    lda fxd_num+2
    sta fxs_mag+2

    stz fxs_32                  ; encode: 14 bits direct, else /32
    lda fxd_num+2
    bne _sl_big
    lda fxd_num+1
    cmp #$40
    bcc _sl_small
_sl_big
    ldx #5
_sl_shift
    lsr fxd_num+2
    ror fxd_num+1
    ror fxd_num
    dex
    bne _sl_shift
    inc fxs_32
_sl_small
    lda fxd_num
    sta fxs_el
    lda fxd_num+1
    sta fxs_eh
    lda fxs_sgn
    beq _sl_pos
    sec                         ; two's complement within the 15 bits
    lda #0
    sbc fxs_el
    sta fxs_el
    lda #0
    sbc fxs_eh
    and #$7F
    sta fxs_eh
_sl_pos
    lda fxs_32
    beq _sl_done
    lda fxs_eh
    ora #$80                    ; the 32x flag rides on bit 15
    sta fxs_eh
_sl_done
    rts

; hand the two edge slopes to the polygon's position slots
verafx_b_x_a_y
    lda fxs_el
    sta fxt_xl
    lda fxs_eh
    sta fxt_xh
    lda fxt_a_l
    sta fxt_yl
    lda fxt_a_h
    sta fxt_yh
    rts
verafx_a_x_b_y
    lda fxt_a_l
    sta fxt_xl
    lda fxt_a_h
    sta fxt_xh
    lda fxs_el
    sta fxt_yl
    lda fxs_eh
    sta fxt_yh
    rts

; park the fxs_* result as edge A
verafx_save_a
    lda fxs_el
    sta fxt_a_l
    lda fxs_eh
    sta fxt_a_h
    lda fxs_sgn
    sta fxt_a_sgn
    lda fxs_mag
    sta fxt_a_mag
    lda fxs_mag+1
    sta fxt_a_mag+1
    lda fxs_mag+2
    sta fxt_a_mag+2
    rts

; carry set if edge B (fxs_*) is a smaller signed slope than edge A.
; Ties go to A-left, which for coincident edges makes no difference.
verafx_cmp_b_lt_a
    lda fxs_sgn
    cmp fxt_a_sgn
    beq _cmp_same
    lda fxs_sgn                 ; different signs: the negative one is less
    bne _cmp_yes
    clc
    rts
_cmp_same
    lda fxt_a_sgn
    bne _cmp_neg
    lda fxs_mag+2               ; both positive: B < A iff |B| < |A|
    cmp fxt_a_mag+2
    bne _cmp_p
    lda fxs_mag+1
    cmp fxt_a_mag+1
    bne _cmp_p
    lda fxs_mag
    cmp fxt_a_mag
_cmp_p
    bcc _cmp_yes
    clc
    rts
_cmp_neg
    lda fxt_a_mag+2             ; both negative: B < A iff |A| < |B|
    cmp fxs_mag+2
    bne _cmp_n
    lda fxt_a_mag+1
    cmp fxs_mag+1
    bne _cmp_n
    lda fxt_a_mag
    cmp fxs_mag
_cmp_n
    bcc _cmp_yes
    clc
    rts
_cmp_yes
    sec
    rts

; swap two adjacent vertex records (x.w y.b, stride 3): X = 0 swaps
; v0/v1, X = 3 swaps v1/v2
verafx_swapv
    ldy #3
verafx_swl
    lda tri_x0,x
    pha
    lda tri_x0+3,x
    sta tri_x0,x
    pla
    sta tri_x0+3,x
    inx
    dey
    bne verafx_swl
    rts
.endif

; --- shared by the line and polygon helpers --------------------------
; Both fx_line and fx_triangle divide through verafx_udiv24 and find their
; framebuffer start through verafx_pix_addr, so these are emitted whenever
; EITHER gate is on (X16_USE_VERAFX_LINETRI, derived in x16_code.asm --
; a LINE-only build must not need the whole triangle filler for them).
.if xuse_verafx_linetri

fxd_num .fill 3, 0
fxd_den .word 0
fxd_rem .word 0

; fxd_num(24) / fxd_den(16) -> quotient in fxd_num, remainder fxd_rem
verafx_udiv24
    stz fxd_rem
    stz fxd_rem+1
    ldx #24
_dv
    asl fxd_num
    rol fxd_num+1
    rol fxd_num+2
    rol fxd_rem
    rol fxd_rem+1
    sec
    lda fxd_rem
    sbc fxd_den
    tay
    lda fxd_rem+1
    sbc fxd_den+1
    bcc _dv_no
    sta fxd_rem+1
    sty fxd_rem
    inc fxd_num
_dv_no
    dex
    bne _dv
    rts

fxa .fill 3, 0

; fxa = X16_P0/P1 + X16_P2 * 320  (the 17-bit bitmap pixel address)
verafx_pix_addr
    lda X16_P2                  ; y << 6
    stz X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    asl
    rol X16_T3
    sta fxa                     ; low byte of y*64 (and of y*320)
    clc                         ; + y << 8
    lda X16_P2
    adc X16_T3
    sta fxa+1
    lda #0
    adc #0
    sta fxa+2
    clc                         ; + x
    lda fxa
    adc X16_P0
    sta fxa
    lda fxa+1
    adc X16_P1
    sta fxa+1
    lda fxa+2
    adc #0
    sta fxa+2
    rts
.endif

; (end zone)
.endif
.if xuse_verafx_utils
; --- inline gfx/verafx_utils.asm ---
;ACME
; =====================================================================
; x16lib :: gfx/verafx_utils.asm -- low-level VERA FX primitives
; =====================================================================
; Gate: X16_USE_VERAFX_UTILS
;
; These are raw building blocks for custom FX workflows: FX_CTRL/MULT
; control, cache fill/write/cycle toggles, 32-bit cache loading,
; multiplier accumulator triggers, increment/position registers, 16-bit
; hop, and polygon-fill reads.
;
; They are deliberately separate from X16_USE_VERAFX. The existing gate
; remains the high-level helper bundle; this file is for code that wants
; to compose the documented FX registers directly.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; fxu_off -- disable FX helpers and return to DCSEL 0
; ---------------------------------------------------------------------
fxu_off
    #vera_dcsel 2
    stz VERA_FX_CTRL
    stz VERA_FX_MULT
    #vera_dcsel 0
    rts

; ---------------------------------------------------------------------
; FX_CTRL helpers
; ---------------------------------------------------------------------
fxu_get_ctrl
    #vera_dcsel 2
    lda VERA_FX_CTRL
    sta X16_T0
    #vera_dcsel 0
    lda X16_T0
    rts

fxu_set_ctrl
    pha
    #vera_dcsel 2
    pla
    sta VERA_FX_CTRL
    #vera_dcsel 0
    rts

fxu_ctrl_on
    pha
    #vera_dcsel 2
    pla
    tsb VERA_FX_CTRL
    #vera_dcsel 0
    rts

fxu_ctrl_off
    pha
    #vera_dcsel 2
    pla
    trb VERA_FX_CTRL
    #vera_dcsel 0
    rts

; fxu_addr1_mode -- set only the FX_CTRL Addr1 Mode field
;   in: A = VERA_FX_ADDR1_* value
fxu_addr1_mode
    and #%00000011
    sta X16_T0
    #vera_dcsel 2
    lda VERA_FX_CTRL
    and #%11111100
    ora X16_T0
    sta VERA_FX_CTRL
    #vera_dcsel 0
    rts

fxu_cache_write_on
    lda #VERA_FX_CACHE_WRITE
    jmp fxu_ctrl_on

fxu_cache_write_off
    lda #VERA_FX_CACHE_WRITE
    jmp fxu_ctrl_off

fxu_cache_fill_on
    lda #VERA_FX_CACHE_FILL
    jmp fxu_ctrl_on

fxu_cache_fill_off
    lda #VERA_FX_CACHE_FILL
    jmp fxu_ctrl_off

fxu_cache_cycle_on
    lda #VERA_FX_CACHE_CYCLE
    jmp fxu_ctrl_on

fxu_cache_cycle_off
    lda #VERA_FX_CACHE_CYCLE
    jmp fxu_ctrl_off

fxu_transparent_on
    lda #VERA_FX_TRANSPARENT
    jmp fxu_ctrl_on

fxu_transparent_off
    lda #VERA_FX_TRANSPARENT
    jmp fxu_ctrl_off

fxu_4bit_on
    lda #VERA_FX_4BIT_MODE
    jmp fxu_ctrl_on

fxu_4bit_off
    lda #VERA_FX_4BIT_MODE
    jmp fxu_ctrl_off

fxu_hop_on
    lda #VERA_FX_16BIT_HOP
    jmp fxu_ctrl_on

fxu_hop_off
    lda #VERA_FX_16BIT_HOP
    jmp fxu_ctrl_off

; ---------------------------------------------------------------------
; FX_MULT / cache helpers
; ---------------------------------------------------------------------
fxu_set_mult
    pha
    #vera_dcsel 2
    pla
    sta VERA_FX_MULT
    #vera_dcsel 0
    rts

; fxu_set_cache -- set all four bytes of the 32-bit cache
;   in: X16_P0..P3 = cache L, M, H, U
fxu_set_cache
    #vera_dcsel 6
    lda X16_P0
    sta VERA_FX_CACHE_L
    lda X16_P1
    sta VERA_FX_CACHE_M
    lda X16_P2
    sta VERA_FX_CACHE_H
    lda X16_P3
    sta VERA_FX_CACHE_U
    #vera_dcsel 0
    rts

; fxu_reset_accum -- clear the multiplier accumulator
fxu_reset_accum
    #vera_dcsel 6
    lda VERA_FX_ACCUM_RESET
    #vera_dcsel 0
    rts

; fxu_accumulate -- trigger multiply-then-accumulate
fxu_accumulate
    #vera_dcsel 6
    lda VERA_FX_ACCUM
    #vera_dcsel 0
    rts

; fxu_cache_fill0/1 -- read DATA0/1, filling the cache when enabled
;   out: A = byte read from the selected data port
fxu_cache_fill0
    lda VERA_DATA0
    rts

fxu_cache_fill1
    lda VERA_DATA1
    rts

; fxu_cache_write0/1 -- write DATA0/1, flushing the cache when enabled
;   in: A = cache nibble mask
fxu_cache_write0
    sta VERA_DATA0
    rts

fxu_cache_write1
    sta VERA_DATA1
    rts

; ---------------------------------------------------------------------
; Increment, position, tile/map, and polygon-fill helpers
; ---------------------------------------------------------------------
; fxu_set_incr -- set X/Y increment registers
;   in: X16_P0/P1 = X increment, X16_P2/P3 = Y increment
fxu_set_incr
    #vera_dcsel 3
    lda X16_P0
    sta VERA_FX_X_INCR_L
    lda X16_P1
    sta VERA_FX_X_INCR_H
    lda X16_P2
    sta VERA_FX_Y_INCR_L
    lda X16_P3
    sta VERA_FX_Y_INCR_H
    #vera_dcsel 0
    rts

; fxu_set_pos -- set X/Y position registers
;   in: X16_P0/P1 = X position, X16_P2/P3 = Y position
fxu_set_pos
    #vera_dcsel 4
    lda X16_P0
    sta VERA_FX_X_POS_L
    lda X16_P1
    sta VERA_FX_X_POS_H
    lda X16_P2
    sta VERA_FX_Y_POS_L
    lda X16_P3
    sta VERA_FX_Y_POS_H
    #vera_dcsel 0
    rts

; fxu_set_subpos -- set X/Y subpixel registers
;   in: A = X subpixel, X = Y subpixel
fxu_set_subpos
    sta X16_T0
    stx X16_T1
    #vera_dcsel 5
    lda X16_T0
    sta VERA_FX_X_POS_S
    lda X16_T1
    sta VERA_FX_Y_POS_S
    #vera_dcsel 0
    rts

; fxu_get_poly_fill -- read polygon fill length
;   out: A = low byte/nibble pattern, X = high byte
fxu_get_poly_fill
    #vera_dcsel 5
    lda VERA_FX_POLY_FILL_L
    sta X16_T0
    lda VERA_FX_POLY_FILL_H
    sta X16_T1
    #vera_dcsel 0
    lda X16_T0
    ldx X16_T1
    rts

; fxu_set_tilebase / fxu_set_mapbase -- raw affine base register writes
;   in: A = precomposed FX_TILEBASE/FX_MAPBASE value
fxu_set_tilebase
    pha
    #vera_dcsel 2
    pla
    sta VERA_FX_TILEBASE
    #vera_dcsel 0
    rts

fxu_set_mapbase
    pha
    #vera_dcsel 2
    pla
    sta VERA_FX_MAPBASE
    #vera_dcsel 0
    rts

; (end zone)
.endif
.if xuse_clock
; --- inline system/clock.asm ---
;ACME
; =====================================================================
; x16lib :: system/clock.asm -- KERNAL clock and RTC wrappers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The 24-bit timer is the classic KERNAL 60 Hz jiffy counter:
;       jsr clock_get_timer       ; A/X/Y = low/mid/high timer bytes
;       lda #lo : ldx #mid : ldy #hi
;       jsr clock_set_timer
;
; Date/time values use the X16 KERNAL r0..r3 contract:
;       r0L = year since 1900
;       r0H = month
;       r1L = day
;       r1H = hours
;       r2L = minutes
;       r2H = seconds
;       r3L = jiffies
;       r3H = weekday
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; clock_update -- update the KERNAL timer/date-time state
; ---------------------------------------------------------------------
clock_update
    jmp UDTIM

; ---------------------------------------------------------------------
; clock_get_timer -- read the 24-bit 60 Hz timer
;   out: A = bits 0-7, X = bits 8-15, Y = bits 16-23
; ---------------------------------------------------------------------
clock_get_timer
    jmp RDTIM

; ---------------------------------------------------------------------
; clock_set_timer -- set the 24-bit 60 Hz timer
;   in: A = bits 0-7, X = bits 8-15, Y = bits 16-23
; ---------------------------------------------------------------------
clock_set_timer
    jmp SETTIM

; ---------------------------------------------------------------------
; clock_get_date_time -- read the RTC date/time into r0..r3
;   out: r0L year since 1900, r0H month, r1L day, r1H hours,
;        r2L minutes, r2H seconds, r3L jiffies, r3H weekday
; ---------------------------------------------------------------------
clock_get_date_time
    jmp CLOCK_GET_DATE_TIME

; ---------------------------------------------------------------------
; clock_set_date_time -- write the RTC date/time from r0..r3
;   in:  r0L year since 1900, r0H month, r1L day, r1H hours,
;        r2L minutes, r2H seconds, r3L jiffies, r3H weekday
; ---------------------------------------------------------------------
clock_set_date_time
    jmp CLOCK_SET_DATE_TIME

; (end zone)
.endif
.if xuse_irq_any
; --- inline system/irq.asm ---
;ACME
; =====================================================================
; x16lib :: system/irq.asm -- VSYNC counter, raster line and sprite
;                             collision interrupts
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Chains onto the KERNAL's IRQ vector (CINV, $0314) rather than taking
; the interrupt over. Our handler services its own sources and then
; jumps to whatever was there before, so the KERNAL still scans the
; keyboard, moves the mouse, blinks the cursor, and acknowledges the
; VERA VSYNC interrupt.
;
; The KERNAL only ever acknowledges VSYNC. LINE and SPRCOL must be
; acknowledged here (writing their ISR bit), or the moment the handler
; returns the same interrupt fires again and the machine livelocks.
;
; The KERNAL's stub has already pushed A/X/Y by the time it reaches
; CINV, and restores them on the way out, so a chained handler -- and
; the user callbacks below -- are free to clobber the registers.
;
; User callbacks run INSIDE the interrupt. Keep them short, and
; save/restore any VERA state you touch: CTRL (ADDRSEL/DCSEL) and the
; address of any data port you reprogram, or the interrupted code's
; VERA access lands somewhere else when it resumes.
; =====================================================================

; (zone: file scope in 64tass)

irq_old_vector  .word 0
irq_frame_count .byte 0
irq_armed       .byte 0
irq_isr         .byte 0         ; ISR snapshot for the current interrupt

irq_line_vec    .word 0
irq_line_armed  .byte 0
; Sprite collision splits in two: the CAPTURE (the handler accumulates the
; colliding groups into irq_sprcol_mask; you enable VERA_IEN and read the
; mask yourself) is X16_USE_IRQ_SPRCOL; the convenience API on top of it
; (irq_sprcol_install/remove + a callback + sprite_collisions) is
; X16_USE_IRQ_SPRCOL_API. X16_USE_IRQ pulls both, for compat.
.if xuse_irq_sprcol
irq_sprcol_mask .byte 0         ; collision groups seen since last read
.endif
.if xuse_irq_sprcol_api
irq_sprcol_vec  .word 0
irq_sprcol_armed .byte 0
.endif

; ---------------------------------------------------------------------
; irq_handler -- services VSYNC / LINE / SPRCOL, then chains
; ---------------------------------------------------------------------
irq_handler
    lda VERA_ISR
    sta irq_isr

    and #VERA_IRQ_VSYNC
    beq _no_vsync
    inc irq_frame_count         ; the KERNAL acks VSYNC for us
_no_vsync

    lda irq_isr
    and #VERA_IRQ_LINE
    beq _no_line
    sta VERA_ISR                ; ack FIRST: nobody else will
    lda irq_line_armed
    beq _no_line
    jsr irq_call_line
_no_line

.if xuse_irq_sprcol
    lda irq_isr
    and #VERA_IRQ_SPRCOL
    beq _no_sprcol
    sta VERA_ISR                ; ack FIRST: nobody else will
    lda irq_isr
    and #VERA_ISR_COLLISION     ; which collision groups fired (bits 7:4)
    ora irq_sprcol_mask         ; accumulate until it is read
    sta irq_sprcol_mask
.if xuse_irq_sprcol_api
    lda irq_sprcol_armed
    beq _no_sprcol
    lda irq_isr
    and #VERA_ISR_COLLISION
    jsr irq_call_sprcol            ; A = the collision groups
.endif
_no_sprcol
.endif

.if xuse_pcm_stream
    lda irq_isr
    and #VERA_IRQ_AFLOW
    beq _no_aflow
    jsr pcm_stream_isr          ; refilling the FIFO IS the acknowledge
_no_aflow
.endif

    jmp (irq_old_vector)

irq_call_line
    jmp (irq_line_vec)
.if xuse_irq_sprcol_api
irq_call_sprcol
    jmp (irq_sprcol_vec)
.endif

; ---------------------------------------------------------------------
; irq_install -- hook CINV and start counting frames. Idempotent.
; ---------------------------------------------------------------------
irq_install
    lda irq_armed
    bne _done

    php                         ; restore the caller's I flag afterwards,
    sei                         ; rather than a blind cli
    lda CINV
    sta irq_old_vector
    lda CINV+1
    sta irq_old_vector+1
    lda #<irq_handler
    sta CINV
    lda #>irq_handler
    sta CINV+1
    stz irq_frame_count
    lda #VERA_IRQ_VSYNC
    tsb VERA_IEN                ; the KERNAL already enables it; harmless
    lda #1
    sta irq_armed
    plp
_done
    rts

; ---------------------------------------------------------------------
; irq_remove -- restore the previous handler and disable our sources
; A permanent hook never removes itself, so irq_remove is behind
; X16_USE_IRQ_REMOVE (X16_USE_IRQ still pulls it, for compat).
; ---------------------------------------------------------------------
.if xuse_irq_remove
irq_remove
    lda irq_armed
    beq _done
    php
    sei
    ; AFLOW must be in this mask. It cannot be acknowledged in ISR --
    ; it clears only when the FIFO refills -- and once CINV is back on
    ; the KERNAL, nothing refills: VERA holds the IRQ line asserted,
    ; the KERNAL handler acks VSYNC and returns, and the machine
    ; livelocks. Removing the hook mid-stream must take AFLOW with it.
    lda #(VERA_IRQ_LINE | VERA_IRQ_SPRCOL | VERA_IRQ_AFLOW)
    trb VERA_IEN                ; ours alone; VSYNC stays for the KERNAL
    stz irq_line_armed
.if xuse_irq_sprcol_api
    stz irq_sprcol_armed
.endif
.if xuse_pcm_stream
    stz pcm_str_active          ; the stream cannot continue unhooked
.endif
    lda irq_old_vector
    sta CINV
    lda irq_old_vector+1
    sta CINV+1
    stz irq_armed
    plp
_done
    rts
.endif

; ---------------------------------------------------------------------
; irq_line_install -- call a handler at a given scanline, every frame
;   in:  A = handler low, X = handler high
;        X16_P0/P1 = scanline (0-511; the visible display is 0-479)
;
; The handler runs inside the IRQ (registers free, keep it short). A
; raster split changes VERA display registers here and changes them
; back in a second line handler or in the VSYNC path.
; ---------------------------------------------------------------------
irq_line_install
    pha                         ; irq_install clobbers A -- and A/X are
    phx                         ; the handler this routine exists to keep
    jsr irq_install             ; make sure the CINV hook is in place
    plx
    pla
    php
    sei
    sta irq_line_vec
    stx irq_line_vec+1
    lda X16_P0
    sta VERA_IRQ_LINE_L
    lda X16_P1
    lsr                         ; scanline bit 8 -> carry
    lda #$80                    ; ...lives in IEN bit 7
    bcs _bit8_set
    trb VERA_IEN
    bra _bit8_done
_bit8_set
    tsb VERA_IEN
_bit8_done
    lda #VERA_IRQ_LINE
    sta VERA_ISR                ; drop any stale pending LINE interrupt
    lda #1
    sta irq_line_armed
    lda #VERA_IRQ_LINE
    tsb VERA_IEN
    plp
    rts

irq_line_remove
    php
    sei
    lda #VERA_IRQ_LINE
    trb VERA_IEN
    sta VERA_ISR                ; ack anything still pending
    stz irq_line_armed
    plp
    rts

; ---------------------------------------------------------------------
; The sprite-collision convenience API (X16_USE_IRQ_SPRCOL_API): enable
; the interrupt with a poll or callback handler, and read the groups. It
; sits on top of the CAPTURE above -- a program that enables VERA_IEN's
; collision bit itself and reads irq_sprcol_mask directly needs only
; X16_USE_IRQ_SPRCOL and drops all of this.
; ---------------------------------------------------------------------
.if xuse_irq_sprcol_api
; ---------------------------------------------------------------------
; irq_sprcol_install -- enable the sprite collision interrupt
;   in:  A = handler low, X = handler high -- or A = X = 0 for polling
;
; VERA reports collisions between sprites whose collision masks (the
; top nibble of attribute byte 6, see sprite_flags) share a bit, once
; per frame at the end of rendering. The handler receives the group
; bits in A. With a null handler nothing is called, but the groups
; still accumulate for sprite_collisions below.
; ---------------------------------------------------------------------
irq_sprcol_install
    pha                         ; irq_install clobbers A
    phx
    jsr irq_install
    plx
    pla
    php
    sei
    sta irq_sprcol_vec
    stx irq_sprcol_vec+1
    ora irq_sprcol_vec+1        ; A|X == 0 -> poll-only, no callback
    beq _polling
    lda #1
_polling
    sta irq_sprcol_armed
    stz irq_sprcol_mask
    lda #VERA_IRQ_SPRCOL
    sta VERA_ISR                ; drop any stale pending collision
    tsb VERA_IEN
    plp
    rts

irq_sprcol_remove
    php
    sei
    lda #VERA_IRQ_SPRCOL
    trb VERA_IEN
    sta VERA_ISR
    stz irq_sprcol_armed
    plp
    rts

; ---------------------------------------------------------------------
; sprite_collisions -- read and clear the accumulated collision groups
;   out: A = group bits seen since the last call (ISR bits 7:4), Z set
;        if none. Requires irq_sprcol_install (a null handler is fine).
; ---------------------------------------------------------------------
sprite_collisions
    php
    sei                         ; read-and-clear must be atomic against
    lda irq_sprcol_mask         ; the accumulating interrupt handler
    stz irq_sprcol_mask
    plp                         ; ...but plp restores the CALLER's flags,
    ora #0                      ; so re-derive Z from A afterwards
    rts
.endif

; ---------------------------------------------------------------------
; irq_save_regs / irq_restore_regs -- bracket a callback that calls
; library routines.
;
; The KERNAL's virtual registers r0-r15 ($02-$21) and the library's
; X16_P0..X16_T7 block are ordinary zero page: whatever the interrupt
; cut off may be holding live values there. mem_copy loads r0-r2 and
; runs with interrupts enabled -- a callback that calls another mem_*,
; mouse_get, or anything using the parameter block would corrupt the
; interrupted copy's pointers on resume.
;
; A callback that only touches A/X/Y and its own variables needs
; nothing. One that calls into the library does:
;
;       my_handler
;           jsr irq_save_regs
;           ...anything at all...
;           jsr irq_restore_regs
;           rts
;
; One buffer, no nesting -- interrupts do not nest here either.
; Clobbers A and X.
; ---------------------------------------------------------------------
irq_save_regs
    ldx #31
_save_r
    lda r0L,x                   ; r0-r15 at $02-$21
    sta irq_zp_buf,x
    dex
    bpl _save_r
    ldx #15
_save_p
    lda X16_P0,x                ; the library's parameter/scratch block
    sta irq_zp_buf+32,x
    dex
    bpl _save_p
    rts

irq_restore_regs
    ldx #31
_rest_r
    lda irq_zp_buf,x
    sta r0L,x
    dex
    bpl _rest_r
    ldx #15
_rest_p
    lda irq_zp_buf+32,x
    sta X16_P0,x
    dex
    bpl _rest_p
    rts

irq_zp_buf .fill 48, 0

; ---------------------------------------------------------------------
; irq_frames
;   out: A = the frame counter (wraps at 256)
;
; Byte subtraction wraps correctly, so deltas are valid across the wrap:
;       jsr irq_frames : sta start
;       ... work ...
;       jsr irq_frames : sec : sbc start   ; = frames elapsed
; ---------------------------------------------------------------------
irq_frames
    lda irq_frame_count
    rts

; ---------------------------------------------------------------------
; vsync_wait -- block until the next frame boundary.
;
; Frame-locked: it waits for the counter to change rather than polling
; VERA, so it cannot miss a frame or spin twice within one. Requires
; irq_install, and interrupts enabled -- it will hang otherwise. A
; program that drives its own loop from irq_frames does not need it, so
; it is behind X16_USE_IRQ_VSYNC (X16_USE_IRQ still pulls it, for compat).
; ---------------------------------------------------------------------
.if xuse_irq_vsync
vsync_wait
    lda irq_frame_count
_wait
    cmp irq_frame_count
    beq _wait
    rts
.endif

; (end zone)
.endif
.if xuse_psg
; --- inline audio/psg.asm ---
;ACME
; =====================================================================
; x16lib :: audio/psg.asm -- VERA PSG (16 voices)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; Requires X16_USE_VERA (psg_init uses vera_fill).
;
; The voices live in VRAM at $1F9C0, four bytes each:
;   0  frequency 7:0
;   1  frequency 15:8
;   2  right(7) | left(6) | volume(5:0)
;   3  waveform(7:6) | pulse width or XOR(5:0)
;
; output_frequency = 25000000/512 / 2`17 * freq_word
;   -> freq_word = Hz * 2.68435 (approximately), so A4 (440 Hz) is 1181.
;
; That VRAM range is write-only. Reads return the last value the host
; wrote, so psg_get_* only report what this program last set.
; =====================================================================

; (zone: file scope in 64tass)

PSG_PAN_LEFT  = %01000000
PSG_PAN_RIGHT = %10000000
PSG_PAN_BOTH  = %11000000

PSG_WAVE_PULSE    = %00000000
PSG_WAVE_SAWTOOTH = %01000000
PSG_WAVE_TRIANGLE = %10000000
PSG_WAVE_NOISE    = %11000000

; ---------------------------------------------------------------------
; psg_voice_ptr -- point data port 0 at a voice register
;   in:  X = voice (0-15), A = byte offset within the voice (0-3)
; ---------------------------------------------------------------------
psg_voice_ptr
    sta X16_T2
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL

    txa
    asl
    asl                         ; voice * 4, never carries (max 60)
    clc
    adc X16_T2
    clc
    adc #<VRAM_PSG              ; $C0 + up to 63, may carry
    sta VERA_ADDR_L
    lda #>VRAM_PSG
    adc #0
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))
    sta VERA_ADDR_H
    rts

; ---------------------------------------------------------------------
; psg_init -- silence all 16 voices
; ---------------------------------------------------------------------
psg_init
    #vera_addr 0, VRAM_PSG, VERA_INC_1
    lda #0
    ldx #(16 * VERA_PSG_VOICE_SIZE)
    ldy #0
    jmp vera_fill

; ---------------------------------------------------------------------
; psg_set_freq -- in: X = voice, X16_P0/P1 = frequency word
;
; The HIGH byte is written first, stepping the port DOWNWARD from
; offset 1. Low-byte-first leaves the voice running on new-low/old-high
; for a few cycles -- an audible click on every pitch change.
; ---------------------------------------------------------------------
psg_set_freq
    lda #1                      ; point at freq bits 15:8
    jsr psg_voice_ptr
    lda VERA_ADDR_H
    ora #VERA_ADDR_H_DECR       ; ...and walk backwards
    sta VERA_ADDR_H
    lda X16_P1
    sta VERA_DATA0              ; high byte first
    lda X16_P0
    sta VERA_DATA0              ; then low, at offset 0
    rts

; ---------------------------------------------------------------------
; psg_set_vol -- in: X = voice, A = volume (0-63), Y = pan (PSG_PAN_*)
; ---------------------------------------------------------------------
psg_set_vol
    and #$3F
    sta X16_T3
    tya
    and #PSG_PAN_BOTH
    ora X16_T3
    sta X16_T3
    lda #2
    jsr psg_voice_ptr
    lda X16_T3
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; psg_set_wave -- in: X = voice, A = waveform (PSG_WAVE_*),
;                     Y = pulse width / XOR (0-63)
; ---------------------------------------------------------------------
psg_set_wave
    and #PSG_WAVE_NOISE         ; keep bits 7:6
    sta X16_T3
    tya
    and #$3F
    ora X16_T3
    sta X16_T3
    lda #3
    jsr psg_voice_ptr
    lda X16_T3
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; psg_note_off -- in: X = voice.  Volume to zero, everything else kept.
; ---------------------------------------------------------------------
psg_note_off
    lda #2
    jsr psg_voice_ptr
    lda VERA_DATA0              ; the host-written shadow
    and #PSG_PAN_BOTH           ; keep the panning, drop the volume
    pha
    lda #2
    jsr psg_voice_ptr
    pla
    sta VERA_DATA0
    rts

; =====================================================================
; ASR envelopes -- the decay everybody hand-rolls in the frame loop
; (bounce.asm included). Per voice: attack ramps the volume to a peak,
; sustain holds it for a tick count, release ramps it back to silence.
; Drive psg_env_tick once per frame -- from vsync_wait's loop or a
; VSYNC callback (bracket library calls there with irq_save_regs).
; =====================================================================

; ---------------------------------------------------------------------
; psg_env_start -- (re)trigger a voice's envelope
;   in:  A = voice (0-15)
;        X16_P0 = peak volume (0-63)
;        X16_P1 = attack step per tick (0 = jump straight to the peak)
;        X16_P2 = sustain ticks at the peak (0 = release immediately,
;                 255 = until psg_env_release)
;        X16_P3 = release step per tick (0 = hold until psg_env_stop)
;
; Set the voice's frequency, wave and pan first (psg_set_vol's pan is
; preserved; only the volume bits are driven).
; ---------------------------------------------------------------------
psg_env_start
    and #$0F
    tax
    lda X16_P0
    and #$3F
    sta env_peak,x
    lda X16_P1
    sta env_astep,x
    lda X16_P2
    sta env_sus,x
    lda X16_P3
    sta env_rstep,x
    lda X16_P1
    beq _instant
    stz env_vol,x
    lda #1                      ; stage 1: attack
    sta env_stage,x
    rts
_instant
    lda env_peak,x
    sta env_vol,x
    lda #2                      ; straight to sustain
    sta env_stage,x
    jmp psg_env_write              ; make the jump audible immediately

; ---------------------------------------------------------------------
; psg_env_release -- in: A = voice. Enter the release phase now.
; psg_env_stop    -- in: A = voice. Silence and disarm immediately.
; ---------------------------------------------------------------------
psg_env_release
    and #$0F
    tax
    lda env_stage,x
    beq _done                   ; not playing
    lda #3
    sta env_stage,x
_done
    rts

psg_env_stop
    and #$0F
    tax
    stz env_stage,x
    stz env_vol,x
    jmp psg_env_write

; ---------------------------------------------------------------------
; psg_env_tick -- advance every armed envelope one step and write the
; changed volumes to the PSG. Call once per frame. Clobbers A/X/Y and
; the port-0 address.
; ---------------------------------------------------------------------
psg_env_tick
    ldx #15
_voice
    lda env_stage,x
    beq _next                   ; 0: idle
    cmp #2
    beq _sustain
    bcc _attack                 ; 1

    ; --- release ---
    lda env_rstep,x
    beq _next                   ; rstep 0: hold until psg_env_stop
    sta X16_T0
    lda env_vol,x
    sec
    sbc X16_T0
    bcs _rel_ok
    lda #0
_rel_ok
    sta env_vol,x
    bne _write
    stz env_stage,x             ; faded out: disarm
    bra _write

_attack
    lda env_vol,x
    clc
    adc env_astep,x
    cmp env_peak,x
    bcc _att_ok
    lda env_peak,x              ; reached (or overshot) the peak
    pha
    lda #2
    sta env_stage,x
    pla
_att_ok
    sta env_vol,x
    bra _write

_sustain
    lda env_sus,x
    cmp #255
    beq _next                   ; 255: hold until psg_env_release
    dec env_sus,x
    bne _next
    lda #3                      ; sustain over: release
    sta env_stage,x
    bra _next                   ; volume unchanged this tick

_write
    jsr psg_env_write
_next
    dex
    bpl _voice
    rts

; write voice X's env_vol to its volume bits, preserving the pan bits
; (via the host-readback shadow, like psg_note_off). Preserves X --
; psg_voice_ptr does too.
psg_env_write
    lda #2
    jsr psg_voice_ptr
    lda VERA_DATA0              ; the shadow's pan bits
    and #PSG_PAN_BOTH
    ora env_vol,x
    sta X16_T0
    lda #2
    jsr psg_voice_ptr
    lda X16_T0
    sta VERA_DATA0
    rts

env_stage .fill 16, 0
env_vol   .fill 16, 0
env_peak  .fill 16, 0
env_astep .fill 16, 0
env_sus   .fill 16, 0
env_rstep .fill 16, 0

; (end zone)
.endif
.if xuse_ym
; --- inline audio/ym.asm ---
;ACME
; =====================================================================
; x16lib :: audio/ym.asm -- YM2151 FM synthesiser
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The chip is at YM_REG ($9F40) and YM_DATA ($9F41). Note: NOT $9FE0.
;
; Two ways in, and they do not mix freely:
;
;   ym_write   writes a chip register directly. Fast, complete access to
;              everything (LFO, per-operator envelopes) -- but the ROM
;              audio driver keeps RAM shadows of volume and pan, and a
;              raw write leaves those stale.
;
;   ym_poke    goes through the ROM driver in BANK_AUDIO, keeping its
;              shadows coherent. Use this if you also use the note API.
;
; This is the AUDIOYM.TXT distinction between YM! and FMPOKE.
; =====================================================================

; (zone: file scope in 64tass)

YM_TIMEOUT = 128                ; busy-wait spins before giving up
YM_BUSY    = %10000000          ; YM_DATA bit 7 while the chip is busy

; ---------------------------------------------------------------------
; ym_write -- raw register write
;   in:  A = value, X = register
;   out: carry clear on success, set if the chip stayed busy
;   Preserves A and X.
;
; The busy flag must be clear before touching YM_REG, and the chip needs
; settling time between the register select and the data write. Wrapped
; in sei so an interrupt cannot land between the two halves and leave a
; half-issued write behind.
; ---------------------------------------------------------------------
ym_write
    php
    sei

    ldy #YM_TIMEOUT
_wait
    dey
    bmi _timeout
    bit YM_DATA
    bmi _wait                   ; busy

    stx YM_REG
    nop                         ; settling time between select and data
    nop
    nop
    sta YM_DATA

    plp
    clc
    rts
_timeout
    plp
    sec
    rts

; ---------------------------------------------------------------------
; ym_busy -- out: carry set while the chip is busy
; ---------------------------------------------------------------------
ym_busy
    lda YM_DATA
    asl                         ; bit 7 into carry
    rts

; ---------------------------------------------------------------------
; ROM driver entry points. All of these live in BANK_AUDIO at $C000+,
; not in the $FFxx jump table, so they go through jsrfar.
;
; jsrfar restores the callee's processor status on the way out, so the
; carry flag survives in BOTH directions: you can pass a flag in (as
; ym_patch does) and read a result out.
;
; ***  THE CHANNEL GOES IN ym_A, NOT ym_X.  ***
; Every one of these takes the FM channel (0-7) in ym_A and its payload in
; ym_X. That is the opposite of what the register-level ym_write does, and
; the opposite of what you would guess. Getting it backwards plays a
; valid-looking note on the wrong channel rather than failing.
; ---------------------------------------------------------------------

; ym_init -- reset the chip and load the default instrument patches
;   out: carry set on failure
ym_init
    #jsrfar rom_audio_init, BANK_AUDIO
    #jsrfar rom_ym_loaddefpatches, BANK_AUDIO
    rts

; ym_poke -- in: A = value, X = register.  Keeps the driver's shadows
;            coherent, unlike ym_write.  Preserves A and X.
ym_poke
    #jsrfar rom_ym_write, BANK_AUDIO
    rts

; ym_patch -- load an instrument
;   in:  A = channel (0-7)
;        carry set: X = ROM patch index (0-162)
;        carry clear: X/Y = address of a patch in RAM
;   out: carry set on failure
ym_patch
    #jsrfar rom_ym_loadpatch, BANK_AUDIO
    rts

; ym_note -- play a raw YM2151 key code
;   in:  A = channel, X = KC (key code), Y = KF (key fraction / bend)
;        carry clear to retrigger the envelope, set to just change pitch
ym_note
    #jsrfar rom_ym_playnote, BANK_AUDIO
    rts

; ym_note_bas -- play a packed note, the FMNOTE of AUDIOFM.TXT
;   in:  A = channel, X = (octave << 4) | 1..12,  X = 0 releases
;        carry clear to retrigger
;   out: carry set on failure
;
; Goes through the ROM's BASIC shim, which converts the packed note to a
; key code for us. This is the one you want for playing tunes.
ym_note_bas
    #jsrfar rom_bas_fmnote, BANK_AUDIO
    rts

; ym_release_note -- in: A = channel
ym_release_note
    #jsrfar rom_ym_release, BANK_AUDIO
    rts

; ym_vol -- in: A = channel, X = attenuation (0 = the patch's own volume,
;                                             larger = quieter)
ym_vol
    #jsrfar rom_ym_setatten, BANK_AUDIO
    rts

; ym_pan -- in: A = channel, X = 0 off, 1 left, 2 right, 3 both
ym_pan
    #jsrfar rom_ym_setpan, BANK_AUDIO
    rts

; ym_get_pan -- in: A = channel.  out: X = pan setting
; ym_get_vol -- in: A = channel.  out: X = attenuation
;
; Read the ROM driver's shadows. These only agree with the chip if you
; have been writing through ym_poke / ym_vol / ym_pan rather than the
; raw ym_write.
ym_get_pan
    #jsrfar rom_ym_getpan, BANK_AUDIO
    rts

ym_get_vol
    #jsrfar rom_ym_getatten, BANK_AUDIO
    rts

; ym_drum -- in: A = channel, X = drum note (25-87)
ym_drum
    #jsrfar rom_ym_playdrum, BANK_AUDIO
    rts

; (end zone)
.endif
.if xuse_audio_rom
; --- inline audio/rom.asm ---
;ACME
; =====================================================================
; x16lib :: audio/rom.asm -- BANK_AUDIO API wrappers
; =====================================================================
; Gate: X16_USE_AUDIO_ROM
;
; Thin wrappers over the Commander X16 ROM audio bank. These calls keep
; the ROM driver's PSG/YM volume, pan, attenuation and patch shadows
; coherent. They are intentionally separate from X16_USE_PSG/X16_USE_YM,
; whose existing local helpers remain unchanged.
;
; Prefix convention: ar_* = audio ROM.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; BASIC-compatible FM/PSG utility and play-string calls.
; ---------------------------------------------------------------------
ar_fmfreq             ; in: A=channel, X/Y=Hz, C set=no retrigger
    #jsrfar rom_bas_fmfreq, BANK_AUDIO
    rts

ar_fmnote             ; in: A=channel, X=(octave<<4)|note, Y=KF, C set=no retrigger
    #jsrfar rom_bas_fmnote, BANK_AUDIO
    rts

ar_fmplaystring       ; in: A=length, X/Y=string pointer
    #jsrfar rom_bas_fmplaystring, BANK_AUDIO
    rts

ar_fmvib              ; in: A=LFO speed, X=depth
    #jsrfar rom_bas_fmvib, BANK_AUDIO
    rts

ar_playstring_voice   ; in: A=voice/channel for next play-string call
    #jsrfar rom_bas_playstringvoice, BANK_AUDIO
    rts

ar_psgfreq            ; in: A=voice, X/Y=Hz
    #jsrfar rom_bas_psgfreq, BANK_AUDIO
    rts

ar_psgnote            ; in: A=voice, X=(octave<<4)|note, Y=KF
    #jsrfar rom_bas_psgnote, BANK_AUDIO
    rts

ar_psgwav             ; in: A=voice, X=waveform+duty
    #jsrfar rom_bas_psgwav, BANK_AUDIO
    rts

ar_psgplaystring      ; in: A=length, X/Y=string pointer
    #jsrfar rom_bas_psgplaystring, BANK_AUDIO
    rts

ar_fmchordstring      ; in: A=length, X/Y=string pointer
    #jsrfar rom_bas_fmchordstring, BANK_AUDIO
    rts

ar_psgchordstring     ; in: A=length, X/Y=string pointer
    #jsrfar rom_bas_psgchordstring, BANK_AUDIO
    rts

; ---------------------------------------------------------------------
; Note conversion helpers.
;   Carry set means invalid input; failed calls return X/Y = 0.
;   FM output:  X = KC, Y = KF where applicable.
;   PSG output: X = frequency low, Y = frequency high.
; ---------------------------------------------------------------------
ar_note_bas2fm        ; in: X=BASIC note, out: A=X=YM KC
    #jsrfar rom_notecon_bas2fm, BANK_AUDIO
    rts

ar_note_bas2midi      ; in: X=BASIC note, out: A=X=MIDI note
    #jsrfar rom_notecon_bas2midi, BANK_AUDIO
    rts

ar_note_bas2psg       ; in: X=BASIC note, Y=KF, out: X/Y=PSG freq
    #jsrfar rom_notecon_bas2psg, BANK_AUDIO
    rts

ar_note_fm2bas        ; in: X=YM KC, out: A=X=BASIC note
    #jsrfar rom_notecon_fm2bas, BANK_AUDIO
    rts

ar_note_fm2midi       ; in: X=YM KC, out: A=X=MIDI note
    #jsrfar rom_notecon_fm2midi, BANK_AUDIO
    rts

ar_note_fm2psg        ; in: X=YM KC, Y=KF, out: X/Y=PSG freq
    #jsrfar rom_notecon_fm2psg, BANK_AUDIO
    rts

ar_note_freq2bas      ; in: X/Y=Hz, out: X=BASIC note, Y=KF
    #jsrfar rom_notecon_freq2bas, BANK_AUDIO
    rts

ar_note_freq2fm       ; in: X/Y=Hz, out: X=KC, Y=KF
    #jsrfar rom_notecon_freq2fm, BANK_AUDIO
    rts

ar_note_freq2midi     ; in: X/Y=Hz, out: X=MIDI note, Y=KF
    #jsrfar rom_notecon_freq2midi, BANK_AUDIO
    rts

ar_note_freq2psg      ; in: X/Y=Hz, out: X/Y=PSG freq
    #jsrfar rom_notecon_freq2psg, BANK_AUDIO
    rts

ar_note_midi2bas      ; in: A=MIDI note, out: A=X=BASIC note
    #jsrfar rom_notecon_midi2bas, BANK_AUDIO
    rts

ar_note_midi2fm       ; in: X=MIDI note, out: A=X=YM KC
    #jsrfar rom_notecon_midi2fm, BANK_AUDIO
    rts

ar_note_midi2psg      ; in: X=MIDI note, Y=KF, out: X/Y=PSG freq
    #jsrfar rom_notecon_midi2psg, BANK_AUDIO
    rts

ar_note_psg2bas       ; in: X/Y=PSG freq, out: X=BASIC note, Y=KF
    #jsrfar rom_notecon_psg2bas, BANK_AUDIO
    rts

ar_note_psg2fm        ; in: X/Y=PSG freq, out: X=KC, Y=KF
    #jsrfar rom_notecon_psg2fm, BANK_AUDIO
    rts

ar_note_psg2midi      ; in: X/Y=PSG freq, out: X=MIDI note, Y=KF
    #jsrfar rom_notecon_psg2midi, BANK_AUDIO
    rts

; ---------------------------------------------------------------------
; ROM PSG API.
; ---------------------------------------------------------------------
ar_psg_init
    #jsrfar rom_psg_init, BANK_AUDIO
    rts

ar_psg_playfreq       ; in: A=voice, X/Y=PSG frequency
    #jsrfar rom_psg_playfreq, BANK_AUDIO
    rts

ar_psg_read           ; in: X=PSG register, C set=cooked volume; out: A=value
    #jsrfar rom_psg_read, BANK_AUDIO
    rts

ar_psg_setatten       ; in: A=voice, X=attenuation
    #jsrfar rom_psg_setatten, BANK_AUDIO
    rts

ar_psg_setfreq        ; in: A=voice, X/Y=PSG frequency
    #jsrfar rom_psg_setfreq, BANK_AUDIO
    rts

ar_psg_setpan         ; in: A=voice, X=0 off, 1 left, 2 right, 3 both
    #jsrfar rom_psg_setpan, BANK_AUDIO
    rts

ar_psg_setvol         ; in: A=voice, X=volume
    #jsrfar rom_psg_setvol, BANK_AUDIO
    rts

ar_psg_write          ; in: A=value, X=PSG register
    #jsrfar rom_psg_write, BANK_AUDIO
    rts

ar_psg_getatten       ; in: A=voice, out: X=attenuation
    #jsrfar rom_psg_getatten, BANK_AUDIO
    rts

ar_psg_getpan         ; in: A=voice, out: X=pan
    #jsrfar rom_psg_getpan, BANK_AUDIO
    rts

ar_psg_write_fast     ; in: A=value, X=PSG register; caller prepoints VERA
    #jsrfar rom_psg_write_fast, BANK_AUDIO
    rts

; ---------------------------------------------------------------------
; ROM YM/FM API.
; ---------------------------------------------------------------------
ar_ym_init
    #jsrfar rom_ym_init, BANK_AUDIO
    rts

ar_ym_loaddefpatches
    #jsrfar rom_ym_loaddefpatches, BANK_AUDIO
    rts

ar_ym_loadpatch       ; in: A=channel; C set X=ROM patch, C clear X/Y=RAM patch
    #jsrfar rom_ym_loadpatch, BANK_AUDIO
    rts

ar_ym_loadpatchlfn    ; in: A=channel, X=logical file number
    #jsrfar rom_ym_loadpatchlfn, BANK_AUDIO
    rts

ar_ym_playdrum        ; in: A=channel, X=drum MIDI note
    #jsrfar rom_ym_playdrum, BANK_AUDIO
    rts

ar_ym_playnote        ; in: A=channel, X=KC, Y=KF, C set=no retrigger
    #jsrfar rom_ym_playnote, BANK_AUDIO
    rts

ar_ym_setatten        ; in: A=channel, X=attenuation
    #jsrfar rom_ym_setatten, BANK_AUDIO
    rts

ar_ym_setdrum         ; in: A=channel, X=drum MIDI note; does not trigger
    #jsrfar rom_ym_setdrum, BANK_AUDIO
    rts

ar_ym_setnote         ; in: A=channel, X=KC, Y=KF; does not trigger
    #jsrfar rom_ym_setnote, BANK_AUDIO
    rts

ar_ym_setpan          ; in: A=channel, X=0 off, 1 left, 2 right, 3 both
    #jsrfar rom_ym_setpan, BANK_AUDIO
    rts

ar_ym_read            ; in: X=YM register, C set=cooked TL; out: A=value
    #jsrfar rom_ym_read, BANK_AUDIO
    rts

ar_ym_release         ; in: A=channel
    #jsrfar rom_ym_release, BANK_AUDIO
    rts

ar_ym_trigger         ; in: A=channel, C set=no retrigger
    #jsrfar rom_ym_trigger, BANK_AUDIO
    rts

ar_ym_write           ; in: A=value, X=YM register; preserves shadows
    #jsrfar rom_ym_write, BANK_AUDIO
    rts

ar_ym_getatten        ; in: A=channel, out: X=attenuation
    #jsrfar rom_ym_getatten, BANK_AUDIO
    rts

ar_ym_getpan          ; in: A=channel, out: X=pan
    #jsrfar rom_ym_getpan, BANK_AUDIO
    rts

ar_audio_init         ; init YM, PSG, and default patches
    #jsrfar rom_audio_init, BANK_AUDIO
    rts

ar_ym_get_chip_type   ; out: A=0 none, 1 OPP, 2 OPM, 3 unexpected
    #jsrfar rom_ym_get_chip_type, BANK_AUDIO
    rts

; (end zone)
.endif
.if xuse_zsm
; --- inline audio/zsm.asm ---
;ACME
; =====================================================================
; x16lib :: audio/zsm.asm -- compact ZSM stream player
; =====================================================================
; Gate: X16_USE_ZSM
;
; Supports ZSM revision 1 streams loaded in normal 16-bit address space:
;   - ZSM header validation ('z','m'), stream starts at header+16
;   - PSG register writes
;   - YM2151 register/value batch writes
;   - delay commands, EOF, and 16-bit loop offsets
;   - PCM EXTCMD channel 0 commands 0/1 (AUDIO_CTRL/AUDIO_RATE)
;
; X16_USE_ZSM_PCM adds PCM instrument triggers from the optional PCM
; table. This first PCM layer supports memory-resident sample data in
; 16-bit address space and uses the existing AFLOW PCM streamer.
;
; Call zsm_tick at the ZSM header's tick rate. Use zsm_get_tickrate after
; ; ---------------------------------------------------------------------
; zsm_lasterr -- why the last zsm_init failed
;   out: A = ZSM_ERR_* (ZSM_ERR_NONE after one that worked)
;
; zsm_init answers with both a carry and a code, and a caller that can
; only read one of them needs the code: "it would not start" is not much
; to go on when the answer is that the file is a version too new.
; ---------------------------------------------------------------------
zsm_lasterr
    lda zsm_code
    rts

zsm_init if you need to configure your scheduler.
; =====================================================================

; (zone: file scope in 64tass)

ZSM_ERR_NONE    = 0
ZSM_ERR_MAGIC   = 1
ZSM_ERR_VERSION = 2
ZSM_ERR_RANGE   = 3
ZSM_ERR_PCM     = 4

zsm_code        .byte 0         ; the last ZSM_ERR_*, for zsm_lasterr

ZSM_FLAG_ACTIVE = %00000001
ZSM_FLAG_LOOP   = %00000010
ZSM_FLAG_EOF    = %00000100
ZSM_FLAG_PCM    = %00001000

ZSM_MAX_VERSION = 1
ZSM_YM_TIMEOUT  = 128

.if xuse_zsm_pcm
ZSM_PCM_FIFO_RESET = %10000000
ZSM_PCM_16BIT      = %00100000
ZSM_PCM_STEREO     = %00010000
.endif

; ---------------------------------------------------------------------
; zsm_init -- initialize from a ZSM file header
;   in:  r0 = pointer to the 16-byte ZSM header
;   out: carry clear on success
;        carry set on failure, A = ZSM_ERR_*
;
; Only 16-bit loop offsets are supported. A file with loop offset bit
; 16 set returns ZSM_ERR_RANGE.
; ---------------------------------------------------------------------
zsm_init
    lda r0L
    sta zsm_baseL
    lda r0H
    sta zsm_baseH

    ldy #0
    lda (r0),y
    cmp #'z'
    bne _magic
    iny
    lda (r0),y
    cmp #'m'
    bne _magic

    ldy #2
    lda (r0),y
    cmp #ZSM_MAX_VERSION + 1
    bcs _version

    ldy #$0c
    lda (r0),y
    sta zsm_tickL
    iny
    lda (r0),y
    sta zsm_tickH

.if xuse_zsm_pcm
    jsr zsm_pcm_init
    bcs _pcm_error
.endif

    clc
    lda zsm_baseL
    adc #16
    sta zsm_ptrL
    lda zsm_baseH
    adc #0
    sta zsm_ptrH
    lda zsm_ptrL
    sta zsm_startL
    lda zsm_ptrH
    sta zsm_startH

    ldy #3
    lda (r0),y
    sta X16_T0
    iny
    lda (r0),y
    sta X16_T1
    iny
    lda (r0),y
    bne _range

    lda X16_T0
    ora X16_T1
    beq _noloop
    clc
    lda zsm_baseL
    adc X16_T0
    sta zsm_loopL
    lda zsm_baseH
    adc X16_T1
    sta zsm_loopH
    lda #(ZSM_FLAG_ACTIVE | ZSM_FLAG_LOOP)
    bra _state
_noloop
    stz zsm_loopL
    stz zsm_loopH
    lda #ZSM_FLAG_ACTIVE
_state
    sta zsm_flags
    stz zsm_delay
    lda #ZSM_ERR_NONE
    sta zsm_code
    clc
    rts
_magic
    lda #ZSM_ERR_MAGIC
    sta zsm_code
    sec
    rts
_version
    lda #ZSM_ERR_VERSION
    sta zsm_code
    sec
    rts
_range
    lda #ZSM_ERR_RANGE
    sta zsm_code
    sec
    rts
.if xuse_zsm_pcm
_pcm_error
    lda #ZSM_ERR_PCM
    sta zsm_code
    sec
    rts
.endif

; ---------------------------------------------------------------------
; zsm_init_stream -- initialize a raw headerless ZSM stream
;   in: r0 = stream pointer, r1 = loop pointer or 0 for no loop
; ---------------------------------------------------------------------
zsm_init_stream
    lda r0L
    sta zsm_baseL
    sta zsm_ptrL
    sta zsm_startL
    lda r0H
    sta zsm_baseH
    sta zsm_ptrH
    sta zsm_startH
    lda r1L
    sta zsm_loopL
    lda r1H
    sta zsm_loopH
.if xuse_zsm_pcm
    stz zsm_pcm_flags
    stz zsm_pcm_rate
.endif
    lda r1L
    ora r1H
    beq _noloop
    lda #(ZSM_FLAG_ACTIVE | ZSM_FLAG_LOOP)
    bra _state
_noloop
    lda #ZSM_FLAG_ACTIVE
_state
    sta zsm_flags
    stz zsm_delay
    lda #60
    sta zsm_tickL
    stz zsm_tickH
    clc
    rts

; ---------------------------------------------------------------------
; zsm_play / zsm_stop / zsm_rewind
; ---------------------------------------------------------------------
zsm_play
    lda #ZSM_FLAG_ACTIVE
    tsb zsm_flags
    rts

zsm_stop
    lda #ZSM_FLAG_ACTIVE
    trb zsm_flags
.if xuse_zsm_pcm
    jsr pcm_stream_stop
    stz VERA_AUDIO_RATE
.endif
    rts

zsm_rewind
    lda zsm_startL
    sta zsm_ptrL
    lda zsm_startH
    sta zsm_ptrH
    stz zsm_delay
    lda #ZSM_FLAG_EOF
    trb zsm_flags
    rts

; ---------------------------------------------------------------------
; zsm_get_tickrate -- out: A = low byte, X = high byte
; ---------------------------------------------------------------------
zsm_get_tickrate
    lda zsm_tickL
    ldx zsm_tickH
    rts

; ---------------------------------------------------------------------
; zsm_status
;   out: A = ZSM_FLAG_* bits, carry set if active
; ---------------------------------------------------------------------
zsm_status
    lda zsm_flags
    lsr
    lda zsm_flags
    rts

; ---------------------------------------------------------------------
; zsm_tick -- advance playback by one player tick
;   out: A = ZSM_FLAG_* bits, carry set if still active
; ---------------------------------------------------------------------
zsm_tick
    lda zsm_flags
    and #ZSM_FLAG_ACTIVE
    beq _inactive
    lda zsm_delay
    beq _commands
    dec zsm_delay
    bra zsm_status
_commands
    jsr zsm_next
    cmp #$40
    bcc _psg
    beq _ext
    cmp #$80
    bcc _ym
    beq _eof

    and #$7f                    ; delay 1..127 ticks
    sta zsm_delay
    bra zsm_status

_psg
    tax                         ; X = PSG register offset
    jsr zsm_next                ; A = value
    jsr zsm_psg_write
    bra _commands

_ym
    and #$3f                    ; number of reg/value pairs
    tax
    beq _commands
_ym_loop
    phx
    jsr zsm_next
    tax                         ; X = YM register
    jsr zsm_next                ; A = value
    jsr zsm_ym_write
    plx
    dex
    bne _ym_loop
    bra _commands

_ext
    jsr zsm_next
    sta X16_T0                  ; ccnnnnnn
    and #$3f
    sta X16_T1                  ; remaining payload length
    lda X16_T0
    and #%11000000
    bne _skip_ext
    jsr zsm_ext_pcm
    bra _commands
_skip_ext
    jsr zsm_skip_t1
    bra _commands

_eof
    lda zsm_flags
    and #ZSM_FLAG_LOOP
    beq _stop_eof
    lda zsm_loopL
    sta zsm_ptrL
    lda zsm_loopH
    sta zsm_ptrH
    bra _commands
_stop_eof
    lda #ZSM_FLAG_ACTIVE
    trb zsm_flags
    lda #ZSM_FLAG_EOF
    tsb zsm_flags
_inactive
    jmp zsm_status

; ---------------------------------------------------------------------
; zsm_next -- read one stream byte and advance zsm_ptr
; ---------------------------------------------------------------------
zsm_next
    lda zsm_ptrL
    sta X16_TPTR0
    lda zsm_ptrH
    sta X16_TPTR0+1
    ldy #0
    lda (X16_TPTR0),y
    inc zsm_ptrL
    bne zsm_next_done
    inc zsm_ptrH
zsm_next_done
    rts

; ---------------------------------------------------------------------
; zsm_skip_t1 -- skip X16_T1 stream bytes
; ---------------------------------------------------------------------
zsm_skip_t1
    lda X16_T1
    beq zsm_skip_done
zsm_skip_loop
    jsr zsm_next
    dec X16_T1
    bne zsm_skip_loop
zsm_skip_done
    rts

; ---------------------------------------------------------------------
; zsm_ext_pcm -- handle EXTCMD channel 0 command/argument pairs
;   X16_T1 = payload length. Unknown/truncated commands are consumed.
; ---------------------------------------------------------------------
zsm_ext_pcm
    lda X16_T1
    beq zsm_ext_pcm_done
zsm_ext_pcm_loop
    jsr zsm_next
    tax                         ; command
    dec X16_T1
    beq zsm_ext_pcm_done        ; truncated command: consumed
    jsr zsm_next
    tay                         ; argument
    dec X16_T1
    txa
    beq zsm_ext_pcm_ctrl
    cmp #1
    beq zsm_ext_pcm_rate
.if xuse_zsm_pcm
    cmp #2
    beq zsm_ext_pcm_trigger
.endif
    bra zsm_ext_pcm_next        ; command 2 instrument trigger: ignored
zsm_ext_pcm_ctrl
    tya
    sta VERA_AUDIO_CTRL
    bra zsm_ext_pcm_next
zsm_ext_pcm_rate
    tya
.if xuse_zsm_pcm
    sta zsm_pcm_rate
.endif
    sta VERA_AUDIO_RATE
    bra zsm_ext_pcm_next
.if xuse_zsm_pcm
zsm_ext_pcm_trigger
    tya
    jsr zsm_pcm_trigger
.endif
zsm_ext_pcm_next
    lda X16_T1
    bne zsm_ext_pcm_loop
zsm_ext_pcm_done
    rts

.if xuse_zsm_pcm
; ---------------------------------------------------------------------
; zsm_pcm_init -- parse optional PCM header/table from the ZSM header
;   in: r0 = ZSM header pointer
;   out: carry set if the PCM header is present but unsupported/invalid
; ---------------------------------------------------------------------
zsm_pcm_init
    stz zsm_pcm_flags
    stz zsm_pcm_rate

    ldy #6
    lda (r0),y
    sta X16_T0
    iny
    lda (r0),y
    sta X16_T1
    iny
    lda (r0),y
    beq _pcm_offset_ok
    jmp _range
_pcm_offset_ok
    lda X16_T0
    ora X16_T1
    bne _has_pcm
    clc                         ; no PCM header
    rts
_has_pcm

    clc
    lda zsm_baseL
    adc X16_T0
    sta zsm_pcm_hdrL
    lda zsm_baseH
    adc X16_T1
    sta zsm_pcm_hdrH
    bcs _range

    lda zsm_pcm_hdrL
    sta X16_TPTR0
    lda zsm_pcm_hdrH
    sta X16_TPTR0+1
    ldy #0
    lda (X16_TPTR0),y
    cmp #'P'
    bne _range
    iny
    lda (X16_TPTR0),y
    cmp #'C'
    bne _range
    iny
    lda (X16_TPTR0),y
    cmp #'M'
    bne _range
    iny
    lda (X16_TPTR0),y
    sta zsm_pcm_last

    ; data base = pcm header + 4 + 16 * (last index + 1)
    lda zsm_pcm_last
    cmp #$ff
    bne _count_to_bytes
    stz X16_T0
    lda #$10
    sta X16_T1
    bra _table_bytes
_count_to_bytes
    inc a
    sta X16_T0
    stz X16_T1
    asl X16_T0
    rol X16_T1
    asl X16_T0
    rol X16_T1
    asl X16_T0
    rol X16_T1
    asl X16_T0
    rol X16_T1
_table_bytes
    clc
    lda zsm_pcm_hdrL
    adc #4
    sta zsm_pcm_dataL
    lda zsm_pcm_hdrH
    adc #0
    sta zsm_pcm_dataH
    clc
    lda zsm_pcm_dataL
    adc X16_T0
    sta zsm_pcm_dataL
    lda zsm_pcm_dataH
    adc X16_T1
    sta zsm_pcm_dataH
    bcs _range

    lda #(ZSM_FLAG_PCM)
    tsb zsm_pcm_flags
_ok
    clc
    rts
_range
    sec
    rts

; ---------------------------------------------------------------------
; zsm_pcm_present -- out: carry set if a supported PCM table is present
; ---------------------------------------------------------------------
zsm_pcm_present
    lda zsm_pcm_flags
    and #ZSM_FLAG_PCM
    beq _no
    sec
    rts
_no
    clc
    rts

; ---------------------------------------------------------------------
; zsm_pcm_trigger -- start the PCM instrument in A
; ---------------------------------------------------------------------
zsm_pcm_trigger
    sta X16_T0                  ; instrument index
    jsr zsm_pcm_present
    bcs _present
    rts
_present
    lda X16_T0
    cmp zsm_pcm_last
    bcc _index_ok
    beq _index_ok
    rts
_index_ok
    ; instrument pointer = header + 4 + index*16
    lda X16_T0
    sta X16_T1
    stz X16_T2
    asl X16_T1
    rol X16_T2
    asl X16_T1
    rol X16_T2
    asl X16_T1
    rol X16_T2
    asl X16_T1
    rol X16_T2
    clc
    lda zsm_pcm_hdrL
    adc #4
    sta X16_TPTR0
    lda zsm_pcm_hdrH
    adc #0
    sta X16_TPTR0+1
    clc
    lda X16_TPTR0
    adc X16_T1
    sta X16_TPTR0
    lda X16_TPTR0+1
    adc X16_T2
    sta X16_TPTR0+1

    ldy #1
    lda (X16_TPTR0),y           ; instrument AUDIO_CTRL format bits
    and #(ZSM_PCM_16BIT | ZSM_PCM_STEREO)
    sta X16_T3

    ldy #4                      ; sample offset high byte unsupported
    lda (X16_TPTR0),y
    bne _done
    ldy #7                      ; sample length high byte unsupported
    lda (X16_TPTR0),y
    bne _done

    ldy #2
    lda (X16_TPTR0),y
    sta X16_T4                  ; sample offset low
    iny
    lda (X16_TPTR0),y
    sta X16_T5                  ; sample offset high
    ldy #5
    lda (X16_TPTR0),y
    sta X16_P2                  ; sample length low
    iny
    lda (X16_TPTR0),y
    sta X16_P3                  ; sample length high
    ora X16_P2
    beq _done

    ldy #8
    lda (X16_TPTR0),y
    and #%10000000
    sta pcm_str_loop

    ; sample source = pcm data base + sample offset
    clc
    lda zsm_pcm_dataL
    adc X16_T4
    sta X16_P0
    lda zsm_pcm_dataH
    adc X16_T5
    sta X16_P1
    bcs _done                  ; crossed 64K, unsupported here

    stz VERA_AUDIO_RATE
    lda VERA_AUDIO_CTRL
    and #$0f
    ora X16_T3
    ora #ZSM_PCM_FIFO_RESET
    sta VERA_AUDIO_CTRL

    lda zsm_pcm_rate
    jmp pcm_stream_start
_done
    rts
.endif

; ---------------------------------------------------------------------
; zsm_psg_write -- write A to PSG register offset X
; ---------------------------------------------------------------------
zsm_psg_write
    sta X16_T0
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    txa
    clc
    adc #<VRAM_PSG
    sta VERA_ADDR_L
    lda #>VRAM_PSG
    adc #0
    sta VERA_ADDR_M
    lda #VERA_ADDR_H_BANK
    sta VERA_ADDR_H
    lda X16_T0
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; zsm_ym_write -- raw YM register write
;   in: A = value, X = register
; ---------------------------------------------------------------------
zsm_ym_write
    sta X16_T0
    stx X16_T1
    php
    sei
    ldy #ZSM_YM_TIMEOUT
_wait
    dey
    bmi _done
    bit YM_DATA
    bmi _wait
    lda X16_T1
    sta YM_REG
    nop
    nop
    nop
    lda X16_T0
    sta YM_DATA
_done
    plp
    rts

; ---------------------------------------------------------------------
; Player state.
; ---------------------------------------------------------------------
zsm_baseL  .byte 0
zsm_baseH  .byte 0
zsm_startL .byte 0
zsm_startH .byte 0
zsm_ptrL   .byte 0
zsm_ptrH   .byte 0
zsm_loopL  .byte 0
zsm_loopH  .byte 0
zsm_tickL  .byte 60
zsm_tickH  .byte 0
zsm_delay  .byte 0
zsm_flags  .byte 0
.if xuse_zsm_pcm
zsm_pcm_hdrL  .byte 0
zsm_pcm_hdrH  .byte 0
zsm_pcm_dataL .byte 0
zsm_pcm_dataH .byte 0
zsm_pcm_last  .byte 0
zsm_pcm_rate  .byte 0
zsm_pcm_flags .byte 0
.endif

; (end zone)
.endif
.if xuse_pcm
; --- inline audio/pcm.asm ---
;ACME
; =====================================================================
; x16lib :: audio/pcm.asm -- VERA PCM audio (4 KB FIFO)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; AUDIO_CTRL ($9F3B): bit 7 read = FIFO full, bit 6 read = FIFO empty,
;   bit 5 = 16-bit, bit 4 = stereo, bits 3:0 = volume (0-15).
;   Writing a 1 to bit 7 resets the FIFO.
; AUDIO_RATE ($9F3C): 0 stops playback, 128 = 48828 Hz. Above 128 is
;   invalid.
; AUDIO_DATA ($9F3D): each write pushes one byte. Writes are silently
;   dropped when the FIFO is full.
;
; Samples are two's-complement signed.
;
; Set the rate to 0, prime the FIFO, then set the real rate. Starting
; playback on an empty FIFO underruns immediately.
; =====================================================================

; (zone: file scope in 64tass)

PCM_FIFO_FULL   = %10000000
PCM_FIFO_EMPTY  = %01000000
PCM_FIFO_RESET  = %10000000     ; on write
PCM_16BIT       = %00100000
PCM_STEREO      = %00010000

; ---------------------------------------------------------------------
; pcm_ctrl  -- in: A = control byte (volume | stereo | 16-bit | reset)
; pcm_rate  -- in: A = sample rate (0 stops, 128 is full speed)
; pcm_reset -- clear the FIFO, keeping the current format and volume
; ---------------------------------------------------------------------
pcm_ctrl
    sta VERA_AUDIO_CTRL
    rts

pcm_rate
    cmp #129
    bcc _ok
    lda #128                    ; anything above 128 is invalid
_ok
    sta VERA_AUDIO_RATE
    rts

pcm_reset
    lda VERA_AUDIO_CTRL
    and #(PCM_16BIT | PCM_STEREO | $0F)
    ora #PCM_FIFO_RESET
    sta VERA_AUDIO_CTRL
    rts

; ---------------------------------------------------------------------
; pcm_full  -- out: carry set if the FIFO cannot take another byte
; pcm_empty -- out: carry set if the FIFO has run dry
; ---------------------------------------------------------------------
pcm_full
    lda VERA_AUDIO_CTRL
    asl                         ; bit 7 into carry
    rts

pcm_empty
    lda VERA_AUDIO_CTRL
    and #PCM_FIFO_EMPTY
    cmp #PCM_FIFO_EMPTY         ; carry set when the bit is set
    rts

; ---------------------------------------------------------------------
; pcm_put -- in: A = sample byte.  Dropped by the hardware if full.
; ---------------------------------------------------------------------
pcm_put
    sta VERA_AUDIO_DATA
    rts

; ---------------------------------------------------------------------
; pcm_write -- push a block into the FIFO
;   in:  X16_P0/P1 = source address, X16_P2/P3 = byte count
;
; Does not throttle: intended for priming an empty FIFO with up to 4 KB.
; Bytes written past a full FIFO are discarded by the hardware, so pace
; a longer stream yourself with pcm_full.
; ---------------------------------------------------------------------
pcm_write
    ldy #0
_loop
    lda X16_P2
    ora X16_P3
    beq _done                   ; count exhausted

    lda (X16_P0),y
    sta VERA_AUDIO_DATA

    inc X16_P0                  ; advance the source pointer
    bne _dec
    inc X16_P1
_dec
    lda X16_P2                  ; 16-bit decrement of the count
    bne _dec_low
    dec X16_P3
_dec_low
    dec X16_P2
    bra _loop
_done
    rts

; =====================================================================
; AFLOW-driven streaming (X16_USE_PCM_STREAM, which implies X16_USE_IRQ)
;
; pcm_write primes a FIFO; it cannot PLAY anything longer than the
; FIFO's 4 KB. Streaming works the way the hardware intends: VERA
; raises AFLOW whenever the FIFO drops below 1/4 full, and the
; interrupt refills it from the sample buffer. AFLOW has no ISR
; acknowledge -- it clears only when the FIFO rises back over 1/4, and
; when the data runs out the refiller must disable it in IEN or the
; interrupt storms forever.
;
; The source pointer is kept inside an absolute lda (self-modified),
; not in zero page: the refill runs in interrupt context, where every
; zero-page scratch byte may belong to whatever code was interrupted.
; =====================================================================
.if xuse_pcm_stream

pcm_str_rem    .fill 3, 0       ; bytes still to feed (24-bit)
pcm_str_active .byte 0
pcm_str_loop   .byte 0          ; caller-owned: nonzero = wrap to the
                                ; start when the data runs out; set or
                                ; clear it BEFORE pcm_stream_start*
pcm_str_mode   .byte 0          ; 0 = low RAM source, 1 = banked RAM
pcm_str_bank   .byte 0          ; the bank currently being read (mode 1)
pcm_str_rsrc   .word 0          ; rewind snapshot: source address...
pcm_str_rbank  .byte 0          ; ...bank...
pcm_str_rlen   .fill 3, 0       ; ...and byte count
pcm_str_svbk   .byte 0          ; the interrupted code's RAM_BANK

; ---------------------------------------------------------------------
; pcm_stream_start -- play a sample buffer through the FIFO
;   in:  X16_P0/P1 = sample data (low RAM)
;        X16_P2/P3 = byte count
;        A         = sample rate (1-128; 128 = 48828 Hz)
;
; Set the format and volume first with pcm_ctrl, and pcm_str_loop if
; the sample should repeat. The FIFO is primed here in one go, THEN
; the rate starts playback, so it cannot underrun at t=0. Requires
; interrupts enabled; installs the CINV hook itself.
; ---------------------------------------------------------------------
pcm_stream_start
    pha
    jsr pcm_stream_stop         ; quiesce a previous stream

    stz pcm_str_mode
    lda X16_P0                  ; patch the source into the refiller
    sta pcm_src+1
    sta pcm_str_rsrc
    lda X16_P1
    sta pcm_src+2
    sta pcm_str_rsrc+1
    lda X16_P2
    sta pcm_str_rem
    sta pcm_str_rlen
    lda X16_P3
    sta pcm_str_rem+1
    sta pcm_str_rlen+1
    stz pcm_str_rem+2
    stz pcm_str_rlen+2
    ora X16_P2
    bne pcm_start_common
    pla                         ; zero bytes: nothing to play
    rts

; ---------------------------------------------------------------------
; pcm_stream_start_bank -- play a sample living in banked RAM
;   in:  X16_P0/P1 = offset within the bank window (0-8191)
;        X16_P2/P3/P4 = byte count (24 bits: whole songs)
;        X16_P5    = the bank the sample starts in
;        A         = sample rate (1-128)
;
; The refiller maps banks in as it goes (rolling $C000 back to $A000,
; bank + 1) and always restores the interrupted code's RAM_BANK, so
; the main program never notices.
; ---------------------------------------------------------------------
pcm_stream_start_bank
    pha
    jsr pcm_stream_stop

    lda #1
    sta pcm_str_mode
    lda X16_P0                  ; window address = $A000 + offset
    sta pcm_src+1
    sta pcm_str_rsrc
    lda X16_P1
    clc
    adc #$A0
    sta pcm_src+2
    sta pcm_str_rsrc+1
    lda X16_P5
    sta pcm_str_bank
    sta pcm_str_rbank
    lda X16_P2
    sta pcm_str_rem
    sta pcm_str_rlen
    lda X16_P3
    sta pcm_str_rem+1
    sta pcm_str_rlen+1
    lda X16_P4
    sta pcm_str_rem+2
    sta pcm_str_rlen+2
    ora X16_P2
    ora X16_P3
    bne pcm_start_common
    pla
    rts

; the shared tail: hook, prime, arm AFLOW if data remains, set the rate
pcm_start_common
    jsr irq_install
    lda #1
    sta pcm_str_active
    jsr pcm_stream_fill         ; prime the FIFO before playback starts

    lda pcm_str_active          ; anything left to stream?
    beq _go                     ; no: it all fit in the FIFO
    php
    sei
    lda #VERA_IRQ_AFLOW
    tsb VERA_IEN
    plp
_go
    pla
    jmp pcm_rate                ; ...and start the DAC

; ---------------------------------------------------------------------
; pcm_stream_stop -- stop refilling. What is already queued in the
; FIFO keeps playing; call pcm_reset/pcm_rate(0) for immediate silence.
; (pcm_str_loop is caller-owned and survives; a looping stream stops
; all the same -- the loop flag only matters when the data runs out.)
; ---------------------------------------------------------------------
pcm_stream_stop
    php
    sei
    lda #VERA_IRQ_AFLOW
    trb VERA_IEN
    stz pcm_str_active
    plp
    rts

; ---------------------------------------------------------------------
; pcm_stream_active -- out: A = 1 while data remains, 0 when the whole
;                      buffer has been handed to the FIFO (Z mirrors A)
;                      A looping stream stays active until stopped.
; ---------------------------------------------------------------------
pcm_stream_active
    lda pcm_str_active
    rts

; ---------------------------------------------------------------------
; pcm_stream_isr -- the AFLOW service, called from irq_handler.
; pcm_stream_fill -- push bytes until the FIFO is full or the data is
;                    gone; also used to prime. Clobbers A/X/Y (fine in
;                    the IRQ; the KERNAL stub restores them).
; ---------------------------------------------------------------------
pcm_stream_isr
    lda pcm_str_active
    bne pcm_stream_fill
    lda #VERA_IRQ_AFLOW         ; stray AFLOW with no stream: mute it
    trb VERA_IEN
    rts

pcm_stream_fill
    lda pcm_str_mode
    beq psf_loop
    lda RAM_BANK                ; banked source: map it in, and put the
    sta pcm_str_svbk            ; interrupted code's bank back on exit
    lda pcm_str_bank
    sta RAM_BANK
psf_loop
    lda pcm_str_rem
    ora pcm_str_rem+1
    ora pcm_str_rem+2
    beq psf_exhausted
    bit VERA_AUDIO_CTRL         ; bit 7: FIFO full
    bpl psf_feed
    jmp psf_full                   ; out of branch range from here
psf_feed
pcm_src
    lda $FFFF                   ; operand = current source (self-modified)
    sta VERA_AUDIO_DATA

    inc pcm_src+1                  ; advance the source
    bne psf_dec
    inc pcm_src+2
    lda pcm_str_mode
    beq psf_dec
    lda pcm_src+2                  ; banked: roll $C000 -> $A000, bank + 1
    cmp #$C0
    bne psf_dec
    lda #$A0
    sta pcm_src+2
    inc pcm_str_bank
    lda pcm_str_bank
    sta RAM_BANK
psf_dec
    lda pcm_str_rem             ; 24-bit decrement
    bne psf_dec0
    lda pcm_str_rem+1
    bne psf_dec1
    dec pcm_str_rem+2
psf_dec1
    dec pcm_str_rem+1
psf_dec0
    dec pcm_str_rem
    bra psf_loop

psf_exhausted
    lda pcm_str_loop
    beq psf_stop_refill
    lda pcm_str_rlen            ; an empty snapshot cannot loop
    ora pcm_str_rlen+1
    ora pcm_str_rlen+2
    beq psf_stop_refill
    lda pcm_str_rsrc            ; rewind to the start...
    sta pcm_src+1
    lda pcm_str_rsrc+1
    sta pcm_src+2
    lda pcm_str_rlen
    sta pcm_str_rem
    lda pcm_str_rlen+1
    sta pcm_str_rem+1
    lda pcm_str_rlen+2
    sta pcm_str_rem+2
    lda pcm_str_mode
    bne psf_rewind_bank
    jmp psf_loop                   ; psf_loop is out of branch range from here
psf_rewind_bank
    lda pcm_str_rbank           ; ...including the starting bank
    sta pcm_str_bank
    sta RAM_BANK
    jmp psf_loop

psf_stop_refill
    lda #VERA_IRQ_AFLOW         ; out of data: stop the refill interrupt
    trb VERA_IEN                ; (leaving it enabled would storm: AFLOW
    stz pcm_str_active          ; only clears by refilling the FIFO)
psf_full
    lda pcm_str_mode
    beq psf_out
    lda pcm_str_svbk            ; the interrupted code's bank goes back
    sta RAM_BANK
psf_out
    rts

.endif

; (end zone)
.endif
.if xuse_input_any
; --- inline input/input.asm ---
;ACME
; =====================================================================
; x16lib :: input/input.asm -- joystick, mouse, keyboard
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Thin wrappers over the KERNAL. Nothing here touches VERA directly
; except mouse_show, which the KERNAL handles for us.
; =====================================================================

; (zone: file scope in 64tass)

; --- joystick button bits (ACTIVE LOW: a clear bit means pressed) -----
; byte 0
JOY_B      = %10000000
JOY_Y      = %01000000
JOY_SELECT = %00100000
JOY_START  = %00010000
JOY_UP     = %00001000
JOY_DOWN   = %00000100
JOY_LEFT   = %00000010
JOY_RIGHT  = %00000001
; byte 1
JOY_A      = %10000000
JOY_X      = %01000000
JOY_L      = %00100000
JOY_R      = %00010000

JOY_PRESENT = $00
JOY_ABSENT  = $FF

; ---------------------------------------------------------------------
; joy_scan -- sample every joystick. Call once per frame before joy_get.
;             The KERNAL's IRQ already does this; only needed if you
;             have taken the interrupt over.
; ---------------------------------------------------------------------
joy_scan
    jmp JOYSTICK_SCAN

; ---------------------------------------------------------------------
; joy_get
;   in:  A = joystick (0 = keyboard, 1-4 = gamepads)
;   out: A = buttons byte 0 (B Y SELECT START UP DOWN LEFT RIGHT)
;        X = buttons byte 1 (A X L R and four set filler bits)
;        Y = $00 present, $FF absent
;
; Bits are ACTIVE LOW. A pressed button reads 0, so test with a mask and
; branch on zero:  and #JOY_LEFT : beq moving_left
; ---------------------------------------------------------------------
joy_get
    jmp JOYSTICK_GET

; ---------------------------------------------------------------------
; mouse_show -- in: A = $00 hide, $FF show without changing the cursor,
;                      n  show and select cursor sprite n
;               The screen size is left unchanged (MOUSE_CONFIG is
;               called with X = Y = 0). Call MOUSE_CONFIG yourself to
;               resize the mouse field.
; mouse_hide
; ---------------------------------------------------------------------
mouse_show
    ldx #0
    ldy #0
    jmp MOUSE_CONFIG

mouse_hide
    lda #0
    ldx #0
    ldy #0
    jmp MOUSE_CONFIG

; ---------------------------------------------------------------------
; mouse_get -- read position and buttons
;   out: X16_P0/P1 = x, X16_P2/P3 = y, A = buttons
;        (bit 0 left, bit 1 right, bit 2 middle)
;
; The KERNAL writes the four position bytes to zero page starting at the
; address in X, which is why the results land in the parameter block.
; ---------------------------------------------------------------------
mouse_get
    ldx #X16_P0
    jmp MOUSE_GET

; ---------------------------------------------------------------------
; key_get -- out: A = PETSCII code, or 0 if nothing is waiting
;            Non-blocking.
; ---------------------------------------------------------------------
key_get
    jmp GETIN

; key_wait (blocking) and key_peek (lookahead) are convenience calls an
; event-driven program never uses -- it drains with key_get -- so they are
; behind X16_USE_INPUT_KEYWAIT (X16_USE_INPUT still pulls them, for compat).
.if xuse_input_keywait
; ---------------------------------------------------------------------
; key_wait -- block until a key is pressed.  out: A = PETSCII code
; ---------------------------------------------------------------------
key_wait
_loop
    jsr GETIN
    beq _loop
    rts

; ---------------------------------------------------------------------
; key_peek -- out: A = next key without consuming it
;                  X = number of keys queued
;                  Z set (and X = 0) when the buffer is empty
; ---------------------------------------------------------------------
key_peek
    jmp KBDBUF_PEEK
.endif

; (end zone)
.endif
.if xuse_keyboard
; --- inline input/keyboard.asm ---
;ACME
; =====================================================================
; x16lib :: input/keyboard.asm -- X16 keyboard buffer and layout helpers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; This gate exposes the X16-specific keyboard buffer and keymap jump-table
; calls that are not part of the stable X16_USE_INPUT surface.
;
; KEYMAP contract:
;       sec : jsr kbd_keymap       ; get current layout
;             A = layout index, X/Y = NUL-terminated layout name
;       clc : X/Y = name pointer : jsr kbd_keymap
;             carry clear on success, carry set on unknown layout
; =====================================================================

; (zone: file scope in 64tass)

KBD_MOD_SHIFT = %00000001
KBD_MOD_ALT   = %00000010       ; Commodore/Alt
KBD_MOD_CTRL  = %00000100
KBD_MOD_CAPS  = %00010000
KBD_MOD_ALTGR = KBD_MOD_ALT | KBD_MOD_CTRL

; ---------------------------------------------------------------------
; kbd_scan -- scan keyboard once
; ---------------------------------------------------------------------
kbd_scan
    jmp SCNKEY

; ---------------------------------------------------------------------
; kbd_peek -- read next buffered key without consuming it
;   out: A = next PETSCII key, X = queued key count, Z set when empty
; ---------------------------------------------------------------------
kbd_peek
    jmp KBDBUF_PEEK

; ---------------------------------------------------------------------
; kbd_put -- append a PETSCII key to the keyboard buffer
;   in: A = PETSCII key
; ---------------------------------------------------------------------
kbd_put
    jmp KBDBUF_PUT

; ---------------------------------------------------------------------
; kbd_get_modifiers -- read the current modifier bitfield
;   out: A = KBD_MOD_* bits
; ---------------------------------------------------------------------
kbd_get_modifiers
    jmp KBDBUF_GET_MODIFIERS

; ---------------------------------------------------------------------
; kbd_keymap -- get or set the active keyboard layout
;   in:  C clear: X/Y = NUL-terminated layout string
;        C set:   query current layout
;   out: query: A = layout index, X/Y = current layout string
;        set:   carry clear on success, carry set on failure
; ---------------------------------------------------------------------
kbd_keymap
    jmp KEYMAP

; ---------------------------------------------------------------------
; kbd_get_keymap -- friendly current-layout query
;   out: A = layout index, X/Y = current layout string
; ---------------------------------------------------------------------
kbd_get_keymap
    sec
    jmp KEYMAP

; ---------------------------------------------------------------------
; kbd_set_keymap -- friendly layout setter
;   in: X/Y = NUL-terminated layout string
;   out: carry clear on success, carry set on failure
; ---------------------------------------------------------------------
kbd_set_keymap
    clc
    jmp KEYMAP

; (end zone)
.endif
.if xuse_mouse
; --- inline input/mouse.asm ---
;ACME
; =====================================================================
; x16lib :: input/mouse.asm -- full KERNAL mouse wrappers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; This gate complements the compact mouse helpers in X16_USE_INPUT. It
; exposes the full stable KERNAL mouse surface with distinct mse_* names
; so it can be enabled alongside X16_USE_INPUT or a section bundle.
;
; MOUSE_CONFIG:
;       A = $00 hide mouse
;           n   show mouse and select cursor sprite n
;           $FF show mouse without changing cursor sprite
;       X = width in 8-pixel units
;       Y = height in 8-pixel units
;       X=0 and Y=0 leaves the current bounds unchanged
;
; MOUSE_GET:
;       X = zero-page destination for xlo,xhi,ylo,yhi
;       A = buttons, X = signed wheel delta
; =====================================================================

; (zone: file scope in 64tass)

MSE_BUTTON_LEFT   = %00000001
MSE_BUTTON_RIGHT  = %00000010
MSE_BUTTON_MIDDLE = %00000100
MSE_BUTTON_4      = %00010000
MSE_BUTTON_5      = %00100000

; ---------------------------------------------------------------------
; mse_config -- raw MOUSE_CONFIG wrapper
;   in: A = show/cursor selector, X = width/8, Y = height/8
; ---------------------------------------------------------------------
mse_config
    jmp MOUSE_CONFIG

; ---------------------------------------------------------------------
; mse_scan -- scan mouse once
; ---------------------------------------------------------------------
mse_scan
    jmp MOUSE_SCAN

; ---------------------------------------------------------------------
; mse_get_to -- raw MOUSE_GET wrapper
;   in:  X = zero-page destination for xlo,xhi,ylo,yhi
;   out: A = buttons, X = signed wheel delta
; ---------------------------------------------------------------------
mse_get_to
    jmp MOUSE_GET

; ---------------------------------------------------------------------
; mse_get -- read mouse to X16_P0..X16_P3
;   out: X16_P0/P1 = x, X16_P2/P3 = y, A = buttons, X = wheel delta
; ---------------------------------------------------------------------
mse_get
    ldx #X16_P0
    jmp MOUSE_GET

; ---------------------------------------------------------------------
; mse_show -- show and select cursor sprite A, keeping current bounds
; ---------------------------------------------------------------------
mse_show
    ldx #0
    ldy #0
    jmp MOUSE_CONFIG

; ---------------------------------------------------------------------
; mse_show_keep -- show mouse without changing cursor sprite or bounds
; ---------------------------------------------------------------------
mse_show_keep
    lda #$ff
    ldx #0
    ldy #0
    jmp MOUSE_CONFIG

; ---------------------------------------------------------------------
; mse_hide -- hide mouse, keeping current bounds
; ---------------------------------------------------------------------
mse_hide
    lda #0
    ldx #0
    ldy #0
    jmp MOUSE_CONFIG

; (end zone)
.endif
.if xuse_i2c
; --- inline comms/i2c.asm ---
;ACME
; =====================================================================
; x16lib :: comms/i2c.asm -- KERNAL I2C helper wrappers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; These are thin wrappers over the Commander X16 KERNAL I2C jump table.
; The carry flag follows the ROM convention: carry set means NAK/error.
;
; Byte calls:
;       ldx #device                 ; 7-bit I2C device address
;       ldy #offset                 ; device register/offset
;       jsr i2c_read_byte           ; A = value, C = error
;
;       lda #value
;       ldx #device
;       ldy #offset
;       jsr i2c_write_byte          ; C = error
;
; Batch calls use the KERNAL virtual registers:
;       X  = 7-bit I2C device address
;       r0 = RAM buffer pointer
;       r1 = byte count
;       C  = 0 to advance r0 after each read, 1 to keep r0 fixed
;       r2 = bytes written by i2c_batch_write
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; i2c_read_byte -- read one byte from an I2C device offset
;   in:  X = 7-bit device address, Y = offset
;   out: A = value, X/Y preserved, carry set on error
; ---------------------------------------------------------------------
i2c_read_byte
    jmp I2C_READ_BYTE

; ---------------------------------------------------------------------
; i2c_write_byte -- write one byte to an I2C device offset
;   in:  A = value, X = 7-bit device address, Y = offset
;   out: X/Y preserved, carry set on error
; ---------------------------------------------------------------------
i2c_write_byte
    jmp I2C_WRITE_BYTE

; ---------------------------------------------------------------------
; i2c_batch_read -- read bytes into RAM through r0
;   in:  X = 7-bit device address, r0 = buffer, r1 = byte count
;        C = 0 advance buffer pointer, C = 1 keep pointer fixed
;   out: X/r0/r1 preserved, carry set on error
; ---------------------------------------------------------------------
i2c_batch_read
    jmp I2C_BATCH_READ

; ---------------------------------------------------------------------
; i2c_batch_write -- write bytes from RAM through r0
;   in:  X = 7-bit device address, r0 = buffer, r1 = byte count
;   out: X/r0/r1 preserved, r2 = byte count written, carry set on error
; ---------------------------------------------------------------------
i2c_batch_write
    jmp I2C_BATCH_WRITE

; (end zone)
.endif
.if xuse_vera_spi
; --- inline comms/spi.asm ---
;ACME
; =====================================================================
; x16lib :: comms/spi.asm -- VERA SPI controller helpers
; =====================================================================
; Gate: X16_USE_VERA_SPI
;
; VERA's SPI controller is exposed at VERA_SPI_DATA/CTRL. Writing DATA
; starts one full-duplex transfer; BUSY stays set until the received byte
; can be read back from DATA. SELECT asserts chip-select when set.
;
; Buffer routines use r0 = RAM pointer and r1 = byte count. They advance
; r0 to one byte past the buffer and leave r1 = 0.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; spi_get_ctrl -- read SPI_CTRL
;   out: A = VERA_SPI_* control/status bits
; ---------------------------------------------------------------------
spi_get_ctrl
    lda VERA_SPI_CTRL
    rts

; ---------------------------------------------------------------------
; spi_set_ctrl -- write SPI_CTRL
;   in: A = VERA_SPI_SELECT/SLOWCLK/AUTOTX bits
; ---------------------------------------------------------------------
spi_set_ctrl
    sta VERA_SPI_CTRL
    rts

; ---------------------------------------------------------------------
; spi_wait -- wait for the active transfer to finish
; ---------------------------------------------------------------------
spi_wait
    bit VERA_SPI_CTRL
    bmi spi_wait
    rts

; ---------------------------------------------------------------------
; spi_select / spi_deselect -- assert or release chip-select
; ---------------------------------------------------------------------
spi_select
    lda VERA_SPI_CTRL
    ora #VERA_SPI_SELECT
    sta VERA_SPI_CTRL
    rts

spi_deselect
    lda VERA_SPI_CTRL
    and #%11111110
    sta VERA_SPI_CTRL
    rts

; ---------------------------------------------------------------------
; spi_slow / spi_fast -- select ~390 kHz or ~12.5 MHz SPI clock
; ---------------------------------------------------------------------
spi_slow
    lda VERA_SPI_CTRL
    ora #VERA_SPI_SLOWCLK
    sta VERA_SPI_CTRL
    rts

spi_fast
    lda VERA_SPI_CTRL
    and #%11111101
    sta VERA_SPI_CTRL
    rts

; ---------------------------------------------------------------------
; spi_autotx_on / spi_autotx_off
;   Auto-TX makes each SPI_DATA read start a new $FF transfer.
; ---------------------------------------------------------------------
spi_autotx_on
    lda VERA_SPI_CTRL
    ora #VERA_SPI_AUTOTX
    sta VERA_SPI_CTRL
    rts

spi_autotx_off
    lda VERA_SPI_CTRL
    and #%11111011
    sta VERA_SPI_CTRL
    rts

; ---------------------------------------------------------------------
; spi_transfer -- transmit A, wait, then return the received byte
;   in:  A = byte to transmit
;   out: A = received byte
; ---------------------------------------------------------------------
spi_transfer
    sta VERA_SPI_DATA
    jsr spi_wait
    lda VERA_SPI_DATA
    rts

; ---------------------------------------------------------------------
; spi_write -- transmit A and wait; received byte is discarded
; ---------------------------------------------------------------------
spi_write
    sta VERA_SPI_DATA
    jmp spi_wait

; ---------------------------------------------------------------------
; spi_read -- transmit $FF, wait, then return the received byte
;   out: A = received byte
; ---------------------------------------------------------------------
spi_read
    lda #$ff
    jmp spi_transfer

; ---------------------------------------------------------------------
; spi_autotx_read -- wait, then read DATA in Auto-TX mode
;   out: A = received byte; the read starts the next $FF transfer
; ---------------------------------------------------------------------
spi_autotx_read
    jsr spi_wait
    lda VERA_SPI_DATA
    rts

; ---------------------------------------------------------------------
; spi_read_bytes -- read bytes into RAM
;   in:  r0 = destination pointer, r1 = byte count
;   out: r0 advanced, r1 = 0
; ---------------------------------------------------------------------
spi_read_bytes
    lda r1L
    ora r1H
    beq _done
_loop
    jsr spi_read
    ldy #0
    sta (r0),y
    inc r0L
    bne _dec
    inc r0H
_dec
    lda r1L
    bne _dec_lo
    dec r1H
_dec_lo
    dec r1L
    lda r1L
    ora r1H
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; spi_write_bytes -- write bytes from RAM
;   in:  r0 = source pointer, r1 = byte count
;   out: r0 advanced, r1 = 0
; ---------------------------------------------------------------------
spi_write_bytes
    lda r1L
    ora r1H
    beq _done
_loop
    ldy #0
    lda (r0),y
    jsr spi_write
    inc r0L
    bne _dec
    inc r0H
_dec
    lda r1L
    bne _dec_lo
    dec r1H
_dec_lo
    dec r1L
    lda r1L
    ora r1H
    bne _loop
_done
    rts

; (end zone)
.endif
.if xuse_serial
; --- inline comms/serial.asm ---
;ACME
; =====================================================================
; x16lib :: comms/serial.asm -- the serial / WiFi card UARTs
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The Commander X16 serial / WiFi card carries up to two 16C550-style
; UARTs in the expansion I/O window. They live on 8-byte boundaries
; between $9F60 and $9FF8; the standard card populates $9F60 (UART 0)
; and $9F68 (UART 1). The WiFi half is an ESP32 running ZiModem, driven
; as an AT-command modem over UART 0 -- but that is a protocol on top of
; these bytes, not something this module knows about.
;
; The register file (offset from the UART's base address):
;   0  RHR/THR   receive / transmit holding    (DLL when DLAB=1)
;   1  IER       interrupt enable              (DLM when DLAB=1)
;   2  IIR/FCR   read: interrupt id / write: FIFO control
;   3  LCR       line control (word size, parity, stop, DLAB)
;   4  MCR       modem control (DTR/RTS/loop/auto-flow)
;   5  LSR       line status (DR, THRE, errors)
;   6  MSR       modem status
;   7  SCR       scratch (no hardware effect -- used to fingerprint)
;
; Typical use, 9600 baud on the standard card:
;       jsr ser_detect              ; A = count, ser_u0 = first UART
;       lda ser_u0 : ldx ser_u0+1
;       ldy #<SER_BAUD_9600 : sty X16_P0
;       ldy #>SER_BAUD_9600 : sty X16_P1
;       jsr ser_init                ; 8N1, FIFOs, auto-flow, no IRQ
;       lda #<msg : ldx #>msg : jsr ser_puts
;   poll:
;       jsr ser_get                 ; carry set = nothing waiting
;       bcs poll
;       ; A = the received byte
;
; ser_init remembers the UART it was handed; ser_put/ser_get/... all
; talk to that one. Point them elsewhere by calling ser_init again.
;
; Reads have side effects on real UARTs -- reading RHR pops the RX FIFO,
; reading LSR clears the sticky error bits -- so this module never lets
; an indexed store's dummy read fall on RHR: byte writes to THR go out
; through `sta (ptr)` (no index, no dummy read on the 65C02).
; =====================================================================

; (zone: file scope in 64tass)

; --- register offsets ------------------------------------------------
SER_RHR = 0                     ; = THR on write, = DLL when DLAB set
SER_IER = 1                     ; = DLM when DLAB set
SER_FCR = 2                     ; write: FIFO control (reads IIR)
SER_LCR = 3
SER_MCR = 4
SER_LSR = 5
SER_MSR = 6
SER_SCR = 7

; --- LSR bits --------------------------------------------------------
SER_LSR_DR   = %00000001        ; a received byte is ready
SER_LSR_THRE = %00100000        ; the transmit holding register is empty

; --- baud-rate divisors (14.7456 MHz clock: 14745600 / (16 * baud)) --
; Hand these to ser_init in X16_P0 (low) / X16_P1 (high).
SER_BAUD_921600 = $0001
SER_BAUD_460800 = $0002
SER_BAUD_230400 = $0004
SER_BAUD_115200 = $0008
SER_BAUD_57600  = $0010
SER_BAUD_38400  = $0018
SER_BAUD_28800  = $0020
SER_BAUD_19200  = $0030
SER_BAUD_14400  = $0040
SER_BAUD_9600   = $0060
SER_BAUD_4800   = $00C0
SER_BAUD_2400   = $0180
SER_BAUD_1200   = $0300
SER_BAUD_600    = $0600
SER_BAUD_300    = $0C00

SER_SCAN_FIRST = $9F60          ; first candidate UART base
SER_SCAN_LAST  = $9FF8          ; last candidate UART base
SER_SCAN_STEP  = 8              ; UARTs sit on 8-byte boundaries

; ---------------------------------------------------------------------
; ser_detect -- scan the expansion window for UART chips.
;   out: A = number found (0, 1 or 2)
;        carry clear if at least one was found, set if none
;        ser_u0 = first UART base (0 if none)
;        ser_u1 = second UART base (0 if none)
;
; The probe writes and reads back three registers whose behaviour a UART
; is required to have and bare bus is not: the top nibble of IER always
; reads 0, the top two bits of MCR always read 0, and the scratch
; register holds whatever you put in it. Two different scratch patterns
; make a floating bus very unlikely to answer by accident. Interrupts
; are held off across the probe so an IRQ handler never sees the UART
; mid-fingerprint.
; ---------------------------------------------------------------------
ser_detect
    stz ser_u0
    stz ser_u0+1
    stz ser_u1
    stz ser_u1+1
    lda #<SER_SCAN_FIRST        ; X16_TPTR1 walks the candidate bases
    sta X16_T2
    lda #>SER_SCAN_FIRST
    sta X16_T3
    php
    sei
_scan
    jsr serial_probe
    bcc _next                   ; carry set from serial_probe = a UART is here
    lda ser_u0+1                ; first slot still empty?
    ora ser_u0
    bne _have_first
    lda X16_T2                  ; store as UART 0
    sta ser_u0
    lda X16_T3
    sta ser_u0+1
    bra _next
_have_first
    lda X16_T2                  ; store as UART 1 and stop
    sta ser_u1
    lda X16_T3
    sta ser_u1+1
    bra _done
_next
    clc                         ; advance the base by SER_SCAN_STEP
    lda X16_T2
    adc #SER_SCAN_STEP
    sta X16_T2
    bcc _nohi
    inc X16_T3
_nohi
    lda X16_T3                  ; past SER_SCAN_LAST?
    cmp #>SER_SCAN_LAST
    bcc _scan
    bne _done
    lda X16_T2
    cmp #<SER_SCAN_LAST
    bcc _scan
    beq _scan                   ; include SER_SCAN_LAST itself
_done
    plp
    ldx #0                      ; count the non-zero slots
    lda ser_u0
    ora ser_u0+1
    beq _c0
    inx
_c0
    lda ser_u1
    ora ser_u1+1
    beq _c1
    inx
_c1
    txa
    beq _none                   ; count 0: nothing found
    clc                         ; carry clear = at least one UART
    rts
_none
    sec
    rts

; probe the UART whose base is in X16_TPTR1 (X16_T2/T3).
;   out: carry set = a UART answered, carry clear = nothing there
; Leaves IER and MCR at 0 either way.
serial_probe
    ldy #SER_IER
    lda #$F0
    sta (X16_T2),y
    lda (X16_T2),y
    and #$F0                    ; the high nibble must read back as 0
    bne serial_no
    lda #0
    sta (X16_T2),y
    ldy #SER_MCR
    lda #$FF
    sta (X16_T2),y
    lda (X16_T2),y
    cmp #$3F                    ; bits 7,6 of MCR always read 0
    bne serial_no_mcr
    lda #0
    sta (X16_T2),y
    ldy #SER_SCR                ; scratch holds two distinct patterns
    lda #$A5
    sta (X16_T2),y
    lda (X16_T2),y
    cmp #$A5
    bne serial_no
    lda #$5A
    sta (X16_T2),y
    lda (X16_T2),y
    cmp #$5A
    bne serial_no
    sec
    rts
serial_no_mcr
    lda #0                      ; leave MCR clean before bailing
    sta (X16_T2),y
serial_no
    clc
    rts

; ---------------------------------------------------------------------
; ser_init -- program a UART for 8N1, FIFOs on, auto-flow, no interrupts.
;   in:  A = UART base low, X = UART base high
;        X16_P0/P1 = baud divisor (SER_BAUD_* constant)
; The UART becomes "the current one" for ser_put/ser_get/etc.
; ---------------------------------------------------------------------
ser_init
    sta ser_base
    stx ser_base+1
    jsr serial_load_ptr

    ldy #SER_LCR                ; DLAB = 1 to reach the divisor latch
    lda #$80
    sta (X16_T0),y
    ldy #SER_RHR               ; DLL
    lda X16_P0
    sta (X16_T0),y
    ldy #SER_IER               ; DLM
    lda X16_P1
    sta (X16_T0),y
    ldy #SER_LCR                ; 8 bits, no parity, 1 stop, DLAB = 0
    lda #$03
    sta (X16_T0),y
    ldy #SER_FCR                ; FIFO enable + reset both, RX trigger 8
    lda #$87
    sta (X16_T0),y
    ldy #SER_MCR                ; DTR+RTS, auto-flow, OUT2 (ZiModem stream)
    lda #$27
    sta (X16_T0),y
    ldy #SER_IER                ; no interrupts: this module polls
    lda #$00
    sta (X16_T0),y
    rts

; ---------------------------------------------------------------------
; ser_avail -- is a received byte waiting?
;   out: carry set = yes (LSR data-ready), carry clear = no
; ---------------------------------------------------------------------
ser_avail
    jsr serial_load_ptr
    ldy #SER_LSR
    lda (X16_T0),y
    and #SER_LSR_DR
    beq _none
    sec
    rts
_none
    clc
    rts

; ---------------------------------------------------------------------
; ser_get -- read one byte without blocking.
;   out: carry clear + A = byte if one was waiting;
;        carry set if the RX FIFO was empty (A undefined)
; ---------------------------------------------------------------------
ser_get
    jsr serial_load_ptr
    ldy #SER_LSR
    lda (X16_T0),y
    and #SER_LSR_DR
    beq _empty
    ldy #SER_RHR
    lda (X16_T0),y             ; this read pops the RX FIFO
    clc
    rts
_empty
    sec
    rts

; ---------------------------------------------------------------------
; ser_get_wait -- read one byte, blocking until one arrives.
;   out: A = byte
; Spins on the UART: only sane once something is actually connected.
; ---------------------------------------------------------------------
ser_get_wait
    jsr serial_load_ptr
_wait
    ldy #SER_LSR
    lda (X16_T0),y
    and #SER_LSR_DR
    beq _wait
    ldy #SER_RHR
    lda (X16_T0),y
    rts

; ---------------------------------------------------------------------
; ser_put -- send one byte, waiting for room in the transmit FIFO.
;   in:  A = byte
; Preserves nothing but is safe to call in a tight loop.
; ---------------------------------------------------------------------
ser_put
    pha
    jsr serial_load_ptr
_wait
    ldy #SER_LSR
    lda (X16_T0),y
    and #SER_LSR_THRE
    beq _wait                   ; hold until the holding register is empty
    pla
    sta (X16_T0)                ; THR write: no index, so no dummy read
    rts

; ---------------------------------------------------------------------
; ser_puts -- send a NUL-terminated string.
;   in:  A = string low, X = string high
; ---------------------------------------------------------------------
ser_puts
    sta X16_P2
    stx X16_P3
    ldy #0
_loop
    lda (X16_P2),y
    beq _done
    phy
    jsr ser_put
    ply
    iny
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; ser_write -- send a counted (binary-safe) run of bytes.
;   in:  A = data low, X = data high, Y = length (1..255; 0 = 256)
; ---------------------------------------------------------------------
ser_write
    sta X16_P2
    stx X16_P3
    sty X16_P4                  ; remaining count
    ldy #0
_loop
    phy
    lda (X16_P2),y
    jsr ser_put
    ply
    iny
    dec X16_P4
    bne _loop
    rts

; ---------------------------------------------------------------------
; ser_read_until -- read into a buffer until a match string is seen.
;   in:  A = match low, X = match high (NUL-terminated needle)
;        X16_P0/P1 = buffer address
;        X16_P2/P3 = max bytes to store
;   out: X16_P4/P5 = bytes actually stored
; The matched needle is included in the buffer. Stops at the match or at
; max bytes. Blocks on the UART between bytes -- for real hardware.
; ---------------------------------------------------------------------
ser_read_until
    sta X16_T4                  ; X16_TPTR2 = match base (needle start)
    stx X16_T5
    lda X16_T4                  ; X16_P6/P7 = the moving needle cursor
    sta X16_P6
    lda X16_T5
    sta X16_P7
    stz X16_P4                  ; stored count = 0
    stz X16_P5
_loop
    lda X16_P5                  ; stored >= max ?  (16-bit compare)
    cmp X16_P3
    bcc _room
    bne _done
    lda X16_P4
    cmp X16_P2
    bcs _done
_room
    jsr ser_get_wait            ; A = next byte
    ldy #0
    sta (X16_P0),y              ; store it
    inc X16_P0
    bne _nostorehi
    inc X16_P1
_nostorehi
    inc X16_P4                  ; ++stored (16-bit)
    bne _cmp
    inc X16_P5
_cmp
    cmp (X16_P6)                ; does it continue the needle?
    bne _reset
    inc X16_P6                  ; advance the needle cursor
    bne _noneedlehi
    inc X16_P7
_noneedlehi
    lda (X16_P6)                ; needle fully matched (next char NUL)?
    beq _done
    bra _loop
_reset
    lda X16_T4                  ; mismatch: rewind the needle cursor
    sta X16_P6
    lda X16_T5
    sta X16_P7
    bra _loop
_done
    rts

; ---------------------------------------------------------------------
; ser_discard_until -- read and throw away bytes until a match is seen.
;   in:  A = match low, X = match high (NUL-terminated needle)
; The matched needle is discarded too. Blocks on the UART -- hardware.
; ---------------------------------------------------------------------
ser_discard_until
    sta X16_T4                  ; needle base
    stx X16_T5
    lda X16_T4                  ; moving cursor in X16_P6/P7
    sta X16_P6
    lda X16_T5
    sta X16_P7
_loop
    jsr ser_get_wait
    cmp (X16_P6)
    bne _reset
    inc X16_P6
    bne _nohi
    inc X16_P7
_nohi
    lda (X16_P6)
    beq _done                   ; hit the NUL: whole needle matched
    bra _loop
_reset
    lda X16_T4
    sta X16_P6
    lda X16_T5
    sta X16_P7
    bra _loop
_done
    rts

; copy the current UART base into X16_TPTR0 for (zp),y register access
serial_load_ptr
    lda ser_base
    sta X16_T0
    lda ser_base+1
    sta X16_T0+1
    rts

ser_base .byte 0, 0             ; the UART ser_init last selected
ser_u0   .byte 0, 0             ; ser_detect results
ser_u1   .byte 0, 0

; (end zone)
.endif
.if xuse_serial_zimodem
; --- inline comms/zimodem.asm ---
;ACME
; =====================================================================
; x16lib :: comms/zimodem.asm -- ZiModem (ESP32 WiFi) over the serial card
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The WiFi half of the serial card is an ESP32 running ZiModem firmware.
; You drive it as a Hayes-style modem: send "AT..." command lines over
; UART 0 and read the replies back, "OK\r\n" on success. This layer is a
; thin skin over comms/serial.asm's ser_* primitives -- it frames the AT
; commands and matches the replies; it is not the ESP32 firmware.
;
;       lda #<uart : ldx #>uart          ; a base from ser_detect
;       lda #<SER_BAUD_115200 : sta X16_P0
;       lda #>SER_BAUD_115200 : sta X16_P1
;       jsr zi_init                      ; reset the modem to a known state
;       lda #<atcmd : ldx #>atcmd
;       jsr zi_cmd                       ; e.g. "atd..." to dial a host
;       jsr zi_wait_ok
;
; zi_init leaves the same UART selected that ser_init did, so every ser_*
; call keeps working alongside these.
;
; A NOTE ON TESTING. Unlike the base UART module, ZiModem is an
; interactive protocol: nearly every routine here blocks reading the
; ESP32's reply (through ser_discard_until / ser_read_until / ser_get_wait).
; The bundled emulator has no ESP32 and never fills the receive FIFO, so
; those flows cannot run headless -- they are verified on real hardware.
; What the test suite DOES pin on-target is the one piece of real logic:
; zi_hexdecode (the hex-mode payload decoder), plus zi_cmd's transmit
; path, plus 7-way byte parity. The rest is documented, not emulator-run.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; zi_init -- put the ESP32 into a known command state.
;   in:  A = UART base low, X = UART base high
;        X16_P0/P1 = baud divisor (SER_BAUD_* constant)
; Programs the UART (ser_init), lets the board settle, aborts any stream
; left running with CTRL-C, then applies the standard ZiModem config
; (echo off, verbose result codes, stream mode) and waits for "OK".
; ---------------------------------------------------------------------
zi_init
    jsr ser_init                ; program + select the UART
    lda #4                      ; the ESP32 may still be booting
    jsr zi_delay
    lda #$03                    ; CTRL-C: abort any prior file stream
    jsr ser_put
    lda #2
    jsr zi_delay
    lda #<zi_cfg                ; ate0q0v1x1f0r1s45=3&p0&k3
    ldx #>zi_cfg
    jsr zi_cmd
    jmp zi_wait_ok

; ---------------------------------------------------------------------
; zi_reset -- issue ATZ, returning the modem to its saved profile.
; ---------------------------------------------------------------------
zi_reset
    lda #$03
    jsr ser_put
    lda #2
    jsr zi_delay
    lda #<zi_atz
    ldx #>zi_atz
    jsr zi_cmd
    jmp zi_wait_ok

; ---------------------------------------------------------------------
; zi_cmd -- send an AT command line.
;   in:  A = command low, X = command high (NUL-terminated, no CR)
; Appends the CR/LF the firmware expects. Pure transmit -- it does NOT
; read the reply; follow with zi_wait_ok (or your own read) when the
; command answers with "OK".
; ---------------------------------------------------------------------
zi_cmd
    jsr ser_puts                ; the command text
    lda #<zi_crlf
    ldx #>zi_crlf
    jmp ser_puts                ; the line ending

; ---------------------------------------------------------------------
; zi_wait_ok -- read and discard the reply up to and including "OK\r\n".
; Blocks on the UART -- for a connected board.
; ---------------------------------------------------------------------
zi_wait_ok
    lda #<zi_ok
    ldx #>zi_ok
    jmp ser_discard_until

; ---------------------------------------------------------------------
; zi_get_ip -- fetch the current IPv4 address as a NUL-terminated string.
;   in:  A = buffer low, X = buffer high (>= 25 bytes)
; Sends ATI2, reads the reply, and trims it at the first whitespace so
; the buffer holds just the dotted-quad. Blocks -- hardware.
; ---------------------------------------------------------------------
zi_get_ip
    sta zi_dest
    stx zi_dest+1
    lda #<zi_ati2
    ldx #>zi_ati2
    jsr zi_cmd                  ; ATI2 -> the board prints its IP then OK
    lda zi_dest                 ; read the reply into the caller's buffer
    sta X16_P0
    lda zi_dest+1
    sta X16_P1
    lda #24
    sta X16_P2
    stz X16_P3
    lda #<zi_ok
    ldx #>zi_ok
    jsr ser_read_until          ; up to and including "OK\r\n"
    lda zi_dest                 ; a zero-page cursor to walk the reply
    sta X16_T0
    lda zi_dest+1
    sta X16_T0+1
    ldy #0                      ; trim at the first control/space char
_scan
    lda (X16_T0),y
    cmp #' '+1                  ; anything <= space ends the address
    bcc _cut
    iny
    bne _scan
_cut
    lda #0
    sta (X16_T0),y
    rts

; ---------------------------------------------------------------------
; zi_hex_open -- begin a hex-mode file download.
;   in:  A = filename/URL low, X = filename/URL high (NUL-terminated)
;   out: carry clear = transfer started, carry set = file not found
; Switches the board to hex transfer, requests the file, and eats the
; "[..header..]" line. Then pull the payload with zi_hex_chunk until it
; returns 0, and finish with zi_hex_close. Blocks -- hardware.
; ---------------------------------------------------------------------
zi_hex_open
    sta zi_fname
    stx zi_fname+1
    lda #<zi_ats45              ; ats45=1 : enable hex-mode transfer
    ldx #>zi_ats45
    jsr zi_cmd
    jsr zi_wait_ok
    lda #<zi_atg                ; at&g"
    ldx #>zi_atg
    jsr ser_puts
    lda zi_fname
    ldx zi_fname+1
    jsr ser_puts                ; the filename
    lda #<zi_qcrlf              ; " CR LF
    ldx #>zi_qcrlf
    jsr ser_puts
    jsr ser_get_wait            ; '[' opens the header, anything else errs
    cmp #'['
    bne _err
    lda #<zi_crlf               ; skip the rest of the header line
    ldx #>zi_crlf
    jsr ser_discard_until
    clc
    rts
_err
    lda #<zi_rrerr              ; drain to the end of the "ERROR" line
    ldx #>zi_rrerr
    jsr ser_discard_until
    sec
    rts

; ---------------------------------------------------------------------
; zi_hex_chunk -- read the next payload chunk of a hex-mode download.
;   in:  A = buffer low, X = buffer high (must hold >= 44 bytes)
;   out: A = bytes decoded into the buffer, 0 when the file is done
; One hex line -> up to 44 raw bytes. Blocks on the UART -- hardware.
; ---------------------------------------------------------------------
zi_hex_chunk
    sta zi_dest
    stx zi_dest+1
    lda #<zi_linebuf            ; read one CR/LF-terminated line
    sta X16_P0
    lda #>zi_linebuf
    sta X16_P1
    lda #90
    sta X16_P2
    stz X16_P3
    lda #<zi_crlf
    ldx #>zi_crlf
    jsr ser_read_until          ; P4/P5 = bytes stored (incl. the CR/LF)
    lda X16_P5
    bne _data
    lda X16_P4                  ; "OK\r\n" (4 bytes, starts 'O') ends it
    cmp #4
    bne _data
    lda zi_linebuf
    cmp #'O'
    bne _data
    lda #0
    rts
_data
    lda X16_P4                  ; digits = line length minus the CR/LF
    sec
    sbc #2
    tay
    lda zi_dest                 ; decode into the caller's buffer
    sta X16_P0
    lda zi_dest+1
    sta X16_P1
    lda #<zi_linebuf
    ldx #>zi_linebuf
    jmp zi_hexdecode            ; returns A = bytes produced

; ---------------------------------------------------------------------
; zi_hex_close -- swallow the trailing "OK" after the payload.
; ---------------------------------------------------------------------
zi_hex_close
    jmp zi_wait_ok

; ---------------------------------------------------------------------
; zi_hexdecode -- turn a run of ASCII hex digits into packed bytes.
;   in:  A = source low, X = source high (uppercase hex text)
;        Y = number of digits (even)
;        X16_P0/P1 = destination pointer
;   out: A = bytes written (Y / 2); X16_P0/P1 advanced past them
; The one piece of ZiModem logic with an independent oracle, so it is a
; standalone routine the test suite drives directly.
; ---------------------------------------------------------------------
zi_hexdecode
    sta X16_T4                  ; T4/T5 = source cursor
    stx X16_T5
    sty X16_T6                  ; T6 = digits left
    stz X16_T7                  ; T7 = bytes produced
_loop
    lda X16_T6
    beq _done
    ldy #0
    lda (X16_T4),y              ; high nibble digit
    jsr zimodem_nib
    asl
    asl
    asl
    asl
    sta X16_T3
    ldy #1
    lda (X16_T4),y              ; low nibble digit
    jsr zimodem_nib
    ora X16_T3
    sta (X16_P0)                ; store the packed byte
    inc X16_P0
    bne _dst
    inc X16_P1
_dst
    lda X16_T4                  ; source += 2
    clc
    adc #2
    sta X16_T4
    bcc _src
    inc X16_T5
_src
    inc X16_T7
    dec X16_T6
    dec X16_T6
    bra _loop
_done
    lda X16_T7
    rts

; one ASCII hex digit in A -> its 0..15 value (uppercase A-F)
zimodem_nib
    sec
    sbc #'0'
    cmp #10
    bcc zimodem_nib_lo
    sbc #('A' - '0' - 10)       ; = 7: fold 'A'..'F' onto 10..15
zimodem_nib_lo
    rts

; ---------------------------------------------------------------------
; zi_delay -- a coarse busy-wait so the ESP32 can keep up.
;   in:  A = ticks (~40 ms each at 8 MHz; timing is approximate)
; Self-contained (no jiffy IRQ, no KERNAL), so it works in any context.
; ---------------------------------------------------------------------
zi_delay
    tax
    beq _done
_tick
    lda #0                      ; A: 256-step middle counter
_mid
    ldy #0
_inner
    iny
    bne _inner                  ; 256 inner steps
    inc a
    bne _mid                    ; 256 middle steps -> 65536 inner
    dex
    bne _tick
_done
    rts

; --- data ------------------------------------------------------------
zi_cfg   .text "ate0q0v1x1f0r1s45=3&p0&k3", $00
zi_atz   .text "atz", $00
zi_ati2  .text "ati2", $00
zi_ats45 .text "ats45=1", $00
zi_atg   .text "at&g", $22, $00     ; at&g"
zi_qcrlf .byte $22, $0D, $0A, $00   ; " CR LF
zi_crlf  .byte $0D, $0A, $00
zi_ok    .text "OK", $0D, $0A, $00
zi_rrerr .text "RROR", $0D, $0A, $00

zi_dest  .byte 0, 0                 ; caller's current destination buffer
zi_fname .byte 0, 0
zi_linebuf .fill 90, 0              ; one hex line, read before decoding

; (end zone)
.endif
.if xuse_bank
; --- inline storage/bank.asm ---
;ACME
; =====================================================================
; x16lib :: storage/bank.asm -- banked RAM ($A000-$BFFF window)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; RAM_BANK ($00) selects which 8 KB bank appears at $A000-$BFFF.
; Bank 0 holds KERNAL variables; banks 1..255 are yours.
;
; Offsets are 0..8191 into the window. The bulk copies auto-advance
; across bank boundaries, so a run may start near the end of one bank
; and finish in the next.
;
; All routines here save and restore RAM_BANK, so they are safe to call
; without disturbing whatever bank the caller had mapped in.
; =====================================================================

; (zone: file scope in 64tass)

BANK_WINDOW     = $A000
BANK_WINDOW_END = $C000
BANK_SIZE       = BANK_WINDOW_END - BANK_WINDOW    ; 8192

; ---------------------------------------------------------------------
; bank_set / bank_get -- the RAM bank mapped at $A000
; ---------------------------------------------------------------------
bank_set
    sta RAM_BANK
    rts

bank_get
    lda RAM_BANK
    rts

; ---------------------------------------------------------------------
; bank_peek
;   in:  A = bank, X16_P0/P1 = offset (0..8191)
;   out: A = byte
; bank_poke
;   in:  A = byte, X = bank, X16_P0/P1 = offset
; ---------------------------------------------------------------------
bank_peek
    ldx RAM_BANK
    phx
    sta RAM_BANK
    jsr bank_window_ptr
    ldy #0
    lda (X16_T0),y
    plx
    stx RAM_BANK
    rts

bank_poke
    pha                         ; [byte]
    lda RAM_BANK
    pha                         ; [byte][caller bank]
    stx RAM_BANK
    jsr bank_window_ptr
    ldy #0
    pla
    tax                         ; X = caller bank
    pla                         ; A = byte to store
    sta (X16_T0),y
    stx RAM_BANK
    rts

; Shared helpers are zone-local (a leading '.'), not cheap locals (a
; leading '@'): a cheap local only reaches from one global label to the
; next, so bank_peek could not see a helper defined after bank_poke.

; T0/T1 = BANK_WINDOW + offset. Preserves A.
bank_window_ptr
    pha
    lda X16_P0
    clc
    adc #<BANK_WINDOW
    sta X16_T0
    lda X16_P1
    adc #>BANK_WINDOW
    sta X16_T1
    pla
    rts

; ---------------------------------------------------------------------
; mem_to_bank -- copy low RAM into banked RAM
;   in:  X16_P0/P1 = source address
;        X16_P2    = destination bank
;        X16_P3/P4 = destination offset (0..8191)
;        X16_P5/P6 = byte count
;
; bank_to_mem -- the inverse
;   in:  X16_P0    = source bank
;        X16_P1/P2 = source offset
;        X16_P3/P4 = destination address
;        X16_P5/P6 = byte count
;
; Both auto-advance: a run that hits the end of a bank continues at
; offset 0 of the next. The heavy lifting is the KERNAL's MEMORY_COPY
; ($FEE7) one bank-segment at a time -- far faster than a byte loop.
; ---------------------------------------------------------------------
mem_to_bank
    lda RAM_BANK
    pha
    lda X16_P2
    sta RAM_BANK

    lda X16_P0                  ; T0/T1 = low-RAM side
    sta X16_T0
    lda X16_P1
    sta X16_T1
    lda X16_P3                  ; T2/T3 = offset within the window
    sta X16_T2
    lda X16_P4
    sta X16_T3
    lda X16_P5                  ; T4/T5 = remaining
    sta X16_T4
    lda X16_P6
    sta X16_T5

_seg_out
    jsr bank_segment                ; T6/T7 = bytes until the bank edge
    beq _out_done
    lda X16_T0                  ; source: low RAM
    sta r0L
    lda X16_T1
    sta r0H
    lda X16_T2                  ; target: window + offset
    sta r1L
    lda X16_T3
    clc
    adc #>BANK_WINDOW
    sta r1H
    lda X16_T6
    sta r2L
    lda X16_T7
    sta r2H
    jsr MEMORY_COPY
    jsr bank_advance
    bra _seg_out
_out_done
    pla
    sta RAM_BANK
    rts

bank_to_mem
    lda RAM_BANK
    pha
    lda X16_P0
    sta RAM_BANK

    lda X16_P3                  ; T0/T1 = low-RAM side
    sta X16_T0
    lda X16_P4
    sta X16_T1
    lda X16_P1                  ; T2/T3 = offset within the window
    sta X16_T2
    lda X16_P2
    sta X16_T3
    lda X16_P5
    sta X16_T4
    lda X16_P6
    sta X16_T5

_seg_in
    jsr bank_segment
    beq _in_done
    lda X16_T2                  ; source: window + offset
    sta r0L
    lda X16_T3
    clc
    adc #>BANK_WINDOW
    sta r0H
    lda X16_T0                  ; target: low RAM
    sta r1L
    lda X16_T1
    sta r1H
    lda X16_T6
    sta r2L
    lda X16_T7
    sta r2H
    jsr MEMORY_COPY
    jsr bank_advance
    bra _seg_in
_in_done
    pla
    sta RAM_BANK
    rts

; --- shared helpers --------------------------------------------------

; T6/T7 = min(remaining, space left in this bank). Z set when nothing
; remains.
bank_segment
    lda X16_T4
    ora X16_T5
    beq bank_seg_done               ; remaining == 0 (Z set for the caller)

    sec                         ; space = $2000 - offset
    lda #<BANK_SIZE
    sbc X16_T2
    sta X16_T6
    lda #>BANK_SIZE
    sbc X16_T3
    sta X16_T7

    lda X16_T5                  ; remaining < space? then take remaining
    cmp X16_T7
    bcc bank_seg_take_rem
    bne bank_seg_have
    lda X16_T4
    cmp X16_T6
    bcs bank_seg_have
bank_seg_take_rem
    lda X16_T4
    sta X16_T6
    lda X16_T5
    sta X16_T7
bank_seg_have
    lda #1                      ; Z clear: there is work to do
bank_seg_done
    rts

; consume T6/T7 bytes: advance the low-RAM pointer and the window
; offset (rolling into the next bank), shrink the remaining count.
bank_advance
    clc
    lda X16_T0
    adc X16_T6
    sta X16_T0
    lda X16_T1
    adc X16_T7
    sta X16_T1

    clc
    lda X16_T2
    adc X16_T6
    sta X16_T2
    lda X16_T3
    adc X16_T7
    sta X16_T3
    cmp #>BANK_SIZE             ; offset reached $2000: next bank
    bne bank_adv_count
    stz X16_T2
    stz X16_T3
    inc RAM_BANK
bank_adv_count
    sec
    lda X16_T4
    sbc X16_T6
    sta X16_T4
    lda X16_T5
    sbc X16_T7
    sta X16_T5
    rts

; ---------------------------------------------------------------------
; bank_copy_far -- copy banked RAM to banked RAM
;   in:  X16_P0    = source bank,      X16_P1/P2 = source offset
;        X16_P3    = destination bank, X16_P4/P5 = destination offset
;        X16_P6/P7 = byte count
;
; Only one bank fits in the $A000 window at a time, so this bounces
; through a small low-RAM buffer, MEMORY_COPY on both legs. Both sides
; auto-advance across bank boundaries. The parameter block is consumed.
; ---------------------------------------------------------------------
bank_copy_far
    lda RAM_BANK
    pha

_far_loop
    lda X16_P6
    ora X16_P7
    bne _far_more
    jmp _far_done               ; out of branch range from here
_far_more

    ; chunk = min(count, bounce size, source bank space, dest space)
    ldx #BANK_BOUNCE_SIZE
    lda X16_P7
    bne _far_src_cap            ; count >= 256: the buffer is the cap
    lda X16_P6
    cmp #BANK_BOUNCE_SIZE
    bcs _far_src_cap
    tax                         ; count < buffer: count is the cap
_far_src_cap
    ; Space to the end of a bank only matters when the offset is in the
    ; window's last page: below that, more than a full chunk remains.
    sec
    lda #<BANK_SIZE
    sbc X16_P1
    sta X16_T0
    lda #>BANK_SIZE
    sbc X16_P2
    bne _far_dst_cap            ; >= 256 bytes left in the source bank
    txa
    cmp X16_T0
    bcc _far_dst_cap
    ldx X16_T0
_far_dst_cap
    sec
    lda #<BANK_SIZE
    sbc X16_P4
    sta X16_T0
    lda #>BANK_SIZE
    sbc X16_P5
    bne _far_go
    txa
    cmp X16_T0
    bcc _far_go
    ldx X16_T0
_far_go
    stx X16_T7                  ; T7 = chunk (1..BANK_BOUNCE_SIZE)

    lda X16_P0                  ; leg 1: source bank -> bounce buffer
    sta RAM_BANK
    lda X16_P1
    sta r0L
    lda X16_P2
    clc
    adc #>BANK_WINDOW
    sta r0H
    lda #<bank_bounce
    sta r1L
    lda #>bank_bounce
    sta r1H
    stx r2L
    stz r2H
    jsr MEMORY_COPY

    lda X16_P3                  ; leg 2: bounce buffer -> destination
    sta RAM_BANK
    lda #<bank_bounce
    sta r0L
    lda #>bank_bounce
    sta r0H
    lda X16_P4
    sta r1L
    lda X16_P5
    clc
    adc #>BANK_WINDOW
    sta r1H
    lda X16_T7
    sta r2L
    stz r2H
    jsr MEMORY_COPY

    clc                         ; advance the source (bank rolls at $2000)
    lda X16_P1
    adc X16_T7
    sta X16_P1
    lda X16_P2
    adc #0
    sta X16_P2
    cmp #>BANK_SIZE
    bne _far_adv_dst
    stz X16_P1
    stz X16_P2
    inc X16_P0
_far_adv_dst
    clc
    lda X16_P4
    adc X16_T7
    sta X16_P4
    lda X16_P5
    adc #0
    sta X16_P5
    cmp #>BANK_SIZE
    bne _far_count
    stz X16_P4
    stz X16_P5
    inc X16_P3
_far_count
    sec
    lda X16_P6
    sbc X16_T7
    sta X16_P6
    lda X16_P7
    sbc #0
    sta X16_P7
    jmp _far_loop

_far_done
    pla
    sta RAM_BANK
    rts

BANK_BOUNCE_SIZE = 128
bank_bounce
    .fill BANK_BOUNCE_SIZE, 0

; (end zone)
.endif
.if xuse_bankalloc
; --- inline storage/bankalloc.asm ---
;ACME
; =====================================================================
; x16lib :: storage/bankalloc.asm -- whole-bank RAM allocator
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Banked RAM is 8 KB pages at $A000, selected by RAM_BANK. The natural
; allocation unit IS the bank: sample sets, level maps, decompression
; buffers. This is a bitmap allocator over banks 1-255 (bank 0 belongs
; to the KERNAL).
;
; The allocator hands out BANK NUMBERS; it never touches RAM_BANK
; itself. Combine with bank_peek/poke, mem_to_bank/bank_to_mem and
; bank_copy_far from storage/bank.asm.
;
;       lda #1                  ; manage banks 1..
;       ldx #63                 ; ..63 (a 512K machine's worth minus 0)
;       jsr bank_alloc_init
;       jsr bank_alloc          ; carry clear, A = a free bank
;       ...
;       jsr bank_free           ; give it back
; =====================================================================

; (zone: file scope in 64tass)

ba_map .fill 32, 0              ; one bit per bank; set = FREE

bankalloc_bit
    .byte $01, $02, $04, $08, $10, $20, $40, $80

; ---------------------------------------------------------------------
; bank_alloc_init -- define the pool
;   in:  A = first bank, X = last bank (inclusive); A <= X
;
; Banks outside the range are never handed out. Call again to reset
; the pool (all banks become free; nothing is remembered).
; ---------------------------------------------------------------------
bank_alloc_init
    sta X16_T0                  ; first
    stx X16_T1                  ; last

    ldx #31                     ; everything starts out un-ownable
_clear
    stz ba_map,x
    dex
    bpl _clear

    lda X16_T0
_mark
    jsr bankalloc_set_bit                ; mark free
    lda X16_T0
    cmp X16_T1
    beq _done
    inc X16_T0
    lda X16_T0
    bra _mark
_done
    rts

; ---------------------------------------------------------------------
; bank_alloc -- take a free bank from the pool
;   out: carry clear, A = bank number -- or carry set: pool exhausted
;   Allocates the lowest free bank first.
; ---------------------------------------------------------------------
bank_alloc
    ldx #0
_scan
    lda ba_map,x
    bne _found
    inx
    cpx #32
    bne _scan
    sec                         ; nothing free
    rts
_found
    ldy #0
_bit
    lda ba_map,x
    and bankalloc_bit,y
    bne _take
    iny
    bra _bit                    ; must hit: the byte was nonzero
_take
    lda ba_map,x                ; clear the bit: bank is now in use
    eor bankalloc_bit,y
    sta ba_map,x
    txa                         ; bank = byte index * 8 + bit index
    asl
    asl
    asl
    sta X16_T0
    tya
    ora X16_T0
    clc
    rts

; ---------------------------------------------------------------------
; bank_free -- return a bank to the pool
;   in:  A = bank number (one that bank_alloc handed out)
;
; Freeing a bank that is already free, or that was never in the pool,
; quietly marks it allocatable -- there is no ownership record to
; check against, so don't do that.
; ---------------------------------------------------------------------
bank_free
    ; fall through to bankalloc_set_bit

; mark bank A's bit in the map. Clobbers A, X, Y; preserves T0/T1 not.
bankalloc_set_bit
    pha
    lsr
    lsr
    lsr
    tax                         ; byte index
    pla
    and #$07
    tay
    lda ba_map,x
    ora bankalloc_bit,y
    sta ba_map,x
    rts

; ---------------------------------------------------------------------
; bank_reserve -- claim a specific bank (mark it in use)
;   in:  A = bank number
;   out: carry clear if it was free and is now yours; carry set if it
;        was already taken (or outside the pool)
; ---------------------------------------------------------------------
bank_reserve
    pha
    lsr
    lsr
    lsr
    tax
    pla
    and #$07
    tay
    lda ba_map,x
    and bankalloc_bit,y
    beq _taken
    lda ba_map,x                ; it was free: clear the bit
    eor bankalloc_bit,y
    sta ba_map,x
    clc
    rts
_taken
    sec
    rts

; (end zone)
.endif
.if xuse_stack
; --- inline storage/stack.asm ---
;ACME
; =====================================================================
; x16lib :: storage/stack.asm -- an 8 KB LIFO stack in a HIRAM bank
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; A last-in-first-out stack whose 8 KB of storage is one whole banked-RAM
; bank ($A000-$BFFF). Tell it which bank to own with stack_init, then push
; and pop bytes or words. It grows downward from the top of the bank; the
; stack POINTER and the free/size counters live in low RAM, so only the
; data itself sits in the bank. There are no over/underflow guards -- the
; capacity is 8191 bytes, check stack_isfull / stack_isempty yourself.
;
;       lda #5 : jsr stack_init      ; take bank 5 for the stack
;       lda #42 : jsr stack_push
;       lda #<1000 : ldx #>1000 : jsr stack_pushw
;       jsr stack_popw               ; A/X = 1000
;       jsr stack_pop                ; A = 42
;
; Every routine saves and restores RAM_BANK, so a stack in bank 5 and your
; own use of bank 7 in between never trip over each other. The small
; 256-byte stack that does not need a bank is stk_* in util/buffers.asm.
; =====================================================================

; (zone: file scope in 64tass)

STACK_TOP = 8191                ; top offset of the bank window (0..8191)

stack_bank .byte 0              ; the HIRAM bank the stack owns
stack_sp   .byte 0, 0           ; 16-bit offset; grows down from STACK_TOP

; ---------------------------------------------------------------------
; stack_init -- claim a bank and empty the stack.
;   in: A = HIRAM bank number
; ---------------------------------------------------------------------
stack_init
    sta stack_bank
    lda #<STACK_TOP
    sta stack_sp
    lda #>STACK_TOP
    sta stack_sp+1
    rts

; ---------------------------------------------------------------------
; stack_push -- push one byte.  in: A = byte
; ---------------------------------------------------------------------
stack_push
    sta X16_T2
    lda RAM_BANK
    sta X16_T3
    lda stack_bank
    sta RAM_BANK
    jsr stack_sptr
    lda X16_T2
    sta (X16_T0)                ; buffer[sp] = value
    jsr stack_spdec
    lda X16_T3
    sta RAM_BANK
    rts

; ---------------------------------------------------------------------
; stack_pushw -- push one word (low byte first, then high).
;   in: A = low, X = high
; ---------------------------------------------------------------------
stack_pushw
    sta X16_T2
    stx X16_T4
    lda RAM_BANK
    sta X16_T3
    lda stack_bank
    sta RAM_BANK
    jsr stack_sptr
    lda X16_T2
    sta (X16_T0)                ; buffer[sp] = low
    jsr stack_spdec
    jsr stack_sptr
    lda X16_T4
    sta (X16_T0)                ; buffer[sp] = high
    jsr stack_spdec
    lda X16_T3
    sta RAM_BANK
    rts

; ---------------------------------------------------------------------
; stack_pop -- pop one byte.  out: A = byte
; ---------------------------------------------------------------------
stack_pop
    lda RAM_BANK
    sta X16_T3
    lda stack_bank
    sta RAM_BANK
    jsr stack_spinc
    jsr stack_sptr
    lda (X16_T0)
    tay
    lda X16_T3
    sta RAM_BANK
    tya
    rts

; ---------------------------------------------------------------------
; stack_popw -- pop one word.  out: A = low, X = high
; The high byte was pushed last, so it comes off first.
; ---------------------------------------------------------------------
stack_popw
    lda RAM_BANK
    sta X16_T3
    lda stack_bank
    sta RAM_BANK
    jsr stack_spinc
    jsr stack_sptr
    lda (X16_T0)
    sta X16_T4                  ; high
    jsr stack_spinc
    jsr stack_sptr
    lda (X16_T0)
    sta X16_T2                  ; low
    lda X16_T3
    sta RAM_BANK
    lda X16_T2
    ldx X16_T4
    rts

; ---------------------------------------------------------------------
; stack_size -- out: A = low, X = high  (bytes stored = STACK_TOP - sp)
; ---------------------------------------------------------------------
stack_size
    sec
    lda #<STACK_TOP
    sbc stack_sp
    pha
    lda #>STACK_TOP
    sbc stack_sp+1
    tax
    pla
    rts

; ---------------------------------------------------------------------
; stack_free -- out: A = low, X = high  (bytes free = sp)
; ---------------------------------------------------------------------
stack_free
    lda stack_sp
    ldx stack_sp+1
    rts

; ---------------------------------------------------------------------
; stack_isempty -- out: carry set if empty (sp == STACK_TOP)
; ---------------------------------------------------------------------
stack_isempty
    lda stack_sp
    cmp #<STACK_TOP
    bne stack_notempty
    lda stack_sp+1
    cmp #>STACK_TOP
    bne stack_notempty
    sec
    rts
stack_notempty
    clc
    rts

; ---------------------------------------------------------------------
; stack_isfull -- out: carry set if less than 2 bytes remain
; (sp == 0, or sp has wrapped below 0 to > STACK_TOP)
; ---------------------------------------------------------------------
stack_isfull
    lda stack_sp+1
    cmp #$20                    ; sp >= $2000: wrapped past the bottom
    bcs stack_full
    bne stack_notfull
    lda stack_sp
    cmp #2                      ; 0 or 1 byte free is full for pushw
    bcc stack_full
stack_notfull
    clc
    rts
stack_full
    sec
    rts

; --- helpers (zone-local so every routine above reaches them) --------
; T0/T1 = $A000 + stack_sp
stack_sptr
    lda stack_sp
    sta X16_T0
    lda stack_sp+1
    clc
    adc #$A0                    ; $A000's high byte; sp_hi <= $1F, no carry
    sta X16_T1
    rts

; sp-- (16-bit)
stack_spdec
    lda stack_sp
    bne stack_spdec_lo
    dec stack_sp+1
stack_spdec_lo
    dec stack_sp
    rts

; sp++ (16-bit)
stack_spinc
    inc stack_sp
    bne stack_spinc_hi
    inc stack_sp+1
stack_spinc_hi
    rts

; (end zone)
.endif
.if xuse_ringbuffer
; --- inline storage/ringbuffer.asm ---
;ACME
; =====================================================================
; x16lib :: storage/ringbuffer.asm -- an 8 KB FIFO ring in a HIRAM bank
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; A first-in-first-out queue whose 8 KB of storage is one whole banked-RAM
; bank ($A000-$BFFF). Tell it which bank to own with ring_init, then put
; and get bytes or words. The head, tail and fill counters live in low
; RAM; only the queued data sits in the bank. There are no over/underflow
; guards -- the capacity is 8191 bytes; check ring_isfull / ring_isempty.
;
;       lda #6 : jsr ring_init       ; take bank 6 for the queue
;       lda #'H' : jsr ring_put
;       lda #<300 : ldx #>300 : jsr ring_putw
;       jsr ring_get                 ; A = 'H'  (FIFO order)
;       jsr ring_getw                ; A/X = 300
;
; Every routine saves and restores RAM_BANK. The small 256-byte ring that
; needs no bank is rb_* in util/buffers.asm.
; =====================================================================

; (zone: file scope in 64tass)

RING_CAP = 8192                 ; the bank window is 8192 bytes (0..8191)

ring_bank .byte 0              ; the HIRAM bank the queue owns
ring_fill .byte 0, 0          ; bytes currently queued
ring_head .byte 0, 0          ; where the next put goes
ring_tail .byte 0, 0          ; one before where the next get comes from

; ---------------------------------------------------------------------
; ring_init -- claim a bank and empty the queue.
;   in: A = HIRAM bank number
; ---------------------------------------------------------------------
ring_init
    sta ring_bank
    stz ring_fill
    stz ring_fill+1
    stz ring_head
    stz ring_head+1
    lda #<(RING_CAP-1)          ; tail starts at the top; the first get's
    sta ring_tail               ; inc_tail wraps it to 0, where head began
    lda #>(RING_CAP-1)
    sta ring_tail+1
    rts

; ---------------------------------------------------------------------
; ring_put -- enqueue one byte.  in: A = byte
; ---------------------------------------------------------------------
ring_put
    sta X16_T2
    lda RAM_BANK
    sta X16_T3
    lda ring_bank
    sta RAM_BANK
    jsr ringbuffer_rhptr
    lda X16_T2
    sta (X16_T0)                ; buffer[head] = value
    lda X16_T3
    sta RAM_BANK
    jsr ringbuffer_inchead
    jsr ringbuffer_fillinc
    rts

; ---------------------------------------------------------------------
; ring_putw -- enqueue one word (low byte first).
;   in: A = low, X = high
; ---------------------------------------------------------------------
ring_putw
    sta X16_T2
    stx X16_T4
    lda RAM_BANK
    sta X16_T3
    lda ring_bank
    sta RAM_BANK
    jsr ringbuffer_rhptr
    lda X16_T2
    sta (X16_T0)                ; buffer[head] = low
    jsr ringbuffer_inchead
    jsr ringbuffer_rhptr
    lda X16_T4
    sta (X16_T0)                ; buffer[head] = high
    lda X16_T3
    sta RAM_BANK
    jsr ringbuffer_inchead
    jsr ringbuffer_fillinc
    jsr ringbuffer_fillinc
    rts

; ---------------------------------------------------------------------
; ring_get -- dequeue one byte.  out: A = byte
; ---------------------------------------------------------------------
ring_get
    jsr ringbuffer_filldec
    jsr ringbuffer_inctail
    lda RAM_BANK
    sta X16_T3
    lda ring_bank
    sta RAM_BANK
    jsr ringbuffer_rtptr
    lda (X16_T0)
    tay
    lda X16_T3
    sta RAM_BANK
    tya
    rts

; ---------------------------------------------------------------------
; ring_getw -- dequeue one word.  out: A = low, X = high
; ---------------------------------------------------------------------
ring_getw
    jsr ringbuffer_filldec
    jsr ringbuffer_filldec
    lda RAM_BANK
    sta X16_T3
    lda ring_bank
    sta RAM_BANK
    jsr ringbuffer_inctail
    jsr ringbuffer_rtptr
    lda (X16_T0)
    sta X16_T2                  ; low
    jsr ringbuffer_inctail
    jsr ringbuffer_rtptr
    lda (X16_T0)
    sta X16_T4                  ; high
    lda X16_T3
    sta RAM_BANK
    lda X16_T2
    ldx X16_T4
    rts

; ---------------------------------------------------------------------
; ring_size -- out: A = low, X = high  (bytes queued = fill)
; ---------------------------------------------------------------------
ring_size
    lda ring_fill
    ldx ring_fill+1
    rts

; ---------------------------------------------------------------------
; ring_free -- out: A = low, X = high  (usable bytes free)
; ---------------------------------------------------------------------
ring_free
    sec
    lda #<(RING_CAP-1)
    sbc ring_fill
    pha
    lda #>(RING_CAP-1)
    sbc ring_fill+1
    tax
    pla
    rts

; ---------------------------------------------------------------------
; ring_isempty -- out: carry set if empty (fill == 0)
; ---------------------------------------------------------------------
ring_isempty
    lda ring_fill
    ora ring_fill+1
    bne ringbuffer_notempty
    sec
    rts
ringbuffer_notempty
    clc
    rts

; ---------------------------------------------------------------------
; ring_isfull -- out: carry set if less than 2 bytes remain (fill >= 8191)
; ---------------------------------------------------------------------
ring_isfull
    lda ring_fill+1
    cmp #>(RING_CAP-1)          ; $1F
    bcc ringbuffer_notfull
    bne ringbuffer_full
    lda ring_fill
    cmp #<(RING_CAP-1)          ; $FF
    bcc ringbuffer_notfull
ringbuffer_full
    sec
    rts
ringbuffer_notfull
    clc
    rts

; --- helpers (zone-local) --------------------------------------------
; T0/T1 = $A000 + ring_head
ringbuffer_rhptr
    lda ring_head
    sta X16_T0
    lda ring_head+1
    clc
    adc #$A0
    sta X16_T1
    rts

; T0/T1 = $A000 + ring_tail
ringbuffer_rtptr
    lda ring_tail
    sta X16_T0
    lda ring_tail+1
    clc
    adc #$A0
    sta X16_T1
    rts

; head++, wrapping to 0 when it reaches RING_CAP (8192)
ringbuffer_inchead
    inc ring_head
    bne ringbuffer_inchead_hi
    inc ring_head+1
ringbuffer_inchead_hi
    lda ring_head+1
    cmp #>RING_CAP              ; $20
    bne ringbuffer_inchead_done
    stz ring_head
    stz ring_head+1
ringbuffer_inchead_done
    rts

; tail++, wrapping to 0 when it reaches RING_CAP
ringbuffer_inctail
    inc ring_tail
    bne ringbuffer_inctail_hi
    inc ring_tail+1
ringbuffer_inctail_hi
    lda ring_tail+1
    cmp #>RING_CAP
    bne ringbuffer_inctail_done
    stz ring_tail
    stz ring_tail+1
ringbuffer_inctail_done
    rts

; fill++ / fill-- (16-bit)
ringbuffer_fillinc
    inc ring_fill
    bne ringbuffer_fillinc_done
    inc ring_fill+1
ringbuffer_fillinc_done
    rts

ringbuffer_filldec
    lda ring_fill
    bne ringbuffer_filldec_lo
    dec ring_fill+1
ringbuffer_filldec_lo
    dec ring_fill
    rts

; (end zone)
.endif
.if xuse_mem
; --- inline storage/mem.asm ---
;ACME
; =====================================================================
; x16lib :: storage/mem.asm -- KERNAL block memory operations
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Thin wrappers over the KERNAL's block routines -- MEMORY_FILL,
; MEMORY_COPY, MEMORY_CRC and MEMORY_DECOMPRESS. These live in the
; $FExx jump table, so no bank switching is needed.
;
; ONE PROPERTY MAKES THESE SPECIAL: addresses in $9F00-$9FFF are NOT
; incremented during the operation. Point a VERA data port somewhere
; and pass $9F23 (VERA_DATA0) as the source or target, and these
; routines stream straight into or out of VRAM at the port's own
; increment. mem_decompress with target VERA_DATA0 unpacks assets
; directly into video memory -- no staging buffer.
;
; All four take a 16-bit byte count; the KERNAL's virtual registers
; r0-r2 are used for arguments and are treated as caller-save, exactly
; like everywhere else in this library.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; mem_fill -- set a block of memory to one value
;   in:  X16_P0/P1 = target address, X16_P2/P3 = byte count, A = value
;
; A target in $9F00-$9FFF is written repeatedly without incrementing:
; to fill VRAM, point port 0 first and pass VERA_DATA0 as the target.
; ---------------------------------------------------------------------
mem_fill
    ldx X16_P2                  ; a zero count fills nothing
    bne _go
    ldx X16_P3
    beq _done
_go
    pha
    lda X16_P0
    sta r0L
    lda X16_P1
    sta r0H
    lda X16_P2
    sta r1L
    lda X16_P3
    sta r1H
    pla
    jmp MEMORY_FILL
_done
    rts

; ---------------------------------------------------------------------
; mem_copy -- copy a block of memory
;   in:  X16_P0/P1 = source, X16_P2/P3 = target, X16_P4/P5 = byte count
;
; The regions may overlap. Source or target in $9F00-$9FFF is not
; incremented, so this uploads to VRAM (target VERA_DATA0), downloads
; from VRAM (source VERA_DATA0), or copies VRAM to VRAM (port to port).
; ---------------------------------------------------------------------
mem_copy
    lda X16_P4                  ; a zero count copies nothing
    ora X16_P5
    beq _done
    lda X16_P0
    sta r0L
    lda X16_P1
    sta r0H
    lda X16_P2
    sta r1L
    lda X16_P3
    sta r1H
    lda X16_P4
    sta r2L
    lda X16_P5
    sta r2H
    jmp MEMORY_COPY
_done
    rts

; ---------------------------------------------------------------------
; mem_crc -- CRC-16/IBM-3740 of a block
;   in:  X16_P0/P1 = address, X16_P2/P3 = byte count
;   out: A = CRC low, X = CRC high
;
; The CRC of an empty block is the algorithm's initial value, $FFFF.
; ---------------------------------------------------------------------
mem_crc
    lda X16_P2
    ora X16_P3
    bne _go
    lda #$FF                    ; empty block: the $FFFF init value
    tax
    rts
_go
    lda X16_P0
    sta r0L
    lda X16_P1
    sta r0H
    lda X16_P2
    sta r1L
    lda X16_P3
    sta r1H
    jsr MEMORY_CRC
    lda r2L
    ldx r2H
    rts

; ---------------------------------------------------------------------
; mem_decompress -- decompress an LZSA2 block
;   in:  X16_P0/P1 = compressed data, X16_P2/P3 = output address
;   out: A/X = address one past the last output byte
;
; Compress with:  lzsa -r -f2 <original> <compressed>
; (raw LZSA2 block -- no frame header).
;
; Cannot decompress in place. The input may sit in banked RAM (map the
; bank yourself; 8 KB limit). A target in $9F00-$9FFF is not
; incremented: point port 0 at VRAM and pass VERA_DATA0 as the target
; to unpack assets straight into video memory.
; ---------------------------------------------------------------------
mem_decompress
    lda X16_P0
    sta r0L
    lda X16_P1
    sta r0H
    lda X16_P2
    sta r1L
    lda X16_P3
    sta r1H
    jsr MEMORY_DECOMPRESS
    lda r1L                     ; the KERNAL leaves r1 one past the end
    ldx r1H
    rts

; (end zone)
.endif
.if xuse_fileio
; --- inline storage/fileio.asm ---
;ACME
; =====================================================================
; x16lib :: storage/fileio.asm -- generic KERNAL file/channel I/O
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; This module is for streamed file/channel I/O: OPEN/CLOSE, CHKIN/CHKOUT,
; CHRIN/CHROUT, READST, and related setup calls. For one-shot PRG
; LOAD/SAVE, keep using storage/load.asm's fs_* helpers.
;
; Helper calls use:
;       X16_P0/P1 = filename address
;       X16_P2    = filename length
;       X16_P3    = logical file number
;       X16_P4    = device
;       X16_P5    = secondary address
; =====================================================================

; (zone: file scope in 64tass)

FIO_DEV_KEYBOARD = 0
FIO_DEV_SCREEN   = 3
FIO_DEV_DISK     = 8
FIO_LFN_COMMAND  = 15
FIO_SA_NONE      = 0
FIO_SA_COMMAND   = 15

; --- raw KERNAL wrappers ---------------------------------------------
fio_set_lfs
    jmp SETLFS                  ; A = logical, X = device, Y = secondary

fio_set_name
    jmp SETNAM                  ; A = length, X/Y = name pointer

; fio_open -- out: carry set on error, A = the KERNAL error code
fio_open
    jmp OPEN

fio_close
    jmp CLOSE                   ; A = logical file number

fio_chkin
    jmp CHKIN                   ; X = logical file number

fio_chkout
    jmp CHKOUT                  ; X = logical file number

fio_clrchn
    jmp CLRCHN

; fio_chrin -- out: A = the byte read from the current input channel
fio_chrin
    jmp CHRIN

fio_chrout
    jmp CHROUT

; fio_readst -- out: A = the KERNAL status byte (bit 6 = end of file)
fio_readst
    jmp READST

; fio_getin -- out: A = one byte, 0 if nothing is waiting
fio_getin
    jmp GETIN

fio_close_all
    jmp CLALL                   ; close every open logical file

fio_close_device
    jmp CLOSE_ALL               ; A = device number

; ---------------------------------------------------------------------
; fio_open_named -- SETNAM + SETLFS + OPEN from X16_P0..P5
;   out: carry follows OPEN
; ---------------------------------------------------------------------
fio_open_named
    jsr fileio_setup
    jmp OPEN

; ---------------------------------------------------------------------
; fio_open_read -- open, then select the logical file for input
;   out: carry set if OPEN or CHKIN failed
; ---------------------------------------------------------------------
fio_open_read
    jsr fio_open_named
    bcs _done
    ldx X16_P3
    jmp CHKIN
_done
    rts

; ---------------------------------------------------------------------
; fio_open_write -- open, then select the logical file for output
;   out: carry set if OPEN or CHKOUT failed
; ---------------------------------------------------------------------
fio_open_write
    jsr fio_open_named
    bcs _done
    ldx X16_P3
    jmp CHKOUT
_done
    rts

; ---------------------------------------------------------------------
; fio_close_named -- CLRCHN + CLOSE for X16_P3
; ---------------------------------------------------------------------
fio_close_named
    jsr CLRCHN
    lda X16_P3
    jmp CLOSE

fileio_setup
    lda X16_P2
    ldx X16_P0
    ldy X16_P1
    jsr SETNAM
    lda X16_P3
    ldx X16_P4
    ldy X16_P5
    jmp SETLFS

; (end zone)
.endif
.if xuse_iec
; --- inline storage/iec.asm ---
;ACME
; =====================================================================
; x16lib :: storage/iec.asm -- low-level IEC / serial bus wrappers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; These are direct helpers for the classic Commodore serial bus / IEC
; KERNAL calls. Most programs should use FILEIO, LOAD, DOS, or BMX
; instead; this gate is for protocols that need explicit bus control.
;
; MACPTR and MCIOUT are X16 block transfers for the current channel:
;       A   = byte count, 0 lets the implementation choose
;       X/Y = destination/source pointer
;       X/Y = bytes transferred on return
;       C   = set when unsupported/error
; =====================================================================

; (zone: file scope in 64tass)

IEC_CMD_DATA  = $60             ; secondary data channel command base
IEC_CMD_CLOSE = $E0             ; close channel command base
IEC_CMD_OPEN  = $F0             ; open channel command base

; --- raw KERNAL wrappers ---------------------------------------------
iec_listen
    jmp LISTEN                  ; A = device number

iec_talk
    jmp TALK                    ; A = device number

iec_second
    jmp SECOND                  ; A = secondary/listen command byte

iec_tksa
    jmp TKSA                    ; A = secondary/talk command byte

iec_ciout
    jmp CIOUT                   ; A = byte to send

iec_acptr
    jmp ACPTR                   ; out: A = byte received

iec_unlisten
    jmp UNLSN

iec_untalk
    jmp UNTLK

iec_set_timeout
    jmp SETTMO                  ; A = timeout control (ROM r49 is a no-op)

iec_readst
    jmp READST                  ; out: A = serial/KERNAL status

iec_macptr
    jmp MACPTR                  ; block read: A=count, X/Y=dest

iec_mciout
    jmp MCIOUT                  ; block write: A=count, X/Y=source

; ---------------------------------------------------------------------
; iec_open_channel -- LISTEN device, send OPEN secondary command
;   in: A = device number, Y = secondary channel
; ---------------------------------------------------------------------
iec_open_channel
    jsr LISTEN
    tya
    ora #IEC_CMD_OPEN
    jmp SECOND

; ---------------------------------------------------------------------
; iec_data_channel -- LISTEN device, send DATA secondary command
;   in: A = device number, Y = secondary channel
; ---------------------------------------------------------------------
iec_data_channel
    jsr LISTEN
    tya
    ora #IEC_CMD_DATA
    jmp SECOND

; ---------------------------------------------------------------------
; iec_talk_channel -- TALK device, send DATA secondary command
;   in: A = device number, Y = secondary channel
; ---------------------------------------------------------------------
iec_talk_channel
    jsr TALK
    tya
    ora #IEC_CMD_DATA
    jmp TKSA

; ---------------------------------------------------------------------
; iec_close_channel -- LISTEN device, send CLOSE secondary command
;   in: A = device number, Y = secondary channel
; ---------------------------------------------------------------------
iec_close_channel
    jsr LISTEN
    tya
    ora #IEC_CMD_CLOSE
    jmp SECOND

; (end zone)
.endif
.if xuse_load
; --- inline storage/load.asm ---
;ACME
; =====================================================================
; x16lib :: storage/load.asm -- load and save
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Device 8 is the SD card. Filenames are (address, length), not
; NUL-terminated.
;
; Two different registers steer a load, and they are easy to conflate:
;
;   SETLFS's secondary address says how to TREAT the file:
;     0  skip the 2-byte PRG header, load at the address you pass in X/Y
;     1  skip it, load at the address the header itself names
;     2  raw: no header to skip, load everything at your X/Y address
;
;   LOAD's own A register says WHERE memory-wise:
;     0  system RAM        1  verify only
;     2  VRAM bank 0       3  VRAM bank 1
;
; (Putting 2/3 into the secondary address does NOT reach VRAM -- it
; requests a raw header-included load into system RAM.)
; =====================================================================

; (zone: file scope in 64tass)

FS_SA_ADDR   = 0                ; skip the header, load at the caller's address
FS_SA_HEADER = 1                ; skip it, load at the header's own address
FS_SA_RAW    = 2                ; no header: load the whole file at the address

; ---------------------------------------------------------------------
; fs_setname -- in: X16_P0/P1 = filename address, A = length
; ---------------------------------------------------------------------
fs_setname
    ldx X16_P0
    ldy X16_P1
    jmp SETNAM

; ---------------------------------------------------------------------
; fs_load -- load a file
;   in:  X16_P0/P1 = filename address
;        X16_P2    = filename length
;        X16_P3    = device (usually 8)
;        X16_P4    = secondary address (FS_SA_*)
;        X16_P5/P6 = destination address (ignored when SA = 1)
;   out: carry clear on success; carry set with A = KERNAL error code
;        X/Y = address one past the last byte loaded
; ---------------------------------------------------------------------
fs_load
    lda #0                      ; LOAD A = 0: into system RAM
    ; fall through
; in: A = LOAD's destination code (0 RAM, 2/3 VRAM); rest as fs_load
load_load_common
    sta X16_T3
    lda X16_P2
    jsr fs_setname

    lda #1                      ; logical file number
    ldx X16_P3                  ; device
    ldy X16_P4                  ; secondary address
    jsr SETLFS

    lda X16_T3
    ldx X16_P5
    ldy X16_P6
    jmp LOAD

; ---------------------------------------------------------------------
; fs_save -- save a block of memory as a PRG
;   in:  X16_P0/P1 = filename address
;        X16_P2    = filename length
;        X16_P3    = device
;        X16_P5/P6 = start address
;        X16_T6/T7 = end address, one past the last byte
;   out: carry clear on success; carry set with A = KERNAL error code
;
;   X16_T4/T5 is borrowed as the zero-page pointer KERNAL SAVE requires.
; ---------------------------------------------------------------------
; fs_save wants five 16-bit-ish things and the parameter block is eight
; bytes, so the end address goes in T6/T7 rather than squeezing P7.
;   X16_P5/P6 = start, X16_T6/T7 = end (exclusive)
fs_save
    lda X16_P2
    jsr fs_setname

    lda #1
    ldx X16_P3
    ldy #0                      ; secondary 0: no PRG-header relocation
    jsr SETLFS

    lda X16_P5                  ; SAVE takes the start address through a
    sta X16_T4                  ; zero-page pointer, given by its address
    lda X16_P6
    sta X16_T5

    lda #X16_T4                 ; A = zero-page offset of the pointer
    ldx X16_T6                  ; X/Y = end address, exclusive
    ldy X16_T7
    jmp SAVE

; ---------------------------------------------------------------------
; fs_vload -- load straight into VRAM
;   in:  X16_P0/P1 = filename address
;        X16_P2    = filename length
;        X16_P3    = device
;        X16_P4    = VRAM bank (0 or 1)
;        X16_P5/P6 = VRAM address within that bank
;   out: as fs_load
;
; The bank turns into LOAD's A register (2 or 3); the secondary address
; is forced to 0 so the PRG header is skipped and X/Y is honoured.
; ---------------------------------------------------------------------
fs_vload
    lda X16_P4
    and #$01
    clc
    adc #2                      ; LOAD A: bank 0 -> 2, bank 1 -> 3
    stz X16_P4                  ; SETLFS SA = 0 (does not disturb A)
    bra load_load_common

; ---------------------------------------------------------------------
; fs_prg_entry -- a PRG's entry address, read without loading the file
;   in:  X16_P0/P1 = filename address
;        X16_P2    = filename length
;        X16_P3    = device (usually 8)
;   out: X/Y = the SYS address out of the file's BASIC stub, or $0000 if
;        the file cannot be read or does not begin with one
;
; A launcher has to know where to JSR before it hands the machine over,
; and loading the file to find out is the one thing it cannot do: the
; load would overwrite the launcher asking the question. So this reads
; the first few bytes off the disk and parses the stub where it lies:
;
;   two load-address bytes, two link bytes, two line-number bytes,
;   the SYS token ($9E), any spaces, then the address in ASCII.
;
; The address is read rather than assumed -- a compiler emitting
; "SYS 2071" today moves that number the moment the stub text changes.
; $0000 doubles as "no entry here", since no PRG can start there.
;
; Uses logical file 1, as fs_load does, on secondary address 2 so the
; bytes arrive raw rather than being treated as a program to relocate.
; ---------------------------------------------------------------------
FS_PRG_SKIP = 6                 ; load address, link, line number

fs_prg_entry
    stz X16_T0                  ; the result, built a digit at a time
    stz X16_T1

    lda X16_P2
    jsr fs_setname
    lda #1                      ; logical file
    ldx X16_P3                  ; device
    ldy #2                      ; a plain data channel
    jsr SETLFS
    jsr OPEN
    bcs load_quit
    ldx #1
    jsr CHKIN
    bcs load_quit

    lda #FS_PRG_SKIP            ; CHRIN is free to clobber Y, so the
    sta X16_T6                  ; count cannot live there
load_skip
    jsr load_getb
    bcs load_quit
    dec X16_T6
    bne load_skip

    jsr load_getb                   ; the SYS token
    bcs load_quit
    cmp #$9E
    bne load_quit
load_space
    jsr load_getb
    bcs load_quit
    cmp #' '
    beq load_space
                                ; A = the first character after them
load_digit
    cmp #'0'
    bcc load_quit                   ; a non-digit ends the number, and
    cmp #'9'+1                  ; ending it before it starts leaves 0
    bcs load_quit

    sec
    sbc #'0'
    sta X16_T2

    lda X16_T0                  ; result = result * 10 + digit,
    sta X16_T3                  ; taking *10 as ((r * 4) + r) * 2
    lda X16_T1
    sta X16_T4
    asl X16_T0
    rol X16_T1
    asl X16_T0
    rol X16_T1
    clc
    lda X16_T0
    adc X16_T3
    sta X16_T0
    lda X16_T1
    adc X16_T4
    sta X16_T1
    asl X16_T0
    rol X16_T1
    clc
    lda X16_T0
    adc X16_T2
    sta X16_T0
    lda X16_T1
    adc #0
    sta X16_T1

    jsr load_getb
    bcc load_digit                  ; ran out of file: keep what we have

load_quit
    jsr CLRCHN
    lda #1
    jsr CLOSE
    ldx X16_T0
    ldy X16_T1
    rts

; one byte from the open channel; carry set if the file ended first
load_getb
    jsr CHRIN
    sta X16_T5
    jsr READST
    cmp #0
    bne load_getb_end
    lda X16_T5
    clc
    rts
load_getb_end
    sec
    rts

; (end zone)
.endif
.if xuse_dos
; --- inline storage/dos.asm ---
;ACME
; =====================================================================
; x16lib :: storage/dos.asm -- the DOS command channel
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; fs_load/fs_save report failure with the carry, but never WHY. The
; answer lives on channel 15: every command sent there is answered
; with a status line like "62,FILE NOT FOUND,00,00". These routines
; send commands, read that line, and hand back the numeric code --
; codes below 20 are success, 20 and up are errors, exactly CBM DOS's
; convention.
;
;       jsr dos_status            ; A = code, dos_msg = the text
;       lda #<name : ldx #>name : ldy #len
;       jsr dos_delete            ; carry set if the drive said no
;
; The device defaults to 8; store to dos_device to change it.
; =====================================================================

; (zone: file scope in 64tass)

dos_device .byte 8
dos_code   .byte 0              ; the code from the last command, for
                                ; dos_lasterr -- see its header below

; ---------------------------------------------------------------------
; dos_cmd -- send a raw DOS command and fetch the reply
;   in:  A = command low, X = command high, Y = length (0 = none: just
;        read the pending status)
;   out: A = status code (0-99; 255 if the channel would not open)
;        carry set when the code is an error (>= 20)
;        dos_msg = the full reply, NUL-terminated; Y = its length
; ---------------------------------------------------------------------
dos_cmd
    sta X16_T0
    stx X16_T1
    tya                         ; SETNAM wants A = length, X/Y = address
    ldx X16_T0
    ldy X16_T1
    jsr SETNAM

    lda #15
    ldx dos_device
    ldy #15                     ; secondary 15: the command channel
    jsr SETLFS
    jsr OPEN
    bcs _no_channel

    ldx #15
    jsr CHKIN
    bcs _no_channel

    ldy #0
_read
    jsr CHRIN
    cmp #$0D                    ; the status line ends with a CR
    beq _got
    cpy #(DOS_MSG_MAX - 1)
    bcs _skip                   ; overlong: keep draining, stop storing
    sta dos_msg,y
    iny
_skip
    jsr READST
    beq _read                   ; keep going while the stream is alive
_got
    lda #0
    sta dos_msg,y
    phy
    jsr CLRCHN
    lda #15
    jsr CLOSE
    ply

    ; the code is the first two digits: "62,FILE NOT FOUND,..."
    lda dos_msg
    sec
    sbc #'0'
    sta X16_T0
    asl                         ; *10 = *8 + *2
    asl
    adc X16_T0
    asl
    sta X16_T0
    lda dos_msg+1
    sec
    sbc #'0'
    clc
    adc X16_T0
    sta dos_code
    cmp #20                     ; carry set = error class
    rts

_no_channel
    jsr CLRCHN
    lda #15
    jsr CLOSE
    stz dos_msg
    ldy #0
    lda #$FF
    sta dos_code
    lda #$FF
    sec
    rts

; ---------------------------------------------------------------------
; dos_status -- read the drive's pending status line
;   out: as dos_cmd. Note the first read after power-on returns code
;        73 (the DOS version banner) by design.
; ---------------------------------------------------------------------
dos_status
    lda #0
    tax
    tay
    jmp dos_cmd

; ---------------------------------------------------------------------
; dos_lasterr -- the status code the last dos_* call came back with
;   out: A = the code (0-19 success, 20-99 error, 255 = no channel)
;
; Every routine here reports twice: the carry says pass or fail, and A
; says why. A caller that can only see one of those -- a generated
; high-level binding, say, which will not guess a type for a routine
; that documents both -- can call this afterwards and get the code.
; ---------------------------------------------------------------------
dos_lasterr
    lda dos_code
    rts

; ---------------------------------------------------------------------
; One-call wrappers. Each takes A = name low, X = name high,
; Y = name length, and returns like dos_cmd.
;
;   dos_delete   S:name       scratch a file
;   dos_mkdir    MD:name      make a directory
;   dos_rmdir    RD:name      remove a directory
;   dos_chdir    CD:name      change directory ("/" is the root)
;
; Note "/" and not "//": an emulator's host-filesystem emulation accepts
; CD://, but a real card answers 62, FILE NOT FOUND -- and a chdir that
; fails says nothing, so the caller carries on in the wrong directory.
;
; dos_rename additionally takes the OLD name in X16_P0/P1 with its
; length in X16_P2, and renames it to the A/X/Y name:  R:new=old
; ---------------------------------------------------------------------
dos_delete
    jsr dos_stash_name
    lda #'S'
    sta dos_cmdbuf
    lda #':'
    sta dos_cmdbuf+1
    ldx #2
    bra dos_append_send

dos_mkdir
    jsr dos_stash_name
    lda #'M'
    bra dos_dir_cmd
dos_rmdir
    jsr dos_stash_name
    lda #'R'
    bra dos_dir_cmd
dos_chdir
    jsr dos_stash_name
    lda #'C'
dos_dir_cmd
    sta dos_cmdbuf
    lda #'D'
    sta dos_cmdbuf+1
    lda #':'
    sta dos_cmdbuf+2
    ldx #3
    bra dos_append_send

dos_rename
    jsr dos_stash_name             ; the NEW name
    lda #'R'
    sta dos_cmdbuf
    lda #':'
    sta dos_cmdbuf+1
    ldx #2
    jsr dos_append                 ; R:new
    bcs dos_too_long
    cpx #DOS_CMD_MAX
    bcs dos_too_long
    lda #'='
    sta dos_cmdbuf,x
    inx
    ldy #0                      ; append the OLD name from X16_P0..P2
_old
    cpy X16_P2
    beq _send
    cpx #DOS_CMD_MAX
    bcs dos_too_long
    lda (X16_P0),y
    sta dos_cmdbuf,x
    inx
    iny
    bra _old
_send
    bra dos_send

; park A/X/Y (name pointer + length) in T0/T1/T2
dos_stash_name
    sta X16_T0
    stx X16_T1
    sty X16_T2
    rts

; copy the stashed name into dos_cmdbuf at X, then send; X advances
dos_append_send
    jsr dos_append
    bcs dos_too_long
dos_send
    txa
    tay                         ; Y = total command length
    lda #<dos_cmdbuf
    ldx #>dos_cmdbuf
    jmp dos_cmd

dos_append
    ldy #0
_cp
    cpy X16_T2
    beq _done
    cpx #DOS_CMD_MAX
    bcs _too_long
    lda (X16_T0),y
    sta dos_cmdbuf,x
    inx
    iny
    bra _cp
_done
    clc
    rts
_too_long
    sec
    rts

; local construction failure: no command was sent
dos_too_long
    stz dos_msg
    ldy #0
    lda #$FF
    sec
    rts

DOS_MSG_MAX = 64
DOS_CMD_MAX = 80
dos_msg    .fill DOS_MSG_MAX, 0
dos_cmdbuf .fill DOS_CMD_MAX, 0

; (end zone)
.endif
.if xuse_dir
; --- inline storage/dir.asm ---
;ACME
; =====================================================================
; x16lib :: storage/dir.asm -- reading a directory
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; A drive hands its directory over as a BASIC program listing, which is
; a peculiar thing to have to parse but is what every CBM drive does:
;
;       load address (2)
;       link (2)  blocks (2)  text... $00      <- one entry
;       link (2)  blocks (2)  text... $00
;       $00 $00                                <- end
;
; The "line number" is the block count, and the text carries the name in
; quotes followed by its type:
;
;       "GAME.PRG"        PRG
;       "LEVELS"          DIR
;
; These routines walk that so a caller never sees it:
;
;       +xm_dir_open path, path_len, 8
;       bcs no_directory
; loop  +xm_dir_next namebuf, 40
;       bcc done                  ; carry CLEAR at the end of the listing
;       jsr dir_type              ; A = DIR_TYPE_PRG, _DIR, ...
;       ...
;       bra loop
; done  jsr dir_close
;
; The header line comes back as DIR_TYPE_HOST and the trailing "BLOCKS
; FREE." line as DIR_TYPE_NONE with an empty name, rather than being
; hidden -- a file browser wants to skip them, a disk info panel wants
; to show them, and this way neither has to re-parse anything.
; =====================================================================

; (zone: file scope in 64tass)

DIR_LFN = 3                     ; logical file: clear of fs_load's 1 and
                                ; of the command channel's 15

DIR_TYPE_NONE = 0               ; no name on the line: "BLOCKS FREE."
DIR_TYPE_PRG  = 1
DIR_TYPE_SEQ  = 2
DIR_TYPE_USR  = 3
DIR_TYPE_REL  = 4
DIR_TYPE_DIR  = 5
DIR_TYPE_HOST = 6               ; the header line naming the volume

dir_ty   .byte 0
dir_blk  .word 0

dir_dollar
    .text "$"

; ---------------------------------------------------------------------
; dir_open -- open a directory for reading
;   in:  X16_P0/P1 = path address, X16_P2 = path length
;        (a length of 0 asks for "$", the current directory)
;        X16_P3    = device (usually 8)
;   out: carry set if the directory could not be opened
; ---------------------------------------------------------------------
dir_open
    lda X16_P2
    bne dir_named
    lda #1                      ; no path given: just "$"
    ldx #<dir_dollar
    ldy #>dir_dollar
    bra dir_setnam
dir_named
    ldx X16_P0
    ldy X16_P1
dir_setnam
    jsr SETNAM
    lda #DIR_LFN
    ldx X16_P3
    ldy #0                      ; secondary 0: the directory, not a file
    jsr SETLFS
    jsr OPEN
    bcs dir_openbad
    ldx #DIR_LFN
    jsr CHKIN
    bcs dir_openbad
    jsr dir_getb                   ; the two load-address bytes, discarded
    bcs dir_openbad
    jsr dir_getb
    bcs dir_openbad
    clc
    rts
dir_openbad
    sec
    rts

; ---------------------------------------------------------------------
; dir_next -- read the next entry
;   in:  X16_P0/P1 = a buffer for the name, X16_P2 = its size (2-255)
;   out: carry SET if an entry was read, CLEAR at the end of the listing
;
; The name arrives NUL-terminated and truncated to fit -- the buffer
; size is honoured, so a long name cannot walk off the end of it.
; dir_type and dir_blocks then describe the entry just read.
; ---------------------------------------------------------------------
dir_next
    stz dir_ty                  ; DIR_TYPE_NONE until the line says more
    stz dir_blk
    stz dir_blk+1

    ldx #DIR_LFN                ; the caller may have used the channel
    jsr CHKIN                   ; in between, so re-select it every time
    bcs dir_no

    jsr dir_getb                   ; link
    bcs dir_no
    sta X16_T0
    jsr dir_getb
    bcs dir_no
    ora X16_T0
    beq dir_no                     ; a zero link is the end of the listing

    jsr dir_getb                   ; the line number is the block count
    bcs dir_no
    sta dir_blk
    jsr dir_getb
    bcs dir_no
    sta dir_blk+1

    stz X16_T1                  ; name bytes stored so far
    stz X16_T2                  ; 0 before the name, 1 inside, 2 after
dir_text
    jsr dir_getb
    bcs dir_endline                ; the file ended: keep what we have
    cmp #0
    beq dir_endline                ; and $00 ends the line properly
    ldx X16_T2
    cpx #1
    beq dir_inname
    cpx #2
    beq dir_after
    cmp #'"'                    ; before the name: find the quote
    bne dir_text
    inc X16_T2
    bra dir_text

dir_inname
    cmp #'"'                    ; the closing quote ends the name
    beq dir_closed
    ldx X16_T1
    inx
    cpx X16_P2                  ; room for this byte AND a terminator?
    bcs dir_text                   ; no: drop it, but keep parsing the type
    ldy X16_T1                  ; CHRIN is free to clobber Y, so load it
    sta (X16_P0),y              ; here rather than holding it across
    inc X16_T1
    bra dir_text
dir_closed
    lda #2
    sta X16_T2
    bra dir_text

dir_after
    cmp #' '                    ; the first non-space after the name is
    beq dir_text                   ; the type
    ldx dir_ty
    bne dir_text                   ; already classified this line
    jsr dir_classify
    bra dir_text

dir_endline
    ldy X16_T1
    lda #0
    sta (X16_P0),y              ; NUL-terminate within the buffer
    sec                         ; an entry was read
    rts
dir_no
    clc
    rts

; The first letter is enough: PRG, SEQ, USR, REL, DIR and HOST do not
; collide. A suffix like PRG< (locked) classifies the same way.
dir_classify
    cmp #'P'
    beq dir_t_prg
    cmp #'S'
    beq dir_t_seq
    cmp #'U'
    beq dir_t_usr
    cmp #'R'
    beq dir_t_rel
    cmp #'D'
    beq dir_t_dir
    cmp #'H'
    beq dir_t_host
    rts
dir_t_prg
    lda #DIR_TYPE_PRG
    bra dir_setty
dir_t_seq
    lda #DIR_TYPE_SEQ
    bra dir_setty
dir_t_usr
    lda #DIR_TYPE_USR
    bra dir_setty
dir_t_rel
    lda #DIR_TYPE_REL
    bra dir_setty
dir_t_dir
    lda #DIR_TYPE_DIR
    bra dir_setty
dir_t_host
    lda #DIR_TYPE_HOST
dir_setty
    sta dir_ty
    rts

; ---------------------------------------------------------------------
; dir_type -- what the entry dir_next just read is
;   out: A = DIR_TYPE_PRG, DIR_TYPE_DIR, DIR_TYPE_HOST, ...
; ---------------------------------------------------------------------
dir_type
    lda dir_ty
    rts

; ---------------------------------------------------------------------
; dir_blocks -- how big the entry dir_next just read is
;   out: X/Y = the block count the listing gave for it
; ---------------------------------------------------------------------
dir_blocks
    ldx dir_blk
    ldy dir_blk+1
    rts

; ---------------------------------------------------------------------
; dir_close -- finished with the directory
; ---------------------------------------------------------------------
dir_close
    jsr CLRCHN
    lda #DIR_LFN
    jmp CLOSE

; one byte from the directory channel; carry set if the stream ended
dir_getb
    jsr CHRIN
    sta X16_T3
    jsr READST
    cmp #0
    bne dir_getb_end
    lda X16_T3
    clc
    rts
dir_getb_end
    sec
    rts

; (end zone)
.endif
.if xuse_filepick
; --- inline ui/filepick.asm ---
;ACME
; =====================================================================
; x16lib :: ui/filepick.asm -- a file browser on a panel
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; A directory panel with a mouse and a keyboard: scrolling, descent into
; folders, and one question answered -- which file? The caller does the
; rest. It is the same browser in every program that opens it, which is
; the point: one set of keys, one look, one copy.
;
;       +xm_fp_filter pattern          ; what to list
;       jsr fp_open                    ; A = FPK_NONE / FPK_PICK / FPK_ALT
;       cmp #FPK_PICK
;       bne _nothing
;       jsr fp_path                    ; X/Y = the absolute path
;
; ...or, from a BANKED filepick, fp_copy_path / fp_copy_name into your
; own buffer: a pointer this module returns names its own storage, which
; travels into the bank with it and is not mapped once the wrapper has
; switched back.
;       ...
; _nothing
;       jsr fp_close
;
; THE FILTER is a list of patterns separated by ';':
;
;       "*filepick_prg"             programs
;       "*filepick_bmx;*filepick_png"       either kind of picture
;       "*.*"               every file, whatever it is called
;
; Directories are always listed whatever the filter says, or there would
; be no way to reach the file you wanted. Matching folds case: a drive
; answers in ASCII and a pattern in a PETSCII source is written
; lower-case, and clearing bit 5 lands either on the other.
;
; fp_primary sets a SECOND pattern for callers that list everything but
; can only act on some of it -- a launcher lists "*.*" with a primary of
; "*filepick_prg", and anything else is marked [dat] and can be handed to a
; program rather than run.
;
; WHY THIS IS WORTH BANKING: it is around 3 KB, and a program only needs
; it while the panel is up. -Bank it and the whole browser leaves low
; RAM, wrappers and all; the caller pays for the wrapper it calls.
;
; THE ENTRY CACHE is 64 entries of 40 bytes in a RAM bank -- fp_cache
; says where, and $A400 in bank 63 is the default. The bank is paged in
; while the panel is up and the caller's own bank is restored by
; fp_close.
;
; SAVE-UNDER: a launcher repaints itself when the panel closes and does
; not care what was underneath. A spreadsheet does. fp_saveunder keeps
; the covered characters and colours in a bank and puts them back --
; about 5.7 KB of an 8 KB bank at 80 columns.
; =====================================================================

; (zone: file scope in 64tass)

FPK_NONE   = 0                   ; cancelled: ESC, Run/Stop, or the x box
FPK_PICK   = 1                   ; a file was chosen: fp_path has it
FPK_ALT    = 2                   ; the second gesture: right click, or 'a'
FPK_HERE   = 3                   ; 'h': this DIRECTORY, not a file in it

FPK_ESIZE  = 40                  ; one cache entry: type, then the name
FPK_ETYPE  = 0
FPK_ENAME  = 1
FPK_MAXENT = 64
FPK_NOBANK = 255                 ; fp_saveunder: keep nothing
FPK_PTOP   = 3                   ; the panel's first row
FPK_DBLCLK = 30                  ; jiffies: half a second
FPK_AEDIT  = $76                 ; blue on yellow: the one place the panel
                                 ; is asking rather than showing, and it
                                 ; has to be unmistakable. Deliberately
                                 ; not the caller's palette -- a prompt
                                 ; that blends in is a prompt nobody
                                 ; answers.

; ---- configuration ---------------------------------------------------
fp_vram     .word $2000     ; the listing: VRAM, not banked RAM
fp_vramh    .byte $01       ; ...$12000 by default, clear of the text map
fp_filt     .word 0             ; 0 means "*.*"
fp_prim     .word 0             ; 0 means "the same as the filter"
fp_head     .word 0             ; 0 means "files in "
fp_foot     .word 0
fp_apanel   .byte $F6           ; blue on light grey
fp_abar     .byte $F6
fp_asel     .byte $6F           ; inverted
fp_under    .word $4000     ; the save-under, also VRAM: $14000
fp_underh   .byte $01
fp_undon    .byte 0         ; 0 = keep nothing
fp_chset    .byte 3             ; PET upper/lower; 255 leaves it alone
fp_startat  .word 0             ; 0 means "/"

; ---- state -----------------------------------------------------------
fp_curdir   .fill 64
fp_full     .fill 64
fp_nm       .fill 40
fp_nent     .byte 0
fp_sel      .byte 0
fp_top      .byte 0
fp_down     .byte 0
fp_lastck   .word 0
fp_lastidx  .byte 255
fp_rows     .byte 40
fp_left     .byte 6
fp_wide     .byte 68
fp_scrw     .byte 80
fp_scrh     .byte 60
fp_bankwas  .byte 0
fp_saved    .byte 0
fp_pass     .byte 0
fp_act      .byte 0
fp_key      .byte 0
fp_row      .byte 0
fp_idx      .byte 0
fp_attr     .byte 0
fp_cnt      .byte 0
fp_tmp      .byte 0
fp_tmp2     .byte 0
fp_kind     .byte 0         ; an entry's type, which filepick_ent must not eat
fp_src      .word 0             ; scratch pointers, kept out of the ZP
fp_dst      .word 0             ; block so a library call cannot eat them
fp_pat      .word 0
fp_ptr      .word 0

filepick_root
    .text "/", 0
filepick_headdef
    .text "files in ", 0
filepick_alldef
    .text "*.*", 0
filepick_footdef
    .text "double click opens   esc closes", 0
filepick_dirtag
    .text "[dir] ", 0
filepick_dattag
    .text "[dat] ", 0
filepick_blanktag
    .text "      ", 0
filepick_closebox
    .text " x ", 0
filepick_dotdot
    .text "..", 0

; =====================================================================
; configuration
; =====================================================================

; ---------------------------------------------------------------------
; fp_cache -- where the listing is held
;   in: X16_P0/P1 = VRAM address (low 16 bits), X16_P2 = bit 16
;
; 2,560 bytes of VRAM, not RAM: a banked filepick runs from the $A000
; window, so reaching its own data through a RAM bank would page its own
; code away. The default is $12000, clear of the text map at $1B000.
; ---------------------------------------------------------------------
fp_cache
    lda X16_P0
    sta fp_vram
    lda X16_P1
    sta fp_vram+1
    lda X16_P2
    and #$01
    sta fp_vramh
    rts

; ---------------------------------------------------------------------
; fp_filter -- which files to list, as a ';' list of "*filepick_ext" patterns
;   in: X16_P0/P1 = the pattern string, NUL-terminated
; ---------------------------------------------------------------------
fp_filter
    lda X16_P0
    sta fp_filt
    lda X16_P1
    sta fp_filt+1
    rts

; ---------------------------------------------------------------------
; fp_primary -- which of the listed files the caller can act on itself
;   in: X16_P0/P1 = the pattern string, NUL-terminated
;
; Anything listed that does NOT match is marked [dat] in the panel, and
; fp_is_primary reports which kind was chosen.
; ---------------------------------------------------------------------
fp_primary
    lda X16_P0
    sta fp_prim
    lda X16_P1
    sta fp_prim+1
    rts

; ---------------------------------------------------------------------
; fp_style -- the panel's colours
;   in: A = panel, X = header/footer, Y = the selected row
; ---------------------------------------------------------------------
fp_style
    sta fp_apanel
    stx fp_abar
    sty fp_asel
    rts

; ---------------------------------------------------------------------
; fp_heading -- the text in front of the path on the header row
;   in: X16_P0/P1 = the string, NUL-terminated
; ---------------------------------------------------------------------
fp_heading
    lda X16_P0
    sta fp_head
    lda X16_P1
    sta fp_head+1
    rts

; ---------------------------------------------------------------------
; fp_footing -- the reminder along the bottom of the panel
;   in: X16_P0/P1 = the string, NUL-terminated
; ---------------------------------------------------------------------
fp_footing
    lda X16_P0
    sta fp_foot
    lda X16_P1
    sta fp_foot+1
    rts

; ---------------------------------------------------------------------
; fp_saveunder -- keep what the panel covers, and put it back on close
;   in: A = 0 for none, non-zero to keep it
;       X16_P0/P1 = VRAM address (low 16 bits), X16_P2 = bit 16
;
; The text map is VRAM, so its copy lives in VRAM too: 5,712 bytes at 80
; columns, $14000 by default. A launcher that repaints itself does not
; need this; a spreadsheet does.
; ---------------------------------------------------------------------
fp_saveunder
    sta fp_undon
    beq filepick_sv_off
    lda X16_P0
    sta fp_under
    lda X16_P1
    sta fp_under+1
    lda X16_P2
    and #$01
    sta fp_underh
filepick_sv_off
    rts

; ---------------------------------------------------------------------
; fp_charset -- the charset the panel is drawn in (3 = PET upper/lower)
;   in: A = charset number, or 255 to leave whatever the caller had
;
; There is no way to ask the KERNAL which charset is loaded, so the
; browser cannot put back what it does not know: a caller using the
; graphics set should pass 255 and draw its own.
; ---------------------------------------------------------------------
fp_charset
    sta fp_chset
    rts

; ---------------------------------------------------------------------
; fp_start_dir -- where the browser opens
;   in: X16_P0/P1 = the path, NUL-terminated (the default is "/")
; ---------------------------------------------------------------------
fp_start_dir
    lda X16_P0
    sta fp_startat
    lda X16_P1
    sta fp_startat+1
    rts

; =====================================================================
; what the caller reads back
; =====================================================================

; ---------------------------------------------------------------------
; fp_path -- the absolute path of the chosen entry
;   out: X/Y = a pointer to it, NUL-terminated
;
; ONLY SAFE UNBANKED. This module's storage moves with the module: put
; it in a RAM bank with -Bank and the pointer names an address in a bank
; that is no longer mapped by the time the caller reads it. The caller
; sees whatever is in the window instead -- an empty string, if it is a
; freshly cleared bank, which is how a perfectly good file arrived at
; the drive with no name at all.
;
; Use fp_copy_path / fp_copy_name / fp_copy_dir instead: they run with
; the module's bank paged in and copy into the CALLER's memory.
; ---------------------------------------------------------------------
fp_path
    ldx #<fp_full
    ldy #>fp_full
    rts

; ---------------------------------------------------------------------
; fp_name -- the chosen entry's name, without the directory
;   out: X/Y = a pointer into the path, NUL-terminated
; ---------------------------------------------------------------------
fp_name
    lda #<fp_full
    sta fp_ptr
    lda #>fp_full
    sta fp_ptr+1
    ldy #0
filepick_nm_scan
    lda fp_full,y
    beq filepick_nm_done
    cmp #'/'
    bne filepick_nm_next
    ; the character after this slash starts the name
    tya
    sec
    adc #<fp_full               ; sec: +1 as well, for the slash itself
    sta fp_ptr
    lda #>fp_full
    adc #0
    sta fp_ptr+1
filepick_nm_next
    iny
    bne filepick_nm_scan
filepick_nm_done
    ldx fp_ptr
    ldy fp_ptr+1
    rts

; ---------------------------------------------------------------------
; fp_dir -- the directory being browsed, which is where the drive is
;           left standing
;   out: X/Y = a pointer to it, NUL-terminated
; ---------------------------------------------------------------------
fp_dir
    ldx #<fp_curdir
    ldy #>fp_curdir
    rts

; ---------------------------------------------------------------------
; fp_copy_path -- the absolute path, copied into the caller's memory
;   in:  X16_P0/P1 = destination, X16_P2 = its size (the NUL included)
;   out: A = how many characters were copied, terminator aside
;
; This is the one to use from a BANKED filepick: the copy happens with
; the module's bank paged in, and lands somewhere the caller can still
; read afterwards.
; ---------------------------------------------------------------------
fp_copy_path
    lda #<fp_full
    sta fp_src
    lda #>fp_full
    sta fp_src+1
    bra filepick_copy_out

; ---------------------------------------------------------------------
; fp_copy_name -- just the name, without the directory
;   in:  X16_P0/P1 = destination, X16_P2 = its size
;   out: A = how many characters were copied
; ---------------------------------------------------------------------
fp_copy_name
    jsr fp_name
    stx fp_src
    sty fp_src+1
    bra filepick_copy_out

; ---------------------------------------------------------------------
; fp_copy_dir -- the directory being browsed, which is where the drive
;                was left standing
;   in:  X16_P0/P1 = destination, X16_P2 = its size
;   out: A = how many characters were copied
; ---------------------------------------------------------------------
fp_copy_dir
    lda #<fp_curdir
    sta fp_src
    lda #>fp_curdir
    sta fp_src+1
filepick_copy_out
    lda X16_P0
    sta fp_dst
    lda X16_P1
    sta fp_dst+1
    lda X16_P2
    beq filepick_co_none
    dec a  ; leave room for the terminator
    jsr filepick_put_str
    tya                         ; filepick_put_str leaves Y = the length
    rts
filepick_co_none
    lda #0
    rts

; ---------------------------------------------------------------------
; fp_is_primary -- is the chosen entry one the caller can act on?
;   out: carry set when it matches the primary pattern
; ---------------------------------------------------------------------
fp_is_primary
    jsr fp_name
    stx X16_P0
    sty X16_P1
    jsr filepick_primpat
    sta X16_P2
    stx X16_P3
    jmp fp_match

; ---------------------------------------------------------------------
; fp_panel_top / fp_panel_left / fp_panel_width / fp_panel_rows
;   out: A = the panel's geometry, for a caller drawing inside it
;
; Valid once fp_open has run: the panel is sized to the screen it finds.
; ---------------------------------------------------------------------
fp_panel_top
    lda #FPK_PTOP
    rts

fp_panel_left
    lda fp_left
    rts

fp_panel_width
    lda fp_wide
    rts

fp_panel_rows
    lda fp_rows
    rts

; =====================================================================
; matching
; =====================================================================

; ---------------------------------------------------------------------
; fp_match -- does a name match a ';' list of patterns?
;   in:  X16_P0/P1 = the name, X16_P2/P3 = the pattern list
;   out: carry set when it matches
;
; A pattern list is "*filepick_prg", or "*filepick_bmx;*filepick_png", or "*.*" for anything.
; A pattern pointer of $0000 matches everything, which is what an unset
; filter means.
; ---------------------------------------------------------------------
fp_match
    lda X16_P2
    ora X16_P3
    bne filepick_m_have
    sec                         ; no pattern: everything matches
    rts
filepick_m_have
    lda X16_P2
    sta fp_pat
    lda X16_P3
    sta fp_pat+1
filepick_m_loop
    lda fp_pat
    sta X16_T0
    lda fp_pat+1
    sta X16_T1
    ldy #0
    lda (X16_T0),y
    beq filepick_m_no                   ; end of the list, nothing matched
    jsr filepick_match_one
    bcs filepick_m_yes
    ; step past this pattern to the one after the ';'
filepick_m_skip
    lda fp_pat
    sta X16_T0
    lda fp_pat+1
    sta X16_T1
    ldy #0
    lda (X16_T0),y
    beq filepick_m_no
    cmp #';'
    beq filepick_m_next
    inc fp_pat
    bne filepick_m_skip
    inc fp_pat+1
    bra filepick_m_skip
filepick_m_next
    inc fp_pat
    bne filepick_m_loop
    inc fp_pat+1
    bra filepick_m_loop
filepick_m_yes
    sec
    rts
filepick_m_no
    clc
    rts

; One pattern, at fp_pat, against the name in X16_P0/P1.
;   out: carry set when it matches
filepick_match_one
    lda fp_pat
    sta X16_T0
    lda fp_pat+1
    sta X16_T1
    ldy #0
    lda (X16_T0),y
    cmp #'*'
    beq filepick_mo_star
    clc                         ; only "*..." patterns are understood
    rts
filepick_mo_star
    ldy #1
    lda (X16_T0),y
    bne filepick_hop1   ; "*"
    jmp filepick_mo_all
filepick_hop1
    cmp #';'
    bne filepick_hop2   ; "*;..."
    jmp filepick_mo_all
filepick_hop2
    cmp #'.'
    beq filepick_hop3
    jmp filepick_mo_bad
filepick_hop3
    ldy #2
    lda (X16_T0),y
    cmp #'*'
    bne filepick_hop4   ; "*.*"
    jmp filepick_mo_all
filepick_hop4
    ; "*filepick_ext": measure the extension, up to the next ';'
    lda fp_pat
    clc
    adc #2
    sta fp_src
    lda fp_pat+1
    adc #0
    sta fp_src+1
    ldy #0
filepick_mo_extlen
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    lda (X16_T0),y
    beq filepick_mo_gotext
    cmp #';'
    beq filepick_mo_gotext
    iny
    bne filepick_mo_extlen
filepick_mo_gotext
    cpy #0
    beq filepick_mo_bad                 ; "*." on its own is not a pattern
    sty fp_cnt                  ; the extension's length

    ; the name's length
    lda X16_P0
    sta X16_T0
    lda X16_P1
    sta X16_T1
    ldy #0
filepick_mo_namelen
    lda (X16_T0),y
    beq filepick_mo_gotname
    iny
    bne filepick_mo_namelen
filepick_mo_gotname
    cpy fp_cnt                  ; a name has to be longer than "filepick_ext"
    bcc filepick_mo_bad
    beq filepick_mo_bad
    tya
    sec
    sbc fp_cnt                  ; where the tail starts
    sta fp_tmp
    ; the character before the tail must be the dot
    tay
    dey
    lda (X16_T0),y
    cmp #'.'
    bne filepick_mo_bad
    ; compare, folding case
    ldy #0
filepick_mo_cmp
    cpy fp_cnt
    beq filepick_mo_all
    lda X16_P0
    sta X16_T0
    lda X16_P1
    sta X16_T1
    tya
    clc
    adc fp_tmp
    tax                         ; index of this tail character
    txa
    tay
    lda (X16_T0),y
    jsr filepick_fold
    sta fp_tmp2
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    txa
    sec
    sbc fp_tmp
    tay
    lda (X16_T0),y
    jsr filepick_fold
    cmp fp_tmp2
    bne filepick_mo_bad
    iny
    bne filepick_mo_cmp
filepick_mo_all
    sec
    rts
filepick_mo_bad
    clc
    rts

; A -> the same letter with bit 5 clear, whichever case it arrived in
filepick_fold
    cmp #$41
    bcc filepick_fd_out
    cmp #$5B
    bcc filepick_fd_do
    cmp #$61
    bcc filepick_fd_out
    cmp #$7B
    bcs filepick_fd_out
filepick_fd_do
    and #$DF
filepick_fd_out
    rts

; -> A/X = the primary pattern, falling back to the filter, then to "*.*"
filepick_primpat
    lda fp_prim
    ora fp_prim+1
    beq filepick_pp_filt
    lda fp_prim
    ldx fp_prim+1
    rts
filepick_pp_filt
    lda fp_filt
    ora fp_filt+1
    beq filepick_pp_all
    lda fp_filt
    ldx fp_filt+1
    rts
filepick_pp_all
    lda #<filepick_alldef
    ldx #>filepick_alldef
    rts

; -> A/X = the filter, or "*.*"
filepick_filtpat
    lda fp_filt
    ora fp_filt+1
    beq filepick_fp_all
    lda fp_filt
    ldx fp_filt+1
    rts
filepick_fp_all
    lda #<filepick_alldef
    ldx #>filepick_alldef
    rts

; =====================================================================
; small helpers
; =====================================================================

; X16_P0/P1 = string -> Y = its length, terminator aside
filepick_zlen
    lda X16_P0
    sta X16_T0
    lda X16_P1
    sta X16_T1
    ldy #0
filepick_zl_loop
    lda (X16_T0),y
    beq filepick_zl_done
    iny
    bne filepick_zl_loop
filepick_zl_done
    rts

; fp_src -> fp_dst, at most A characters, always terminated
filepick_put_str
    sta fp_cnt
    ldy #0
filepick_ps_loop
    cpy fp_cnt
    beq filepick_ps_end
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    lda (X16_T0),y
    beq filepick_ps_end
    pha
    lda fp_dst
    sta X16_T0
    lda fp_dst+1
    sta X16_T1
    pla
    sta (X16_T0),y
    iny
    bne filepick_ps_loop
filepick_ps_end
    lda fp_dst
    sta X16_T0
    lda fp_dst+1
    sta X16_T1
    lda #0
    sta (X16_T0),y
    rts

; A = entry index: point VERA port 0 at that entry in the cache.
;
; The cache is in VRAM rather than in a RAM bank, and that is not a
; detail: a BANKED filepick runs from the $A000 window itself, so paging
; a bank in to reach its own data would page its own code away. VRAM is
; reachable from anywhere.
filepick_ent
    sta fp_tmp
    stz fp_ptr
    stz fp_ptr+1
    lda fp_tmp                  ; index * 40 = index*32 + index*8
    sta fp_ptr
    asl fp_ptr                  ; *2
    rol fp_ptr+1
    asl fp_ptr                  ; *4
    rol fp_ptr+1
    asl fp_ptr                  ; *8
    rol fp_ptr+1
    lda fp_ptr
    sta fp_tmp2                 ; keep index*8
    lda fp_ptr+1
    sta fp_cnt
    asl fp_ptr                  ; *16
    rol fp_ptr+1
    asl fp_ptr                  ; *32
    rol fp_ptr+1
    clc
    lda fp_ptr
    adc fp_tmp2
    sta fp_ptr
    lda fp_ptr+1
    adc fp_cnt
    sta fp_ptr+1
    clc                         ; + the cache's own address
    lda fp_ptr
    adc fp_vram
    sta fp_ptr
    lda fp_ptr+1
    adc fp_vram+1
    sta fp_ptr+1
    ; fall through: point port 0 at fp_ptr, stepping by one
filepick_point0
    stz VERA_CTRL               ; ADDRSEL 0
    lda fp_ptr
    sta VERA_ADDR_L
    lda fp_ptr+1
    sta VERA_ADDR_M
    lda fp_vramh
    and #$01
    ora #$10                    ; increment 1
    sta VERA_ADDR_H
    rts

; A = entry index: point port 0 at that entry's NAME
filepick_ent_name
    jsr filepick_ent
    clc
    lda fp_ptr
    adc #FPK_ENAME
    sta fp_ptr
    lda fp_ptr+1
    adc #0
    sta fp_ptr+1
    jmp filepick_point0

; A = entry index -> A = its type, port 0 left just past it
filepick_ent_type
    jsr filepick_ent
    lda VERA_DATA0
    rts

; A = entry index: copy its name out of VRAM into fp_nm, so the rest of
; the code can treat it as an ordinary string.
filepick_ent_fetch
    jsr filepick_ent_name
    ldy #0
filepick_ef_loop
    lda VERA_DATA0
    sta fp_nm,y
    beq filepick_ef_done
    iny
    cpy #FPK_ESIZE-2
    bne filepick_ef_loop
    lda #0
    sta fp_nm,y
filepick_ef_done
    rts

; =====================================================================
; the listing
; =====================================================================

; Read the current directory into the cache: directories first, then
; whatever the primary pattern matches, then the rest. Three passes over
; the listing rather than a sort.
filepick_read
    stz fp_nent
    stz fp_pass
filepick_rd_pass
    stz X16_P0                  ; dir_open with no name: "$"
    stz X16_P1
    stz X16_P2
    lda #8
    sta X16_P3
    jsr dir_open
    bcc filepick_hop5
    jmp filepick_rd_done
filepick_hop5
filepick_rd_next
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    lda #40
    sta X16_P2
    jsr dir_next
    bcs filepick_hop6
    jmp filepick_rd_close
filepick_hop6
    jsr dir_type
    sta fp_tmp                  ; the type the drive reported
    ; Not files. The header line is a path on an emulator's host
    ; filesystem (HOST) and the volume label on a real card (NONE, with
    ; raw directory bytes in the name), and the "BLOCKS FREE." trailer
    ; is NONE as well: listing either put rubbish in the panel.
    cmp #DIR_TYPE_NONE
    beq filepick_rd_next
    cmp #DIR_TYPE_HOST
    beq filepick_rd_next
    lda fp_nent
    cmp #FPK_MAXENT
    bcs filepick_rd_next                ; the cache is full
    ; which pass wants this one?
    lda fp_tmp
    cmp #DIR_TYPE_DIR
    bne filepick_rd_file
    lda fp_pass
    bne filepick_rd_next                ; directories belong to pass 0
    lda fp_nm                   ; "." leads nowhere
    cmp #'.'
    bne filepick_rd_keep_dir
    lda fp_nm+1
    beq filepick_rd_next
filepick_rd_keep_dir
    lda #DIR_TYPE_DIR
    sta fp_kind
    bra filepick_rd_store
filepick_rd_file
    lda fp_pass
    beq filepick_rd_next                ; files are passes 1 and 2
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr filepick_filtpat
    sta X16_P2
    stx X16_P3
    jsr fp_match
    bcc filepick_rd_next                ; not ours to show at all
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr filepick_primpat
    sta X16_P2
    stx X16_P3
    jsr fp_match
    ; The carry says primary -- and the cmp below would destroy it, so
    ; put it somewhere that survives asking which pass this is. Without
    ; this the pass test read its own comparison's carry, every file
    ; came out primary, and nothing was ever marked [dat].
    lda #0
    rol                         ; 1 = primary, 0 = data
    sta fp_cnt
    lda fp_pass
    cmp #1
    bne filepick_rd_datapass
    lda fp_cnt                  ; pass 1 keeps the primaries
    bne filepick_rd_isprim
    jmp filepick_rd_next
filepick_rd_isprim
    lda #DIR_TYPE_PRG
    sta fp_kind
    bra filepick_rd_store
filepick_rd_datapass
    lda fp_cnt                  ; pass 2 keeps everything else
    beq filepick_rd_isdata
    jmp filepick_rd_next
filepick_rd_isdata
    lda #DIR_TYPE_SEQ
    sta fp_kind
filepick_rd_store
    lda fp_nent
    jsr filepick_ent                    ; port 0 at the entry, stepping by one
    lda fp_kind
    sta VERA_DATA0              ; the type
    ldy #0                      ; ...then the name, terminator included
filepick_rd_name
    lda fp_nm,y
    sta VERA_DATA0
    beq filepick_rd_named
    iny
    cpy #FPK_ESIZE-2
    bne filepick_rd_name
    lda #0
    sta VERA_DATA0
filepick_rd_named
    inc fp_nent
    jmp filepick_rd_next
filepick_rd_close
    jsr dir_close
    inc fp_pass
    lda fp_pass
    cmp #3
    bcs filepick_hop8
    jmp filepick_rd_pass
filepick_hop8
filepick_rd_done
    rts

; fp_curdir + "/" + the name at X16_P0/P1 -> fp_full
filepick_make_path
    lda X16_P0
    sta fp_src
    lda X16_P1
    sta fp_src+1
    ldy #0
filepick_mp_dir
    lda fp_curdir,y
    beq filepick_mp_slash
    sta fp_full,y
    iny
    cpy #40
    bne filepick_mp_dir
filepick_mp_slash
    cpy #0
    beq filepick_mp_name
    dey
    lda fp_full,y
    iny
    cmp #'/'
    beq filepick_mp_name
    lda #'/'
    sta fp_full,y
    iny
filepick_mp_name
    sty fp_tmp                  ; where the name goes
    ldx #0
filepick_mp_copy
    txa
    tay
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    lda (X16_T0),y
    beq filepick_mp_end
    ldy fp_tmp
    sta fp_full,y
    inc fp_tmp
    lda fp_tmp
    cmp #63
    bcs filepick_mp_end
    inx
    bne filepick_mp_copy
filepick_mp_end
    ldy fp_tmp
    lda #0
    sta fp_full,y
    rts

; Where we are, kept by hand: ".." trims the last component, anything
; else appends one. The drive is not asked, because it answers with a
; volume label on a card and a path on an emulator.
filepick_descend
    lda X16_P0
    sta fp_src
    lda X16_P1
    sta fp_src+1
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    ldy #0
    lda (X16_T0),y
    cmp #'.'
    bne filepick_ds_append
    iny
    lda (X16_T0),y
    cmp #'.'
    bne filepick_ds_append
    iny
    lda (X16_T0),y
    bne filepick_ds_append
    ; ".." -- back up over the last component
    ldy #0
filepick_ds_len
    lda fp_curdir,y
    beq filepick_ds_gotlen
    iny
    bne filepick_ds_len
filepick_ds_gotlen
    cpy #2
    bcc filepick_ds_root
filepick_ds_back
    dey
    beq filepick_ds_root
    lda fp_curdir,y
    cmp #'/'
    bne filepick_ds_back
    cpy #0
    bne filepick_ds_cut
filepick_ds_root
    lda #'/'
    sta fp_curdir
    lda #0
    sta fp_curdir+1
    rts
filepick_ds_cut
    lda #0
    sta fp_curdir,y
    rts
filepick_ds_append
    ldy #0
filepick_ds_alen
    lda fp_curdir,y
    beq filepick_ds_agot
    iny
    bne filepick_ds_alen
filepick_ds_agot
    cpy #0
    beq filepick_ds_acopy
    dey
    lda fp_curdir,y
    iny
    cmp #'/'
    beq filepick_ds_acopy
    lda #'/'
    sta fp_curdir,y
    iny
filepick_ds_acopy
    sty fp_tmp
    ldx #0
filepick_ds_aloop
    txa
    tay
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    lda (X16_T0),y
    beq filepick_ds_aend
    ldy fp_tmp
    sta fp_curdir,y
    inc fp_tmp
    lda fp_tmp
    cmp #63
    bcs filepick_ds_aend
    inx
    bne filepick_ds_aloop
filepick_ds_aend
    ldy fp_tmp
    lda #0
    sta fp_curdir,y
    rts

; =====================================================================
; the panel
; =====================================================================
filepick_layout
    jsr screen_get_mode
    cmp #0
    bne filepick_ly_small
    lda #80
    sta fp_scrw
    lda #60
    sta fp_scrh
    lda #40
    sta fp_rows
    lda #6
    sta fp_left
    lda #68
    sta fp_wide
    rts
filepick_ly_small
    lda #40
    sta fp_scrw
    lda #30
    sta fp_scrh
    lda #22
    sta fp_rows
    lda #1
    sta fp_left
    lda #38
    sta fp_wide
    rts

; A = row, X = colour: fill one row of the panel
filepick_prow
    pha
    phx
    tax                         ; screen_addr wants X = row, Y = column
    ldy fp_left
    jsr screen_addr
    plx                         ; colour
    lda fp_wide
    ldy #' '
    jsr screen_blitfill
    pla
    rts

; X16_P0/P1 = text, A = colour, X = row, Y = column: blit a NUL string
filepick_blitz
    sta fp_attr
    pha
    phy
    txa
    tax
    ply
    jsr screen_addr
    pla
    jsr filepick_zlen                   ; Y = length
    cpy #0
    beq filepick_bz_done
    tya
    ldx fp_attr
    jsr screen_blit
filepick_bz_done
    rts

filepick_draw
    ; ---- the header row ------------------------------------------
    lda #FPK_PTOP
    ldx fp_abar
    jsr filepick_prow
    lda fp_head
    ora fp_head+1
    bne filepick_dw_head
    lda #<filepick_headdef
    sta X16_P0
    lda #>filepick_headdef
    sta X16_P1
    bra filepick_dw_headgo
filepick_dw_head
    lda fp_head
    sta X16_P0
    lda fp_head+1
    sta X16_P1
filepick_dw_headgo
    ldx #FPK_PTOP
    ldy fp_left
    iny
    jsr screen_addr
    jsr filepick_zlen
    cpy #0
    beq filepick_dw_path
    tya
    ldx fp_abar
    jsr screen_blit
filepick_dw_path
    lda #<fp_curdir
    sta X16_P0
    lda #>fp_curdir
    sta X16_P1
    jsr filepick_zlen
    tya
    ; a deep path must not run off the bar
    sta fp_tmp
    lda fp_wide
    sec
    sbc #14
    cmp fp_tmp
    bcs filepick_dw_pathlen
    sta fp_tmp
filepick_dw_pathlen
    lda fp_tmp
    beq filepick_dw_close
    ldx fp_abar
    jsr screen_blit
filepick_dw_close
    ldx #FPK_PTOP
    lda fp_left
    clc
    adc fp_wide
    sec
    sbc #3
    tay
    jsr screen_addr
    lda #<filepick_closebox
    sta X16_P0
    lda #>filepick_closebox
    sta X16_P1
    lda #3
    ldx #$F2                    ; red on light grey: click to close
    jsr screen_blit

    ; ---- the rows -------------------------------------------------
    stz fp_row
filepick_dw_row
    lda fp_row
    cmp fp_rows
    bcc filepick_hop9
    jmp filepick_dw_foot
filepick_hop9
    clc
    adc fp_top
    sta fp_idx
    ldx fp_apanel
    cmp fp_sel
    bne filepick_dw_attr
    ldx fp_asel
filepick_dw_attr
    stx fp_attr
    lda fp_row
    clc
    adc #FPK_PTOP+1
    ldx fp_attr
    jsr filepick_prow
    lda fp_idx
    cmp fp_nent
    bcs filepick_dw_next
    ; Read the entry out of VRAM FIRST. The cache and the screen are
    ; both reached through VERA port 0, and screen_addr points it at the
    ; screen -- fetching a name after that wrote the row into the cache
    ; instead of onto the display, and left the panel blank.
    lda fp_idx
    jsr filepick_ent_type
    sta fp_kind                 ; filepick_ent uses fp_tmp2 itself
    lda fp_idx
    jsr filepick_ent_fetch              ; the name, into fp_nm
    lda fp_row
    clc
    adc #FPK_PTOP+1
    tax
    lda fp_left
    clc
    adc #2
    tay
    jsr screen_addr
    lda fp_kind
    cmp #DIR_TYPE_DIR
    bne filepick_dw_notdir
    lda #<filepick_dirtag
    ldx #>filepick_dirtag
    bra filepick_dw_tag
filepick_dw_notdir
    cmp #DIR_TYPE_SEQ
    bne filepick_dw_blanktag
    lda #<filepick_dattag
    ldx #>filepick_dattag
    bra filepick_dw_tag
filepick_dw_blanktag
    lda #<filepick_blanktag
    ldx #>filepick_blanktag
filepick_dw_tag
    sta X16_P0
    stx X16_P1
    lda #6
    ldx fp_attr
    jsr screen_blit
    ; the name, clamped: a row that runs over wraps around the screen
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr filepick_zlen
    tya
    sta fp_tmp
    lda fp_wide
    sec
    sbc #10
    cmp fp_tmp
    bcs filepick_dw_namelen
    sta fp_tmp
filepick_dw_namelen
    lda fp_tmp
    beq filepick_dw_next
    ldx fp_attr
    jsr screen_blit
filepick_dw_next
    inc fp_row
    jmp filepick_dw_row

    ; ---- the footer ------------------------------------------------
filepick_dw_foot
    lda fp_rows
    clc
    adc #FPK_PTOP+1
    ldx fp_abar
    jsr filepick_prow
    lda fp_foot
    ora fp_foot+1
    bne filepick_dw_footset
    lda #<filepick_footdef
    sta X16_P0
    lda #>filepick_footdef
    sta X16_P1
    bra filepick_dw_footgo
filepick_dw_footset
    lda fp_foot
    sta X16_P0
    lda fp_foot+1
    sta X16_P1
filepick_dw_footgo
    lda fp_rows
    clc
    adc #FPK_PTOP+1
    tax
    lda fp_left
    clc
    adc #1
    tay
    jsr screen_addr
    jsr filepick_zlen
    cpy #0
    beq filepick_dw_end
    tya
    sta fp_tmp
    lda fp_wide
    sec
    sbc #2
    cmp fp_tmp
    bcs filepick_dw_footlen
    sta fp_tmp
filepick_dw_footlen
    lda fp_tmp
    ldx fp_abar
    jsr screen_blit
filepick_dw_end
    rts

; A = the key: move the selection
filepick_move
    cmp #$91                    ; up
    bne filepick_mv_down
    lda fp_sel
    beq filepick_mv_clamp
    dec fp_sel
    bra filepick_mv_clamp
filepick_mv_down
    cmp #$11
    bne filepick_mv_home
    lda fp_sel
    clc
    adc #1
    cmp fp_nent
    bcs filepick_mv_clamp
    inc fp_sel
    bra filepick_mv_clamp
filepick_mv_home
    cmp #$13
    bne filepick_mv_clamp
    stz fp_sel
filepick_mv_clamp
    lda fp_sel                  ; scrolled off the top?
    cmp fp_top
    bcs filepick_mv_bottom
    sta fp_top
filepick_mv_bottom
    lda fp_top                  ; ...or off the bottom?
    clc
    adc fp_rows
    cmp fp_sel
    beq filepick_mv_scroll
    bcs filepick_mv_out
filepick_mv_scroll
    lda fp_sel
    sec
    sbc fp_rows
    clc
    adc #1
    sta fp_top
filepick_mv_out
    rts

; =====================================================================
; save-under
;
; The text map IS VRAM, so keeping a copy of it somewhere else in VRAM
; costs nothing but the space: port 0 walks the screen, port 1 walks the
; scratch, and the bytes go across one at a time. A RAM bank would have
; been the obvious place and is the wrong one -- a banked filepick runs
; from the $A000 window, and paging a bank in there would page its own
; code out mid-copy.
;
; Two bytes per cell, (rows + 2) rows of the panel's width: 5,712 bytes
; at 80 columns.
; =====================================================================

; A = row: point port 1 at that row's copy in the scratch area
filepick_under_addr
    sta fp_tmp
    stz fp_dst
    stz fp_dst+1
    lda fp_tmp
    beq filepick_ua_have
    ldx fp_tmp
filepick_ua_loop
    clc
    lda fp_dst
    adc fp_wide
    sta fp_dst
    lda fp_dst+1
    adc #0
    sta fp_dst+1
    dex
    bne filepick_ua_loop
filepick_ua_have
    asl fp_dst                  ; two bytes per cell
    rol fp_dst+1
    clc
    lda fp_dst
    adc fp_under
    sta fp_dst
    lda fp_dst+1
    adc fp_under+1
    sta fp_dst+1
    lda #1
    sta VERA_CTRL               ; ADDRSEL 1
    lda fp_dst
    sta VERA_ADDR_L
    lda fp_dst+1
    sta VERA_ADDR_M
    lda fp_underh
    and #$01
    ora #$10                    ; increment 1
    sta VERA_ADDR_H
    stz VERA_CTRL               ; back to port 0 for the caller
    rts

filepick_save_under
    lda fp_undon
    bne filepick_su_go1
    rts
filepick_su_go1
    stz fp_row
filepick_su_row
    lda fp_row
    cmp fp_rows
    bcc filepick_su_go
    beq filepick_su_go
    sec                         ; rows + 2: the header and the footer
    sbc fp_rows
    cmp #2
    bcc filepick_su_go
    lda #1
    sta fp_saved
    rts
filepick_su_go
    lda fp_row
    clc
    adc #FPK_PTOP
    tax
    ldy fp_left
    jsr screen_addr             ; port 0 at the screen row
    lda fp_row
    jsr filepick_under_addr             ; port 1 at its copy
    lda fp_wide
    asl                         ; two bytes per cell
    sta fp_cnt
filepick_su_cell
    lda VERA_DATA0
    sta VERA_DATA1
    dec fp_cnt
    bne filepick_su_cell
    inc fp_row
    bra filepick_su_row

filepick_restore_under
    lda fp_undon
    bne filepick_ru_go1
    rts
filepick_ru_go1
    lda fp_saved
    bne filepick_ru_go2
    rts
filepick_ru_go2
    stz fp_row
filepick_ru_row
    lda fp_row
    cmp fp_rows
    bcc filepick_ru_go
    beq filepick_ru_go
    sec
    sbc fp_rows
    cmp #2
    bcc filepick_ru_go
    stz fp_saved
    rts
filepick_ru_go
    lda fp_row
    clc
    adc #FPK_PTOP
    tax
    ldy fp_left
    jsr screen_addr
    lda fp_row
    jsr filepick_under_addr
    lda fp_wide
    asl
    sta fp_cnt
filepick_ru_cell
    lda VERA_DATA1
    sta VERA_DATA0
    dec fp_cnt
    bne filepick_ru_cell
    inc fp_row
    bra filepick_ru_row

; =====================================================================
; opening, closing, and the loop between
; =====================================================================

; ---------------------------------------------------------------------
; fp_open -- put the panel up on the starting directory
;   out: A = FPK_NONE (cancelled), FPK_PICK (a file), FPK_ALT (the
;        second gesture on a file: right click, or 'a'), FPK_HERE ('h':
;        the directory being shown, for "save into...")
;
; FPK_HERE is for a caller that wants a PLACE rather than a file. The
; drive is left standing in that directory whatever the answer, so a
; bare filename written afterwards lands there and fp_copy_dir names it.
; Without it ESC has to double as "use this one", and then there is no
; way left to mean "cancel".
;
; The chosen path is fp_path either way it ended on a file. Call
; fp_close when done with it -- that is what puts back the screen and
; the caller's RAM bank.
; ---------------------------------------------------------------------
fp_open
    jsr filepick_layout
    stz fp_saved
    lda fp_startat
    ora fp_startat+1
    bne filepick_op_start
    lda #<filepick_root
    sta X16_P0
    lda #>filepick_root
    sta X16_P1
    bra filepick_op_setdir
filepick_op_start
    lda fp_startat
    sta X16_P0
    lda fp_startat+1
    sta X16_P1
filepick_op_setdir
    lda X16_P0
    sta fp_src
    lda X16_P1
    sta fp_src+1
    lda #<fp_curdir
    sta fp_dst
    lda #>fp_curdir
    sta fp_dst+1
    lda #63
    jsr filepick_put_str
    lda fp_src                  ; and take the drive there
    sta X16_P0
    lda fp_src+1
    sta X16_P1
    jsr filepick_zlen                   ; Y = length
    lda X16_P0                  ; dos_chdir wants A/X = name, Y = length
    ldx X16_P1
    jsr dos_chdir
    stz fp_sel
    stz fp_top
    lda #255
    sta fp_lastidx
    lda fp_chset
    cmp #255
    beq filepick_op_nochar
    jsr screen_charset
filepick_op_nochar
    jsr filepick_save_under
    jsr filepick_read
    lda #1                      ; the pointer, with the panel's bounds
    ldx fp_scrw
    ldy fp_scrh
    jsr mse_config
    lda #1                      ; the click that opened us may still be held
    sta fp_down
    jmp filepick_loop

; ---------------------------------------------------------------------
; fp_resume -- the same panel again, same directory, same selection
;   out: A = as fp_open
;
; For a caller that acted on an FPK_ALT and wants the browser back.
; ---------------------------------------------------------------------
fp_resume
    lda #1
    ldx fp_scrw
    ldy fp_scrh
    jsr mse_config
    lda #1
    sta fp_down
    jmp filepick_loop

; ---------------------------------------------------------------------
; fp_close -- put back what the panel covered and the caller's RAM bank
;
; The DRIVE is left in the directory that was being browsed: a caller
; that needs to be somewhere else should say so with dos_chdir.
; ---------------------------------------------------------------------
fp_close
    jsr filepick_restore_under
    jmp mse_hide

; ---------------------------------------------------------------------
; fp_redraw -- paint the panel again, after a caller has drawn over it
; ---------------------------------------------------------------------
fp_redraw
    jmp filepick_draw

filepick_loop
    jsr filepick_draw
filepick_lp_input
    stz fp_key
    stz fp_act
filepick_lp_poll
    jsr key_get
    sta fp_key
    beq filepick_hop10
    ; The KERNAL answers in PETSCII, where an unshifted letter is $41-$5A
    ; -- the codes ASCII uses for CAPITALS -- and a shifted one is
    ; $C1-$DA. ACME's 'n' is $6E, which the keyboard never sends, so
    ; every letter command in here was dead until this fold.
    cmp #$C1
    bcc filepick_kf_done
    cmp #$DB
    bcs filepick_kf_done
    sec
    sbc #$80
    sta fp_key
filepick_kf_done
    jmp filepick_lp_act
filepick_hop10
    jsr mse_get
    and #3                      ; left (1) and right (2)
    sta fp_tmp
    bne filepick_lp_press
    stz fp_down                 ; released
    bra filepick_lp_poll
filepick_lp_press
    lda fp_down
    bne filepick_lp_poll                ; still the same press
    lda #1
    sta fp_down
    ; which cell is under the pointer?
    lda X16_P2                  ; y, in pixels
    lsr X16_P3
    ror
    lsr X16_P3
    ror
    lsr X16_P3
    ror
    sta fp_row                  ; the text row
    lda X16_P0                  ; x
    lsr X16_P1
    ror
    lsr X16_P1
    ror
    lsr X16_P1
    ror
    sta fp_tmp2                 ; the text column
    ; the x box on the header row closes, like ESC
    lda fp_row
    cmp #FPK_PTOP
    bne filepick_lp_rows
    lda fp_left
    clc
    adc fp_wide
    sec
    sbc #3
    cmp fp_tmp2
    bcs filepick_lp_poll
    lda #$1B
    sta fp_key
    jmp filepick_lp_act
filepick_lp_rows
    lda fp_row
    cmp #FPK_PTOP+1
    bcc filepick_lp_poll
    sec
    sbc #FPK_PTOP+1
    sta fp_row                  ; the line within the list
    cmp fp_rows
    bcs filepick_lp_poll
    clc
    adc fp_top
    cmp fp_nent
    bcc filepick_fk1677
    jmp filepick_lp_poll
filepick_fk1677
    sta fp_idx
    sta fp_sel
    lda fp_tmp
    and #2
    beq filepick_lp_left
    ; RIGHT button: the ALT gesture
    lda #3
    sta fp_act
    lda #255
    sta fp_lastidx
    bra filepick_lp_act
filepick_lp_left
    jsr clock_get_timer         ; A/X = the low 16 bits of the jiffy clock
    sta fp_tmp
    stx fp_tmp2
    lda fp_idx
    cmp fp_lastidx
    bne filepick_lp_single
    sec                         ; how long since the last click here?
    lda fp_tmp
    sbc fp_lastck
    sta fp_cnt
    lda fp_tmp2
    sbc fp_lastck+1
    bne filepick_lp_single              ; more than 255 jiffies ago
    lda fp_cnt
    cmp #FPK_DBLCLK
    bcs filepick_lp_single
    lda #1                      ; double click
    sta fp_act
    lda #255
    sta fp_lastidx
    bra filepick_lp_act
filepick_lp_single
    lda fp_tmp
    sta fp_lastck
    lda fp_tmp2
    sta fp_lastck+1
    lda fp_idx
    sta fp_lastidx
    lda #2                      ; select only
    sta fp_act
filepick_lp_act
    lda fp_act
    cmp #2
    bne filepick_hop11   ; selection moved: redraw and carry on
    jmp filepick_loop
filepick_hop11
    cmp #3
    bne filepick_lp_key
    ; the ALT gesture, which only makes sense on a file
    lda fp_sel
    jsr filepick_ent_type
    cmp #DIR_TYPE_DIR
    beq filepick_lp_again
    jsr filepick_path_of_sel
    lda #FPK_ALT
    rts
filepick_lp_again
    lda #1
    sta fp_down
    jmp filepick_loop
filepick_lp_key
    lda fp_act
    cmp #1
    bne filepick_lp_haskey
    lda #$0D                    ; a double click is Enter
    sta fp_key
filepick_lp_haskey
    lda fp_key
    cmp #'H'                    ; "the folder I am looking at"
    bne filepick_lp_nothere
    lda #FPK_HERE
    rts
filepick_lp_nothere
.if xuse_filepick_edit
    lda fp_key
    cmp #'N'
    bne filepick_lp_note1
    jmp filepick_ed_newdir
filepick_lp_note1
    cmp #'E'                    ; not 'r': that already runs/picks
    bne filepick_lp_note2
    jmp filepick_ed_rename
filepick_lp_note2
    cmp #'D'
    bne filepick_lp_note3
    jmp filepick_ed_delete
filepick_lp_note3
    cmp #'C'
    bne filepick_lp_note4
    jmp filepick_ed_copy
filepick_lp_note4
    cmp #'V'
    bne filepick_lp_note5
    jmp filepick_ed_paste
filepick_lp_note5
.endif
    lda fp_key
    cmp #$1B
    bne filepick_hop12
    jmp filepick_lp_none
filepick_hop12
    cmp #$03
    bne filepick_hop13
    jmp filepick_lp_none
filepick_hop13
    cmp #$91
    bne filepick_hop14
    jmp filepick_lp_move
filepick_hop14
    cmp #$11
    bne filepick_hop15
    jmp filepick_lp_move
filepick_hop15
    cmp #$13
    beq filepick_lp_move
    lda fp_nent
    bne filepick_hop16   ; nothing to act on
    jmp filepick_lp_input
filepick_hop16
    lda fp_sel
    jsr filepick_ent_type
    cmp #DIR_TYPE_DIR
    bne filepick_lp_file
    lda fp_key
    cmp #$0D
    beq filepick_hop17
    jmp filepick_lp_input
filepick_hop17
    ; descend: the drive first, then our own idea of where we are
    lda fp_sel
    jsr filepick_ent_fetch
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr filepick_zlen                   ; Y = length
    lda #<fp_nm                 ; A/X = name, Y = length
    ldx #>fp_nm
    jsr dos_chdir
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr filepick_descend
    stz fp_sel
    stz fp_top
    jsr filepick_read
    jmp filepick_loop
filepick_lp_file
    lda fp_key
    cmp #$0D
    beq filepick_lp_pick
    cmp #'R'
    beq filepick_lp_pick
    cmp #'A'
    beq filepick_hop18
    jmp filepick_lp_input
filepick_hop18
    jsr filepick_path_of_sel
    lda #FPK_ALT
    rts
filepick_lp_pick
    jsr filepick_path_of_sel
    lda #FPK_PICK
    rts
filepick_lp_move
    lda fp_key
    jsr filepick_move
    jmp filepick_loop
filepick_lp_none
    lda #FPK_NONE
    rts

.if xuse_filepick_edit
; =====================================================================
; managing what is in the panel, rather than only choosing from it
;
;   n  make a folder        c  remember a file  (copy)
;   e  rename               v  write it here    (paste)
;   d  delete
;
; Gated on its own: a program that only wants to ask "which file?" --
; imgview does -- should not carry mkdir and delete to get it.
;
; Every one of these ends by re-reading the directory, so the panel is
; never showing something the drive no longer has.
; =====================================================================
fp_clip     .fill 64            ; the file 'c' remembered, absolute
fp_clipok   .byte 0
fp_buf      .fill 256           ; what a copy moves at a time
fp_elen     .byte 0             ; length of the text being edited

filepick_s_newdir
    .text "new folder: ", 0
filepick_s_rename
    .text "rename to: ", 0
filepick_s_delete
    .text "delete? y/n: ", 0
filepick_s_swr
    .text ",s,w", 0

; Edit fp_nm in place on the panel's first row. X16_P0/P1 = the label.
;   out: carry set when Enter was pressed with something in the field
;
; Drawn blue on yellow, which nothing else in the panel uses: a field
; you type into that looks like the rows you do not is a field nobody
; sees. Inverting it was not enough -- the selected row is inverted too.
filepick_ed_prompt
    lda X16_P0
    sta fp_src
    lda X16_P1
    sta fp_src+1
filepick_ep_draw
    lda #FPK_PTOP+1
    ldx #FPK_AEDIT
    jsr filepick_prow
    ldx #FPK_PTOP+1
    ldy fp_left
    iny
    jsr screen_addr
    lda fp_src
    sta X16_P0
    lda fp_src+1
    sta X16_P1
    jsr filepick_zlen
    tya
    ldx #FPK_AEDIT
    jsr screen_blit
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    lda fp_elen
    beq filepick_ep_cursor
    ldx #FPK_AEDIT
    jsr screen_blit
filepick_ep_cursor
    lda #<filepick_s_cursor
    sta X16_P0
    lda #>filepick_s_cursor
    sta X16_P1
    lda #1
    ldx #FPK_AEDIT
    jsr screen_blit
    jsr key_wait
    cmp #$0D
    beq filepick_ep_enter
    cmp #$1B
    beq filepick_ep_cancel
    cmp #$03
    beq filepick_ep_cancel
    cmp #$14                    ; backspace
    bne filepick_ep_char
    lda fp_elen
    beq filepick_ep_draw
    dec fp_elen
    ldy fp_elen
    lda #0
    sta fp_nm,y
    bra filepick_ep_draw
filepick_ep_char
    cmp #' '
    bcc filepick_ep_draw
    cmp #$80
    bcs filepick_ep_draw
    ldy fp_elen
    cpy #30
    bcs filepick_ep_draw
    sta fp_nm,y
    inc fp_elen
    ldy fp_elen
    lda #0
    sta fp_nm,y
    jmp filepick_ep_draw
filepick_ep_enter
    lda fp_elen
    beq filepick_ep_cancel
    sec
    rts
filepick_ep_cancel
    clc
    rts

filepick_s_cursor
    .text "_", 0

; X16_P0/P1 = question -> carry set on y
filepick_ed_confirm
    lda #FPK_PTOP+1
    ldx #FPK_AEDIT
    jsr filepick_prow
    ldx #FPK_PTOP+1
    ldy fp_left
    iny
    jsr screen_addr
    jsr filepick_zlen
    tya
    ldx #FPK_AEDIT
    jsr screen_blit
    jsr key_wait
    and #$DF                    ; either case
    cmp #'Y'
    beq filepick_ec_yes
    clc
    rts
filepick_ec_yes
    sec
    rts

; n -- make a folder here
filepick_ed_newdir
    stz fp_nm
    stz fp_elen
    lda #<filepick_s_newdir
    sta X16_P0
    lda #>filepick_s_newdir
    sta X16_P1
    jsr filepick_ed_prompt
    bcs filepick_far1977
    jmp filepick_ed_done
filepick_far1977
    lda #<fp_nm
    ldx #>fp_nm
    ldy fp_elen
    jsr dos_mkdir
    jmp filepick_ed_reread

; e -- rename the selected entry
filepick_ed_rename
    lda fp_nent
    bne filepick_far1987
    jmp filepick_ed_done
filepick_far1987
    lda fp_sel
    jsr filepick_ent_fetch              ; the old name, into fp_nm
    lda #<fp_nm
    sta fp_src
    lda #>fp_nm
    sta fp_src+1
    lda #<fp_clip
    sta fp_dst
    lda #>fp_clip
    sta fp_dst+1
    lda #38
    jsr filepick_put_str                ; keep it: the prompt edits fp_nm
    sty fp_clipok               ; ...and its length, borrowed for a moment
    ldy #0
filepick_er_len
    lda fp_nm,y
    beq filepick_er_gotlen
    iny
    bne filepick_er_len
filepick_er_gotlen
    sty fp_elen
    lda #<filepick_s_rename
    sta X16_P0
    lda #>filepick_s_rename
    sta X16_P1
    jsr filepick_ed_prompt
    bcc filepick_ed_clipreset
    lda #<fp_clip               ; old name
    sta X16_P0
    lda #>fp_clip
    sta X16_P1
    lda fp_clipok
    sta X16_P2
    lda #<fp_nm                 ; new name
    ldx #>fp_nm
    ldy fp_elen
    jsr dos_rename
filepick_ed_clipreset
    stz fp_clipok               ; it was only borrowed
    jmp filepick_ed_reread

; d -- delete the selected entry, folder or file
filepick_ed_delete
    lda fp_nent
    beq filepick_ed_done
    lda fp_sel
    jsr filepick_ent_type
    sta fp_kind
    lda fp_sel
    jsr filepick_ent_fetch
    ldy #0
filepick_dl_len
    lda fp_nm,y
    beq filepick_dl_gotlen
    iny
    bne filepick_dl_len
filepick_dl_gotlen
    sty fp_elen
    lda #<filepick_s_delete
    sta X16_P0
    lda #>filepick_s_delete
    sta X16_P1
    jsr filepick_ed_confirm
    bcc filepick_ed_done
    lda fp_kind
    cmp #DIR_TYPE_DIR
    beq filepick_dl_dir
    lda #<fp_nm
    ldx #>fp_nm
    ldy fp_elen
    jsr dos_delete
    jmp filepick_ed_reread
filepick_dl_dir
    lda #<fp_nm
    ldx #>fp_nm
    ldy fp_elen
    jsr dos_rmdir
    jmp filepick_ed_reread

; c -- remember the selected file
filepick_ed_copy
    lda fp_nent
    beq filepick_ed_done
    lda fp_sel
    jsr filepick_ent_type
    cmp #DIR_TYPE_DIR
    beq filepick_ed_done                ; folders are not copied, only their files
    jsr filepick_path_of_sel            ; fp_full = the absolute path
    lda #<fp_full
    sta fp_src
    lda #>fp_full
    sta fp_src+1
    lda #<fp_clip
    sta fp_dst
    lda #>fp_clip
    sta fp_dst+1
    lda #62
    jsr filepick_put_str
    lda #1
    sta fp_clipok
filepick_ed_done
    jmp filepick_loop

; v -- write the remembered file into the folder on show
filepick_ed_paste
    lda fp_clipok
    beq filepick_ed_done
    ; the destination name is the source's leaf, plus ",s,w" so the
    ; drive writes a sequential file rather than looking for a program
    lda #<fp_clip
    sta fp_src
    lda #>fp_clip
    sta fp_src+1
    ldy #0
    ldx #0
filepick_pa_leaf
    lda fp_clip,y
    beq filepick_pa_gotleaf
    cmp #'/'
    bne filepick_pa_next
    iny
    tya
    tax                         ; x = where the leaf starts
    dey
filepick_pa_next
    iny
    bne filepick_pa_leaf
filepick_pa_gotleaf
    txa
    tay
    ldx #0
filepick_pa_copy
    lda fp_clip,y
    beq filepick_pa_suffix
    sta fp_nm,x
    inx
    iny
    bne filepick_pa_copy
filepick_pa_suffix
    ldy #0
filepick_pa_swr
    lda filepick_s_swr,y
    beq filepick_pa_named
    sta fp_nm,x
    inx
    iny
    bne filepick_pa_swr
filepick_pa_named
    stx fp_elen
    ; source: the absolute path, read on logical file 4
    lda #<fp_clip
    sta X16_P0
    lda #>fp_clip
    sta X16_P1
    ldy #0
filepick_pa_slen
    lda fp_clip,y
    beq filepick_pa_gotslen
    iny
    bne filepick_pa_slen
filepick_pa_gotslen
    sty X16_P2
    lda #4
    sta X16_P3
    lda #8
    sta X16_P4
    lda #2
    sta X16_P5
    jsr fio_open_read
    bcs filepick_pa_failsrc
    ; destination on logical file 5, in whatever directory we are in
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    lda fp_elen
    sta X16_P2
    lda #5
    sta X16_P3
    lda #8
    sta X16_P4
    lda #2
    sta X16_P5
    jsr fio_open_write
    bcs filepick_pa_faildst
filepick_pa_block
    ldx #4                      ; read a block
    jsr CHKIN
    ldy #0
filepick_pa_read
    jsr CHRIN
    sta fp_buf,y
    iny
    beq filepick_pa_full                ; 256 bytes
    jsr READST
    beq filepick_pa_read
    sty fp_cnt                  ; short block: the last one
    lda #1
    sta fp_tmp
    bra filepick_pa_write
filepick_pa_full
    sty fp_cnt                  ; 0 means 256
    stz fp_tmp
filepick_pa_write
    ldx #5
    jsr CHKOUT
    ldy #0
filepick_pa_out
    lda fp_buf,y
    jsr CHROUT
    iny
    cpy fp_cnt
    bne filepick_pa_out
    lda fp_tmp
    beq filepick_pa_block
    ; done
    jsr CLRCHN
    lda #5
    jsr CLOSE
    lda #4
    jsr CLOSE
    bra filepick_ed_reread
filepick_pa_faildst
    jsr CLRCHN
    lda #4
    jsr CLOSE
    jmp filepick_loop
filepick_pa_failsrc
    jsr CLRCHN
    lda #4
    jsr CLOSE
    jmp filepick_loop

filepick_ed_reread
    jsr filepick_read
    stz fp_sel
    stz fp_top
    jmp filepick_loop
.endif

; the selected entry's name -> fp_full, as an absolute path
filepick_path_of_sel
    lda fp_sel
    jsr filepick_ent_fetch
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jmp filepick_make_path

; (end zone)
.endif
.if xuse_bmx
; --- inline storage/bmx.asm ---
;ACME
; =====================================================================
; x16lib :: storage/bmx.asm -- the X16's native bitmap file format
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; BMX version 1 (the format Prog8 and the community tools write):
;
;   offset  size  field
;   0-2     3     magic "BMX"
;   3       1     version (1)
;   4       1     bits per pixel (1/2/4/8)
;   5       1     VERA colour depth code (0-3; log2 of the bpp)
;   6-7     2     width in pixels, little-endian
;   8-9     2     height
;   10      1     palette entries (0 means 256)
;   11      1     first palette index
;   12-13   2     file offset of the pixel data
;   14      1     compression (0 = none; nothing else is supported)
;   15      1     border colour
;
; The palette follows the header (2 bytes per entry, GB then R --
; VERA's own layout), the pixel data follows the palette.
;
; Rows are written to VRAM bmx_stride bytes apart (default 320, the
; full-screen bitmap stride) -- so a 320-wide image is a plain
; contiguous load, and a narrower one lands as a "stamp" with the
; surrounding pixels untouched. bmx_save reads rows the same way.
;
; CAVEAT for bmx_save: the palette region of VRAM reads back the last
; value the HOST wrote (see const_vera.asm), so the palette saved is
; only meaningful if this program set those entries itself (pal_set /
; pal_load / a previous bmx_load).
; =====================================================================

; (zone: file scope in 64tass)

; Filled in by bmx_load's header parse; set by the caller for bmx_save.
bmx_width    .word 0
bmx_height   .word 0
bmx_bpp      .byte 8
bmx_palstart .byte 0
bmx_palcount .word 256          ; 1-256 entries
bmx_border   .byte 0
bmx_stride   .word 320          ; VRAM bytes between row starts
bmx_code     .byte 0            ; the last BMX_ERR_*, for bmx_lasterr

BMX_ERR_IO     = 1              ; open/read/write failed
BMX_ERR_FORMAT = 2              ; not a BMX, or not version 1
BMX_ERR_PACKED = 3              ; compressed data is not supported

; ---------------------------------------------------------------------
; bmx_lasterr -- why the last bmx_* call failed
;   out: A = BMX_ERR_IO / _FORMAT / _PACKED, or 0 after a call that worked
;
; These routines answer twice -- the carry says whether, A says why -- and
; a caller that can only see one of them (a generated binding will not
; guess a type for a routine documenting both) would otherwise be left
; unable to tell a missing file from a loaded one.
; ---------------------------------------------------------------------
bmx_lasterr
    lda bmx_code
    rts

; ---------------------------------------------------------------------
; bmx_load -- load a BMX file: palette into the VERA palette, pixels
;             into VRAM
;   in:  X16_P0/P1 = filename address, X16_P2 = length
;        X16_P3    = device (usually 8)
;        X16_P4    = VRAM bank (0/1), X16_P5/P6 = VRAM address
;   out: carry clear on success, set with A = BMX_ERR_* on failure
;        bmx_width/height/bpp/palstart/palcount/border reflect the file
; ---------------------------------------------------------------------
bmx_load
    stz bmx_code
    jsr bmx_open_read
    bcc _hdr
    lda #BMX_ERR_IO
    sta bmx_code
    rts
_hdr
    ldx #0                      ; pull in the 16-byte header
_get_hdr
    jsr CHRIN
    sta bmx_hdr,x
    inx
    cpx #16
    bne _get_hdr

    ; OPEN and CHKIN both succeed for a file that does not exist: CBM DOS
    ; reports "62,FILE NOT FOUND" on the command channel, and the KERNAL
    ; only surfaces it in ST once a read has been attempted. Without this
    ; check the 16 CHRINs above return junk, the magic test below fails,
    ; and a missing file is reported as BMX_ERR_FORMAT -- "this is not a
    ; BMX" rather than "this is not there". ST is likewise nonzero for a
    ; header shorter than 16 bytes, which is an I/O error too. A real BMX
    ; has palette and pixels after byte 16, so EOF cannot legitimately be
    ; set at this point.
    jsr READST
    beq _validate
    lda #BMX_ERR_IO
    sta bmx_code
    bra _close_err

_validate
    lda bmx_hdr                 ; validate
    cmp #'B'
    bne _bad_fmt
    lda bmx_hdr+1
    cmp #'M'
    bne _bad_fmt
    lda bmx_hdr+2
    cmp #'X'
    bne _bad_fmt
    lda bmx_hdr+3
    cmp #1
    bne _bad_fmt
    lda bmx_hdr+14
    beq _fmt_ok
    lda #BMX_ERR_PACKED
    sta bmx_code
    bra _close_err
_bad_fmt
    lda #BMX_ERR_FORMAT
    sta bmx_code
_close_err
    pha
    jsr bmx_close_read
    pla
    sec
    rts

_fmt_ok
    lda bmx_hdr+4               ; publish the header fields
    sta bmx_bpp
    lda bmx_hdr+6
    sta bmx_width
    lda bmx_hdr+7
    sta bmx_width+1
    lda bmx_hdr+8
    sta bmx_height
    lda bmx_hdr+9
    sta bmx_height+1
    lda bmx_hdr+11
    sta bmx_palstart
    lda bmx_hdr+15
    sta bmx_border
    lda bmx_hdr+10
    sta bmx_palcount
    stz bmx_palcount+1
    bne _pal_n
    inc bmx_palcount+1          ; 0 in the file means 256
_pal_n

    ; --- palette -> $1FA00 + palstart*2 -------------------------------
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    lda bmx_palstart
    asl                         ; carry = address bit 8
    sta VERA_ADDR_L
    lda #>VRAM_PALETTE
    adc #0
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))
    sta VERA_ADDR_H

    lda bmx_palcount            ; byte count = entries * 2
    sta bmx_cnt
    lda bmx_palcount+1
    sta bmx_cnt+1
    asl bmx_cnt
    rol bmx_cnt+1
    jsr bmx_bulk_read              ; MACPTR into DATA0; CHRIN fallback
    bcc _pal_done
    jmp _io_short
_pal_done

    ; --- skip any gap up to the header's data offset -------------------
    ; expected position so far = 16 + palcount*2
    lda bmx_palcount
    sta bmx_cnt
    lda bmx_palcount+1
    sta bmx_cnt+1
    asl bmx_cnt
    rol bmx_cnt+1
    clc
    lda bmx_cnt
    adc #16
    sta bmx_cnt
    lda bmx_cnt+1
    adc #0
    sta bmx_cnt+1
    sec                         ; gap = data offset - position
    lda bmx_hdr+12
    sbc bmx_cnt
    sta bmx_cnt
    lda bmx_hdr+13
    sbc bmx_cnt+1
    sta bmx_cnt+1
    bcc _data                   ; offset before position: trust the data
_skip
    lda bmx_cnt
    ora bmx_cnt+1
    beq _data
    jsr CHRIN
    jsr bmx_dec_cnt
    bra _skip

_data
    ; The header, the palette and any gap all came out of the file, so
    ; every pixel row must still be ahead of us. A nonzero ST here means
    ; the file ended somewhere in the palette or the gap. (EOF cannot be
    ; legitimate at this point unless the image has no rows at all, and a
    ; zero-height BMX describes nothing.)
    jsr READST
    cmp #0
    beq _rows_ahead
    jmp _io_short               ; _io_short is past the row loop: too far
                                ; for a relative branch from here
_rows_ahead

    ; --- pixel rows, bmx_stride apart ----------------------------------
    lda X16_P5                  ; the walking VRAM address
    sta bmx_cur
    lda X16_P6
    sta bmx_cur+1
    lda X16_P4
    and #$01
    sta bmx_cur+2
    jsr bmx_row_bytes              ; bmx_row = width >> (3 - depth)

    lda bmx_height
    sta bmx_rows
    lda bmx_height+1
    sta bmx_rows+1
_row
    lda bmx_rows
    ora bmx_rows+1
    beq _done
    jsr bmx_point_cur              ; port 0 at bmx_cur, INC_1

    lda bmx_row
    sta bmx_cnt
    lda bmx_row+1
    sta bmx_cnt+1
    jsr bmx_bulk_read              ; the whole row in MACPTR-sized gulps
    bcc _row_done
    jmp _io_short
_row_done
    clc                         ; cur += stride (17-bit)
    lda bmx_cur
    adc bmx_stride
    sta bmx_cur
    lda bmx_cur+1
    adc bmx_stride+1
    sta bmx_cur+1
    lda bmx_cur+2
    adc #0
    and #$01
    sta bmx_cur+2
    lda bmx_rows
    bne _dec_rows
    dec bmx_rows+1
_dec_rows
    dec bmx_rows

    ; ST is checked once per row, not once per byte: CHRIN is already the
    ; slow part, but a per-pixel READST would double it. Between rows the
    ; test is exact -- another row is expected, so any status at all (EOF
    ; included) means the file is shorter than its own header claims.
    ; After the LAST row EOF is not merely allowed but expected, since the
    ; final pixel is the final byte of the file.
    lda bmx_rows
    ora bmx_rows+1
    beq _done
    jsr READST
    cmp #0
    beq _row

_io_short
    lda #BMX_ERR_IO
    sta bmx_code
    jmp _close_err

_done
    jsr bmx_close_read
    clc
    rts

; ---------------------------------------------------------------------
; bmx_save -- write a BMX file from VRAM
;   in:  X16_P0/P1 = filename address, X16_P2 = length
;        X16_P3    = device
;        X16_P4    = VRAM bank, X16_P5/P6 = VRAM address of the image
;        bmx_width/height/bpp/palstart/palcount/border/stride describe
;        what to save (bpp 8 and stride 320 are the defaults)
;   out: carry clear on success, set with A = BMX_ERR_IO on failure
; ---------------------------------------------------------------------
bmx_save
    stz bmx_code
    jsr bmx_open_write
    bcc _wr_hdr
    lda #BMX_ERR_IO
    sta bmx_code
    rts
_wr_hdr
    lda #'B'
    sta bmx_hdr
    lda #'M'
    sta bmx_hdr+1
    lda #'X'
    sta bmx_hdr+2
    lda #1
    sta bmx_hdr+3
    lda bmx_bpp
    sta bmx_hdr+4
    jsr bmx_depth_code
    sta bmx_hdr+5
    lda bmx_width
    sta bmx_hdr+6
    lda bmx_width+1
    sta bmx_hdr+7
    lda bmx_height
    sta bmx_hdr+8
    lda bmx_height+1
    sta bmx_hdr+9
    lda bmx_palcount            ; 256 stores as 0
    sta bmx_hdr+10
    lda bmx_palstart
    sta bmx_hdr+11
    lda bmx_palcount            ; data offset = 16 + palcount*2
    sta bmx_cnt
    lda bmx_palcount+1
    sta bmx_cnt+1
    asl bmx_cnt
    rol bmx_cnt+1
    clc
    lda bmx_cnt
    adc #16
    sta bmx_hdr+12
    lda bmx_cnt+1
    adc #0
    sta bmx_hdr+13
    stz bmx_hdr+14              ; uncompressed
    lda bmx_border
    sta bmx_hdr+15

    ldx #0
_hdr_out
    lda bmx_hdr,x
    jsr CHROUT
    inx
    cpx #16
    bne _hdr_out

    ; --- palette from the VRAM shadow ----------------------------------
    lda #VERA_CTRL_ADDRSEL
    tsb VERA_CTRL               ; port 1 reads, so CHROUT stays safe
    lda bmx_palstart
    asl
    sta VERA_ADDR_L
    lda #>VRAM_PALETTE
    adc #0
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))
    sta VERA_ADDR_H
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL

    lda bmx_palcount
    sta bmx_cnt
    lda bmx_palcount+1
    sta bmx_cnt+1
    asl bmx_cnt
    rol bmx_cnt+1
_pal_out
    lda bmx_cnt
    ora bmx_cnt+1
    beq _pal_wrote
    lda VERA_DATA1
    jsr CHROUT
    jsr bmx_dec_cnt
    bra _pal_out
_pal_wrote

    ; --- pixel rows -----------------------------------------------------
    lda X16_P5
    sta bmx_cur
    lda X16_P6
    sta bmx_cur+1
    lda X16_P4
    and #$01
    sta bmx_cur+2
    jsr bmx_row_bytes

    lda bmx_height
    sta bmx_rows
    lda bmx_height+1
    sta bmx_rows+1
_wrow
    lda bmx_rows
    ora bmx_rows+1
    beq _wdone
    jsr bmx_point_cur1             ; port 1 at bmx_cur

    lda bmx_row
    sta bmx_cnt
    lda bmx_row+1
    sta bmx_cnt+1
_wpix
    lda bmx_cnt
    ora bmx_cnt+1
    beq _wrow_done
    lda VERA_DATA1
    jsr CHROUT
    jsr bmx_dec_cnt
    bra _wpix
_wrow_done
    clc
    lda bmx_cur
    adc bmx_stride
    sta bmx_cur
    lda bmx_cur+1
    adc bmx_stride+1
    sta bmx_cur+1
    lda bmx_cur+2
    adc #0
    and #$01
    sta bmx_cur+2
    lda bmx_rows
    bne _wdec
    dec bmx_rows+1
_wdec
    dec bmx_rows
    bra _wrow

_wdone
    jsr bmx_close_write
    clc
    rts

; ---------------------------------------------------------------------
; bmx_load_hires -- load a BMX file into the VERA_2 640x480 SDRAM
;             bitmap (the gfx8h engine). Palette goes to the VERA_2
;             palette, pixels stream to VERA_2 SDRAM starting at offset 0.
;   in:  X16_P0/P1 = filename address, X16_P2 = length
;        X16_P3    = device (usually 8)
;   out: carry clear on success, set with A = BMX_ERR_* on failure
;        bmx_width/height/bpp/palstart/palcount/border reflect the file
;   note: select the hi-res 8bpp mode first (gfx8h_init). Rows land
;         BMX_HIRES_STRIDE (640) bytes apart from SDRAM offset 0, so a
;         full-width 640x480x8 image is a plain contiguous load. Unlike
;         bmx_load (which targets VERA VRAM through DATA0), this streams
;         into the MiSTer VERA_2 SDRAM address space through VERA2_DATA.
; ---------------------------------------------------------------------
BMX_HIRES_STRIDE = 640

bmx_load_hires
    stz bmx_code
    jsr bmx_open_read
    bcc _hdr
    lda #BMX_ERR_IO
    sta bmx_code
    rts
_hdr
    ldx #0                      ; pull in the 16-byte header
_get_hdr
    jsr CHRIN
    sta bmx_hdr,x
    inx
    cpx #16
    bne _get_hdr

    jsr READST                  ; a short/absent header is an I/O error
    beq _validate
    lda #BMX_ERR_IO
    sta bmx_code
    bra _close_err
_validate
    lda bmx_hdr
    cmp #'B'
    bne _bad_fmt
    lda bmx_hdr+1
    cmp #'M'
    bne _bad_fmt
    lda bmx_hdr+2
    cmp #'X'
    bne _bad_fmt
    lda bmx_hdr+3
    cmp #1
    bne _bad_fmt
    lda bmx_hdr+14
    beq _fmt_ok
    lda #BMX_ERR_PACKED
    sta bmx_code
    bra _close_err
_bad_fmt
    lda #BMX_ERR_FORMAT
    sta bmx_code
_close_err
    pha
    jsr bmx_close_read
    pla
    sec
    rts

_fmt_ok
    lda bmx_hdr+4               ; publish the header fields
    sta bmx_bpp
    lda bmx_hdr+6
    sta bmx_width
    lda bmx_hdr+7
    sta bmx_width+1
    lda bmx_hdr+8
    sta bmx_height
    lda bmx_hdr+9
    sta bmx_height+1
    lda bmx_hdr+11
    sta bmx_palstart
    lda bmx_hdr+15
    sta bmx_border
    lda bmx_hdr+10
    sta bmx_palcount
    stz bmx_palcount+1
    bne _pal_n
    inc bmx_palcount+1          ; 0 in the file means 256
_pal_n

    ; --- palette -> the VERA_2 palette (IDX auto-increments) -----------
    lda bmx_palstart
    sta VERA2_PAL_IDX
    lda bmx_palcount            ; entries remaining (16-bit)
    sta bmx_cnt
    lda bmx_palcount+1
    sta bmx_cnt+1
_pal_loop
    lda bmx_cnt
    ora bmx_cnt+1
    beq _pal_done
    jsr CHRIN
    sta VERA2_PAL_LO
    jsr CHRIN
    sta VERA2_PAL_HI
    jsr bmx_dec_cnt
    bra _pal_loop
_pal_done

    ; --- skip any gap up to the header's data offset -------------------
    lda bmx_palcount
    sta bmx_cnt
    lda bmx_palcount+1
    sta bmx_cnt+1
    asl bmx_cnt
    rol bmx_cnt+1
    clc
    lda bmx_cnt
    adc #16
    sta bmx_cnt
    lda bmx_cnt+1
    adc #0
    sta bmx_cnt+1
    sec                         ; gap = data offset - position
    lda bmx_hdr+12
    sbc bmx_cnt
    sta bmx_cnt
    lda bmx_hdr+13
    sbc bmx_cnt+1
    sta bmx_cnt+1
    bcc _data
_skip
    lda bmx_cnt
    ora bmx_cnt+1
    beq _data
    jsr CHRIN
    jsr bmx_dec_cnt
    bra _skip

_data
    jsr READST
    cmp #0
    beq _rows_ahead
    jmp _io_short
_rows_ahead

    ; --- pixel rows into VERA_2 SDRAM, BMX_HIRES_STRIDE apart -----------
    stz bmx_cur                 ; SDRAM byte offset 0
    stz bmx_cur+1
    stz bmx_cur+2
    jsr bmx_row_bytes              ; bmx_row = width >> (3 - depth)

    lda bmx_height
    sta bmx_rows
    lda bmx_height+1
    sta bmx_rows+1
_row
    lda bmx_rows
    ora bmx_rows+1
    beq _done
    jsr bmx_point_cur2             ; VERA_2 addr = bmx_cur, INC_1

    lda bmx_row
    sta bmx_cnt
    lda bmx_row+1
    sta bmx_cnt+1
    jsr bmx_bulk_read2             ; the whole row, MACPTR into VERA2_DATA
    bcc _row_done
    jmp _io_short
_row_done
    clc                         ; cur += 640 (20-bit)
    lda bmx_cur
    adc #<BMX_HIRES_STRIDE
    sta bmx_cur
    lda bmx_cur+1
    adc #>BMX_HIRES_STRIDE
    sta bmx_cur+1
    lda bmx_cur+2
    adc #0
    sta bmx_cur+2
    lda bmx_rows
    bne _dec_rows
    dec bmx_rows+1
_dec_rows
    dec bmx_rows

    lda bmx_rows
    ora bmx_rows+1
    beq _done
    jsr READST
    cmp #0
    beq _row

_io_short
    lda #BMX_ERR_IO
    sta bmx_code
    jmp _close_err

_done
    jsr bmx_close_read
    clc
    rts

; VERA_2 SDRAM address <- bmx_cur, auto-increment by 1
bmx_point_cur2
    lda bmx_cur
    sta VERA2_ADDR_L
    lda bmx_cur+1
    sta VERA2_ADDR_M
    lda bmx_cur+2
    and #$0F
    ora #(VERA2_INC_1 << 4)     ; VERA2_INC_1 code is 0: high nibble stays
    sta VERA2_ADDR_H
    rts

; read bmx_cnt bytes from the open channel into VERA2_DATA (the SDRAM
; port is already aimed). Same MACPTR streaming trick as bmx_bulk_read,
; but the fixed destination is the VERA_2 data register.
;   out: carry clear = done; carry set = the stream died mid-read
bmx_bulk_read2
_more
    lda bmx_cnt
    ora bmx_cnt+1
    beq _br_ok
    lda bmx_cnt+1
    beq _small
    lda #255
    bra _ask
_small
    lda bmx_cnt
_ask
    ldx #<VERA2_DATA
    ldy #>VERA2_DATA
    sec                         ; fixed destination: stream into VERA_2
    jsr MACPTR
    bcs _fallback
    txa
    bne _got
    tya
    beq _br_short
_got
    stx bmx_t
    sec
    lda bmx_cnt
    sbc bmx_t
    sta bmx_cnt
    sty bmx_t
    lda bmx_cnt+1
    sbc bmx_t
    sta bmx_cnt+1
    bra _more
_br_ok
    clc
    rts
_br_short
    sec
    rts
_fallback
    lda bmx_cnt
    ora bmx_cnt+1
    beq _br_ok
    jsr CHRIN
    sta VERA2_DATA
    jsr bmx_dec_cnt
    bra _fallback

; --- plumbing ---------------------------------------------------------

bmx_open_read
    lda X16_P2
    ldx X16_P0
    ldy X16_P1
    jsr SETNAM
    lda #2
    ldx X16_P3
    ldy #0                      ; sequential read, no header games
    jsr SETLFS
    jsr OPEN
    bcs bmx_open_bad
    ldx #2
    jsr CHKIN
    bcs bmx_open_bad
    clc
    rts

bmx_open_write
    lda X16_P2
    ldx X16_P0
    ldy X16_P1
    jsr SETNAM
    lda #2
    ldx X16_P3
    ldy #1                      ; write
    jsr SETLFS
    jsr OPEN
    bcs bmx_open_bad
    ldx #2
    jsr CHKOUT
    bcs bmx_open_bad
    clc
    rts

bmx_open_bad
    jsr CLRCHN
    lda #2
    jsr CLOSE
    sec
    rts

bmx_close_read
bmx_close_write
    jsr CLRCHN
    lda #2
    jsr CLOSE
    rts

; bmx_row = bmx_width >> (3 - depth): the bytes in one row of pixels
bmx_row_bytes
    lda bmx_width
    sta bmx_row
    lda bmx_width+1
    sta bmx_row+1
    jsr bmx_depth_code
    eor #$03                    ; 3 - depth (depth is 0-3)
    tax
    beq bmx_rb_done
bmx_rb_shift
    lsr bmx_row+1
    ror bmx_row
    dex
    bne bmx_rb_shift
bmx_rb_done
    rts

; A = the VERA depth code for bmx_bpp (8->3, 4->2, 2->1, 1->0)
bmx_depth_code
    lda bmx_bpp
    cmp #8
    beq bmx_dc8
    cmp #4
    beq bmx_dc4
    cmp #2
    beq bmx_dc2
    lda #0
    rts
bmx_dc8
    lda #3
    rts
bmx_dc4
    lda #2
    rts
bmx_dc2
    lda #1
    rts

bmx_point_cur
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    lda bmx_cur
    sta VERA_ADDR_L
    lda bmx_cur+1
    sta VERA_ADDR_M
    lda bmx_cur+2
    ora #(VERA_INC_1 << 4)
    sta VERA_ADDR_H
    rts

bmx_point_cur1
    lda #VERA_CTRL_ADDRSEL
    tsb VERA_CTRL
    lda bmx_cur
    sta VERA_ADDR_L
    lda bmx_cur+1
    sta VERA_ADDR_M
    lda bmx_cur+2
    ora #(VERA_INC_1 << 4)
    sta VERA_ADDR_H
    lda #VERA_CTRL_ADDRSEL      ; leave ADDRSEL alone for the KERNAL
    trb VERA_CTRL
    rts

bmx_dec_cnt
    lda bmx_cnt
    bne bmx_dc_lo
    dec bmx_cnt+1
bmx_dc_lo
    dec bmx_cnt
    rts

bmx_t .byte 0

; read bmx_cnt bytes from the open channel into VERA_DATA0 (the port
; is already aimed). MACPTR moves them in bulk -- with the input carry
; SET the KERNAL holds the destination address fixed, which is exactly
; the data-port streaming trick mem_copy uses. A device that cannot do
; MACPTR answers carry set, and the byte-by-byte CHRIN path takes over.
;   out: carry clear = done; carry set = the stream died mid-read
bmx_bulk_read
_more
    lda bmx_cnt
    ora bmx_cnt+1
    beq _br_ok
    lda bmx_cnt+1
    beq _small
    lda #255                    ; a big remainder: largest single ask
    bra _ask
_small
    lda bmx_cnt                 ; the exact remainder
_ask
    ldx #<VERA_DATA0
    ldy #>VERA_DATA0
    sec                         ; fixed destination: stream into VERA
    jsr MACPTR
    bcs _fallback               ; the device cannot do block reads
    txa                         ; X/Y = bytes actually delivered
    bne _got
    tya
    beq _br_short               ; zero bytes: the file ran out
_got
    stx bmx_t                   ; bmx_cnt -= bytes read
    sec
    lda bmx_cnt
    sbc bmx_t
    sta bmx_cnt
    sty bmx_t
    lda bmx_cnt+1
    sbc bmx_t
    sta bmx_cnt+1
    bra _more
_br_ok
    clc
    rts
_br_short
    sec
    rts
_fallback
    lda bmx_cnt
    ora bmx_cnt+1
    beq _br_ok
    jsr CHRIN
    sta VERA_DATA0
    jsr bmx_dec_cnt
    bra _fallback

bmx_hdr  .fill 16, 0
bmx_cnt  .word 0
bmx_cur  .fill 3, 0
bmx_row  .word 0
bmx_rows .word 0

; (end zone)
.endif
.if xuse_math && X16_SKIP_MATH == 0
; --- inline util/math.asm ---
; 64tass
; =====================================================================
; x16lib :: util/math.asm -- game math (64tass edition)
; =====================================================================
; Port of src_acme/util/math.asm. 64tass floats are not used here:
; the sine and arctangent tables are inlined literals, generated from
; the identical formulas the ACME tree computes at assembly time:
;   sin:  int(sin(i*pi/128) * 127.0 + 128.5) - 128     (i = 0..255)
;   atan: int(atan(i/32) * 128.0/pi + 0.5)             (i = 0..32)
; The ACME build remains the reference; the shared test suite pins
; both to the same anchor values.
; =====================================================================

; ---------------------------------------------------------------------
; rnd_seed -- in: A = low, X = high. Zero is nudged to 1.
; rnd8  -- out: A = the next pseudo-random byte (X = high byte)
; rnd16 -- out: A = low, X = high
; ---------------------------------------------------------------------
rnd_seed
    sta rnd_state
    stx rnd_state+1
    ora rnd_state+1
    bne _done
    inc rnd_state               ; zero stays zero forever
_done
    rts

rnd8                            ; same routine; read A, ignore X
rnd16
    lda rnd_state+1
    lsr
    lda rnd_state
    ror
    eor rnd_state+1
    sta rnd_state+1             ; x ^= x >> 9
    ror
    eor rnd_state
    sta rnd_state               ; x ^= x << 7
    eor rnd_state+1
    sta rnd_state+1             ; x ^= x << 8
    lda rnd_state
    ldx rnd_state+1
    rts

rnd_state .word $2A56

; ---------------------------------------------------------------------
; sin8 / cos8   -- in: A = angle 0-255.  out: A = -127..127 signed
; sin8u / cos8u -- in: A = angle 0-255.  out: A = 1..255 unsigned
; Preserve X; clobber Y.
; ---------------------------------------------------------------------
sin8
    tay
    lda math_sintab,y
    rts

cos8
    clc
    adc #64                     ; cos(a) = sin(a + 90 degrees)
    tay
    lda math_sintab,y
    rts

sin8u
    tay
    lda math_sintab,y
    clc
    adc #128
    rts

cos8u
    clc
    adc #64
    tay
    lda math_sintab,y
    clc
    adc #128
    rts

math_sintab
    .byte $00, $03, $06, $09, $0c, $10, $13, $16, $19, $1c, $1f, $22, $25, $28, $2b, $2e
    .byte $31, $33, $36, $39, $3c, $3f, $41, $44, $47, $49, $4c, $4e, $51, $53, $55, $58
    .byte $5a, $5c, $5e, $60, $62, $64, $66, $68, $6a, $6b, $6d, $6f, $70, $71, $73, $74
    .byte $75, $76, $78, $79, $7a, $7a, $7b, $7c, $7d, $7d, $7e, $7e, $7e, $7f, $7f, $7f
    .byte $7f, $7f, $7f, $7f, $7e, $7e, $7e, $7d, $7d, $7c, $7b, $7a, $7a, $79, $78, $76
    .byte $75, $74, $73, $71, $70, $6f, $6d, $6b, $6a, $68, $66, $64, $62, $60, $5e, $5c
    .byte $5a, $58, $55, $53, $51, $4e, $4c, $49, $47, $44, $41, $3f, $3c, $39, $36, $33
    .byte $31, $2e, $2b, $28, $25, $22, $1f, $1c, $19, $16, $13, $10, $0c, $09, $06, $03
    .byte $00, $fd, $fa, $f7, $f4, $f0, $ed, $ea, $e7, $e4, $e1, $de, $db, $d8, $d5, $d2
    .byte $cf, $cd, $ca, $c7, $c4, $c1, $bf, $bc, $b9, $b7, $b4, $b2, $af, $ad, $ab, $a8
    .byte $a6, $a4, $a2, $a0, $9e, $9c, $9a, $98, $96, $95, $93, $91, $90, $8f, $8d, $8c
    .byte $8b, $8a, $88, $87, $86, $86, $85, $84, $83, $83, $82, $82, $82, $81, $81, $81
    .byte $81, $81, $81, $81, $82, $82, $82, $83, $83, $84, $85, $86, $86, $87, $88, $8a
    .byte $8b, $8c, $8d, $8f, $90, $91, $93, $95, $96, $98, $9a, $9c, $9e, $a0, $a2, $a4
    .byte $a6, $a8, $ab, $ad, $af, $b2, $b4, $b7, $b9, $bc, $bf, $c1, $c4, $c7, $ca, $cd
    .byte $cf, $d2, $d5, $d8, $db, $de, $e1, $e4, $e7, $ea, $ed, $f0, $f4, $f7, $fa, $fd

; ---------------------------------------------------------------------
; atan2 -- the angle of a vector
;   in:  A = dx, X = dy  (signed bytes)
;   out: A = angle 0-255 (0 = +x/east, 64 = +y/down-screen)
; ---------------------------------------------------------------------
atan2
    stz at_negx
    tay                         ; |dx|, remembering the sign
    bpl _dx_pos
    inc at_negx
    eor #$FF
    clc
    adc #1
_dx_pos
    sta at_ax
    txa                         ; |dy|
    stz at_negy
    bpl _dy_pos
    inc at_negy
    eor #$FF
    clc
    adc #1
_dy_pos
    sta at_ay

    ; base angle 0..64 within the positive quadrant
    cmp at_ax
    beq _diag
    bcc _shallow
    lda at_ax                   ; steep: base = 64 - atan(ax/ay)
    ldx at_ay
    jsr math_ratio32
    tay
    sec
    lda #64
    sbc math_atantab,y
    bra _quad
_diag
    ora at_ax
    bne _is45
    lda #0                      ; atan2(0,0): call it east
    rts
_is45
    lda #32                     ; exactly 45 degrees
    bra _quad
_shallow
    lda at_ay                   ; shallow: base = atan(ay/ax)
    ldx at_ax
    jsr math_ratio32
    tay
    lda math_atantab,y

_quad
    ; fold the base angle into the right quadrant
    ldy at_negx
    beq _dx_ok
    eor #$FF                    ; dx < 0: angle = 128 - base
    clc
    adc #129
_dx_ok
    ldy at_negy
    beq _done
    eor #$FF                    ; dy < 0: angle = -angle
    clc
    adc #1
_done
    rts

; A = (A * 32) / X, for A <= X and X nonzero. Result 0..32.
math_ratio32
    stx at_den
    sta at_num+1                ; num = A * 256...
    stz at_num
    ldx #3
_shift
    lsr at_num+1                ; ...then >> 3 = A * 32
    ror at_num
    dex
    bne _shift
    lda #0                      ; 16-bit / 8-bit restoring divide
    ldx #16
_div
    asl at_num
    rol at_num+1
    rol
    cmp at_den
    bcc _no
    sbc at_den
    inc at_num
_no
    dex
    bne _div
    lda at_num                  ; the quotient
    rts

at_ax   .byte 0
at_ay   .byte 0
at_negx .byte 0
at_negy .byte 0
at_num  .word 0
at_den  .byte 0

math_atantab                    ; round(atan(t/32) * 256/2pi), t = 0..32
    .byte $00, $01, $03, $04, $05, $06, $08, $09, $0a, $0b, $0c, $0d, $0f, $10, $11, $12
    .byte $13, $14, $15, $16, $17, $18, $19, $19, $1a, $1b, $1c, $1d, $1d, $1e, $1f, $1f
    .byte $20

; ---------------------------------------------------------------------
; lerp8 -- linear interpolation between two unsigned bytes
;   in:  X16_P0 = a, X16_P1 = b, A = t (0 = a ... 255 = b)
;   out: A = the interpolated value; t=0 is exactly a, t=255 exactly b
; ---------------------------------------------------------------------
lerp8
    sta lp_t
    lda X16_P1
    cmp X16_P0
    bcc _down
    sbc X16_P0                  ; carry set: a clean subtract
    jsr math_scale_t
    clc
    adc X16_P0
    rts
_down
    lda X16_P0                  ; b < a: interpolate downwards
    sec
    sbc X16_P1
    jsr math_scale_t
    sta lp_d
    sec
    lda X16_P0
    sbc lp_d
    rts

; A = (A * (lp_t + 1)) >> 8
math_scale_t
    sta lp_d
    lda lp_t
    cmp #$FF
    beq _whole                  ; t+1 = 256: the answer is d itself
    inc a                       ; n = t+1, fits a byte
    sta lp_n
    lda #0
    ldx #8
_mul
    lsr lp_n
    bcc _skip
    clc
    adc lp_d
_skip
    ror
    dex
    bne _mul
    rts
_whole
    lda lp_d
    rts

lp_t .byte 0
lp_n .byte 0
lp_d .byte 0
.endif
.if xuse_clip
; --- inline util/clip.asm ---
;ACME
; =====================================================================
; x16lib :: util/clip.asm -- Cohen-Sutherland line clipping
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; gfx8l_line and fx_line are documented as non-clipping. This removes
; that sharp edge: give clip_line a segment in 16-bit SIGNED
; coordinates (anywhere within +/-4095) and it either rejects it or
; hands back the visible part, already loaded into the line drawers'
; parameter block:
;
;       ; clipl_x0/y0/x1/y1 = the segment, clip_set = the rectangle
;       jsr clip_line
;       bcs _offscreen              ; nothing visible
;       lda #colour
;       sta X16_P6
;       jsr gfx8l_line              ; or fx_line
;
; The rectangle is inclusive and defaults to the full 320x240 bitmap.
; =====================================================================

; (zone: file scope in 64tass)

; the segment, written by the caller (16-bit signed, +/-4095)
clipl_x0 .word 0
clipl_y0 .word 0
clipl_x1 .word 0
clipl_y1 .word 0

; the clip rectangle, inclusive
clip_xmin .word 0
clip_ymin .word 0
clip_xmax .word 319
clip_ymax .word 239

; outcode bits
CLIP_LEFT   = %0001
CLIP_RIGHT  = %0010
CLIP_TOP    = %0100
CLIP_BOTTOM = %1000

; ---------------------------------------------------------------------
; clip_set -- change the rectangle
;   in: X16_P0/P1 = xmin, X16_P2/P3 = ymin,
;       X16_P4/P5 = xmax, X16_P6/P7 = ymax   (inclusive)
; ---------------------------------------------------------------------
clip_set
    lda X16_P0
    sta clip_xmin
    lda X16_P1
    sta clip_xmin+1
    lda X16_P2
    sta clip_ymin
    lda X16_P3
    sta clip_ymin+1
    lda X16_P4
    sta clip_xmax
    lda X16_P5
    sta clip_xmax+1
    lda X16_P6
    sta clip_ymax
    lda X16_P7
    sta clip_ymax+1
    rts

; ---------------------------------------------------------------------
; clip_line -- clip clipl_* against the rectangle
;   out: carry set   = entirely outside, draw nothing
;        carry clear = clipl_* now hold the visible sub-segment, and
;                      X16_P0..P5 are loaded for gfx8l_line / fx_line
; ---------------------------------------------------------------------
clip_line
_loop
    jsr clip_oc0
    sta cp_c0
    jsr clip_oc1
    sta cp_c1
    ora cp_c0
    bne _outside
    jmp _accept                 ; both inside (out of branch range)
_outside
    lda cp_c0
    and cp_c1
    beq _clip_one
    sec                         ; share an outside half-plane: reject
    rts

_clip_one
    ; pull the endpoint with a nonzero code into the work slot
    lda cp_c0
    bne _use0
    lda #1
    sta cp_which
    lda cp_c1
    sta cp_code
    ldx #3
_cp1
    lda clipl_x1,x
    sta cw_x,x
    lda clipl_x0,x
    sta co_x,x
    dex
    bpl _cp1
    jmp _intersect              ; out of branch range
_use0
    stz cp_which
    sta cp_code
    ldx #3
_cp0
    lda clipl_x0,x
    sta cw_x,x
    lda clipl_x1,x
    sta co_x,x
    dex
    bpl _cp0

_intersect
    lda cp_code
    and #CLIP_BOTTOM
    beq _not_bottom
    lda clip_ymax
    sta cp_b
    lda clip_ymax+1
    sta cp_b+1
    jsr clip_cross_y
    bra _store
_not_bottom
    lda cp_code
    and #CLIP_TOP
    beq _not_top
    lda clip_ymin
    sta cp_b
    lda clip_ymin+1
    sta cp_b+1
    jsr clip_cross_y
    bra _store
_not_top
    lda cp_code
    and #CLIP_RIGHT
    beq _not_right
    lda clip_xmax
    sta cp_b
    lda clip_xmax+1
    sta cp_b+1
    jsr clip_cross_x
    bra _store
_not_right
    lda clip_xmin
    sta cp_b
    lda clip_xmin+1
    sta cp_b+1
    jsr clip_cross_x

_store
    ; write the moved endpoint back and go around again
    lda cp_which
    bne _st1
    ldx #3
_sb0
    lda cw_x,x
    sta clipl_x0,x
    dex
    bpl _sb0
    jmp _loop
_st1
    ldx #3
_sb1
    lda cw_x,x
    sta clipl_x1,x
    dex
    bpl _sb1
    jmp _loop

_accept
    lda clipl_x0                ; load the drawers' parameter block
    sta X16_P0
    lda clipl_x0+1
    sta X16_P1
    lda clipl_y0
    sta X16_P2
    lda clipl_x1
    sta X16_P3
    lda clipl_x1+1
    sta X16_P4
    lda clipl_y1
    sta X16_P5
    clc
    rts

; --- outcodes ---------------------------------------------------------
; A = outcode of (clipl_x0, clipl_y0) / (clipl_x1, clipl_y1)
clip_oc0
    ldx #0                      ; offset of endpoint 0's fields
    bra clip_outcode
clip_oc1
    ldx #4
clip_outcode
    stz cp_oc
    ; x < xmin?
    lda clipl_x0,x
    cmp clip_xmin
    lda clipl_x0+1,x
    sbc clip_xmin+1
    bvc _ocx1
    eor #$80
_ocx1
    bpl _ocx2                   ; x >= xmin
    lda #CLIP_LEFT
    tsb cp_oc
    bra _ocy                    ; can't also be right of xmax
_ocx2
    ; xmax < x?
    lda clip_xmax
    cmp clipl_x0,x
    lda clip_xmax+1
    sbc clipl_x0+1,x
    bvc _ocx3
    eor #$80
_ocx3
    bpl _ocy
    lda #CLIP_RIGHT
    tsb cp_oc
_ocy
    ; y < ymin?
    lda clipl_y0,x
    cmp clip_ymin
    lda clipl_y0+1,x
    sbc clip_ymin+1
    bvc _ocy1
    eor #$80
_ocy1
    bpl _ocy2
    lda #CLIP_TOP
    tsb cp_oc
    bra _ocdone
_ocy2
    ; ymax < y?
    lda clip_ymax
    cmp clipl_y0,x
    lda clip_ymax+1
    sbc clipl_y0+1,x
    bvc _ocy3
    eor #$80
_ocy3
    bpl _ocdone
    lda #CLIP_BOTTOM
    tsb cp_oc
_ocdone
    lda cp_oc
    rts

; --- intersections ----------------------------------------------------
; Move the work endpoint onto the horizontal boundary cp_b:
;   cw_x += (co_x - cw_x) * (cp_b - cw_y) / (co_y - cw_y);  cw_y = cp_b
clip_cross_y
    sec                         ; numerator 1: dx = co_x - cw_x
    lda co_x
    sbc cw_x
    sta cp_m1
    lda co_x+1
    sbc cw_x+1
    sta cp_m1+1
    sec                         ; numerator 2: cp_b - cw_y
    lda cp_b
    sbc cw_y
    sta cp_m2
    lda cp_b+1
    sbc cw_y+1
    sta cp_m2+1
    sec                         ; denominator: dy = co_y - cw_y
    lda co_y
    sbc cw_y
    sta cp_m3
    lda co_y+1
    sbc cw_y+1
    sta cp_m3+1
    jsr clip_muldiv                 ; cp_q = m1 * m2 / m3, signed
    clc
    lda cw_x
    adc cp_q
    sta cw_x
    lda cw_x+1
    adc cp_q+1
    sta cw_x+1
    lda cp_b
    sta cw_y
    lda cp_b+1
    sta cw_y+1
    rts

; Move the work endpoint onto the vertical boundary cp_b:
;   cw_y += (co_y - cw_y) * (cp_b - cw_x) / (co_x - cw_x);  cw_x = cp_b
clip_cross_x
    sec
    lda co_y
    sbc cw_y
    sta cp_m1
    lda co_y+1
    sbc cw_y+1
    sta cp_m1+1
    sec
    lda cp_b
    sbc cw_x
    sta cp_m2
    lda cp_b+1
    sbc cw_x+1
    sta cp_m2+1
    sec
    lda co_x
    sbc cw_x
    sta cp_m3
    lda co_x+1
    sbc cw_x+1
    sta cp_m3+1
    jsr clip_muldiv
    clc
    lda cw_y
    adc cp_q
    sta cw_y
    lda cw_y+1
    adc cp_q+1
    sta cw_y+1
    lda cp_b
    sta cw_x
    lda cp_b+1
    sta cw_x+1
    rts

; cp_q = (cp_m1 * cp_m2) / cp_m3, all signed 16-bit. With inputs
; within +/-4095 the product fits 24 bits and the quotient 16.
clip_muldiv
    stz cp_sgn
    lda cp_m1+1                 ; strip the three signs
    bpl _m1p
    inc cp_sgn
    jsr clip_neg1
_m1p
    lda cp_m2+1
    bpl _m2p
    inc cp_sgn
    sec
    lda #0
    sbc cp_m2
    sta cp_m2
    lda #0
    sbc cp_m2+1
    sta cp_m2+1
_m2p
    lda cp_m3+1
    bpl _m3p
    inc cp_sgn
    sec
    lda #0
    sbc cp_m3
    sta cp_m3
    lda #0
    sbc cp_m3+1
    sta cp_m3+1
_m3p
    ; 16x16 -> 32 shift-add multiply: prod = m1 * m2 (umul16's shape,
    ; with the adc carry rolling down through the rotate)
    stz cp_prod+2
    stz cp_prod+3
    ldx #16
_mul
    lsr cp_m2+1
    ror cp_m2
    bcc _noadd
    lda cp_prod+2
    clc
    adc cp_m1
    sta cp_prod+2
    lda cp_prod+3
    adc cp_m1+1
    bra _rot
_noadd
    lda cp_prod+3               ; carry is already clear
_rot
    ror
    sta cp_prod+3
    ror cp_prod+2
    ror cp_prod+1
    ror cp_prod
    dex
    bne _mul

    ; 32 / 16 restoring divide: quotient into cp_prod
    stz cp_rem
    stz cp_rem+1
    ldx #32
_div
    asl cp_prod
    rol cp_prod+1
    rol cp_prod+2
    rol cp_prod+3
    rol cp_rem
    rol cp_rem+1
    sec
    lda cp_rem
    sbc cp_m3
    tay
    lda cp_rem+1
    sbc cp_m3+1
    bcc _nofit
    sta cp_rem+1
    sty cp_rem
    inc cp_prod
_nofit
    dex
    bne _div

    lda cp_prod
    sta cp_q
    lda cp_prod+1
    sta cp_q+1
    lda cp_sgn                  ; odd number of negatives: negate
    lsr
    bcc _posq
    sec
    lda #0
    sbc cp_q
    sta cp_q
    lda #0
    sbc cp_q+1
    sta cp_q+1
_posq
    rts

clip_neg1
    sec
    lda #0
    sbc cp_m1
    sta cp_m1
    lda #0
    sbc cp_m1+1
    sta cp_m1+1
    rts

; the work endpoint (being moved) and the opposite (fixed) endpoint --
; kept as x,y word pairs so indexed 4-byte copies can move them
cw_x .word 0
cw_y .word 0
co_x .word 0
co_y .word 0

cp_c0    .byte 0
cp_c1    .byte 0
cp_code  .byte 0
cp_which .byte 0
cp_oc    .byte 0
cp_b     .word 0
cp_m1    .word 0
cp_m2    .word 0
cp_m3    .word 0
cp_q     .word 0
cp_sgn   .byte 0
cp_prod  .fill 4, 0
cp_rem   .word 0

; (end zone)
.endif
.if xuse_buffers
; --- inline util/buffers.asm ---
;ACME
; =====================================================================
; x16lib :: util/buffers.asm -- byte ring buffer and byte stack
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The two structures an input queue and an audio refiller keep
; reinventing. One static instance of each, 256 bytes of storage,
; 8-bit indices so wrap-around is free. Capacity is 255 (a count byte
; distinguishes full from empty).
;
; Single-producer/single-consumer safe across an interrupt boundary is
; NOT promised: put and get both touch the count. If one side runs in
; an IRQ, wrap the other side's call in php/sei/plp.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; rb_init  -- empty the ring buffer
; rb_put   -- in: A = byte.  carry set = full, byte not stored
; rb_get   -- out: A = byte. carry set = empty
; rb_count -- out: A = bytes queued (Z reflects it)
; rb_put/rb_get preserve X and Y.
; ---------------------------------------------------------------------
rb_init
    stz rb_head
    stz rb_tail
    stz rb_len
    rts

rb_put
    pha
    lda rb_len
    cmp #255
    bcs _full
    pla
    phx
    ldx rb_head
    sta rb_data,x
    inc rb_head
    inc rb_len
    plx
    clc
    rts
_full
    pla
    sec
    rts

rb_get
    lda rb_len
    beq _empty
    phx
    ldx rb_tail
    lda rb_data,x
    inc rb_tail
    dec rb_len
    plx
    clc
    rts
_empty
    sec
    rts

rb_count
    lda rb_len
    rts

; ---------------------------------------------------------------------
; stk_init  -- empty the stack
; stk_push  -- in: A = byte.  carry set = full (255 deep)
; stk_pop   -- out: A = byte. carry set = empty
; stk_depth -- out: A = bytes stacked
; stk_push/stk_pop preserve X and Y.
; ---------------------------------------------------------------------
stk_init
    stz stk_sp
    rts

stk_push
    pha
    lda stk_sp
    cmp #255
    bcs _full
    pla
    phx
    ldx stk_sp
    sta stk_data,x
    inc stk_sp
    plx
    clc
    rts
_full
    pla
    sec
    rts

stk_pop
    lda stk_sp
    beq _empty
    phx
    dec stk_sp
    ldx stk_sp
    lda stk_data,x
    plx
    clc
    rts
_empty
    sec
    rts

stk_depth
    lda stk_sp
    rts

rb_head  .byte 0
rb_tail  .byte 0
rb_len   .byte 0
rb_data  .fill 256, 0
stk_sp   .byte 0
stk_data .fill 256, 0

; (end zone)
.endif
.if xuse_adpcm
; --- inline audio/adpcm.asm ---
;ACME
; =====================================================================
; x16lib :: audio/adpcm.asm -- IMA ADPCM decoding (4:1 compression)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The natural partner to the PCM streamer: IMA ADPCM stores 16-bit
; samples as 4-bit deltas, so a second of 16-bit mono at 16 kHz is
; 8 KB instead of 32 -- one RAM bank per second, streamable from disk.
;
; This is the canonical IMA/DVI algorithm (the one in WAV files, with
; the LOW nibble of each byte first). Decoder state is exposed:
; adpcm_pred and adpcm_index -- IMA WAV block headers carry initial
; values for both; store them before decoding a block's payload.
;
;       jsr adpcm_init              ; predictor 0, index 0
;       ...set X16_P0..P5...
;       jsr adpcm_block             ; n bytes in -> 2n samples out
; =====================================================================

; (zone: file scope in 64tass)

adpcm_pred  .word 0             ; the predictor (signed 16-bit sample)
adpcm_index .byte 0             ; step table index 0-88

; ---------------------------------------------------------------------
; adpcm_init -- reset the decoder (predictor 0, step index 0)
; ---------------------------------------------------------------------
adpcm_init
    stz adpcm_pred
    stz adpcm_pred+1
    stz adpcm_index
    rts

; ---------------------------------------------------------------------
; adpcm_nibble -- decode one 4-bit code
;   in:  A = the code (0-15)
;   out: A = sample low, X = sample high (signed 16-bit; also left in
;        adpcm_pred). Clobbers Y.
; ---------------------------------------------------------------------
adpcm_nibble
    sta ad_n
    lda adpcm_index             ; step = steptab[index]
    asl
    tay
    lda adpcm_steps,y
    sta ad_sh
    lda adpcm_steps+1,y
    sta ad_sh+1

    ; diff = step>>3 (+ step if bit2) (+ step>>1 if bit1) (+ step>>2
    ; if bit0); max 1.875 * 32767 = 61436, which fits 16 bits unsigned
    stz ad_diff
    stz ad_diff+1
    lda ad_n
    and #4
    beq _no4
    lda ad_sh
    sta ad_diff
    lda ad_sh+1
    sta ad_diff+1
_no4
    lsr ad_sh+1
    ror ad_sh
    lda ad_n
    and #2
    beq _no2
    jsr adpcm_add_sh
_no2
    lsr ad_sh+1
    ror ad_sh
    lda ad_n
    and #1
    beq _no1
    jsr adpcm_add_sh
_no1
    lsr ad_sh+1
    ror ad_sh
    jsr adpcm_add_sh                 ; the unconditional step>>3

    ; predictor +/- diff, in 24 bits, saturated to 16
    lda adpcm_pred              ; sign-extend the predictor
    sta ad_p
    lda adpcm_pred+1
    sta ad_p+1
    stz ad_p+2
    bpl _ext_ok
    dec ad_p+2                  ; $FF
_ext_ok
    lda ad_n
    and #8
    bne _minus
    clc
    lda ad_p
    adc ad_diff
    sta ad_p
    lda ad_p+1
    adc ad_diff+1
    sta ad_p+1
    lda ad_p+2
    adc #0
    sta ad_p+2
    bra _clamp
_minus
    sec
    lda ad_p
    sbc ad_diff
    sta ad_p
    lda ad_p+1
    sbc ad_diff+1
    sta ad_p+1
    lda ad_p+2
    sbc #0
    sta ad_p+2

_clamp
    ; a legal 16-bit value has p+2 = $00 with p+1 bit7 clear, or
    ; p+2 = $FF with p+1 bit7 set; anything else saturates
    lda ad_p+2
    beq _maybe_pos
    cmp #$FF
    beq _maybe_neg
    bra _sat                    ; way out of range
_maybe_pos
    lda ad_p+1
    bpl _in_range
    bra _sat_pos
_maybe_neg
    lda ad_p+1
    bmi _in_range
    bra _sat_neg
_sat
    lda ad_p+2
    bmi _sat_neg
_sat_pos
    lda #$FF
    sta ad_p
    lda #$7F
    sta ad_p+1
    bra _in_range
_sat_neg
    stz ad_p
    lda #$80
    sta ad_p+1
_in_range
    lda ad_p
    sta adpcm_pred
    lda ad_p+1
    sta adpcm_pred+1

    ; index += indextab[n & 7], clamped to 0..88
    lda ad_n
    and #7
    tay
    lda adpcm_index
    clc
    adc adpcm_idxtab,y
    bpl _not_neg
    lda #0
_not_neg
    cmp #89
    bcc _idx_ok
    lda #88
_idx_ok
    sta adpcm_index

    lda adpcm_pred
    ldx adpcm_pred+1
    rts

adpcm_add_sh
    clc
    lda ad_diff
    adc ad_sh
    sta ad_diff
    lda ad_diff+1
    adc ad_sh+1
    sta ad_diff+1
    rts

; ---------------------------------------------------------------------
; adpcm_block -- decode a run of bytes to 16-bit little-endian samples
;   in:  X16_P0/P1 = source (ADPCM bytes)
;        X16_P2/P3 = destination (4 bytes out per byte in)
;        X16_P4/P5 = SOURCE byte count
;
; Low nibble first, as in IMA WAV blocks. The parameter block is
; consumed (pointers advance). Decoder state carries across calls, so
; feeding a block in slices is fine.
; ---------------------------------------------------------------------
adpcm_block
_loop
    lda X16_P4
    ora X16_P5
    beq _done

    ldy #0
    lda (X16_P0),y
    pha
    and #$0F                    ; low nibble first
    jsr adpcm_emit
    pla
    lsr
    lsr
    lsr
    lsr
    jsr adpcm_emit

    inc X16_P0
    bne _next
    inc X16_P1
_next
    lda X16_P4
    bne _declo
    dec X16_P5
_declo
    dec X16_P4
    bra _loop
_done
    rts

; decode nibble A, append the sample to the output pointer
adpcm_emit
    jsr adpcm_nibble
    ldy #0
    sta (X16_P2),y
    txa
    iny
    sta (X16_P2),y
    clc
    lda X16_P2
    adc #2
    sta X16_P2
    bcc _ok
    inc X16_P3
_ok
    rts

ad_n    .byte 0
ad_sh   .word 0
ad_diff .word 0
ad_p    .fill 3, 0

adpcm_idxtab
    .byte $FF, $FF, $FF, $FF, 2, 4, 6, 8

adpcm_steps
    .word 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31
    .word 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143
    .word 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658
    .word 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024
    .word 3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899
    .word 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767

; (end zone)
.endif
.if xuse_wav
; --- inline audio/wavfile.asm ---
;ACME
; =====================================================================
; x16lib :: audio/wavfile.asm -- parse a WAV/RIFF header
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; wav_parse_header reads a RIFF/WAVE header from a memory buffer and
; publishes the PCM format, so the caller can hand the numbers to the
; PCM streamer and stream the sample data that follows. Parsing the
; small header from RAM keeps this independent of how the file is read
; (LOAD, MACPTR, a bank, ...); the caller streams the bulk data itself.
;
; WAV layout:  "RIFF" <size> "WAVE"  then 8-byte-headed chunks; the
; "fmt " chunk carries the format, the "data" chunk the samples.
; =====================================================================

; (zone: file scope in 64tass)

wav_format   .byte 0           ; audio format code (1 = PCM)
wav_channels .byte 0           ; channel count
wav_rate     .fill 4, 0        ; sample rate, little-endian
wav_bits     .byte 0           ; bits per sample
wav_data_off .word 0           ; byte offset of the sample data in the buffer
wav_data_len .fill 4, 0        ; sample-data length in bytes

wavfile_cur
    .word 0                   ; current chunk offset from the buffer base
wavfile_sz
    .fill 4, 0                ; current chunk size
wavfile_adv
    .word 0                   ; bytes to advance to the next chunk
wavfile_fmt
    .byte 0                   ; have we seen a fmt chunk yet?

; ---------------------------------------------------------------------
; wav_parse_header -- parse a WAV header from a buffer
;   in:  X16_P0/P1 = pointer to the header bytes (consumed as a walking
;        pointer; the buffer must hold everything up to the data chunk)
;   out: carry clear on success, with wav_format/channels/rate/bits and
;        wav_data_off/wav_data_len filled in; carry set if the buffer is
;        not RIFF/WAVE or has no fmt+data chunks.
; ---------------------------------------------------------------------
wav_parse_header
    bra wavfile_begin
wavfile_bad
    sec
    rts
wavfile_begin
    ldy #0                     ; "RIFF"
    lda (X16_P0),y
    cmp #'R'
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'I'
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'F'
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'F'
    bne wavfile_bad
    ldy #8                     ; "WAVE"
    lda (X16_P0),y
    cmp #'W'
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'A'
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'V'
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'E'
    bne wavfile_bad

    stz wavfile_fmt
    lda #12                    ; first chunk starts at offset 12
    sta wavfile_cur
    stz wavfile_cur+1
    lda X16_P0
    clc
    adc #12
    sta X16_P0
    lda X16_P1
    adc #0
    sta X16_P1

wavfile_chunk
    ldy #0                     ; "fmt " ?
    lda (X16_P0),y
    cmp #'f'
    bne wavfile_not_fmt
    iny
    lda (X16_P0),y
    cmp #'m'
    bne wavfile_not_fmt
    iny
    lda (X16_P0),y
    cmp #'t'
    bne wavfile_not_fmt
    iny
    lda (X16_P0),y
    cmp #' '
    bne wavfile_not_fmt
    ; fmt chunk body starts at +8
    ldy #8
    lda (X16_P0),y
    sta wav_format
    ldy #10
    lda (X16_P0),y
    sta wav_channels
    ldy #12
    lda (X16_P0),y
    sta wav_rate
    iny
    lda (X16_P0),y
    sta wav_rate+1
    iny
    lda (X16_P0),y
    sta wav_rate+2
    iny
    lda (X16_P0),y
    sta wav_rate+3
    ldy #22
    lda (X16_P0),y
    sta wav_bits
    inc wavfile_fmt
    bra wavfile_advance

wavfile_not_fmt
    ldy #0                     ; "data" ?
    lda (X16_P0),y
    cmp #'d'
    bne wavfile_advance
    iny
    lda (X16_P0),y
    cmp #'a'
    bne wavfile_advance
    iny
    lda (X16_P0),y
    cmp #'t'
    bne wavfile_advance
    iny
    lda (X16_P0),y
    cmp #'a'
    bne wavfile_advance
    ; data chunk: length at +4, sample data at +8
    ldy #4
    lda (X16_P0),y
    sta wav_data_len
    iny
    lda (X16_P0),y
    sta wav_data_len+1
    iny
    lda (X16_P0),y
    sta wav_data_len+2
    iny
    lda (X16_P0),y
    sta wav_data_len+3
    lda wavfile_cur
    clc
    adc #8
    sta wav_data_off
    lda wavfile_cur+1
    adc #0
    sta wav_data_off+1
    lda wavfile_fmt                   ; a data chunk before fmt is malformed
    bne wavfile_datok
    jmp wavfile_bad
wavfile_datok
    clc
    rts

wavfile_advance
    ldy #4                     ; chunk size (32-bit; header chunks are small)
    lda (X16_P0),y
    sta wavfile_sz
    iny
    lda (X16_P0),y
    sta wavfile_sz+1
    iny
    lda (X16_P0),y
    sta wavfile_sz+2
    iny
    lda (X16_P0),y
    sta wavfile_sz+3
    lda wavfile_sz                    ; pad an odd size up to even
    and #1
    beq wavfile_even
    inc wavfile_sz
    bne wavfile_even
    inc wavfile_sz+1
wavfile_even
    lda wavfile_sz                    ; adv = 8 + size (16-bit is plenty pre-data)
    clc
    adc #8
    sta wavfile_adv
    lda wavfile_sz+1
    adc #0
    sta wavfile_adv+1
    lda X16_P0                 ; walk the pointer and the offset
    clc
    adc wavfile_adv
    sta X16_P0
    lda X16_P1
    adc wavfile_adv+1
    sta X16_P1
    lda wavfile_cur
    clc
    adc wavfile_adv
    sta wavfile_cur
    lda wavfile_cur+1
    adc wavfile_adv+1
    sta wavfile_cur+1
    lda wavfile_cur+1                 ; bail if we walk past a sane header size
    cmp #4                     ; ~1 KB of chunks without a data: give up
    bcc wavfile_more
    jmp wavfile_bad
wavfile_more
    jmp wavfile_chunk

; (end zone)
.endif
.if xuse_zx0
; --- inline util/zx0.asm ---
;ACME
; =====================================================================
; x16lib :: util/zx0.asm -- ZX0 decompression (Einar Saukas's format)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The ROM's LZSA2 (mem_decompress) is free and fast; ZX0 packs
; tighter. This decodes the MODERN ZX0 v2 stream -- what `zx0` and
; `salvador` emit by default (not their -classic mode).
;
;       salvador data.bin data.zx0
;
;       lda #<data_zx0 : sta X16_P0 : lda #>data_zx0 : sta X16_P1
;       lda #<dest     : sta X16_P2 : lda #>dest     : sta X16_P3
;       jsr zx0_decompress          ; A/X = one past the last byte
;
; RAM to RAM only (the match copier reads the output back). Cannot
; decompress in place. Ported from the reference dzx0.c: three states
; (literals / repeat last offset / new offset), interlaced Elias gamma
; lengths, and the offset byte's low bit seeding the next length.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; zx0_decompress
;   in:  X16_P0/P1 = compressed data, X16_P2/P3 = output address
;   out: A/X = one past the last output byte
;        (X16_P0..P3 are consumed; X16_T6/T7 used as the copy pointer)
; ---------------------------------------------------------------------
zx0_decompress
    stz zx_bits                 ; empty bit buffer: first use refills
    stz zx_bt
    lda #1                      ; the initial offset is 1
    sta zx_off
    stz zx_off+1

_literals
    jsr zx0_gamma_n                ; literal run length
_lit_byte
    jsr zx0_getbyte
    sta (X16_P2)
    inc X16_P2
    bne _lit_dec
    inc X16_P3
_lit_dec
    jsr zx0_dec_len
    bne _lit_byte

    jsr zx0_getbit
    bcs _new_offset

_last_offset
    jsr zx0_gamma_n                ; match length, offset unchanged
    jsr zx0_copy
    jsr zx0_getbit
    bcc _literals

_new_offset
    jsr zx0_gamma_i                ; the offset MSB, inverted gamma (v2)
    lda zx_val+1                ; 256 is the end-of-stream marker
    beq _not_end
    lda zx_val
    bne _not_end
    lda X16_P2                  ; done: hand back the output end
    ldx X16_P3
    rts
_not_end
    lda zx_val                  ; offset = MSB*128 - (next byte >> 1)
    lsr
    sta zx_off+1
    lda #0
    ror
    sta zx_off
    jsr zx0_getbyte                ; ...which also latches zx_last
    lsr
    sta zx_t
    sec
    lda zx_off
    sbc zx_t
    sta zx_off
    lda zx_off+1
    sbc #0
    sta zx_off+1
    lda #1                      ; that byte's low bit is the FIRST bit
    sta zx_bt                   ; of the coming length gamma
    jsr zx0_gamma_n
    inc zx_val                  ; new-offset match lengths are +1
    bne _len_ok
    inc zx_val+1
_len_ok
    jsr zx0_copy
    jsr zx0_getbit
    bcs _new_offset
    bra _literals

; --- plumbing ---------------------------------------------------------

; copy zx_val bytes from (output - zx_off) to the output
zx0_copy
    sec
    lda X16_P2
    sbc zx_off
    sta X16_T6
    lda X16_P3
    sbc zx_off+1
    sta X16_T7
_byte
    lda (X16_T6)
    sta (X16_P2)
    inc X16_T6
    bne _dst
    inc X16_T7
_dst
    inc X16_P2
    bne _count
    inc X16_P3
_count
    jsr zx0_dec_len
    bne _byte
    rts

; zx_val -= 1; Z set when it reaches zero (val >= 1 on entry)
zx0_dec_len
    lda zx_val
    bne _lo
    dec zx_val+1
_lo
    dec zx_val
    lda zx_val
    ora zx_val+1
    rts

; interlaced Elias gamma into zx_val: normal and inverted data bits
zx0_gamma_i
    lda #1
    bra zx0_gamma
zx0_gamma_n
    lda #0
zx0_gamma
    sta zx_inv
    lda #1
    sta zx_val
    stz zx_val+1
_more
    jsr zx0_getbit
    bcs _done                   ; a 1 control bit ends the number
    jsr zx0_getbit
    lda #0
    rol                         ; A = the data bit
    eor zx_inv
    lsr                         ; ...back into the carry
    rol zx_val
    rol zx_val+1
    bra _more
_done
    rts

; next bit into the carry. The buffer keeps a sentinel 1 in bit 0, so
; a zero buffer after the shift means "that carry was the sentinel":
; refill and take bit 7 of the fresh byte instead.
zx0_getbit
    lda zx_bt
    beq _stream
    stz zx_bt                   ; backtrack: the offset byte's low bit
    lda zx_last
    lsr
    rts
_stream
    asl zx_bits
    beq _refill
    rts
_refill
    jsr zx0_getbyte
    sec
    rol                         ; carry = bit 7, sentinel into bit 0
    sta zx_bits
    rts

zx0_getbyte
    lda (X16_P0)
    sta zx_last
    inc X16_P0
    bne _gb_ok
    inc X16_P1
_gb_ok
    lda zx_last
    rts

zx_bits .byte 0
zx_last .byte 0
zx_bt   .byte 0
zx_inv  .byte 0
zx_val  .word 0
zx_off  .word 0
zx_t    .byte 0

; (end zone)
.endif
.if xuse_tsc
; --- inline util/tscrunch.asm ---
;ACME
; =====================================================================
; x16lib :: util/tscrunch.asm -- TSCrunch decompression
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; TSCrunch (Antonio Savona) is a byte-aligned LZ+RLE built to maximise
; 6502 DECODE SPEED -- the other end of the trade from ZX0: unpacks
; markedly faster, packs a little looser. Crunch with:
;
;       tscrunch data.bin data.tsc        (plain memory crunch)
;
; This is a 65C02 port of the reference decrunch_small.asm: the
; original leans on the NMOS undocumented opcodes LAX and ALR, which
; the X16's 65C02 does not have -- they are replaced with legal pairs,
; everything else (including the load-bearing carry choreography) is
; kept move for move. Copyright for the original algorithm and
; decruncher: Antonio Savona.
;
;       lda #<data_tsc : sta X16_P0 : lda #>data_tsc : sta X16_P1
;       lda #<dest     : sta X16_P2 : lda #>dest     : sta X16_P3
;       jsr tsc_decompress          ; A/X = one past the last byte
;
; RAM to RAM, forward only, cannot decompress in place.
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; tsc_decompress
;   in:  X16_P0/P1 = compressed data, X16_P2/P3 = output address
;   out: A/X = one past the last output byte
;        (X16_P0..P3 consumed; X16_T5..T7 used as scratch)
; ---------------------------------------------------------------------
tsc_decompress
    ldy #0
    lda (X16_P0),y              ; the stream's first byte parameterises
    sta tscrunch_optlen+1               ; the one-token zero-run length
    inc X16_P0
    bne tsc2_entry
    inc X16_P1

tsc2_entry
    lda (X16_P0),y              ; (LAX) token
    tax
    bmi tsc2_rleorlz

    cmp #$20
    bcs tsc2_lz2

    ; --- literal: token = count, the bytes follow ---------------------
    tay
tsc2_lit
    lda (X16_P0),y
    dey
    sta (X16_P2),y
    bne tsc2_lit
    txa                         ; carry is clear (cmp #$20 fell through)
    inx
tsc2_bump_zp
    adc X16_P2                  ; output += A (+ inherited carry)
    sta X16_P2
    bcs tsc2_put_hi
tsc2_put_ok
    txa
tsc2_bump_get
    adc X16_P0                  ; input += X
    sta X16_P0
    bcc tsc2_entry
    inc X16_P1
    bcs tsc2_entry

tsc2_put_hi
    inc X16_P3
    clc
    bcc tsc2_put_ok

    ; --- RLE or LZ (token bit 7 set) -----------------------------------
tsc2_rleorlz
    and #$7F                    ; (ALR #$7F)
    lsr
    bcc tsc2_lz

    ; RLE: A = length field, carry is set for the +1 in tsc2_bump_zp
    beq tsc2_optrun
    ldx #2
    iny
    sta X16_T5                  ; run length
    lda (X16_P0),y              ; the byte to repeat
    ldy X16_T5
tsc2_run_start
    sta (X16_P2),y
tsc2_rle_loop
    dey
    sta (X16_P2),y
    bne tsc2_rle_loop
    lda X16_T5
    bcs tsc2_bump_zp                ; always (carry survived untouched)

tsc2_done
    lda X16_P2                  ; the end of the output
    ldx X16_P3
    rts

    ; --- LZ2: a two-byte match with a one-byte token -------------------
tsc2_lz2
    beq tsc2_done                   ; $20 is the end-of-stream marker
    ora #$80                    ; carry is set: offset folds negative
    adc X16_P2
    sta X16_T6
    lda X16_P3
    sbc #$00
    sta X16_T7
    lda (X16_T6),y              ; y = 0
    sta (X16_P2),y
    iny
    lda (X16_T6),y
    sta (X16_P2),y
    tya                         ; A = 1
    tax                         ; X = 1
    dey                         ; Y = 0
    beq tsc2_bump_zp                ; always; carry set: output += 2

    ; --- LZ match ------------------------------------------------------
tsc2_lz
    lsr                         ; carry: short (1) or long (0) offset
    sta tsc2_lzto+1                 ; length - 1
    iny
    lda X16_P2
    bcc tsc2_long
    sbc (X16_P0),y              ; carry set: back = output - offset
    sta X16_T6
    lda X16_P3
    sbc #$00
    ldx #2
tsc2_lz_put
    sta X16_T7
    ldy #0
    lda (X16_T6),y              ; matches MUST copy forward
    sta (X16_P2),y
tsc2_lz_loop
    iny
    lda (X16_T6),y
    sta (X16_P2),y
tsc2_lzto
    cpy #0                      ; operand = length - 1 (self-modified)
    bne tsc2_lz_loop
    tya
    ldy #0
    bcs tsc2_bump_zp                ; cpy equality left the carry set

    ; --- the one-token zero run ----------------------------------------
tsc2_optrun
tscrunch_optlen
    ldy #255                    ; operand = the stream's header byte
    sty X16_T5
    ldx #1                      ; A = 0: a run of zeros
    bne tsc2_run_start

    ; --- long LZ: 15-bit offset, one more length bit --------------------
tsc2_long
    adc (X16_P0),y              ; carry clear, compensated by the encoder
    sta X16_T6
    iny
    lda (X16_P0),y              ; (LAX)
    tax
    ora #$80
    adc X16_P3                  ; the low add's carry ripples in here
    cpx #$80                    ; offset bit 15 doubles as a length bit
    rol tsc2_lzto+1
    ldx #3
    bne tsc2_lz_put                 ; always

; (end zone)
.endif
.if xuse_fixed
; --- inline util/fixed.asm ---
;ACME
; =====================================================================
; x16lib :: util/fixed.asm -- 16x16 multiply and 8.8 fixed point
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; =====================================================================

; (zone: file scope in 64tass)

; Scratch, private to this module.
fx_prod     .byte 0, 0, 0, 0    ; 32-bit product
fx_mcand    .byte 0, 0          ; multiplicand
fx_mplier   .byte 0, 0          ; multiplier (consumed)
fx_sign     .byte 0

; ---------------------------------------------------------------------
; umul16 -- unsigned 16 x 16 -> 32
;   in:  X16_P0/P1 = a, X16_P2/P3 = b
;   out: X16_P4..P7 = product, low byte first
; ---------------------------------------------------------------------
umul16
    lda X16_P0
    sta fx_mcand
    lda X16_P1
    sta fx_mcand+1
    lda X16_P2
    sta fx_mplier
    lda X16_P3
    sta fx_mplier+1

    stz fx_prod+2
    stz fx_prod+3
    ldx #16
_shift
    lsr fx_mplier+1
    ror fx_mplier               ; low bit of the multiplier into carry
    bcc _noadd
    lda fx_prod+2
    clc
    adc fx_mcand
    sta fx_prod+2
    lda fx_prod+3
    adc fx_mcand+1              ; A = new high byte, carry = overflow
    bra _rotate
_noadd
    lda fx_prod+3               ; carry is already clear
_rotate
    ror                         ; carry rolls down through the product
    sta fx_prod+3
    ror fx_prod+2
    ror fx_prod+1
    ror fx_prod
    dex
    bne _shift

    lda fx_prod
    sta X16_P4
    lda fx_prod+1
    sta X16_P5
    lda fx_prod+2
    sta X16_P6
    lda fx_prod+3
    sta X16_P7
    rts

; ---------------------------------------------------------------------
; mul88 -- signed 8.8 fixed-point multiply:  r = (a * b) >> 8
;   in:  X16_P0/P1 = a, X16_P2/P3 = b   (both signed 8.8)
;   out: X16_P0/P1 = r                  (signed 8.8)
;
; Lets sprites move at fractional speeds: hold the position in 8.8, add
; an 8.8 velocity each frame, and take the high byte as the pixel.
;
;   384 ($0180 = 1.5) * 512 ($0200 = 2.0) = 768 ($0300 = 3.0)
; ---------------------------------------------------------------------
mul88
    stz fx_sign

    lda X16_P1                  ; sign of a
    bpl _a_positive
    inc fx_sign
    jsr _negate_a
_a_positive
    lda X16_P3                  ; sign of b
    bpl _b_positive
    inc fx_sign
    jsr _negate_b
_b_positive

    jsr umul16                  ; P4..P7 = |a| * |b|

    lda X16_P5                  ; >> 8 : take bytes 1 and 2
    sta X16_P0
    lda X16_P6
    sta X16_P1

    lda fx_sign
    lsr                         ; odd number of negatives -> negate
    bcc _done
    jsr _negate_a
_done
    rts

_negate_a
    sec
    lda #0
    sbc X16_P0
    sta X16_P0
    lda #0
    sbc X16_P1
    sta X16_P1
    rts

_negate_b
    sec
    lda #0
    sbc X16_P2
    sta X16_P2
    lda #0
    sbc X16_P3
    sta X16_P3
    rts

; (end zone)
.endif
.if xuse_bcd
; --- inline util/bcd.asm ---
;ACME
; =====================================================================
; x16lib :: util/bcd.asm -- packed-BCD (decimal-mode) add and subtract
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Decimal arithmetic through the 65C02's BCD mode, so 8-bit, 16-bit and
; 32-bit packed-BCD values add and subtract the way you read them:
;
;       $0987 + $1111 = $2098          (not the binary $1A98)
;
; Each byte holds two decimal digits, low byte first. The point is to
; skip the costly binary->decimal conversion a game score or clock would
; otherwise need every frame: keep the count in BCD and print its hex
; form, which already reads as decimal.
;
; Values live in named registers, like util/int16.asm and util/int32.asm:
;
;       bcd_a   the accumulator; the add/sub routines overwrite it
;       bcd_b   the operand
;
;       +i32_const bcd_a, $00000987     ; a 4-byte BCD literal reads decimal
;       +i32_const bcd_b, $00001111
;       jsr bcd_add32                   ; bcd_a = $00002098
;
; Signed and unsigned share one routine per width -- decimal ADC/SBC does
; not know the difference, exactly as two's-complement add/sub does not
; in the integer modules. Pick the width; the interpretation is yours.
;
;   bcd_add8/16/32   bcd_a += bcd_b   (8/16/32-bit)
;   bcd_sub8/16/32   bcd_a -= bcd_b
;   bcd_addto        add bcd_b (32-bit) to a value in place, given a pointer
;   bcd_subfrom      subtract bcd_b (32-bit) from a value in place
;
; Add leaves the carry set on overflow past the width; subtract leaves it
; clear on borrow (result went below zero) -- the usual ADC/SBC carry.
;
; INTERRUPTS: these run in decimal mode across the operation. The KERNAL's
; IRQ handler is decimal-safe (it saves and restores the flags and does no
; decimal-sensitive ADC/SBC), so ordinary use is fine. A CUSTOM interrupt
; handler that does its own ADC/SBC must `cld` first, or bracket the call
; in sei/cli -- otherwise it would run those adds in decimal by mistake.
; =====================================================================

; (zone: file scope in 64tass)

bcd_a .byte 0, 0, 0, 0
bcd_b .byte 0, 0, 0, 0

; ---------------------------------------------------------------------
; bcd_add8 / bcd_add16 / bcd_add32 -- bcd_a += bcd_b at that width.
;   out: carry set if the sum overflowed the width
; ---------------------------------------------------------------------
bcd_add8
    sed
    clc
    lda bcd_a
    adc bcd_b
    sta bcd_a
    cld
    rts

bcd_add16
    sed
    clc
    lda bcd_a
    adc bcd_b
    sta bcd_a
    lda bcd_a+1
    adc bcd_b+1
    sta bcd_a+1
    cld
    rts

bcd_add32
    sed
    clc
    ldx #0
    ldy #4
_loop
    lda bcd_a,x
    adc bcd_b,x                 ; carry threads through the loop untouched:
    sta bcd_a,x                 ; inx and dey leave it alone, cpx would not
    inx
    dey
    bne _loop
    cld
    rts

; ---------------------------------------------------------------------
; bcd_sub8 / bcd_sub16 / bcd_sub32 -- bcd_a -= bcd_b at that width.
;   out: carry clear if the result went below zero (borrow)
; ---------------------------------------------------------------------
bcd_sub8
    sed
    sec
    lda bcd_a
    sbc bcd_b
    sta bcd_a
    cld
    rts

bcd_sub16
    sed
    sec
    lda bcd_a
    sbc bcd_b
    sta bcd_a
    lda bcd_a+1
    sbc bcd_b+1
    sta bcd_a+1
    cld
    rts

bcd_sub32
    sed
    sec
    ldx #0
    ldy #4
_loop
    lda bcd_a,x
    sbc bcd_b,x
    sta bcd_a,x
    inx
    dey
    bne _loop
    cld
    rts

; ---------------------------------------------------------------------
; bcd_addto -- add bcd_b (32-bit) to a 4-byte BCD value in place.
;   in:  A = value low, X = value high (pointer to 4 bytes, low first)
;   out: carry set on overflow. Saves copying the value through bcd_a.
; ---------------------------------------------------------------------
bcd_addto
    sta X16_T0
    stx X16_T1
    sed
    clc
    ldy #0
    lda (X16_T0),y
    adc bcd_b
    sta (X16_T0),y
    iny
    lda (X16_T0),y
    adc bcd_b+1
    sta (X16_T0),y
    iny
    lda (X16_T0),y
    adc bcd_b+2
    sta (X16_T0),y
    iny
    lda (X16_T0),y
    adc bcd_b+3
    sta (X16_T0),y
    cld
    rts

; ---------------------------------------------------------------------
; bcd_subfrom -- subtract bcd_b (32-bit) from a 4-byte BCD value in place.
;   in:  A = value low, X = value high (pointer to 4 bytes, low first)
;   out: carry clear on borrow.
; ---------------------------------------------------------------------
bcd_subfrom
    sta X16_T0
    stx X16_T1
    sed
    sec
    ldy #0
    lda (X16_T0),y
    sbc bcd_b
    sta (X16_T0),y
    iny
    lda (X16_T0),y
    sbc bcd_b+1
    sta (X16_T0),y
    iny
    lda (X16_T0),y
    sbc bcd_b+2
    sta (X16_T0),y
    iny
    lda (X16_T0),y
    sbc bcd_b+3
    sta (X16_T0),y
    cld
    rts

; (end zone)
.endif
.if xuse_collide
; --- inline util/collide.asm ---
;ACME
; =====================================================================
; x16lib :: util/collide.asm -- axis-aligned bounding-box overlap
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; collide8 -- do two boxes overlap?
;   in:  X16_P0 = ax, X16_P1 = ay, X16_P2 = aw, X16_P3 = ah
;        X16_P4 = bx, X16_P5 = by, X16_P6 = bw, X16_P7 = bh
;   out: carry set if the boxes overlap, clear otherwise
;
; Coordinates and sizes are unsigned bytes; the edge sums are computed
; in 9 bits so a box may legitimately run past x=255.
;
; Edges that merely touch do NOT overlap: a box at x=0 width 10 and one
; at x=10 are adjacent, not colliding. Overlap on an axis is
;       ax < bx+bw  AND  bx < ax+aw
; and both must hold on x and on y.
; ---------------------------------------------------------------------
; Coordinates fit in a byte, so this cannot describe the right-hand half
; of a 640-wide display. Use collide16 there.
collide8
    ; --- x axis ---
    lda X16_P4
    clc
    adc X16_P6                  ; bx + bw
    bcs _ax_lt                  ; past 255, so ax is certainly less
    cmp X16_P0                  ; carry set if (bx+bw) >= ax
    bcc _apart
    beq _apart                  ; equal means touching, not overlapping
_ax_lt
    lda X16_P0
    clc
    adc X16_P2                  ; ax + aw
    bcs _bx_lt
    cmp X16_P4
    bcc _apart
    beq _apart
_bx_lt

    ; --- y axis ---
    lda X16_P5
    clc
    adc X16_P7                  ; by + bh
    bcs _ay_lt
    cmp X16_P1
    bcc _apart
    beq _apart
_ay_lt
    lda X16_P1
    clc
    adc X16_P3                  ; ay + ah
    bcs _by_lt
    cmp X16_P5
    bcc _apart
    beq _apart
_by_lt

    sec
    rts
_apart
    clc
    rts

; ---------------------------------------------------------------------
; collide16 -- the same test with 16-bit unsigned coordinates and sizes.
;
; Needed for anything positioned in display space: in the default 80x60
; text mode the X16's screen is 640x480, and sprite coordinates are in
; those units. Only screen modes 2, 3 and $80 halve it to 320x240.
;
; Eight 16-bit fields, more than the parameter block holds, so the
; caller writes them directly:
;
;       lda #<x : sta cl_ax : lda #>x : sta cl_ax+1
;       ... cl_ay, cl_aw, cl_ah, cl_bx, cl_by, cl_bw, cl_bh ...
;       jsr collide16
;
;   out: carry set if the boxes overlap
;
; The edge sums are 17-bit, so a box may legitimately run past x=65535.
; Touching edges do not overlap, exactly as in collide8.
; ---------------------------------------------------------------------
collide16
    ; ax < bx + bw ?
    clc
    lda cl_bx
    adc cl_bw
    sta cl_t0
    lda cl_bx+1
    adc cl_bw+1
    sta cl_t1
    bcs _ax_lt                  ; sum overflowed 16 bits: ax is less
    lda cl_ax
    cmp cl_t0
    lda cl_ax+1
    sbc cl_t1
    bcs _apart16                ; ax >= sum, so touching or clear
_ax_lt

    ; bx < ax + aw ?
    clc
    lda cl_ax
    adc cl_aw
    sta cl_t0
    lda cl_ax+1
    adc cl_aw+1
    sta cl_t1
    bcs _bx_lt
    lda cl_bx
    cmp cl_t0
    lda cl_bx+1
    sbc cl_t1
    bcs _apart16
_bx_lt

    ; ay < by + bh ?
    clc
    lda cl_by
    adc cl_bh
    sta cl_t0
    lda cl_by+1
    adc cl_bh+1
    sta cl_t1
    bcs _ay_lt
    lda cl_ay
    cmp cl_t0
    lda cl_ay+1
    sbc cl_t1
    bcs _apart16
_ay_lt

    ; by < ay + ah ?
    clc
    lda cl_ay
    adc cl_ah
    sta cl_t0
    lda cl_ay+1
    adc cl_ah+1
    sta cl_t1
    bcs _by_lt
    lda cl_by
    cmp cl_t0
    lda cl_by+1
    sbc cl_t1
    bcs _apart16
_by_lt

    sec
    rts
_apart16
    clc
    rts

; Box A, box B, and scratch. Written by the caller.
cl_ax .word 0
cl_ay .word 0
cl_aw .word 0
cl_ah .word 0
cl_bx .word 0
cl_by .word 0
cl_bw .word 0
cl_bh .word 0
cl_t0 .byte 0
cl_t1 .byte 0

; (end zone)
.endif
.if xuse_bits
; --- inline util/bits.asm ---
;ACME
; =====================================================================
; x16lib :: util/bits.asm -- bit and nibble helpers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; catnib -- in: A = high nibble, X = low nibble.  out: A = (A<<4)|X
; ---------------------------------------------------------------------
catnib
    and #$0F
    asl
    asl
    asl
    asl
    sta X16_T0
    txa
    and #$0F
    ora X16_T0
    rts

; ---------------------------------------------------------------------
; hinib / lonib -- in: A = byte.  out: A = that nibble, in bits 3:0
; ---------------------------------------------------------------------
hinib
    lsr
    lsr
    lsr
    lsr
    rts

lonib
    and #$0F
    rts

; ---------------------------------------------------------------------
; bit_set / bit_clr -- in: X16_PTR0 = address, A = mask
; bit_put          -- in: X16_PTR0 = address, A = mask,
;                        X != 0 to set, X = 0 to clear
; ---------------------------------------------------------------------
bit_set
    ldy #0
    ora (X16_PTR0),y
    sta (X16_PTR0),y
    rts

bit_clr
    eor #$FF
    ldy #0
    and (X16_PTR0),y
    sta (X16_PTR0),y
    rts

bit_put
    cpx #0
    beq bit_clr
    bra bit_set

; ---------------------------------------------------------------------
; bit_test -- in: X16_PTR0 = address, A = mask
;             out: Z clear if any masked bit is set
; ---------------------------------------------------------------------
bit_test
    ldy #0
    and (X16_PTR0),y
    rts

; (end zone)
.endif
.if xuse_number
; --- inline util/number.asm ---
;ACME
; =====================================================================
; x16lib :: util/number.asm -- number formatting and parsing
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Results land in a shared buffer that the next call overwrites. Copy
; the string out if you need to keep it.
; =====================================================================

; (zone: file scope in 64tass)

num_buf .fill 17, 0            ; enough for 16 binary digits plus a terminator

; ---------------------------------------------------------------------
; u16_to_dec -- unsigned 16-bit to decimal, no leading zeros
;   in:  X16_P0/P1 = value
;   out: A = buffer address low, X = high, Y = length
;        The buffer is NUL-terminated as well, for screen_puts.
;
; Repeated subtraction against a table of powers of ten. Small and
; obvious; a 16-bit divide would not be faster at this size.
; ---------------------------------------------------------------------
; Consumes X16_P0/P1.
u16_to_dec
    stz X16_T2                  ; have we emitted a significant digit yet?
    stz X16_T4                  ; output length

    ldx #0                      ; index into the power-of-ten table
_digit
    lda #'0'
    sta X16_T3                  ; digit accumulator
_subtract
    sec
    lda X16_P0
    sbc number_pow10_lo,x
    sta X16_T0                  ; tentative low byte
    lda X16_P1
    sbc number_pow10_hi,x
    bcc _next_digit             ; would go negative: this digit is done
    sta X16_P1
    lda X16_T0
    sta X16_P0
    inc X16_T3
    bra _subtract

_next_digit
    lda X16_T3
    cmp #'0'
    bne _emit                   ; a non-zero digit always prints
    lda X16_T2
    bne _emit                   ; already past the leading zeros
    cpx #4
    beq _emit                   ; the units digit always prints
    bra _skip
_emit
    inc X16_T2
    ldy X16_T4
    lda X16_T3
    sta num_buf,y
    iny
    sty X16_T4
_skip
    inx
    cpx #5
    bne _digit

    ldy X16_T4
    lda #0
    sta num_buf,y               ; NUL terminator; Y is now the length

    lda #<num_buf
    ldx #>num_buf
    rts

number_pow10_lo
    .byte <10000, <1000, <100, <10, <1
number_pow10_hi
    .byte >10000, >1000, >100, >10, >1

; ---------------------------------------------------------------------
; u16_to_hex -- unsigned 16-bit to four hex digits
;   in:  X16_P0/P1 = value
;   out: A = buffer low, X = buffer high, Y = 4
; ---------------------------------------------------------------------
u16_to_hex
    lda X16_P1
    jsr number_hi_digit
    sta num_buf
    lda X16_P1
    jsr number_lo_digit
    sta num_buf+1
    lda X16_P0
    jsr number_hi_digit
    sta num_buf+2
    lda X16_P0
    jsr number_lo_digit
    sta num_buf+3
    stz num_buf+4

    lda #<num_buf
    ldx #>num_buf
    ldy #4
    rts

number_hi_digit
    lsr
    lsr
    lsr
    lsr
number_lo_digit
    and #$0F
    cmp #10
    bcs number_letter
    clc
    adc #'0'
    rts
number_letter
    clc
    adc #('A' - 10)
    rts

; ---------------------------------------------------------------------
; dec_to_u16 -- parse decimal digits
;   in:  X16_P0/P1 = string address, X16_P2 = length
;   out: X16_P4/P5 = value, carry set if a non-digit or overflow was found
; ---------------------------------------------------------------------
dec_to_u16
    stz X16_P4
    stz X16_P5
    ldy #0
_loop
    cpy X16_P2
    beq _ok
    lda (X16_P0),y
    sec
    sbc #'0'
    cmp #10
    bcs _bad
    sta X16_T0                  ; the new digit

    ; value = value * 10 + digit
    lda X16_P4
    sta X16_T1
    lda X16_P5
    sta X16_T2                  ; T2:T1 = value
    asl X16_P4
    rol X16_P5                  ; value * 2
    bcs _bad
    asl X16_P4
    rol X16_P5                  ; value * 4
    bcs _bad
    clc
    lda X16_P4
    adc X16_T1
    sta X16_P4
    lda X16_P5
    adc X16_T2
    bcs _bad
    sta X16_P5                  ; value * 5
    asl X16_P4
    rol X16_P5                  ; value * 10
    bcs _bad
    clc
    lda X16_P4
    adc X16_T0
    sta X16_P4
    lda X16_P5
    adc #0
    bcs _bad
    sta X16_P5

    iny
    bra _loop
_ok
    clc
    rts
_bad
    sec
    rts

; ---------------------------------------------------------------------
; u8_to_dec -- unsigned 8-bit to decimal (no leading zeros)
;   in:  A = value      out: A = buf low, X = buf high, Y = length
; ---------------------------------------------------------------------
u8_to_dec
    sta X16_P0
    stz X16_P1
    jmp u16_to_dec

; ---------------------------------------------------------------------
; u8_to_hex -- unsigned 8-bit to two hex digits
;   in:  A = value      out: A = buf low, X = buf high, Y = 2
; ---------------------------------------------------------------------
u8_to_hex
    pha
    jsr number_hi_digit
    sta num_buf
    pla
    jsr number_lo_digit
    sta num_buf+1
    stz num_buf+2
    lda #<num_buf
    ldx #>num_buf
    ldy #2
    rts

; ---------------------------------------------------------------------
; u8_to_bin -- unsigned 8-bit to eight binary digits, MSB first
;   in:  A = value      out: A = buf low, X = buf high, Y = 8
; ---------------------------------------------------------------------
u8_to_bin
    sta X16_T0
    ldy #0
_loop
    asl X16_T0                  ; MSB -> carry
    lda #'0'
    adc #0
    sta num_buf,y
    iny
    cpy #8
    bne _loop
    lda #0
    sta num_buf,y
    lda #<num_buf
    ldx #>num_buf
    ldy #8
    rts

; ---------------------------------------------------------------------
; u16_to_bin -- unsigned 16-bit to sixteen binary digits, MSB first
;   in:  X16_P0/P1 = value (consumed)   out: A/X = buf, Y = 16
; ---------------------------------------------------------------------
u16_to_bin
    ldy #0
_loop
    asl X16_P0
    rol X16_P1                  ; MSB -> carry
    lda #'0'
    adc #0
    sta num_buf,y
    iny
    cpy #16
    bne _loop
    lda #0
    sta num_buf,y
    lda #<num_buf
    ldx #>num_buf
    ldy #16
    rts

; ---------------------------------------------------------------------
; s16_to_dec -- signed 16-bit to decimal, with a leading '-'
;   in:  X16_P0/P1 = value (consumed)   out: A/X = buf, Y = length
; ---------------------------------------------------------------------
s16_to_dec
    lda X16_P1
    bpl _pos
    sec                         ; value = -value
    lda #0
    sbc X16_P0
    sta X16_P0
    lda #0
    sbc X16_P1
    sta X16_P1
    jsr u16_to_dec              ; format the magnitude
    sty X16_T5                  ; length of the digits
    ldx X16_T5
_shift
    lda num_buf,x               ; make room for the sign: shift right by one
    sta num_buf+1,x
    dex
    bpl _shift
    lda #'-'
    sta num_buf
    lda #<num_buf
    ldx #>num_buf
    ldy X16_T5
    iny
    rts
_pos
    jmp u16_to_dec

; ---------------------------------------------------------------------
; s8_to_dec -- signed 8-bit to decimal, with a leading '-'
;   in:  A = value      out: A/X = buf, Y = length
; ---------------------------------------------------------------------
s8_to_dec
    sta X16_P0
    stz X16_P1
    bit X16_P0
    bpl _go
    lda #$FF                    ; sign-extend into the high byte
    sta X16_P1
_go
    jmp s16_to_dec

; (end zone)
.endif
.if xuse_sort
; --- inline util/sort.asm ---
;ACME
; =====================================================================
; x16lib :: util/sort.asm -- in-place sorting of memory blocks
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Sorts a contiguous block of fixed-size elements in place, ascending.
; There is no "array type" -- you pass a base address and an element
; count, which is exactly what a high-level array is underneath.
;
;   sort_u8  / sort_s8   -- byte elements, unsigned / signed
;   sort_u16 / sort_s16  -- word elements, unsigned / signed
;   sort_ptr             -- 2-byte elements ordered by a caller comparator
;
; One insertion-sort engine drives them all through a comparator vector;
; the typed entries just pick the element size and the comparator. O(n`2)
; but tiny and stable -- right for the modest arrays a 6502 sorts.
;
; Comparator ABI (used by sort_ptr, and internally):
;   in:  X16_PTR2 (P4/P5) = address of element A
;        X16_PTR3 (P6/P7) = address of element B
;   out: carry SET if A must sort AFTER B (A > B), clear otherwise.
;   May use A/X/Y; must not disturb the srt_* state.
; =====================================================================

; (zone: file scope in 64tass)

srt_base  .word 0              ; base address of the array
srt_count .word 0              ; element count
srt_size  .byte 0              ; element size in bytes (1 or 2)
srt_cmp   .word 0              ; comparator routine vector
srt_i     .word 0              ; outer index
srt_j     .word 0              ; inner index
srt_key   .fill 2, 0           ; the element being inserted

; ---------------------------------------------------------------------
; public entry points -- in: X16_P0/P1 = base, X16_P2/P3 = count
; ---------------------------------------------------------------------
sort_u8
    ldx #1
    lda #<sort_cmp_u8
    ldy #>sort_cmp_u8
    bra sort_setup
sort_s8
    ldx #1
    lda #<sort_cmp_s8
    ldy #>sort_cmp_s8
    bra sort_setup
sort_u16
    ldx #2
    lda #<sort_cmp_u16
    ldy #>sort_cmp_u16
    bra sort_setup
sort_s16
    ldx #2
    lda #<sort_cmp_s16
    ldy #>sort_cmp_s16
    bra sort_setup

; sort_ptr -- element size 2, comparator address in X16_P4/P5
sort_ptr
    lda X16_P4
    ldy X16_P5
    ldx #2
    ; fall through to sort_setup

sort_setup
    stx srt_size
    sta srt_cmp
    sty srt_cmp+1
    lda X16_P0
    sta srt_base
    lda X16_P1
    sta srt_base+1
    lda X16_P2
    sta srt_count
    lda X16_P3
    sta srt_count+1

    ; nothing to do for fewer than two elements
    lda srt_count+1
    bne sort_start
    lda srt_count
    cmp #2
    bcs sort_start
sort_done
    rts
sort_start
    lda #1                     ; i = 1
    sta srt_i
    stz srt_i+1

sort_outer
    ; while i < count
    lda srt_i+1
    cmp srt_count+1
    bcc sort_body
    bne sort_done
    lda srt_i
    cmp srt_count
    bcs sort_done
sort_body
    ; key = arr[i]
    lda srt_i
    sta X16_T0
    lda srt_i+1
    sta X16_T1
    jsr sort_addr2                 ; P4/P5 = &arr[i]
    jsr sort_load_key

    ; j = i - 1  (i >= 1 so this does not underflow)
    lda srt_i
    sec
    sbc #1
    sta srt_j
    lda srt_i+1
    sbc #0
    sta srt_j+1

sort_inner
    ; P4/P5 = &arr[j],  P6/P7 = &srt_key,  compare
    lda srt_j
    sta X16_T0
    lda srt_j+1
    sta X16_T1
    jsr sort_addr2                 ; P4/P5 = &arr[j]
    lda #<srt_key
    sta X16_P6
    lda #>srt_key
    sta X16_P7
    jsr sort_callcmp               ; carry set if arr[j] > key
    bcc sort_place_jp1

    ; arr[j+1] = arr[j]
    lda srt_j                  ; T0/T1 = j+1
    clc
    adc #1
    sta X16_T0
    lda srt_j+1
    adc #0
    sta X16_T1
    jsr sort_addr3                 ; P6/P7 = &arr[j+1]  (dest; P4/P5 still &arr[j])
    jsr sort_copy_elem

    ; if j == 0, key belongs at arr[0]
    lda srt_j
    ora srt_j+1
    beq sort_place_0

    lda srt_j                  ; j--
    sec
    sbc #1
    sta srt_j
    lda srt_j+1
    sbc #0
    sta srt_j+1
    bra sort_inner

sort_place_0
    stz X16_T0                 ; &arr[0]
    stz X16_T1
    jsr sort_addr3
    jsr sort_store_key
    bra sort_next_i

sort_place_jp1
    lda srt_j                  ; &arr[j+1]
    clc
    adc #1
    sta X16_T0
    lda srt_j+1
    adc #0
    sta X16_T1
    jsr sort_addr3
    jsr sort_store_key

sort_next_i
    inc srt_i
    bne _loop
    inc srt_i+1
_loop
    jmp sort_outer

; --- address arithmetic ----------------------------------------------
; sort_addr2 / sort_addr3 : X16_T0/T1 = index -> P4/P5 (resp. P6/P7) = base+index*size
sort_addr2
    ldx srt_size
    cpx #2
    beq _two
    clc
    lda srt_base
    adc X16_T0
    sta X16_P4
    lda srt_base+1
    adc X16_T1
    sta X16_P5
    rts
_two
    lda X16_T0
    asl
    sta X16_T2
    lda X16_T1
    rol
    sta X16_T3
    clc
    lda srt_base
    adc X16_T2
    sta X16_P4
    lda srt_base+1
    adc X16_T3
    sta X16_P5
    rts

sort_addr3
    ldx srt_size
    cpx #2
    beq _two3
    clc
    lda srt_base
    adc X16_T0
    sta X16_P6
    lda srt_base+1
    adc X16_T1
    sta X16_P7
    rts
_two3
    lda X16_T0
    asl
    sta X16_T2
    lda X16_T1
    rol
    sta X16_T3
    clc
    lda srt_base
    adc X16_T2
    sta X16_P6
    lda srt_base+1
    adc X16_T3
    sta X16_P7
    rts

; --- element moves ---------------------------------------------------
sort_load_key
    ldy #0
    lda (X16_P4),y
    sta srt_key
    ldx srt_size
    cpx #2
    bne _done
    iny
    lda (X16_P4),y
    sta srt_key+1
_done
    rts

sort_store_key
    ldy #0
    lda srt_key
    sta (X16_P6),y
    ldx srt_size
    cpx #2
    bne _done2
    iny
    lda srt_key+1
    sta (X16_P6),y
_done2
    rts

sort_copy_elem
    ldy #0
    lda (X16_P4),y
    sta (X16_P6),y
    ldx srt_size
    cpx #2
    bne _done3
    iny
    lda (X16_P4),y
    sta (X16_P6),y
_done3
    rts

sort_callcmp
    jmp (srt_cmp)

; --- built-in comparators (A at P4/P5, B at P6/P7; C set iff A > B) ----
; Each is self-contained (no far branches to shared exits).
sort_cmp_u8
    ldy #0
    lda (X16_P4),y
    cmp (X16_P6),y             ; C = (A >= B)
    bne _ret                  ; not equal -> C is already (A > B)
    clc                       ; equal -> not greater
_ret
    rts

sort_cmp_s8
    ldy #0
    lda (X16_P4),y
    cmp (X16_P6),y
    beq _eq
    lda (X16_P4),y
    sec
    sbc (X16_P6),y
    bvc _nov
    eor #$80
_nov
    bmi _lt                   ; N set -> A < B
    sec                       ; A > B
    rts
_lt
_eq
    clc
    rts

sort_cmp_u16
    ldy #1
    lda (X16_P4),y            ; high bytes
    cmp (X16_P6),y
    bne _ne                   ; high differs -> C decides
    dey
    lda (X16_P4),y            ; low bytes
    cmp (X16_P6),y
    bne _ne
    clc                       ; fully equal
    rts
_ne
    rts                       ; C = (A > B), since not equal

sort_cmp_s16
    ldy #1
    lda (X16_P4),y
    cmp (X16_P6),y
    bne _hidiff
    dey
    lda (X16_P4),y
    cmp (X16_P6),y            ; hi equal: low bytes decide (same sign)
    bne _lodiff
    clc                       ; fully equal
    rts
_lodiff
    rts                       ; C = (A > B)
_hidiff
    lda (X16_P4),y            ; y=1, signed compare of high bytes
    sec
    sbc (X16_P6),y
    bvc _nov2
    eor #$80
_nov2
    bmi _lt2                  ; A < B
    sec                       ; A > B
    rts
_lt2
    clc
    rts

; (end zone)
.endif
.if xuse_int16
; --- inline util/int16.asm ---
;ACME
; =====================================================================
; x16lib :: util/int16.asm -- 16-bit integer arithmetic
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; Requires X16_USE_NUMBER (i16_to_dec_s builds on u16_to_dec).
;
; The same shape as util/int32.asm, one size down. Values live in named
; two-byte registers the caller writes directly:
;
;       i16_a   the accumulator; most routines read and overwrite it
;       i16_b   the operand
;       i16_r   the remainder left by the divides
;
;       +i16_const i16_a, 1000
;       +i16_const i16_b, 7
;       jsr i16_divmod             ; i16_a = 142, i16_r = 6
;
; Add, subtract, negate, multiply and the left shift are shared between
; signed and unsigned: two's complement makes them identical. Only
; comparison, division, the right shift and decimal output need to know
; which you meant, and those come in pairs.
;
; For the full 32-bit product of two 16-bit values use umul16 in
; util/fixed.asm; i16_mul keeps only the low 16 bits.
; =====================================================================

; (zone: file scope in 64tass)

i16_a .byte 0, 0
i16_b .byte 0, 0
i16_r .byte 0, 0

i16_tmp   .byte 0, 0
i16_rem   .byte 0, 0
i16_cnt   .byte 0
i16_root  .byte 0
i16_sign  .byte 0
i16_qsign .byte 0
i16_rsign .byte 0
i16_buf  .fill 8, 0             ; "-32768" plus a terminator

; ---------------------------------------------------------------------
; i16_from_u8 -- in: A.  i16_a = A, zero-extended
; i16_from_s8 -- in: A.  i16_a = A, sign-extended
; ---------------------------------------------------------------------
i16_from_u8
    sta i16_a
    stz i16_a+1
    rts

i16_from_s8
    sta i16_a
    and #$80
    beq _positive
    lda #$FF
    sta i16_a+1
    rts
_positive
    stz i16_a+1
    rts

; ---------------------------------------------------------------------
; i16_add -- i16_a += i16_b
; i16_sub -- i16_a -= i16_b
; ---------------------------------------------------------------------
i16_add
    clc
    lda i16_a
    adc i16_b
    sta i16_a
    lda i16_a+1
    adc i16_b+1
    sta i16_a+1
    rts

i16_sub
    sec
    lda i16_a
    sbc i16_b
    sta i16_a
    lda i16_a+1
    sbc i16_b+1
    sta i16_a+1
    rts

; ---------------------------------------------------------------------
; i16_neg -- i16_a = -i16_a
; i16_abs -- i16_a = |i16_a|
; ---------------------------------------------------------------------
i16_neg
    sec
    lda #0
    sbc i16_a
    sta i16_a
    lda #0
    sbc i16_a+1
    sta i16_a+1
    rts

i16_abs
    lda i16_a+1
    bmi i16_neg
    rts

; ---------------------------------------------------------------------
; i16_shl -- i16_a <<= 1
; i16_shr -- i16_a >>= 1, logical (zero fill)
; i16_asr -- i16_a >>= 1, arithmetic (sign fill)
; Carry holds the bit shifted out.
; ---------------------------------------------------------------------
i16_shl
    asl i16_a
    rol i16_a+1
    rts

i16_shr
    lsr i16_a+1
    ror i16_a
    rts

i16_asr
    lda i16_a+1
    asl                         ; sign bit into carry
    ror i16_a+1                 ; ...and back in at the top
    ror i16_a
    rts

; ---------------------------------------------------------------------
; i16_cmpu -- unsigned compare i16_a with i16_b
; i16_cmps -- signed compare
;   out: A = $FF if a < b, 0 if equal, 1 if a > b.  Z set when equal.
;        Neither operand is modified.
; ---------------------------------------------------------------------
i16_cmpu
    lda i16_a+1
    cmp i16_b+1
    bne _differ
    lda i16_a
    cmp i16_b
    bne _differ
    lda #0
    rts
_differ
    bcs _greater
    lda #$FF
    rts
_greater
    lda #1
    rts

i16_cmps
    ; Same-signed operands compare like unsigned ones. Different signs
    ; short-circuit: the negative one is smaller, whatever the bits say.
    lda i16_a+1
    eor i16_b+1
    bpl i16_cmpu                ; signs agree
    lda i16_a+1
    bmi _a_negative
    lda #1                      ; a >= 0, b < 0
    rts
_a_negative
    lda #$FF
    rts

; ---------------------------------------------------------------------
; i16_mul -- i16_a = i16_a * i16_b, modulo 2`16
;
; Shift-and-add. Signed and unsigned agree on the low 16 bits, so this
; serves both; only the discarded overflow differs.
; ---------------------------------------------------------------------
i16_mul
    lda i16_a                   ; tmp = a, then rebuild a as the product
    sta i16_tmp
    lda i16_a+1
    sta i16_tmp+1
    stz i16_a
    stz i16_a+1

    lda #16
    sta i16_cnt
_loop
    lsr i16_b+1                 ; next bit of the multiplier
    ror i16_b
    bcc _no_add

    clc                         ; a += tmp
    lda i16_a
    adc i16_tmp
    sta i16_a
    lda i16_a+1
    adc i16_tmp+1
    sta i16_a+1
_no_add
    asl i16_tmp                 ; tmp <<= 1
    rol i16_tmp+1

    dec i16_cnt
    bne _loop
    rts

; ---------------------------------------------------------------------
; i16_divmod -- unsigned:  i16_a = i16_a / i16_b,  i16_r = i16_a % i16_b
;   out: carry set if i16_b was zero, in which case nothing is changed
;
; Restoring division: shift the dividend left through the remainder one
; bit at a time, subtracting the divisor whenever it fits.
; ---------------------------------------------------------------------
i16_divmod
    lda i16_b
    ora i16_b+1
    bne _go
    sec                         ; divide by zero
    rts
_go
    stz i16_r
    stz i16_r+1

    lda #16
    sta i16_cnt
_loop
    asl i16_a                   ; dividend out of the top of a...
    rol i16_a+1
    rol i16_r                   ; ...and into the bottom of r
    rol i16_r+1

    sec                         ; trial subtraction r - b
    lda i16_r
    sbc i16_b
    sta i16_tmp
    lda i16_r+1
    sbc i16_b+1
    sta i16_tmp+1
    bcc _next                   ; did not fit: leave r alone

    lda i16_tmp                 ; it fit: keep the difference
    sta i16_r
    lda i16_tmp+1
    sta i16_r+1
    inc i16_a                   ; and set the quotient bit
_next
    dec i16_cnt
    bne _loop
    clc
    rts

; ---------------------------------------------------------------------
; i16_divmod_s -- signed divide, truncating toward zero
;   i16_a = i16_a / i16_b,  i16_r = i16_a % i16_b
;   out: carry set if i16_b was zero
;
; The quotient's sign is the exclusive-or of the operands' signs; the
; remainder takes the sign of the DIVIDEND, which is what C and Forth's
; SM/REM both do. -7 / 2 is -3 remainder -1, not -4 remainder 1.
; ---------------------------------------------------------------------
; Note: i16_divmod_s leaves i16_b holding |i16_b|.
; -32768 has no positive counterpart, so |a| overflows for that one value.
i16_divmod_s
    lda i16_b
    ora i16_b+1
    bne _go
    sec                         ; divide by zero
    rts
_go
    ; Capture both signs BEFORE taking absolute values, or they are gone.
    lda i16_a+1
    sta i16_rsign               ; remainder follows the dividend
    eor i16_b+1
    sta i16_qsign               ; quotient follows sign(a) xor sign(b)

    jsr i16_abs                 ; |a|

    lda i16_b+1                 ; |b|
    bpl _b_positive
    sec
    lda #0
    sbc i16_b
    sta i16_b
    lda #0
    sbc i16_b+1
    sta i16_b+1
_b_positive

    jsr i16_divmod              ; unsigned |a| / |b|; b is nonzero

    lda i16_rsign
    bpl _quotient
    sec                         ; negate the remainder
    lda #0
    sbc i16_r
    sta i16_r
    lda #0
    sbc i16_r+1
    sta i16_r+1
_quotient
    lda i16_qsign
    bpl _done
    jsr i16_neg
_done
    clc
    rts

; ---------------------------------------------------------------------
; i16_sqrt -- floor(sqrt(i16_a)), the ISQRT of FLOAT.TXT
;   out: A = the root (0..255).  Consumes i16_a.
;
; Digit-by-digit binary square root: two bits of the operand enter the
; remainder each round, and the trial subtrahend is 4*root+1.
; ---------------------------------------------------------------------
i16_sqrt
    stz i16_root
    stz i16_rem
    stz i16_rem+1

    ldx #8
_iter
    asl i16_a                   ; two bits of a into the remainder
    rol i16_a+1
    rol i16_rem
    rol i16_rem+1
    asl i16_a
    rol i16_a+1
    rol i16_rem
    rol i16_rem+1

    lda i16_root                ; trial = (root << 2) | 1
    sta i16_tmp
    stz i16_tmp+1
    asl i16_tmp
    rol i16_tmp+1
    asl i16_tmp
    rol i16_tmp+1
    lda i16_tmp
    ora #1
    sta i16_tmp

    asl i16_root                ; root <<= 1, bit 0 clear

    lda i16_rem                 ; rem >= trial ?
    cmp i16_tmp
    lda i16_rem+1
    sbc i16_tmp+1
    bcc _next

    sec                         ; rem -= trial
    lda i16_rem
    sbc i16_tmp
    sta i16_rem
    lda i16_rem+1
    sbc i16_tmp+1
    sta i16_rem+1
    inc i16_root                ; set the new root bit
_next
    dex
    bne _iter

    lda i16_root
    rts

; ---------------------------------------------------------------------
; i16_to_dec   -- unsigned i16_a to decimal
; i16_to_dec_s -- signed i16_a to decimal, with a leading '-'
;   out: A = buffer low, X = buffer high, Y = length; NUL-terminated.
;   Both consume i16_a.
; ---------------------------------------------------------------------
i16_to_dec
    lda i16_a
    sta X16_P0
    lda i16_a+1
    sta X16_P1
    jmp u16_to_dec

i16_to_dec_s
    stz i16_sign
    lda i16_a+1
    bpl _positive

    inc i16_sign                ; negative: print the magnitude
    sec
    lda #0
    sbc i16_a
    sta X16_P0
    lda #0
    sbc i16_a+1
    sta X16_P1
    bra _convert
_positive
    lda i16_a
    sta X16_P0
    lda i16_a+1
    sta X16_P1
_convert
    jsr u16_to_dec              ; digits land in num_buf

    ldx #0
    lda i16_sign
    beq _copy
    lda #'-'
    sta i16_buf
    ldx #1
_copy
    ldy #0
_loop
    lda num_buf,y               ; the terminator is copied too
    sta i16_buf,x
    beq _done
    inx
    iny
    bra _loop
_done
    txa
    tay                         ; Y = length, not counting the terminator
    lda #<i16_buf
    ldx #>i16_buf
    rts

; (end zone)
.endif
.if xuse_int32
; --- inline util/int32.asm ---
;ACME
; =====================================================================
; x16lib :: util/int32.asm -- 32-bit integer arithmetic
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The DOUBLE.TXT surface, in assembly. Values are 32 bits, little-endian,
; and live in two named registers the caller writes directly:
;
;       i32_a   the accumulator; most routines read and overwrite it
;       i32_b   the operand
;       i32_r   the remainder left by i32_divmod
;
; They are four-byte buffers rather than parameter-block arguments
; because a 32-bit binary operation needs eight bytes of input, and the
; block only holds eight in total.
;
;       +i32_const i32_a, 1000000
;       +i32_const i32_b, 7
;       jsr i32_divmod              ; i32_a = 142857, i32_r = 1
;
; Signed and unsigned share the same add, subtract, multiply and shift:
; two's complement makes them identical. Only comparison, division and
; decimal output need to know.
; =====================================================================

; (zone: file scope in 64tass)

; +i32_const lives in core/macros.asm, because ACME needs a macro defined
; before it is called and this file is sourced last.

i32_a .byte 0, 0, 0, 0
i32_b .byte 0, 0, 0, 0
i32_r .byte 0, 0, 0, 0

i32_tmp .byte 0, 0, 0, 0
i32_cnt .byte 0

; ---------------------------------------------------------------------
; i32_from_u16 -- in: A = low, X = high.   i32_a = A/X, zero-extended
; i32_from_s16 -- in: A = low, X = high.   i32_a = A/X, sign-extended
; i32_to_s16   -- out: A = low, X = high   (the top two bytes are lost)
; ---------------------------------------------------------------------
i32_from_u16
    sta i32_a
    stx i32_a+1
    stz i32_a+2
    stz i32_a+3
    rts

i32_from_s16
    sta i32_a
    stx i32_a+1
    txa
    and #$80
    beq _positive
    lda #$FF                    ; negative: fill the top with ones
    sta i32_a+2
    sta i32_a+3
    rts
_positive
    stz i32_a+2
    stz i32_a+3
    rts

i32_to_s16
    ldx i32_a+1
    lda i32_a
    rts

; ---------------------------------------------------------------------
; i32_add -- i32_a += i32_b
; i32_sub -- i32_a -= i32_b
; ---------------------------------------------------------------------
i32_add
    clc
    lda i32_a
    adc i32_b
    sta i32_a
    lda i32_a+1
    adc i32_b+1
    sta i32_a+1
    lda i32_a+2
    adc i32_b+2
    sta i32_a+2
    lda i32_a+3
    adc i32_b+3
    sta i32_a+3
    rts

i32_sub
    sec
    lda i32_a
    sbc i32_b
    sta i32_a
    lda i32_a+1
    sbc i32_b+1
    sta i32_a+1
    lda i32_a+2
    sbc i32_b+2
    sta i32_a+2
    lda i32_a+3
    sbc i32_b+3
    sta i32_a+3
    rts

; ---------------------------------------------------------------------
; i32_neg -- i32_a = -i32_a
; i32_abs -- i32_a = |i32_a|
; ---------------------------------------------------------------------
i32_neg
    sec
    lda #0
    sbc i32_a
    sta i32_a
    lda #0
    sbc i32_a+1
    sta i32_a+1
    lda #0
    sbc i32_a+2
    sta i32_a+2
    lda #0
    sbc i32_a+3
    sta i32_a+3
    rts

i32_abs
    lda i32_a+3
    bmi i32_neg
    rts

; ---------------------------------------------------------------------
; i32_shl -- i32_a <<= 1
; i32_shr -- i32_a >>= 1, logical (zero fill)
; i32_asr -- i32_a >>= 1, arithmetic (sign fill)
; Carry holds the bit shifted out.
; ---------------------------------------------------------------------
i32_shl
    asl i32_a
    rol i32_a+1
    rol i32_a+2
    rol i32_a+3
    rts

i32_shr
    lsr i32_a+3
    ror i32_a+2
    ror i32_a+1
    ror i32_a
    rts

i32_asr
    lda i32_a+3
    asl                         ; sign bit into carry
    ror i32_a+3                 ; ...and back in at the top
    ror i32_a+2
    ror i32_a+1
    ror i32_a
    rts

; ---------------------------------------------------------------------
; i32_cmpu -- unsigned compare i32_a with i32_b
; i32_cmps -- signed compare
;   out: A = $FF if a < b, 0 if equal, 1 if a > b
;        Z set when equal.  Neither operand is modified.
; ---------------------------------------------------------------------
i32_cmpu
    lda i32_a+3
    cmp i32_b+3
    bne _differ
    lda i32_a+2
    cmp i32_b+2
    bne _differ
    lda i32_a+1
    cmp i32_b+1
    bne _differ
    lda i32_a
    cmp i32_b
    bne _differ
    lda #0                      ; equal
    rts
_differ
    bcs _greater
    lda #$FF
    rts
_greater
    lda #1
    rts

i32_cmps
    ; Same-signed operands compare like unsigned values. Different signs
    ; short-circuit: the negative one is the smaller, whatever the bits.
    lda i32_a+3
    eor i32_b+3
    bpl i32_cmpu                ; signs agree
    lda i32_a+3
    bmi _a_negative
    lda #1                      ; a >= 0, b < 0
    rts
_a_negative
    lda #$FF
    rts

; ---------------------------------------------------------------------
; i32_mul -- i32_a = i32_a * i32_b, modulo 2`32
;
; Shift-and-add. Signed and unsigned agree on the low 32 bits, so this
; serves both; only the discarded overflow differs.
; ---------------------------------------------------------------------
i32_mul
    lda i32_a                   ; tmp = a, then rebuild a as the product
    sta i32_tmp
    lda i32_a+1
    sta i32_tmp+1
    lda i32_a+2
    sta i32_tmp+2
    lda i32_a+3
    sta i32_tmp+3
    stz i32_a
    stz i32_a+1
    stz i32_a+2
    stz i32_a+3

    lda #32
    sta i32_cnt
_loop
    lsr i32_b+3                 ; next bit of the multiplier
    ror i32_b+2
    ror i32_b+1
    ror i32_b
    bcc _no_add

    clc                         ; a += tmp
    lda i32_a
    adc i32_tmp
    sta i32_a
    lda i32_a+1
    adc i32_tmp+1
    sta i32_a+1
    lda i32_a+2
    adc i32_tmp+2
    sta i32_a+2
    lda i32_a+3
    adc i32_tmp+3
    sta i32_a+3
_no_add
    asl i32_tmp                 ; tmp <<= 1
    rol i32_tmp+1
    rol i32_tmp+2
    rol i32_tmp+3

    dec i32_cnt
    bne _loop
    rts

; ---------------------------------------------------------------------
; i32_divmod -- unsigned:  i32_a = i32_a / i32_b,  i32_r = i32_a % i32_b
;   out: carry set if i32_b was zero, in which case nothing is changed
;
; Restoring division: shift the dividend left through the remainder one
; bit at a time, subtracting the divisor whenever it fits.
; ---------------------------------------------------------------------
i32_divmod
    lda i32_b                   ; divide by zero?
    ora i32_b+1
    ora i32_b+2
    ora i32_b+3
    bne _go
    sec
    rts
_go
    stz i32_r
    stz i32_r+1
    stz i32_r+2
    stz i32_r+3

    lda #32
    sta i32_cnt
_loop
    asl i32_a                   ; shift dividend out of the top of a...
    rol i32_a+1
    rol i32_a+2
    rol i32_a+3
    rol i32_r                   ; ...and into the bottom of r
    rol i32_r+1
    rol i32_r+2
    rol i32_r+3

    sec                         ; trial subtraction r - b
    lda i32_r
    sbc i32_b
    sta i32_tmp
    lda i32_r+1
    sbc i32_b+1
    sta i32_tmp+1
    lda i32_r+2
    sbc i32_b+2
    sta i32_tmp+2
    lda i32_r+3
    sbc i32_b+3
    sta i32_tmp+3
    bcc _restore                ; it did not fit: leave r alone

    lda i32_tmp                 ; it fit: keep the difference
    sta i32_r
    lda i32_tmp+1
    sta i32_r+1
    lda i32_tmp+2
    sta i32_r+2
    lda i32_tmp+3
    sta i32_r+3
    inc i32_a                   ; and set the quotient bit
_restore
    dec i32_cnt
    bne _loop
    clc
    rts

; ---------------------------------------------------------------------
; i32_to_dec -- unsigned i32_a to decimal, no leading zeros
;   out: A = buffer low, X = buffer high, Y = length
;        NUL-terminated, so screen_puts can print it directly.
;   Consumes i32_a and i32_b.
;
; Repeated division by ten, digits emitted least significant first and
; then reversed in place.
; ---------------------------------------------------------------------
i32_to_dec
    ldy #0
    sty i32_digits
_divide
    #i32_const i32_b, 10
    jsr i32_divmod
    lda i32_r                   ; remainder is the next digit
    clc
    adc #'0'
    ldy i32_digits
    sta i32_buf,y
    inc i32_digits

    lda i32_a                   ; quotient zero yet?
    ora i32_a+1
    ora i32_a+2
    ora i32_a+3
    bne _divide

    ; Reverse the digits in place.
    ldx #0
    ldy i32_digits
    dey
_reverse
    stx i32_lo
    sty i32_hi
    cpx i32_hi
    bcs _done                   ; pointers met or crossed
    lda i32_buf,x
    pha
    lda i32_buf,y
    sta i32_buf,x
    pla
    sta i32_buf,y
    inx
    dey
    bra _reverse
_done
    ldy i32_digits
    lda #0
    sta i32_buf,y               ; terminate; Y is the length
    lda #<i32_buf
    ldx #>i32_buf
    rts

i32_buf    .fill 12, 0          ; "4294967295" plus a terminator
i32_digits .byte 0
i32_lo     .byte 0
i32_hi     .byte 0

; (end zone)
.endif
.if xuse_float
; --- inline util/float.asm ---
;ACME
; =====================================================================
; x16lib :: util/float.asm -- floating point, via the ROM's FP library
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The X16 ROM already carries a complete C128/C65-compatible floating
; point library in BANK_BASIC, reachable through a stable jump table at
; $FE00. This module is a binding, not a reimplementation: several
; thousand lines of 6502 we do not have to write, test, or carry.
;
; Everything works on FAC, the floating accumulator in zero page. A
; float in memory is 5 bytes (FP_SIZE); reserve them with .fill 5, 0.
;
;       f_from_s16 / f_store  fvar_a       ; fvar_a = 10.0
;       f_from_s16 / f_store  fvar_b       ; fvar_b = 4.0
;       f_load  fvar_a
;       f_div   fvar_b                     ; FAC = 2.5
;       f_to_str                           ; A/X -> "2.5"
;
; Pointer arguments are A = low byte, Y = high byte, matching the ROM.
;
; --- on operand order ------------------------------------------------
; The ROM's fp_fsub and fp_fdiv are backwards from what jumptab.s claims:
; both load ARG from memory and then subtract or divide FAC INTO it, so
; you get `mem - FAC` and `mem / FAC`. f_sub and f_div below present the
; intuitive direction by stashing FAC in ARG first and running the
; ARG-first form. f_rsub and f_rdiv expose the raw order, which is what
; you want for `1/x` and similar.
;
; --- cost ------------------------------------------------------------
; Every call crosses a ROM bank via jsrfar, which is not free. For hot
; per-frame maths prefer util/fixed.asm (8.8) or util/int32.asm.
; =====================================================================

; (zone: file scope in 64tass)

; A caller's operand address, stashed across the bank crossings. Must be
; in zero page: f_to_str_trim dereferences it with (zp),y. Nothing here
; calls another library routine, so borrowing the shared scratch pointer
; cannot collide with anything.
f_ptr = X16_TPTR0

; ---------------------------------------------------------------------
; f_zero -- FAC = 0
; f_neg  -- FAC = -FAC
; f_abs  -- FAC = |FAC|
; f_int  -- FAC = int(FAC), truncating toward negative infinity
; ---------------------------------------------------------------------
f_zero
    #jsrfar fp_zerofc, BANK_BASIC
    rts

; fp_negop is the true unary minus. fp_negfac, despite its name, is an
; internal helper of the ROM's add/subtract path that two's-complements
; the mantissa in place -- calling it on a normalised FAC denormalises
; it (5.0 comes back as garbage that reads about -2.5).
f_neg
    #jsrfar fp_negop, BANK_BASIC
    rts

f_abs
    #jsrfar fp_abs, BANK_BASIC
    rts

f_int
    #jsrfar fp_int, BANK_BASIC
    rts

; ---------------------------------------------------------------------
; f_sgn -- out: A = $FF if FAC < 0, 0 if zero, 1 if positive
; ---------------------------------------------------------------------
f_sgn
    #jsrfar fp_sign, BANK_BASIC
    rts

; ---------------------------------------------------------------------
; f_from_u8  -- in: A = 0..255.            FAC = A
; f_from_s16 -- in: A = low, X = high.     FAC = the signed value
; f_to_s16   -- out: A = low, X = high.    Rounds toward zero.
;
; fp_givayf wants the high byte in A and the low byte in Y, the reverse
; of this library's usual A = low convention, so swap on the way in.
; fp_ayint leaves the result big-endian in FACMO (high) and FACLO (low).
;
; f_from_u8 goes through givayf with a zero high byte: the ROM's
; fp_float converts a SIGNED byte, so 200 through it would come out
; as -56.
; ---------------------------------------------------------------------
f_from_u8
    tay                         ; Y = low byte
    lda #0                      ; A = high byte: zero-extend
    #jsrfar fp_givayf, BANK_BASIC
    rts

f_from_s16
    sta f_ptr                   ; stash the low byte
    txa                         ; A = high
    ldy f_ptr                   ; Y = low
    #jsrfar fp_givayf, BANK_BASIC
    rts

f_to_s16
    #jsrfar fp_ayint, BANK_BASIC
    lda FP_FACLO
    ldx FP_FACMO
    rts

; ---------------------------------------------------------------------
; f_load  -- in: A/Y = address.  FAC = the 5-byte float there
; f_store -- in: A/Y = address.  Store round(FAC) there
;
; fp_movmf takes its pointer in X/Y rather than A/Y. Only this one does.
; ---------------------------------------------------------------------
f_load
    #jsrfar fp_movfm, BANK_BASIC
    rts

f_store
    tax
    #jsrfar fp_movmf, BANK_BASIC
    rts

; ---------------------------------------------------------------------
; f_add  -- in: A/Y = address.   FAC = FAC + mem
; f_mul  -- in: A/Y = address.   FAC = FAC * mem
; Both commute, so the ROM's order does not matter.
; ---------------------------------------------------------------------
f_add
    #jsrfar fp_fadd, BANK_BASIC
    rts

f_mul
    #jsrfar fp_fmult, BANK_BASIC
    rts

; ---------------------------------------------------------------------
; f_sub -- in: A/Y = address.   FAC = FAC - mem
; f_div -- in: A/Y = address.   FAC = FAC / mem
;
; The ROM only offers mem-first. Move FAC into ARG, load mem into FAC,
; then use the ARG-first entry, which computes ARG (op) FAC.
; ---------------------------------------------------------------------
f_sub
    sta f_ptr
    sty f_ptr+1
    #jsrfar fp_movef, BANK_BASIC        ; ARG = FAC
    lda f_ptr
    ldy f_ptr+1
    #jsrfar fp_movfm, BANK_BASIC        ; FAC = mem
    #jsrfar fp_fsubt, BANK_BASIC        ; FAC = ARG - FAC
    rts

f_div
    sta f_ptr
    sty f_ptr+1
    #jsrfar fp_movef, BANK_BASIC        ; ARG = FAC
    lda f_ptr
    ldy f_ptr+1
    #jsrfar fp_movfm, BANK_BASIC        ; FAC = mem
    #jsrfar fp_fdivt, BANK_BASIC        ; FAC = ARG / FAC
    rts

; ---------------------------------------------------------------------
; f_rsub -- in: A/Y = address.   FAC = mem - FAC
; f_rdiv -- in: A/Y = address.   FAC = mem / FAC   (the reciprocal form)
; The ROM's native order, one bank crossing instead of three.
; ---------------------------------------------------------------------
f_rsub
    #jsrfar fp_fsub, BANK_BASIC
    rts

f_rdiv
    #jsrfar fp_fdiv, BANK_BASIC
    rts

; ---------------------------------------------------------------------
; f_pow  -- in: A/Y = address.   FAC = FAC ^ mem
; f_rpow -- in: A/Y = address.   FAC = mem ^ FAC   (the ROM's order)
; ---------------------------------------------------------------------
f_pow
    sta f_ptr
    sty f_ptr+1
    #jsrfar fp_movef, BANK_BASIC        ; ARG = FAC
    lda f_ptr
    ldy f_ptr+1
    #jsrfar fp_movfm, BANK_BASIC        ; FAC = mem
    #jsrfar fp_fpwrt, BANK_BASIC        ; FAC = ARG ^ FAC
    rts

f_rpow
    #jsrfar fp_fpwr, BANK_BASIC
    rts

; ---------------------------------------------------------------------
; f_cmp -- in: A/Y = address
;          out: A = $FF if FAC < mem, 0 if equal, 1 if FAC > mem
; ---------------------------------------------------------------------
f_cmp
    #jsrfar fp_fcomp, BANK_BASIC
    rts

; ---------------------------------------------------------------------
; Transcendentals. Each replaces FAC. sin, cos, tan and atan destroy ARG.
; ---------------------------------------------------------------------
f_sqrt
    #jsrfar fp_sqr, BANK_BASIC
    rts

f_ln
    #jsrfar fp_log, BANK_BASIC
    rts

f_exp
    #jsrfar fp_exp, BANK_BASIC
    rts

f_sin
    #jsrfar fp_sin, BANK_BASIC
    rts

f_cos
    #jsrfar fp_cos, BANK_BASIC
    rts

f_tan
    #jsrfar fp_tan, BANK_BASIC
    rts

f_atan
    #jsrfar fp_atn, BANK_BASIC
    rts

; ---------------------------------------------------------------------
; f_to_str -- out: A = low, X = high of a NUL-terminated string
;
; The ROM writes it to FP_FBUFFR ($0100 -- the bottom of the stack page,
; which BASIC also uses for this). Copy it out before you push anything
; deep, and before the next f_to_str overwrites it.
;
; Positive numbers get a leading space, exactly as BASIC's PRINT shows
; them; f_to_str_trim skips it.
;
; f_to_str_trim -- out: A = low, X = high, the string without that space
; ---------------------------------------------------------------------
f_to_str
    #jsrfar fp_fout, BANK_BASIC
    pha                         ; the ROM returns A = low, Y = high
    tya
    tax                         ; X = high
    pla                         ; A = low
    rts

f_to_str_trim
    jsr f_to_str
    sta f_ptr
    stx f_ptr+1
    ldy #0
    lda (f_ptr),y
    cmp #32                     ; a leading space
    bne _done
    inc f_ptr                   ; skip the sign space
    bne _done
    inc f_ptr+1
_done
    lda f_ptr
    ldx f_ptr+1
    rts

; ---------------------------------------------------------------------
; f_from_str -- parse a decimal string into FAC
;   in: A/Y = address, X = length
;
; fp_val wants X = address LOW, Y = address high, A = length. Note the
; low byte in X: jumptab.s writes the argument as "float_X:float_Y", which
; everywhere else in that file means high:low, but the code is
; `stx index / sty index+1` -- low first. The comment is wrong.
; ---------------------------------------------------------------------
f_from_str
    sta f_ptr                   ; address low
    txa                         ; A = length
    ldx f_ptr                   ; X = address low; Y is already the high byte
    #jsrfar fp_val, BANK_BASIC
    rts

; (end zone)
.endif
.if xuse_double
; --- inline util/double.asm ---
;ACME
; =====================================================================
; x16lib :: util/double.asm -- 64-bit software floating point (binary64)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; util/float.asm binds the ROM's 5-byte float (about 9 significant
; digits). Fine for graphics, thin for a calculator. This is a
; from-scratch IEEE-754 double: 8 bytes, ~15-16 significant digits, the
; full 10^+/-308 range -- the ROM has nothing to lean on, so it is all
; software.
;
; The shape mirrors float.asm: a floating accumulator d_ac (like FAC)
; and operations that take a pointer to a memory operand in A/Y and act
; on d_ac. A double in memory is 8 bytes (D_SIZE); values are
; little-endian IEEE-754 binary64, so they interoperate with anyone
; else's doubles.
;
;       lda #<dvar : ldy #>dvar : jsr d_load     ; d_ac = dvar
;       lda #<dvar2: ldy #>dvar2: jsr d_add      ; (stage 2) d_ac += dvar2
;       lda #<dvar : ldy #>dvar : jsr d_store     ; dvar = d_ac
;
; STAGING: built in tested stages. This file currently has the format,
; load/store, integer conversions and compare (Stage 1). d_add/d_sub,
; d_mul/d_div, decimal string I/O and the transcendentals follow.
;
; House style (as in gfx/shapes.asm): every label is a unique zone-local,
; because ACME's _cheap locals do NOT reset at a zone-local routine label
; -- two routines cannot each own an _loop.
;
; --- internal unpacked form ------------------------------------------
;   dac_c  class: 0 zero, 1 normal, 2 infinity, 3 NaN
;   dac_s  sign in bit 7
;   dac_e  exponent, signed 16-bit
;   dac_m  64-bit significand, little-endian, normalised so bit 63 = 1
;          value = (-1)`sign * dac_m * 2`dac_e
; Subnormals are flushed to zero; overflow makes an infinity.
; =====================================================================

; (zone: file scope in 64tass)

D_SIZE = 8

D_ZERO = 0
D_NORM = 1
D_INF  = 2
D_NAN  = 3

d_ptr    = X16_TPTR0       ; operand pointer (shared scratch)
dstr_ptr = X16_TPTR1       ; d_from_str's string pointer (survives the
                                 ; inner d_* calls, which only touch TPTR0)

; ---------------------------------------------------------------------
; d_load  -- in: A = low, Y = high of an 8-byte double.  d_ac = mem
; d_store -- in: A = low, Y = high.  mem = d_ac
; ---------------------------------------------------------------------
d_load
    sta d_ptr
    sty d_ptr+1
    ldy #D_SIZE-1
double_dld_l
    lda (d_ptr),y
    sta d_ac,y
    dey
    bpl double_dld_l
    rts

d_store
    sta d_ptr
    sty d_ptr+1
    ldy #D_SIZE-1
double_dst_l
    lda d_ac,y
    sta (d_ptr),y
    dey
    bpl double_dst_l
    rts

; ---------------------------------------------------------------------
; d_neg -- d_ac = -d_ac      d_abs -- d_ac = |d_ac|
; ---------------------------------------------------------------------
d_neg
    lda d_ac+7
    eor #$80
    sta d_ac+7
    rts

d_abs
    lda d_ac+7
    and #$7F
    sta d_ac+7
    rts

; ---------------------------------------------------------------------
; d_from_s16 -- in: A = low, X = high (signed 16-bit).  d_ac = value
; ---------------------------------------------------------------------
d_from_s16
    sta X16_P0
    stx X16_P1
    txa                          ; sign-extend into P2/P3
    and #$80
    beq double_dfs16_pos
    lda #$FF
double_dfs16_pos
    sta X16_P2
    sta X16_P3
    ; fall through

; ---------------------------------------------------------------------
; d_from_s32 -- in: X16_P0..P3 = signed 32-bit, little-endian.
;               d_ac = value (exact; 32 bits fit the 53-bit mantissa)
; ---------------------------------------------------------------------
d_from_s32
    lda X16_P3                   ; remember the sign, then take |value|
    and #$80
    sta dac_s
    beq double_dfr_mag
    sec                          ; negate P0..P3
    lda #0
    sbc X16_P0
    sta X16_P0
    lda #0
    sbc X16_P1
    sta X16_P1
    lda #0
    sbc X16_P2
    sta X16_P2
    lda #0
    sbc X16_P3
    sta X16_P3
double_dfr_mag
    lda X16_P0
    ora X16_P1
    ora X16_P2
    ora X16_P3
    bne double_dfr_nz
    jmp double_d_zero_signed           ; +/- 0
double_dfr_nz
    ; magnitude into the top 32 bits of dac_m (= value * 2`32), then
    ; normalise up to bit 63.
    stz dac_m
    stz dac_m+1
    stz dac_m+2
    stz dac_m+3
    lda X16_P0
    sta dac_m+4
    lda X16_P1
    sta dac_m+5
    lda X16_P2
    sta dac_m+6
    lda X16_P3
    sta dac_m+7
    lda #<-32
    sta dac_e
    lda #>-32
    sta dac_e+1
    lda #D_NORM
    sta dac_c
    stz d_sticky                 ; an integer converts exactly
    jsr double_d_norm
    jmp double_d_pack

; ---------------------------------------------------------------------
; d_to_s32 -- out: X16_P0..P3 = (s32) d_ac, truncated toward zero.
;   carry set on overflow (|d_ac| too big; result clamped) or NaN.
;
; value = dac_m * 2`dac_e with dac_m normalised (bit 63 = 1). The
; integer part is dac_m >> (-dac_e). For an s32-range value dac_e lies
; in -63..-33; dac_e >= -32 overflows, dac_e <= -64 truncates to 0.
; ---------------------------------------------------------------------
d_to_s32
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack                ; d_ac -> dac_*
    lda dac_c
    cmp #D_NORM
    beq double_dto_norm
    stz X16_P0                   ; zero -> 0 ; inf/nan -> 0 + carry
    stz X16_P1
    stz X16_P2
    stz X16_P3
    cmp #D_ZERO
    beq double_dto_okz
    sec
    rts
double_dto_okz
    clc
    rts
double_dto_norm
    ; shift = -dac_e
    sec
    lda #0
    sbc dac_e
    sta d_cnt
    lda #0
    sbc dac_e+1
    sta d_cnt+1
    ; shift < 33  -> overflow  (signed compare d_cnt vs 33)
    lda d_cnt
    cmp #33
    lda d_cnt+1
    sbc #0
    bvc double_dto_v1
    eor #$80
double_dto_v1
    bmi double_dto_over
    ; shift > 63  -> 0  (signed compare d_cnt vs 64)
    lda d_cnt
    cmp #64
    lda d_cnt+1
    sbc #0
    bvc double_dto_v2
    eor #$80
double_dto_v2
    bpl double_dto_tiny
    ; 33..63: shift dac_m right d_cnt into the work area
    ldy #7
double_dto_cp
    lda dac_m,y
    sta d_work,y
    dey
    bpl double_dto_cp
    ldx d_cnt
double_dto_sr
    lsr d_work+7
    ror d_work+6
    ror d_work+5
    ror d_work+4
    ror d_work+3
    ror d_work+2
    ror d_work+1
    ror d_work
    dex
    bne double_dto_sr
    lda d_work   
    sta X16_P0   ; low 32 bits are the integer
    lda d_work+1 
    sta X16_P1
    lda d_work+2 
    sta X16_P2
    lda d_work+3 
    sta X16_P3
    lda dac_s
    bpl double_dto_pos
    sec                          ; apply the sign
    lda #0
    sbc X16_P0
    sta X16_P0
    lda #0
    sbc X16_P1
    sta X16_P1
    lda #0
    sbc X16_P2
    sta X16_P2
    lda #0
    sbc X16_P3
    sta X16_P3
double_dto_pos
    clc
    rts
double_dto_tiny
    stz X16_P0
    stz X16_P1
    stz X16_P2
    stz X16_P3
    clc
    rts
double_dto_over
    lda dac_s
    bmi double_dto_oneg
    lda #$FF
    sta X16_P0        ; +2147483647
    sta X16_P1
    sta X16_P2
    lda #$7F
    sta X16_P3
    sec
    rts
double_dto_oneg
    stz X16_P0                   ; -2147483648
    stz X16_P1
    stz X16_P2
    lda #$80
    sta X16_P3
    sec
    rts

; ---------------------------------------------------------------------
; d_cmp -- in: A = low, Y = high of an operand.
;   out: A = $FF if d_ac < mem, 0 if equal, 1 if d_ac > mem.  Z if equal.
;        A NaN on either side is unordered and answers 1.
; ---------------------------------------------------------------------
d_cmp
    sta d_ptr
    sty d_ptr+1
    jsr double_d_unpack                ; operand -> dac_*
    jsr double_d_ac_to_bf              ; ...move it to dbf_*
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack                ; d_ac -> dac_*

    lda dac_c
    cmp #D_NAN
    beq double_dcm_gt
    lda dbf_c
    cmp #D_NAN
    beq double_dcm_gt
    lda dac_c                    ; both zero -> equal (any sign)
    ora dbf_c
    bne double_dcm_nz
    lda #0
    rts
double_dcm_nz
    lda dac_s                    ; different signs decide
    eor dbf_s
    bpl double_dcm_same
    lda dac_s
    bmi double_dcm_lt                  ; a<0, b>=0
    bra double_dcm_gt                  ; a>=0, b<0
double_dcm_same
    jsr double_d_mag_cmp               ; A = -1/0/1 by |a| vs |b|
    tax
    lda dac_s
    bpl double_dcm_done                ; positive: order as computed
    txa                          ; negative: reverse
    eor #$FF
    clc
    adc #1
    tax
double_dcm_done
    txa
    rts
double_dcm_lt
    lda #$FF
    rts
double_dcm_gt
    lda #1
    rts

; |a| (dac_*) vs |b| (dbf_*): A = $FF/0/1
double_d_mag_cmp
    lda dac_c                    ; zero < normal < inf
    cmp dbf_c
    bne double_dmg_class
    cmp #D_NORM
    beq double_dmg_num
    lda #0
    rts
double_dmg_class
    bcs double_dmg_gt
    lda #$FF
    rts
double_dmg_gt
    lda #1
    rts
double_dmg_num
    lda dac_e+1                  ; exponent (signed 16-bit)
    cmp dbf_e+1
    bne double_dmg_ehi
    lda dac_e
    cmp dbf_e
    bne double_dmg_elo
    ldy #7                       ; equal exponent: mantissa, high first
double_dmg_ml
    lda dac_m,y
    cmp dbf_m,y
    bne double_dmg_md
    dey
    bpl double_dmg_ml
    lda #0
    rts
double_dmg_md
    bcs double_dmg_gt
    lda #$FF
    rts
double_dmg_elo
    bcs double_dmg_gt
    lda #$FF
    rts
double_dmg_ehi
    lda dac_e+1
    sec
    sbc dbf_e+1
    bvc double_dmg_ev
    eor #$80
double_dmg_ev
    bmi double_dmg_lt
    lda #1
    rts
double_dmg_lt
    lda #$FF
    rts

; ---------------------------------------------------------------------
; d_add -- d_ac += mem(A/Y)        d_sub -- d_ac -= mem(A/Y)
;
; Classic align/add-or-subtract/normalise. Bits shifted out during the
; alignment become a sticky bit that feeds double_d_pack's rounding. Near-total
; cancellation keeps only a sticky (not full guard bits), so a subtraction
; that annihilates most of the significand can round up to 1 ulp loose --
; refined in a later pass; ordinary sums are correctly rounded.
; ---------------------------------------------------------------------
d_sub
    sta d_ptr
    sty d_ptr+1
    jsr double_d_unpack                ; operand -> dac_*
    lda dac_s
    eor #$80                     ; subtract = add the negation
    sta dac_s
    jmp double_d_add_common
d_add
    sta d_ptr
    sty d_ptr+1
    jsr double_d_unpack                ; operand -> dac_*
double_d_add_common
    jsr double_d_ac_to_bf              ; operand -> dbf_*
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack                ; d_ac -> dac_*
    stz d_sticky

    lda dac_c                    ; NaN on either side -> NaN
    cmp #D_NAN
    beq double_dad_nan
    lda dbf_c
    cmp #D_NAN
    beq double_dad_nan
    lda dac_c
    cmp #D_INF
    bne double_dad_acfin
    lda dbf_c                    ; dac is inf
    cmp #D_INF
    bne double_dad_packac              ; inf + finite -> dac
    lda dac_s
    eor dbf_s
    bmi double_dad_nan                 ; inf + (-inf) -> NaN
    bpl double_dad_packac              ; inf + inf -> dac
double_dad_acfin
    lda dbf_c
    cmp #D_INF
    beq double_dad_retbf               ; finite + inf -> dbf
    lda dac_c
    beq double_dad_retbf               ; 0 + x -> x
    lda dbf_c
    bne double_dad_align
    jmp double_d_pack                  ; x + 0 -> x
double_dad_nan
    lda #D_NAN
    sta dac_c
    jmp double_d_pack
double_dad_packac
    jmp double_d_pack
double_dad_retbf
    jsr double_d_bf_to_ac
    jmp double_d_pack

double_dad_align
    ; make dac the larger-or-equal exponent (swap if needed)
    lda dac_e+1
    cmp dbf_e+1
    bne double_dad_ehi
    lda dac_e
    cmp dbf_e
    bcs double_dad_noswap
    bra double_dad_swap
double_dad_ehi
    lda dac_e+1
    sec
    sbc dbf_e+1
    bvc double_dad_ev
    eor #$80
double_dad_ev
    bpl double_dad_noswap
double_dad_swap
    jsr double_d_swap_ab
double_dad_noswap
    sec                          ; diff = dac_e - dbf_e (>= 0)
    lda dac_e
    sbc dbf_e
    sta d_cnt
    lda dac_e+1
    sbc dbf_e+1
    sta d_cnt+1
    lda d_cnt+1                  ; diff >= 64 -> dbf negligible
    bne double_dad_big
    lda d_cnt
    cmp #64
    bcc double_dad_doshift
double_dad_big
    lda dbf_m
    ora dbf_m+1
    ora dbf_m+2
    ora dbf_m+3
    ora dbf_m+4
    ora dbf_m+5
    ora dbf_m+6
    ora dbf_m+7
    beq double_dad_zb
    lda #1
    sta d_sticky
double_dad_zb
    lda #0
    ldy #7
double_dad_zbl
    sta dbf_m,y
    dey
    bpl double_dad_zbl
    bra double_dad_addsub
double_dad_doshift
    ldx d_cnt
    beq double_dad_addsub
double_dad_shl
    lsr dbf_m+7
    ror dbf_m+6
    ror dbf_m+5
    ror dbf_m+4
    ror dbf_m+3
    ror dbf_m+2
    ror dbf_m+1
    ror dbf_m
    bcc double_dad_ns
    lda #1
    sta d_sticky
double_dad_ns
    dex
    bne double_dad_shl
double_dad_addsub
    lda dac_s
    eor dbf_s
    bpl double_dad_addm
    jmp double_dad_dosub
double_dad_addm
    ; --- same sign: add the magnitudes ---
    clc
    lda dac_m  
    adc dbf_m
    sta dac_m
    lda dac_m+1
    adc dbf_m+1
    sta dac_m+1
    lda dac_m+2
    adc dbf_m+2
    sta dac_m+2
    lda dac_m+3
    adc dbf_m+3
    sta dac_m+3
    lda dac_m+4
    adc dbf_m+4
    sta dac_m+4
    lda dac_m+5
    adc dbf_m+5
    sta dac_m+5
    lda dac_m+6
    adc dbf_m+6
    sta dac_m+6
    lda dac_m+7
    adc dbf_m+7
    sta dac_m+7
    bcc double_dad_pack
    lda dac_m                    ; carry out of bit 63: >>1, exp++
    and #1
    beq double_dad_c0
    lda #1
    sta d_sticky
double_dad_c0
    ror dac_m+7
    ror dac_m+6
    ror dac_m+5
    ror dac_m+4
    ror dac_m+3
    ror dac_m+2
    ror dac_m+1
    ror dac_m
    lda #$80
    ora dac_m+7
    sta dac_m+7
    inc dac_e
    bne double_dad_pack
    inc dac_e+1
double_dad_pack
    jmp double_d_pack
double_dad_dosub
    ; --- opposite sign: larger magnitude minus smaller ---
    jsr double_d_mant_cmp
    bne double_dad_subgo
    jmp double_dad_cancel
double_dad_subgo
    bpl double_dad_abig
    sec                          ; dbf > dac: dbf - dac, sign = dbf_s
    lda dbf_m  
    sbc dac_m
    sta dac_m
    lda dbf_m+1
    sbc dac_m+1
    sta dac_m+1
    lda dbf_m+2
    sbc dac_m+2
    sta dac_m+2
    lda dbf_m+3
    sbc dac_m+3
    sta dac_m+3
    lda dbf_m+4
    sbc dac_m+4
    sta dac_m+4
    lda dbf_m+5
    sbc dac_m+5
    sta dac_m+5
    lda dbf_m+6
    sbc dac_m+6
    sta dac_m+6
    lda dbf_m+7
    sbc dac_m+7
    sta dac_m+7
    lda dbf_s
    sta dac_s
    bra double_dad_subnorm
double_dad_abig
    sec                          ; dac - dbf, sign = dac_s (unchanged)
    lda dac_m  
    sbc dbf_m
    sta dac_m
    lda dac_m+1
    sbc dbf_m+1
    sta dac_m+1
    lda dac_m+2
    sbc dbf_m+2
    sta dac_m+2
    lda dac_m+3
    sbc dbf_m+3
    sta dac_m+3
    lda dac_m+4
    sbc dbf_m+4
    sta dac_m+4
    lda dac_m+5
    sbc dbf_m+5
    sta dac_m+5
    lda dac_m+6
    sbc dbf_m+6
    sta dac_m+6
    lda dac_m+7
    sbc dbf_m+7
    sta dac_m+7
double_dad_subnorm
    jsr double_d_norm                  ; renormalise (may be a big left shift)
    jmp double_d_pack
double_dad_cancel
    lda #0                       ; exact cancellation -> +0
    sta dac_s
    lda #D_ZERO
    sta dac_c
    jmp double_d_pack

; swap dac_* <-> dbf_*
double_d_swap_ab
    ldx dac_c
    lda dbf_c
    sta dac_c
    stx dbf_c
    ldx dac_s
    lda dbf_s
    sta dac_s
    stx dbf_s
    ldx dac_e
    lda dbf_e
    sta dac_e
    stx dbf_e
    ldx dac_e+1
    lda dbf_e+1
    sta dac_e+1
    stx dbf_e+1
    ldy #7
double_dsw_m
    ldx dac_m,y
    lda dbf_m,y
    sta dac_m,y
    txa
    sta dbf_m,y
    dey
    bpl double_dsw_m
    rts

; dbf_* -> dac_*
double_d_bf_to_ac
    lda dbf_c
    sta dac_c
    lda dbf_s
    sta dac_s
    lda dbf_e
    sta dac_e
    lda dbf_e+1
    sta dac_e+1
    ldy #7
double_dba_m
    lda dbf_m,y
    sta dac_m,y
    dey
    bpl double_dba_m
    rts

; compare dac_m vs dbf_m (64-bit unsigned): A = $FF/0/1
double_d_mant_cmp
    ldy #7
double_dmc_l
    lda dac_m,y
    cmp dbf_m,y
    bne double_dmc_diff
    dey
    bpl double_dmc_l
    lda #0
    rts
double_dmc_diff
    bcs double_dmc_gt
    lda #$FF
    rts
double_dmc_gt
    lda #1
    rts

; ---------------------------------------------------------------------
; d_mul -- d_ac *= mem(A/Y)
; 64x64 -> 128 shift-add (umul16's shape, one size up), then take the
; top 64 bits normalised, the rest a sticky.
; ---------------------------------------------------------------------
d_mul
    sta d_ptr
    sty d_ptr+1
    jsr double_d_unpack
    jsr double_d_ac_to_bf              ; operand -> dbf_*
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack               ; d_ac -> dac_*
    stz d_sticky
    lda dac_s
    eor dbf_s
    and #$80
    sta d_rsign

    lda dac_c
    cmp #D_NAN
    beq double_dml_nan
    lda dbf_c
    cmp #D_NAN
    beq double_dml_nan
    lda dac_c
    cmp #D_INF
    beq double_dml_ainf
    lda dbf_c
    cmp #D_INF
    beq double_dml_binf
    lda dac_c
    beq double_dml_zero
    lda dbf_c
    beq double_dml_zero
    jmp double_dml_mul
double_dml_ainf
    lda dbf_c
    beq double_dml_nan                 ; inf * 0
    bra double_dml_inf
double_dml_binf
    lda dac_c
    beq double_dml_nan                 ; 0 * inf
    bra double_dml_inf
double_dml_zero
    lda d_rsign
    sta dac_s
    lda #D_ZERO
    sta dac_c
    jmp double_d_pack
double_dml_nan
    lda #D_NAN
    sta dac_c
    jmp double_d_pack
double_dml_inf
    lda d_rsign
    sta dac_s
    lda #D_INF
    sta dac_c
    jmp double_d_pack
double_dml_mul
    lda #0                       ; product high half = 0
    ldx #7
double_dml_zh
    sta d_prod+8,x
    dex
    bpl double_dml_zh
    ldx #64
double_dml_loop
    lsr dbf_m+7
    ror dbf_m+6
    ror dbf_m+5
    ror dbf_m+4
    ror dbf_m+3
    ror dbf_m+2
    ror dbf_m+1
    ror dbf_m
    bcc double_dml_noadd
    clc
    lda d_prod+8 
    adc dac_m
    sta d_prod+8
    lda d_prod+9 
    adc dac_m+1
    sta d_prod+9
    lda d_prod+10
    adc dac_m+2
    sta d_prod+10
    lda d_prod+11
    adc dac_m+3
    sta d_prod+11
    lda d_prod+12
    adc dac_m+4
    sta d_prod+12
    lda d_prod+13
    adc dac_m+5
    sta d_prod+13
    lda d_prod+14
    adc dac_m+6
    sta d_prod+14
    lda d_prod+15
    adc dac_m+7
    bra double_dml_rot
double_dml_noadd
    lda d_prod+15
double_dml_rot
    ror
    sta d_prod+15
    ror d_prod+14
    ror d_prod+13
    ror d_prod+12
    ror d_prod+11
    ror d_prod+10
    ror d_prod+9
    ror d_prod+8
    ror d_prod+7
    ror d_prod+6
    ror d_prod+5
    ror d_prod+4
    ror d_prod+3
    ror d_prod+2
    ror d_prod+1
    ror d_prod
    dex
    beq double_dml_norm
    jmp double_dml_loop
double_dml_norm
    ; normalise: bit127 set -> adjust 64; else shift left 1, adjust 63
    ldy #64
    lda d_prod+15
    bmi double_dml_top
    asl d_prod
    rol d_prod+1
    rol d_prod+2
    rol d_prod+3
    rol d_prod+4
    rol d_prod+5
    rol d_prod+6
    rol d_prod+7
    rol d_prod+8
    rol d_prod+9
    rol d_prod+10
    rol d_prod+11
    rol d_prod+12
    rol d_prod+13
    rol d_prod+14
    rol d_prod+15
    ldy #63
double_dml_top
    sty d_t0
    lda d_prod+8 
    sta dac_m
    lda d_prod+9 
    sta dac_m+1
    lda d_prod+10
    sta dac_m+2
    lda d_prod+11
    sta dac_m+3
    lda d_prod+12
    sta dac_m+4
    lda d_prod+13
    sta dac_m+5
    lda d_prod+14
    sta dac_m+6
    lda d_prod+15
    sta dac_m+7
    lda d_prod
    ora d_prod+1
    ora d_prod+2
    ora d_prod+3
    ora d_prod+4
    ora d_prod+5
    ora d_prod+6
    ora d_prod+7
    beq double_dml_nost
    lda #1
    sta d_sticky
double_dml_nost
    clc                          ; exp = dac_e + dbf_e + adjust
    lda dac_e
    adc dbf_e
    sta dac_e
    lda dac_e+1
    adc dbf_e+1
    sta dac_e+1
    clc
    lda dac_e
    adc d_t0
    sta dac_e
    lda dac_e+1
    adc #0
    sta dac_e+1
    lda d_rsign
    sta dac_s
    lda #D_NORM
    sta dac_c
    jmp double_d_pack

; ---------------------------------------------------------------------
; d_div -- d_ac /= mem(A/Y)
; Q = floor((dividend_m << 63) / divisor_m), 64 restoring-division steps,
; then normalise; the remainder becomes the sticky.
; ---------------------------------------------------------------------
d_div
    sta d_ptr
    sty d_ptr+1
    jsr double_d_unpack
    jsr double_d_ac_to_bf              ; divisor -> dbf_*
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack               ; dividend (d_ac) -> dac_*
    stz d_sticky
    lda dac_s
    eor dbf_s
    and #$80
    sta d_rsign

    lda dac_c
    cmp #D_NAN
    beq double_ddv_nan
    lda dbf_c
    cmp #D_NAN
    beq double_ddv_nan
    lda dac_c
    cmp #D_INF
    bne double_ddv_afin
    lda dbf_c                    ; dividend inf
    cmp #D_INF
    beq double_ddv_nan                 ; inf / inf
    bra double_ddv_inf
double_ddv_afin
    lda dbf_c
    cmp #D_INF
    beq double_ddv_zero                ; finite / inf = 0
    lda dbf_c
    bne double_ddv_bnz
    lda dac_c                    ; divisor 0
    beq double_ddv_nan                 ; 0 / 0
    bra double_ddv_inf                 ; x / 0 = inf
double_ddv_bnz
    lda dac_c
    bne double_ddv_div
    bra double_ddv_zero                ; 0 / finite = 0
double_ddv_nan
    lda #D_NAN
    sta dac_c
    jmp double_d_pack
double_ddv_inf
    lda d_rsign
    sta dac_s
    lda #D_INF
    sta dac_c
    jmp double_d_pack
double_ddv_zero
    lda d_rsign
    sta dac_s
    lda #D_ZERO
    sta dac_c
    jmp double_d_pack
double_ddv_div
    ; dividend = dac_m << 63 in the 128-bit d_prod (= dac_m<<64 then >>1)
    lda dac_m  
    sta d_prod+8
    lda dac_m+1
    sta d_prod+9
    lda dac_m+2
    sta d_prod+10
    lda dac_m+3
    sta d_prod+11
    lda dac_m+4
    sta d_prod+12
    lda dac_m+5
    sta d_prod+13
    lda dac_m+6
    sta d_prod+14
    lda dac_m+7
    sta d_prod+15
    lda #0
    ldx #7
double_ddv_zl
    sta d_prod,x
    dex
    bpl double_ddv_zl
    lsr d_prod+15
    ror d_prod+14
    ror d_prod+13
    ror d_prod+12
    ror d_prod+11
    ror d_prod+10
    ror d_prod+9
    ror d_prod+8
    ror d_prod+7
    ror d_prod+6
    ror d_prod+5
    ror d_prod+4
    ror d_prod+3
    ror d_prod+2
    ror d_prod+1
    ror d_prod
    lda d_prod+8 
    sta d_rem            ; rem = high half
    lda d_prod+9 
    sta d_rem+1
    lda d_prod+10
    sta d_rem+2
    lda d_prod+11
    sta d_rem+3
    lda d_prod+12
    sta d_rem+4
    lda d_prod+13
    sta d_rem+5
    lda d_prod+14
    sta d_rem+6
    lda d_prod+15
    sta d_rem+7
    ldx #64
double_ddv_loop
    asl d_prod
    rol d_prod+1
    rol d_prod+2
    rol d_prod+3
    rol d_prod+4
    rol d_prod+5
    rol d_prod+6
    rol d_prod+7
    rol d_rem
    rol d_rem+1
    rol d_rem+2
    rol d_rem+3
    rol d_rem+4
    rol d_rem+5
    rol d_rem+6
    rol d_rem+7
    bcs double_ddv_sub                 ; bit 64 set -> definitely subtract
    sec
    lda d_rem  
    sbc dbf_m
    sta d_diff
    lda d_rem+1
    sbc dbf_m+1
    sta d_diff+1
    lda d_rem+2
    sbc dbf_m+2
    sta d_diff+2
    lda d_rem+3
    sbc dbf_m+3
    sta d_diff+3
    lda d_rem+4
    sbc dbf_m+4
    sta d_diff+4
    lda d_rem+5
    sbc dbf_m+5
    sta d_diff+5
    lda d_rem+6
    sbc dbf_m+6
    sta d_diff+6
    lda d_rem+7
    sbc dbf_m+7
    sta d_diff+7
    bcc double_ddv_noq                 ; borrow -> rem < divisor
    bra double_ddv_setq
double_ddv_sub
    sec
    lda d_rem  
    sbc dbf_m
    sta d_diff
    lda d_rem+1
    sbc dbf_m+1
    sta d_diff+1
    lda d_rem+2
    sbc dbf_m+2
    sta d_diff+2
    lda d_rem+3
    sbc dbf_m+3
    sta d_diff+3
    lda d_rem+4
    sbc dbf_m+4
    sta d_diff+4
    lda d_rem+5
    sbc dbf_m+5
    sta d_diff+5
    lda d_rem+6
    sbc dbf_m+6
    sta d_diff+6
    lda d_rem+7
    sbc dbf_m+7
    sta d_diff+7
double_ddv_setq
    lda d_diff  
    sta d_rem
    lda d_diff+1
    sta d_rem+1
    lda d_diff+2
    sta d_rem+2
    lda d_diff+3
    sta d_rem+3
    lda d_diff+4
    sta d_rem+4
    lda d_diff+5
    sta d_rem+5
    lda d_diff+6
    sta d_rem+6
    lda d_diff+7
    sta d_rem+7
    inc d_prod                   ; quotient bit
double_ddv_noq
    dex
    beq double_ddv_fin
    jmp double_ddv_loop
double_ddv_fin
    lda d_rem
    ora d_rem+1
    ora d_rem+2
    ora d_rem+3
    ora d_rem+4
    ora d_rem+5
    ora d_rem+6
    ora d_rem+7
    beq double_ddv_nost
    lda #1
    sta d_sticky
double_ddv_nost
    lda d_prod  
    sta dac_m
    lda d_prod+1
    sta dac_m+1
    lda d_prod+2
    sta dac_m+2
    lda d_prod+3
    sta dac_m+3
    lda d_prod+4
    sta dac_m+4
    lda d_prod+5
    sta dac_m+5
    lda d_prod+6
    sta dac_m+6
    lda d_prod+7
    sta dac_m+7
    sec                          ; exp = dac_e - dbf_e - 63
    lda dac_e
    sbc dbf_e
    sta dac_e
    lda dac_e+1
    sbc dbf_e+1
    sta dac_e+1
    sec
    lda dac_e
    sbc #63
    sta dac_e
    lda dac_e+1
    sbc #0
    sta dac_e+1
    lda d_rsign
    sta dac_s
    lda #D_NORM
    sta dac_c
    jsr double_d_norm                  ; quotient may need one left shift
    jmp double_d_pack

; ---------------------------------------------------------------------
; d_sqrt -- d_ac = sqrt(d_ac)
;
; A "magic constant" bit-hack picks a guess within ~3% (sqrt(4) and other
; powers of four come out exact), then Newton's iteration
; x' = (x + v/x)/2 refines it -- six passes reach full binary64. NaN for
; a negative operand; 0/inf/NaN pass through.
; ---------------------------------------------------------------------
d_sqrt
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    cmp #D_NAN
    beq double_dsq_ret
    cmp #D_ZERO
    beq double_dsq_ret
    lda dac_s
    bmi double_dsq_neg
    lda dac_c
    cmp #D_INF
    beq double_dsq_ret
    ; normal positive
    lda #<d_sqv
    ldy #>d_sqv
    jsr d_store                  ; save the operand
    ; guess bits = (value bits >> 1) + 0x1FF8000000000000
    lsr d_ac+7
    ror d_ac+6
    ror d_ac+5
    ror d_ac+4
    ror d_ac+3
    ror d_ac+2
    ror d_ac+1
    ror d_ac
    clc
    lda d_ac+6
    adc #$F8
    sta d_ac+6
    lda d_ac+7
    adc #$1F
    sta d_ac+7
    bcc double_dsq_gok
    ; (carry only if the exponent overflowed -- clamp, will still refine)
double_dsq_gok
    lda #<d_sqg
    ldy #>d_sqg
    jsr d_store
    ldx #6
double_dsq_it
    stx d_sqi
    lda #<d_sqv
    ldy #>d_sqv
    jsr d_load                   ; d_ac = v
    lda #<d_sqg
    ldy #>d_sqg
    jsr d_div                    ; d_ac = v / x
    lda #<d_sqg
    ldy #>d_sqg
    jsr d_add                    ; + x
    lda #<d_half
    ldy #>d_half
    jsr d_mul                    ; * 0.5
    lda #<d_sqg
    ldy #>d_sqg
    jsr d_store                  ; x = (x + v/x)/2
    ldx d_sqi
    dex
    bne double_dsq_it
    lda #<d_sqg
    ldy #>d_sqg
    jsr d_load
double_dsq_ret
    rts
double_dsq_neg
    lda #D_NAN
    sta dac_c
    jmp double_d_pack

; ---------------------------------------------------------------------
; d_exp -- d_ac = e`d_ac
;
; Range-reduce x = n*ln2 + r (n = trunc(x/ln2), |r| < ln2), sum the
; Taylor series e`r = 1 + r + r`2/2! + ..., then scale by 2`n (add n to
; the binary exponent). 0->1, +inf->+inf, -inf->+0, NaN->NaN.
; ---------------------------------------------------------------------
d_exp
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    cmp #D_NAN
    beq double_dex_ret
    cmp #D_ZERO
    beq double_dex_one
    cmp #D_INF
    bne double_dex_norm
    lda dac_s
    bmi double_dex_zero                ; e^-inf = 0
    rts                          ; e^+inf = +inf
double_dex_one
    lda #<d_one
    ldy #>d_one
    jmp d_load
double_dex_zero
    lda #D_ZERO
    sta dac_c
    stz dac_s
    jmp double_d_pack
double_dex_ret
    rts
double_dex_norm
    lda #<d_tv                   ; save x
    ldy #>d_tv
    jsr d_store
    lda #<d_log2e                ; v = x * log2e = x / ln2
    ldy #>d_log2e
    jsr d_mul
    jsr d_to_s32                 ; n = trunc(v)
    lda X16_P0
    sta d_tn16
    lda X16_P1
    sta d_tn16+1
    jsr d_from_s32               ; (double) n
    lda #<d_ln2
    ldy #>d_ln2
    jsr d_mul                    ; n * ln2
    lda #<d_tt
    ldy #>d_tt
    jsr d_store
    lda #<d_tv
    ldy #>d_tv
    jsr d_load                   ; x
    lda #<d_tt
    ldy #>d_tt
    jsr d_sub                    ; r = x - n*ln2
    lda #<d_tr
    ldy #>d_tr
    jsr d_store
    lda #<d_one                  ; sum = 1
    ldy #>d_one
    jsr d_load
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store
    lda #<d_one                  ; term = 1
    ldy #>d_one
    jsr d_load
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_store
    lda #1
    sta d_tkc
double_dex_loop
    lda #<d_tterm                ; term = term * r / k
    ldy #>d_tterm
    jsr d_load
    lda #<d_tr
    ldy #>d_tr
    jsr d_mul
    lda #<d_tt
    ldy #>d_tt
    jsr d_store
    lda d_tkc
    ldx #0
    jsr d_from_s16
    lda #<d_tk
    ldy #>d_tk
    jsr d_store
    lda #<d_tt
    ldy #>d_tt
    jsr d_load
    lda #<d_tk
    ldy #>d_tk
    jsr d_div
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_store
    lda #<d_tsum                 ; sum += term
    ldy #>d_tsum
    jsr d_load
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_add
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store
    inc d_tkc
    lda d_tkc
    cmp #19
    beq double_dex_scale
    jmp double_dex_loop
double_dex_scale
    lda #<d_tsum                 ; e`r
    ldy #>d_tsum
    jsr d_load
    lda #<d_ac                   ; multiply by 2`n: exponent += n
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    cmp #D_NORM
    bne double_dex_sdone               ; a zero cannot be scaled
    clc
    lda dac_e
    adc d_tn16
    sta dac_e
    lda dac_e+1
    adc d_tn16+1
    sta dac_e+1
    stz d_sticky
    jmp double_d_pack
double_dex_sdone
    rts

; ---------------------------------------------------------------------
; d_ln -- d_ac = ln(d_ac)
;
; Split value = m * 2`e with m in [0.75, 1.5) (halving m once if >= 1.5),
; so ln = e*ln2 + ln(m); ln(m) = 2*(t + t`3/3 + t`5/5 + ...) with
; t = (m-1)/(m+1), |t| <= 0.2. x<=0 -> -inf / NaN; +inf -> +inf.
; ---------------------------------------------------------------------
d_ln
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    cmp #D_NAN
    bne double_dln_c1
    rts                          ; NaN -> NaN
double_dln_c1
    cmp #D_ZERO
    bne double_dln_c2
    jmp double_dln_ninf                ; ln(0) = -inf
double_dln_c2
    lda dac_s
    bpl double_dln_c3
    jmp double_dln_nan                 ; ln(negative) = NaN
double_dln_c3
    lda dac_c
    cmp #D_INF
    bne double_dln_norm
    rts                          ; ln(+inf) = +inf
double_dln_norm
    ; e = dac_e + 63
    clc
    lda dac_e
    adc #63
    sta d_tn16
    lda dac_e+1
    adc #0
    sta d_tn16+1
    ; m = value with exponent -63 (in [1,2))
    lda #<-63
    sta dac_e
    lda #>-63
    sta dac_e+1
    stz dac_s
    lda #D_NORM
    sta dac_c
    stz d_sticky
    jsr double_d_pack
    ; if m >= 1.5: m /= 2, e++
    lda #<d_1p5
    ldy #>d_1p5
    jsr d_cmp
    cmp #$FF
    beq double_dln_mok
    lda #<d_half
    ldy #>d_half
    jsr d_mul
    inc d_tn16
    bne double_dln_mok
    inc d_tn16+1
double_dln_mok
    lda #<d_tv                   ; save m
    ldy #>d_tv
    jsr d_store
    lda #<d_one                  ; num = m - 1
    ldy #>d_one
    jsr d_sub
    lda #<d_tt
    ldy #>d_tt
    jsr d_store
    lda #<d_tv                   ; den = m + 1
    ldy #>d_tv
    jsr d_load
    lda #<d_one
    ldy #>d_one
    jsr d_add
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store
    lda #<d_tt                   ; t = num / den
    ldy #>d_tt
    jsr d_load
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_div
    lda #<d_tr
    ldy #>d_tr
    jsr d_store
    lda #<d_tr                   ; t2 = t*t
    ldy #>d_tr
    jsr d_mul
    lda #<d_tt
    ldy #>d_tt
    jsr d_store
    lda #<d_tr                   ; sum = t
    ldy #>d_tr
    jsr d_load
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store
    lda #<d_tr                   ; term = t
    ldy #>d_tr
    jsr d_load
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_store
    lda #3
    sta d_tkc
double_dln_loop
    lda #<d_tterm                ; term *= t2
    ldy #>d_tterm
    jsr d_load
    lda #<d_tt
    ldy #>d_tt
    jsr d_mul
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_store
    lda d_tkc                    ; sum += term / k
    ldx #0
    jsr d_from_s16
    lda #<d_tk
    ldy #>d_tk
    jsr d_store
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_load
    lda #<d_tk
    ldy #>d_tk
    jsr d_div
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_add
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store
    lda d_tkc
    clc
    adc #2
    sta d_tkc
    cmp #33
    bcs double_dln_series_done
    jmp double_dln_loop
double_dln_series_done
    lda #<d_tsum                 ; ln(m) = 2 * sum
    ldy #>d_tsum
    jsr d_load
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_add
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_store                  ; ln(m)
    ; + e * ln2
    lda d_tn16
    sta X16_P0
    lda d_tn16+1
    sta X16_P1
    and #$80
    beq double_dln_epos
    lda #$FF
double_dln_epos
    sta X16_P2
    sta X16_P3
    jsr d_from_s32               ; (double) e
    lda #<d_ln2
    ldy #>d_ln2
    jsr d_mul                    ; e * ln2
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_add                    ; + ln(m)
    rts
double_dln_nan
    lda #D_NAN
    sta dac_c
    jmp double_d_pack
double_dln_ninf
    lda #D_INF
    sta dac_c
    lda #$80
    sta dac_s
    jmp double_d_pack
double_dln_ret
    rts

; ---------------------------------------------------------------------
; d_pow -- d_ac = d_ac ^ mem(A/Y)   (base ^ exponent)
;
; x`y = exp(y * ln x). y == 0 gives 1 (even for x <= 0); otherwise a
; base <= 0 yields NaN/inf through d_ln (no integer-power special case).
; ---------------------------------------------------------------------
d_pow
    sta d_powyp
    sty d_powyp+1
    lda #<d_powx                 ; save the base
    ldy #>d_powx
    jsr d_store
    lda d_powyp                  ; y == 0 ?  -> 1
    ldy d_powyp+1
    jsr d_load
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    beq double_dpw_one
    lda #<d_powx                 ; exp(y * ln x)
    ldy #>d_powx
    jsr d_load
    jsr d_ln
    lda d_powyp
    ldy d_powyp+1
    jsr d_mul
    jmp d_exp
double_dpw_one
    lda #<d_one
    ldy #>d_one
    jmp d_load

; ---------------------------------------------------------------------
; d_sin / d_cos / d_tan -- d_ac = sin/cos/tan(d_ac)
;
; Reduce x = n*(pi/2) + r with |r| <= pi/4 (a single subtraction, so a
; huge x loses precision), Taylor sin(r)/cos(r), select by n mod 4.
; NaN/inf -> NaN; sin(0)=0, cos(0)=1.
; ---------------------------------------------------------------------
d_sin
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    cmp #D_NORM
    beq double_dsn_go
    cmp #D_ZERO
    beq double_dsn_ret
    lda #D_NAN
    sta dac_c
    jmp double_d_pack
double_dsn_ret
    rts
double_dsn_go
    jsr double_d_trig_reduce
    lda d_scq
    beq double_dsn_q0
    cmp #1
    beq double_dsn_q1
    cmp #2
    beq double_dsn_q2
    jsr double_d_cosr                  ; q3: -cos(r)
    jmp d_neg
double_dsn_q0
    jmp double_d_sinr
double_dsn_q1
    jmp double_d_cosr
double_dsn_q2
    jsr double_d_sinr                  ; q2: -sin(r)
    jmp d_neg

d_cos
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    cmp #D_NORM
    beq double_dcs_go
    cmp #D_ZERO
    bne double_dcs_nan
    lda #<d_one
    ldy #>d_one
    jmp d_load
double_dcs_nan
    lda #D_NAN
    sta dac_c
    jmp double_d_pack
double_dcs_go
    jsr double_d_trig_reduce
    lda d_scq
    beq double_dcs_q0
    cmp #1
    beq double_dcs_q1
    cmp #2
    beq double_dcs_q2
    jmp double_d_sinr                  ; q3: sin(r)
double_dcs_q0
    jmp double_d_cosr
double_dcs_q1
    jsr double_d_sinr                  ; q1: -sin(r)
    jmp d_neg
double_dcs_q2
    jsr double_d_cosr                  ; q2: -cos(r)
    jmp d_neg

d_tan
    lda #<d_tanx
    ldy #>d_tanx
    jsr d_store
    jsr d_sin
    lda #<d_tans
    ldy #>d_tans
    jsr d_store
    lda #<d_tanx
    ldy #>d_tanx
    jsr d_load
    jsr d_cos
    lda #<d_tanc
    ldy #>d_tanc
    jsr d_store
    lda #<d_tans
    ldy #>d_tans
    jsr d_load
    lda #<d_tanc
    ldy #>d_tanc
    jmp d_div

; ---------------------------------------------------------------------
; d_atan -- d_ac = atan(d_ac)
;
; Fold to x in [0, tan(pi/12)] via atan(-x)=-atan(x), atan(x)=pi/2-atan(1/x)
; for x>1, and atan(x)=pi/6+atan((x*sqrt3-1)/(x+sqrt3)) for x>tan(pi/12);
; then the fast series x - x`3/3 + x`5/5 - ...  +-inf -> +-pi/2.
; ---------------------------------------------------------------------
d_atan
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    cmp #D_NORM
    beq double_dat_go
    cmp #D_ZERO
    beq double_dat_ret
    cmp #D_INF
    beq double_dat_inf
    lda #D_NAN
    sta dac_c
    jmp double_d_pack
double_dat_ret
    rts
double_dat_inf
    lda dac_s
    php
    lda #<d_pihalf
    ldy #>d_pihalf
    jsr d_load
    plp
    bpl double_dat_ret
    jmp d_neg
double_dat_go
    stz d_atflags
    lda dac_s
    bpl double_dat_pos
    lda #1
    sta d_atflags                ; negx
    jsr d_abs
double_dat_pos
    lda #<d_one                  ; x > 1 ?  x = 1/x
    ldy #>d_one
    jsr d_cmp
    cmp #1
    bne double_dat_norecip
    lda #<d_atx
    ldy #>d_atx
    jsr d_store
    lda #<d_one
    ldy #>d_one
    jsr d_load
    lda #<d_atx
    ldy #>d_atx
    jsr d_div
    lda d_atflags
    ora #2                       ; recip
    sta d_atflags
double_dat_norecip
    lda #<d_tan15                ; x > tan(pi/12) ?
    ldy #>d_tan15
    jsr d_cmp
    cmp #1
    bne double_dat_nosixth
    lda #<d_atx                  ; x = (x*sqrt3 - 1)/(x + sqrt3)
    ldy #>d_atx
    jsr d_store
    lda #<d_sqrt3
    ldy #>d_sqrt3
    jsr d_mul
    lda #<d_one
    ldy #>d_one
    jsr d_sub
    lda #<d_atn
    ldy #>d_atn
    jsr d_store
    lda #<d_atx
    ldy #>d_atx
    jsr d_load
    lda #<d_sqrt3
    ldy #>d_sqrt3
    jsr d_add
    lda #<d_atd
    ldy #>d_atd
    jsr d_store
    lda #<d_atn
    ldy #>d_atn
    jsr d_load
    lda #<d_atd
    ldy #>d_atd
    jsr d_div
    lda d_atflags
    ora #4                       ; sixth
    sta d_atflags
double_dat_nosixth
    ; atan(r) = r - r`3/3 + r`5/5 - ...  Carry the power p = r`(2k+1) in
    ; d_atn (only ever *= -r`2, so its sign alternates); each term divides
    ; a COPY of p by (2k+1) -- p itself must not be divided.
    lda #<d_tr
    ldy #>d_tr
    jsr d_store                  ; r = reduced x
    jsr double_d_trig_nr2              ; d_tt = -r`2
    lda #<d_tr
    ldy #>d_tr
    jsr d_load
    lda #<d_atn
    ldy #>d_atn
    jsr d_store                  ; p = r
    lda #<d_tr
    ldy #>d_tr
    jsr d_load
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store                  ; sum = r
    lda #1
    sta d_tkc
double_dat_loop
    lda #<d_atn                  ; p *= -r`2
    ldy #>d_atn
    jsr d_load
    lda #<d_tt
    ldy #>d_tt
    jsr d_mul
    lda #<d_atn
    ldy #>d_atn
    jsr d_store
    lda d_tkc                    ; divisor = 2k+1
    asl
    clc
    adc #1
    ldx #0
    jsr d_from_s16
    lda #<d_tk
    ldy #>d_tk
    jsr d_store
    lda #<d_atn                  ; term = p / (2k+1)
    ldy #>d_atn
    jsr d_load
    lda #<d_tk
    ldy #>d_tk
    jsr d_div
    lda #<d_tsum                 ; sum += term
    ldy #>d_tsum
    jsr d_add
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store
    inc d_tkc
    lda d_tkc
    cmp #16
    beq double_dat_reassemble
    jmp double_dat_loop
double_dat_reassemble
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_load                   ; atan(r)
    lda d_atflags
    and #4
    beq double_dat_no6
    lda #<d_pi6
    ldy #>d_pi6
    jsr d_add                    ; + pi/6
double_dat_no6
    lda d_atflags
    and #2
    beq double_dat_norec2
    jsr d_neg                    ; pi/2 - result
    lda #<d_pihalf
    ldy #>d_pihalf
    jsr d_add
double_dat_norec2
    lda d_atflags
    and #1
    beq double_dat_fin
    jmp d_neg
double_dat_fin
    rts

; ---------------------------------------------------------------------
; d_sinh / d_cosh / d_tanh -- d_ac = sinh/cosh/tanh(d_ac), via exp
;   sinh = (e`x - e^-x)/2, cosh = (e`x + e^-x)/2, tanh = sinh/cosh.
; tanh saturates to +-1 for |x| >= 20 (where e`x would overflow) and
; propagates NaN. (sinh of a tiny x cancels e`x - e^-x -- ~ulp there.)
; ---------------------------------------------------------------------
d_sinh
    jsr double_d_hyp_exps              ; d_hypa = e`x, d_hypb = e^-x
    lda #<d_hypa
    ldy #>d_hypa
    jsr d_load
    lda #<d_hypb
    ldy #>d_hypb
    jsr d_sub                    ; e`x - e^-x
    lda #<d_half
    ldy #>d_half
    jmp d_mul                    ; / 2

d_cosh
    jsr double_d_hyp_exps
    lda #<d_hypa
    ldy #>d_hypa
    jsr d_load
    lda #<d_hypb
    ldy #>d_hypb
    jsr d_add                    ; e`x + e^-x
    lda #<d_half
    ldy #>d_half
    jmp d_mul

d_tanh
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    lda dac_c
    cmp #D_NAN
    bne double_dth_go
    rts                          ; NaN -> NaN
double_dth_go
    lda #<d_hypx                 ; save x (for the sign, and to restore)
    ldy #>d_hypx
    jsr d_store
    jsr d_abs
    lda #<d_hyp20
    ldy #>d_hyp20
    jsr d_cmp                    ; |x| < 20 ?
    cmp #$FF
    beq double_dth_small
    lda #<d_one                  ; |x| >= 20: tanh = sign(x)
    ldy #>d_one
    jsr d_load
    lda d_hypx+7
    bpl double_dth_ret
    jmp d_neg
double_dth_ret
    rts
double_dth_small
    lda #<d_hypx
    ldy #>d_hypx
    jsr d_load                   ; x
    jsr double_d_hyp_exps
    lda #<d_hypa                 ; num = e`x - e^-x
    ldy #>d_hypa
    jsr d_load
    lda #<d_hypb
    ldy #>d_hypb
    jsr d_sub
    lda #<d_hypn
    ldy #>d_hypn
    jsr d_store
    lda #<d_hypa                 ; den = e`x + e^-x
    ldy #>d_hypa
    jsr d_load
    lda #<d_hypb
    ldy #>d_hypb
    jsr d_add
    lda #<d_hypd
    ldy #>d_hypd
    jsr d_store
    lda #<d_hypn
    ldy #>d_hypn
    jsr d_load
    lda #<d_hypd
    ldy #>d_hypd
    jmp d_div                    ; num / den

; d_hypa = e`(d_ac), d_hypb = e`(-d_ac)
double_d_hyp_exps
    lda #<d_hypx
    ldy #>d_hypx
    jsr d_store                  ; save x
    lda #<d_hypx
    ldy #>d_hypx
    jsr d_load
    jsr d_exp
    lda #<d_hypa
    ldy #>d_hypa
    jsr d_store                  ; e`x
    lda #<d_hypx
    ldy #>d_hypx
    jsr d_load
    jsr d_neg
    jsr d_exp
    lda #<d_hypb
    ldy #>d_hypb
    jmp d_store                  ; e^-x

; x (d_ac) -> d_tr = r in [-pi/4, pi/4], d_scq = n mod 4
double_d_trig_reduce
    lda #<d_tv
    ldy #>d_tv
    jsr d_store                  ; save x
    lda #<d_pihalf
    ldy #>d_pihalf
    jsr d_div                    ; x / (pi/2)
    lda d_ac+7                   ; round to nearest: += copysign(0.5)
    bmi double_dtr_neg
    lda #<d_half
    ldy #>d_half
    jsr d_add
    bra double_dtr_trunc
double_dtr_neg
    lda #<d_half
    ldy #>d_half
    jsr d_sub
double_dtr_trunc
    jsr d_to_s32                 ; n
    lda X16_P0
    and #3
    sta d_scq
    jsr d_from_s32               ; (double) n
    lda #<d_pihalf
    ldy #>d_pihalf
    jsr d_mul                    ; n * (pi/2)
    lda #<d_tt
    ldy #>d_tt
    jsr d_store
    lda #<d_tv
    ldy #>d_tv
    jsr d_load                   ; x
    lda #<d_tt
    ldy #>d_tt
    jsr d_sub                    ; r = x - n*(pi/2)
    lda #<d_tr
    ldy #>d_tr
    jmp d_store

; sin(d_tr) via Taylor: sum = r, term *= -r`2/((2k)(2k+1)), sum += term
double_d_sinr
    jsr double_d_trig_nr2              ; d_tt = -r`2
    lda #<d_tr
    ldy #>d_tr
    jsr d_load
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store                  ; sum = r
    lda #<d_tr
    ldy #>d_tr
    jsr d_load
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_store                  ; term = r
    lda #1
    sta d_tkc
double_dsr_loop
    jsr double_d_trig_termstep         ; term *= -r`2
    lda d_tkc                    ; / (2k)
    asl
    ldx #0
    jsr double_d_trig_divk
    lda d_tkc                    ; / (2k+1)
    asl
    clc
    adc #1
    ldx #0
    jsr double_d_trig_divk
    jsr double_d_trig_addsum           ; sum += term
    inc d_tkc
    lda d_tkc
    cmp #10
    beq double_dsr_done
    jmp double_dsr_loop
double_dsr_done
    lda #<d_tsum
    ldy #>d_tsum
    jmp d_load

; cos(d_tr) via Taylor: sum = 1, term *= -r`2/((2k-1)(2k)), sum += term
double_d_cosr
    jsr double_d_trig_nr2              ; d_tt = -r`2
    lda #<d_one
    ldy #>d_one
    jsr d_load
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_store                  ; sum = 1
    lda #<d_one
    ldy #>d_one
    jsr d_load
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_store                  ; term = 1
    lda #1
    sta d_tkc
double_dcr_loop
    jsr double_d_trig_termstep         ; term *= -r`2
    lda d_tkc                    ; / (2k-1)
    asl
    sec
    sbc #1
    ldx #0
    jsr double_d_trig_divk
    lda d_tkc                    ; / (2k)
    asl
    ldx #0
    jsr double_d_trig_divk
    jsr double_d_trig_addsum
    inc d_tkc
    lda d_tkc
    cmp #10
    beq double_dcr_done
    jmp double_dcr_loop
double_dcr_done
    lda #<d_tsum
    ldy #>d_tsum
    jmp d_load

; term = term * (-r`2)   [-r`2 is in d_tt]
double_d_trig_termstep
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_load
    lda #<d_tt
    ldy #>d_tt
    jsr d_mul
    lda #<d_tterm
    ldy #>d_tterm
    jmp d_store

; term = term / (A:X as a small integer)
double_d_trig_divk
    jsr d_from_s16
    lda #<d_tk
    ldy #>d_tk
    jsr d_store
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_load
    lda #<d_tk
    ldy #>d_tk
    jsr d_div
    lda #<d_tterm
    ldy #>d_tterm
    jmp d_store

; sum += term
double_d_trig_addsum
    lda #<d_tsum
    ldy #>d_tsum
    jsr d_load
    lda #<d_tterm
    ldy #>d_tterm
    jsr d_add
    lda #<d_tsum
    ldy #>d_tsum
    jmp d_store

; d_tt = -(d_tr * d_tr)
double_d_trig_nr2
    lda #<d_tr
    ldy #>d_tr
    jsr d_load
    lda #<d_tr
    ldy #>d_tr
    jsr d_mul
    jsr d_neg
    lda #<d_tt
    ldy #>d_tt
    jmp d_store

; ---------------------------------------------------------------------
; d_from_str -- parse a decimal string into d_ac
;   in: A = low, Y = high of the string, X = length
;
; Accepts  [+/-] digits [ . digits ] [ (E|e) [+/-] digits ].  Digits are
; accumulated as a double (d_ac = d_ac*10 + digit), then scaled by
; 10`(exponent - fraction_digits) with repeated *10 / /10. Each step
; rounds, so a long mantissa can land a unit-in-the-last-place off -- fine
; for a calculator; a correctly-rounded parser is a later refinement.
; ---------------------------------------------------------------------
d_from_str
    sta dstr_ptr
    sty dstr_ptr+1
    stx dstr_len
    stz dstr_i
    stz dstr_neg
    stz dstr_frac
    stz dstr_exp
    stz dstr_exp+1
    jsr double_d_zero                  ; accumulator = 0
    lda #<dstr_acc
    ldy #>dstr_acc
    jsr d_store

    jsr double_dstr_peek               ; optional sign
    bcs double_dstr_int                ; empty: fall through the phases to scaling
    cmp #'-'
    bne double_dstr_ckplus
    inc dstr_neg
    jsr double_dstr_next
    bra double_dstr_int
double_dstr_ckplus
    cmp #'+'
    bne double_dstr_int
    jsr double_dstr_next
double_dstr_int
    jsr double_dstr_peek               ; integer digits
    bcs double_dstr_dot
    cmp #'0'
    bcc double_dstr_dot
    cmp #'9'+1
    bcs double_dstr_dot
    sec
    sbc #'0'
    jsr double_dstr_muladd
    jsr double_dstr_next
    bra double_dstr_int
double_dstr_dot
    jsr double_dstr_peek
    bcs double_dstr_exp0
    cmp #'.'
    bne double_dstr_exp0
    jsr double_dstr_next
double_dstr_frc
    jsr double_dstr_peek               ; fraction digits
    bcs double_dstr_exp0
    cmp #'0'
    bcc double_dstr_exp0
    cmp #'9'+1
    bcs double_dstr_exp0
    sec
    sbc #'0'
    jsr double_dstr_muladd
    inc dstr_frac
    jsr double_dstr_next
    bra double_dstr_frc
double_dstr_exp0
    jsr double_dstr_peek
    bcc double_dstr_e_has
    jmp double_dstr_scale
double_dstr_e_has
    cmp #'E'
    beq double_dstr_esgn
    cmp #'e'
    beq double_dstr_esgn
    jmp double_dstr_scale
double_dstr_esgn
    jsr double_dstr_next
    stz dstr_esign
    jsr double_dstr_peek
    bcc double_dstr_e_sgnok
    jmp double_dstr_scale
double_dstr_e_sgnok
    cmp #'-'
    bne double_dstr_eckp
    inc dstr_esign
    jsr double_dstr_next
    bra double_dstr_edig
double_dstr_eckp
    cmp #'+'
    bne double_dstr_edig
    jsr double_dstr_next
double_dstr_edig
    jsr double_dstr_peek               ; exponent digits -> dstr_exp
    bcs double_dstr_edone
    cmp #'0'
    bcc double_dstr_edone
    cmp #'9'+1
    bcs double_dstr_edone
    sec
    sbc #'0'
    pha
    ; dstr_exp = dstr_exp*10 + digit
    lda dstr_exp
    asl
    sta dstr_t
    lda dstr_exp+1
    rol
    sta dstr_t+1                  ; exp*2
    asl dstr_t
    rol dstr_t+1                  ; exp*4
    asl dstr_t
    rol dstr_t+1                  ; exp*8
    clc
    lda dstr_t
    adc dstr_exp
    sta dstr_t
    lda dstr_t+1
    adc dstr_exp+1
    sta dstr_t+1                  ; exp*8 + exp = exp*9
    clc
    lda dstr_t
    adc dstr_exp
    sta dstr_exp
    lda dstr_t+1
    adc dstr_exp+1
    sta dstr_exp+1               ; exp*10
    pla
    clc
    adc dstr_exp
    sta dstr_exp
    lda dstr_exp+1
    adc #0
    sta dstr_exp+1
    jsr double_dstr_next
    bra double_dstr_edig
double_dstr_edone
    lda dstr_esign
    beq double_dstr_scale
    sec                          ; negate the explicit exponent
    lda #0
    sbc dstr_exp
    sta dstr_exp
    lda #0
    sbc dstr_exp+1
    sta dstr_exp+1
double_dstr_scale
    sec                          ; finalexp = exp - fraction_digits
    lda dstr_exp
    sbc dstr_frac
    sta dstr_exp
    lda dstr_exp+1
    sbc #0
    sta dstr_exp+1
    lda #<dstr_acc               ; d_ac = accumulator
    ldy #>dstr_acc
    jsr d_load
    lda dstr_neg
    beq double_dstr_ns
    jsr d_neg
double_dstr_ns
    lda dstr_exp+1               ; scale by 10`finalexp
    bmi double_dstr_neg_exp
    lda dstr_exp                 ; positive: multiply
    ora dstr_exp+1
    beq double_dstr_ret
    lda dstr_exp
    sta dstr_cnt
    lda dstr_exp+1
    sta dstr_cnt+1
double_dstr_ml
    lda #<d_ten
    ldy #>d_ten
    jsr d_mul
    jsr double_dstr_deccnt
    bne double_dstr_ml
    rts
double_dstr_neg_exp
    sec                          ; count = -finalexp
    lda #0
    sbc dstr_exp
    sta dstr_cnt
    lda #0
    sbc dstr_exp+1
    sta dstr_cnt+1
double_dstr_dv
    lda #<d_ten
    ldy #>d_ten
    jsr d_div
    jsr double_dstr_deccnt
    bne double_dstr_dv
double_dstr_ret
    rts

; peek: A = char at dstr_i, carry clear; carry set at end of string
double_dstr_peek
    ldy dstr_i
    cpy dstr_len
    bcs double_dstr_pend
    lda (dstr_ptr),y
    clc
    rts
double_dstr_pend
    sec
    rts

double_dstr_next
    inc dstr_i
    rts

; accumulator = accumulator * 10 + A  (A = digit 0..9)
double_dstr_muladd
    pha
    lda #<dstr_acc
    ldy #>dstr_acc
    jsr d_load
    lda #<d_ten
    ldy #>d_ten
    jsr d_mul
    lda #<dstr_acc
    ldy #>dstr_acc
    jsr d_store                  ; acc *= 10
    pla
    ldx #0
    jsr d_from_s16               ; d_ac = digit
    lda #<dstr_acc
    ldy #>dstr_acc
    jsr d_add                    ; d_ac = digit + acc*10
    lda #<dstr_acc
    ldy #>dstr_acc
    jsr d_store
    rts

; dstr_cnt--, returns Z set when it reaches zero
double_dstr_deccnt
    lda dstr_cnt
    bne double_dstr_dcl
    dec dstr_cnt+1
double_dstr_dcl
    dec dstr_cnt
    lda dstr_cnt
    ora dstr_cnt+1
    rts

; ---------------------------------------------------------------------
; d_to_str -- format d_ac as a NUL-terminated decimal string
;   out: A = low, X = high of the string (in d_strbuf)
;
; Scales |value| into [1,10) (repeated *10 / /10 -- so a very large or
; small exponent loses low digits), extracts 17 digits, rounds to 16,
; strips trailing zeros, and lays out fixed notation for -4 <= exp <= 20
; or scientific "d.dddddE+NN" beyond. Correctly-rounded shortest output
; (Grisu/Ryu) is a later refinement; exact short values print exactly.
; ---------------------------------------------------------------------
d_to_str
    lda #<d_ac
    sta d_ptr
    lda #>d_ac
    sta d_ptr+1
    jsr double_d_unpack
    stz dts_bx
    lda dac_c
    cmp #D_NAN
    bne double_dts_s0
    jmp double_dts_nan
double_dts_s0
    lda dac_s
    bpl double_dts_sok
    lda #'-'
    jsr double_dts_emit
double_dts_sok
    lda dac_c
    cmp #D_INF
    bne double_dts_s1
    jmp double_dts_inf
double_dts_s1
    cmp #D_ZERO
    bne double_dts_s2
    jmp double_dts_zero
double_dts_s2
    jsr d_abs
    stz dts_e
    stz dts_e+1
double_dts_su
    lda #<d_ten
    ldy #>d_ten
    jsr d_cmp
    cmp #$FF
    beq double_dts_sd
    lda #<d_ten
    ldy #>d_ten
    jsr d_div
    inc dts_e
    bne double_dts_su
    inc dts_e+1
    bra double_dts_su
double_dts_sd
    lda #<d_one
    ldy #>d_one
    jsr d_cmp
    cmp #$FF
    bne double_dts_ext
    lda #<d_ten
    ldy #>d_ten
    jsr d_mul
    lda dts_e
    bne double_dts_sdl
    dec dts_e+1
double_dts_sdl
    dec dts_e
    bra double_dts_sd
double_dts_ext
    ldx #0
double_dts_extl
    stx dts_di
    jsr d_to_s32
    ldx dts_di
    lda X16_P0
    sta dts_dig,x
    lda #<dts_val
    ldy #>dts_val
    jsr d_store
    lda X16_P0
    ldx #0
    jsr d_from_s16
    lda #<dts_digd
    ldy #>dts_digd
    jsr d_store
    lda #<dts_val
    ldy #>dts_val
    jsr d_load
    lda #<dts_digd
    ldy #>dts_digd
    jsr d_sub
    lda #<d_ten
    ldy #>d_ten
    jsr d_mul
    ldx dts_di
    inx
    cpx #17
    bne double_dts_extl
    ; round the 17th digit into the 16
    lda dts_dig+16
    cmp #5
    bcc double_dts_strip
    ldx #15
double_dts_rul
    inc dts_dig,x
    lda dts_dig,x
    cmp #10
    bcc double_dts_strip
    lda #0
    sta dts_dig,x
    dex
    bpl double_dts_rul
    lda #1                       ; carried past the top: 9.99.. -> 10.0
    sta dts_dig
    inc dts_e
    bne double_dts_strip
    inc dts_e+1
double_dts_strip
    ldx #15
double_dts_strl
    lda dts_dig,x
    bne double_dts_strd
    dex
    bpl double_dts_strl
double_dts_strd
    inx
    stx dts_ndig
    ; choose fixed vs scientific
    lda dts_e+1
    beq double_dts_epos
    cmp #$FF
    bne double_dts_scij
    lda dts_e
    cmp #$FC                     ; E >= -4 ?
    bcs double_dts_fixed
    bra double_dts_scij
double_dts_epos
    lda dts_e
    cmp #21                      ; E <= 20 ?
    bcc double_dts_fixed
double_dts_scij
    jmp double_dts_sci
double_dts_fixed
    clc                          ; P = E + 1 (point position)
    lda dts_e
    adc #1
    sta dts_p
    lda dts_e+1
    adc #0
    sta dts_p+1
    lda dts_p+1
    bmi double_dts_lead0
    lda dts_p
    ora dts_p+1
    beq double_dts_lead0
    lda dts_p                    ; P > 0
    cmp dts_ndig
    bcc double_dts_mid                 ; P < ndig -> point in the middle
    ldx #0                       ; P >= ndig -> integer + trailing zeros
double_dts_intl
    cpx dts_ndig
    beq double_dts_intz
    lda dts_dig,x
    jsr double_dts_emitd
    inx
    bra double_dts_intl
double_dts_intz
    lda dts_p
    sec
    sbc dts_ndig
    tax
double_dts_intzl
    cpx #0
    beq double_dts_donej
    lda #'0'
    jsr double_dts_emit
    dex
    bra double_dts_intzl
double_dts_donej
    jmp double_dts_done
double_dts_mid
    ldx #0
double_dts_mid1
    cpx dts_p
    beq double_dts_middot
    lda dts_dig,x
    jsr double_dts_emitd
    inx
    bra double_dts_mid1
double_dts_middot
    lda #'.'
    jsr double_dts_emit
double_dts_mid2
    cpx dts_ndig
    beq double_dts_donej
    lda dts_dig,x
    jsr double_dts_emitd
    inx
    bra double_dts_mid2
double_dts_lead0
    lda #'0'
    jsr double_dts_emit
    lda #'.'
    jsr double_dts_emit
    sec                          ; (-P) leading zeros
    lda #0
    sbc dts_p
    tax
double_dts_l0l
    cpx #0
    beq double_dts_l0d
    lda #'0'
    jsr double_dts_emit
    dex
    bra double_dts_l0l
double_dts_l0d
    ldx #0
double_dts_l0dl
    cpx dts_ndig
    beq double_dts_donej
    lda dts_dig,x
    jsr double_dts_emitd
    inx
    bra double_dts_l0dl
double_dts_sci
    lda dts_dig
    jsr double_dts_emitd
    lda dts_ndig
    cmp #2
    bcc double_dts_scie
    lda #'.'
    jsr double_dts_emit
    ldx #1
double_dts_scil
    cpx dts_ndig
    beq double_dts_scie
    lda dts_dig,x
    jsr double_dts_emitd
    inx
    bra double_dts_scil
double_dts_scie
    lda #'E'
    jsr double_dts_emit
    lda dts_e+1
    bpl double_dts_scipos
    lda #'-'
    jsr double_dts_emit
    sec
    lda #0
    sbc dts_e
    sta dts_e
    lda #0
    sbc dts_e+1
    sta dts_e+1
    bra double_dts_scimag
double_dts_scipos
    lda #'+'
    jsr double_dts_emit
double_dts_scimag
    jsr double_dts_edec
    bra double_dts_done
double_dts_nan
    lda #'N'
    jsr double_dts_emit
    lda #'A'
    jsr double_dts_emit
    lda #'N'
    jsr double_dts_emit
    bra double_dts_done
double_dts_inf
    lda #'I'
    jsr double_dts_emit
    lda #'N'
    jsr double_dts_emit
    lda #'F'
    jsr double_dts_emit
    bra double_dts_done
double_dts_zero
    lda #'0'
    jsr double_dts_emit
double_dts_done
    ldx dts_bx
    lda #0
    sta d_strbuf,x
    lda #<d_strbuf
    ldx #>d_strbuf
    rts

; A -> d_strbuf[dts_bx], dts_bx++ . Uses Y (not X): the digit loops that
; call this keep their index in X.
double_dts_emit
    ldy dts_bx
    sta d_strbuf,y
    iny
    sty dts_bx
    rts

; A (0..9) -> emit as an ASCII digit
double_dts_emitd
    clc
    adc #'0'
    bra double_dts_emit

; emit dts_e (0..999) in decimal, no leading zeros
double_dts_edec
    stz dts_lead
    ldx #0                       ; hundreds
double_dts_ed_h
    lda dts_e
    sec
    sbc #100
    tay
    lda dts_e+1
    sbc #0
    bcc double_dts_ed_hd
    sty dts_e
    sta dts_e+1
    inx
    bra double_dts_ed_h
double_dts_ed_hd
    cpx #0
    beq double_dts_ed_t
    txa
    jsr double_dts_emitd
    inc dts_lead
double_dts_ed_t
    ldx #0                       ; tens
double_dts_ed_tl
    lda dts_e
    cmp #10
    bcc double_dts_ed_td
    sbc #10
    sta dts_e
    inx
    bra double_dts_ed_tl
double_dts_ed_td
    cpx #0
    bne double_dts_ed_te
    lda dts_lead
    beq double_dts_ed_u
double_dts_ed_te
    txa
    jsr double_dts_emitd
double_dts_ed_u
    lda dts_e
    jsr double_dts_emitd
    rts

; ---------------------------------------------------------------------
; internal: unpack, copy, normalise, pack
; ---------------------------------------------------------------------

; (d_ptr) 8 packed bytes -> dac_*  (dac_c/s/e/m)
double_d_unpack
    ldy #7
double_dun_cp
    lda (d_ptr),y
    sta d_ub,y
    dey
    bpl double_dun_cp

    lda d_ub+7                   ; sign
    and #$80
    sta dac_s

    lda d_ub+7                   ; biased exp = (b7&$7F)<<4 | (b6>>4)
    and #$7F
    sta dac_e
    stz dac_e+1
    asl dac_e
    rol dac_e+1
    asl dac_e
    rol dac_e+1
    asl dac_e
    rol dac_e+1
    asl dac_e
    rol dac_e+1
    lda d_ub+6
    lsr
    lsr
    lsr
    lsr
    ora dac_e
    sta dac_e                    ; dac_e:dac_e+1 = biased 0..2047

    lda dac_e                    ; biased == 0 -> zero
    ora dac_e+1
    bne double_dun_notz
    lda #D_ZERO
    sta dac_c
    lda #0
    ldy #7
double_dun_zm
    sta dac_m,y
    dey
    bpl double_dun_zm
    rts
double_dun_notz
    lda dac_e+1                  ; biased == 2047 -> inf/nan
    cmp #>2047
    bne double_dun_normal
    lda dac_e
    cmp #<2047
    bne double_dun_normal
    lda d_ub                     ; mantissa all zero -> inf
    ora d_ub+1
    ora d_ub+2
    ora d_ub+3
    ora d_ub+4
    ora d_ub+5
    sta d_t0
    lda d_ub+6
    and #$0F
    ora d_t0
    bne double_dun_nan
    lda #D_INF
    sta dac_c
    rts
double_dun_nan
    lda #D_NAN
    sta dac_c
    rts
double_dun_normal
    lda #D_NORM
    sta dac_c
    ; significand = (1<<52) | frac52, placed at bits 0..52, then << 11
    lda d_ub  
    sta dac_m
    lda d_ub+1
    sta dac_m+1
    lda d_ub+2
    sta dac_m+2
    lda d_ub+3
    sta dac_m+3
    lda d_ub+4
    sta dac_m+4
    lda d_ub+5
    sta dac_m+5
    lda d_ub+6
    and #$0F
    ora #$10                     ; implicit leading 1 (bit 52 -> byte6 bit4)
    sta dac_m+6
    stz dac_m+7
    ; << 8
    lda dac_m+6
    sta dac_m+7
    lda dac_m+5
    sta dac_m+6
    lda dac_m+4
    sta dac_m+5
    lda dac_m+3
    sta dac_m+4
    lda dac_m+2
    sta dac_m+3
    lda dac_m+1
    sta dac_m+2
    lda dac_m  
    sta dac_m+1
    stz dac_m
    ; << 3
    asl dac_m
    rol dac_m+1
    rol dac_m+2
    rol dac_m+3
    rol dac_m+4
    rol dac_m+5
    rol dac_m+6
    rol dac_m+7
    asl dac_m
    rol dac_m+1
    rol dac_m+2
    rol dac_m+3
    rol dac_m+4
    rol dac_m+5
    rol dac_m+6
    rol dac_m+7
    asl dac_m
    rol dac_m+1
    rol dac_m+2
    rol dac_m+3
    rol dac_m+4
    rol dac_m+5
    rol dac_m+6
    rol dac_m+7
    ; exponent = biased - 1086
    sec
    lda dac_e
    sbc #<1086
    sta dac_e
    lda dac_e+1
    sbc #>1086
    sta dac_e+1
    rts

; dac_* -> dbf_*
double_d_ac_to_bf
    lda dac_c
    sta dbf_c
    lda dac_s
    sta dbf_s
    lda dac_e
    sta dbf_e
    lda dac_e+1
    sta dbf_e+1
    ldy #7
double_dab_m
    lda dac_m,y
    sta dbf_m,y
    dey
    bpl double_dab_m
    rts

; normalise dac_m so bit 63 = 1, adjusting dac_e; all-zero -> true zero
double_d_norm
double_dnm_chk
    lda dac_m+7
    bmi double_dnm_done
    lda dac_m
    ora dac_m+1
    ora dac_m+2
    ora dac_m+3
    ora dac_m+4
    ora dac_m+5
    ora dac_m+6
    ora dac_m+7
    bne double_dnm_sh
    lda #D_ZERO
    sta dac_c
    rts
double_dnm_sh
    asl dac_m
    rol dac_m+1
    rol dac_m+2
    rol dac_m+3
    rol dac_m+4
    rol dac_m+5
    rol dac_m+6
    rol dac_m+7
    lda dac_e
    bne double_dnm_nolo
    dec dac_e+1
double_dnm_nolo
    dec dac_e
    bra double_dnm_chk
double_dnm_done
    rts

; d_ac = +0
double_d_zero
    lda #0
    ldy #7
double_dz_l
    sta d_ac,y
    dey
    bpl double_dz_l
    rts

; d_ac = +/- 0 (keep dac_s)
double_d_zero_signed
    lda #0
    ldy #6
double_dzs_l
    sta d_ac,y
    dey
    bpl double_dzs_l
    lda dac_s
    sta d_ac+7
    rts

; pack dac_* (normalised) into d_ac with round-to-nearest-even.
; overflow -> infinity, underflow -> zero.
double_d_pack
    lda dac_c
    cmp #D_NORM
    beq double_dpk_norm
    cmp #D_INF
    bne double_dpk_notinf
    jmp double_dpk_inf
double_dpk_notinf
    cmp #D_NAN
    bne double_dpk_notnan
    jmp double_dpk_nan
double_dpk_notnan
    jmp double_d_zero_signed
double_dpk_norm
    ldy #7                       ; work on a copy (a round carry may renorm)
double_dpk_cpm
    lda dac_m,y
    sta d_work,y
    dey
    bpl double_dpk_cpm
    ; drop bits 10..0. R = bit 10, S = OR(bits 9..0)
    lda d_work+1
    and #$04                     ; bit 10
    sta d_t0                     ; R
    lda d_work
    sta d_t1
    lda d_work+1
    and #$03                     ; bits 9..8
    ora d_t1
    ora d_sticky                 ; bits lost during alignment / mul / div
    sta d_t1                     ; S
    lda d_work+1                 ; clear bits 10..8
    and #$F8
    sta d_work+1
    stz d_work                   ; clear bits 7..0
    ; round to nearest even
    lda d_t0
    beq double_dpk_rounded             ; R = 0: truncate
    lda d_t1
    bne double_dpk_up                  ; R=1, S!=0: up
    lda d_work+1                 ; tie: up only if bit 11 (lsb kept) is set
    and #$08
    beq double_dpk_rounded
double_dpk_up
    clc
    lda d_work+1
    adc #$08
    sta d_work+1
    lda d_work+2
    adc #0
    sta d_work+2
    lda d_work+3
    adc #0
    sta d_work+3
    lda d_work+4
    adc #0
    sta d_work+4
    lda d_work+5
    adc #0
    sta d_work+5
    lda d_work+6
    adc #0
    sta d_work+6
    lda d_work+7
    adc #0
    sta d_work+7
    bcc double_dpk_rounded
    ror d_work+7
    ror d_work+6
    ror d_work+5
    ror d_work+4
    ror d_work+3
    ror d_work+2
    ror d_work+1
    ror d_work
    lda #$80
    ora d_work+7
    sta d_work+7
    inc dac_e
    bne double_dpk_rounded
    inc dac_e+1
double_dpk_rounded
    clc                          ; biased = dac_e + 1086
    lda dac_e
    adc #<1086
    sta d_bias
    lda dac_e+1
    adc #>1086
    sta d_bias+1
    lda d_bias+1
    bmi double_dpk_under               ; biased < 0
    bne double_dpk_maybe               ; >= 256
    bra double_dpk_asm
double_dpk_maybe
    lda d_bias+1
    cmp #>2047
    bcc double_dpk_asm
    bne double_dpk_ovf
    lda d_bias
    cmp #<2047
    bcc double_dpk_asm
double_dpk_ovf
    jmp double_dpk_inf
double_dpk_under
    jmp double_d_zero_signed
double_dpk_asm
    ; significand >> 11 (drop the low 11 bits already cleared): >>8 then >>3
    lda d_work+1
    sta d_work
    lda d_work+2
    sta d_work+1
    lda d_work+3
    sta d_work+2
    lda d_work+4
    sta d_work+3
    lda d_work+5
    sta d_work+4
    lda d_work+6
    sta d_work+5
    lda d_work+7
    sta d_work+6
    stz d_work+7
    lsr d_work+6
    ror d_work+5
    ror d_work+4
    ror d_work+3
    ror d_work+2
    ror d_work+1
    ror d_work
    lsr d_work+6
    ror d_work+5
    ror d_work+4
    ror d_work+3
    ror d_work+2
    ror d_work+1
    ror d_work
    lsr d_work+6
    ror d_work+5
    ror d_work+4
    ror d_work+3
    ror d_work+2
    ror d_work+1
    ror d_work
    ; d_work[0..6] = 53-bit significand; bit 52 (implicit) at byte6 bit4
    lda d_work  
    sta d_ac
    lda d_work+1
    sta d_ac+1
    lda d_work+2
    sta d_ac+2
    lda d_work+3
    sta d_ac+3
    lda d_work+4
    sta d_ac+4
    lda d_work+5
    sta d_ac+5
    lda d_work+6                 ; frac 51..48 (drop implicit bit 4)
    and #$0F
    sta d_t0
    lda d_bias                   ; byte6 = (biased low nibble << 4) | frac
    asl
    asl
    asl
    asl
    ora d_t0
    sta d_ac+6
    lda d_bias                   ; byte7 = sign | (biased >> 4)
    lsr
    lsr
    lsr
    lsr
    sta d_t0
    lda d_bias+1
    asl
    asl
    asl
    asl
    ora d_t0
    and #$7F
    ora dac_s
    sta d_ac+7
    rts
double_dpk_inf
    stz d_ac
    stz d_ac+1
    stz d_ac+2
    stz d_ac+3
    stz d_ac+4
    stz d_ac+5
    lda #$F0
    sta d_ac+6
    lda dac_s
    ora #$7F
    sta d_ac+7
    rts
double_dpk_nan
    lda #$FF
    sta d_ac
    sta d_ac+1
    sta d_ac+2
    sta d_ac+3
    sta d_ac+4
    sta d_ac+5
    lda #$F8
    sta d_ac+6
    lda #$7F
    sta d_ac+7
    rts

; ---------------------------------------------------------------------
; state
; ---------------------------------------------------------------------
d_ac  .fill 8, 0                ; the packed accumulator

dac_c .byte 0
dac_s .byte 0
dac_e .word 0
dac_m .fill 8, 0

dbf_c .byte 0
dbf_s .byte 0
dbf_e .word 0
dbf_m .fill 8, 0

d_ub     .fill 8, 0
d_work   .fill 8, 0
d_cnt    .word 0
d_bias   .word 0
d_t0     .byte 0
d_t1     .byte 0
d_sticky .byte 0
d_rsign  .byte 0
d_prod   .fill 16, 0
d_rem    .fill 8, 0
d_diff   .fill 8, 0

d_ten    .byte $00,$00,$00,$00,$00,$00,$24,$40   ; 10.0
d_one    .byte $00,$00,$00,$00,$00,$00,$F0,$3F   ; 1.0
d_half   .byte $00,$00,$00,$00,$00,$00,$E0,$3F   ; 0.5

d_sqv    .fill 8, 0
d_sqg    .fill 8, 0
d_sqi    .byte 0

d_ln2    .byte $EF,$39,$FA,$FE,$42,$2E,$E6,$3F   ; ln 2  = 0.6931471805599453
d_log2e  .byte $FE,$82,$2B,$65,$47,$15,$F7,$3F   ; 1/ln2 = 1.4426950408889634
d_1p5    .byte $00,$00,$00,$00,$00,$00,$F8,$3F   ; 1.5
d_pihalf .byte $18,$2D,$44,$54,$FB,$21,$F9,$3F   ; pi/2 = 1.5707963267948966
d_pi6    .byte $66,$73,$2D,$38,$52,$C1,$E0,$3F   ; pi/6 = 0.5235987755982988
d_sqrt3  .byte $AA,$4C,$58,$E8,$7A,$B6,$FB,$3F   ; sqrt3 = 1.7320508075688772
d_tan15  .byte $56,$CD,$9E,$5E,$14,$26,$D1,$3F   ; tan(pi/12) = 0.26794919243112270
d_hyp20  .byte $00,$00,$00,$00,$00,$00,$34,$40   ; 20.0 (tanh saturation cutoff)

d_tv     .fill 8, 0                              ; transcendental scratch
d_tr     .fill 8, 0
d_tt     .fill 8, 0
d_tsum   .fill 8, 0
d_tterm  .fill 8, 0
d_tk     .fill 8, 0
d_tn16   .word 0
d_tkc    .byte 0
d_powx   .fill 8, 0
d_powyp  .word 0
d_scq    .byte 0
d_tanx   .fill 8, 0
d_tans   .fill 8, 0
d_tanc   .fill 8, 0
d_atflags .byte 0
d_atx    .fill 8, 0
d_atn    .fill 8, 0
d_atd    .fill 8, 0
d_hypx   .fill 8, 0
d_hypa   .fill 8, 0
d_hypb   .fill 8, 0
d_hypn   .fill 8, 0
d_hypd   .fill 8, 0

dstr_len   .byte 0
dstr_i     .byte 0
dstr_neg   .byte 0
dstr_frac  .byte 0
dstr_esign .byte 0
dstr_exp   .word 0
dstr_t     .word 0
dstr_cnt   .word 0
dstr_acc   .fill 8, 0

dts_bx    .byte 0
dts_di    .byte 0
dts_ndig  .byte 0
dts_lead  .byte 0
dts_e     .word 0
dts_p     .word 0
dts_dig   .fill 18, 0
dts_val   .fill 8, 0
dts_digd  .fill 8, 0
d_strbuf  .fill 26, 0

; (end zone)
.endif
.if xuse_string
; --- inline string/string.asm ---
;ACME
; =====================================================================
; x16lib :: string/string.asm -- 0-terminated string fundamentals
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The core of the string library: measure, copy, append, compare, hash.
; Strings are NUL-terminated and passed by pointer in A (low) / X (high),
; the same convention as screen_puts / ser_puts. A second string (the
; target of a copy, the other side of a compare) goes in X16_P0/P1.
; Lengths are bytes, so strings are at most 255 characters (plus the NUL);
; there are no bounds checks -- make your target buffers big enough.
;
;       lda #<hello : ldx #>hello
;       jsr str_length                ; Y = 5
;       lda #<src : ldx #>src
;       lda #<dst : sta X16_P0
;       lda #>dst : sta X16_P1
;       jsr str_copy                  ; dst = src, Y = length
;
; The case, search, slice and classification routines live in their own
; files (X16_USE_STRING_CASE / _FIND / _SLICE / _CTYPE).
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; str_length -- in: A = low, X = high.  out: Y = length (A clobbered)
; Counts up to the first NUL. A string of 256+ bytes reports 0.
; ---------------------------------------------------------------------
str_length
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    beq _done
    iny
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; str_copy -- copy a string, overwriting the target.
;   in:  A = source low, X = source high, X16_P0/P1 = target
;   out: Y = length copied
; ---------------------------------------------------------------------
str_copy
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    sta (X16_P0),y              ; copies the NUL too, then stops
    beq _done
    iny
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; str_ncopy -- copy at most maxlength bytes, then NUL-terminate.
;   in:  A = source low, X = source high, X16_P0/P1 = target,
;        Y = maxlength
;   out: Y = length of the target string
; ---------------------------------------------------------------------
str_ncopy
    sta X16_T0
    stx X16_T1
    sty X16_T2                  ; maxlength
    ldy #0
_loop
    cpy X16_T2
    beq _cap                    ; hit the cap
    lda (X16_T0),y
    sta (X16_P0),y
    beq _done                   ; copied the NUL
    iny
    bne _loop
_cap
    lda #0
    sta (X16_P0),y              ; terminate at the cap
_done
    rts

; ---------------------------------------------------------------------
; str_append -- append a suffix to a target string.
;   in:  A = target low, X = target high, X16_P0/P1 = suffix
;   out: A = length of the resulting string
; ---------------------------------------------------------------------
str_append
    jsr str_length              ; T0/T1 = target, Y = its length
    sty X16_T2
    tya                         ; T0/T1 += length -> the append point
    clc
    adc X16_T0
    sta X16_T0
    bcc _nc
    inc X16_T1
_nc
    ldy #0
_loop
    lda (X16_P0),y              ; copy the suffix in
    sta (X16_T0),y
    beq _done
    iny
    bne _loop
_done
    tya                         ; result length = target + suffix
    clc
    adc X16_T2
    rts

; ---------------------------------------------------------------------
; str_nappend -- append, but never let the target exceed maxlength.
;   in:  A = target low, X = target high, X16_P0/P1 = suffix,
;        Y = maxlength
;   out: A = length of the resulting string (unchanged if it would
;        overflow the cap)
; ---------------------------------------------------------------------
str_nappend
    sty X16_T3                  ; maxlength
    jsr str_length              ; T0/T1 = target, Y = its length
    sty X16_T2                  ; current length
    cpy X16_T3
    bcs _toosmall               ; length >= max: no room, leave it be
    lda X16_T3                  ; room = max - length
    sec
    sbc X16_T2
    sta X16_T3
    lda X16_T2                  ; T0/T1 += length -> the append point
    clc
    adc X16_T0
    sta X16_T0
    bcc _nc
    inc X16_T1
_nc
    ldy #0
_loop
    cpy X16_T3                  ; stop at the room limit
    beq _cap
    lda (X16_P0),y
    sta (X16_T0),y
    beq _done
    iny
    bne _loop
_cap
    lda #0
    sta (X16_T0),y              ; terminate at the cap
_done
    tya                         ; result length = old length + appended
    clc
    adc X16_T2
    rts
_toosmall
    lda X16_T2                  ; unchanged length
    rts

; ---------------------------------------------------------------------
; str_compare -- compare two strings, case-sensitively, for sorting.
;   in:  A = string1 low, X = string1 high, X16_P0/P1 = string2
;   out: A = $FF (-1) if string1 < string2, 0 if equal, 1 if greater
; ---------------------------------------------------------------------
str_compare
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y              ; string1 char
    beq _s1end
    cmp (X16_P0),y              ; vs string2 char
    bne _diff
    iny
    bne _loop
    lda #0                      ; ran the whole page: equal
    rts
_s1end
    lda (X16_P0),y              ; string1 ended; string2 too?
    beq _equal
    lda #$FF                    ; string1 is the shorter -> before
    rts
_diff
    bcs _greater                ; carry from cmp: set if s1 >= s2
    lda #$FF
    rts
_greater
    lda #1
    rts
_equal
    lda #0
    rts

; ---------------------------------------------------------------------
; str_hash -- an 8-bit rolling hash of the string.
;   in:  A = low, X = high.  out: A = hash
;   hash(-1) = 179; hash(i) = rol(hash(i-1)) XOR string[i]
; ---------------------------------------------------------------------
str_hash
    sta X16_T0
    stx X16_T1
    lda #179
    sta X16_T2
    ldy #0
    clc
_loop
    lda (X16_T0),y
    beq _done
    rol X16_T2
    eor X16_T2
    sta X16_T2
    iny
    bne _loop
_done
    lda X16_T2
    rts

; (end zone)
.endif
.if xuse_string_ctype
; --- inline string/ctype.asm ---
;ACME
; =====================================================================
; x16lib :: string/ctype.asm -- single-character classification
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Character predicates, each taking the character in A and returning the
; answer in the carry (set = yes). Digits, hex digits and whitespace mean
; the same thing in PETSCII and ISO, so they have one routine each; the
; case-sensitive ones (upper / letter / print) come in a PETSCII form and
; an _iso form, because the two encodings place the letters differently.
;
;       lda mychar
;       jsr str_isdigit
;       bcs it_is_a_digit
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; str_isdigit -- carry set if A is '0'..'9'
; ---------------------------------------------------------------------
str_isdigit
    cmp #'0'
    bcc _no
    cmp #'9'+1
    bcs _no
    sec
    rts
_no
    clc
    rts

; ---------------------------------------------------------------------
; str_isxdigit -- carry set if A is a hex digit (0-9, A-F, a-f)
; ---------------------------------------------------------------------
str_isxdigit
    cmp #'0'
    bcc _no
    cmp #'9'+1
    bcc _yes
    cmp #'A'
    bcc _no
    cmp #'F'+1
    bcc _yes
    cmp #'a'
    bcc _no
    cmp #'f'+1
    bcc _yes
_no
    clc
    rts
_yes
    sec
    rts

; ---------------------------------------------------------------------
; str_islower -- carry set if A is 'a'..'z' (97-122). Same either encoding.
; ---------------------------------------------------------------------
str_islower
    cmp #'a'
    bcc _no
    cmp #'z'+1
    bcs _no
    sec
    rts
_no
    clc
    rts

; ---------------------------------------------------------------------
; str_isupper -- PETSCII: the two upper-case ranges, 97-122 and 193-218
; ---------------------------------------------------------------------
str_isupper
    cmp #97
    bcc _no
    cmp #122+1
    bcc _yes
    cmp #193
    bcc _no
    cmp #218+1
    bcc _yes
_no
    clc
    rts
_yes
    sec
    rts

; ---------------------------------------------------------------------
; str_isupper_iso -- ISO: 'A'..'Z' (65-90)
; ---------------------------------------------------------------------
str_isupper_iso
    cmp #'A'
    bcc _no
    cmp #'Z'+1
    bcs _no
    sec
    rts
_no
    clc
    rts

; ---------------------------------------------------------------------
; str_isletter -- PETSCII: a lower- or upper-case letter
; ---------------------------------------------------------------------
str_isletter
    jsr str_islower
    bcs _yes
    jmp str_isupper
_yes
    rts

; ---------------------------------------------------------------------
; str_isletter_iso -- ISO: a lower- or upper-case letter
; ---------------------------------------------------------------------
str_isletter_iso
    jsr str_islower
    bcs _yes
    jmp str_isupper_iso
_yes
    rts

; ---------------------------------------------------------------------
; str_isspace -- carry set if A is space, CR, LF, TAB, shift-CR or
; shift-space (32, 13, 10, 9, 141, 160)
; ---------------------------------------------------------------------
str_isspace
    cmp #32
    beq _yes
    cmp #13
    beq _yes
    cmp #9
    beq _yes
    cmp #10
    beq _yes
    cmp #141
    beq _yes
    cmp #160
    beq _yes
    clc
    rts
_yes
    sec
    rts

; ---------------------------------------------------------------------
; str_isprint -- PETSCII printable: 32-127 or 160-255
; ---------------------------------------------------------------------
str_isprint
    cmp #160
    bcs _yes
    cmp #32
    bcc _no
    cmp #128
    bcs _no
    sec
    rts
_no
    clc
    rts
_yes
    sec
    rts

; ---------------------------------------------------------------------
; str_isprint_iso -- ISO printable: 32-126 or 160-255
; ---------------------------------------------------------------------
str_isprint_iso
    cmp #160
    bcs _yes
    cmp #32
    bcc _no
    cmp #127
    bcs _no
    sec
    rts
_no
    clc
    rts
_yes
    sec
    rts

; (end zone)
.endif
.if xuse_string_case
; --- inline string/case.asm ---
;ACME
; =====================================================================
; x16lib :: string/case.asm -- upper/lower case conversion
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Whole-string (in place) and single-character case folding, in both
; encodings. PETSCII and ISO place the letters at different codes, so the
; two encodings genuinely swap: PETSCII "lower" is numerically ISO "upper"
; and vice versa -- that is not a bug, it is the charset. The whole-string
; routines return the string length in Y. The compare routines fold both
; sides before comparing and return -1/0/1 like str_compare.
;
;       lda #<name : ldx #>name : jsr str_upper     ; NAME, in place
;       lda mychar : jsr str_lowerchar              ; A = folded char
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; str_lowerchar / str_lowerchar_iso -- fold one character to lower case
; str_upperchar / str_upperchar_iso -- ...to upper case.  in/out: A
; ---------------------------------------------------------------------
str_lowerchar
    and #$7f
    cmp #97
    bcc _done
    cmp #123
    bcs _done
    and #%11011111
_done
    rts

str_lowerchar_iso
    cmp #65
    bcc _done
    cmp #91
    bcs _done
    ora #$20
_done
    rts

str_upperchar
    cmp #65
    bcc _done
    cmp #91
    bcs _done
    ora #%00100000
_done
    rts

str_upperchar_iso
    cmp #97
    bcc _done
    cmp #123
    bcs _done
    and #%11011111
_done
    rts

; ---------------------------------------------------------------------
; str_lower / str_lower_iso -- fold a whole string to lower case in place.
; str_upper / str_upper_iso -- ...to upper case.
;   in: A = low, X = high.  out: Y = length
; ---------------------------------------------------------------------
str_lower
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    beq _done
    jsr str_lowerchar
    sta (X16_T0),y
    iny
    bne _loop
_done
    rts

str_lower_iso
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    beq _done
    jsr str_lowerchar_iso
    sta (X16_T0),y
    iny
    bne _loop
_done
    rts

str_upper
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    beq _done
    jsr str_upperchar
    sta (X16_T0),y
    iny
    bne _loop
_done
    rts

str_upper_iso
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    beq _done
    jsr str_upperchar_iso
    sta (X16_T0),y
    iny
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; str_compare_nocase / str_compare_nocase_iso -- case-insensitive compare.
;   in:  A = string1 low, X = string1 high, X16_P0/P1 = string2
;   out: A = $FF (-1) if string1 < string2, 0 if equal, 1 if greater
; ---------------------------------------------------------------------
str_compare_nocase
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    beq _s1end
    jsr str_lowerchar
    sta X16_T2
    lda (X16_P0),y
    jsr str_lowerchar
    cmp X16_T2
    bne _diff
    iny
    bne _loop
    lda #0
    rts
_diff
    bcc _greater                ; folded s2 < folded s1 -> string1 sorts after
    lda #$FF
    rts
_greater
    lda #1
    rts
_s1end
    lda (X16_P0),y
    beq _same
    lda #$FF
    rts
_same
    lda #0
    rts

str_compare_nocase_iso
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    beq _s1end
    jsr str_lowerchar_iso
    sta X16_T2
    lda (X16_P0),y
    jsr str_lowerchar_iso
    cmp X16_T2
    bne _diff
    iny
    bne _loop
    lda #0
    rts
_diff
    bcc _greater
    lda #$FF
    rts
_greater
    lda #1
    rts
_s1end
    lda (X16_P0),y
    beq _same
    lda #$FF
    rts
_same
    lda #0
    rts

; (end zone)
.endif
.if xuse_string_find
; --- inline string/find.asm ---
;ACME
; =====================================================================
; x16lib :: string/find.asm -- searching within a string
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Locate a character (forward or backward), find the first line ending,
; test membership, or match a wildcard pattern. The string is passed in
; A (low) / X (high); the character to look for is in Y. The find
; routines answer in A -- the index when they hit, 255 when they miss --
; and set the carry to say the same thing, so a caller can read whichever
; suits it.
;
;       lda #<path : ldx #>path
;       ldy #'/'
;       jsr str_rfind                 ; A = index of the last '/', or 255
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; str_find -- first index of a character, scanning left to right.
;   in:  A = low, X = high, Y = character
;   out: A = the index, or 255 when the character is not there
;        (the carry says the same thing: set when found)
; ---------------------------------------------------------------------
str_find
    sta X16_T0
    stx X16_T1
    sty X16_T2
    ldy #0
_loop
    lda (X16_T0),y
    beq _notfound
    cmp X16_T2
    beq _found
    iny
    bne _loop
_notfound
    lda #255
    clc
    rts
_found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_contains -- carry set if the character occurs in the string.
;   in: A = low, X = high, Y = character
; ---------------------------------------------------------------------
str_contains
    jmp str_find

; ---------------------------------------------------------------------
; str_find_eol -- first index of a CR (13) or LF (10).
;   in:  A = low, X = high
;   out: A = the index, or 255 when the character is not there
;        (the carry says the same thing: set when found)
; ---------------------------------------------------------------------
str_find_eol
    sta X16_T0
    stx X16_T1
    ldy #0
_loop
    lda (X16_T0),y
    beq _notfound
    cmp #13
    beq _found
    cmp #10
    beq _found
    iny
    bne _loop
_notfound
    lda #255
    clc
    rts
_found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_rfind -- first index of a character, scanning right to left.
;   in:  A = low, X = high, Y = character
;   out: A = the index, or 255 when the character is not there
;        (the carry says the same thing: set when found)
; ---------------------------------------------------------------------
str_rfind
    sty X16_T2
    sta X16_T0
    stx X16_T1
    ldy #0
_len
    lda (X16_T0),y
    beq _gotlen
    iny
    bne _len
_gotlen
    cpy #0
    beq _notfound               ; empty string
    dey                         ; start at the last character
_loop
    lda (X16_T0),y
    cmp X16_T2
    beq _found
    dey
    cpy #255                    ; walked past index 0
    bne _loop
_notfound
    lda #255
    clc
    rts
_found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_pattern_match -- match a string against a wildcard pattern.
;   in:  A = string low, X = string high, X16_P0/P1 = pattern
;   out: carry set (and A = 1) if it matches, else carry clear (A = 0)
;
; In the pattern, '?' matches any single character and '*' matches any
; run of characters including none. Case-sensitive. Both string and
; pattern are NUL-terminated and at most 255 long. Each '*' costs 4 bytes
; of CPU stack. Algorithm from 6502.org/source/strings/patmatch.htm.
;
; The whole matcher is written with zone-local labels (no _cheap) because
; it self-modifies (the pattern address is patched into two loads) and
; recurses -- an SMC target mid-routine would otherwise split a cheap
; scope under some assemblers.
; ---------------------------------------------------------------------
str_pattern_match
    sta X16_T0                  ; strptr = the string
    stx X16_T1
    lda X16_P0                  ; patch the pattern address into both loads
    sta find_pm_pat1+1
    sta find_pm_pat2+1
    lda X16_P1
    sta find_pm_pat1+2
    sta find_pm_pat2+2
    jsr find_pm_match               ; carry = the match result
    lda #0
    bcc _done                   ; keep the carry; set A = 1 on a match
    lda #1
_done
    rts

find_pm_match
    ldx #0                      ; X indexes the pattern
    ldy #$ff                    ; Y indexes the string (iny brings it to 0)
find_pm_next
find_pm_pat1
    lda $ffff,x                 ; pattern[X]  (address patched above)
    cmp #'*'
    beq find_pm_star
    iny
    cmp #'?'
    bne find_pm_reg
    lda (X16_T0),y              ; '?' matches anything but the terminator
    beq find_pm_fail
find_pm_reg
    cmp (X16_T0),y
    bne find_pm_fail
    inx
    cmp #0                      ; matched the NUL: end of both
    bne find_pm_next
    rts                         ; carry set = match
find_pm_star
    inx
find_pm_pat2
    cmp $ffff,x                 ; a run of '*' is the same as one
    beq find_pm_star
find_pm_stloop
    txa
    pha
    tya
    pha
    jsr find_pm_next                ; try to match the rest here
    pla
    tay
    pla
    tax
    bcs find_pm_done                ; it matched: keep the carry set
    iny
    lda (X16_T0),y              ; grow what '*' swallows, unless at the end
    bne find_pm_stloop
find_pm_fail
    clc
find_pm_done
    rts

; (end zone)
.endif
.if xuse_string_slice
; --- inline string/slice.asm ---
;ACME
; =====================================================================
; x16lib :: string/slice.asm -- copying pieces of a string
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Copy the left end, the right end, or an interior run of a source string
; into a target buffer, NUL-terminated. The source is passed in A (low) /
; X (high) and the target in X16_P0/P1; you must make the target buffer
; big enough and keep the lengths within the source -- there are no
; bounds checks.
;
;       lda #<name : ldx #>name          ; "COMMANDER"
;       lda #<buf : sta X16_P0
;       lda #>buf : sta X16_P1
;       ldy #3 : jsr str_left            ; buf = "COM"
; =====================================================================

; (zone: file scope in 64tass)

; ---------------------------------------------------------------------
; str_left -- copy the first `length` characters.
;   in: A = source low, X = source high, X16_P0/P1 = target, Y = length
; ---------------------------------------------------------------------
str_left
    sta X16_T0
    stx X16_T1
    lda #0
    sta (X16_P0),y              ; terminate the target at [length]
    cpy #0
    beq _done
_loop
    dey
    lda (X16_T0),y
    sta (X16_P0),y
    cpy #0
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; str_right -- copy the last `length` characters.
;   in: A = source low, X = source high, X16_P0/P1 = target, Y = length
; ---------------------------------------------------------------------
str_right
    sty X16_T2                  ; length
    sta X16_T0
    stx X16_T1
    ldy #0                      ; measure the source
_len
    lda (X16_T0),y
    beq _gotlen
    iny
    bne _len
_gotlen
    tya                         ; source += (total - length)
    sec
    sbc X16_T2
    clc
    adc X16_T0
    sta X16_T0
    bcc _nc
    inc X16_T1
_nc
    ldy X16_T2                  ; then it is just a left-copy of `length`
    lda #0
    sta (X16_P0),y
    cpy #0
    beq _done
_loop
    dey
    lda (X16_T0),y
    sta (X16_P0),y
    cpy #0
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; str_slice -- copy `length` characters starting at `start`.
;   in: A = source low, X = source high, X16_P0/P1 = target,
;       X16_P2 = start, Y = length
; ---------------------------------------------------------------------
str_slice
    sta X16_T0
    stx X16_T1
    lda X16_T0                  ; source += start
    clc
    adc X16_P2
    sta X16_T0
    bcc _nc
    inc X16_T1
_nc
    lda #0
    sta (X16_P0),y              ; terminate the target at [length]
    cpy #0
    beq _done
_loop
    dey
    lda (X16_T0),y
    sta (X16_P0),y
    cpy #0
    bne _loop
_done
    rts

; ---------------------------------------------------------------------
; str_rtrim -- drop trailing whitespace, in place.
;   in: A = low, X = high.  out: Y = the new length
; Whitespace is space, TAB, CR, LF, shift-CR (141) and shift-space (160),
; the same set as str_isspace.
; ---------------------------------------------------------------------
str_rtrim
    sta X16_T0
    stx X16_T1
    ldy #0
_len
    lda (X16_T0),y
    beq _back
    iny
    bne _len
_back
    cpy #0
    beq _cut                    ; empty, or every char was whitespace
    dey
    lda (X16_T0),y
    jsr slice_slice_isws
    bcs _back                   ; whitespace: keep stepping back
    iny                         ; keep the last non-whitespace character
_cut
    lda #0
    sta (X16_T0),y
    rts

; ---------------------------------------------------------------------
; str_ltrim -- drop leading whitespace, shifting the rest down, in place.
;   in: A = low, X = high.  out: Y = the new length
; ---------------------------------------------------------------------
str_ltrim
    sta X16_T0
    stx X16_T1
    ldy #0
_skip
    lda (X16_T0),y
    beq _blank                  ; ran off the end: all whitespace
    jsr slice_slice_isws
    bcc _found
    iny
    bne _skip
_found
    cpy #0
    beq _nolead                 ; nothing to strip
    tya                         ; T2/T3 = source = string + first-kept index
    clc
    adc X16_T0
    sta X16_T2
    lda X16_T1
    adc #0
    sta X16_T3
    ldy #0
_shift
    lda (X16_T2),y
    sta (X16_T0),y
    beq _done
    iny
    bne _shift
_done
    rts
_nolead
    ldy #0                      ; unchanged; count its length for the caller
_nll
    lda (X16_T0),y
    beq _nldone
    iny
    bne _nll
_nldone
    rts
_blank
    lda #0                      ; all whitespace -> empty string
    sta (X16_T0)
    ldy #0
    rts

; ---------------------------------------------------------------------
; str_trim -- drop whitespace from both ends, in place.
;   in: A = low, X = high.  out: Y = the new length
; ---------------------------------------------------------------------
str_trim
    sta X16_T6
    stx X16_T7
    jsr str_rtrim
    lda X16_T6
    ldx X16_T7
    jmp str_ltrim

; whitespace test: A = char -> carry set if whitespace. Preserves A, X, Y.
slice_slice_isws
    cmp #32
    beq slice_isws_yes
    cmp #13
    beq slice_isws_yes
    cmp #10
    beq slice_isws_yes
    cmp #9
    beq slice_isws_yes
    cmp #141
    beq slice_isws_yes
    cmp #160
    beq slice_isws_yes
    clc
    rts
slice_isws_yes
    sec
    rts

; (end zone)
.endif
.if xuse_string_sort
; --- inline string/strsort.asm ---
;ACME
; =====================================================================
; x16lib :: string/strsort.asm -- sort an array of string pointers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; str_sort orders an array of NUL-terminated-string POINTERS (uwords)
; ascending by string content, using str_compare. The strings never
; move -- only the pointer array is permuted, exactly the layout of a
; high-level string array.
;
; It carries its own (insertion) sort rather than calling the SORT
; module's sort_ptr, so a program that sorts strings pulls in only the
; STRING module, and a program that sorts numbers pulls in only SORT --
; the two never drag each other in.
; =====================================================================

; (zone: file scope in 64tass)

ss_base  .word 0               ; base of the pointer array
ss_count .word 0               ; element count
ss_i     .word 0
ss_j     .word 0
ss_key   .word 0               ; the pointer being inserted

; ---------------------------------------------------------------------
; str_sort -- ascending sort of a string-pointer array
;   in: X16_P0/P1 = array base, X16_P2/P3 = element count
; ---------------------------------------------------------------------
str_sort
    lda X16_P0
    sta ss_base
    lda X16_P1
    sta ss_base+1
    lda X16_P2
    sta ss_count
    lda X16_P3
    sta ss_count+1

    lda ss_count+1
    bne _start
    lda ss_count
    cmp #2
    bcs _start
_done
    rts
_start
    lda #1
    sta ss_i
    stz ss_i+1

_outer
    lda ss_i+1
    cmp ss_count+1
    bcc _body
    bne _done
    lda ss_i
    cmp ss_count
    bcs _done
_body
    ; key = arr[i]
    lda ss_i
    sta X16_T0
    lda ss_i+1
    sta X16_T1
    jsr strsort_addr4                 ; P4/P5 = &arr[i]
    ldy #0
    lda (X16_P4),y
    sta ss_key
    iny
    lda (X16_P4),y
    sta ss_key+1

    lda ss_i                   ; j = i - 1
    sec
    sbc #1
    sta ss_j
    lda ss_i+1
    sbc #0
    sta ss_j+1

_inner
    lda ss_j                   ; P4/P5 = &arr[j]
    sta X16_T0
    lda ss_j+1
    sta X16_T1
    jsr strsort_addr4
    ; str_compare(s1 = *arr[j], s2 = key)  ->  A = -1/0/1
    lda ss_key
    sta X16_P0
    lda ss_key+1
    sta X16_P1
    ldy #1
    lda (X16_P4),y
    tax                        ; s1 high
    dey
    lda (X16_P4),y             ; s1 low
    jsr str_compare
    cmp #1
    bne _place_jp1             ; arr[j] <= key: stop shifting

    ; arr[j+1] = arr[j]   (P4/P5 = &arr[j] survives str_compare)
    lda ss_j
    clc
    adc #1
    sta X16_T0
    lda ss_j+1
    adc #0
    sta X16_T1
    jsr strsort_addr6                 ; P6/P7 = &arr[j+1]
    ldy #0
    lda (X16_P4),y
    sta (X16_P6),y
    iny
    lda (X16_P4),y
    sta (X16_P6),y

    lda ss_j                   ; j == 0 ? key belongs at arr[0]
    ora ss_j+1
    beq _place_0
    lda ss_j
    sec
    sbc #1
    sta ss_j
    lda ss_j+1
    sbc #0
    sta ss_j+1
    jmp _inner

_place_0
    stz X16_T0
    stz X16_T1
    jsr strsort_addr6                 ; P6/P7 = &arr[0]
    bra _store

_place_jp1
    lda ss_j
    clc
    adc #1
    sta X16_T0
    lda ss_j+1
    adc #0
    sta X16_T1
    jsr strsort_addr6                 ; P6/P7 = &arr[j+1]

_store
    ldy #0
    lda ss_key
    sta (X16_P6),y
    iny
    lda ss_key+1
    sta (X16_P6),y

_next_i
    inc ss_i
    bne _loop
    inc ss_i+1
_loop
    jmp _outer

; X16_T0/T1 = index -> P4/P5 (strsort_addr4) or P6/P7 (strsort_addr6) = base + index*2
strsort_addr4
    lda X16_T0
    asl
    sta X16_T2
    lda X16_T1
    rol
    sta X16_T3
    clc
    lda ss_base
    adc X16_T2
    sta X16_P4
    lda ss_base+1
    adc X16_T3
    sta X16_P5
    rts
strsort_addr6
    lda X16_T0
    asl
    sta X16_T2
    lda X16_T1
    rol
    sta X16_T3
    clc
    lda ss_base
    adc X16_T2
    sta X16_P6
    lda ss_base+1
    adc X16_T3
    sta X16_P7
    rts

; (end zone)
.endif
