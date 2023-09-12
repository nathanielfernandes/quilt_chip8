fn overflowing_add(a, b) {
    let sum = a + b
    let carry = (if sum > 255 { 1 } else { 0 })
    (sum & 255, carry)
}

fn overflowing_sub(a, b) {
    let diff = a - b
    let borrow = (if a > b { 1 } else { 0 })
    (diff & 255, borrow)
}

fn wrapping_add(a, b) {
    (a + b) & 255
}
