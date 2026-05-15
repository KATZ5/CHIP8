; ==========================================
; TV Static - Stress testing the RNG and ALU
; ==========================================
CLS

LD I, pixel     ; Point I to our hacked pixel instruction

static_loop:
; Generate a random X between 0 and 63 (0x3F)
RND V0, 0x3F

; Generate a random Y between 0 and 31 (0x1F)
RND V1, 0x1F

; Draw the pixel!
DRW V0, V1, 1

JP static_loop

; --- DATA SECTION ---
pixel:
LD V0, V0       ; The Data-as-Code Hack! Compiles to 0x8000 (A 1-bit pixel)