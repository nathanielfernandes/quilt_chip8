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
        Value::None
    }

    fn @draw(_ctx,) {
        let fps = get_fps();
        draw_text(&format!("fps: {:?}", fps), 2.0, 20.0, 30.0, GREEN);

        futures::executor::block_on(next_frame());
        Value::None
    }

    fn @display_clear(_ctx,) {
        Value::None
    }
}

fn window_conf() -> Conf {
    Conf {
        window_title: "Chip8".to_owned(),
        window_width: 1600,
        window_height: 800,
        ..Default::default()
    }
}

#[macroquad::main(window_conf)]
async fn main() {
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
