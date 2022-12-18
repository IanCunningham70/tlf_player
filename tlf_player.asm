//------------------------------------------------------------------------------------------------------------------------------------------------------------
// TLF music player v1.0
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
// memory map
//
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
#import "standardlibrary.asm"			
//------------------------------------------------------------------------------------------------------------------------------------------------------------

.var scroller_zeropage    = $aa
.var scroller_line    = 1024+(40*0)


//------------------------------------------------------------------------------------------------------------------------------------------------------------
// load the default music
//------------------------------------------------------------------------------------------------------------------------------------------------------------
.var music = LoadSid("sid\Soldier_of_Fortune.sid")
.pc = music.location "Music"
.fill music.size, music.getData(i)

//------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------
BasicUpstart2(music_player)
//------------------------------------------------------------------------------------------------------------------------------------------------------------

						* = $c000 "Main Code"
						.memblock "main code"
music_player:

						jsr initialise_music
						jsr init_scroll_text


						sei
						lda #$7f
						sta $dc0d
						sta $dd0d
						lda $dc0d
						lda $dd0d
						lda #$35
						sta $01
						lda #$81
						sta irqenable   
						lda #$01
						sta raster
						lda #$81
						sta irqenable
						lda #$ff
						sta irqflag
						ldx #<main_irq
						ldy #>main_irq
						stx $fffe
						sty $ffff
						cli

case:					jmp case

//------------------------------------------------------------------------------------------------------------------------------------------------------------

main_irq:				pha
						txa
						pha
						tya
						pha


						jsr music.play

						jsr scroller_2x2


						lda #$34
						sta raster
						ldx #<scrollirq
						ldy #>scrollirq
						stx $fffe
						sty $ffff
						inc irqflag

//------------------------------------------------------------------------------------------------------------------------------------------------------------

scrollirq:				
						lda #24
						sta charset
						

						lda #100
						sta raster
						ldx #<main_irq
						ldy #>main_irq
						stx $fffe
						sty $ffff

						inc irqflag
						pla
						tay
						pla
						tax
						pla
						rti
//------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------
initialise_music:		lda #$00		
						tax
						tay
						jsr music.init
						rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------




//------------------------------------------------------------------------------------------------------------------------------------------------------------
// 2x2 scroller
//------------------------------------------------------------------------------------------------------------------------------------------------------------

scroller_2x2:  			lda scroll_delay
						beq asc00
						dec scroll_delay
						rts
asc00:    				lda scroll_xposition
						sec
						sbc #$02						// hardcode scroll speed
						and #$07
						sta scroll_xposition
						bcc asc01
						rts
asc01:    				ldx #$00
asc02:    				lda scroller_line+1,x
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
scroller_nextchar:    	lda scroller_width
						cmp #$01
						beq scroller_plotChar
						lda scroller_tempChar
						clc
						adc #64
						sta scroller_tempChar
						inc scroller_width
						rts
scroller_plotChar:     	ldy #$00
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

scroll_pause:   		ldy #$00
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

init_scroll_text:		ldx #<scroll_text
						ldy #>scroll_text
						stx scroller_zeropage
						sty scroller_zeropage+1
						lda #$01					// reset width
						sta scroller_width
						lda #$20					// reset to space
						sta scroller_tempChar
						rts
//------------------------------------------------------------------------------------------------------------------------------------------------------------
scroll_xposition:    	.byte $00
scroll_delay:   		.byte $00
scroller_width:    		.byte $00
scroller_tempChar:    	.byte $00
scroller_pauseLength:   .byte 100,125,150,175,200,225,250
//------------------------------------------------------------------------------------------------------------------------------------------------------------





//------------------------------------------------------------------------------------------------------------------------------------------------------------
.align $100 
.memblock "data tables"




.align $100
.memblock "tune text"
tune_text:
					//	.text "----------------------------------------"
						.text "           soldier of fortune           "
						.text "            composed by tlf             "
						.text "            in sid-factory 2            "
						.text "                                        "

.align $100
.memblock "scroll text"
scroll_text:
					//	.text "----------------------------------------"
						.text "                  padua                 "
						.text "                 presents               "
						.text "            tlf music player            "
						.text "             coded by case              "
						.text "            logo by premium             "
						.text "        charset by mad or cupid         "
						.text "      and of course music by tlf        "
						.text "           this tune called             "
						.byte $24 // "
						.text "soldier of furtune"
						.byte $24 // "

//------------------------------------------------------------------------------------------------------------------------------------------------------------
