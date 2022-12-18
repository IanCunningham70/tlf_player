                        //------------------------------------------------------------------------------
						// CINQUE part 2 
						// 
						// idea and gfx : cupid
						// code : case
						// music : c0zmo
						// help : dano, anonym, doomed, lubber
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						// memory map
						//
						// $0c00 - $2000 - music
						// $c000 - $cfff - code (can be moved if more music space is required)
						//
						// $3000 - boxpattern - also contains additional 4 chatracter screens
						//					  - each shifted 1 character to the left for the
						//                    - screen scrolling effect.
						// $4400 - cross
						// $4c00 - stars
						// $5400 - balls
						// $5c00 - x-factor
						// $6400 - q-bert
						// $6c00 - diamonds
						// $7400 - cubes
						// $7c00 - believe
						// $8400 - dare to add colour
						// $8c00 - cut fold glue
						// $9400 - think outside of the box
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						#if RELEASE
						{
							.import source "../../demo-builder/link_macros_kickass.inc"
							.import source "../../demo-builder/loader_kickass.inc"
						}
						#endif
                        //------------------------------------------------------------------------------
						#import "../../lib/standardlibrary.asm"			
                        //------------------------------------------------------------------------------
						#if !RELEASE
							.var music = LoadSid ("../../music/C0Z-CINQUE1.sid" )
							*=music.location "Music"
							.fill music.size, music.getData(i)
						#endif
                        //------------------------------------------------------------------------------
						#if !RELEASE
							BasicUpstart2(part_entrypoint)
						#endif
                        //------------------------------------------------------------------------------

						* = $c000 "Main Code"			// main code starts below

part_entrypoint:
						#if !RELEASE
							lda #$00		
							tax
							tay
							jsr music.init
						#endif

						lda #BLUE
						sta fade_border+1
						sta fade_screen+1

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

						// each screen is contained within its own single jsr, no more self modified code.

						jsr cross							// fade on cross pattern

						#if RELEASE
							:wait_frame_count($06ce) 		//wait for drums
						#endif
						
						jsr stars_prep						// plot stars
						jsr balls							// fade in the balls screen
						jsr xFactor							// screen 15 xfactor
						jsr boxPattern						// screen 16 boxpattern

                        //------------------------------------------------------------------------------
						// following are next for the scrolling treatment.
                        //------------------------------------------------------------------------------

						jsr qBert							// screen 17 qbert
						jsr diamonds						// screen 18 diamonds

                        //------------------------------------------------------------------------------

						jsr boxFld							// fld screen ON, wait and then FLD off
						jsr screens2

						#if RELEASE
							link_player_irq_(1)
							jmp (part_done) 
						#else
							!:inc $d020
							jmp !-
						#endif
                        //------------------------------------------------------------------------------
main_irq:				pha
						txa
						pha
						tya
						pha

						lda #200
						sta smoothpos

						lda screen_toggle
						sta screenmode

						lda #%00010100
						sta charset

						bit $c45e					// timing to push 'wolf-dots' off the screen
						bit $c45e
						bit $c45e
						bit $c45e
fade_border:			lda #$00					// placeholder code for colour fades when needed
						sta border
fade_screen:			lda #$00
						sta screen

						#if !RELEASE
							jsr music.play
						#else
							jsr link_music_play
						#endif

						inc irqflag
						pla
						tay
						pla
						tax
						pla
						rti
                        //------------------------------------------------------------------------------
						// cross
                        //------------------------------------------------------------------------------
cross:					ldx #$00				// choose screen to display
						stx screen_number
						jsr screen_text
						lda #BLUE				// color screen blue
						jsr recolor
						lda #$1b
						sta screen_toggle
						jsr crossCycle
						jsr standardPause
						rts
crossCycle:				ldy crossColorsNum
						cpy #8
						beq crossCycleFaded
						lda crossColorsIn,y
						ldx #40
					!:	sta $d800+(40 * 01) + 8,x
						sta $d800+(40 * 02) + 8,x						
						sta $d800+(40 * 03) + 8,x						
						sta $d800+(40 * 04) + 8,x						
						sta $d800+(40 * 05) + 8,x						
						sta $d800+(40 * 06) + 8,x						
						sta $d800+(40 * 07) + 8,x						
						sta $d800+(40 * 08) + 8,x						
						sta $d800+(40 * 09) + 8,x						
						sta $d800+(40 * 10) + 8,x						
						sta $d800+(40 * 11) + 8,x						
						sta $d800+(40 * 12) + 8,x						
						sta $d800+(40 * 13) + 8,x						
						sta $d800+(40 * 14) + 8,x						
						sta $d800+(40 * 15) + 8,x						
						sta $d800+(40 * 16) + 8,x						
						sta $d800+(40 * 17) + 8,x						
						sta $d800+(40 * 18) + 8,x						
						sta $d800+(40 * 19) + 8,x						
						sta $d800+(40 * 20) + 8,x						
						sta $d800+(40 * 21) + 8,x						
						sta $d800+(40 * 22) + 8,x						
						sta $d800+(40 * 23) + 8,x						
						dex
						bne !-
						inc crossColorsNum
						jsr pauseQuick
						jmp crossCycle
