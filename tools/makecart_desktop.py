#!/usr/bin/env python3
# =====================================================================
# makecart_desktop.py -- wrap the desktop PRG into an X16 cartridge.
#
# WHY A CART: a launched program owns $0801 and can crash, hang, or
# simply never return. From RAM there is no way back except a power
# cycle. A cartridge gets control at RESET, so the desktop can always
# come back -- which turns "a launchable program must return" from a
# requirement into a preference.
#
# The KERNAL's test is the literal string "CX16" at $C000 of ROM bank
# 32 (see the compare at bank 0 $F6F4 against the copy at $F724);
# execution then continues at $C004.
#
# WHY IT COPIES ITSELF TO RAM: the ROM window shows one bank, so
# setting $01 to reach a KERNAL routine swaps out the very code making
# the call. Genuinely ROM-resident code needs a RAM thunk around every
# KERNAL call, and the desktop is dense with them. So bank 32 carries
# the PRG image and a stub that copies it to $0801 and jumps -- the
# desktop then runs exactly as it does from disk, unchanged.
#
#   python tools/makecart_desktop.py build/desktop.prg build/DESKTOP.CRT
# =====================================================================
import os, subprocess, sys

BANK = 16384
BANK2 = 34                    # the image outgrew one bank; 33 is the NVRAM
LOAD = 0x0801                 # where a PRG expects to be
COPY = 0x0400                 # the copier itself runs from golden RAM


def sys_entry(prg):
    """The SYS address out of a PRG's BASIC stub -- the same parse the
    desktop's own launcher does, because $0801 holds the stub TEXT and
    jumping there executes BASIC tokens as 6502. (It lands in the
    monitor at PC $0004, which is how this was found.)"""
    i = 2 + 4                          # load address, link, line number
    if prg[i] != 0x9E:
        sys.exit('no SYS token: not a machine-language PRG')
    i += 1
    while prg[i] == 0x20:
        i += 1
    v = 0
    while 0x30 <= prg[i] <= 0x39:
        v = v * 10 + (prg[i] - 0x30)
        i += 1
    return v


def loader(src1, pages1, pages2, entry):
    """The part that runs from GOLDEN RAM, because it changes banks.

    The desktop outgrew one 16 KB bank, so the image is split across two
    ROM banks and the second half needs $01 switched mid-copy -- which a
    copier living in the cart cannot survive: the store to $01 swaps out
    the instruction after it. So the whole copy runs from $0400, where
    no bank switch can reach it.
    """
    code = bytearray()

    def e(*b):
        code.extend(b)

    # zero page scratch: $FB/$FC = source, $FD/$FE = destination.
    # The destination pointer is NOT reset between the two halves: the
    # page loop leaves it exactly where the first half ended, which is
    # why the first half is rounded down to a whole number of pages.
    e(0xA9, src1 & 0xFF, 0x85, 0xFB)           # lda #<src1 : sta $FB
    e(0xA9, src1 >> 8, 0x85, 0xFC)             # lda #>src1 : sta $FC
    e(0xA9, LOAD & 0xFF, 0x85, 0xFD)           # lda #<$0801 : sta $FD
    e(0xA9, LOAD >> 8, 0x85, 0xFE)             # lda #>$0801 : sta $FE
    e(0xA2, pages1)                            # ldx #pages1
    jsr1 = len(code)
    e(0x20, 0x00, 0x00)                        # jsr copy   (patched below)

    e(0xA9, BANK2, 0x85, 0x01)                 # lda #34 : sta $01
    e(0xA9, 0x00, 0x85, 0xFB)                  # lda #$00 : sta $FB
    e(0xA9, 0xC0, 0x85, 0xFC)                  # lda #$C0 : sta $FC
    e(0xA2, pages2)                            # ldx #pages2
    jsr2 = len(code)
    e(0x20, 0x00, 0x00)                        # jsr copy   (patched below)

    # A two-byte magic in golden RAM tells the desktop it was cart-booted,
    # because one thing genuinely needs to know: launching a BASIC program
    # requires a live BASIC underneath, which a cart boot does not have.
    e(0xA9, 0xCA, 0x8D, 0xF0, 0x04)            # CARTMAG = $CA $FE
    e(0xA9, 0xFE, 0x8D, 0xF1, 0x04)
    # Hand back to the KERNAL bank and jump straight at the desktop --
    # booting THROUGH BASIC was tried and the card's own AUTOBOOT.X16
    # interferes unpredictably (it ate queue characters on one run and
    # crashed inside BASIC's zero page on another). The direct jump is
    # proven.
    e(0xA9, 0x00, 0x85, 0x01)                  # lda #0 : sta $01
    e(0x4C, entry & 0xFF, entry >> 8)          # jmp entry

    copy = COPY + len(code)                    # the page copier itself
    e(0xA0, 0x00)                              # ldy #0
    inner = len(code)
    e(0xB1, 0xFB)                              # lda ($FB),y
    e(0x91, 0xFD)                              # sta ($FD),y
    e(0xC8)                                    # iny
    e(0xD0, (inner - (len(code) + 2)) & 0xFF)  # bne inner
    e(0xE6, 0xFC)                              # inc $FC
    e(0xE6, 0xFE)                              # inc $FE
    e(0xCA)                                    # dex
    e(0xD0, (copy - COPY - (len(code) + 2)) & 0xFF)   # bne copy
    e(0x60)                                    # rts

    code[jsr1 + 1] = copy & 0xFF
    code[jsr1 + 2] = copy >> 8
    code[jsr2 + 1] = copy & 0xFF
    code[jsr2 + 2] = copy >> 8
    return bytes(code)


