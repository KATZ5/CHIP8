; ==========================================
; Bouncing Ball - State, Velocity, and Collisions
; ==========================================
CLS

; 1. Initial State (Position)
LD V0, 32       ; X Position
LD V1, 16       ; Y Position

; 2. Initial Velocity
LD V2, 1        ; X Velocity (+1 moves right)
LD V3, 1        ; Y Velocity (+1 moves down)

LD I, pixel

game_loop:
; Erase the old ball (XOR logic)
DRW V0, V1, 1

; Apply Velocity to Position
ADD V0, V2
ADD V1, V3

; --- COLLISION DETECTION ---
; Check Right Wall
SE V0, 63
JP skip_right
LD V2, 0xFF     ; Set X velocity to -1 (0xFF is -1 in 8-bit math!)
skip_right:

; Check Left Wall
SE V0, 0
JP skip_left
LD V2, 1        ; Set X velocity to +1
skip_left:

; Check Bottom Wall
SE V1, 31
JP skip_bottom
LD V3, 0xFF     ; Set Y velocity to -1
skip_bottom:

; Check Top Wall
SE V1, 0
JP skip_top
LD V3, 1        ; Set Y velocity to +1
skip_top:

; Draw the new ball
DRW V0, V1, 1

; Artificial Delay (so we can see it)
LD VA, 1
LD DT, VA
wait:
LD VB, DT
SE VB, 0
JP wait

JP game_loop

; --- DATA SECTION ---
pixel:
LD V0, V0       ; Our 1-bit pixel (0x8000)