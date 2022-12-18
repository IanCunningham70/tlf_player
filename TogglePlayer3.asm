//----------------------------------------------------------------------
//----------------------------------------------------------------------
//.const screen = $4800
.const colorram = $d800
//--------------
.const zp_DrawSpectrometer = $3e
.const zp_DrawSpectrometerIndex = $3f
.const SID_Ghostbytes = $40                                     // Location of SID Ghostbytes (16 bytes)
//--------------
.const timeLine1 = 20
.const timeLine2 = 21
//----------------------------------------------------------------------
.var music = LoadSid(sidname)
//----------------------------------------------------------------------
.var fileCharset = LoadBinary("hires2x2.chr", BF_C64FILE)
//----------------------------------------------------------------------
//.var fileSprites = LoadBinary("sprites_toggle_hires.bin")
//.var fileSprites = LoadBinary("Toggle_Hires_1.bin")
.var fileSprites = LoadBinary("Toggle_Medron8.bin")
//----------------------------------------------------------------------
.var SinusCenterB = ((8 * 4) - 7) / 2
.var SinusAmpB = SinusCenterB

.var SinusCenterY = ((8 * 8) - (21 * 2)) / 2
.var SinusAmpY = SinusCenterY

.var SinusCenterX = 20
.var SinusAmpX = 20

/*
7 * 6 = 42
8 * 6 = 48
4 chars links und rechts unter border

$f0 $f7 | $00       sprite 2 "0" -> $18 + $10
*/

.var listSinusBouncingBar = List()
.var listSinusY = List().add(18,19,19,19,19,20,20,20,20,21,21,21,21,21,21,21,21,21,21,21,20,20,20,20,19,19,18,18,17,16,16,15,14,14,13,12,12,11,10,10,9,9,8,8,7,7,7,7,6,6,6,6,6,6,7,7,7,7,7,8,8,8,8,9,9,9,10,10,10,10,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,11,11,11,11,11,10,10,10,10,9,9,9,9,8,8,8,7,7,7,7,6,6,6,5,5,5,4,4,4,3,3,3,2,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,3,3,4,5,5,6,7,7,8,9,9,10,11,11,12,12,13,13,14,14,14,14,15,15,15,15,15,15,14,14,14,14,14,13,13,13,13,12,12,12,11,11,11,11,10,10,10,10,10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,11,11,11,11,12,12,12,12,13,13,13,14,14,14,14,15,15,15,16,16,16,17,17,17,18,18)
.var listSinusX = List().add(13,12,12,11,11,10,10,9,8,8,7,6,6,5,4,4,3,3,2,2,1,1,0,0,0,0,0,0,0,0,1,1,2,2,3,4,4,5,6,7,8,9,10,11,12,14,15,16,17,18,20,21,22,23,24,25,26,27,28,29,29,30,30,31,31,32,32,32,32,32,32,32,31,31,31,30,30,29,29,28,28,27,26,26,25,24,24,23,22,22,21,21,20,19,19,19,18,18,17,17,17,17,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,15,15,15,15,15,14,14,13,13,12,12,11,11,10,10,9,8,8,7,6,6,5,4,4,3,3,2,2,1,1,0,0,0,0,0,0,0,0,1,1,2,2,3,4,4,5,6,7,8,9,10,11,12,14,15,16,17,18,20,21,22,23,24,25,26,27,28,29,29,30,30,31,31,32,32,32,32,32,32,32,31,31,31,30,30,29,29,28,28,27,26,26,25,24,24,23,22,22,21,21,20,19,19,19,18,18,17,17,17,17,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,15,15,15,15,15,14,14,13)
.for (var i = 0; i < 256; i++)
{
       .var value = SinusCenterB + SinusAmpB * sin(toRadians(i * 360 / 128))
       .eval value = round(value)
       .eval listSinusBouncingBar.add(value)

       .var valueY = SinusCenterY + SinusAmpY * sin(toRadians(i * 360 / 128))
       .eval valueY = $32 + round(valueY)
//     .eval listSinusY.add(valueY)

       .var valueX = SinusCenterX + SinusAmpX * sin(toRadians(i * 360 / 128))
       .eval valueX = round(valueX)
//     .eval listSinusX.add(valueX)
}
//----------------------------------------------------------------------
                                          .pc = $0801 "Basic Upstart"
                                          BasicUpstart2(Init)
