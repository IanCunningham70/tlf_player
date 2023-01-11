//------------------------------------------------------------------------------------------------------------------------------------------------------------
// Simple Music Rip Screen
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------
#import "..\library\standardlibrary.asm"			
//------------------------------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------------------------

.const Screen = $0400
.const color_ram = $d800

.var tuneInfoLine = Screen + (40 * 21)

.var r_line1		= $054a-80
.var r_line2		= $054d-80
.var m_line1		= $0559-80
.var m_line2		= $055c-80
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
BasicUpstart2(ripper)
//------------------------------------------------------------------------------------------------------------------------------------------------------------
											*=$080d
											.memblock "main code"
ripper:										ldx #$ff
											txs
											ldx #$2f
											ldy #$36
											stx $00
											sty $01
											lda #LIGHT_GREY
											sta 646
											sta screen
											jsr $e544
											SetBoth(BLACK)
											sta 650
											lda #$80
											sta 657

											ldy #$00
									!:		lda tune_text,y
											and #$7f
											sta Screen,y
											dey
											bne !-
	
											jsr init_tune

											sei
											lda #$7f
											sta $dc0d
											lda $dc0d
											lda #$1b
											sta screenmode
											lda #23
											sta charset
											lda #200
											sta smoothpos
											lda #$01
											sta irqflag
											sta irqenable
											lda #$d2
											sta raster 
											ldx #<irq
											ldy #>irq
											stx $0314
											sty $0315
											ldx #<restore
											ldy #>restore
											stx $0318
											sty $0319
											cli 

keyscan:									jsr $ffe4
											beq keyscan
											cmp #32
											bne keyscan
											jsr init_tune
											jmp keyscan


irq:

											ldx #$fa
											cpx raster
											bne *-3

											ldx #$0b
											dex
											bne *-1

											SetBoth(LIGHT_GREEN)
											lda raster
											sta ras_1
	
											jsr music.play
	
											lda raster
											sta ras_2
											SetBoth(BLACK)

											jsr timer

											inc irqflag
											jmp $ea31
//------------------------------------------------------------
// Run/Stop & Restore Vector.
//------------------------------------------------------------
restore:	rti
	//------------------------------------------------------------
	// Display Tune Current & Maximum Raster Time In Hex & Decimal
	//------------------------------------------------------------
timer:										lda ras_2
	sec
	sbc ras_1
	sta ras_time
	lda ras_max
	cmp ras_time
	bcs timer_2
	lda ras_time
	sta ras_max

	// Display Hex Values.
timer_2:	lda ras_time
	jsr convert
	sta r_line1+1
	stx r_line1
	lda ras_max
	jsr convert
	sta m_line1+1
	stx m_line1

	// Display Decimal Values.
	ldy ras_time
	lda ascii_lo,y
	sta r_line2+1
	lda ascii_hi,y
	sta r_line2
	ldy ras_max
	lda ascii_lo,y
	sta m_line2+1
	lda ascii_hi,y
	sta m_line2
	rts
	//------------------------------------------------------------
	// Convert From Memory To Screen Codes (HEX).
	//------------------------------------------------------------
convert:	pha
	lsr 
	lsr
	lsr
	lsr
	tay
	ldx ascii_hex,y
	pla
	and #$0f
	tay
	lda ascii_hex,y
	rts
	//------------------------------------------------------------
	// Initalise The Tune.
	//------------------------------------------------------------
init_tune:
	lda #$00
	tax
	tay
	jmp music.init

	//------------------------------------------------------------
	// Data Tables
	//------------------------------------------------------------
ascii_no:										.byte	$00
ascii_hex:
	.byte	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39
	.byte	$01,$02,$03,$04,$05,$06
ascii_hi:
	.byte	$30,$30,$30,$30,$30,$30,$30,$30,$30,$30
	.byte	$31,$31,$31,$31,$31,$31,$31,$31,$31,$31
	.byte	$32,$32,$32,$32,$32,$32,$32,$32,$32,$32
	.byte	$33,$33,$33,$33,$33,$33,$33,$33,$33,$33
	.byte	$34,$34,$34,$34,$34,$34,$34,$34,$34,$34
ascii_lo:
	.byte	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39
	.byte	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39
	.byte	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39
	.byte	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39
	.byte	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39
	//------------------------------------------------------------
	// These Are Used To Calculate The Raster Time Used.
	//------------------------------------------------------------
ras_time:		.byte $00
ras_max:		.byte	$00
ras_1:	.byte	$00
ras_2:	.byte	$00

tune_text:							
									//	.text "----------------------------------------"
										.text "                                        "
										.text "   Donkey Kong Country (Sid Version)    "
										.text "       memory usage $1000 - $23d0       "
										.text "        space to restart the tune       "
										.text "                                        "
										.text "         current          max           "
										.text "                                        "
										.text "                                        "
									//	.text "----------------------------------------"			