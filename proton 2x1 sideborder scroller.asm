//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 64tass -C -B -i -a scroller.asm -o scroller.prg

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// stable Raster IRQ example
//
// by proton / FIG
// 1x2 border scroller
//
// 
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
.const ac = 2  // regs @ zeropage
.const xr = 3
.const yr = 4
.const text_pointer = 5 //- 6
.const font_pointer = 7 //- 8
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// load music
//------------------------------------------------------------------------------------------------------------------------------------------------------------
.var music = LoadSid("sids/Getting_Better.sid")
.pc = music.location "Music"
.fill music.size, music.getData(i)
//------------------------------------------------------------------------------------------------------------------------------------------------------------

                                                .memblock "start"
                                                
                                                * = $0a00
start:
                                                sei                     // prevent IRQs
                                                lda #$35
                                                sta 1                   // ROMs off

                                                lda #0
                                                jsr music.init          // init tune

                                                lda #<scrolltext        // set scrolltext pointer to beginning of the texts
                                                sta text_pointer
                                                lda #>scrolltext
                                                sta text_pointer+1

                                                lda #$40        // "space" is normally 32, we have it 64
                                                ldx #0          // because 2 chars per letter
                                        !:      sta $0400,x     // clear screen & black colorram
                                                sta $0500,x
                                                sta $0600,x
                                                sta $0700,x
                                                sta $d800,x
                                                sta $d900,x
                                                sta $da00,x
                                                sta $db00,x
                                                dex
                                                bne !-

                                                jsr reset_border_sprites

                                                lda #0       // clear idlebyte. this pattern will be visible on bottom
                                                sta $3fff    // and top borders when they are open.
                                                lda #$1c     // screen at $0400, fonts at $3000
                                                sta $d018
                                                lda #$7f     // stop all timer interrupts
                                                sta $dc0d
                                                sta $dd0d
                                                lda $dc0d    // acknowledge if any irqs
                                                lda $dd0d
                                                lda #<nmi
                                                ldx #>nmi
                                                sta $fffa   // use CPU NMI-vector (this prevents restore-key use)
                                                stx $fffb
                                                lda #<irq
                                                ldx #>irq
                                                sta $fffe   // and CPU IRQ-vector
                                                stx $ffff
                                                lda #$1b    // text mode and raster IRQ between 0-255
                                                sta $d011
                                                lda #$42    // rasterline to
                                                sta $d012   // trigger IRQ
                                                lda #1      // set Raster IRQ
                                                sta $d019
                                                sta $d01a
                                                cli         // allow irqs to happen
                                                jmp *       // main thread does nothing

irq3:                                           pha
                                                inc $d019
                                                lda #0
                                                sta $d011   // open up/down border so we can open sideborder at the first text row
                                                lda #<irq   // opening must start a line before actual rasterline
                                                sta $fffe   // and opening will fail if top border is on.
                                                lda #$30
                                                sta $d012
                                                lda $dc0d
                                                pla 
                                                rti 

irq:                                            sta ac      // save registers
                                                stx xr
                                                sty yr
                                                lda #<irq2  // set new IRQ. IRQ-subroutines are on the same memorypage
                                                sta $fffe   // so setting low byte is enough.
                                                inc $d012   // cause next Raster IRQ to occur at next line
                                                inc $d019   // ACK IRQ
                                                lda #0
                                                sta $d020
                                                lda #$1b    // put screen & text mode back on (was disabled while opening
                                                sta $d011   // top and bottom borders)
                                                tsx         // preseve stack
                                                cli         // allow new IRQ to happen
                                                nop
                                                nop         // next IRQ happens during these nops.
                                                nop         // we know what CPU is the executing. NOP takes 2 cycles
                                                nop         // so this causes IRQ within an IRQ. There will be max
                                                nop         // 1 cycle jitter when IRQ is fired
                                                nop
                                                nop
                                                nop
                                                nop
                                                nop
                                                nop
                                                nop
                                                nop
                                                nop
                                                nop
                                                nop 
