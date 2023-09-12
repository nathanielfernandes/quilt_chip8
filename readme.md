# chip8 emulator

This is a chip8 emulator written in [quilt](https://github.com/nathanielfernandes/quilt).

This was a fun weekend project to see how capable quilt is. I was able to get this working in a few hours.

![brix](https://cdn.discordapp.com/attachments/792686378366009354/1151193260941922375/image.png)

Quilt cannot natively draw to a screen or recieve inputs so I extended it's builtins by wrapping over macroquad.

The entire emulator is simulated within quilt, the only thing that is not is the screen and input.
