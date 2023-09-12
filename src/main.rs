mod display;

use display::*;

use macroquad::prelude::*;
pub use quilt::prelude::*;

pub struct Context {
    memory: [u8; 4096],
}

impl VmData for Context {}

specific_builtins! {
    [type=Context]
    [export=appbuiltins]
    [vm_options=options]

    fn @read_rom(_ctx, path: str) {
        let bytes = std::fs::read(path).expect("Failed to read file");
        bytes.into()
    }


    fn @load(ctx, pos: int, font: list) {
        let pos = pos as usize;
        for (i, value) in font.iter().enumerate() {
            match value {
                Value::Int(v) => ctx.memory[pos + i] = *v as u8,
                _ =>  Err(error("Expected int"))?
            }
        }
        Value::None
    }

    fn @memget(ctx, addr: int) {
        ctx.memory[addr as usize].into()
    }

    fn @memset(ctx, addr: int, val: u8) {
        ctx.memory[addr as usize] = val;
        Value::None
    }

    fn @getkey(_ctx,) {
        Value::None
    }

    fn @keydown(_ctx, _key: any) {
        false.into()
    }

    fn @display_set(_ctx, x: u8, y: u8, b: bool) {
        Display::set(x, y, b);
        Value::None
    }

    fn @display_get(_ctx, x: u8, y: u8) {
        Display::get(x, y).into()
    }

    fn @display_clear(_ctx,) {
        Display::clear();
        Value::None
    }
}

fn window_conf() -> Conf {
    Conf {
        window_title: "Chip8".to_owned(),
        window_width: 800,
        window_height: 400,
        ..Default::default()
    }
}

#[macroquad::main(window_conf)]
async fn main() {
    std::thread::spawn(run_quilt);

    let mut display = Display::new();

    loop {
        clear_background(BLACK);
        display.draw();
        next_frame().await
    }
}

fn run_quilt() {
    let src = std::fs::read_to_string("chip8/main.ql").expect("Failed to read file");

    let mut sources = SourceCache::new();

    let ast = match sources.parse_with_includes(
        "main.ql",
        &src,
        &mut DefaultIncludeResolver::default(),
    ) {
        Ok(ast) => ast,
        Err(e) => {
            e.print(&sources).expect("Failed to print error");
            return;
        }
    };

    let script = match Compiler::compile(&ast) {
        Ok(f) => f,
        Err(e) => {
            e.print(&sources).expect("Failed to print error");
            return;
        }
    };

    let state = Context { memory: [0; 4096] };

    let opts = VmOptions::default();

    let mut vm = VM::new(state, script, opts);

    vm.add_builtins(qstd::stdio);
    vm.add_builtins(appbuiltins);

    vm.run()
        .map_err(|e| e.print(&sources))
        .expect("Failed to run VM");
}