irq2:                                           txs         // forget previous IRQ return
                                                ldx #7      // wait until end of the line
                                                dex
                                                bne *-1
                                                lda #1
                                                inc $d019
                                                ldy $d012                       // read current rasterline
                                                cpy $d012                       // and compare it at the last cycle of the rasterline
                                                beq *+2                         // then correct jitter if necessary.
                                                                                // depending on the jitter branch is taken or not taken
                                                                                // if we have 1 cycle jitter, comparison is happening on
                                                                                // the next line and it is not equal, branch is not taken
                                                                                // (2 cycles) but if there is no jitter and rasterline in
                                                                                // the compare is same, branch is taken (3 cycles).
                                                                                // that corrects the jitter and makes raster stable.
                                                ldx #7
                                                dex
                                                bne *-1                         // wait for next rasterline
                                                bit 1
                                                ldy colortable
                                                lda scrollreg                   // this is smooth scroll register value
                                                ora #8                          // add bit that sets 40 chars per line mode on
                                                stx $d016                       // we have 0 in X, this puts screen in 38 chars per line
                                                                                // mode causing VIC to get confused and forget to draw
                                                                                // sideborder, bacause the point to start border drawing
                                                                                // is already passed. this opens border on only one rasterline
                                                sta $d016,x                     // badline timing when four sprites is enabled on the rasterline
                                                stx $d016                       // open sideborder again.
                                                sta $d016                       // "close" border. screen width has to be set back to 40 chars
                                                                                // after each opening so we can open it again.
                                                sty $d021
                                                ldy colortable+1                // read some nice background color
                                                jsr rwait                       // subroutine that wastes suitable amount of cycles
                                                stx $d016                       // open border
                                                sta $d016                       // close border
                                                sty $d021                       // set bgcolor
                                                ldy colortable+2                // repeat this until next badline
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+3
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+4
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+5
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+6
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+7
                                                jsr rwait 
                                                stx $d016   // this is badline, and VIC steals almost all cycles from CPU
                                                sta $d016,x // badline timing
                                                stx $d016   // we have no time to set the color on badline but its ok
                                                sta $d016   // we just open 2 lines and then set the color again
                                                sty $d021
                                                ldy colortable+8
                                                jsr rwait
                                                stx $d016       // because we have 2x1 font, we repeat the opening for
                                                sta $d016       // 8 more rasterlines
                                                sty $d021
                                                ldy colortable+9
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+10
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+11
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+12
                                                jsr rwait
                                                stx $d016
                                                sta $d016
                                                sty $d021
                                                ldy colortable+13
                                                jsr rwait
                                                stx $d016 // last border open
                                                sta $d016 // and close
                                                stx $d020 // set both border and background black. 
                                                stx $d021

                                                jsr music.play          // just play the music
                                                jsr scroller            // update the scroller
                                                jsr set_border_sprites  // set sprites again after scroller is updated

slow:                                           lda #0
                                                eor #1
                                                sta slow+1              // make following color cycling to go every
                                                bne slow2                   // second frame. 25 fps.
                                                tax
                                                ldy colortable          // cycle colors
                                        !:      lda colortable+1,x
                                                sta colortable,x
                                                inx
                                                cpx #13
                                                bne !-
                                                sty colortable+13
slow2:                                        
                                                lda #<irq3              // set IRQ to next IRQ
                                                sta $fffe
                                                lda #$fa        // 3rd IRQ will occur at line 250. that's the rasterline
                                                sta $d012       // where opening top/bottom border is possible
                                                lda $dc0d   // clear irq
                                                ldy yr      // restore registers
                                                ldx xr
                                                lda ac
nmi:                                            rti

rwait:                                          ldx #4  // this just wastes some cycles. instead of wasting them
                                                dex     // you can do also something else. it's upto you abd your needs.
                                                bne *-1
                                                bit 1
                                                rts


reset_border_sprites:                                           // this places four sprites at the sideborders
                                                lda #$32        // 2 sprites on the left and other 2 on the right border
                                                sta $d003
                                                sta $d005
                                                sta $d007
                                                sta $d009
                                                lda #0          // we have cycling background color, so our font used is
                                                sta $d028       // reverdsed. so we have set all sprites black.
                                                sta $d029
                                                sta $d02a
                                                sta $d02b
                                                lda #%11010     // place sprites with x-coordinates >256
                                                sta $d010       // in the left sideborder, second sprite is at the zero
                                                                // and up (0-7) and the first sprite (leftmost) has
                                                                // kinda "negative x-coordinate". VIC has 63 cycles per
                                                                // rasterline and it has equal amount of pixels where
                                                                // every cycle is 8 pixels (hires) Total number of pixels
                                                                // on every rasterline is 504. Sprites can have coordinates
                                                                // above 256, when they are visible on the left side of the
                                                                // screen. but if coordinates go to high enough, they will
                                                                // appear back to screen on left. You have to mind that 63
                                                                // cycles, so next X-coordinate to left from 0 is not
                                                                // -1 ($ff), it is -9 ($f7) so usually the first sprite
                                                                // require little 8 pixels correction on its x-coordinate.
                                                lda #%11110
                                                sta $d015       // we use sprites 2-5 because sprite 1 takes more DMA-time
                                                ldx #$0800/64   // than all others. why? no fucking idea. :D
                                                stx $07f9       // set sprite shape pointers
                                                inx
                                                stx $07fa
                                                inx
                                                stx $07fb
                                                inx
                                                stx $07fc       // all settings above are needed to be set only once
                                                ldx #0          // in this example.
                                                lda #$ff    // we use inverted font, fill sprites fully to cover the background
                                        !:      sta $0800,x
                                                dex
                                                bne !-