crossCycleFaded:		ldx #$0	
						lda cross_colors+(40*01)+8,x
						sta $d800+(40 * 01) + 8,x
						lda cross_colors+(40*02)+8,x
						sta $d800+(40 * 02) + 8,x						
						lda cross_colors+(40*03)+8,x
						sta $d800+(40 * 03) + 8,x						
						lda cross_colors+(40*04)+8,x
						sta $d800+(40 * 04) + 8,x						
						lda cross_colors+(40*05)+8,x
						sta $d800+(40 * 05) + 8,x						
						lda cross_colors+(40*06)+8,x
						sta $d800+(40 * 06) + 8,x						
						lda cross_colors+(40*07)+8,x
						sta $d800+(40 * 07) + 8,x						
						lda cross_colors+(40*08)+8,x
						sta $d800+(40 * 08) + 8,x					
						lda cross_colors+(40*09)+8,x
						sta $d800+(40 * 09) + 8,x						
						lda cross_colors+(40*10)+8,x
						sta $d800+(40 * 10) + 8,x						
						lda cross_colors+(40*11)+8,x
						sta $d800+(40 * 11) + 8,x						
						lda cross_colors+(40*12)+8,x
						sta $d800+(40 * 12) + 8,x						
						lda cross_colors+(40*13)+8,x
						sta $d800+(40 * 13) + 8,x						
						lda cross_colors+(40*14)+8,x
						sta $d800+(40 * 14) + 8,x						
						lda cross_colors+(40*15)+8,x
						sta $d800+(40 * 15) + 8,x						
						lda cross_colors+(40*16)+8,x
						sta $d800+(40 * 16) + 8,x						
						lda cross_colors+(40*17)+8,x
						sta $d800+(40 * 17) + 8,x						
						lda cross_colors+(40*18)+8,x
						sta $d800+(40 * 18) + 8,x						
						lda cross_colors+(40*19)+8,x
						sta $d800+(40 * 19) + 8,x						
						lda cross_colors+(40*20)+8,x
						sta $d800+(40 * 20) + 8,x						
						lda cross_colors+(40*21)+8,x
						sta $d800+(40 * 21) + 8,x						
						lda cross_colors+(40*22)+8,x
						sta $d800+(40 * 22) + 8,x						
						lda cross_colors+(40*23)+8,x
						sta $d800+(40 * 23) + 8,x						
						inx
						cpx #32
						beq crossCycleExit
						jmp crossCycleFaded+2 
crossCycleExit:			rts
                        //------------------------------------------------------------------------------
pauseQuick:				ldy #128			// this pause is half the main pause length
				!:		ldx #128
					!:	dex
						bne !-
						dey
						bne !--
						rts
                        //------------------------------------------------------------------------------
						// standard pause = 3 calls of normal pause
                        //------------------------------------------------------------------------------
standardPause:			jsr pauseLoop
						jsr pauseLoop
						jsr pauseLoop
						rts
                        //------------------------------------------------------------------------------
stars_prep:				lda #$0b							
						sta screen_toggle
						jsr spaced							// clear screen
						lda #$00
						sta f2dg_number						
						jsr f2darkgrey						// fade from blue to dark grey

						ldx #01				// select screen to display
						stx screen_number
						jsr screen_text		// copy screen from memory to screen, including colour data.
						lda #DARK_GRAY		// define background colour
						jsr recolor			// colour all characters in the above colour.
						lda #$00			// reset stars counter to zero
						sta star_number
						lda #$1b
						sta screen_toggle
stars:					ldx star_number
						cpx #18
						bne show_star
						jsr standardPause
						jsr spaced							// clear the screen characters
						rts
show_star:				ldx star_number
						lda stars_sequence,x
						tax
						lda star_mem_color_lo,x
						ldy star_mem_color_hi,x
						sta star_load+1
						sty star_load+2

						lda star_load+1
						clc
						adc #$00
						sta star_save+1
						lda star_load+2
						adc #$d8->stars_colors													// calculate screen color hi byte
						sta star_save+2
				!:		ldx #$00
star_load:				lda $3c00,x
star_save:				sta $d800,x 
						inx
						cpx #6
						bne star_load
						lda star_load+1													// set pointer to next line
						clc
						adc #40
						sta star_load+1
						lda star_load+2
						adc #$00
						sta star_load+2
						lda star_save+1
						clc
						adc #40
						sta star_save+1
						lda star_save+2
						adc #$00
						sta star_save+2
						inc star_lines
						lda star_lines
						cmp #$06
						bne !-
						jsr pauseLoop
						inc star_number
						lda #$00
						sta star_lines
						jmp stars
                        //------------------------------------------------------------------------------
						// balls
                        //------------------------------------------------------------------------------
balls:					lda #$0b
						sta screen_toggle
						lda #$00
						sta f2black_number
						jsr f2black							// fade from dark grey to black
						lda #BLACK
						jsr recolor						
						lda #$1b
						sta screen_toggle

						ldx #$02							// choose screen to display
						stx screen_number
						jsr screen_text
						lda #$00
						sta ballsColorsNum
						jsr ballsCycle
						jsr standardPause
						rts
ballsCycle:				ldy ballsColorsNum
						cpy #8
						beq ballsCycleFaded
						lda ballsColorsIn,y
						ldx #40
					!:	sta $d800+(40 * 00),x
						sta $d800+(40 * 01),x
						sta $d800+(40 * 02),x						
						sta $d800+(40 * 03),x						
						sta $d800+(40 * 04),x						
						sta $d800+(40 * 05),x						
						sta $d800+(40 * 06),x						
						sta $d800+(40 * 07),x						
						sta $d800+(40 * 08),x						
						sta $d800+(40 * 09),x						
						sta $d800+(40 * 10),x						
						sta $d800+(40 * 11),x						
						sta $d800+(40 * 12),x						
						sta $d800+(40 * 13),x						
						sta $d800+(40 * 14),x						
						sta $d800+(40 * 15),x						
						sta $d800+(40 * 16),x						
						sta $d800+(40 * 17),x						
						sta $d800+(40 * 18),x						
						sta $d800+(40 * 19),x						
						sta $d800+(40 * 20),x						
						sta $d800+(40 * 21),x						
						sta $d800+(40 * 22),x						
						sta $d800+(40 * 23),x						
						sta $d800+(40 * 24),x						
						dex
						bne !-
						jsr pauseQuick
						inc ballsColorsNum
						jmp ballsCycle
