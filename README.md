# CHIP-8 Emulator & Toolchain

A fully-featured CHIP-8 emulator, interactive debugger, and custom assembler written entirely in [Odin](https://odin-lang.org/).

Designed as an educational tool for exploring computer architecture, this project visualizes the fetch-decode-execute cycle in real-time. It features a complete immediate-mode GUI dashboard, seamless drag-and-drop workflow, and a built-in assembler that compiles raw text into machine code on the fly.

## ✨ Features

- **Interactive Developer Dashboard:** Built with `microui`, featuring real-time views of the CPU Registers, Stack, Memory layout, and a live Disassembler.
- **Integrated Assembler:** Write custom `.asm` files and drag them directly into the emulator to instantly compile and run.
- **Drag-and-Drop Workflow:** Drop `.ch8` binary ROMs or `.asm` source code files directly onto the application window.

---

## 🛠️ Building from Source

To compile this project, you will need the [Odin Compiler](https://odin-lang.org/docs/install/) installed on your system.

### Windows

Because Odin statically links the Raylib and MicroUI C-libraries by default, building on Windows requires zero extra dependencies. It generates a single, standalone `.exe`.

```bash
# Clone the repository
git clone git@github.com:KATZ5/CHIP8.git
cd CHIP8

# Build the highly optimized release version
odin build . -out:chip8_emulator.exe -o:speed
```

### Linux

To compile on Linux, you need to provide the system development headers for audio and window management (X11/Wayland/ALSA) so Raylib can link successfully.

#### Arch Linux

```bash
sudo pacman -S alsa-lib libx11 libxrandr libxi mesa glu libxcursor libxinerama

odin build . -out:chip8_linux -o:speed
```

## 🎮 Usage

You can launch the emulator with or without a ROM.

```bash
# launch with an rom already loaded
./chip8_emulator roms/Tetris.ch8

```

### Drag and Drop:

Simply launch the executable and drag any .ch8 binary file or .asm text file from your file manager directly onto the emulator window.

Keyboard Controls:

    The CHIP-8 uses a 16-key hex pad (0-F). This is mapped to your standard keyboard (1-4, Q-R, A-F, Z-V).

    Press P to toggle the emulator Pause state.

    While paused, press SPACE to step the CPU forward exactly one instruction at a time.

    Or simply use the debugger view

---

---

## 💻 The Assembler

This emulator includes a custom built-in assembler. You can write CHIP-8 assembly language in your preferred text editor (like VS Code or Vim), save it as an `.asm` file, and drag it into the emulator.

The assembler perfectly adheres to the syntax outlined in **[Cowgod's Chip-8 Technical Reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)** (specifically Section 3.1).

### Syntax Rules

- **Comments:** Any text following a `;` is ignored.
- **Hex vs Decimal:** Standard numbers are treated as decimal (e.g., `10`). Numbers prefixed with `0x` are treated as hex (e.g., `0xA`).
- **Commas:** Commas are completely optional and ignored by the lexer (`LD V0, 5` is identical to `LD V0 5`).
- **Labels:** Words ending in a colon (`loop:`) create memory address labels that can be referenced by `JP` or `CALL` instructions.

### Example Program (`test.asm`)

```asm
; Draws the number "8" to the center of the screen
CLS             ; Clear the display

LD V0, 30       ; Set X coordinate to 30
LD V1, 12       ; Set Y coordinate to 12

LD V2, 8        ; The hex character we want to draw
LD F, V2        ; Point the 'I' register to the built-in font for the character

DRW V0, V1, 5   ; Draw a 5-byte tall sprite at X, Y

infinite_loop:
JP infinite_loop
```

## 📜 Credits

[Odin ](https://odin-lang.org): The systems programming language driving the emulator logic.

[Raylib](https://www.raylib.com/): Hardware-accelerated graphics and audio rendering.

[MicroUI](https://github.com/rxi/microui.git): The lightweight immediate-mode GUI library used for the developer dashboard.

[Cowgod's Chip-8 Technical Reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM): The  spec used to build the opcodes and assembler translation.

