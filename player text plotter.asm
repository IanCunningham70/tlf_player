//------------------------------------------------------------------------------------------------------------------------------------------------------------
// TLF music player v1.0
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// memory map
//
// music 	: $0c00 - $3fff
// 1x1 		: $4800
// 2x2 		: $5000
// bitmap 	: $6000
// code		: $c000
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// remove the screen and replace with a text plotter routine, or create a seperate version.
// add time details to the time line, maybe add raster time usage aswell.
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
#import "..\library\standardlibrary.asm"			
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------

.const Screen = $4000
.const color_ram = $d800

// line to display the clock on
.const timeLine1 = 2
.const timeLine2 = 3

.var movie_load    = $aa
.var movie_line    = Screen + (40*0)
.var screen_data    = $3f40 + Screen
.var color_data     = $4328 + Screen
.var tuneInfoLine   = Screen + (40 * 21)
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// load music
//------------------------------------------------------------------------------------------------------------------------------------------------------------
.var music = LoadSid("sids\DKC_Aqua_V2.sid")
.pc = music.location "Music"
.fill music.size, music.getData(i)
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// add a standard run line for basic
//------------------------------------------------------------------------------------------------------------------------------------------------------------
*=$0801
BasicUpstart2(musicplayer)
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "main code"
										* = $c000

										// jsr basic_fader

musicplayer:
										lda #BLUE
										sta screen
										sta border									

										jsr initialise_music
										jsr init_movie_text
										jsr InitStableRaster
										jsr InitTimer					// setup clock
										jsr InitClock		

// switch to bank 1
										lda $dd00
										and #%11111100
										ora #%00000010
										sta $dd00

										jsr show_Koala

// clear top 4 lines for scoller text and colour

										ldx #$00
								!:		lda #LIGHT_GREY
										sta color_ram,x
										lda #32
										sta movie_line,x
										inx
										cpx #160
										bne !-


										ldx #$00
								!:		lda #32
										sta tuneInfoLine-40,x
										inx
										cpx #200
										bne !-

// show tune info at bottom of screen
										ldx #$00
								!:		lda #GRAY
										sta color_ram + (40 * 21),x
										lda tune_text,x
										and #$7f
										sta tuneInfoLine,x
										inx
										cpx #120
										bne !-

// plot : for clock
										lda #$3a
										sta Screen + 40 * timeLine1 + 34
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 35
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 34
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 35

										sei
										lda #$35
										sta $01
										lda #$7f
										sta $dc0d
										sta $dd0d
										lda $dc0d
										lda $dd0d

										lda #$81
										sta irqenable   
										lda #$00
										sta raster
										lda #$81
										sta irqenable
										lda #$ff
										sta irqflag
										
										ldx #<IrqMusic
										ldy #>IrqMusic
										stx $fffe
										sty $ffff
										cli

case:									jmp case
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "show koala"
show_Koala:								ldx #00
								!:		lda screen_data,x
										sta Screen,x
										lda screen_data + (255 * 1),x
										sta Screen + (255 * 1),x
										lda screen_data + (255 * 2),x
										sta Screen + (255 * 2),x
										lda screen_data + (255 * 3),x
										sta Screen + (255 * 3),x
										lda color_data,x
										sta color_ram,x
										lda color_data + (255 * 1),x
										sta color_ram + (255 * 1),x
										lda color_data + (255 * 2),x
										sta color_ram + (255 * 2),x
										lda color_data + (255 * 3),x
										sta color_ram + (255 * 3),x
										dex
										bne !-
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "Music IRQ"
IrqMusic:
										sta IrqMusicAback + 1
										stx IrqMusicXback + 1
										sty IrqMusicYback + 1

										lda #$ef    					// space to restart music 
										cmp $dc01
										bne !+
										lda #0
										tay
										tax
										jsr music.init
										jsr InitTimer
										jsr InitClock
										jmp stlc

								!: 		jsr music.play

										jsr SetTimer