def bootstrap(loader_src, loader_len):
    """Bank 32: the KERNAL's signature, then just enough code to put the
    loader in golden RAM and jump to it."""
    code = bytearray(b'CX16')

    def e(*b):
        code.extend(b)

    e(0xA2, 0x00)                                    # ldx #0
    top = len(code)
    e(0xBD, loader_src & 0xFF, loader_src >> 8)      # lda loader_src,x
    e(0x9D, COPY & 0xFF, COPY >> 8)                  # sta $0400,x
    e(0xE8)                                          # inx
    e(0xE0, loader_len)                              # cpx #len
    e(0xD0, (top - (len(code) + 2)) & 0xFF)          # bne top
    e(0x4C, COPY & 0xFF, COPY >> 8)                  # jmp $0400
    return bytes(code)


def main(prg_path, out_path):
    prg = open(prg_path, 'rb').read()
    body = prg[2:]                             # drop the PRG load address
    if prg[0] | (prg[1] << 8) != LOAD:
        sys.exit(f'{prg_path}: loads at ${prg[0] | prg[1] << 8:04X}, not ${LOAD:04X}')

    entry = sys_entry(prg)

    # Sizes first, contents second: every field in both routines is a
    # fixed-width immediate, so assembling them with placeholder values
    # gives the real lengths, and the real values change nothing but the
    # bytes. src1 is where the image starts in bank 32.
    ldr_len = len(loader(0, 0, 0, entry))
    boot_len = len(bootstrap(0, ldr_len))
    src1 = 0xC000 + boot_len + ldr_len

    room1 = BANK - boot_len - ldr_len
    len1 = min(len(body), (room1 // 256) * 256)   # whole pages: the copier
    len2 = len(body) - len1                       # carries the destination over
    if len2 > BANK - 256:
        sys.exit(f'{len(body)} bytes will not fit two 16 KB banks')
    pages1 = len1 // 256
    pages2 = (len2 + 255) // 256

    ldr = loader(src1, pages1, pages2, entry)
    boot = bootstrap(0xC000 + boot_len, ldr_len)
    assert len(ldr) == ldr_len and len(boot) == boot_len, 'stub sizes moved'

    bank32 = boot + ldr + body[:len1]
    bank34 = body[len1:]
    bank32 += bytes(BANK - len(bank32))
    bank34 += bytes(BANK - len(bank34))

    here = os.path.dirname(os.path.abspath(__file__))
    d = os.path.dirname(out_path) or '.'
    tmp = os.path.join(d, 'cart_bank32.bin')
    tmp2 = os.path.join(d, 'cart_bank34.bin')
    open(tmp, 'wb').write(bank32)
    open(tmp2, 'wb').write(bank34)

    # makecart insists on a lower-case .crt and REPORTS SUCCESS anyway if
    # you give it anything else, so normalise the name and check the file
    # afterwards rather than trusting the exit code.
    if not out_path.endswith('.crt'):
        out_path = os.path.splitext(out_path)[0] + '.crt'

    makecart = os.path.normpath(os.path.join(here, '..', 'emulator', 'makecart.exe'))
    cmd = [makecart,
           '-desc', 'X16 Desktop',
           '-author', 'X16_Prog8Library',
           '-rom_file', '32', tmp,
           '-nvram', '33',            # the icon list, kept across power-off
           '-rom_file', str(BANK2), tmp2,
           '-o', out_path]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(out_path):
        sys.exit((r.stdout + r.stderr).strip() or 'makecart wrote nothing')
    os.remove(tmp)
    os.remove(tmp2)
    # Quiet on success -- the cart is rebuilt on every launch.
    # print(f'{out_path}: bank 32 ROM = {boot_len + ldr_len} byte stub + '
    #       f'{len1} bytes, bank {BANK2} ROM = {len2} bytes '
    #       f'(entry ${entry:04X}), bank 33 NVRAM')
    # print(f'  {BANK - len2} bytes spare in the second bank')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit('usage: makecart_desktop.py <desktop.prg> <out.crt>')
    main(sys.argv[1], sys.argv[2])