//----------------------------------------------------------------------
                                          .pc = music.location "Music"
.fill music.size, music.getData(i)
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
                                          lda #$7f
                                          sta $dc0d
                                          sta $dd0d
                                          bit $dc0d
                                          bit $dd0d

                                          lda #$35
                                          sta $01
//--------------
                                          jsr InitStableRaster
                                          jsr InitGraphics
                                          jsr SetText
                                          jsr SetSprites
                                          jsr InitTimer
                                          jsr InitClock
//--------------
                                          lda #0
                                          tay
                                          tax
                                          jsr music.init
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
                                          lda zp_DrawSpectrometer
                                          beq !+
                                          lda #0
                                          sta zp_DrawSpectrometer
                                          jsr DrawSpectrometer
!:
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
                                          .memblock "InitGraphics"
InitGraphics:
                                          lda #0
                                          sta $d020
                                          sta $d021

                                          lda $dd00
                                          and #%11111100
                                          ora #%00000010
                                          sta $dd00

                                          lda #$1b
                                          sta $d011

                                          lda #%00100000
                                          sta $d018

                                          lda #$c8
                                          sta $d016

                                          lda #$55
                                          sta $7fff

                                          ldx #0
!:
                                          lda #$20
                                          sta Screen + $100 * 0,x
                                          sta Screen + $100 * 1,x
                                          sta Screen + $100 * 2,x
                                          sta Screen + $100 * 3,x
                                          lda #$01
                                          sta colorram + $100 * 0,x
                                          sta colorram + $100 * 1,x
                                          sta colorram + $100 * 2,x
                                          sta colorram + $100 * 3,x
                                          inx
                                          bne !-

                                          ldx #39
!:                                        lda #$00
                                          sta colorram + 40 * 0,x
                                          sta colorram + 40 * 1,x
                                          sta colorram + 40 * 2,x
                                          sta colorram + 40 * 3,x
                                          sta colorram + 40 * 4,x
                                          sta colorram + 40 * 5,x
                                          sta colorram + 40 * 6,x
                                          sta colorram + 40 * 7,x
                                          dex
                                          bpl !-

                                          ldx #4
!:                                        lda #$00
                                          sta Screen + 40 * 0,x
                                          sta Screen + 40 * 1,x
                                          sta Screen + 40 * 2,x
                                          sta Screen + 40 * 3,x
                                          sta Screen + 40 * 4,x
                                          sta Screen + 40 * 5,x
                                          sta Screen + 40 * 6,x
                                          sta Screen + 40 * 7,x
                                          lda #$00
                                          sta colorram + 40 * 0,x
                                          sta colorram + 40 * 1,x
                                          sta colorram + 40 * 2,x
                                          sta colorram + 40 * 3,x
                                          sta colorram + 40 * 4,x
                                          sta colorram + 40 * 5,x
                                          sta colorram + 40 * 6,x
                                          sta colorram + 40 * 7,x
                                          inx
                                          cpx #32 + 4
                                          bne !-

                                          ldx #0
!:
                                          lda pattern,x
                                          sta Charset + 0,x
                                          inx
                                          cpx #8
                                          bne !-

                                          rts
//------------
pattern:
                                          .byte %11111111, %00000000, %11111111, %00000000, %11111111, %00000000, %11111111, %00000000
//----------------------------------------------------------------------
                                          .memblock "SetText"
SetText:
                                          ldy #0
                                          ldx #0