stlc:
										lda #200
										sta smoothpos
										lda #$1b
										sta screenmode


										lda #(0*8)+$32                 // calculate line for top of scroller
										sta raster
										ldx #<IrqScroller
										ldy #>IrqScroller
										stx $fffe
										sty $ffff
										asl $d019
IrqMusicAback:					        lda #$ff
IrqMusicXback:				         	ldx #$ff
IrqMusicYback:				        	ldy #$ff
										rti
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "2x2 Scroller"

IrqScroller:							sta IrqMusicAback + 1
										stx IrqMusicXback + 1
										sty IrqMusicYback + 1

										lda #%00000100					// point to charset at $4800
										sta charset

										

										lda #(2*8)+$31                 // calculate raster line for top of the logo
										sta raster
										ldx #<IrqClock
										ldy #>IrqClock
										stx $fffe
										sty $ffff
										asl $d019
IrqScrollerAback:				        lda #$ff
IrqScrollerXback:			         	ldx #$ff
IrqScrollerYback:			        	ldy #$ff
										rti
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "Clock IRQ"
IrqClock:
										sta IrqClockAback + 1
										stx IrqClockXback + 1
										sty IrqClockYback + 1
	


										lda #(4*8)+$32                 // calculate raster line for top of the logo
										sta raster
										ldx #<IrqBitmap
										ldy #>IrqBitmap
										stx $fffe
										sty $ffff
										asl $d019
IrqClockAback:					        lda #$ff
IrqClockXback:				         	ldx #$ff
IrqClockYback:				        	ldy #$ff
										rti
//------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "bitmap logo"

IrqBitmap:								sta IrqBitmapAback + 1
										stx IrqBitmapXback + 1
										sty IrqBitmapYback + 1

										bit $c45e
										bit $c45e
										bit $c45e
										bit $c45e
										bit $c45e
										bit $c45e

										nop
										nop
										nop
										nop
										nop

										lda #BLACK
										sta screen

										lda #216						// stop smooth scrolling and change to bitmap mode
										sta smoothpos
										lda #%00001000					// point to bitmap data $6000, screen at $4000
										sta charset
										lda #$3b						// switch on bitmap mode.
										sta screenmode

										// tune info IRQ
          								lda #$d8
										sta raster
										ldx #<IrqTuneInfo
										ldy #>IrqTuneInfo
										stx $fffe
										sty $ffff
										asl $d019
IrqBitmapAback:					        lda #$ff
IrqBitmapXback:				         	ldx #$ff
IrqBitmapYback:				        	ldy #$ff
										rti
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "tune info"

IrqTuneInfo:							sta IrqTuneInfoAback + 1
										stx IrqTuneInfoXback + 1
										sty IrqTuneInfoYback + 1

										// timing purposes
										bit $c45e
										bit $c45e
										bit $c45e
										bit $c45e
										nop
										nop
										nop
										nop
										nop

										lda #BLUE
										sta screen
										lda #200						// stop smooth scrolling and change to bitmap mode
										sta smoothpos
										lda #%00000010					// point to charset at $4800
										sta charset
										lda #$1b						// switch on bitmap mode.
										sta screenmode

										// these are the final IRQ loop setting to go back to the start.
          								lda #$00
										sta raster
										ldx #<IrqMusic
										ldy #>IrqMusic
										stx $fffe
										sty $ffff

										asl $d019
IrqTuneInfoAback:					    lda #$ff
IrqTuneInfoXback:				        ldx #$ff
IrqTuneInfoYback:				        ldy #$ff
										rti
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
                                      	.memblock "InitStableRaster"
InitStableRaster:
										lda #0
										sta spriteset

								!: 		bit screenmode
										bpl !-
								!:		bit screenmode
										bmi !-

										ldx raster
										inx
										cpx raster
										bne *-3
										ldy #$0a
										dey
										bne *-1
										inx
										cpx raster
										nop
										beq *+5
										nop
										bit $24
										ldy #$09
										dey
										bne *-1
										nop
										nop
										inx
										cpx raster
										nop
										beq *+4
										bit $24
										ldy #$0a
										dey
										bne *-1
										inx
										cpx raster
										bne *+2
										nop
										nop
										nop
										nop
										nop

										lda #$3e
										sta $dd06
										sty $dd07
										lda #%00010001
										sta $dd0f

										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "InitClock"
InitClock:
										lda $dc0e
										ora #%10000000
										sta $dc0e   // 50Hz

										lda #0
										sta $dc0b   // Stunden = 0 und Uhr stoppen
										sta $dc0a   // Minuten = 0
										sta $dc09   // Sekunden = 0
										sta $dc08   // Zehntel = 0 und Uhr starten
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "InitTimer"
InitTimer:
										lda #0
										sta seconds_lo
										sta seconds_hi
										sta minute_lo
										sta minute_hi
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "SetTimer2"
SetTimer:
										lda $dc09
										and #%00001111
										sta seconds_lo

										lda $dc09
										and #%01111000
										lsr
										lsr
										lsr
										lsr
										sta seconds_hi

										lda $dc0a
										and #%00001111
										sta minute_lo

										lda $dc0a
										and #%01111000
										lsr
										lsr
										lsr
										lsr
										sta minute_hi

										// plot minute hi in 2 x 2 

										ldx minute_hi
										lda chartab,x
										sta Screen + 40 * timeLine1 + 30
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 31
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 30
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 31


										// plot minute lo in 2 x 2 

										ldx minute_lo
										lda chartab,x
										sta Screen + 40 * timeLine1 + 32
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 33
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 32
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 33


										// plot second hi in 2 x 2 

										ldx seconds_hi
										lda chartab,x
										sta Screen + 40 * timeLine1 + 36
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 37
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 36
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 37

										// plot second lo in 2 x 2 

										ldx seconds_lo
										lda chartab,x
										sta Screen + 40 * timeLine1 + 38
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 39
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 38
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 39
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "initialise music"
initialise_music:						lda #$00		
										tax
										tay
										jsr music.init
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
init_movie_text:
                                        lda #$00
                                        sta movie_line_number

                                        ldx #>movie_text
                                        ldy #<movie_text
                                        rts

//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.align $100 
										.memblock "data tables"
seconds_lo:                             .byte $00
seconds_hi:                             .byte $00
minute_lo:                              .byte $00
minute_hi:                              .byte $00
chartab:                               	.byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39		// numbers 0 - 9 for clock

movie_line_number:                      .byte $00               // current line of text
movie_line_max:                         .byte $00               // maximum number of lines
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 1x1 text, fade on 1 line at a time.
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.align $100
										.memblock "tune text"
tune_text:							
									//	.text "----------------------------------------"
										.text "   Donkey King Country (Sid Version)    "
										.text "       memory usage $1000 - $23d0       "
										.text "        space to restart the tune       "
									//	.text "----------------------------------------"

//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 2x2 text, each line is 20 characters maximum 
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.align $100
										.memblock "text"
movie_text:
                                //      .text "12345678901234567890"
										.text "    tlf of padua    "
                                        .text "      presents      "
										.byte $22 // "
										.text "donky kong country"
										.byte $22 // "
                                        .text "      presents      "

										.text " composed for the   "   
                                        .text "   c64 game remix   " 
                                        .text "   compo in 2023    "



//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// import all gfx for the player
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										* = $4800
										.memblock "1x1 font"
										.import c64 "charsets/1x1-cupid.prg"

										* = $5000
										.memblock "2x2 font"
										.import c64 "charsets/2x2-mad.prg"

										* = $6000
										.memblock "bitmap logo"
										.import c64 "gfx/tlf.kla"
//------------------------------------------------------------------------------------------------------------------------------------------------------------
