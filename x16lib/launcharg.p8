; =====================================================================
; launcharg.p8 -- the file a launcher wants a program to open.
;
; The X16 has no argv. A program launched from a desktop or a shell
; knows only its own name, so every program that wanted to open a
; particular file had to ask for it again -- which is why a file browser
; kept wanting to be copied into each one.
;
; This is the cheaper answer: the launcher leaves the path in golden
; RAM, and the program picks it up on the way in.
;
;   launcher                       program
;   --------                       -------
;   launcharg.set(&path, n)        uword p = launcharg.get()
;   ...load and run the program    if p != 0
;                                      open_that(p)
;                                  else
;                                      ...ask, or use a default
;
; WHY GOLDEN RAM: $0400-$07FF is the block the KERNAL and BASIC leave
; alone and a PRG at $0801 does not cover, so it survives both the LOAD
; and the launch. The desktop's own trampoline lives at $0400; this
; block starts at $0500, clear of it.
;
; WHY A MAGIC: golden RAM boots as garbage and holds whatever the last
; program left there. Without a magic, a program run twice would see a
; stale path the second time, or nonsense on a cold boot. A launcher
; that has no file to pass MUST call clear() -- setting one is not the
; only thing that has to be deliberate.
;
; The path is whatever the launcher chose to write: absolute, relative,
; with or without a drive. A desktop that changed directory before
; launching will normally pass a bare name.
; =====================================================================
launcharg {
    const uword MAGIC = $0500     ; two bytes, $A6 $16 when a path is set
    const uword LEN   = $0502     ; how long it is, 1-127
    const uword TEXT  = $0503     ; the path itself, NUL-terminated
    const ubyte MAX   = 127

    ; -> a pointer to the NUL-terminated path, or 0 when none was passed
    sub get() -> uword {
        if @(MAGIC) != $A6 or @(MAGIC + 1) != $16
            return 0
        if @(LEN) == 0 or @(LEN) > MAX
            return 0
        return TEXT
    }

    ; how long it is, without walking it again; 0 when there is none
    sub length() -> ubyte {
        if get() == 0
            return 0
        return @(LEN)
    }

    sub set(uword path, ubyte n) {
        if n == 0 or n > MAX {
            clear()
            return
        }
        ubyte i = 0
        while i < n {
            @(TEXT + i) = @(path + i)
            i++
        }
        @(TEXT + i) = 0
        @(LEN) = n
        @(MAGIC) = $A6
        @(MAGIC + 1) = $16
    }

    ; A launcher calls this before every launch that passes nothing, and
    ; a program that has consumed its argument calls it so a child it
    ; launches in turn does not inherit it by accident.
    sub clear() {
        @(MAGIC) = 0
        @(MAGIC + 1) = 0
        @(LEN) = 0
    }
}
