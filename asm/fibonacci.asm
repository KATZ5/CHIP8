; ==========================================
; CHIP-8 Fibonacci Sequence Generator
; Watch the V0 and V1 registers in the CPU panel!
; ==========================================

CLS             ; Clear the screen just to be clean

; 1. Initialize the first two numbers of the sequence
LD V0, 0        ; F(n-1) = 0
LD V1, 1        ; F(n)   = 1

calculate:
; 2. Artificial Delay (So humans can watch the registers change)
; We set the Delay Timer to 30 (roughly half a second at 60Hz)
LD VA, 30       
LD DT, VA       

wait_loop:
LD VB, DT       ; Read the delay timer into VB
SE VB, 0        ; Skip the next instruction if the timer hit 0
JP wait_loop    ; Otherwise, keep waiting


; 3. The Fibonacci Math (V2 = V0 + V1)
LD V2, V0       ; Copy V0 into V2 (Temp)
ADD V2, V1      ; Add V1 to V2

; 4. Shift the sequence forward
LD V0, V1       ; V0 becomes the old V1
LD V1, V2       ; V1 becomes the new sum

; 5. Repeat forever
JP calculate