.label OBJECT_NULL		= 0
.label OBJECT_CASE		= 1
.label OBJECT_GOLD		= 2
.label OBJECT_RADIO		= 3
.label OBJECT_BALL		= 4
.label OBJECT_TROLLEY	= 5
.label OBJECT_PLANE		= 6

//this doesn't have an ID. It's just the robber
robber:
{
		init:
				lda #2
				sta robberfloor
				lda #3
				sta robberroom
				lda #148
				sta robberxl
				lda #0
				sta robberxh
				sta robberframe
				sta robberxdir
				
				rts
				
				
		update:
		
				
			!ok:
				
				inc robberframe
				lda robberframe
				cmp #5*4
				bne !skp+
	
				lda #0
				sta robberframe
							
			!skp:

			
				//if we are at the same floor of the cop, if we are running towards him, let's switch direction
				
				lda robberfloor
				cmp copfloor
				bne !next+
			
			
				lda robberroom
				cmp currentroom
				
				beq !fine+
				
				lda #00
				rol
				cmp robberxdir
				bne !next+
				jmp !swdir+
					
			!fine:	
				lda robberxh
				lsr
				lda robberxl
				ror
				
				cmp copx
				lda #00
				rol
				cmp robberxdir
				bne !next+
			!swdir:	
				lda robberxdir
				eor #1
				sta robberxdir
				
				
			!next:
			
				lda robberxdir
				beq !right+
				
			//left
				lda #12
				sta p0tmp
				lda robberroom
				bne !skp+
			
				lda #3
				sta p0tmp
				
			!skp:	
				lda robberxl
				sec
				sbc #1
				sta robberxl
				lda robberxh
				sbc #0
				sta robberxh
				
				lsr 
				lda robberxl
				ror
				
				cmp p0tmp
				bcs !next+
				
				lda robberroom
				bne !switch+
				
				lda #0
				sta robberxdir
				
				lda robberfloor
				beq !incf+
				
				cmp #3
				beq !decf+
				
				cmp copfloor
				bcc !decf+
				beq !decf+
				
			!incf:
				inc robberfloor
				jmp !next+
				
			!decf:
				
				dec robberfloor
				jmp !next+
				
				
			!switch:
				dec robberroom
				lda #<332
				sta robberxl
				lda #>332
				sta robberxh
				jmp !next+	
				
				
			!right:
				lda #328 / 2 //-1
				sta p0tmp
				lda robberroom
				cmp #7
				bne !skp+
				
				lda #338 / 2
				sta p0tmp
				
			!skp:
				lda robberxl
				clc
				adc #1
				sta robberxl
				lda robberxh
				adc #0
				sta robberxh
				
				lsr 
				lda robberxl
				ror
				
				cmp p0tmp
				bcc !next+
				
				lda robberroom
				cmp #7
				bcc !switch+
				
				lda #1
				sta robberxdir
				
				lda robberfloor
				beq !incf+
				
				cmp #3
				beq !decf+
				
				cmp copfloor
				bcc !decf+
				beq !decf+
				
			!incf:
				inc robberfloor
				jmp !next+
				
			!decf:
				
				dec robberfloor
				jmp !next+
				
			!switch:
				inc robberroom
				lda #08
				sta robberxl
				lda #0
				sta robberxh
				jmp !next+		
				
				
			!next:
			
				rts

test_caught:
{

				lda robberfloor
				cmp copfloor
				beq !+
				
				lda #$00
				rts
				
			!:	
				lda robberroom
				cmp currentroom
				beq !+
			
				lda #$00
				rts
			!:	
		
				lda robberxh
				lsr
				lda robberxl
				ror
				
				clc
				adc #8
				cmp copx
				bcc !nohit+
				sec
				sbc #20
				cmp copx
				bcs !nohit+
				//hit
				lda #1
				rts
				
			!nohit:
				lda #0
				rts	
				
				
					
			
}						

robberframe:
		.byte 0				
}


