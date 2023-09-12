use macroquad::prelude::*;

use once_cell::sync::Lazy;
use std::sync::RwLock;

pub static GFXBUFFER: Lazy<RwLock<[bool; 64 * 32]>> = Lazy::new(|| RwLock::new([false; 64 * 32]));
// pub const CLEAR: [bool; 64 * 32] = [false; 64 * 32];

pub struct Display {
    width_ratio: f32,
    height_ratio: f32,
}

impl Display {
    pub const WIDTH: u8 = 64;
    pub const HEIGHT: u8 = 32;

    pub const WIDTH_F32: f32 = Self::WIDTH as f32;
    pub const HEIGHT_F32: f32 = Self::HEIGHT as f32;

    pub fn new() -> Self {
        let width = screen_width();
        let height = screen_height();

        Self {
            width_ratio: width / Self::WIDTH_F32,
            height_ratio: height / Self::HEIGHT_F32,
        }
    }

    pub fn update_screen_size(&mut self) {
        let width = screen_width();
        let height = screen_height();

        let new_width_ratio = width / Self::WIDTH_F32;
        let new_height_ratio = height / Self::HEIGHT_F32;

        if new_width_ratio != self.width_ratio || new_height_ratio != self.height_ratio {
            self.width_ratio = new_width_ratio;
            self.height_ratio = new_height_ratio;
        }
    }

    #[inline(always)]
    pub fn i(x: u8, y: u8) -> usize {
        let mut x = x;
        if x >= Self::WIDTH {
            x -= Self::WIDTH;
        }

        let mut y = y;
        if y >= Self::HEIGHT {
            y -= Self::HEIGHT;
        }

        (x as usize) + (Self::WIDTH as usize) * (y as usize)
    }

    #[inline(always)]
    pub fn set(x: u8, y: u8, b: bool) {
        GFXBUFFER.write().expect("Failed to write GFXBUFFER")[Self::i(x, y)] = b;
    }

    #[inline(always)]
    pub fn get(x: u8, y: u8) -> bool {
        GFXBUFFER.read().expect("Failed to read GFXBUFFER")[Self::i(x, y)]
    }

    #[inline(always)]
    pub fn clear() {
        let mut buffer = GFXBUFFER.write().expect("Failed to write GFXBUFFER");
        for i in 0..buffer.len() {
            buffer[i] = false;
        }
    }

    pub fn draw(&mut self) {
        self.update_screen_size();

        let buffer = GFXBUFFER.read().expect("Failed to read GFXBUFFER");
        for y in 0..Self::HEIGHT {
            for x in 0..Self::WIDTH {
                if buffer[Self::i(x, y)] {
                    draw_rectangle(
                        self.width_ratio * x as f32,
                        self.height_ratio * y as f32,
                        self.width_ratio as f32,
                        self.height_ratio as f32,
                        WHITE,
                    );
                }
            }
        }
    }
}