ballsCycleFaded:		ldx #$00
						lda balls_colors+(40*00),x
						sta $d800+(40 * 00),x
						lda balls_colors+(40*01),x
						sta $d800+(40 * 01),x
						lda balls_colors+(40*02),x
						sta $d800+(40 * 02),x						
						lda balls_colors+(40*03),x
						sta $d800+(40 * 03),x						
						lda balls_colors+(40*04),x
						sta $d800+(40 * 04),x						
						lda balls_colors+(40*05),x
						sta $d800+(40 * 05),x						
						lda balls_colors+(40*06),x
						sta $d800+(40 * 06),x						
						lda balls_colors+(40*07),x
						sta $d800+(40 * 07),x						
						lda balls_colors+(40*08),x
						sta $d800+(40 * 08),x					
						lda balls_colors+(40*09),x
						sta $d800+(40 * 09),x						
						lda balls_colors+(40*10),x
						sta $d800+(40 * 10),x						
						lda balls_colors+(40*11),x
						sta $d800+(40 * 11),x						
						lda balls_colors+(40*12),x
						sta $d800+(40 * 12),x						
						lda balls_colors+(40*13),x
						sta $d800+(40 * 13),x						
						lda balls_colors+(40*14),x
						sta $d800+(40 * 14),x						
						lda balls_colors+(40*15),x
						sta $d800+(40 * 15),x						
						lda balls_colors+(40*16),x
						sta $d800+(40 * 16),x						
						lda balls_colors+(40*17),x
						sta $d800+(40 * 17),x						
						lda balls_colors+(40*18),x
						sta $d800+(40 * 18),x						
						lda balls_colors+(40*19),x
						sta $d800+(40 * 19),x						
						lda balls_colors+(40*20),x
						sta $d800+(40 * 20),x						
						lda balls_colors+(40*21),x
						sta $d800+(40 * 21),x						
						lda balls_colors+(40*22),x
						sta $d800+(40 * 22),x						
						lda balls_colors+(40*23),x
						sta $d800+(40 * 23),x						
						lda balls_colors+(40*24),x
						sta $d800+(40 * 24),x						
						inx
						cpx #40
						beq ballsCycleExit
						jmp ballsCycleFaded+2
ballsCycleExit:			rts
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						// x-factor
                        //------------------------------------------------------------------------------
xFactor:				lda #$0b
						sta screen_toggle
						lda #$00
						sta black2darkgrey_number
						jsr black2darkgrey					// fade to dark grey
						lda #03
						sta screen_number
						jsr screen_text
						lda #DARK_GREY
						jsr recolor
						lda #$1b
						sta screen_toggle

						// set default start positions
						ldx #19
						ldy #20
						stx xposition
						sty yposition

xloop:					ldx xposition
						ldy yposition
						lda x_colors + (40 * 3),x
						sta $d800 + (40 * 3),x
						lda x_colors + (40 * 4),x
						sta $d800 + (40 * 4),x
						lda x_colors + (40 * 5),x
						sta $d800 + (40 * 5),x
						lda x_colors + (40 * 6),x
						sta $d800 + (40 * 6),x
						lda x_colors + (40 * 7),x
						sta $d800 + (40 * 7),x
						lda x_colors + (40 * 8),x
						sta $d800 + (40 * 8),x
						lda x_colors + (40 * 9),x
						sta $d800 + (40 * 9),x
						lda x_colors + (40 * 10),x
						sta $d800 + (40 * 10),x
						lda x_colors + (40 * 11),x
						sta $d800 + (40 * 11),x
						lda x_colors + (40 * 12),x
						sta $d800 + (40 * 12),x
						lda x_colors + (40 * 13),x
						sta $d800 + (40 * 13),x
						lda x_colors + (40 * 14),x
						sta $d800 + (40 * 14),x
						lda x_colors + (40 * 15),x
						sta $d800 + (40 * 15),x
						lda x_colors + (40 * 16),x
						sta $d800 + (40 * 16),x
						lda x_colors + (40 * 17),x
						sta $d800 + (40 * 17),x
						lda x_colors + (40 * 18),x
						sta $d800 + (40 * 18),x
						lda x_colors + (40 * 19),x
						sta $d800 + (40 * 19),x
						lda x_colors + (40 * 20),x
						sta $d800 + (40 * 20),x
						
						lda x_colors + (40 * 3),y
						sta $d800 + (40 * 3),y
						lda x_colors + (40 * 4),y
						sta $d800 + (40 * 4),y
						lda x_colors + (40 * 5),y
						sta $d800 + (40 * 5),y
						lda x_colors + (40 * 6),y
						sta $d800 + (40 * 6),y
						lda x_colors + (40 * 7),y
						sta $d800 + (40 * 7),y
						lda x_colors + (40 * 8),y
						sta $d800 + (40 * 8),y
						lda x_colors + (40 * 9),y
						sta $d800 + (40 * 9),y
						lda x_colors + (40 * 10),y
						sta $d800 + (40 * 10),y
						lda x_colors + (40 * 11),y
						sta $d800 + (40 * 11),y
						lda x_colors + (40 * 12),y
						sta $d800 + (40 * 12),y
						lda x_colors + (40 * 13),y
						sta $d800 + (40 * 13),y
						lda x_colors + (40 * 14),y
						sta $d800 + (40 * 14),y
						lda x_colors + (40 * 15),y
						sta $d800 + (40 * 15),y
						lda x_colors + (40 * 16),y
						sta $d800 + (40 * 16),y
						lda x_colors + (40 * 17),y
						sta $d800 + (40 * 17),y
						lda x_colors + (40 * 18),y
						sta $d800 + (40 * 18),y
						lda x_colors + (40 * 19),y
						sta $d800 + (40 * 19),y
						lda x_colors + (40 * 20),y
						sta $d800 + (40 * 20),y

						ldx #64
				!:		ldy #64
					!:	dey
						bne !-
						dex
						bne !--

						dec xposition
						inc yposition
						
						ldx xposition
						cpx #4
						beq xdone
						jmp xloop
