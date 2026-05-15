; ==========================================
; Self-Modifying Code (Von Neumann Architecture)
; Watch the Disassembler and Memory Panels!
; ==========================================

; 1. Load the address of the 'target_instruction' into I
LD I, target_instruction

; 2. We want to change "ADD V2, 1" (which is Hex 7201) 
; into "ADD V2, 5" (which is Hex 7205).
; Because LD [I], V1 writes BOTH V0 and V1 to memory, we set them both up:
LD V0, 0x72     ; The MSB: "ADD V2"
LD V1, 0x05     ; The LSB: The new value "5"

LD [I], V1      ; Overwrites [I] with 0x72, and [I+1] with 0x05!

; 3. Now we execute the instruction we just mutated
target_instruction:
ADD V2, 1       ; <--- THIS WILL ACTUALLY ADD 5 TO V2 WHEN IT RUNS!

infinite:
JP infinite