!:
                                          lda TextLine1,y
                                          sta Screen + 10 * 40,x
                                          lda TextLine2,y
                                          sta Screen + 14 * 40,x
                                          lda TextLine3,y
                                          sta Screen + 17 * 40,x
                                          lda Time,y
                                          sta Screen + 20 * 40,x
                                          lda TextLine4,y
                                          sta Screen + 23 * 40,x

                                          lda TextLine1,y
                                          clc
                                          adc #$80
                                          sta Screen + 11 * 40,x
                                          lda TextLine2,y
                                          clc
                                          adc #$80
                                          sta Screen + 15 * 40,x
                                          lda TextLine3,y
                                          clc
                                          adc #$80
                                          sta Screen + 18 * 40,x
                                          lda Time,y
                                          clc
                                          adc #$80
                                          sta Screen + 21 * 40,x
                                          lda TextLine4,y
                                          clc
                                          adc #$80
                                          sta Screen + 24 * 40,x

                                          inx

                                          lda TextLine1,y
                                          clc
                                          adc #$40
                                          sta Screen + 10 * 40,x
                                          lda TextLine2,y
                                          clc
                                          adc #$40
                                          sta Screen + 14 * 40,x
                                          lda TextLine3,y
                                          clc
                                          adc #$40
                                          sta Screen + 17 * 40,x
                                          lda Time,y
                                          clc
                                          adc #$40
                                          sta Screen + 20 * 40,x
                                          lda TextLine4,y
                                          clc
                                          adc #$40
                                          sta Screen + 23 * 40,x

                                          lda TextLine1,y
                                          clc
                                          adc #$c0
                                          sta Screen + 11 * 40,x
                                          lda TextLine2,y
                                          clc
                                          adc #$c0
                                          sta Screen + 15 * 40,x
                                          lda TextLine3,y
                                          clc
                                          adc #$c0
                                          sta Screen + 18 * 40,x
                                          lda Time,y
                                          clc
                                          adc #$c0
                                          sta Screen + 21 * 40,x
                                          lda TextLine4,y
                                          clc
                                          adc #$c0
                                          sta Screen + 24 * 40,x

                                          iny

                                          inx
                                          cpx #40
                                          beq igOut
                                          jmp !-
igOut:
                                          rts
//----------------------------------------------------------------------
                                          .memblock "SetSpritesPosition"
SetSpritesPosition:
                                          lda #$08
                                          sta $d000
                                          lda #$38
                                          sta $d002

sspx:                                     ldx #87
                                          clc
                                          lda SinusX,x
//                                        lda #$18 + (4 * 8)
                                          sta $d004
!:                                        adc #24 * 2
                                          sta $d006
!:                                        adc #24 * 2
                                          sta $d008
!:                                        adc #24 * 2
                                          sta $d00a
!:                                        adc #24 * 2
                                          sta $d00c
!:                                        adc #24 * 2
                                          sta $d00e

                                          lda #%10000010
                                          sta $d010

sspy:                                     ldy #38
                                          lda SinusY,y
                                          sta $d001
                                          sta $d003
                                          sta $d005
                                          sta $d007
                                          sta $d009
                                          sta $d00b
                                          sta $d00d
                                          sta $d00f

                                          sta logoon + 1
                                          clc
                                          adc #21 * 2 - 1
                                          sta logooff + 1
//-------------------
                                          inc sspx + 1

                                          inc sspy + 1

                                          rts
//----------------------------------------------------------------------
                                          .memblock "SetSprites"
SetSprites:
                                          jsr SetSpritesPosition

                                          lda #%11111111
                                          sta $d015
                                          sta $d017
                                          sta $d01d

                                          lda #%00000000
                                          sta $d01b
                                          sta $d01c

                                          lda #$0c
                                          sta $d025
                                          lda #$0f
                                          sta $d026

                                          lda #0
                                          sta $d027
                                          sta $d028
                                          sta $d029
                                          sta $d02a
                                          sta $d02b
                                          sta $d02c
                                          sta $d02d
                                          sta $d02e

                                          lda #$0c * 4 + 0
                                          sta Screen + $3f8 + 0
                                          lda #$0c * 4 + 7
                                          sta Screen + $3f8 + 1
                                          lda #$0c * 4 + 1
                                          sta Screen + $3f8 + 2
                                          lda #$0c * 4 + 2
                                          sta Screen + $3f8 + 3
                                          lda #$0c * 4 + 3
                                          sta Screen + $3f8 + 4
                                          lda #$0c * 4 + 4
                                          sta Screen + $3f8 + 5
                                          lda #$0c * 4 + 5
                                          sta Screen + $3f8 + 6
                                          lda #$0c * 4 + 6
                                          sta Screen + $3f8 + 7

                                          rts
//----------------------------------------------------------------------
                                          .memblock "SetTextLineColors"
SetTextLineColors:
stlc0:                                    lda #0
                                          beq !+
                                          jmp stlc2
