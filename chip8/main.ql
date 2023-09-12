include "chip8/helpers.ql"
include "chip8/chip8.ql"
include "chip8/opcodes.ql"
include "chip8/font.ql"

let rom = @read_rom("roms/brix.ch8")

@load(0x00, FONT)
@load(0x200, rom)

let fps = @get_fps()
let time = @now()
while true {
    fps = @get_fps()

    let dt = @now() - time
    if dt > (1.0 / fps) {
        time = @now()
        
        sync_cycle(fps)
    }
}


