package chip8

import "core:fmt"
import "core:strings"
import mu "vendor:microui"
import rl "vendor:raylib"
import "core:os"


mu_text_width :: proc(font: mu.Font, str: string) -> i32 {
	cstring := strings.clone_to_cstring(str, context.temp_allocator)
	size := rl.MeasureTextEx(ui_font, cstring, f32(UI_FONT_SIZE), 1)

	return i32(size.x)
}

mu_text_height :: proc(font: mu.Font) -> i32 {
	return UI_FONT_SIZE
}

draw_debug_view :: proc(
	ctx: ^mu.Context,
	screen_rect: ^mu.Rect,
	clip_rect: ^mu.Rect,
	is_paused: ^bool, 
	dropped_files : string,
) {

	mu.begin(ctx)

	if mu.begin_window(ctx, "DISPLAY", {320, 0, 640, 320}, {.NO_RESIZE}) {
		cnt := mu.get_current_container(ctx)
		clip_rect^ = cnt.body
		mu.layout_row(ctx, {640}, 320)

		screen_rect^ = cnt.body
		mu.end_window(ctx)
	}
	if mu.begin_window(ctx, "CPU", {0, 0, 320, 320}, {.NO_RESIZE}) {
		mu.layout_row(ctx, {-1}, 0)
		mu.text(ctx, "--- ROM Info ---")
		mu.label(ctx, "Chip8 rom")
		mu.label(ctx, "Size: 246 bytes")

		mu.text(ctx, "--- CPU ---")
		mu.layout_row(ctx, {70, 70}, 0)
		mu.label(ctx, fmt.tprintf("PC: %04X", chip8.pc))
		mu.label(ctx, fmt.tprintf("I:  %04X", chip8.I))
		mu.label(ctx, fmt.tprintf("DT: %02X", chip8.delay_timer))
		mu.label(ctx, fmt.tprintf("ST: %02X", chip8.sound_timer))

		mu.layout_row(ctx, {-1}, 0)
		mu.text(ctx, "--- Registers ---")
		mu.layout_row(ctx, {50, 50, 50, 50}, 0)
		for i in 0 ..< 16 {
			mu.label(ctx, fmt.tprintf("V%X:%02X", i, chip8.v[i]))
		}


		mu.end_window(ctx)
	}
	if mu.begin_window(ctx, "DISASSEMBLER", {960, 0, 320, 800}, {.NO_RESIZE}) {
		mu.layout_row(ctx, {130, -1}, 0)
		

		for i in 0 ..< 32 {
			addr := chip8.pc + u16(i * 2)

			if int(addr + 1) < len(chip8.memory) {
				op := (u16(chip8.memory[addr]) << 8) | u16(chip8.memory[addr + 1])
				marker := i == 0 ? "->" : "  "

				// 1. Get the human readable instruction
				instruction := disassemble_opcode(op)

				// 2. Print Column 1 (Marker + Address + Opcode)
				mu.text(ctx, fmt.tprintf("%s %04X | %04X", marker, addr, op))

				// 3. Print Column 2 (The disassembled instruction)
				mu.text(ctx, instruction)
			}
		}
		
		mu.end_window(ctx)
	}

	if mu.begin_window(ctx, "STACK", {0, 320, 320, 480}, {.NO_RESIZE}) {
		mu.layout_row(ctx, {-1}, 0)
		mu.text(ctx, "--- Stack ---")
		mu.label(ctx, fmt.tprintf("SP: %d", chip8.sp))

		if len(chip8.stack) == 0 {
			mu.text(ctx, "  (Empty)")
		} else {
			for i in 0 ..< len(chip8.stack) {
				// Point to the top of the stack
				marker := i == (len(chip8.stack) - 1) ? "->" : "  "
				mu.label(ctx, fmt.tprintf("%s [%d]: %04X", marker, i, chip8.stack[i]))
			}
		}
		mu.end_window(ctx)
	}
	if mu.begin_window(ctx, "MEMORY", {320, 560, 640, 240}, {.NO_RESIZE}) {

		// - 80 pixels for the Address column
		// - 0 for the next 8 columns 
		mu.layout_row(ctx, {80, 65, 65, 65, 65, 65, 65, 65, 65}, 0)

		for row in 0 ..< 512 {
			addr := u16(row * 8)

			marker := "  "
			if addr == (chip8.pc / 8) * 8 {
				marker = "->"
			} else if addr == (chip8.I / 8) * 8 {
				marker = " I"
			}

			mu.text(ctx, fmt.tprintf("%s 0x%04X", marker, addr))

			for i in 0 ..< 8 {

				mu.text(ctx, fmt.tprintf("%02X", chip8.memory[addr + u16(i)]))
			}
		}

		mu.end_window(ctx)
	}
	if mu.begin_window(ctx, "CONTROLS", {320, 320, 320, 240}, {.NO_RESIZE}) {
		mu.layout_row(ctx, {300}, 30)

		if .SUBMIT in mu.button(ctx, is_paused^ ? "Run" : "Pause") {
			is_paused^ = !is_paused^
		}

		if .SUBMIT in mu.button(ctx, "DUMP") {
			save_rom_to_file(&chip8.memory)
		}

		if .SUBMIT in mu.button(ctx, "Reset ROM") {
			initialize()
			
		}

		mu.text(ctx, "--- Execution ---")
		if .SUBMIT in mu.button(ctx, "Step 1") do if is_paused^ do emulateCycle()
		if .SUBMIT in mu.button(ctx, "Step 10") do if is_paused^ {
			for _ in 0 ..< 10 do emulateCycle()
		}
		mu.end_window(ctx)
	}
	if mu.begin_window(ctx, "KEYPAD", {640, 320, 320, 240}, {.NO_RESIZE}) {
		mu.layout_row(ctx, {73, 73, 73, 73}, 45)

		keys := [16]string {
			"1",
			"2",
			"3",
			"C",
			"4",
			"5",
			"6",
			"D",
			"7",
			"8",
			"9",
			"E",
			"A",
			"0",
			"B",
			"F",
		}
		key_indices := [16]u8 {
			0x1,
			0x2,
			0x3,
			0xC,
			0x4,
			0x5,
			0x6,
			0xD,
			0x7,
			0x8,
			0x9,
			0xE,
			0xA,
			0x0,
			0xB,
			0xF,
		}

		for i in 0 ..< 16 {
			is_pressed := chip8.keypad[key_indices[i]] == 1
			label := is_pressed ? fmt.tprintf("[%s]", keys[i]) : keys[i]
			mu.button(ctx, label) 
		}
		mu.end_window(ctx)
	}
	mu.end(ctx)

	command: ^mu.Command
	for mu.next_command(ctx, &command) {
		#partial switch cmd in command.variant {
		case ^mu.Command_Text:
			cstr := strings.clone_to_cstring(cmd.str, context.temp_allocator)
			color := rl.Color{cmd.color.r, cmd.color.g, cmd.color.b, cmd.color.a}
			rl.DrawText(cstr, cmd.pos.x, cmd.pos.y, UI_FONT_SIZE, color)
		case ^mu.Command_Rect:
			rect := rl.Rectangle {
				f32(cmd.rect.x),
				f32(cmd.rect.y),
				f32(cmd.rect.w),
				f32(cmd.rect.h),
			}
			color := rl.Color{cmd.color.r, cmd.color.g, cmd.color.b, cmd.color.a}
			rl.DrawRectangleRec(rect, color)
		case ^mu.Command_Clip:
			rl.BeginScissorMode(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)

		}
	}
	rl.EndScissorMode()
}

