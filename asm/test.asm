; ==========================================
; Runtime Sprite Generation via LD [I], Vx
; ==========================================
CLS

; 1. Load the raw byte data into our registers
LD V0, 0x3C     ; Top row of the alien (00111100)
LD V1, 0x7E     ; Bottom row of the alien (01111110)

; 2. Point 'I' to a safe, empty space in memory
LD I, sprite_ram

; 3. Dump the registers into memory!
; This writes V0 into [I], and V1 into [I+1]
LD [I], V1      

; 4. Set up coordinates and draw
LD VA, 10       ; X Coordinate
LD VB, 10       ; Y Coordinate
LD I, sprite_ram ; Ensure I is pointing at our newly built sprite
DRW VA, VB, 2   ; Draw a 2-byte tall sprite

infinite_loop:
JP infinite_loop

; --- EMPTY MEMORY BOUNDARY ---
sprite_ram:
; There is no code here! The assembler stops building here.
; Everything from this address up to 0xFFF is just empty 0x00s, 
; giving us a massive blank canvas to write into.