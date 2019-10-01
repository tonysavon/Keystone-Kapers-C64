showpic:
{
				jsr vsync
				lda #$0b
				sta $d011
				
				lda #$00
				sta $d020
				sta $d021
				
				lda #$00
				sta $dd00
				lda #%10000000
				sta $d018
				lda #$d8
				sta $d016
				
				ldx #0
			!:
				.for (var i = 0; i < 4; i++)
				{
					lda $b800 + $100 * i,x
					sta $d800 + $100 * i,x
				}
				inx
				bne !-
				
				jsr vsync
				lda #$3b
				sta $d011
				
				rts
}


splash:
{
				lda #0
				jsr sid.init

				sei

				lda #0
				sta $d021
				sta $d015
				sta button
				
				lda #$0f
				sta $d418
				
				ldx #39
			!:  lda #0	
				sta $d800 + 16 * 40,x
				lda #$0f
				.for (var i = 0; i < 8; i++)
				sta $d800 + (17 + i) * 40,x
				dex
				bpl !- 			
				
				lda #$c8
				sta $d016
			
			loop:
	
				jsr vsync
				jsr random_
				jsr sid.play
	
				lda #1
				sta $dd00
				lda #%11011000
				sta $d018
				lda #$3b
				sta $d011
				
				lda #180
			!:	cmp $d012
				bcs !-
				
				lda #3
				sta $dd00
				lda #$1b
				sta $d011
				lda #%11010110
				sta $d018
	//			inc $d020

				lda $dc00
				sta joy
	
				jsr select_level
							
	
				lda button
				cmp #2
				bcs !exit+
				cmp #0
				beq waitrelease
				cmp #1
				bne !next+
				beq waitpush
				
			!next:			

				jmp loop				
				
				
			!exit:
				lda #1
				//jsr sid.init
				rts
				
			waitpush:
				lda #%00010000
				bit joy
				bne !skp+
				inc button
			!skp:
				jmp loop
				
			waitrelease:
				lda #%00010000
				bit joy
				beq !skp+
				inc button
			!skp:
				jmp loop
				
				
	select_level:
	{
				//print the level anyway
				ldx #'0'
				lda menulevel
				cmp #10
				bcc !singledigit+
				sbc #10
				ldx #'1'
				clc
			!singledigit:	
				adc #'0'
				sta $3400 + 23 * 40 + 38
				stx $3400 + 23 * 40 + 37
	
				lda menulevel
				sec
				sbc #1
				lsr
				lsr
				tax 
				lda dcol,x
				sta $d800 + 23 * 40 + 38
				sta $d800 + 23 * 40 + 37
				
				lda jtimer
				beq !skp+
				
				dec jtimer
				
				rts	
				
			!skp:
			
				lda #%00000001
				bit joy
				beq !incl+
				asl
				bit joy
				beq !decl+
				rts
				
			!incl:
			
				lda menulevel
				cmp #16
				bcs !done+
				inc menulevel
				lda #10
				sta jtimer
			!done:	
				rts
				
			!decl:
				lda menulevel
				cmp #2
				bcc !done-
				dec menulevel
				lda #10
				sta jtimer
				rts	
				
					
				
	}								
				
button:
.byte 0
joy:
.byte 0
jtimer:
.byte 0

dcol:
.byte 13,7,8,2
}				

