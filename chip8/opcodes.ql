fn NEXT()  { (0, none) }
fn JUMP(j) { (1, j) }
fn SKIP(s) { (2, s) }
fn UNKNOWN(x) { 
    @print("UNKNOWN OPCODE", @hex(x))
    NEXT()
}

fn exec_opcode(opcode) {
    let i   = ((opcode & 0xF000) >> 12)
    let x   = ((opcode & 0x0F00) >> 8)
    let y   = ((opcode & 0x00F0) >> 4)

    let n   = (opcode & 0x000F)
    let nn  = (opcode & 0x00FF)
    let nnn = (opcode & 0x0FFF)

    // @print("i:", i, "x:", x, "y:", y, "n:", n, "nn:", nn, "nnn:", nnn)

    let task, val = switch [i, x, y, n] {
        case [0x00, 0x00, 0x00, 0x00] { JUMP(pc) }

        case [0x00, 0x00, 0x0E, 0x00] { _00E0() } // clear screen
        case [0x00, 0x00, 0x0E, 0x0E] { _00EE() } // return from subroutine

        default {
            switch i {
                case 0x01 { _1NNN(nnn) } // jump to location nnn
                case 0x02 { _2NNN(nnn) } // call subroutine at nnn
                case 0x03 { _3XNN(x, nn) } // skip next instruction if Vx == nn
                case 0x04 { _4XNN(x, nn) } // skip next instruction if Vx != nn
                case 0x05 { // skip next instruction i
                    if n == 0x00 { 
                        _5XY0(x, y) 
                    }  else { 
                        UNKNOWN(opcode) 
                    }
                }
                case 0x06 { _6XNN(x, nn) } // set vx to nn
                case 0x07 { _7XNN(x, nn) } // add nn to vx

                case 0x08 {
                    switch n {
                        case 0x00 { _8XY0(x, y) } // set vx to vy
                        case 0x01 { _8XY1(x, y) } // set vx to vx | vy
                        case 0x02 { _8XY2(x, y) } // set vx to vx & vy
                        case 0x03 { _8XY3(x, y) } // set vx to vx ^ vy
                        case 0x04 { _8XY4(x, y) } // set vx to vx + vy
                        case 0x05 { _8XY5(x, y) } // set vx to vx - vy
                        case 0x06 { _8XY6(x, y) } // shift vx right by 1
                        case 0x07 { _8XY7(x, y) } // set vx to vy - vx
                        case 0x0E { _8XYE(x, y) } // shift vx left by 1

                        default { UNKNOWN(opcode) }
                    }
                }

                case 0x09 { // skip next instruction if Vx != Vy
                    if n == 0x00 { 
                        _9XY0(x, y) 
                    }  else { 
                        UNKNOWN(opcode) 
                    }
                }

                case 0x0A { _ANNN(nnn) } // set i to nnn
                case 0x0B { _BNNN(nnn) } // jump to v0 + nnn
                case 0x0C { _CXNN(x, nn) } // set vx to random byte & nn
                case 0x0D { _DXYN(x, y, n) } // display draw

                case 0x0E {
                    switch nn {
                        case 0x9E { _EX9E(x) } // skip if key vx down
                        case 0xA1 { _EXA1(x) } // skip if key vx not down

                        default { UNKNOWN(opcode) }
                    }
                }

                case 0x0F {
                    switch nn {
                        case 0x07 { _FX07(x) } // set vx to delay timer
                        case 0x0A { _FX0A(x) } // get key
                        case 0x15 { _FX15(x) } // set delay timer to vx
                        case 0x18 { _FX18(x) } // set sound timer to vx
                        case 0x1E { _FX1E(x) } // add vx to i
                        case 0x29 { _FX29(x) } // set i to be the font in vx
                        case 0x33 { _FX33(x) } // get each number place and store in memory
                        case 0x55 { _FX55(x) } // store registers to memory
                        case 0x65 { _FX65(x) } // load registers from memory

                        default { UNKNOWN(opcode) }
                    }
                }
                
                default { UNKNOWN(opcode) }
            }
        }
    }

    // @print("task:", task, "val:", val)

    switch task {
        // next
        case 0 { pc += 0x02 }
        // jump
        case 1 { pc = val }
        // skip
        case 2 {
            if val {
                pc += 0x04
            } else {
                pc += 0x02
            }
        }
    }
}


// clear screen
fn _00E0() {
    @display_clear()
    NEXT()
}

// jump to location nnn
fn _1NNN(nnn) {
    JUMP(nnn)
}

// set vx to nn
fn _6XNN(x, nn) {
    v = @set(v, x, nn)
    NEXT()
}

// add nn to vx
fn _7XNN(x, nn) {
    let sum = wrapping_add(v[x], nn)
    v = @set(v, x, sum)
    NEXT()
}

// set i to nnn
fn _ANNN(nnn) {
    i = nnn
    NEXT()
}

