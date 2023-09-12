// Chip8
let hz = 500 // assumed frequency of cpu
let tick = 0 // current tick

let i = 0 // index register
let pc = 0x200 // program counter
let delay_timer = 0 // delay timer
let sound_timer = 0 // sound timer

let v = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] // registers

let keypad_is_waiting = false // is keypad waiting for input
let keypad_destination = 0 // where to store keypad input


let stack = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
let pointer = 0

fn stack_pop() {
    pointer -= 1
    stack[pointer]
}

fn stack_push(value) {
    stack = @set(stack, pointer, value)
    pointer += 1
}

fn fetch(pc) {
    (@memget(pc) << 8) | @memget(pc + 1)
}

fn tick_timers() {
    tick += 1
    if (tick % (hz / 60)) == 0 {
        if delay_timer > 0 { delay_timer -= 1 }
        if sound_timer > 0 { sound_timer -= 1 }
    }

    if tick >= hz { 
        tick = 0 
    }
}

fn cycle() {
    tick_timers()

    if keypad_is_waiting {
        let key = @getkey()
        if key != none {
            @set(v, keypad_destination, key)
        }
    } else {
        let opcode = fetch(pc)
        // @print("executing opcode: ", @hex(opcode))
        exec_opcode(opcode)
    }
}

fn sync_cycle(fps) {
    for _ in 0 : ((hz / @max(fps, 1))) {
        cycle()
    }
}