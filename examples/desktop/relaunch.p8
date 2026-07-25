; =====================================================================
; relaunch.p8 -- the hard half of a desktop launcher, on its own.
;
; A PRG loads at $0801 and overwrites whatever was there, so a launcher
; cannot call a program and expect to still exist afterwards. It cannot
; even load one: the moment LOAD runs, the caller's own next instruction
; has been overwritten by the incoming program.
;
; What survives is golden RAM, $0400-$07FF. The KERNAL does not use it,
; BASIC does not use it, and Prog8 only uses it if asked. So a fifty-four
; byte trampoline goes there and does the whole job from outside $0801:
;
;       SETNAM/SETLFS/LOAD   child
;       JSR  <child entry>       ; the child owns $0801.. now
;       ...the child returns...
;       SETNAM/SETLFS/LOAD   this program, back off disk
;       JMP  (<our entry>)
;
; The trampoline refers only to fixed golden-RAM addresses and the KERNAL
; jump table, never to itself, so it can be copied to $0400 and run there.
;
; Entry addresses are read out of each PRG's BASIC stub rather than
; assumed -- Prog8 emits "SYS 2071" today, but that number moves with the
; stub text. cx.fs_prg_entry does that reading, off the disk and without
; loading anything, since loading a program to find out where it starts
; would defeat the whole exercise.
;
; This program proves the round trip and nothing else: it launches
; CHILD.PRG, and CHILD.PRG comes back here. The desktop builds on it.
;
;   .\build.ps1 -Run
; =====================================================================
%import x16lib
%import x16lib_const
%zeropage dontuse         ; the library owns ZP $22-$31; keep Prog8 out of it

main {
    ; ---- golden RAM: the one place a launched program will not tread --
    const uword STUB     = $0400      ; the trampoline
    const uword CHILDVEC = $0440      ; child entry (the JSR is patched too)
    const uword SELFVEC  = $0442      ; where the trampoline returns to
    const uword FLAG     = $0444      ; "you have been here before"
    const uword CNAMLEN  = $0480      ; child filename
    const uword CNAME    = $0481
    const uword SNAMLEN  = $04C0      ; our own filename
    const uword SNAME    = $04C1
    const ubyte MAGIC    = $A5
    const ubyte JSRAT    = 25         ; offset of the JSR operand in stub

    ubyte[] stub = [
        $AD, $80, $04,                ; lda CNAMLEN
        $A2, $81,                     ; ldx #<CNAME
        $A0, $04,                     ; ldy #>CNAME
        $20, $BD, $FF,                ; jsr SETNAM
        $A9, $01,                     ; lda #1        logical file
        $A2, $08,                     ; ldx #8        device
        $A0, $01,                     ; ldy #1        SA 1: use the header
        $20, $BA, $FF,                ; jsr SETLFS
        $A9, $00,                     ; lda #0        load, not verify
        $20, $D5, $FF,                ; jsr LOAD
        $20, $00, $00,                ; jsr <child entry>   (patched)
        $AD, $C0, $04,                ; lda SNAMLEN
        $A2, $C1,                     ; ldx #<SNAME
        $A0, $04,                     ; ldy #>SNAME
        $20, $BD, $FF,                ; jsr SETNAM
        $A9, $01,                     ; lda #1
        $A2, $08,                     ; ldx #8
        $A0, $01,                     ; ldy #1
        $20, $BA, $FF,                ; jsr SETLFS
        $A9, $00,                     ; lda #0
        $20, $D5, $FF,                ; jsr LOAD
        $6C, $42, $04                 ; jmp (SELFVEC)
    ]

    str self  = "relaunch.prg"
    str child = "child.prg"
    str s_first   = "desktop: launching child.prg"
    str s_back    = "desktop: back from the child"
    str s_nofile  = "desktop: cannot read child.prg"
    str s_done    = "round trip complete. press a key."

    sub start() {
        cx.load_banks()
        void cx.screen_set_mode(0)
        cx.screen_charset(3)
        cx.screen_color(1, 6)
        cx.screen_cls()

        if @(FLAG) == MAGIC {
            @(FLAG) = 0
            cx.screen_puts(&s_back)
            nl()
            cx.screen_puts(&s_done)
            nl()
            void cx.key_wait()
            cx.screen_reset()
            return
        }

        cx.screen_puts(&s_first)
        nl()
        if not launch(&child, len(child)) {
            cx.screen_puts(&s_nofile)
            nl()
            void cx.key_wait()
            cx.screen_reset()
        }
    }

    sub nl() {
        cx.screen_chrout($0d)
    }

    sub putname(uword lenaddr, uword straddr, uword s, ubyte n) {
        @(lenaddr) = n
        ubyte i = 0
        while i < n {
            @(straddr + i) = @(s + i)
            i++
        }
    }

    ; -> false if the child could not be read. Otherwise never returns:
    ; the trampoline takes over and this program is reloaded from disk.
    sub launch(uword name, ubyte namelen) -> bool {
        uword centry = cx.fs_prg_entry(name, namelen, 8)
        if centry == 0
            return false

        putname(CNAMLEN, CNAME, name, namelen)
        putname(SNAMLEN, SNAME, &self, len(self))
        pokew(CHILDVEC, centry)
        pokew(SELFVEC, cx.fs_prg_entry(&self, len(self), 8))
        @(FLAG) = MAGIC

        ubyte i = 0
        while i < len(stub) {
            @(STUB + i) = stub[i]
            i++
        }
        pokew(STUB + JSRAT, centry)
        goto STUB
        return true
    }
}