xdone:					jsr standardPause
						rts
                        //------------------------------------------------------------------------------						
xposition:				.byte 19
yposition:				.byte 20
						.byte $ca, $5e
                        //------------------------------------------------------------------------------						
						// fade from black to grey
                        //------------------------------------------------------------------------------
f2darkgrey:				ldy f2dg_number
						cpy #$08					// maximum number in colour table
						bne !+
						lda #DARK_GRAY
						sta fade_border+1
						sta fade_screen+1			
						rts
			!:			lda f2dg_table,y
						sta fade_border+1
						sta fade_screen+1
						jsr pauseQuick
						inc f2dg_number
						jmp f2darkgrey
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------						
						// fade from lightgrey to black
                        //------------------------------------------------------------------------------
f2black:				ldy f2black_number
						cpy #$08					// maximum number in colour table
						bne !+
						lda #BLACK
						sta fade_border+1
						sta fade_screen+1			
						rts
			!:			lda f2black_table,y
						sta fade_border+1
						sta fade_screen+1
						jsr pauseQuick
						inc f2black_number
						jmp f2black
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------						
						// fade from white to lightgrey
                        //------------------------------------------------------------------------------
white2lightgrey:		ldy white2lightgrey_number
						cpy #$08					// maximum number in colour table
						bne !+
						lda #LIGHT_GRAY
						sta fade_border+1
						sta fade_screen+1			
						rts
			!:			lda white2lightgrey_table,y
						sta fade_border+1
						sta fade_screen+1
						jsr pauseQuick
						inc white2lightgrey_number
						jmp white2lightgrey
                        //------------------------------------------------------------------------------
white2lightgrey_number: .byte $00
white2lightgrey_table:  .byte $01,$0d,$0f,$0f,$0f,$0f,$0f,$0f	//  white to light grey
                        //------------------------------------------------------------------------------


                        //------------------------------------------------------------------------------						
						// fade from lightgrey to black
                        //------------------------------------------------------------------------------
black2darkgrey:			ldy black2darkgrey_number
						cpy #$08					// maximum number in colour table
						bne !+
						lda #DARK_GRAY
						sta fade_border+1
						sta fade_screen+1			
						rts
			!:			lda black2darkgrey_table,y
						sta fade_border+1
						sta fade_screen+1
						jsr pauseQuick
						inc black2darkgrey_number
						jmp black2darkgrey
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						// box-pattern, swipe on and scroll
                        //------------------------------------------------------------------------------
boxPattern:				
						lda #$0b
						sta screen_toggle
						lda #$00
						sta darkgrey2white_number
						jsr darkgrey2white					// fade to white
						jsr spaced
						lda #$1b
						sta screen_toggle

						ldx #$00
						stx column_number
						stx charload+1
						ldy #>boxpattern_chars
						sty charload+2
						sty charloadhi+1
                        ldy #>boxpattern_colors
						sty colorload+2
						sty colorloadhi+1
						jsr plotScreen
						lda #%11100100
						sta nextScreen
						lda #$01
						sta screenPosition 

						sei
						lda #$22
						sta raster
						lda #$c1
						sta smoothpos
						ldx #<boxPatternIrq
						ldy #>boxPatternIrq
						stx $fffe
						sty $ffff
						cli

// Screen 16 displayed scrolling						
						jsr standardPause
						jsr standardPause
						jsr standardPause

						sei 				// switch back to main irq
						lda #$01
						sta raster
						lda #$0b
						sta screen_toggle
						lda #$22
						sta raster
						ldx #<main_irq
						ldy #>main_irq
						stx $fffe
						sty $ffff
						cli
						rts
                        //------------------------------------------------------------------------------
boxPatternIrq:			pha
						txa
						pha
						tya
						pha

						lda nextScreen
						sta charset

						lda smoothpos
						and #$f0
						ora scrollXpos
						sta smoothpos

						#if !RELEASE
							jsr music.play
						#else
							jsr link_music_play
						#endif

						// select half way point on screen to start colour scrolling

						ldx #<boxPatternIrq2
						ldy #>boxPatternIrq2
						stx $fffe
						sty $ffff


						lda #$92
						sta raster
						lda screenmode
						sta screenmode

						inc irqflag
						pla
						tay
						pla
						tax
						pla
						rti

boxPatternIrq2:			pha
						txa
						pha
						tya
						pha

						jsr scrollscreenTOP

						ldx #<boxPatternIrq
						ldy #>boxPatternIrq
						stx $fffe
						sty $ffff

						lda #$22
						sta raster
						lda screenmode
						sta screenmode

						inc irqflag
						pla
						tay
						pla
						tax
						pla
						rti
                        //------------------------------------------------------------------------------
nextScreen:				.byte %11100100
screenPosition:			.byte $00					// screen counter 0 - 3
screenMemory:			.byte %11000100    			// screen at $3000
						.byte %11010100				// screen at $3400
						.byte %11100100				// screen at $3800
						.byte %11110100				// screen at $3c00
                        //------------------------------------------------------------------------------
scrollscreenTOP:		lda scrollXpos
						sec
						sbc #$01					// scroll speed
						and #$07
						sta scrollXpos
						bcc scrollerMoveTop
						rts
						// done 7 pixels, now move the screen pointer to the next screen
						// if done 3 times, then go back to screen position 1
