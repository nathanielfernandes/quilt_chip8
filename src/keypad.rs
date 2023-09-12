use std::sync::RwLock;

use macroquad::prelude::*;
use once_cell::sync::Lazy;

const KEYPAD_MAP: [KeyCode; 16] = [
    KeyCode::X,
    KeyCode::Key1,
    KeyCode::Key2,
    KeyCode::Key3,
    KeyCode::Q,
    KeyCode::W,
    KeyCode::E,
    KeyCode::A,
    KeyCode::S,
    KeyCode::D,
    KeyCode::Z,
    KeyCode::C,
    KeyCode::Key4,
    KeyCode::R,
    KeyCode::F,
    KeyCode::V,
];

pub static KEYPAD: Lazy<RwLock<[bool; 16]>> = Lazy::new(|| RwLock::new([false; 16]));

pub fn get_key() -> Option<u8> {
    for (i, key) in KEYPAD
        .read()
        .expect("failed to lock keyapad")
        .iter()
        .enumerate()
    {
        if *key {
            return Some(i as u8);
        }
    }

    None
}

pub fn kp_is_key_down(key: u8) -> bool {
    KEYPAD.read().expect("failed to lock keypad")[key as usize]
}

pub fn update_keypad() {
    let mut keypad = KEYPAD.write().expect("failed to lock keypad");
    for (i, key) in KEYPAD_MAP.iter().enumerate() {
        keypad[i] = is_key_down(*key);
    }
}