!:
                                          dec stlc1 + 1
stlc1:                                    lda #50 * 2
                                          bne stlcOut
                                          lda #50 * 2
                                          sta stlc1 + 1

                                          inc stlc0 + 1
                                          jmp stlcOut

stlc2:
                                          ldy #0
stlc3:                                    ldx #1
!:
                                          lda TextlineColors + 0,x
                                          sta colorram + (40 * 14),y
                                          lda TextlineColors + 1,x
                                          sta colorram + (40 * 15),y
                                          inx
                                          iny
                                          cpy #40
                                          bne !-

                                          ldy #0
stlc4:                                    ldx #40 + 13
!:
                                          lda TextlineColors + 1,x
                                          sta colorram + (40 * 17),y
                                          lda TextlineColors + 0,x
                                          sta colorram + (40 * 18),y
                                          inx
                                          iny
                                          cpy #40
                                          bne !-

                                          inc stlc3 + 1
                                          dec stlc4 + 1
                                          lda stlc4 + 1
                                          bne stlcOut
                                          lda #1
                                          sta stlc3 + 1
                                          lda #40 + 13
                                          sta stlc4 + 1

                                          lda #0
                                          sta stlc0 + 1
stlcOut:
                                          rts
//-------------------
TextlineColors:
.fill 42, $01
                                          .byte $07, $0f, $0a, $08, $09
                                          .byte $00
                                          .byte $06, $04, $0e, $03, $07             // 11
.fill 42, $01
//----------------------------------------------------------------------
                                          .memblock "SetBouncingBars"
SetBouncingBars:
                                          ldx #0
//                                        lda #$03
                                          lda #$00
!:
                                          sta BouncingBars,x
//                                        eor #$ff
                                          inx
                                          cpx #8 * 4
                                          bne !-
//rts
sbb1:                                     lda #17
                                          sta sbb0 + 1
                                          lda #0
                                          sta sbb2 + 1

sbb0:                                     ldy #14
                                          ldx SinusBouncingBar,y
                                          ldy #0
!:                                        lda BouncingBar,y
                                          sta BouncingBars,x
                                          inx
                                          iny
                                          cpy #7
                                          bne !-

                                          lda sbb0 + 1
                                          clc
                                          adc #8
                                          sta sbb0 + 1

                                          inc sbb2 + 1
sbb2:                                     lda #0
                                          cmp #8
                                          bne sbb0

                                          inc sbb1 + 1

                                          rts
//-------------------
BouncingBar:                              .byte $09, $08, $02, $0a, $0d, $03, $05
BouncingBars:
.fill 8 * 4, $0b
//----------------------------------------------------------------------
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

chartab:                                  .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
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
                                          lda #$ef
                                          cmp $dc01
                                          bne !+
                                          lda #0
                                          tay
                                          tax
                                          jsr music.init
                                          jsr InitTimer
                                          jmp stlc

!:                                        jsr PlayMusic

                                          jsr Spectrometer
                                          inc zp_DrawSpectrometer

                                          jsr SetTimer
//--------------
stlc:
                                          jsr SetTextLineColors

                                          jsr SetBouncingBars

                                          jsr SetSpritesPosition
//--------------
                                          lda #%01111011
                                          sta $d011
/*
                                          lda #$00
                                          sta $d020
                                          sta $d021
*/
                                          lda #%11111111
                                          sta $d015
//--------------
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
//--------------
clo:                                      ldx #0
                                          ldy FlashColors,x

                                          ldx #%00011011

                                          lda $d012
!:                                        cmp $d012
                                          beq !-

                                          stx $d011

                                          sty $d021

cloGate:                                  lda #0
                                          bne clo2
                                          dec clo1 + 1
clo1:                                     lda #50 * 5
                                          bne cloEnd
                                          lda #50 * 5
                                          sta clo1 + 1
                                          inc cloGate + 1
                                          jmp cloEnd
clo2:
                                          inc clo + 1
                                          lda clo + 1
                                          cmp #4 * 13
                                          bne cloEnd
                                          lda #0
                                          sta clo + 1
                                          sta cloGate + 1
cloEnd:
//--------------
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
                                          .memblock "IrqLogoOff"
IrqLogoOff:
                                          pha
                                          txa
                                          pha
                                          tya
                                          pha
