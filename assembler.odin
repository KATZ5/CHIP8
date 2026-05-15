package chip8

import "core:fmt"
import "core:strconv"
import "core:strings"

parse_reg :: proc(s: string) -> (u16, bool) {
	if len(s) == 2 && s[0] == 'v' {
		val, ok := strconv.parse_int(s[1:], 16)
		if ok do return u16(val), true
	}
	return 0, false
}

parse_val :: proc(s: string, labels: map[string]u16) -> (u16, bool) {
	if val, exists := labels[s]; exists do return val, true

	if strings.has_prefix(s, "0x") {
		val, ok := strconv.parse_int(s[2:], 16)
		return u16(val), ok
	}

	val, ok := strconv.parse_int(s, 10)
	return u16(val), ok
}

assemble_code :: proc(source: string) -> (compiled_bytes: []u8, success: bool) {
	labels := make(map[string]u16)
	defer delete(labels)

	lines := strings.split(source, "\n")
	defer delete(lines)

	current_address: u16 = 0x200

	for raw_line in lines {
		line := strings.to_lower(strings.trim_space(raw_line))

		if idx := strings.index(line, ";"); idx >= 0 {
			line = strings.trim_space(line[:idx])
		}
		if len(line) == 0 do continue

		if strings.has_suffix(line, ":") {
			label_name := line[:len(line) - 1]
			labels[label_name] = current_address
			continue
		}

		current_address += 2
	}


	output := make([dynamic]u8)
	line_number := 0

	for raw_line in lines {
		line_number += 1
		line := strings.to_lower(strings.trim_space(raw_line))

		if idx := strings.index(line, ";"); idx >= 0 {
			line = strings.trim_space(line[:idx])
		}
		if len(line) == 0 || strings.has_suffix(line, ":") do continue

		clean_line, sec := strings.replace_all(line, ",", " ", context.temp_allocator)
		tokens := strings.fields(clean_line, context.temp_allocator)
		if len(tokens) == 0 do continue

		op := tokens[0]
		opcode: u16 = 0
		err := false

		switch op {
		case "cls":
			opcode = 0x00E0
		case "ret":
			opcode = 0x00EE
		case "sys":
			val, _ := parse_val(tokens[1], labels)
			opcode = 0x0000 | (val & 0x0FFF)
		case "jp":
			if tokens[1] == "v0" {
				val, _ := parse_val(tokens[2], labels)
				opcode = 0xB000 | (val & 0x0FFF)
			} else {
				val, _ := parse_val(tokens[1], labels)
				opcode = 0x1000 | (val & 0x0FFF)
			}
		case "call":
			val, _ := parse_val(tokens[1], labels)
			opcode = 0x2000 | (val & 0x0FFF)
		case "se":
			x, _ := parse_reg(tokens[1])
			if y, is_reg := parse_reg(tokens[2]); is_reg {
				opcode = 0x5000 | (x << 8) | (y << 4) | 0x0000
			} else {
				val, _ := parse_val(tokens[2], labels)
				opcode = 0x3000 | (x << 8) | (val & 0x00FF)
			}
		case "sne":
			x, _ := parse_reg(tokens[1])
			if y, is_reg := parse_reg(tokens[2]); is_reg {
				opcode = 0x9000 | (x << 8) | (y << 4) | 0x0000
			} else {
				val, _ := parse_val(tokens[2], labels)
				opcode = 0x4000 | (x << 8) | (val & 0x00FF)
			}
		case "ld":
			if tokens[1] == "i" {
				val, _ := parse_val(tokens[2], labels)
				opcode = 0xA000 | (val & 0x0FFF)
			} else if tokens[1] == "dt" {
				x, _ := parse_reg(tokens[2])
				opcode = 0xF000 | (x << 8) | 0x0015
			} else if tokens[1] == "st" {
				x, _ := parse_reg(tokens[2])
				opcode = 0xF000 | (x << 8) | 0x0018
			} else if tokens[1] == "f" {
				x, _ := parse_reg(tokens[2])
				opcode = 0xF000 | (x << 8) | 0x0029
			} else if tokens[1] == "b" {
				x, _ := parse_reg(tokens[2])
				opcode = 0xF000 | (x << 8) | 0x0033
			} else if tokens[1] == "[i]" {
				x, _ := parse_reg(tokens[2])
				opcode = 0xF000 | (x << 8) | 0x0055
			} else {
				x, _ := parse_reg(tokens[1])
				if tokens[2] == "dt" {
					opcode = 0xF000 | (x << 8) | 0x0007
				} else if tokens[2] == "k" {
					opcode = 0xF000 | (x << 8) | 0x000A
				} else if tokens[2] == "[i]" {
					opcode = 0xF000 | (x << 8) | 0x0065
				} else {
					if y, is_reg := parse_reg(tokens[2]); is_reg {
						opcode = 0x8000 | (x << 8) | (y << 4) | 0x0000
					} else {
						val, _ := parse_val(tokens[2], labels)
						opcode = 0x6000 | (x << 8) | (val & 0x00FF)
					}
				}
			}
		case "add":
			if tokens[1] == "i" {
				x, _ := parse_reg(tokens[2])
				opcode = 0xF000 | (x << 8) | 0x001E
			} else {
				x, _ := parse_reg(tokens[1])
				if y, is_reg := parse_reg(tokens[2]); is_reg {
					opcode = 0x8000 | (x << 8) | (y << 4) | 0x0004
				} else {
					val, _ := parse_val(tokens[2], labels)
					opcode = 0x7000 | (x << 8) | (val & 0x00FF)
				}
			}
		case "or":
			x, _ := parse_reg(tokens[1]); y, _ := parse_reg(tokens[2])
			opcode = 0x8000 | (x << 8) | (y << 4) | 0x0001
		case "and":
			x, _ := parse_reg(tokens[1]); y, _ := parse_reg(tokens[2])
			opcode = 0x8000 | (x << 8) | (y << 4) | 0x0002
		case "xor":
			x, _ := parse_reg(tokens[1]); y, _ := parse_reg(tokens[2])
			opcode = 0x8000 | (x << 8) | (y << 4) | 0x0003
		case "sub":
			x, _ := parse_reg(tokens[1]); y, _ := parse_reg(tokens[2])
			opcode = 0x8000 | (x << 8) | (y << 4) | 0x0005
		case "shr":
			x, _ := parse_reg(tokens[1])
			y: u16 = 0
			if len(tokens) > 2 do y, _ = parse_reg(tokens[2])
			opcode = 0x8000 | (x << 8) | (y << 4) | 0x0006
		case "subn":
			x, _ := parse_reg(tokens[1]); y, _ := parse_reg(tokens[2])
			opcode = 0x8000 | (x << 8) | (y << 4) | 0x0007
		case "shl":
			x, _ := parse_reg(tokens[1])
			y: u16 = 0
			if len(tokens) > 2 do y, _ = parse_reg(tokens[2])
			opcode = 0x8000 | (x << 8) | (y << 4) | 0x000E
		case "rnd":
			x, _ := parse_reg(tokens[1]); val, _ := parse_val(tokens[2], labels)
			opcode = 0xC000 | (x << 8) | (val & 0x00FF)
		case "drw":
			x, _ := parse_reg(tokens[1]); y, _ := parse_reg(tokens[2])
			val, _ := parse_val(tokens[3], labels)
			opcode = 0xD000 | (x << 8) | (y << 4) | (val & 0x000F)
		case "skp":
			x, _ := parse_reg(tokens[1])
			opcode = 0xE000 | (x << 8) | 0x009E
		case "sknp":
			x, _ := parse_reg(tokens[1])
			opcode = 0xE000 | (x << 8) | 0x00A1
		case:
			fmt.eprintfln("Assembler Error at line %d: Unknown instruction '%s'", line_number, op)
			err = true
		}

		if err do return nil, false

		append(&output, u8((opcode & 0xFF00) >> 8))
		append(&output, u8(opcode & 0x00FF))
	}

	return output[:], true
}