// display draw
fn _DXYN(x, y, n) {
    let x = v[x] % 64
    let y = v[y] % 32

    @set(v, 0x0F, 0x00)

    for b in 0 : n {
        let sprite_data = @memget(i + b)
        let x = x
        for i in 0 : 8 {
            i = 7 - i

            if ((sprite_data >> i) & 0x01) == 0x01 {
                let prev = @display_get(x, y)
                @display_set(x, y, !prev)

                if prev {
                    v = @set(v, 0x0F, 0x01)
                }
            }

            x += 1
        }
        y += 1
    }

    NEXT()
}


// return from subroutine
fn _00EE() {
    JUMP(stack_pop())
}

// call subroutine at nnn
fn _2NNN(nnn) {
    stack_push(pc + 0x02)
    JUMP(nnn)
}

// skip next instruction if Vx == nn
fn _3XNN(x, nn) {
    SKIP(v[x] == nn)
}

// skip next instruction if Vx != nn
fn _4XNN(x, nn) {
    SKIP(v[x] != nn)
}

// skip next instruction if Vx == Vy
fn _5XY0(x, y) {
    SKIP(v[x] == v[y])
}

// skip if Vx != Vy
fn _9XY0(x, y) {
    SKIP(v[x] != v[y])
}

// set vx to vy
fn _8XY0(x, y) {
    v = @set(v, x, v[y])
    NEXT()
}

// set vx to vx | vy
fn _8XY1(x, y) {
    v = @set(v, x, v[x] | v[y])
    NEXT()
}

// set vx to vx & vy
fn _8XY2(x, y) {
    v = @set(v, x, v[x] & v[y])
    NEXT()
}

// set vx to vx ^ vy
fn _8XY3(x, y) {
    v = @set(v, x, v[x] ^ v[y])
    NEXT()
}

// set vx to vx + vy
fn _8XY4(x, y) {
    let source = v[y]
    let target = v[x]

    let sum, carry = overflowing_add(source, target)
    v = @set(v, x, sum)
    v = @set(v, 0x0F, carry)

    NEXT()
}

// set vx to vx - vy
fn _8XY5(x, y) {
    let source = v[y]
    let target = v[x]

    let diff, borrow = overflowing_sub(target, source)
    v = @set(v, x, diff)
    v = @set(v, 0x0F, borrow)

    NEXT()
}

// set vx to vy - vx
fn _8XY7(x, y) {
    let diff, borrow = overflowing_sub(v[y], v[x])
    v = @set(v, x, diff)
    v = @set(v, 0x0F, borrow)

    NEXT()
}

// shift vx right by 1
fn _8XY6(x, y) {
    v = @set(v, 0x0F, v[x] & 0x01)
    v = @set(v, x, v[x] >> 1)
    NEXT()
}

// shift vx left by 1
fn _8XYE(x, y) {
    let msb = (v[x] >> 7) & 0x01
    v = @set(v, 0x0F, msb)
    v = @set(v, x, (v[x] << 1) & 255)
    NEXT()
}

// jump to v0 + nnn
fn _BNNN(nnn) {
    JUMP(v[0x00] + nnn)
}

// set vx to random byte & nn
fn _CXNN(x, nn) {
    let r = @randint(0, 255) & nn
    v = @set(v, x, r)
    NEXT()
}

// skip if key vx down
fn _EX9E(x) {
    SKIP(@keydown(v[x]))
}

// skip if key vx not down
fn _EXA1(x) {
    SKIP(!@keydown(v[x]))
}

// set vx to delay timer
fn _FX07(x) {
    v = @set(v, x, delay_timer)
    NEXT()
}

// set delay timer to vx
fn _FX15(x) {
    delay_timer = v[x]
    NEXT()
}

// set sound timer to vx
fn _FX18(x) {
    sound_timer = v[x]
    NEXT()
}

// add vx to i
fn _FX1E(x) {
    i += v[x]
    NEXT()
}

// get key
fn _FX0A(x) {
    keypad_is_waiting = true
    keypad_destination = x
    NEXT()
}

// set i to be the font in vx
fn _FX29(x) {
    i = (v[x] * 5) & 0xFFFF 
    NEXT()
}

// get each number place and store in memory
fn _FX33(x) {
    let vx = v[x]

    let hundreds = vx / 100
    let tens = (vx / 10) % 10
    let ones = vx % 10

    @memset(i, hundreds)
    @memset(i + 1, tens)
    @memset(i + 2, ones)
    
    NEXT()
}

// store registers to memory
fn _FX55(x) {
    for j in 0 : (x + 1) {
        @memset(i + j, v[j])
    }
    NEXT()
}

// load registers from memory
fn _FX65(x) {
    for j in 0 : (x + 1) {
        v = @set(v, j, @memget(i + j))
    }
    NEXT()
}