scrollerMoveTop:    	ldx screenPosition
						cpx #04
						bne setNextScreen
						ldx #$00
						stx screenPosition
setNextScreen:			lda screenMemory,x
						sta nextScreen
						inc screenPosition			

						// store current column 0 colours into a buffer

						lda $d800+(40*0)
						sta colorBuffer
						lda $d800+(40*1)
						sta colorBuffer+1
						lda $d800+(40*2)
						sta colorBuffer+2
						lda $d800+(40*3)
						sta colorBuffer+3
						lda $d800+(40*4)
						sta colorBuffer+4
						lda $d800+(40*5)
						sta colorBuffer+5
						lda $d800+(40*6)
						sta colorBuffer+6
						lda $d800+(40*7)
						sta colorBuffer+7
						lda $d800+(40*8)
						sta colorBuffer+8
						lda $d800+(40*9)
						sta colorBuffer+9
						lda $d800+(40*10)
						sta colorBuffer+10
						lda $d800+(40*11)
						sta colorBuffer+11
						lda $d800+(40*12)
						sta colorBuffer+12
						lda $d800+(40*13)
						sta colorBuffer+13
						lda $d800+(40*14)
						sta colorBuffer+14
						lda $d800+(40*15)
						sta colorBuffer+15
						lda $d800+(40*16)
						sta colorBuffer+16
						lda $d800+(40*17)
						sta colorBuffer+17
						lda $d800+(40*18)
						sta colorBuffer+18
						lda $d800+(40*19)
						sta colorBuffer+19
						lda $d800+(40*20)
						sta colorBuffer+20
						lda $d800+(40*21)
						sta colorBuffer+21
						lda $d800+(40*22)
						sta colorBuffer+22
						lda $d800+(40*23)
						sta colorBuffer+23
						lda $d800+(40*24)
						sta colorBuffer+24

						// move colours 1 character left
						
loady:					ldy #25

moveTopLoop:			ldx #$00

		loadcols:		lda $d800+(40*0)+1,x
		storecols0:		sta $d800+(40*0)+(8*0),x
		storecols1:		sta $d800+(40*0)+(8*1),x
		storecols2:		sta $d800+(40*0)+(8*2),x
		storecols3:		sta $d800+(40*0)+(8*3),x
		storecols4:		sta $d800+(40*0)+(8*4),x

						inx
						cpx #8
						bne loadcols

						clc
						lda loadcols+1
						adc #40
						sta loadcols+1
						lda loadcols+2
						adc #0
						sta loadcols+2

						clc
						lda storecols0+1
						adc #40
						sta storecols0+1
						lda storecols0+2
						adc #0
						sta storecols0+2

						clc
						lda storecols1+1
						adc #40
						sta storecols1+1
						lda storecols1+2
						adc #0
						sta storecols1+2

						clc
						lda storecols2+1
						adc #40
						sta storecols2+1
						lda storecols2+2
						adc #0
						sta storecols2+2

						clc
						lda storecols3+1
						adc #40
						sta storecols3+1
						lda storecols3+2
						adc #0
						sta storecols3+2

						clc
						lda storecols4+1
						adc #40
						sta storecols4+1
						lda storecols4+2
						adc #0
						sta storecols4+2

						ldx #0			
						dey
						beq !+
						jmp moveTopLoop
						
		!:				lda #<$d800+(40*0)+1
						sta loadcols+1
						lda #>$d800+(40*0)+1
						sta loadcols+2
						lda #<$d800+(40*0)+(8*0)
						sta storecols0+1
						lda #>$d800+(40*0)+(8*0)
						sta storecols0+2
						lda #<$d800+(40*0)+(8*1)
						sta storecols1+1
						lda #>$d800+(40*0)+(8*1)
						sta storecols1+2
						lda #<$d800+(40*0)+(8*2)
						sta storecols2+1
						lda #>$d800+(40*0)+(8*2)
						sta storecols2+2
						lda #<$d800+(40*0)+(8*3)
						sta storecols3+1
						lda #>$d800+(40*0)+(8*3)
						sta storecols3+2
						lda #<$d800+(40*0)+(8*4)
						sta storecols4+1
						lda #>$d800+(40*0)+(8*4)
						sta storecols4+2

// Define macro
.macro SetColors(colBuffer,storeAddr) {
		lda colBuffer
		sta storeAddr+(8*0)
		sta storeAddr+(8*1)
		sta storeAddr+(8*2)
		sta storeAddr+(8*3)
		sta storeAddr+(8*4)
}


movedoneTOP:

						// re-draw colours from buffer to column 39

						SetColors(colorBuffer+0,$d800+(40*0)+7+(8*0))
						SetColors(colorBuffer+1,$d800+(40*1)+7+(8*0))
						SetColors(colorBuffer+2,$d800+(40*2)+7+(8*0))
						SetColors(colorBuffer+3,$d800+(40*3)+7+(8*0))
						SetColors(colorBuffer+4,$d800+(40*4)+7+(8*0))
						SetColors(colorBuffer+5,$d800+(40*5)+7+(8*0))
						SetColors(colorBuffer+6,$d800+(40*6)+7+(8*0))
						SetColors(colorBuffer+7,$d800+(40*7)+7+(8*0))
						SetColors(colorBuffer+8,$d800+(40*8)+7+(8*0))
						SetColors(colorBuffer+9,$d800+(40*9)+7+(8*0))
						SetColors(colorBuffer+10,$d800+(40*10)+7+(8*0))
						SetColors(colorBuffer+11,$d800+(40*11)+7+(8*0))
						SetColors(colorBuffer+12,$d800+(40*12)+7+(8*0))
						SetColors(colorBuffer+13,$d800+(40*13)+7+(8*0))
						SetColors(colorBuffer+14,$d800+(40*14)+7+(8*0))
						SetColors(colorBuffer+15,$d800+(40*15)+7+(8*0))
						SetColors(colorBuffer+16,$d800+(40*16)+7+(8*0))
						SetColors(colorBuffer+17,$d800+(40*17)+7+(8*0))
						SetColors(colorBuffer+18,$d800+(40*18)+7+(8*0))
						SetColors(colorBuffer+19,$d800+(40*19)+7+(8*0))
						SetColors(colorBuffer+20,$d800+(40*20)+7+(8*0))
						SetColors(colorBuffer+21,$d800+(40*21)+7+(8*0))
						SetColors(colorBuffer+22,$d800+(40*22)+7+(8*0))
						SetColors(colorBuffer+23,$d800+(40*23)+7+(8*0))
						SetColors(colorBuffer+24,$d800+(40*24)+7+(8*0))
						rts
                        //------------------------------------------------------------------------------


                        //------------------------------------------------------------------------------
						// q-bert - swipe on and scroll!!
                        //------------------------------------------------------------------------------