//--------------
                                          ldy #0

                                          ldx #%01111011

                                          lda $d012
!:                                        cmp $d012
                                          beq !-

                                          stx $d011

                                          sty $d020
                                          sty $d021
//--------------
                                          lda #$74
                                          sta $d012
                                          ldx #<IrqTextOn
                                          ldy #>IrqTextOn
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
                                          .memblock "IrqTextOn"
IrqTextOn:
                                          pha
                                          txa
                                          pha
                                          tya
                                          pha
//--------------
                                          pha
                                          pla
                                          pha
                                          pla
                                          bit $dbdb

                                          lda #%00000000
                                          sta $d015

                                          lda #%00011011
                                          sta $d011

                                          lda #%00100000
                                          sta $d018
//--------------
                                          lda #$7a
!:                                        cmp $d012
                                          bne !-


/*                                        ldx #7
!:                                        dex
                                          bne !-
                                          bit $ffff
                                          nop
*/
                                          lda #$3f
                                          sbc $dd06
                                          and #$07
                                          sta jump + 1
jump:                                     bcs jump
                                          lda #$a9
                                          lda #$a9
                                          lda #$a9
                                          lda #$a5
                                          nop

                                          bit $ffff
                                          bit $ffff
                                          bit $ffff
                                          bit $ffff
                                          bit $ffff

                                          jsr DrawBouncingBars
//--------------
                                          lda #$d0
                                          sta $d012
                                          ldx #<Irq
                                          ldy #>Irq
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
                                          .align $100
                                          .memblock "DrawSpectrometer"
DrawSpectrometer:
                                          lda #0
                                          sta zp_DrawSpectrometerIndex

sp3:                                      tax
                                          lda dBMeterValue,x
                                          asl
                                          asl
                                          asl
//                                        asl
                                          tay
                                          sta sp0 + 1

                                          txa
                                          asl
                                          clc
                                          adc #4
                                          tax

                                          ldy #0

sp2:                                      lda ScreenPosLo,y
                                          sta sp1 + 1
                                          sta sp11 + 1
                                          lda ScreenPosHi,y
                                          sta sp1 + 2
                                          sta sp11 + 2

//sp0:                                    lda SpectroMeterScreen,y
sp0:                                      lda SpectroMeterScreen8,y
sp1:                                      sta $ffff,x
                                          inx
sp11:                                     sta $ffff,x
                                          dex

                                          iny
//                                        cpy #16
                                          cpy #8
                                          bne sp2

                                          inc zp_DrawSpectrometerIndex
                                          lda zp_DrawSpectrometerIndex
                                          cmp #16
                                          bne sp3
//--------------
                                          rts
//--------------
ScreenPosLo:
.for (var i = 0; i < 16; i++)
{
       .var value = colorram + 40 * (i + 0)
                                          .byte <value
}

ScreenPosHi:
.for (var i = 0; i < 16; i++)
{
       .var value = colorram + 40 * (i + 0)
                                          .byte >value
}
//----------------------------------------------------------------------
                                          .align $100
                                          .memblock "DrawBouncingBars"
DrawBouncingBars:
                                          ldy #0
                                          ldx #0
dbb:
                                          lda BouncingBars,x   //4
                                          sta $d020            //4
                                          sta $d021            //4
                                          inx                  //2 = 14
                                          bit $ff
                                          bit $ffff

                                          lda BouncingBars,x   //4
                                          sta $d020            //4
                                          sta $d021            //4
                                          inx                  //2 = 14
                                          jsr Wait46

                                          lda BouncingBars,x   //4
                                          sta $d020            //4
                                          sta $d021            //4
                                          inx                  //2 = 14
                                          jsr Wait46

                                          lda BouncingBars,x   //4
                                          sta $d020            //4
                                          sta $d021            //4
                                          inx                  //2 = 14
                                          jsr Wait46

                                          lda BouncingBars,x   //4
                                          sta $d020            //4
                                          sta $d021            //4
                                          inx                  //2 = 14
                                          jsr Wait46

                                          lda BouncingBars,x   //4
                                          sta $d020            //4
                                          sta $d021            //4
                                          inx                  //2 = 14
                                          jsr Wait46

                                          lda BouncingBars,x   //4
                                          sta $d020            //4
                                          sta $d021            //4
                                          inx                  //2 = 14
                                          jsr Wait46

                                          lda BouncingBars,x   //4
                                          sta $d020            //4
                                          sta $d021            //4
                                          inx                  //2 = 14
                                          jsr Wait41

                                          iny                  // 2
                                          cpy #4               // 2
                                          bne dbb              // 3

                                          nop
                                          nop

                                          lda #$00
                                          sta $d020
                                          sta $d021

                                          rts
