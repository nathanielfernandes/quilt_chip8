fn overflowing_add(a, b) {
    let sum = a + b
    let carry = if sum < a { 1 } else { 0 }
    sum = sum & 0xFF
    (sum, carry)
}

fn overflowing_sub(a, b) {
    let diff = a - b
    let carry = if diff > a { 1 } else { 0 }
    diff = diff & 0xFF
    (diff, carry)
}


fn wrapping_add(a, b) {
    (a + b) & 0xFF
}