qBert:
						lda #$0b
						sta screen_toggle
						lda #$00
						sta white2lightgrey_number
						jsr white2lightgrey					// fade to light grey
						lda #$1b
						sta screen_toggle

                        //------------------------------------------------------------------------------
						// colour pattern is from column 0 to 9 across and down to line 17.
						//  
						// not sure where to start with this one, maybe split screen into 3 sections
						// and scroller the characters in each on, use ECM form the colors ? but this
						// would not work for the next screen.  Ideally it would be good to have a
						// single routine that will do both screens as they are basically the same,
						//
						// cupid has said to scroll the screen up
                        //------------------------------------------------------------------------------


						ldx #$00
						stx column_number
						stx line_number
						stx charload+1
						ldy #>qbert_chars
						sty charload+2
						sty charloadhi+1
                        ldy #>qbert_colors
						sty colorload+2
						sty colorloadhi+1
						jsr plotScreen

						jsr standardPause
						rts
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						// diamonds - swipe on and scroll!!
                        //------------------------------------------------------------------------------
diamonds:				
                        //------------------------------------------------------------------------------
						// colour pattern is from column 0 to 9 across and down to line 17.
                        //------------------------------------------------------------------------------
						
						ldx #$00
						stx column_number
						stx line_number
						stx charload+1
						ldy #>diamonds_chars
						sty charload+2
						sty charloadhi+1
                        ldy #>diamonds_cols
						sty colorload+2
						sty colorloadhi+1
						jsr plotScreen

						jsr standardPause
						rts
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						// bring in the boxFld images using reverse FLD
                        //------------------------------------------------------------------------------
boxFld:					
						lda #$0b
						sta screen_toggle
						lda #$00
						sta f2black_number
						jsr f2black							// fade to black
						jsr spaced

						lda #07							// select screen to show
						sta screen_number
						jsr screen_text
						jsr screen_color
						lda #$ff
						sta $3fff
						lda #GREY
						sta screen

						lda #$1b
						sta screen_toggle

						// change to gort irq for FLD fx.
						sei
						ldx #<gortExit
						ldy #>gortExit
						stx $fffe
						sty $ffff
						cli

					!:	lda gort_lines+1
						cmp #5
						bne !-

                        //------------------------------------------------------------------------------
						// need to work out why the pause does not work ?, maybe switch back to the 
						// 'main_irq' ?
                        //------------------------------------------------------------------------------
						
						ldx #255
				!:		ldy #128
					!:	dey
						bne !-
						dex
						bne !--

						sei
						ldx #<finalIrq
						ldy #>finalIrq
						stx $fffe
						sty $ffff
						cli

					!:	lda fld_lines+1
						cmp #$ce
						bne !-

						// switch back to main irq

						lda #$0b
						sta screen_toggle

						sei
						lda #$01
						sta raster
						ldx #<main_irq
						ldy #>main_irq
						stx $fffe
						sty $ffff
						cli
						lda #$00
						sta $3fff
						lda #BLACK
						sta fade_screen+1
						rts
                        //------------------------------------------------------------------------------
						// specific irq for showing the 'gort' image.
                        //------------------------------------------------------------------------------
gortExit:				pha
						txa
						pha
						tya
						pha

						lda #$2f
						sta raster
						lda #BLACK
						sta border
						lda #LIGHT_GRAY
						sta screen

						#if !RELEASE
							jsr music.play
						#else
							jsr link_music_play
						#endif

						lda #<gortExit2
						ldx #>gortExit2
						sta $fffe
						stx $ffff
						jmp gortExitIRQ
gortExit2:				pha
						txa
						pha
						tya
						pha
						lda #$01
						sta raster
						lda #<gortExit
						ldx #>gortExit
						sta $fffe
						stx $ffff
						ldx #$00
												// -- Loop take exactly 63 cycles
gort_loop:				inx						// increase so y scroll is 1 ahead of y raster
						txa						//
						and #$07
						ora #$10				// 24 rows, so no jitter at the bottom.
						sta screenmode			// 12
						jsr screens2_done
						jsr screens2_done
						jsr screens2_done		// 48
						nop
						nop
						nop
						nop
						nop				    	// 58
gort_lines:				cpx #200				// if number of rasterlines of gort is reached, quit the loop
						bne gort_loop			// 63
						lda gort_lines+1		// Check if we still need to scroll further
						cmp #10			    	// screen is no longer than 200 lines.
						bcc gortExitIRQ
						clc
						sbc gort_speed: #1	// Add scroll speed to current number of lines
						sta gort_lines+1
						ldx gort_speed_gate: #8 // Speed up gradually 
						dex
						bne !+
						ldx #8
						inc gort_speed
				!:		stx gort_speed_gate

						