set_border_sprites:
                                                lda scrollreg   // these sprite settings are updated on every frame.
                                                and #7
                                                sta $d004       // set sprite x-coordinate for second sprite
                                                ora #$e0        // put first sprite to negative x-coordinate (range e0-f7)
                                                sta $d002
                                                and #7
                                                ora #$58
                                                sta $d006       // and place 2 others to the right sideborder
                                                clc
                                                adc #$18
                                                sta $d008
                                                rts


scroller:
                                                lda scrollreg
                                                sec 
                                                sbc #3          // scroll speed
                                                bcc !+
                                                sta scrollreg
                                                rts
                                        !:      adc #8          // after 8 pixels adjust back
                                                sta scrollreg

                                                ldy #0          // then also shift all the content
                                                ldx #12
                                        !:      lda $0807,y // move data in sprites (left border)
                                                sta $0806,y
                                                lda $0808,y
                                                sta $0807,y
                                                lda $0846,y
                                                sta $0808,y
                                                lda $0847,y
                                                sta $0846,y
                                                lda $0848,y
                                                sta $0847,y
                                                lda $0887,y // move data in sprites (right border)
                                                sta $0886,y
                                                lda $0888,y
                                                sta $0887,y
                                                lda $08c6,y
                                                sta $0888,y
                                                lda $08c7,y
                                                sta $08c6,y
                                                lda $08c8,y
                                                sta $08c7,y
                                                iny
                                                iny
                                                iny
                                                dex
                                                bne !-

                                                lda $0400 // read char from screen
                                                stx font_pointer+1
                                                asl // font pointer start
                                                asl //8x
                                                rol font_pointer+1
                                                asl // 16x (16b each char)
                                                rol font_pointer+1
                                                sta font_pointer
                                                lda font_pointer+1
                                                ora #$30    // font start $3000
                                                sta font_pointer+1

                                                ldy #2      // copy font data into sprite
                                                ldx #0
                                        !:      lda (font_pointer),y
                                                sta $0848,x
                                                iny
                                                inx
                                                inx
                                                inx
                                                cpx #36
                                                bne !-

                                                ldx #0
                                        !:      lda $0401,x     // move text on the screen
                                                sta $0400,x 
                                                lda $0429,x
                                                sta $0428,x
                                                inx
                                                cpx #40
                                                bne !-
                                                lda scroll_char_buffer
                                                sta $0427   // upper half
                                                ora #1
                                                sta $044f   // lower

                                                lda scroll_char_buffer+1 // move char data into buffer so we know what char to show
                                                sta scroll_char_buffer   // on screen after it has come on screen in the sprites on right
                                                lda scroll_char_buffer+2
                                                sta scroll_char_buffer+1
                                                lda scroll_char_buffer+3
                                                sta scroll_char_buffer+2
                                                lda scroll_char_buffer+4
                                                sta scroll_char_buffer+3
                                                lda scroll_char_buffer+5
                                                sta scroll_char_buffer+4

                                                ldy #0                  // read new char from scrolltext
                                        !:      lda (text_pointer),y
                                                bpl !+
                                                lda #<scrolltext        // if negative char ($80-$ff), restart the scroll
                                                sta text_pointer
                                                lda #>scrolltext
                                                sta text_pointer+1
                                                bne !-
                                        !:      and #$3f                // only 64 chars
                                                asl
                                                sta scroll_char_buffer+5
                                                inc text_pointer
                                                bne !+
                                                inc text_pointer+1
                                        !:
                                                sty font_pointer+1
                                                asl                     // font pointer start
                                                asl                     // 8x
                                                rol font_pointer+1
                                                asl                     // 16x (16b each char)
                                                rol font_pointer+1
                                                sta font_pointer
                                                lda font_pointer+1
                                                ora #$30                // font start $3000
                                                sta font_pointer+1
                                                
                                                ldy #2
                                                ldx #0
                                        !:      lda (font_pointer),y            // copy new char to sprite on the right border
                                                sta $08c8,x
                                                iny
                                                inx
                                                inx
                                                inx
                                                cpx #36
                                                bne !-
                                                rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
scrollreg:                                      .byte $00                               // used for smooth scrolling
scroll_char_buffer:                             .fill 6,64                              // sprite char buffer       
colortable:                                     .byte 9,2,4,8,10,7,1,7,10,8,4,2,9,9     // colortable to cycle behind text
//------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                * = $3000
                                                .memblock "2x1 font"
                                                .import c64 "scrollfont"
//------------------------------------------------------------------------------------------------------------------------------------------------------------

scrolltext:
                                                .text "  uujeah!  it's a scroller........           "
                                                .text " abcdefghijklmnopqrstuvwxyz ,.1234567890 !£$%^&*()-=_+ "


                                                .byte 255                       // end byte for scroller
//------------------------------------------------------------------------------------------------------------------------------------------------------------