disassemble_opcode :: proc(opcode: u16) -> string {
	// Break the opcode down into useful variables
	n1 := (opcode & 0xF000) >> 12
	x := (opcode & 0x0F00) >> 8
	y := (opcode & 0x00F0) >> 4
	n := opcode & 0x000F
	nn := opcode & 0x00FF
	nnn := opcode & 0x0FFF

	// Return an empty string for empty memory
	if opcode == 0x0000 do return ""

	switch n1 {
	case 0x0:
		if opcode == 0x00E0 do return "CLS"
		if opcode == 0x00EE do return "RET"
		return fmt.tprintf("SYS %03X", nnn)
	case 0x1:
		return fmt.tprintf("JP %03X", nnn)
	case 0x2:
		return fmt.tprintf("CALL %03X", nnn)
	case 0x3:
		return fmt.tprintf("SE V%X, %02X", x, nn)
	case 0x4:
		return fmt.tprintf("SNE V%X, %02X", x, nn)
	case 0x5:
		return fmt.tprintf("SE V%X, V%X", x, y)
	case 0x6:
		return fmt.tprintf("LD V%X, %02X", x, nn)
	case 0x7:
		return fmt.tprintf("ADD V%X, %02X", x, nn)
	case 0x8:
		switch n {
		case 0x0:
			return fmt.tprintf("LD V%X, V%X", x, y)
		case 0x1:
			return fmt.tprintf("OR V%X, V%X", x, y)
		case 0x2:
			return fmt.tprintf("AND V%X, V%X", x, y)
		case 0x3:
			return fmt.tprintf("XOR V%X, V%X", x, y)
		case 0x4:
			return fmt.tprintf("ADD V%X, V%X", x, y)
		case 0x5:
			return fmt.tprintf("SUB V%X, V%X", x, y)
		case 0x6:
			return fmt.tprintf("SHR V%X", x)
		case 0x7:
			return fmt.tprintf("SUBN V%X, V%X", x, y)
		case 0xE:
			return fmt.tprintf("SHL V%X", x)
		}
	case 0x9:
		return fmt.tprintf("SNE V%X, V%X", x, y)
	case 0xA:
		return fmt.tprintf("LD I, %03X", nnn)
	case 0xB:
		return fmt.tprintf("JP V0, %03X", nnn)
	case 0xC:
		return fmt.tprintf("RND V%X, %02X", x, nn)
	case 0xD:
		return fmt.tprintf("DRW V%X, V%X, %X", x, y, n)
	case 0xE:
		if nn == 0x9E do return fmt.tprintf("SKP V%X", x)
		if nn == 0xA1 do return fmt.tprintf("SKNP V%X", x)
	case 0xF:
		switch nn {
		case 0x07:
			return fmt.tprintf("LD V%X, DT", x)
		case 0x0A:
			return fmt.tprintf("LD V%X, K", x)
		case 0x15:
			return fmt.tprintf("LD DT, V%X", x)
		case 0x18:
			return fmt.tprintf("LD ST, V%X", x)
		case 0x1E:
			return fmt.tprintf("ADD I, V%X", x)
		case 0x29:
			return fmt.tprintf("LD F, V%X", x)
		case 0x33:
			return fmt.tprintf("LD B, V%X", x)
		case 0x55:
			return fmt.tprintf("LD [I], V%X", x)
		case 0x65:
			return fmt.tprintf("LD V%X, [I]", x)
		}
	}

	// If we hit data that isn't a valid instruction (prite data)
	return "???"
}

save_rom_to_file :: proc(memory: ^[4096]u8) {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)

    //Loop through the ROM memory space
    for pc := 0x200; pc < 4096; pc += 2 {
        // Fetch the opcode
        opcode := (u16(memory[pc]) << 8) | u16(memory[pc+1])

        if opcode == 0x0000 {
            continue 
        }

        instruction := disassemble_opcode(opcode)

        fmt.sbprintfln(&builder, "0x%04X: %04X - %s", pc, opcode, instruction)
    }

    final_text := strings.to_string(builder)

    err := os.write_entire_file("disassembly.txt", transmute([]u8)final_text)

    if err != nil {
        fmt.eprintfln("Failed to save disassembly: %v", err)
    } else {
        fmt.println("Successfully dumped ROM to disassembly.txt!")
    }
}