gortExitIRQ:		 	inc irqflag
						pla
						tay
						pla
						tax
						pla
						rti
                        //------------------------------------------------------------------------------
finalIrq:				pha
						txa
						pha
						tya
						pha

						lda #$2f
						sta raster

						#if !RELEASE
							jsr music.play
						#else
							jsr link_music_play
						#endif

						lda #<finalIrq2
						ldx #>finalIrq2
						sta $fffe
						stx $ffff
						jmp endfinalirq

finalIrq2:				pha
						txa
						pha
						tya
						pha
						lda #$01
						sta raster
						lda #<finalIrq
						ldx #>finalIrq
						sta $fffe
						stx $ffff
						ldx #$00
											// -- Loop take exactly 63 cycles
fld_loop:				inx					// increase so y scroll is 1 ahead of y raster
						txa					//
						and #$07
						ora #$10			// 24 rows, so no jitter at the bottom.
						sta screenmode		// 12
						jsr screens2_done
						jsr screens2_done
						jsr screens2_done	// 48
						nop
						nop
						nop
						nop
						nop				    // 58
fld_lines:				cpx #10				// if number of rasterlines of fld is reached, quit the loop
						bne fld_loop		// 63
						lda fld_lines+1		// Check if we still need to scroll further
						cmp #200			// screen is no longer than 200 lines.
						bcs endfinalirq
						clc
						adc fld_speed: #1	// Add scroll speed to current number of lines
						sta fld_lines+1
						ldx fld_speed_gate: #8 // Speed up gradually 
						dex
						bne !+
						ldx #8
						inc fld_speed
					!:	stx fld_speed_gate						
endfinalirq:			inc irqflag
						pla
						tay
						pla
						tax
						pla
						rti
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						// this section will do the final 4 screens, adjust the pause using the 
                        //------------------------------------------------------------------------------
screens2:				lda #$0b
						sta screen_toggle
						jsr spaced
						lda #$1b
						sta screen_toggle
						lda #7								// do the final 4 screens
						sta screen_number

			!:			lda screen_number
						cmp #11
						beq screens2_done
						inc screen_number
						jsr screen_text
						jsr screen_color
						jsr standardPause
						jmp !-
screens2_done:			rts
                        //------------------------------------------------------------------------------						
screen_text:			ldx screen_number
						ldy petscii_hi_table,x
						sty plot_load+2
						ldy #$04
						sty plot_save+2
						lda #$00
						sta plot_save+1
						sta plot_load+1
						jsr plot_screen
						rts
                        //------------------------------------------------------------------------------						
screen_color:			ldx screen_number
						ldy color_hi_table,x
						sty plot_load+2
						ldy #$d8
						sty plot_save+2
						lda #$00
						sta plot_save+1
						sta plot_load+1
						jsr plot_screen
						rts
                        //------------------------------------------------------------------------------
						// pre-define load and save pointers, then call to plot a whole screen and its					
						// colour data.
                        //------------------------------------------------------------------------------
plot_screen:			ldy #$00
plot_loop:				ldx #$00
plot_load:				lda $2c00,x
plot_save:				sta $0400,x
						inx
						bne plot_load
						inc plot_load+2
						inc plot_save+2
						iny
						cpy #4
						bne plot_loop
						rts
                        //------------------------------------------------------------------------------
pauseLoop:	            ldx #255
			            ldy #255
                !:      dey
                        bne !-
                        dex
                        bne pauseLoop+2
                        rts						 
                        //------------------------------------------------------------------------------
						//  clear the character screen using spaces
                        //------------------------------------------------------------------------------
spaced:					ldx #$00
						lda #32
				!:		sta $0400,x
						sta $0500,x
						sta $0600,x
						sta $0700,x
						dex
						bne !-
						rts
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						// recolour the screen using color in A
						//------------------------------------------------------------------------------
recolor:				ldx #$00
				!:		sta $d800,x
						sta $d900,x
						sta $da00,x
						sta $db00,x
						inx
						bne !-
						rts
						//------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------
						// column plotter
                        //------------------------------------------------------------------------------
plotScreen: 			lda column_number
						cmp #40
						bne !+
                        rts
            !:          jsr column_setup
						jsr column_next										// plot 1 column
						jsr shortPause
                        inc column_number
                        jmp plotScreen
                        //------------------------------------------------------------------------------
column_setup:			ldx column_number
						stx charload+1
						stx charsave+1
						stx colorload+1
						stx colorsave+1
						ldy #$04
						sty charsave+2
						ldy #$d8
						sty colorsave+2
charloadhi:				ldy #$00
						sty charload+2
colorloadhi:			ldy #$00
						sty colorload+2
						lda #$00
						sta line_number
						rts
                        //------------------------------------------------------------------------------
column_next:

charload:				lda $6000
charsave:				sta $0400
colorload:				lda $6400
colorsave:				sta $d800

						lda charload+1
						clc
						adc #40
						sta charload+1
						lda charload+2
						adc #$00
						sta charload+2
						lda charsave+1
						clc
						adc #40
						sta charsave+1
						lda charsave+2
						adc #$00
						sta charsave+2

						lda colorload+1
						clc
						adc #40
						sta colorload+1
						lda colorload+2
						adc #$00
						sta colorload+2
						lda colorsave+1
						clc
						adc #40
						sta colorsave+1
						lda colorsave+2
						adc #$00
						sta colorsave+2

						inc line_number											// check line number
						lda line_number
						cmp #25
						bne column_next
column_done:			lda #$00
						sta line_number
						rts
                        //------------------------------------------------------------------------------
