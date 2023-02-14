//------------------------------------------------------------------------------------------------------------------------------------------------------------
// TLF music player v1.0 - the one with the 2x2 scroller
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// music 	: $0900 - $3fff
// 1x1 		: $4800
// 2x2 		: $5000
// bitmap 	: $6000
// code		: $c000
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
#import "..\library\standardlibrary.asm"			
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
.const ScreenMemory = $4000
.const color_ram = $d800
.const timeLine1 = 2									// line to display the clock on
.const timeLine2 = 3									// 2nd line for clock display

.var scroller_zeropage  = $aa							// used for the 2x2 scroller
.var scroller_line    	= ScreenMemory + (40*0)			// line of scroller on screen
.var screen_data 		= $3f40 + ScreenMemory			// bitmap screen data
.var color_data 		= $4328 + ScreenMemory			// bitmap color data
.var tuneInfoLine 		= ScreenMemory + (40 * 21)		// tuneinfo line
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

musicplayer:							lda $dd00						// switch to bank 1
										and #%11111100
										ora #%00000010
										sta $dd00

										lda #BLUE						// hardcode screen and border to match the bitmap
										sta screen
										sta border									

										jsr InitStableRaster
										jsr InitTimer					// setup clock
										jsr InitClock		
										jsr show_Koala					// display the bitmap
										jsr initialise_music
										jsr init_scroll_text

										lda #$20
										sta MusicPLay
										sta ClockTime
										lda #$01
										sta toggleByte

// clear top 4 lines for scoller text and colour
										ldx #$00
								!:		lda #LIGHT_GREY
										sta color_ram,x
										lda #32
										sta scroller_line,x
										inx
										cpx #160
										bne !-

// clear bottom 5 lines for scoller text and colour
										ldx #$00
								!:		lda #32
										sta tuneInfoLine-40,x
										inx
										cpx #200
										bne !-

// show tune info at bottom of screen
										ldx #$00
								!:		lda #LIGHT_BLUE
										sta color_ram + (40 * 21),x
										lda tune_text,x
										and #$7f
										sta tuneInfoLine,x
										inx
										cpx #160
										bne !-

// plot : for clock
										lda #$3a
										sta ScreenMemory + 40 * timeLine1 + 34
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine1 + 35
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 34
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 35

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

										jsr setSprite							// display sprite

case:									jmp case
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "setsprite"
setSprite:								lda #%00000001
										sta spriteset

										lda #%00000000
										sta spriteexpy
										sta spriteexpx

										lda #%00000000
										sta spritepr
										sta spritermsb

										lda #WHITE
										sta spritecolors

										ldx #240
										stx sprite0x
										ldy #64
										sty sprite0y

										lda #(play_sprite / 64)
										sta ScreenMemory + $03f8				// $03f8 + $4000 = $43f8
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "show koala"
show_Koala:								ldx #00
								!:		lda screen_data,x
										sta ScreenMemory,x
										lda screen_data + (255 * 1),x
										sta ScreenMemory + (255 * 1),x
										lda screen_data + (255 * 2),x
										sta ScreenMemory + (255 * 2),x
										lda screen_data + (255 * 3),x
										sta ScreenMemory + (255 * 3),x
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
										.memblock "Music IRQ"
IrqMusic:								sta IrqMusicAback + 1
										stx IrqMusicXback + 1
										sty IrqMusicYback + 1

MusicPLay:						 		jsr music.play
ClockTime:								jsr SetTimer

										lda #200
										sta smoothpos
										lda #$1b
										sta screenmode

										jsr scroller_2x2				// run actual scroll routine

										lda #(0*8)+$32                 	// calculate line for top of scroller
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

										lda #%00000100					// point to charset at $4800, screen at $4000
										sta charset

										lda smoothpos
										and #$f0
										ora scroll_xposition
										sta smoothpos

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
										.memblock "Clock IRQ"
IrqClock:								sta IrqClockAback + 1
										stx IrqClockXback + 1
										sty IrqClockYback + 1
	
										ldx #$0a
										dex
										bne *-1
										lda #200
										sta smoothpos

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
										.memblock "bitmap logo"
IrqBitmap:								sta IrqBitmapAback + 1
										stx IrqBitmapXback + 1
										sty IrqBitmapYback + 1

										// timing to move vold dots off the screen
										
										ldx #$09
										dex
										bne *-1
	
										lda #BLACK						// set colour of bitmap background
										sta screen
										lda #216						// stop smooth scrolling and change to bitmap mode
										sta smoothpos
										lda #%00001000					// point to bitmap data $6000, screen at $4000
										sta charset
										lda #$3b						// switch on bitmap mode.
										sta screenmode

										lda SpriteCurrentColor
										sta spritecolors

										jsr infoTextFader
										jsr infoTextFader2
										jsr infoTextFader3

ScanKeyboard:                        	lda $dc01    // cia1: data port register b

// press 1 to restart the tune, also reset the clock

CheckResetTune:                         cmp #$fe
										bne CheckFastForward

										jsr initialise_music
										jsr InitTimer
										jsr InitClock
										lda #$20
										sta MusicPLay
										sta ClockTime
										lda #$01
										sta toggleByte

										jmp KeyboardScanned