//-------------------
Wait46:
                                          nop
                                          bit $ff
                                          bit $ffff
                                          bit $ffff
                                          jsr Wait
                                          jsr Wait

Wait:                                     rts

Wait41:
                                          nop
                                          bit $ff
                                          jsr Wait
                                          jsr Wait

                                          rts
//----------------------------------------------------------------------
                                          .memblock "Spectrometer"
Spectrometer:               // Call this every frame. You can then use the values in the dBMeterValue table as index for drawing your spectrometer bands.

DecreaseBarIndexes:         ldx #16                             // MeterTemp contains the index values, or height, of each of the 16 bands.
!:                          lda MeterTemp,x                     // This code will go through each of these values and decrease them until = 0.
                            beq dBMeterUpdate_NoDec
                            dec MeterTemp,x
dBMeterUpdate_NoDec:        tay
                            lda SoundbarSine,y                  // The index value from MeterTemp is used to get a value from a bouncing sinewave.
                            sta dBMeterValue,x                  // SoundbarSine is the sine, it contains a 90 degree drop and a small 180 degree bounce.
                            dex
                            bpl !-

                            ldx SID_Ghostbytes                  // Get Channel 1 Note
                            lda SID_Ghostbytes+1
                            jsr GetNote
                            lda SID_Ghostbytes+6                // Isolate sustain value
                            and #$f0
                            lsr
                            lsr
                            lsr
                            lsr
                            clc
                            adc #6
                            sta MeterTemp,x                     // Store new index for band representing the node played. X was received by GetNote function.
                            jsr CalculateSurroundings           // Calculate polarization of neighbouring bands

                            ldx SID_Ghostbytes+7                // Channel 2 Note
                            lda SID_Ghostbytes+8
                            jsr GetNote
                            lda SID_Ghostbytes+$d               // Repeat channel 2
                            and #$f0
                            lsr
                            lsr
                            lsr
                            lsr
                            clc
                            adc #6
                            sta MeterTemp,x
                            jsr CalculateSurroundings

                            ldx SID_Ghostbytes+$e               // Repeat channel 3
                            lda SID_Ghostbytes+$f
                            jsr GetNote
                            lda SID_Ghostbytes+$14
                            and #$f0
                            lsr
                            lsr
                            lsr
                            lsr
                            clc
                            adc #6
                            sta MeterTemp,x
                            jsr CalculateSurroundings
                            rts

GetNote:                    stx NoteLo                  // Input is the node frequency
                            sta NoteHi                  // We'll search the shortened frequency tables to approximate the node playing on a linear scale
                            ldx #8
                            ldy #0                      // Search iteration counter
IterateBinarySearch:        lda FreqTableLookupHilsb,x
                            sta CompareHi+1
                            lda FreqTableLookupHimsb,x
                            sta CompareHi+2
                            lda FreqTableLookupLolsb,x
                            sta CompareLo+1
                            lda FreqTableLookupLomsb,x
                            sta CompareLo+2

                            lda NoteHi                  // compare high bytes
CompareHi:                  cmp FreqTablePalHi
                            bcc Lower1                  // if NUM1H < NUM2H then NUM1 < NUM2
                            bne Higher1                 // if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
                            lda NoteLo                  // compare low bytes
CompareLo:                  cmp FreqTablePalLo
                            bcs Higher1                 // if NUM1L >= NUM2L then NUM1 >= NUM2
                            rts

Lower1:                     txa
                            sec
                            sbc Delta,y
                            tax
                            iny
                            cpy #4                      // Control max number of iterations
                            beq Done
                            jmp IterateBinarySearch

Higher1:                    txa
                            clc
                            adc Delta,y
                            tax
                            iny
                            cpy #4
                            beq Done
                            jmp IterateBinarySearch

