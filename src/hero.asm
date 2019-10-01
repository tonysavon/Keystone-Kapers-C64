.label STATUS_MOVING	= %00000001
.label STATUS_DIRECTION = %00000010
.label STATUS_JUMPING	= %00000100
.label STATUS_DUCKING	= %00001000
.label STATUS_ELEVATOR  = %00100000
.label STATUS_ESCALATOR = %01000000


cop:
{
			init:
				
				lda #0
				sta ld01e
				sta ld01e + 1
				sta ld01e + 2
				sta ld01e + 3
				
				sta jumpclock
				
				jsr timer.init		

				jsr timer.update
				
				ldx #3
				stx copfloor
			
				lda #148
				sta copx
				lda environment.elevator_y - 1,x
				sta copy
				lda #[cop_sprites & $3fff] / 64 + 24
				sta copf
				lda #STATUS_DIRECTION
				sta status
				
				ldx #7
				stx currentroom
				jsr set_room
							
				rts
				
				
			update:
			
				lda cop.status
				and #STATUS_JUMPING
				beq !nojump+
				//jumps. Check if it's the still jump or the move jump
				lda #STATUS_MOVING
				bit cop.status
				beq !jumpnomoves+
				
				lda #STATUS_DIRECTION
				bit cop.status
				beq !movesright+
			
			!movesleft:
				dec copx
				jmp !skp+
			!movesright:
				inc copx
			!skp:	
				
				
			!jumpnomoves:

				ldx #[cop_sprites & $3fff] / 64 + 3
				lda cop.jumpclock
				cmp #6
				bcc !skp+
				inx
				cmp #24
				bcc !skp+
				inx
			!skp:	
				stx copf
						
				inc cop.jumpclock
				lda cop.jumpclock
				cmp #32
				bne !skp+
				lda cop.status
				and #[$ff - STATUS_JUMPING]
				sta cop.status
				lda #0
				sta cop.jumpclock
				sta cop.walkframe
				
			!skp:
				jmp !updatedone+
				
			!nojump:
				lda cop.status
				and #STATUS_DUCKING
				beq !noduck+
				
				lda #[cop_sprites & $3fff] / 64 + 11
				sta copf
				jmp !updatedone+
				
			
			
			!noduck:
				lda cop.status
				and #STATUS_MOVING
				bne !moves+
				
				
				//still
				lda #[cop_sprites & $3fff] / 64 
				sta copf
				
				jmp !updatedone+
				
			!moves:	
				//walking
				
				lda #STATUS_DIRECTION
				bit cop.status
				beq !movesright+
			
			!movesleft:
				dec copx
				jmp !skp+
			!movesright:
				inc copx
			!skp:	
				inc cop.walkframe
				lda cop.walkframe
				cmp #10
				beq !sf+
				cmp #20
				bne !skp+
				lda #0
				sta cop.walkframe
			!sf:	
				lda music_on
				bne !skp+
				
				:sfx(SFX_FOOTSTEP) //the footstep effect is overkill with the music on. We just don't play it
				
			!skp:
				lda walkframe
				lsr
				//lsr
				clc
				adc #[cop_sprites & $3fff] / 64 + 1
				sta copf
				
				jmp !updatedone+
			
			
			!updatedone:
			
				lda status
				anc #STATUS_DIRECTION
				beq !skp+
				
				lda copf
				adc #24
				sta copf 
				
			!skp:
			
				//check if we changed screen
				lda copx
				cmp #8
				bcs !ok+
				
				lda currentroom
				bne !switchroom+
				inc copx
				jmp !ok+
				
			!switchroom:	
				//room left
				dec currentroom
				lda #328/2 - 2
				sta copx
				jsr set_room
				
			!ok:	
				
				lda copx
				cmp #328/2 - 1
				bcc !ok+
				
				lda currentroom
				cmp #7
				bcc !switchroom+
				dec copx
				jmp !ok+
				
			!switchroom:	
				inc currentroom
				lda #8 + 1
				sta copx
				jsr set_room
				
				
			!ok:
			
				rts	
status:
.byte 0			

walkframe: //0 to 10
.byte 0	

jumpclock:
.byte 0

jumppath:
.fill 32 ,9.9 * sqrt(sin(PI * i / 32.0))


}