shortPause:				ldx #64
				!:		ldy #32
					!:	dey
						bne !-
						dex
						bne !--
						rts
                        //------------------------------------------------------------------------------

                        //------------------------------------------------------------------------------						
						// fade from dark grey to white
                        //------------------------------------------------------------------------------
darkgrey2white:    		ldy darkgrey2white_number
						cpy #$08					// maximum number in colour table
						bne !+
						lda #WHITE
						sta fade_border+1
						sta fade_screen+1			
						rts
			!:			lda darkgrey2white_table,y
						sta fade_border+1
						sta fade_screen+1
						jsr pauseQuick
						inc darkgrey2white_number
						jmp darkgrey2white
                        //------------------------------------------------------------------------------
						.align $100
						.memblock "misc counters"

darkgrey2white_number: .byte $00
darkgrey2white_table:  .byte $0b,$04,$0c,$03,$0d,$01,$01,$01	//  white to light grey

scrollXpos:    			.byte $01,$00,$00

column_delay:           .byte $00
column_number:			.byte $00
line_number:			.byte $00

x_counter:				.byte $00										// how many chars to plot
y_counter:				.byte $00										// how many lines to plot
screen_number: 			.byte $00										// current screen number
screen_max:				.byte $00										// maximum number of screens
screen_toggle:			.byte $00										// toggle screen on/off

                        //------------------------------------------------------------------------------
						// colour table to go from dark blue to white.
                        //------------------------------------------------------------------------------
crossColorsIn:			.byte $6, $b, $4, $c, $3,$d, $1, $1						
crossColorsNum:			.byte $00,$00
                        //------------------------------------------------------------------------------
						// colour table to go from dark black to white.
                        //------------------------------------------------------------------------------
ballsColorsIn:			.byte $0, $6, $b, $4, $c, $3,$d, $1						
ballsColorsNum:			.byte $00,$00
                        //------------------------------------------------------------------------------
						// fade tables and counters
                        //------------------------------------------------------------------------------
f2dg_number:			.byte $00						
f2dg_table:				.byte $06,$09,$0b,$0b,$0b,$0b,$0b,$0b	// blue to darkgrey
f2black_number:			.byte $00
f2black_table:			.byte $0f,$05,$08,$02,$09,$00,$00,$00	// lightgrey to black

black2darkgrey_number:	.byte $00
black2darkgrey_table:	.byte $00,$06,$0b,$0b,$0b,$0b,$0b,$0b	//  black to dark grey
                        //------------------------------------------------------------------------------
						// order for star's to be displayed
stars_sequence:			.byte 10, 17, 00, 07, 13, 03, 15, 01, 08, 04, 12, 16, 02, 05, 06, 09, 11, 14
star_number:			.byte $00
star_lines:				.byte $00
star_mem_color_hi:		.byte >stars_colors+(40*1)+0, >stars_colors+(40*2)+6, >stars_colors+(40*3)+12 
						.byte >stars_colors+(40*4)+18, >stars_colors+(40*5)+24, >stars_colors+(40*6)+30
						.byte >stars_colors+(40*7)+1, >stars_colors+(40*8)+7, >stars_colors+(40*9)+13 
						.byte >stars_colors+(40*10)+19, >stars_colors+(40*11)+25, >stars_colors+(40*12)+31
						.byte >stars_colors+(40*13)+3, >stars_colors+(40*14)+9, >stars_colors+(40*15)+15
						.byte >stars_colors+(40*16)+21, >stars_colors+(40*17)+27, >stars_colors+(40*18)+33
star_mem_color_lo:		.byte <stars_colors+(40*1)+0, <stars_colors+(40*2)+6, <stars_colors+(40*3)+12
						.byte <stars_colors+(40*4)+18, <stars_colors+(40*5)+24, <stars_colors+(40*6)+30
						.byte <stars_colors+(40*7)+1, <stars_colors+(40*8)+7, <stars_colors+(40*9)+13
						.byte <stars_colors+(40*10)+19, <stars_colors+(40*11)+25, <stars_colors+(40*12)+31
						.byte <stars_colors+(40*13)+3, <stars_colors+(40*14)+9, <stars_colors+(40*15)+15
						.byte <stars_colors+(40*16)+21, <stars_colors+(40*17)+27, <stars_colors+(40*18)+33

petscii_hi_table:		.byte >cross_chars, >stars_chars, >balls_chars, >x_chars, >boxpattern_chars
						.byte >qbert_chars, >diamonds_chars, >crayons_chars, >believe_chars, >dare_chars
						.byte >cutfold_chars, >outside_chars
						
color_hi_table:			.byte >cross_colors, >stars_colors, >balls_colors, >x_colors, >boxpattern_colors
						.byte >qbert_colors, >diamonds_cols, >crayons_colors, >believe_colors, >dare_colors
						.byte >cutfold_colors, >outside_colors

colorBuffer:			.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
						.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
						.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
						.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

						//------------------------------------------------------------------------------
						*=$3000
						.import source "screen16-boxpattern-a.asm"		// do not change, needed for scrolling effect.
						.align $100
						.import source "screen12-cross.asm"
						.align $0100
						.import source "screen13-stars.asm"
						.align $0100
						.import source "screen14-balls.asm"
						.align $0100
						.import source "screen15-xfactor.asm"
						.align $0100
						.import source "screen17-qbert.asm"
						.align $0100
						.import source "screen18-diamonds.asm"
						.align $0100
						.import source "screen19-cubes.asm"
						.align $0100
						.import source "screen20-believe.asm"
						.align $0100
						.import source "screen21-daretoaddcolor.asm"
						.align $0100
						.import source "screen22-cutfoldglue.asm"
						.align $0100
						.import source "screen23-thinkoutofthebox.asm"
                        //------------------------------------------------------------------------------