Done:                       rts                         // X register contains the node played approximated to a table of 16 positions.

CalculateSurroundings:      lda MeterTemp-2,x           // Rudimentary, but it works :)
                            cmp MeterTemp,x             // Current band index in X.
                            bcc LeftIsLower             // Take Current band from index-2 and calculate the value between these two and use it for band index-1.
                            lda MeterTemp-2,x           // Do the same for the other side, index1=index2+((index-index2)/2)
                            sec
                            sbc MeterTemp,x
                            lsr
                            clc
                            adc MeterTemp,x
                            sta MeterTemp-1,x
                            jmp LeftSurround
LeftIsLower:                lda MeterTemp,x
                            sec
                            sbc MeterTemp-2,x
                            lsr
                            clc
                            adc MeterTemp-2,x
LeftSurround:               cmp #21
                            bcc !+
                            lda #21
!:                          sta MeterTemp-1,x

                            lda MeterTemp+2,x
                            cmp MeterTemp,x
                            bcc LeftIsLower2
                            lda MeterTemp+2,x
                            sec
                            sbc MeterTemp,x
                            lsr
                            clc
                            adc MeterTemp,x
                            sta MeterTemp+1,x
                            jmp LeftSurround2
LeftIsLower2:               lda MeterTemp,x
                            sec
                            sbc MeterTemp+2,x
                            lsr
                            clc
                            adc MeterTemp+2,x
LeftSurround2:              cmp #21
                            bcc !+
                            lda #21
!:                          sta MeterTemp+1,x

                            rts
//----------------------------------------------------------------------
// Play music using ghostbytes
                                          .memblock "PlayMusic"
PlayMusic:
                                          lda $01                             // Grab SID data. This is called from IRQ.
                                          pha
                                          lda #$30
                                          sta $01
.for (var i = 0; i < speed; i++)
{
       .if (speed > 1 && i > 0)
       {
              .if (multiSpeed)
              {
                                          jsr music.play + 3
              }
              else
              {
                                          jsr music.play + 0
              }
       }
       else
       {
                                          jsr music.play
       }
}
                                          ldx #$19
!CopySIDData:                             lda $d400,x
                                          sta SID_Ghostbytes,x
                                          dex
                                          bpl !CopySIDData-

                                          pla
                                          sta $01

                                          ldx #$19
!CopyToSID:                               lda SID_Ghostbytes,x
                                          sta $d400,x
                                          dex
                                          bpl !CopyToSID-

                                          rts
//----------------------------------------------------------------------
                                          .align $100
                                          .memblock "SpectroMeterScreen"
SpectroMeterScreen:
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $00, $05, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $08, $05, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $08, $08, $05, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $00, $02, $08, $08, $05, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $00, $02, $02, $08, $08, $05, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $00, $09, $02, $02, $08, $08, $05, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $00, $09, $09, $02, $02, $08, $08, $05, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
                                          .byte $09, $09, $09, $02, $02, $08, $08, $05, $05, $05, $0d, $0d, $0d, $0d, $0d, $0d
//----------------------------------------------------------------------
                                          .align $100
                                          .memblock "SpectroMeterScreen8"
SpectroMeterScreen8:
                                          .byte $00, $00, $00, $00, $00, $00, $00, $00
                                          .byte $00, $00, $00, $00, $00, $00, $00, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $00, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $05, $0d, $0d
                                          .byte $00, $00, $00, $00, $00, $05, $0d, $0d
                                          .byte $00, $00, $00, $00, $05, $05, $0d, $0d
                                          .byte $00, $00, $00, $00, $05, $05, $0d, $0d
                                          .byte $00, $00, $00, $08, $05, $05, $0d, $0d
                                          .byte $00, $00, $00, $08, $05, $05, $0d, $0d
                                          .byte $00, $00, $02, $08, $05, $05, $0d, $0d
                                          .byte $00, $00, $02, $08, $05, $05, $0d, $0d
                                          .byte $00, $09, $02, $08, $05, $05, $0d, $0d
                                          .byte $00, $09, $02, $08, $05, $05, $0d, $0d
                                          .byte $09, $09, $02, $08, $05, $05, $0d, $0d
                                          .byte $09, $09, $02, $08, $05, $05, $0d, $0d
