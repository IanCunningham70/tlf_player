//------------------------------------------------------------------------------------------------------------------------------------------------------------
// TLF music player v1.0
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// memory map
//
// music : $0c00 - $1fff
// bitmap : $200
// 1x1 : $4800
// 2x2 : $5000
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
#import "standardlibrary.asm"			
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
.var scroller_zeropage    = $aa
.var scroller_line    = 1024+(40*0)
.var screen_data = $3f40
.var color_data = $4328
.var back_colour = $4710

.const Screen = $0400
.const color_ram = $d800

// line to display the clock on
.const timeLine1 = 10
.const timeLine2 = 11
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// load music
//------------------------------------------------------------------------------------------------------------------------------------------------------------
.var music = LoadSid("sids\Yellow.sid")
.pc = music.location "Music"
.fill music.size, music.getData(i)
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
BasicUpstart2(music_player)
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "main code"
										* = $c000
music_player:
										// jsr basic_fader

										lda #BLACK
										sta screen
										sta border									

										jsr initialise_music
										jsr init_scroll_text
										jsr InitStableRaster
										
										// setup clock

										jsr InitTimer
										jsr InitClock

										jsr show_Koala


										ldx #80
								!:		lda #YELLOW
										sta scroller_line+$d400,x
										lda #32
										sta scroller_line,x
										dex
										bpl !-

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
										lda screen_data + $100,x
										sta Screen + $100,x
										lda screen_data + $200,x
										sta Screen + $200,x
										lda screen_data + $300,x
										sta Screen + $300,x
										lda color_data,x
										sta color_ram,x
										lda color_data + $100,x
										sta color_ram + $100,x
										lda color_data + $200,x
										sta color_ram + $200,x
										lda color_data + $300,x
										sta color_ram + $300,x
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

										jsr scroller_2x2

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

										lda #24
										sta charset

										lda smoothpos
										and #$f0
										ora scroll_xposition
										sta smoothpos

										lda #(2*8)+$32                 // calculate raster line for bottom of scroller
										cmp raster
										bne *-3
										ldx #$0a
										dex
										bne *-1
										lda #216
										sta smoothpos
										lda #26
										sta charset
										lda #$3b
										sta screenmode

										lda #(6*8)+$32                 // calculate raster line for top of the logo
										sta raster
										ldx #<IrqBitmap
										ldy #>IrqBitmap
										stx $fffe
										sty $ffff

										asl $d019

IrqScrollerAback:				        lda #$ff
IrqScrollerXback:			         	ldx #$ff
IrqScrollerYback:			        	ldy #$ff

										rti
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "bitmap logo"

IrqBitmap:								sta IrqBitmapAback + 1
										stx IrqBitmapXback + 1
										sty IrqBitmapYback + 1

										lda #216
										sta smoothpos
										lda #26
										sta charset
										lda #$3b
										sta screenmode

										// tune info IRQ

										// these are the final IRQ loop setting to go back to the start.
          								lda #$00
										sta raster
										ldx #<IrqMusic
										ldy #>IrqMusic
										stx $fffe
										sty $ffff

										asl $d019
IrqBitmapAback:					        lda #$ff
IrqBitmapXback:				         	ldx #$ff
IrqBitmapYback:				        	ldy #$ff
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
										sta Screen + 40 * timeLine1 + 8
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 9
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 8
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 9


										// plot minute lo in 2 x 2 

										ldx minute_lo
										lda chartab,x
										sta Screen + 40 * timeLine1 + 10
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 11
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 10
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 11


										// plot second hi in 2 x 2 

										ldx seconds_hi
										lda chartab,x
										sta Screen + 40 * timeLine1 + 14
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 15
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 14
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 15

										// plot second lo in 2 x 2 

										ldx seconds_lo
										lda chartab,x
										sta Screen + 40 * timeLine1 + 16
										clc
										adc #$40
										sta Screen + 40 * timeLine1 + 17
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 16
										clc
										adc #$40
										sta Screen + 40 * timeLine2 + 17
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
										.memblock "2x2 scroller with pause"
scroller_2x2:		  					lda scroll_delay
										beq asc00
										dec scroll_delay
										rts
asc00:    								lda scroll_xposition
										sec
										sbc #$02						// hardcode scroll speed
										and #$07
										sta scroll_xposition
										bcc asc01
										rts
asc01:    								ldx #$00
asc02:				    				lda scroller_line+1,x
										sta scroller_line,x
										lda scroller_line+41,x
										sta scroller_line+40,x
										inx
										cpx #$28
										bne asc02
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


//------------------------------------------------------------------------------------------------------------------------------------------------------------
.align $100 
.memblock "data tables"
scroll_xposition:    					.byte $00
scroll_delay:   						.byte $00
scroller_width:    						.byte $00
scroller_tempChar:    					.byte $00
scroller_pauseLength:   				.byte 100,125,150,175,200,225,250

seconds_lo:                             .byte $00
seconds_hi:                             .byte $00
minute_lo:                              .byte $00
minute_hi:                              .byte $00
chartab:                               	.byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39		// numbers 0 - 9 for clock
//------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 1x1 text, fade on 1 line at a time.
//------------------------------------------------------------------------------------------------------------------------------------------------------------
.align $100
.memblock "tune text"
tune_text:
									//	.text "----------------------------------------"
										.text "                 yellow                 "
										.text "            composed by tlf             "
										.text "            in sid-factory 2            "
										.text "          time : 00:00 / 03:04          "

//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 2x2 scroll text.
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.align $100
										.memblock "scroll text"
scroll_text:
										.text "        padua presents  tlf music player v1 coded by case, logo by premium this charset by mad"
										.text " and of course music by tlf .... this tune called "

										.byte $22 // "
										.text "yellow"
										.byte $22 // "

										.text "    composed in 2022  "

										.byte $00					// end of scroll text
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// import all gfx for the player
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										* = $2000
										.memblock "bitmap logo"
										.import c64 "gfx/tlf.kla"

										* = $4800
										.memblock "1x1 font"
										.import c64 "gfx/1x1-cupid.prg"

										* = $5000
										.memblock "2x2 font"
										.import c64 "gfx/2x2-mad.prg"
//------------------------------------------------------------------------------------------------------------------------------------------------------------