clear_object:
{
				lda #0
				sta object_list.type,y
				ldx timesstride,y
				
				lda #[empty_sprite & $3fff] / 64
				sta sprf,x
				sta sprf + 1,x
				sta sprf + 2,x
				
				lda #0
				sta spry,x
				sta spry + 1,x
				sta spry + 2,x
				rts
}

//deploys an object. Load y with floor (0-3), accumulator with type
//the x position will be assigned taking into account the gamelevel number, player position. 
//multiple objects will be deployed and num updated accordingly, depending on the gamelevel number.
//each level can only have one type of object (although this ovrengineered engine could handle multiple object typs on the same floot 
deploy_object: 
{
				
				sty savey + 1
				
				ldx timesstride,y
				// now contains the idx of the object on that floor, in a way that addressing sprxl,x targets the right sprites
		
				sta object_list.type,y
				
				//now position it (them) according to object type
				cmp #OBJECT_CASE
				bne !tobj+				
				
				//it's a case. Just one and central, unless we have already deployed it
				tya
				asl
				asl
				asl
				clc
				adc currentroom
				tax
				lda item_collected,x
				beq !ok+ // we can deploy
				lda #OBJECT_RADIO
				jmp deploy_object				
			!ok:
				ldx timesstride,y
				lda #[case_sprite & $3fff] / 64
				sta sprf,x
				
				lda #8
				sta sprc,x
				
			!opt:	
				lda #1
				sta object_list.num,y
				
				lda #160 + 12
				sta sprxl,x
				
				lda environment.elevator_y - 1,y
				sta spry,x	
					
				jmp !next+
					
			!tobj:	
				
				cmp #OBJECT_GOLD
				bne !tobj+
				
				//it's gold. Just one and central, unless we have already deployed it
				tya
				asl
				asl
				asl
				clc
				adc currentroom
				tax
				lda item_collected,x
				beq !ok+ // we can deploy
				lda #OBJECT_RADIO
				jmp deploy_object				
			!ok:
				ldx timesstride,y
				
				lda #[gold_sprite & $3fff] / 64
				sta sprf,x
				
				lda #7
				sta sprc,x
				
				jmp !opt-
			
			!tobj:	
				
				cmp #OBJECT_RADIO
				bne !tobj+
		
				lda #1
				sta sprc,x
					
				//if level < 6: one radio, 6-9: two radios, >= 10: three radios, unless it's room 3 (two radios)
				
				lda gamelevel
				cmp #6
				bcc !oneradio+
				cmp #10
				bcc !tworadios+
				
			!threeradios:
				lda currentroom
				cmp #3
				beq !tworadios+
			
				lda #160 + 12 - 64
				sta sprxl,x
				lda #160 + 12
				sta sprxl + 1,x
				lda #160 + 12 + 64
				sta sprxl + 2,x
				
				lda environment.elevator_y - 1,y
				sta spry,x
				sta spry + 1,x
				sta spry + 2,x
				
				lda #3
				sta object_list.num,y
				jmp !next+	
			
			!tworadios:
				lda #160 + 12 - 64
				sta sprxl,x
				lda #160 + 12 + 64
				sta sprxl + 1,x
				
				lda environment.elevator_y - 1,y
				sta spry,x
				sta spry + 1,x
				
				lda #2
				sta object_list.num,y
				jmp !next+	
			
			!oneradio:

		
				jmp !opt-
				
				
			!tobj:
				cmp #OBJECT_BALL
				bne !tobj+
				
				lda #1
				sta object_list.num,y
				
				lda #32
				sta sprxl,x
				
				//place the ball on the opposite side of the screen with respect to the player
				lda #0	
				bit copx
				bmi !right+
				
				lda #1
			!right:	
				sta sprxh,x
				sta object_list.dir,y
				
				lda #2
				sta sprc,x
				
				lda environment.elevator_y - 1,y
				sta spry,x
				
				lda #1
				sta object_list.num,y
				
				jmp !skp+
				
	
			
			!skp:	
				//balls come in pairs (ahem....) when level >= 10
				lda gamelevel
				cmp #10
				bcs !pair+
				jmp !next+
				
			!pair:	
				//add an additional ball in the center
				
				lda #160 + 32//+ 0
				sta sprxl + 1,x
				
				lda #2
				sta object_list.num,y
				jmp !next+
				
		!tobj:
				cmp #OBJECT_TROLLEY
				beq !tro+
				jmp !tobj+
			!tro:
				//it's trolley/
				
				lda #1
				sta sprc,x
				
				lda gamelevel
				cmp #7
				bcs !skp+
				// < 7
				lda #2
				sta object_list.speed,y
				lda #1
				sta object_list.num,y
				jmp !dir+
			!skp:	
				cmp #11
				bcs !skp+
				//7<=l<11
				lda #4
				sta object_list.speed,y
				lda #1
				sta object_list.num,y
				jmp !dir+
			!skp:	
				cmp #16
				bcs !skp+
				//11<=l<15
				lda #2
				sta object_list.speed,y
				sta object_list.num,y
				jmp !dir+
			!skp:
				//l>=16
				lda #8
				sta object_list.speed,y
				lda #1
				sta object_list.num,y	
				//jmp !dir+
			!dir:
				
				lda gamelevel
				cmp #7
				bcs !random+	
				
				bit copx
				bmi !right+
			!left:
			
				lda #1
				sta object_list.dir,y
				
				lda #<[320 - 32]
				sta sprxl,x
				lda #>[320 - 32]
				sta sprxh,x
				
				lda object_list.num,y
				cmp #2
				bcs !l2+
				jmp !next+
				!l2:
				lda #<[320 - 32 - 128]
				sta sprxl + 1,x
				lda #>[320 - 32 - 128]
				sta sprxh + 1,x
				jmp !next+
					
			!right:
				lda #0
				sta object_list.dir,y
				
				lda #56
				sta sprxl,x
				lda #0
				sta sprxh,x
				
				lda object_list.num,y
				cmp #2
				bcs !r2+
				jmp !next+
				!r2:
				lda #56 + 128
				sta sprxl + 1,x
				lda #0
				sta sprxh + 1,x
				jmp !next+
				
			!random:
			
				lda random_.random,y
				lsr
				bcs !left-
				jmp !right-			
				
	
		!tobj:		
				//then it's a plane!
				sta object_list.type,y
				lda #1
				sta object_list.num,y //always one plane
				lda #7
				sta sprc,x
				
				lda gamelevel
				cmp #8
				bcs !skp+ 
				lda #2
				sta object_list.speed,y
				jmp !dir+
			!skp:
				cmp #12
				bcs !skp+
				lda #4
				sta object_list.speed,y
				jmp !dir+
			!skp:
				cmp #16
				bcs !skp+
				lda #6
				sta object_list.speed,y
				jmp !dir+
			!skp:	
				lda #8
				sta object_list.speed,y
						
			!dir:
				lda gamelevel
				cmp #8
				bcs !random+	
				
				bit copx
				bmi !right+
			!left:
				lda #<[320-24]
				sta sprxl,x
				lda #>[320-25]
				sta sprxh,x
				lda #1
				sta object_list.dir,y
				jmp !next+	
				
			!right:
				lda #48
				sta sprxl,x
				lda #0
				sta sprxh,x
				sta object_list.dir,y
				jmp !next+
				
			!random:
				lda random_.random,y
				lsr
				bcs !left-
				jmp !right-	
				
				
		!next:		
				
		savey:	ldy #0
				rts
				
			
}


balljumppath:
.fill 64, 10 * sin(PI * i / 64.0) - 4
balljumppath_hi:
.fill 64, 21 * sqrt(sin(PI * i / 64.0)) - 4

timesstride:
.fill 4, STRIDE * i
//not all objects use all the properties	

object_list:
{
		type:
		.fill 4,0
		dir:
		.fill 4,0
		speed:
		.fill 4,0
		num:
		.fill 4,0
}
end_object_list:

