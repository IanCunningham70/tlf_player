//------------------------------------------------------------------------------------------------------------------------------------------------------------
// TLF music player v1.0
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// memory map
//
// music : $0c00 - $1fff
// 2x2 font : $2800
// 
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
#import "standardlibrary.asm"			
//------------------------------------------------------------------------------------------------------------------------------------------------------------

.var scroller_zeropage    = $aa
.var scroller_line    = 1024+(40*0)


//------------------------------------------------------------------------------------------------------------------------------------------------------------
// load music
//------------------------------------------------------------------------------------------------------------------------------------------------------------
.var music = LoadSid("sid\Soldier_of_Fortune.sid")
.pc = music.location "Music"
.fill music.size, music.getData(i)
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
BasicUpstart2(music_player)
//------------------------------------------------------------------------------------------------------------------------------------------------------------
										.memblock "main code"
										* = $4000
music_player:

										// jsr basic_fader

										lda #BLACK
										sta screen
										sta border									


										jsr initialise_music

										jsr init_scroll_text

										ldx #80
								!:		lda #GREY
										sta scroller_line+$d400,x
										lda #32
										sta scroller_line,x
										dex
										bne !-

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
										.memblock "IrqMusic"
IrqMusic:
										sta IrqMusicAback + 1
										stx IrqMusicXback + 1
										sty IrqMusicYback + 1

										lda #200
										sta smoothpos

                                        jsr music.play

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

IrqScroller:
										sta IrqMusicAback + 1
										stx IrqMusicXback + 1
										sty IrqMusicYback + 1

										lda #24
										sta charset

										lda smoothpos
										and #$f0
										ora scroll_xposition
										sta smoothpos

										lda #(2*8)+$32                 // calculate raster line
										cmp raster
										bne *-3
										ldx #$0a
										dex
										bne *-1

										lda #200
										sta smoothpos
										lda #26
										sta charset


          								lda #$00
										sta raster
										ldx #<IrqMusic
										ldy #>IrqMusic
										stx $fffe
										sty $ffff

										asl $d019

IrqScrollerAback:				        lda #$ff
IrqScrollerXback:			         	ldx #$ff
IrqScrollerYback:			        	ldy #$ff

										rti

//------------------------------------------------------------------------------------------------------------------------------------------------------------




//------------------------------------------------------------------------------------------------------------------------------------------------------------
initialise_music:						lda #$00		
										tax
										tay
										jsr music.init
										rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 2x2 scroller
//------------------------------------------------------------------------------------------------------------------------------------------------------------

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


//------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 1x1 text, fade on 1 line at a time.
//------------------------------------------------------------------------------------------------------------------------------------------------------------
.align $100
.memblock "tune text"
tune_text:
									//	.text "----------------------------------------"
										.text "           soldier of fortune           "
										.text "            composed by tlf             "
										.text "            in sid-factory 2            "
										.text "                                        "

//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 2x2 scroll text.
//------------------------------------------------------------------------------------------------------------------------------------------------------------
.align $100
.memblock "scroll text"
scroll_text:
									//	.text "01234567890123456789"
										.text "        padua presents  tlf music player v1 coded by case, logo by premium this charset by mad"
										.text " and of course music by tlf .... this tune called "

										.byte $22 // "
										.text "soldier of fortune"
										.byte $22 // "

										.text "    composed in december 2022 using sid-factory ii "

										.byte $00					// end of scroll text
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
										* = $2000
										.memblock "2x2 font"
										.import c64 "gfx/2x2-mad.prg"
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
										* = $2800
										.memblock "1x1 font"
										.import c64 "gfx/1x1-cupid.prg"
//------------------------------------------------------------------------------------------------------------------------------------------------------------
