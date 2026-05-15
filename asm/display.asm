; Draws the number "8" to the center of the screen
CLS             ; Clear the display

LD V0, 30       ; Set X coordinate to 30
LD V1, 12       ; Set Y coordinate to 12

LD V2, 8        ; The hex character we want to draw
LD F, V2        ; Point the 'I' register to the built-in font for the character

DRW V0, V1, 5   ; Draw a 5-byte tall sprite at X, Y

infinite_loop:
JP infinite_loop