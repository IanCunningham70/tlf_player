.var lastkey	= $10
.var actkey	    = $11
.var mask	    = $12

.var matrixlo	= $13
.var matrixhi	= $14

.var table	= $0f00

	*= $1000
	
	lda #$37
	sta $01
	jsr $e544
	
	sei
	lda #$35
	sta $01
	
	ldx #$00
	lda #$00
!:	sta table,x
	dex
	bne !-
	
	lda #$ff
	sta lastkey
	
	lda #$08		// helper table to index into keyboard matrix
	sta table+%01111111
	lda #$07
	sta table+%10111111
	lda #$06
	sta table+%11011111
	lda #$05
	sta table+%11101111
	lda #$04
	sta table+%11110111
	lda #$03
	sta table+%11111011
	lda #$02
	sta table+%11111101
	lda #$01
	sta table+%11111110
	
	lda #$08		// left shift and another key
	sta table+%01111111
	lda #$07
	sta table+%00111111
	lda #$06
	sta table+%01011111
	lda #$05
	sta table+%01101111
	lda #$04
	sta table+%01110111
	lda #$03
	sta table+%01111011
	lda #$02
	sta table+%01111101
	lda #$01
	sta table+%01111110	
	
	lda #$08		// right shift and another key
	sta table+%01101111
	lda #$07
	sta table+%10101111
	lda #$06
	sta table+%11001111
	lda #$05
	sta table+%11101111
	lda #$04
	sta table+%11100111
	lda #$03
	sta table+%11101011
	lda #$02
	sta table+%11101101
	lda #$01
	sta table+%11101110


	// endless dummy 
	
uu:	jsr keyscan
	lda actkey
	cmp #$ff	// $ff= no key pressed
    beq !+
	cmp #$40	// convert to screen codes
	bmi ok
	sec
	sbc #$40
ok:
	sta $0400

!:	jmp uu
	

keyscan:
	lda #%11111110
	sta mask
	
	lda #%11111101
	sta $dc00
	lda $dc01
	and #%10000000
	beq shifted	// left shift pressed

	lda #%10111111
	sta $dc00
	lda $dc01
	and #%00010000
	beq shifted	// right shift pressed
	
	lda #<keytabunshifted
	sta matrixlo
	lda #>keytabunshifted
	sta matrixhi
	jmp scan

shifted:
	lda #<keytabshifted
	sta matrixlo
	lda #>keytabshifted
	sta matrixhi
	
scan:	ldx #$07
	
rowloop:
	lda mask	
	sta $dc00
	ldy $dc01
	lda table,y
	beq next
		
	tay
	lda (matrixlo),y
	cmp #$01
	beq next		// skip left shift
	cmp #$02
	beq next		// skip right shift
	cmp lastkey
	beq debounce
	sta lastkey
	sta actkey
	rts
	
next:	
	sec
	rol mask
		
	lda matrixlo
	clc
	adc #$09
	sta matrixlo
	bcc *+4
	inc matrixhi
	
	dex
	bpl rowloop
	rts
	
debounce:
	lda #$ff
	sta actkey
	rts
		
	// unshifted
	
keytabunshifted:

	.byte $ff,$14,$0D,$1D,$88,$85,$86,$87,$11 // 0
	.byte $ff,$33,$57,$41,$34,$5A,$53,$45,$01 // 1
	.byte $ff,$35,$52,$44,$36,$43,$46,$54,$58 // 2
	.byte $ff,$37,$59,$47,$38,$42,$48,$55,$56 // 3
	.byte $ff,$39,$49,$4A,$30,$4D,$4B,$4F,$4E // 4
	.byte $ff,$2B,$50,$4C,$2D,$2E,$3A,$40,$2C // 5
	.byte $ff,$5C,$2A,$3B,$13,$01,$3D,$5E,$2F // 6
	.byte $ff,$31,$5F,$04,$32,$20,$02,$51,$03 // 7
	.byte $ff

keytabshifted:
	.byte $ff,$94,$8D,$9D,$8C,$89,$8A,$8B,$91
	.byte $ff,$23,$D7,$C1,$24,$DA,$D3,$C5,$01
	.byte $ff,$25,$D2,$C4,$26,$C3,$C6,$D4,$D8
	.byte $ff,$27,$D9,$C7,$28,$C2,$C8,$D5,$D6
	.byte $ff,$29,$C9,$CA,$30,$CD,$CB,$CF,$CE
	.byte $ff,$DB,$D0,$CC,$DD,$3E,$5B,$BA,$3C
	.byte $ff,$A9,$C0,$5D,$93,$01,$3D,$DE,$3F
	.byte $ff,$21,$5F,$04,$22,$A0,$02,$D1,$83
	.byte $ff