//----------------------------------------------------------------------
                                          .align $100
                                          .memblock "Spectrometer Tables"
FreqTableLookupHilsb:                     // SID Frequency lsb/msb lookup tables
.for (var i = 0; i < 16; i++)
{
                                          .byte <FreqTablePalHi+(i*6)
}
//--------------
FreqTableLookupHimsb:
.for (var i = 0; i < 16; i++)
{
                                          .byte >FreqTablePalHi+(i*6)
}
//--------------
FreqTableLookupLolsb:
.for (var i = 0; i < 16; i++)
{
                                          .byte <FreqTablePalLo+(i*6)
}
//--------------
FreqTableLookupLomsb:
.for (var i = 0; i < 16; i++)
{
                                          .byte >FreqTablePalLo+(i*6)
}
//--------------
temp:                                     .byte 0
NoteLo:                                   .byte 0
NoteHi:                                   .byte 0
Delta:                                    .byte 4,2,1,0
//--------------
                                          // Quick'n'dirty 180degree + 90degree drop sine.
SoundbarSine:
                                          .byte 0,2,4,5,6,6,5,4,2,0,2,4,6,8,9,10,11,12,13,14,14,15
//--------------
                                          .align $100
FreqTablePalLo:
                                          .byte $17,$27,$39,$4b,$5f,$74,$8a,$a1,$ba,$d4,$f0,$0e  // Shortened frequency table, because I don't need full granularity.
                                          .byte $2d,$4e,$71,$96,$be,$e8,$14,$43,$74,$a9,$e1,$1c  // 2
                                          .byte $5a,$9c,$e2,$2d,$7c,$cf,$28,$85,$e8,$52,$c1,$37  // 3
                                          .byte $b4,$39,$c5,$5a,$f7,$9e,$4f,$0a,$d1,$a3,$82,$6e  // 4
                                          .byte $68,$71,$8a,$b3,$ee,$3c,$9e,$15,$a2,$46,$04,$dc  // 5
                                          .byte $d0,$e2,$14,$67,$dd,$79,$3c,$29,$44,$8d,$08,$b8  // 6
                                          .byte $a1,$c5,$28,$cd,$ba,$f1,$78,$53,$87,$1a,$10,$71  // 7
                                          .byte $42,$89,$4f,$9b,$74,$e2,$f0,$a6,$0e,$33,$20,$ff  // 8
//--------------
FreqTablePalHi:
                                          .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02  // 1
                                          .byte $02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04  // 2
                                          .byte $04,$04,$04,$05,$05,$05,$06,$06,$06,$07,$07,$08  // 3
                                          .byte $08,$09,$09,$0a,$0a,$0b,$0c,$0d,$0d,$0e,$0f,$10  // 4
                                          .byte $11,$12,$13,$14,$15,$17,$18,$1a,$1b,$1d,$1f,$20  // 5
                                          .byte $22,$24,$27,$29,$2b,$2e,$31,$34,$37,$3a,$3e,$41  // 6
                                          .byte $45,$49,$4e,$52,$57,$5c,$62,$68,$6e,$75,$7c,$83  // 7
                                          .byte $8b,$93,$9c,$a5,$af,$b9,$c4,$d0,$dd,$ea,$f8,$ff  // 8

                                          .byte 0,0
//--------------
                                          .align $100
                                          .pc = * "dBMeterValue"
dBMeterValue:
                                          .fill 16,0
                                           .byte 0,0
//--------------
                                          .pc = * "MeterTemp"
MeterTemp:
                                          .fill 16,0
                                          .byte 0,0
//----------------------------------------------------------------------
                                          .align $100
                                          .memblock "SinusBouncingBar"
SinusBouncingBar:
.fill listSinusBouncingBar.size(), listSinusBouncingBar.get(i)
//----------------------------------------------------------------------
                                          .align $100
                                          .memblock "SinusY"
SinusY:
.fill listSinusY.size(), listSinusY.get(i) + $32
//----------------------------------------------------------------------
                                          .align $100
                                          .memblock "SinusX"
SinusX:
.fill listSinusX.size(), listSinusX.get(i) + $18
//----------------------------------------------------------------------
//----------------------------------------------------------------------