package chip8

import "core:path/filepath"
import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import mu "vendor:microui"
import rl "vendor:raylib"

WINDOW_HEIGHT :: 800
WINDOW_WIDTH :: 1280
PIXEL :: 10
UI_FONT_SIZE :: 15

ui_font: rl.Font
chip8: Chip8
file :string

is_paused := true
main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "CHIP8")
	defer rl.CloseWindow()
	rl.InitAudioDevice();
    defer rl.CloseAudioDevice();
	rl.SetTargetFPS(60)
	
	beep : rl.Sound= rl.LoadSound("roms/beep-21.wav");
	defer rl.UnloadSound(beep);


	ui_font = rl.LoadFontEx("fonts/ITGridbitDemo-Italic.otf", UI_FONT_SIZE, nil, 0)
	defer rl.UnloadFont(ui_font)
	rl.SetTextureFilter(ui_font.texture, .POINT)

	screen_target := rl.LoadRenderTexture(640, 320)
	defer rl.UnloadRenderTexture(screen_target)

	ctx := new(mu.Context)
	defer free(ctx)
	mu.init(ctx)
	ctx.text_width = mu_text_width
	ctx.text_height = mu_text_height


	chip8.stack = make([dynamic]u16)
	defer delete(chip8.stack)
	initialize()

	if len(os.args) > 1{
	loadProgram(os.args[1])
	}
	//printMemory()
	dropped_files : rl.FilePathList

	for !rl.WindowShouldClose() {
		if rl.IsFileDropped() {
			dropped_files = rl.LoadDroppedFiles()
			defer rl.UnloadDroppedFiles(dropped_files)

			if dropped_files.count > 0 {
				file_path := string(dropped_files.paths[0])
				//file = string(dropped_files.paths[0])

				if len(file) > 0 {
            		delete(file)
        		}
				file = strings.clone(file_path)

				if strings.has_suffix(file_path, ".ch8") {
					loadProgram(file_path)
				} else if strings.has_suffix(file_path, ".asm") {
					data, err := os.read_entire_file(file_path, context.allocator)
					if err == os.ERROR_NONE {
						defer delete(data, context.allocator)
						
						compiled_bytes, success := assemble_code(string(data))
						if success {
							defer delete(compiled_bytes)
							
							// Reset and load the compiled bytes
							initialize()
							mem.zero(&chip8.memory[0x200], 4096 - 0x200)
							copy(chip8.memory[0x200:], compiled_bytes)
							
							fmt.printfln("Successfully Assembled & Loaded: %s", file_path)
						} else {
							fmt.println("Assembly failed. Check your syntax.")
						}
					}
				}
			}
		}

		mu.input_mouse_move(ctx, rl.GetMouseX(), rl.GetMouseY())
		mu.input_scroll(ctx, 0, i32(rl.GetMouseWheelMove() * 30))

		if rl.IsMouseButtonPressed(.LEFT) {
			mu.input_mouse_down(ctx, rl.GetMouseX(), rl.GetMouseY(), .LEFT)
		}
		if rl.IsMouseButtonReleased(.LEFT) {
			mu.input_mouse_up(ctx, rl.GetMouseX(), rl.GetMouseY(), .LEFT)
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		checkInput()


		// 1. Toggle Pause State
		if rl.IsKeyPressed(.P) {
			is_paused = !is_paused
			if is_paused do fmt.println("=== EMULATOR PAUSED ===")
			else do fmt.println("=== EMULATOR RESUMED ===")
		}

		if !is_paused {
			// Normal running mode
			for i in 0 ..< 12 {
				emulateCycle()
			}
		} else {
			// Paused mode: Only advance 1 cycle when SPACE is tapped or when the step1 button is pressed
			if rl.IsKeyPressed(.SPACE) {
				emulateCycle()
			}
		}


		if chip8.delay_timer > 0 {
			chip8.delay_timer -= 1
		}

		if chip8.sound_timer > 0 {
			if chip8.sound_timer == 1 {
				fmt.println("BEEP!\n")
				rl.PlaySound(beep)
			}
			chip8.sound_timer -= 1
		}
		draw(screen_target)

		screen_rect, clip_rect: mu.Rect
		draw_debug_view(ctx, &screen_rect, &clip_rect, &is_paused,file)
		source_rec := rl.Rectangle{0, 0, 640, -320}
		dest_rec := rl.Rectangle {
			f32(screen_rect.x),
			f32(screen_rect.y),
			f32(screen_rect.w),
			f32(screen_rect.h),
		}
		rl.BeginScissorMode(clip_rect.x, clip_rect.y, clip_rect.w, clip_rect.h)
		rl.DrawTexturePro(screen_target.texture, source_rec, dest_rec, {0, 0}, 0.0, rl.WHITE)
		rl.EndScissorMode()
		rl.EndDrawing()
		free_all(context.temp_allocator)

	}


}