// tha usual back-arrow key to play tune quicker, remember to also run the clock faster

CheckFastForward:                       cmp #$fd
										bne CheckSpaceBar

										jsr music.play
										jsr SetTimer
										jmp KeyboardScanned

// start / stop toggle, kill volume. 
CheckSpaceBar:                          cmp #$ef
										bne KeyboardScanned

										lda toggleByte
										beq !+

										lda #$ad
										sta MusicPLay
										sta ClockTime
										lda #$00
										sta toggleByte
										sta $d41f
										jmp KeyboardScanned

								!:      lda #$20
										sta MusicPLay
										sta ClockTime
										lda #$01
										sta toggleByte
KeyboardScanned:												

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

										lda #BLUE						// set colour for text background
										sta screen
										lda #200						// stop smooth scrolling and change to bitmap mode
										sta smoothpos
										lda #%00000010					// point to charset at $4800, screen at $4000
										sta charset
										lda #$1b						// switch off bitmap mode.
										sta screenmode

										jsr SpriteColorCycle

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
InitStableRaster:						//lda #$00
										//sta spriteset

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
InitClock:								lda $dc0e
										ora #%10000000
										sta $dc0e   // 50Hz

										lda #$00
										sta $dc0b   // Stunden = 0 und Uhr stoppen
										sta $dc0a   // Minuten = 0
										sta $dc09   // Sekunden = 0
										sta $dc08   // Zehntel = 0 und Uhr starten
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "InitTimer"
InitTimer:								lda #$00
										sta seconds_lo
										sta seconds_hi
										sta minute_lo
										sta minute_hi
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "SetTimer2"
SetTimer:								lda $dc09
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
										sta ScreenMemory + 40 * timeLine1 + 30
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine1 + 31
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 30
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 31
// plot minute lo in 2 x 2 
										ldx minute_lo
										lda chartab,x
										sta ScreenMemory + 40 * timeLine1 + 32
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine1 + 33
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 32
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 33
// plot second hi in 2 x 2
										ldx seconds_hi
										lda chartab,x
										sta ScreenMemory + 40 * timeLine1 + 36
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine1 + 37
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 36
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 37
// plot second lo in 2 x 2 
										ldx seconds_lo
										lda chartab,x
										sta ScreenMemory + 40 * timeLine1 + 38
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine1 + 39
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 38
										clc
										adc #$40
										sta ScreenMemory + 40 * timeLine2 + 39
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "initialise music"
initialise_music:						lda #$00		
										tax
										tay
										jsr music.init
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "2x2 scroller with pause"
scroller_2x2:		  					lda scroll_delay
										beq !+
										dec scroll_delay
										rts
		    				!:			lda scroll_xposition
										sec
										sbc #$03						// hardcode scroll speed
										and #$07
										sta scroll_xposition
										bcc !+
										rts
							!:			ldx #$00
							!:			lda scroller_line+1,x
										sta scroller_line,x
										lda scroller_line+41,x
										sta scroller_line+40,x
										inx
										cpx #$28
										bne !-
										jsr scroller_nextchar
										sta scroller_line+39
										clc
										adc #128
										sta scroller_line+79
										rts
scroller_nextchar:    					lda scroller_width
										cmp #$01
										beq scroller_plotChar
										lda scroller_tempChar
										clc
										adc #64
										sta scroller_tempChar
										inc scroller_width
										rts
scroller_plotChar:     					ldy #$00
										sty scroller_width
										lda (scroller_zeropage),y
										bne !+

										jsr init_scroll_text
										jmp scroller_plotChar

								!:		inc scroller_zeropage
										bne !+
										inc scroller_zeropage+1
								!:	   	cmp #$1f
										bne !+
										jsr scroll_pause
										jmp scroller_nextchar
								!:		and #$7f						// required to convert .text letters
										sta scroller_tempChar
										rts

scroll_pause:   						ldy #$00
										lda (scroller_zeropage),y
										tax
										lda scroller_pauseLength,x
										sta scroll_delay
										lda #$20
										sta scroller_tempChar

										inc scroller_zeropage			// move pointer to the next character
										bne !+
										inc scroller_zeropage+1
								!:     	rts

