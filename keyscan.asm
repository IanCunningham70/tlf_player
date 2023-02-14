
                                                * = $1000

ScanKeyboard:                                   lda $dc01    // cia1: data port register b

// press 1 to restart the tune, also reset the clock

CheckResetTune:                                 cmp #$fe
                                                bne CheckFastForward

                                                lda #BLUE
                                                sta $d020
                                                sta $d021

                                                jmp ScanKeyboard

// tha usual back-arrow key to play tune quicker
// remember to also run the clock faster

CheckFastForward:                               cmp #$fd
                                                bne CheckSpaceBar

                                                lda #WHITE
                                                sta $d020
                                                sta $d021

                                                jmp ScanKeyboard

// start / stop toggle, kill volume. 
CheckSpaceBar:                                  cmp #$ef
                                                bne ScanKeyboard

                                                lda #RED
                                                sta $d020
                                                sta $d021
                                                jmp ScanKeyboard
