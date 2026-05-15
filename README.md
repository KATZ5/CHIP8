# CHIP-8 Emulator & Toolchain

A fully-featured CHIP-8 emulator, interactive debugger, and custom assembler written entirely in [Odin](https://odin-lang.org/).

Designed as an educational tool for exploring computer architecture, this project visualizes the fetch-decode-execute cycle in real-time. It features a complete immediate-mode GUI dashboard, seamless drag-and-drop workflow, and a built-in assembler that compiles raw text into machine code on the fly.

## ✨ Features

- **Cycle-Accurate Emulation:** Accurately implements the standard CHIP-8 instruction set, timers, and display logic.
- **Interactive Developer Dashboard:** Built with `microui`, featuring real-time views of the CPU Registers, Stack, Memory layout, and a live Disassembler.
- **Integrated Assembler:** Write custom `.asm` files and drag them directly into the emulator to instantly compile and run.
- **Drag-and-Drop Workflow:** Drop `.ch8` binary ROMs or `.asm` source code files directly onto the application window.
- **Standalone Deployment:** Statically linked on Windows (no DLLs required) for extremely easy distribution.

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