init_scroll_text:						ldx #<scroll_text
										ldy #>scroll_text
										stx scroller_zeropage
										sty scroller_zeropage+1
										lda #$01					// reset width
										sta scroller_width
										lda #$20					// reset to space
										sta scroller_tempChar
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
infoTextFader:							lda infoTextDelay
										sec
										sbc #$05						// hardcode scroll speed
										and #$07
										sta infoTextDelay
										bcc !+
										rts
							!:			ldx #$00
										lda tune_info_colorTemp
							!:			sta color_ram + (40 * 21),x
										inx
										cpx #$28
										bne !-

										ldy tune_info_colorCounter
										cpy tune_info_colorMax
										bne !+
										lda #$00
										sta tune_info_colorCounter
										rts
							!:			lda tune_info_colorTable,y
										sta tune_info_colorTemp
										inc tune_info_colorCounter
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
infoTextFader2:							lda infoTextDelay+1
										sec
										sbc #$04						// hardcode scroll speed
										and #$07
										sta infoTextDelay+1
										bcc !+
										rts
							!:			ldx #$00
										lda tune_info_colorTemp+1
							!:			sta color_ram + (40 * 22),x
										inx
										cpx #$28
										bne !-

										ldy tune_info_colorCounter+1
										cpy tune_info_colorMax
										bne !+
										lda #$00
										sta tune_info_colorCounter+1
										rts
							!:			lda tune_info_colorTable,y
										sta tune_info_colorTemp+1
										inc tune_info_colorCounter+1
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
infoTextFader3:							lda infoTextDelay+2
										sec
										sbc #$06						// hardcode scroll speed
										and #$07
										sta infoTextDelay+2
										bcc !+
										rts
							!:			ldx #$00
										lda tune_info_colorTemp+2
							!:			sta color_ram + (40 * 23),x
										inx
										cpx #$28
										bne !-

										ldy tune_info_colorCounter+2
										cpy tune_info_colorMax
										bne !+
										lda #$00
										sta tune_info_colorCounter+2
										rts
							!:			lda tune_info_colorTable,y
										sta tune_info_colorTemp+2
										inc tune_info_colorCounter+2
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
SpriteColorCycle:						lda SpriteColorDelay
										sec
										sbc #$03						// hardcode cycle speed
										and #$07
										sta SpriteColorDelay
										bcc !+
										rts
							!:			ldy SpriteColorCounter
										cpy SpriteColorCounterMax
										bne !+
										lda #$00
										sta SpriteColorCounter
										rts
							!:			lda SpriteColorTable,y
										sta SpriteCurrentColor
										inc SpriteColorCounter
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------
// start of ALL data tables
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.align $100 
										.memblock "data tables"

scroll_xposition:    					.byte $00
scroll_delay:   						.byte $00
scroller_width:    						.byte $00
scroller_tempChar:    					.byte $00
scroller_pauseLength:   				.byte 100,125,150,175,200,225,250
toggleByte:								.byte $00													// toggle music on / off
seconds_lo:                             .byte $00
seconds_hi:                             .byte $00
minute_lo:                              .byte $00
minute_hi:                              .byte $00
chartab:                               	.byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39		// numbers 0 - 9 for clock

infoTextDelay:							.byte $00					// used to control the speed of the text fader.
										.byte $00					// line 2
										.byte $00					// line 3

tune_info_colorCounter:					.byte $00					// count the current number
										.byte $00
										.byte $00
										
tune_info_colorMax:						.byte 16					// how many colours in the cycle +1

tune_info_colorTemp:					.byte $00					// line 1
										.byte $00					// line 2
										.byte $00					// line 3

tune_info_colorTable:					.byte $01,$0d,$03,$0e,$04,$0b,$06,$06
										.byte $06,$06,$0b,$04,$0e,$03,$0d										
										.byte $0f					// final colour of the tune text.

spritePointers:							.byte (play_sprite / 64)
										.byte (pause_sprite / 64)

SpriteColorDelay:						.byte $00
SpriteColorCounter:						.byte $00
SpriteCurrentColor:						.byte $00
SpriteColorCounterMax:					.byte 15

SpriteColorTable:						.byte $01,$0d,$03,$0e,$04,$0b,$06,$06
										.byte $06,$06,$0b,$04,$0e,$03,$0d	


//------------------------------------------------------------------------------------------------------------------------------------------------------------




//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 1x1 text, fade 1 line at a time. 1 more line of text is available if needed.
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.align $100
										.memblock "tune text"
									//	.text "----------------------------------------"
tune_text:								.text "   Donkey Kong Country (Sid Version)    "
										.text "       memory usage $1000 - $23d0       "
										.text "        space to restart the tune       "
										.text "                                        "
//------------------------------------------------------------------------------------------------------------------------------------------------------------
// enter .byte $1f followed by a number from 1 - 6 for different pause's.
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.align $100
										.memblock "scroll text"
scroll_text:
										.text "        tlf of padua presents  "

										.byte $22 // "
										.text "donkykong country"
										.byte $22 // "

										.text "    composed for the c64 game remix compo in 2023                                  "
										.text "                   credits go like this ..... tlf logo by premium, " 
										.text "charset's 2x2 & 1x1 charset by cupid ....... and code by case with help from dano (thank you)"
										.text "                    "
										.byte $00					// end of scroll text
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// import all gfx 
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "sprites"
										* = $4400
pause_sprite:							.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03
										.byte $c3,$c0,$03,$c3,$c0,$03,$c3,$c0,$03,$c3,$c0,$03,$c3,$c0,$03,$c3
										.byte $c0,$03,$c3,$c0,$03,$c3,$c0,$03,$c3,$c0,$03,$c3,$c0,$03,$c3,$c0
										.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

play_sprite:							.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01
										.byte $f0,$00,$01,$f8,$00,$01,$fc,$00,$01,$fe,$00,$01,$ff,$00,$01,$ff
										.byte $80,$01,$ff,$80,$01,$ff,$00,$01,$fe,$00,$01,$fc,$00,$01,$f8,$00
										.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

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
