hud_init:
{
				ldx #119 
			!:	lda #9
				sta $d800,x
				lda #1
				sta $4400,x
				dex
				bpl !-
				
				ldx #10
				lda #8
			!:
				sta $d800,x
				sta $d800 + 40,x
				dex
				bne !-
					
				rts
}



//adds X to the score, with x = 100 to 900 in steps of 100. 
//load A with X/100
add_score_x:
{
			ldx #3
			jmp add_score_50.opt
}

//load A with the score to be added div 10. (all possible scores are multiple of 10)
add_score_50:
{
			lda #5
			ldx #4 //back_counter on digits
	opt:
			ldy #0 //flag for extralives
		!:	clc
			adc score,x
			sta score,x
			cmp #$0a
			bcc !done+
			sbc #$0a
			sta score,x
			lda #1
			cpx #2
			bne !skp+
			
			iny

		!skp:	
			dex 
			bpl !- 
		//overflow!
			lda #9
			sta score
			sta score + 1
			sta score + 2
			sta score + 3
			sta score + 4
			sta score + 5
			
		!done:
			
			cpy #0
			beq !skp+
		
			lda lives
			cmp #6
			bcs !skp+
			inc lives
			jsr put_lives
		!skp:	
			//jmp put_score  //it's up next anyway 
}


put_score:
{
			
				ldx #0
				ldy #0
				
			!:	
				lda score,x
				asl	//also clears carry, because score digits are < 128
				adc #2
				sta $4400 + 40 + 2 + 25,y 
				iny
				adc #1
				sta $4400 + 40 + 2 + 25,y
				iny
				inx
				cpx #6 //this will also clear the carry
				bne !-
				
				rts
				
}


			
put_lives:
{
				lda lives
				sec
				sbc #1
				asl
				sta p0tmp
				
				ldx #0
			!:
				cpx p0tmp 
				beq !next+
						
				lda #HEAD_CHARS
				sta $4400 + 00 + 1,x
				lda #HEAD_CHARS + 1
				sta $4400 + 40 + 1,x
				
				lda #HEAD_CHARS + 2
				sta $4400 + 00 + 2,x
				lda #HEAD_CHARS + 3
				sta $4400 + 40 + 2,x
			
				inx
				inx
				
				jmp !-
			
			!next:
				
				lda #1	
				
			!:	cpx #10
				beq !next+
					
				sta $4400 + 00 + 1,x
				sta $4400 + 40 + 1,x
				sta $4400 + 00 + 2,x
				sta $4400 + 40 + 2,x
				inx
				inx
				jmp !-
					
			!next:
				
				rts
}
			

put_level:
{
				lda #[level_sprite & $3fff] / 64
				sta irq_00.sworlv + 1
				
				ldx gamelevel
				lda lvth,x
				
				asl	//clears the carry as this is < 128
				adc #2
				sta $4400 + 40 + 18
				adc #1
				sta $4400 + 40 + 19
				
				lda lvtl,x
				asl	//clears the carry as this is < 128
				adc #2
				sta $4400 + 40 + 20
				adc #1
				sta $4400 + 40 + 21
				 
				rts
	
//it might seem overkill to waste 200 bytes just for this, but it'll be compressed quite well in the end
lvth:
.fill 100, i / 10

lvtl:
.fill 100, mod(i,10)				
}

timer:
{
init:			lda #127
				sta timer_value + 2
				lda #0
				sta timer_value + 1
				lda #5
				sta timer_value + 0	
				
				rts
				
tick:		
				lda timer_value
				bpl !skp+
				rts
				
			!skp:	

				dec timer_value + 2
				bmi !underflow+
				
				lda timer_value 
				bne !skp+
				
				//if less than 10 seconds, we must blink
				lda timer_value + 2
				and #31
				tax
				lda mcgradient,x
				sta $d800 + 40 + 18
				sta $d800 + 40 + 19
				sta $d800 + 40 + 20
				sta $d800 + 40 + 21
				rts
				
				 
			!underflow:		
				lda #127
				sta timer_value + 2
				
				dec timer_value + 1
				bpl update
				
				lda #9
				sta timer_value + 1
				dec timer_value + 0
				bpl update
				
				// timer_value <0 means time is up. We check this elsewhere, we just don't update the screen
								
			!skp:
				rts
				
update:
				lda #[stopwatch_sprite & $3fff] / 64
				sta irq_00.sworlv + 1

				lda timer_value
				bpl !skp+
				
				lda #0
				sta timer_value + 1
			!skp:	
				asl	//clears the carry as this is < 128
				adc #2
				sta $4400 + 40 + 18
				adc #1
				sta $4400 + 40 + 19
				
				lda timer_value + 1
				asl	//clears the carry as this is < 128
				adc #2
				sta $4400 + 40 + 20
				adc #1
				sta $4400 + 40 + 21
								
				rts
				
				
.const mcgradientlist = List().add($00+8, $02+8, $04+8,$04+4, $05+8,$05+8, $03+8,$03+8,$03+8, $07+8,$07+8,$07+8,$07+8, $01+8,$01+8,$01+8,$01+8)
mcgradient:

.fill 15,mcgradientlist.get(15-i)
.fill 17,mcgradientlist.get(i)								
}			
