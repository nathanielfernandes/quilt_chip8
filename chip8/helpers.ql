fn overflowing_add(a, b) {
    let sum = a + b
    let carry = if sum > 0xFF { 1 } else { 0 }
    sum = sum & 0xFF
    (sum, carry)
}

fn overflowing_sub(a, b) {
    let diff = a - b
    let borrow = if b > a { 0 } else { 1 }
    diff = diff & 0xFF
    (diff, borrow)
}

fn wrapping_add(a, b) {
    (a + b) & 0xFF
}