//----------------------------------------------------------------------
//.const screen = $4800
.const colorram = $d800
//--------------
.const timeLine1 = 20
.const timeLine2 = 21
//----------------------------------------------------------------------
.var fileCharset = LoadBinary("hires2x2.chr", BF_C64FILE)
//----------------------------------------------------------------------
                                          .pc = $4000 "Charset"
Charset:
.fill fileCharset.getSize(), fileCharset.get(i)
//----------------------------------------------------------------------
                                          .pc = $4800 "Screen"
Screen:
.fill 40 * 25, $20
//----------------------------------------------------------------------
                                          .pc = $4c00 "Sprites"
Sprites:
.fill fileSprites.getSize(), fileSprites.get(i) ^ $ff
//----------------------------------------------------------------------
                                          .pc = $4e00 "Init"
Init:
                                          jsr InitStableRaster

                                          jsr InitTimer
                                          jsr InitClock

//--------------
                                          lda #$f9
                                          sta $d012

                                          ldx #<Irq
                                          ldy #>Irq
                                          stx $fffe
                                          sty $ffff

                                          lda #$01
                                          sta $d019
                                          sta $d01a
//--------------
Mainloop:

                                          jmp Mainloop
//----------------------------------------------------------------------
TextLine1:                                .text vText1
TextLine2:                                .text vText2
TextLine3:                                .text vText3
Time:                                     .text vTime
TextLine4:                                .text vText4
//----------------------------------------------------------------------
                                          .memblock "InitStableRaster"
InitStableRaster:
                                          lda #0
                                          sta $d015

!:                                        bit $d011
                                          bpl !-
!:                                        bit $d011
                                          bmi !-

                                          ldx $d012
                                          inx
                                          cpx $d012
                                          bne *-3
                                          ldy #$0a
                                          dey
                                          bne *-1
                                          inx
                                          cpx $d012
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
                                          cpx $d012
                                          nop
                                          beq *+4
                                          bit $24
                                          ldy #$0a
                                          dey
                                          bne *-1
                                          inx
                                          cpx $d012
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
//----------------------------------------------------------
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
//----------------------------------------------------------
                                          .memblock "InitTimer"
InitTimer:
                                          lda #0
                                          sta secl
                                          sta sech
                                          sta minl
                                          sta minh

                                          rts
//----------------------------------------------------------------------
                                          .memblock "SetTimer2"
SetTimer:
                                          lda $dc09
                                          and #%00001111
                                          sta secl

                                          lda $dc09
                                          and #%01111000
                                          lsr
                                          lsr
                                          lsr
                                          lsr
                                          sta sech

                                          lda $dc0a
                                          and #%00001111
                                          sta minl

                                          lda $dc0a
                                          and #%01111000
                                          lsr
                                          lsr
                                          lsr
                                          lsr
                                          sta minh

							// plot minute hi in 2 x 2 

                                          ldx minh
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

                                          ldx minl
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

                                          ldx sech
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

                                          ldx secl
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
//-------------------
secl:                                     .byte $00
sech:                                     .byte $00

minl:                                     .byte $00
minh:                                     .byte $00

chartab:                                  .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39		// numbers 0 - 9 for clock
//----------------------------------------------------------------------
                                          .align $100
                                          .memblock "Irq"
Irq:
                                          pha
                                          txa
                                          pha
                                          tya
                                          pha
//--------------
                                          lda #$ef    // space to restart music ?
                                          cmp $dc01
                                          bne !+
                                          lda #0
                                          tay
                                          tax
                                          jsr music.init
                                          jsr InitTimer
                                          jmp stlc

!:                                        jsr PlayMusic

                                          jsr SetTimer
//--------------
stlc:

logoon:                                   lda #$3f
                                          sta $d012
                                          ldx #<IrqLogoOn
                                          ldy #>IrqLogoOn
                                          sty $ffff
                                          stx $fffe

                                          asl $d019

                                          pla
                                          tay
                                          pla
                                          tax
                                          pla

                                          rti
//----------------------------------------------------------------------
                                          .memblock "IrqLogoOn"
IrqLogoOn:
                                          pha
                                          txa
                                          pha
                                          tya
                                          pha
logooff:                                  lda #$3f + (21 * 2) + 2
                                          sta $d012
                                          ldx #<IrqLogoOff
                                          ldy #>IrqLogoOff
                                          sty $ffff
                                          stx $fffe

                                          asl $d019

                                          pla
                                          tay
                                          pla
                                          tax
                                          pla

                                          rti
//-------------------
FlashColors:
                                          .byte $00, $00, $00, $00
                                          .byte $09, $09, $09, $09
                                          .byte $08, $08, $08, $08
                                          .byte $0a, $0a, $0a, $0a
                                          .byte $0f, $0f, $0f, $0f
                                          .byte $07, $07, $07, $0f
                                          .byte $01, $01, $01, $01
                                          .byte $07, $07, $07, $07
                                          .byte $03, $03, $03, $03
                                          .byte $0e, $0e, $0e, $0e
                                          .byte $04, $04, $04, $04
                                          .byte $06, $06, $06, $06
                                          .byte $00, $00, $00, $00
//----------------------------------------------------------------------
