include "chip8/helpers.ql"
include "chip8/chip8.ql"
include "chip8/opcodes.ql"
include "chip8/font.ql"

let rom = @read_rom("roms/test_opcode.ch8")

@load(0x00, FONT)
@load(0x200, rom)

while true {
    cycle()
}


