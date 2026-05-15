package chip8

import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:strings"

import rl "vendor:raylib"

Chip8 :: struct {
	memory:      [4096]u8,
	display:     [64 * 32]u8,
	stack:       [dynamic]u16,
	sp:          u16,
	v:           [16]u8,
	I:           u16,
	pc:          u16,
	opcode:      u16,
	delay_timer: u8,
	sound_timer: u8,
	keypad:      [16]u8,
	drawflag:    bool,
}

initialize :: proc() {
	chip8.pc = 0x200
	chip8.opcode = 0
	chip8.I = 0
	chip8.sp = 0
	chip8.v = 0
	chip8.display = 0
	chip8.delay_timer = 0
	chip8.sound_timer = 0


	clear_dynamic_array(&chip8.stack)

	for i in 0 ..< len(fontset) {
		chip8.memory[i] = fontset[i]
	}


	chip8.drawflag = true

}

loadProgram :: proc(path: string) {
	//fmt.printfln(path)

	if strings.has_suffix(path, ".ch8") {
		data, ok := os.read_entire_file(path, context.allocator)
		if ok != os.ERROR_NONE {
			// could not read file
			fmt.println("FAILED TO OPEN ROM FILE")
			return
		}
		defer delete(data, context.allocator)
		initialize()
		mem.zero(&chip8.memory[0x200], 4096 - 0x200)
		copy(chip8.memory[0x200:], data)
	} else if strings.has_suffix(path, ".asm") {
		data, err := os.read_entire_file(path, context.allocator)
		if err == os.ERROR_NONE {
			defer delete(data, context.allocator)

			compiled_bytes, success := assemble_code(string(data))
			if success {
				defer delete(compiled_bytes)

				// Reset and load the compiled bytes
				initialize()
				mem.zero(&chip8.memory[0x200], 4096 - 0x200)
				copy(chip8.memory[0x200:], compiled_bytes)

				fmt.printfln("Successfully Assembled & Loaded: %s", path)
			} else {
				fmt.println("Assembly failed. Check your syntax.")
			}
		}
	}


}

printMemory :: proc() {
	fmt.println("--- DUMPING PROGRAM MEMORY ---")

	for i := 0x200; i < len(chip8.memory); i += 2 {
		opcode := (u16(chip8.memory[i]) << 8) | u16(chip8.memory[i + 1])


		if opcode == 0x0000 {
			if i + 3 < len(chip8.memory) && chip8.memory[i + 2] == 0 {
				fmt.println("--- END OF PROGRAM SPACE ---")
				break
			}
		}

		fmt.printf("Addr: 0x%04X | Opcode: 0x%04X\n", i, opcode)
	}
}

emulateCycle :: proc() {
	chip8.opcode = (u16(chip8.memory[chip8.pc]) << 8) | u16(chip8.memory[chip8.pc + 1])

	switch chip8.opcode & 0xF000 {
	case 0x0000:
		switch chip8.opcode & 0x000F {
		case 0x0000:
			for i in 0 ..< len(chip8.display) {
				chip8.display[i] = 0
			}
			chip8.pc += 2
		case 0x000E:
			chip8.pc = pop(&chip8.stack)
			chip8.pc += 2
		}
	case 0x1000:
		chip8.pc = chip8.opcode & 0x0FFF
	case 0x2000:
		append(&chip8.stack, chip8.pc)
		chip8.pc = chip8.opcode & 0x0FFF
	case 0x3000:
		x: u16 = u16(chip8.v[(chip8.opcode & 0x0F00) >> 8])
		NN := chip8.opcode & 0x00FF
		if x == NN {
			chip8.pc += 4
		} else {
			chip8.pc += 2
		}
	case 0x4000:
		x: u16 = u16(chip8.v[(chip8.opcode & 0x0F00) >> 8])
		NN := chip8.opcode & 0x00FF
		if x != NN {
			chip8.pc += 4
		} else {
			chip8.pc += 2
		}
	case 0x5000:
		x: u16 = u16(chip8.v[(chip8.opcode & 0x0F00) >> 8])
		y: u16 = u16(chip8.v[(chip8.opcode & 0x00F0) >> 4])
		if x == y {
			chip8.pc += 4
		} else {
			chip8.pc += 2
		}
	case 0x9000:
		x: u16 = u16(chip8.v[(chip8.opcode & 0x0F00) >> 8])
		y: u16 = u16(chip8.v[(chip8.opcode & 0x00F0) >> 4])
		if x != y {
			chip8.pc += 4
		} else {
			chip8.pc += 2
		}
	case 0x6000:
		chip8.v[(chip8.opcode & 0x0F00) >> 8] = u8(chip8.opcode & 0x00FF)
		chip8.pc += 2
	case 0x7000:
		chip8.v[(chip8.opcode & 0x0F00) >> 8] += u8(chip8.opcode & 0x00FF)
		chip8.pc += 2
	case 0x8000:
		switch chip8.opcode & 0x000F {
		case 0x0000:
			chip8.v[(chip8.opcode & 0x0F00) >> 8] = chip8.v[(chip8.opcode & 0x00F0) >> 4]
			chip8.pc += 2
		case 0x0001:
			chip8.v[(chip8.opcode & 0x0F00) >> 8] |= chip8.v[(chip8.opcode & 0x00F0) >> 4]
			chip8.pc += 2
		case 0x0002:
			chip8.v[(chip8.opcode & 0x0F00) >> 8] &= chip8.v[(chip8.opcode & 0x00F0) >> 4]
			chip8.pc += 2
		case 0x0003:
			chip8.v[(chip8.opcode & 0x0F00) >> 8] ~= chip8.v[(chip8.opcode & 0x00F0) >> 4]
			chip8.pc += 2
		case 0x0004:
			x :=
				u16(chip8.v[(chip8.opcode & 0x0F00) >> 8]) +
				u16(chip8.v[(chip8.opcode & 0x00F0) >> 4])
			chip8.v[(chip8.opcode & 0x0F00) >> 8] += chip8.v[(chip8.opcode & 0x00F0) >> 4]
			if x > 0xFF {
				chip8.v[15] = 0x01
			} else {
				chip8.v[15] = 0x00
			}
			chip8.pc += 2
		case 0x0005:
			x := chip8.v[(chip8.opcode & 0x0F00) >> 8]
			y := chip8.v[(chip8.opcode & 0x00F0) >> 4]
			chip8.v[(chip8.opcode & 0x0F00) >> 8] -= chip8.v[(chip8.opcode & 0x00F0) >> 4]
			if x >= y {
				chip8.v[15] = 0x01
			} else if x < y {
				chip8.v[15] = 0x00
			}
			chip8.pc += 2
		case 0x0007:
			x := (chip8.opcode & 0x0F00) >> 8
			y := (chip8.opcode & 0x00F0) >> 4

			chip8.v[x] = chip8.v[y] - chip8.v[x]
			if chip8.v[y] >= chip8.v[x] {
				chip8.v[15] = 1
			} else {
				chip8.v[15] = 0
			}

			chip8.pc += 2
		case 0x0006:
			x := (chip8.opcode & 0x0F00) >> 8
			y := (chip8.opcode & 0x00F0) >> 4
			lsb := (chip8.v[x] & 1)
			chip8.v[x] = (chip8.v[x]) >> 1
			chip8.v[15] = lsb
			chip8.pc += 2
		case 0x000E:
			x := (chip8.opcode & 0x0F00) >> 8
			y := (chip8.opcode & 0x00F0) >> 4
			msb := (chip8.v[x] & 0x80) >> 7
			chip8.v[x] = chip8.v[y] << 1
			chip8.v[15] = msb
			chip8.pc += 2
		}

	case 0xA000:
		chip8.I = chip8.opcode & 0x0FFF
		chip8.pc += 2
	case 0xB000:
		chip8.pc = chip8.opcode & 0x0FFF + u16(chip8.v[0])
	case 0xC000:
		x := u8(rand.uint32_max(u32(255)))
		nn := u8(chip8.opcode & 0x00FF)
		chip8.v[(chip8.opcode & 0x0F00) >> 8] = x & nn
		chip8.pc += 2
	case 0xD000:
		x: u16 = u16(chip8.v[(chip8.opcode & 0x0F00) >> 8]) % 64
		y: u16 = u16(chip8.v[(chip8.opcode & 0x00F0) >> 4]) % 32
		height: u16 = chip8.opcode & 0x000F
		pixel: u16

		chip8.v[0xF] = 0
		for yline: u16 = 0; yline < height; yline += 1 {
			if y + yline >= 32 do continue
			pixel = u16(chip8.memory[chip8.I + yline])
			for xline: u16 = 0; xline < 8; xline += 1 {
				if x + xline >= 64 do continue
				if ((pixel & (0x80 >> xline)) != 0) {
					if (chip8.display[(x + xline + ((y + yline) * 64))] == 1) {
						chip8.v[0xF] = 1
					}
					chip8.display[x + xline + ((y + yline) * 64)] ~= 1
				}
			}
		}

		chip8.drawflag = true
		chip8.pc += 2
	case 0xE000:
		switch chip8.opcode & 0x00FF {
		case 0x009E:
			if chip8.keypad[chip8.v[(chip8.opcode & 0x0F00) >> 8]] == 1 {
				chip8.pc += 4
			} else {
				chip8.pc += 2
			}
		case 0x00A1:
			if chip8.keypad[chip8.v[(chip8.opcode & 0x0F00) >> 8]] == 0 {
				chip8.pc += 4
			} else {
				chip8.pc += 2
			}
		}
	case 0xF000:
		switch chip8.opcode & 0x00FF {
		case 0x0007:
			chip8.v[(chip8.opcode & 0x0F00) >> 8] = chip8.delay_timer
			chip8.pc += 2
		case 0x0015:
			chip8.delay_timer = chip8.v[(chip8.opcode & 0x0F00) >> 8]
			chip8.pc += 2
		case 0x0018:
			chip8.sound_timer = chip8.v[(chip8.opcode & 0x0F00) >> 8]
			chip8.pc += 2
		case 0x001E:
			chip8.I += u16(chip8.v[(chip8.opcode & 0x0F00) >> 8])
			chip8.pc += 2
		case 0x000A:
			x: u16 = (chip8.opcode & 0x0F00) >> 8
			key_pressed := false

			for i in 0 ..< len(chip8.keypad) {
				if chip8.keypad[i] == 1 {
					key_pressed = true
					chip8.v[x] = u8(i)
					break
				}
			}
			if key_pressed {
				chip8.pc += 2
			}
		case 0x0029:
			i := u16(chip8.v[(chip8.opcode & 0x0F00) >> 8])
			chip8.I = i * 5
			chip8.pc += 2
		case 0x0033:
			vx := u16(chip8.v[(chip8.opcode & 0x0F00) >> 8])
			x := u8((vx / 100) % 10)
			y := u8((vx / 10) % 10)
			z := u8((vx % 10))
			chip8.memory[chip8.I] = x
			chip8.memory[chip8.I + 1] = y
			chip8.memory[chip8.I + 2] = z
			chip8.pc += 2
		case 0x0055:
			x: u16 = (chip8.opcode & 0x0F00) >> 8

			for i: u16 = 0; i <= x; i += 1 {
				chip8.memory[chip8.I + i] = chip8.v[i]
			}
			chip8.pc += 2
		case 0x0065:
			x: u16 = (chip8.opcode & 0x0F00) >> 8

			for i: u16 = 0; i <= x; i += 1 {
				chip8.v[i] = chip8.memory[chip8.I + i]
			}
			chip8.pc += 2
		}
	}
}


