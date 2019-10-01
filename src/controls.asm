controls:
{

				lda $dc00
				
				jsr readjoy
				lda #$00
				rol
				sta fire
		
				
				//if it's jumping or on escalator, we can't control!
				lda #STATUS_JUMPING | STATUS_ESCALATOR	
				bit cop.status
				beq !ok+
				jmp !done+
			!ok:			
			
				//if it's in elevator, the only thing we can control is coming out of it
				lda #STATUS_ELEVATOR
				bit cop.status
				beq !noelevator+
				cpy #1
				beq !testexit+
				jmp !done+
			!testexit:	
				ldy environment.elevator_level
				
				//right time?
				lda environment.elevator_clock
				cmp #5
				bcc !noexit+
				
				cmp environment.elevator_startclosing,y
				bcs !noexit+
				
				lda cop.status
				and #[$ff - STATUS_ELEVATOR]
				sta cop.status
				
				lda #$00
				sta $d01b
				sta prioritylevel0 + 1
				sta prioritylevel1 + 1
				sta prioritylevel2 + 1
				
			!noexit:
				jmp !done+		
			
			!noelevator:
				//first check y
				
				//check if we can enter elevator
				cpy #$ff
				bne !test_duck+
				
				lda currentroom
				cmp #3
				bne !testx+
				
				ldy environment.elevator_level
				lda copy
				cmp environment.elevator_y,y //are we at the right level?
				bne !testx+
			
				//right time?
				lda environment.elevator_clock
				cmp #5
				bcc !testx+
				
				cmp environment.elevator_startclosing,y
				bcs !testx+
				
				//right position?
				lda copx
				cmp #$a8 / 2
				bcc !testx+
				cmp #$b2 / 2
				bcs !testx+
				
				//enter elevator!
				lda cop.status
				and #STATUS_DIRECTION //only preserve the direction flag
				ora #STATUS_ELEVATOR
				sta cop.status
				
				lda #$ac / 2
				sta copx
				
				lda #%11000000
				sta $d01b
				sta prioritylevel0 + 1
				sta prioritylevel1 + 1
				sta prioritylevel2 + 1
				
				//speed up elevator if we are not about to close anyway
				lda environment.elevator_startclosing,y
				sec
				sbc #24
				cmp environment.elevator_clock
				bcc !skp+
				sta environment.elevator_clock
				
			!skp:	
				jmp !done+
				
					
			!test_duck:	
				lda cop.status
				and #[$ff - STATUS_DUCKING]
				cpy #$01
				bne !skp+
				
				//wants to duck
				ora #STATUS_DUCKING
			!skp:
				sta cop.status
				
				
			!testx:	
				cpx #1
				beq !wantsright+
				cpx #$ff
				beq !wantsleft+
				
				 
				//horizontally still
				lda cop.status
				and #($ff - STATUS_MOVING)
				sta cop.status
		
				jmp !next+
				
		!wantsright:
				lda cop.status
				and #($ff - STATUS_DIRECTION)
				sta cop.status
				and #STATUS_MOVING
				bne !skp+
				
				lda #0
				sta cop.walkframe
			!skp:
				lda cop.status
				ora #STATUS_MOVING
				sta cop.status	 		
			
				jmp !next+

		!wantsleft:
				lda cop.status
				ora #STATUS_DIRECTION
				sta cop.status
				and #STATUS_MOVING
				bne !skp+
				
				lda #0
				sta cop.walkframe
			!skp:
				lda cop.status
				ora #STATUS_MOVING
				sta cop.status
				 		
			
				jmp !next+				
				
		!next:
		
				lda fire
				bne !next+
			
				lda #STATUS_JUMPING | STATUS_DUCKING | STATUS_ELEVATOR | STATUS_ESCALATOR
				bit cop.status
				bne !next+
					
				lda #STATUS_JUMPING
				ora cop.status
				sta cop.status
				
				lda #0
				sta cop.jumpclock
				
				:sfx(SFX_JUMP)
				
				jmp !next+
				
		!next:		
		!done:	
				rts		

fire:
.byte 0
}
			

readjoy:
{
		
		djrrb:	ldy #0        
				ldx #0       
				lsr           
				bcs djr0      
				dey          
		djr0:	lsr           
				bcs djr1      
				iny           
		djr1:	lsr           
				bcs djr2      
				dex           
		djr2:	lsr           
				bcs djr3      
				inx           
		djr3:	lsr           
				rts
}					