draw :: proc(target: rl.RenderTexture2D) {
	rl.BeginTextureMode(target)
	rl.ClearBackground(rl.BLACK)

	for i in 0 ..< 32 {
		for k in 0 ..< 64 {
			if chip8.display[(i * 64) + k] != 0 {
				rl.DrawRectangle(i32(k) * PIXEL, i32(i) * PIXEL, PIXEL, PIXEL, rl.GREEN)
			}}
	}
	rl.EndTextureMode()

}
checkInput :: proc() {
	chip8.keypad[0x1] = 1 if rl.IsKeyDown(.ONE) else 0
	chip8.keypad[0x2] = 1 if rl.IsKeyDown(.TWO) else 0
	chip8.keypad[0x3] = 1 if rl.IsKeyDown(.THREE) else 0
	chip8.keypad[0xC] = 1 if rl.IsKeyDown(.FOUR) else 0

	chip8.keypad[0x4] = 1 if rl.IsKeyDown(.Q) else 0
	chip8.keypad[0x5] = 1 if rl.IsKeyDown(.W) else 0
	chip8.keypad[0x6] = 1 if rl.IsKeyDown(.E) else 0
	chip8.keypad[0xD] = 1 if rl.IsKeyDown(.R) else 0

	chip8.keypad[0x7] = 1 if rl.IsKeyDown(.A) else 0
	chip8.keypad[0x8] = 1 if rl.IsKeyDown(.S) else 0
	chip8.keypad[0x9] = 1 if rl.IsKeyDown(.D) else 0
	chip8.keypad[0xE] = 1 if rl.IsKeyDown(.F) else 0

	chip8.keypad[0xA] = 1 if rl.IsKeyDown(.Z) else 0
	chip8.keypad[0x0] = 1 if rl.IsKeyDown(.X) else 0
	chip8.keypad[0xB] = 1 if rl.IsKeyDown(.C) else 0
	chip8.keypad[0xF] = 1 if rl.IsKeyDown(.V) else 0
}
