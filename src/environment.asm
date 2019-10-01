environment:
{

	init:
	{			lda #7
				sta elevator_qtick
				lda random_.random
				and #126 //0 to 126 in 2 steps
				sta elevator_clock
				lda random_.random
				and #1
				sta elevator_level //randomly center of top floor.
				beq !topf+
			
				//central floor. Let's give it a random direction
				lda random_.random + 1
				and #1
				sta elevator_dir
				jmp !done+
				
			!topf:
				lda #1 //going down
				sta elevator_dir
			!done:
				
				rts
	}
			
		
	update:
	{			
				//elevator logic
				
			!next:	
				//in case the cop is in the elevator, we must speed it up.
				lda #STATUS_ELEVATOR
				bit cop.status
				beq !next+
				lda elevator_clock
				cmp #6
				bcc !next+

				ldx elevator_level
				lda elevator_startclosing,x
				sec
				sbc #24
				cmp elevator_clock
				bcc !next+
				sta elevator_clock		
	
	!next:
				
				
				dec elevator_qtick
				bpl !next+
				lda #7
				sta elevator_qtick
			
				inc elevator_clock
			
				// if level > 8 and cop is at the same level of the elevator
				// and he is not inside the elevator, and the elevator is in state "open"
				// then the clock runs twice as fast.
				lda gamelevel
				cmp #8
				bcc !skp+
				lda #STATUS_ELEVATOR
				bit cop.status
				bne !skp+
				lda copfloor
				sec
				sbc #1
				cmp elevator_level
				bne !skp+
				lda elevator_clock
				cmp #6
				bcc !skp+
				cmp elevator_startclosing,x
				bcs !skp+
				
				inc elevator_clock
				
			!skp:	
					
				lda elevator_clock
				ldx elevator_level
				cmp elevator_cap,x
				bcc !next+

				lda #0	
				sta elevator_clock
	
				:sfx(SFX_LIFT)
				
				lda elevator_level
				bne !skp+
				inc elevator_level
				jmp !next+
			!skp:
				cmp #2
				bne !skp+
				dec elevator_level
				jmp !next+	
			!skp:	 
				lda elevator_dir
				beq !godown+
				dec elevator_level
				jmp !eorandexit+
			!godown:
				inc elevator_level
			!eorandexit:
				eor #1
				sta elevator_dir
				jmp !next+
				
	!next:	
				
	
	roomcode:	jsr the_rts
	
				//move all the actors
				
				ldy #0 //loops on floors
			!objloop:
				ldx timesstride,y	
				lda object_list.type,y
				
				cmp #OBJECT_RADIO 
				bcs !skp+
				jmp !nextfloor+ //gold and case don't move
			!skp:	
				bne !tobj+	
				
				//it's one or more radios
				txa
				clc
				adc object_list.num,y
				sta p0tmp
				
				lda clock
				lsr
				lsr
				lsr
				anc #1
				adc #[radio_sprites & $3fff] / 64
				
			!:	
				sta sprf,x	 
				inx
				cpx p0tmp
				bne !-
				
				jmp !nextfloor+
				
			!tobj:	
				cmp #OBJECT_BALL
				bne !tobj+
			
				jsr move_balls
				jmp !nextfloor+
				
			!tobj:
				cmp #OBJECT_PLANE
				bne !tobj+
				
				//It's a bird. It's a plane. IT'S SUPERMA... no, it's a plane.
				jsr move_plane		
				jmp !nextfloor+
					
			!tobj:
				//it can only be a trolley	
				jsr move_trolley
				
			!nextfloor:
				iny
				cpy #4
				beq !done+
				jmp !objloop-
			
			!done:		
				rts
	
			
	}		

	
	move_trolley:
	{
	
				txa
				clc
				adc object_list.num,y
				sta p0tmp

				lda object_list.speed,y
				sta p0tmp + 1	//store it here, because we can't do adc addr,y
		!obl:
				lda environment.elevator_y -1,y
				sta spry,x
		
				
				lda clock
				lsr
				lsr
				anc #1
				adc #[trolley_sprites & $3fff] / 64
				sta sprf,x
				
				lda object_list.dir,y
				beq !skp+
				
				lda sprf,x
				adc #2
				sta sprf,x
				
			!skp:
		
				
				lda object_list.dir,y
				beq !right+
			
				
			!left:
				lda sprxl,x
				sec
				sbc p0tmp + 1
				sta sprxl,x
				lda sprxh,x
				sbc #0
				sta sprxh,x
				bcs !done+
				lda #<[320 + 24]
				sta sprxl,x
				lda #>[320 + 24]
				sta sprxh,x
				jmp !done+
				
			!right:
				lda sprxl,x
				clc
				adc p0tmp + 1
				sta sprxl,x
				lda sprxh,x
				adc #0
				sta sprxh,x
				lsr
				lda sprxl,x
				ror
				cmp #[320 + 48] / 2
				bcc !done+ 
				lda #0
				sta sprxl,x
				sta sprxh,x
			!done:
				
				inx
				cpx p0tmp
				bne !obl-		
				rts
				
	}
	
	move_plane:
	{
	
				lda object_list.speed,y
				sta p0tmp + 1	//store it here, because we can't do adc addr,y

				lda environment.elevator_y -1,y
				sec
				sbc #5
				sta spry,x
				
			!anim:	
			
				lda plane_frame
				clc
				adc #1
				cmp #6
				bcc !skp+
				lda #0
			!skp:	
				sta plane_frame
				lsr
				clc
				adc #[plane_sprites & $3fff] / 64
				sta sprf,x
				lda object_list.dir,y
				beq !skp+
				lda sprf,x
				clc
				adc #3
				sta sprf,x
			!skp:		
			move:	
					
				lda object_list.dir,y
				beq !right+
			
				
			!left:
				lda sprxl,x
				sec
				sbc p0tmp + 1
				sta sprxl,x
				lda sprxh,x
				sbc #0
				sta sprxh,x
				bcs !next+
				lda #<[320 + 24]
				sta sprxl,x
				lda #>[320 + 24]
				sta sprxh,x
				jmp !next+
				
			!right:
				lda sprxl,x
				clc
				adc p0tmp + 1
				sta sprxl,x
				lda sprxh,x
				adc #0
				sta sprxh,x
				lsr
				lda sprxl,x
				ror
				cmp #[320 + 48] / 2
				bcc !next+ 
				lda #0
				sta sprxl,x
				sta sprxh,x
			!next:
			
				cpy copfloor
				bne !done+
				
				sty svy+1
			
				lda p0tmp + 1 //this is the speed 
				
				sec
				sbc #1
				lsr
				eor #$ff
				sta p0tmp + 1 //this mask now is a rounding mask
				
					
				lda sprxh,x
				lsr
				lda sprxl,x
				ror
				and p0tmp + 1
				sta cp + 1
				lda copx
				and p0tmp + 1
			cp: cmp #$00
				bne !done+
			
				:sfx(SFX_PLANE)
		svy:	ldy #0
			
			!done:
				rts
	plane_frame:
	.byte 0				
	}
	
	move_balls:
	{
				txa
				clc
				adc object_list.num,y
				sta p0tmp
				
				lda object_list.dir,y
				beq !right+
				
			!left:
				lda sprxl,x
				sec
				sbc #1
				sta sprxl,x
				lda sprxh,x
				sbc #0
				sta sprxh,x
				bpl !nound+
				
				lda #1
				sta sprxh,x
				lda #128
				sta sprxl,x
				
			!nound:	
			
				jsr update_ball_y_and_f
							
				inx
				cpx p0tmp
				bne !left-
				
				rts
				
			!right:
				inc sprxl,x
				bne !skp+
				inc sprxh,x
			!skp:
				lda sprxh,x
				lsr
				lda sprxl,x
				ror
				cmp #192
				bcc !noov+
			
				lda #0
				sta sprxl,x
				sta sprxh,x
			
			!noov:
				
				jsr update_ball_y_and_f
			
				inx
				cpx p0tmp
				bne !right-
				rts
	}
	
	update_ball_y_and_f:
	{
				stx p0tmp + 1 //savex
				lda sprxl,x
				and #63
				
				bne !nosfx+
			
				sta p0tmp + 3
				sty p0tmp + 2
				:sfx(SFX_BALLBOUNCE)
				ldy p0tmp + 2
				lda p0tmp + 3
				
					
			!nosfx:
				
				tax
				lda gamelevel
				cmp #5
				bcc !skp+
				txa
				clc
				adc #64 //high jump
				tax
			!skp:	
				lda balljumppath,x
				sta p0tmp + 2
				ldx p0tmp + 1
				lda environment.elevator_y - 1,y
			
				sec 
				sbc p0tmp + 2
				sta spry,x
			
				lda sprxl,x
				lsr
				lsr
				anc #3
				adc #[ball_sprites & $3fff] / 64 
				sta sprf,x
			
				lda p0tmp + 2
				cmp #8
				bmi !skp+
			
				lda sprf,x
				clc
				adc #4
				sta sprf,x
				lda spry,x
				clc
				adc #10
				sta spry,x
						
			!skp:
				rts
	}
	
	
.byte 120 - 32 //this is like floor -1, that is the rooftop
elevator_y:
.byte 120,120 + 32, 120 + 64	
	
elevator_cap:
.byte 126,126,126
//.byte 48,48,48 // for testing purposes

elevator_startclosing:
.byte 126 - 24, 126 - 24, 126 - 24
//.byte 32,32,32 // for testing purposes

elevator_dir:	//1 = going up. 0 = going down
.byte 1
elevator_level: //0-2
.byte 2
elevator_qtick: //7-0
.byte 7	
elevator_clock: //0-254 (or 0-86 if level 2)
.byte 0	
	
				
escalator_clock:
.byte 0


.var inittbl = List().add(
				roomcode0.init,
				roomcode1.init,
				roomcode2.init,
				roomcode3.init,
				roomcode4.init,
				roomcode5.init,
				roomcode6.init,
				roomcode7.init
				)
inittable:
	.lohifill 8 , inittbl.get(i)
	
.var jmptbl = List().add(
				roomcode0.update,
				roomcode1.update,
				roomcode2.update,
				roomcode3.update,
				roomcode4.update,
				roomcode5.update,
				roomcode6.update,
				roomcode7.update
				)
jumptable:
	.lohifill 8 , jmptbl.get(i)

		
	
		the_rts:
				rts

	
// Specific room code. Each room has an init function, which is called once when the cop enters the room
// and an update function which is called once per frame				
				
				
	//we check if we can board the escalator here, because, unlike the elevator, the ecalator is only "alive" when the room is on display
	roomcode0:
	{
		init:
				lda #0
				sta escalator_clock
	
				lda #[house_sprites & $3fff] / 64
				sta sprf0 + 0
				lda #[house_sprites & $3fff] / 64 + 1
				sta sprf0 + 1
				lda #[house_sprites & $3fff] / 64 + 2
				sta sprf0 + 2
				lda #[house_sprites & $3fff] / 64 + 3
				sta sprf0 + 3
				
				lda #4
				sta object_list.num
				
				
				lda #160
				sta sprxl0 + 0
				sta sprxl0 + 2
				
				lda #160 + 24
				sta sprxl0 + 1
				sta sprxl0 + 3
				
				lda #0
				sta sprxh0 + 0
				sta sprxh0 + 1
				sta sprxh0 + 2
				sta sprxh0 + 3
				
				lda #2
				sta sprc0 + 0
				
				
				lda #69 + 8
				sta spry0 + 0
				sta spry0 + 1
				lda #69 + 21
				sta spry0 + 2
				sta spry0 + 3
				
				rts
				
		update:
				//if player is on escalator, let's move him
				lda #STATUS_ESCALATOR
				bit cop.status
				beq !next+
	
				lda escalator_clock
				and #3
				bne !skp+
	
				dec copy
				dec copx
			!skp:	
				lda escalator_clock
				bne !next+
				
				lda cop.status
				and #[$ff - STATUS_ESCALATOR]
				sta cop.status
				
				dec copfloor
				
				ldx copfloor
				lda elevator_y - 1,x
				sta copy
				
				

			!next:
	
				//move the escalator chars
				lda escalator_clock
			
				and #%00001100 
				tax
				
				.for (var c = 0; c < 3; c++)
				{
					lda escalator_map_left + c,x
					.for (var i = 0; i < 3; i++)
					{
						sta $4400 + 18 + c + i * 2 + (16 + i) * 40
						sta $4400 + 18 + c + i * 2 + (08 + i) * 40
					}
				
				}
				
				//if the cop is not already on the escalator
				lda #STATUS_ESCALATOR
				bit cop.status
				bne !alreadyescalator+
				
				lda copx
				cmp #$dc/2
				bcs !noescalator+
				lda copfloor
				beq !noescalator+
				cmp #2
				beq !noescalator+
			
			
				
				
				lda #$dc/2
				ldx cop.jumpclock
				sec
				sbc cop.jumppath,x
				cmp copx
				bcc !noescalator+
			
				//on the escalator we go!
					
				lda copy
				sec
				sbc cop.jumppath,x
				sta copy
				
				lda cop.jumppath,x
				asl
				asl
				sta escalator_clock
				
				lda #0
				sta cop.jumpclock
				
				lda cop.status
				and #[$ff - STATUS_JUMPING - STATUS_MOVING]
				ora #STATUS_ESCALATOR
				sta cop.status
				
			!noescalator:	
			!alreadyescalator:
			
				lda escalator_clock
				clc
				adc #1
				and #127
				sta escalator_clock
			
				rts
				
	}			
	
	
	roomcode1:
	{
		init:
				lda gamelevel
				cmp #2
				bcc !done+
				
				lda #OBJECT_RADIO
				ldy #0
				jsr deploy_object
				lda #OBJECT_RADIO
				ldy #1
				jsr deploy_object
				
				lda gamelevel
				cmp #3
				bcc !done+
				
				lda #OBJECT_TROLLEY
				ldy #3
				jsr deploy_object
				
				lda gamelevel
				cmp #4
				bcc !done+
				
				lda #OBJECT_PLANE
				ldx gamelevel
				cpx #7
				bne !skp+
				lda #OBJECT_GOLD
			!skp:
				ldy #2
				jsr deploy_object
				
			!done:	
				rts
		update:
				rts
		
	}
	
	
	//columns on level 0 and 2
	roomcode2:
	{
		init:
				
				lda gamelevel
				cmp #8
				bcc !skp+
				lda #8
			!skp:
				asl
				asl
				adc #<[init_list - 4]
				sta p0tmp + 2
				lda #>[init_list - 4]
				adc #0
				sta p0tmp + 3
				
				ldy #0
				
				lda (p0tmp + 2),y
				jsr deploy_object
				iny
				lda (p0tmp + 2),y
				jsr deploy_object
				iny
				lda (p0tmp + 2),y
				jsr deploy_object
				iny
				lda (p0tmp + 2),y
				jsr deploy_object
					
				rts
		init_list:		
				.byte 0,			0,				0,					OBJECT_BALL	
				.byte 0,			0,				0,					OBJECT_BALL
				.byte OBJECT_GOLD,	0,				OBJECT_TROLLEY,		OBJECT_BALL
				.byte OBJECT_RADIO,	OBJECT_PLANE,	OBJECT_TROLLEY,		OBJECT_BALL
				.byte OBJECT_RADIO,	OBJECT_PLANE,	OBJECT_TROLLEY,		OBJECT_BALL
				.byte OBJECT_GOLD,	OBJECT_PLANE,	OBJECT_TROLLEY,		OBJECT_BALL
				.byte OBJECT_RADIO,	OBJECT_PLANE,	OBJECT_TROLLEY,		OBJECT_BALL
				.byte OBJECT_RADIO,	OBJECT_PLANE,	OBJECT_GOLD,		OBJECT_BALL
				
		update:
				rts
				
	}
	
	//elevator room						
	roomcode3:
	{
		init:	
				lda #OBJECT_BALL
				ldy #2
				jsr deploy_object
				
				ldx gamelevel
				cpx #3
				bcc !done+
				
				lda #OBJECT_TROLLEY
				ldy #0
				jsr deploy_object
				
				lda #OBJECT_TROLLEY
				ldy #1
				jsr deploy_object
						
				ldx gamelevel
				cpx #6
				bcc !done+
				
				lda #OBJECT_RADIO
				ldy #3
				jsr deploy_object
			!done:		
				rts
	
		update:
				lda #<[$4400 + 8 * 40 + 19]
				sta p0tmp
				lda #>[$4400 + 8 * 40 + 19]
				sta p0tmp + 1
				
				
				lda #0
				sta p0tmp + 2 //counter on levels
				
			!l:	
				ldx elevator_level
				cpx p0tmp + 2
				beq !skp+
				ldx #0 //door closed
				jsr drawelevatordoor
				jmp !next+
				
			!skp:	
				lda elevator_clock
				
				cmp #5
				bcc !opening+	
				
				cmp elevator_startclosing,x
				bne !skp+
				
				//clock = 0 means starts opening. Play the sfx`
				
				:sfx(SFX_DOOR)
				ldx elevator_level
				lda elevator_clock
				jmp !closing+
			!skp:			
				
				bcc !open+ 
				
			!closing:
				sbc elevator_startclosing,x
				cmp #4
				bcc !ok+
			!closed:
				ldx #0
				jsr drawelevatordoor
				jmp !next+	
				
			!ok:	
				eor #3
				asl
				tax
				jsr drawelevatordoor
				jmp !next+
				
			!open:
				ldx #8
				jsr drawelevatordoor
				jmp !next+
					
			!opening:
				asl
				tax
				jsr drawelevatordoor
		!next:
				lda p0tmp
				clc
				adc #<[4 * 40]
				sta p0tmp
				lda p0tmp + 1
				adc #>[4 * 40]
				sta p0tmp + 1
		
				inc p0tmp + 2
				lda p0tmp + 2
				cmp #3
				bne !l-
											
				
		!next:
		
				//draw the top dial and level arrows
				lda elevator_level
				asl
				asl
				tay
				
				ldx elevator_level
				lda elevator_clock
				cmp elevator_startclosing,x
				bcc !ok+
				
				//it's in an intermediate stage
				cpx #0
				bne !skp+
				
				//arrows down
			
				ldy #2
			
				jmp !ok+
		!skp:	cpx #2
				bne !skp+
				
				ldy #6
				jmp !ok+
				
		!skp:		
				//central so it depends on direction
				ldy #6
				lda elevator_dir
				beq !ok+
				ldy #2

			!ok:	
				lda dial_map,y
				sta $4400 + 6 * 40 + 19
				iny
				lda dial_map,y
				sta $4400 + 6 * 40 + 20
				
		
				//if the hero is in elevator mode, move it accordingly
				lda cop.status
				and #STATUS_ELEVATOR
				beq !skp+
				
				ldx elevator_level
				lda elevator_y,x
				sta copy
				
				inx
				stx copfloor
				
		!skp:
		
		!next:	
				
				
				
				lda elevator_clock
				lsr
				anc #1
				adc #1
				tax		//white or red
				ldy #1	//white
				
				lda elevator_dir
				bne !arrdown+
				
				txa
				tay
				ldx	#1		
					
			!arrdown:	
				stx $d800 + 21 + 40 * 9
				stx $d800 + 21 + 40 * 13
				stx $d800 + 21 + 40 * 17	
				sty $d800 + 18 + 40 * 9
				sty $d800 + 18 + 40 * 13
				sty $d800 + 18 + 40 * 17
						
			!next:
				rts
				
				//load x with the frame number times 2 (0-4)
				//assumes (p0tmp) contains the screen address of the elevator
				
		drawelevatordoor:
				ldy #0
				lda elevator_map,x
				sta (p0tmp),y
				lda elevator_map + 1,x
				iny
				sta (p0tmp),y
				
				ldy #40
				lda elevator_map + 10,x
				sta (p0tmp),y
				lda elevator_map + 10 + 1,x
				iny
				sta (p0tmp),y
								
				ldy #80
				lda elevator_map + 20,x
				sta (p0tmp),y
				lda elevator_map + 20 + 1,x
				iny
				sta (p0tmp),y
				
				rts 		
	}
	
	
	//plants on level1
	roomcode4:
	{
		init:
				ldx gamelevel
				cpx #1
				bne !skp+
				
				lda #OBJECT_GOLD
				ldy #0
				jsr deploy_object
		!skp:		
				lda #OBJECT_BALL
				ldy #1
				jsr deploy_object
				
				ldx gamelevel
				cpx #2
				bcc !done+
				
				lda #OBJECT_RADIO
				ldy #2
				jsr deploy_object
				
				ldx gamelevel
				cpx #3
				bcc !done+
				
				lda #OBJECT_TROLLEY
				ldy #0
				jsr deploy_object
				
				ldx gamelevel
				cpx #4
				bcc !done+
				
				lda #OBJECT_PLANE
				ldy #3
				jsr deploy_object
					
			!done:		
				rts
				
		update:
				rts
				
	}
	
	
	roomcode5:
	{
		init:
				//the following can be overwritten
				lda #OBJECT_CASE
				ldy #1
				jsr deploy_object
				
				lda #OBJECT_GOLD
				ldy #2
				jsr deploy_object
				
				lda #OBJECT_CASE
				ldy #3
				jsr deploy_object
				
				lda gamelevel
				cmp #1
				beq !done+
				
				and #1
				
				beq !alarm+
				lda #OBJECT_GOLD
				jmp !skp+
			!alarm:	
				lda #OBJECT_RADIO
			!skp:
				ldy #0
				jsr deploy_object
				
				
			!done:	
				rts
		
		update:
				rts
	}
	
	
	
	roomcode6:
	{
		init:
				ldy #3
				lda #OBJECT_BALL
				jsr deploy_object
				
				lda gamelevel
				cmp #3
				bcc !skp+
				lda #OBJECT_TROLLEY
				ldy #2
				jsr deploy_object
			
			
				lda gamelevel
			!skp:
				cmp #4
				bcc !skp+
				lda #OBJECT_PLANE
				ldy #1
				jsr deploy_object	
			
				lda gamelevel
			!skp:	
				cmp #2
				bcc !done+
				
				//it's a radio, unless it's level 4, then it's gold
				ldy #0
				cmp #4
				bne !rd+
				lda #OBJECT_GOLD
				jmp !+
			!rd:	
				lda #OBJECT_RADIO
			!:
				jsr deploy_object	
				
			!done:	
				rts
		update:
				rts
	}
	
	//this room has the right escalator
	roomcode7:
	{
		init:
				lda #0
				sta escalator_clock

				rts
				
		update:
				//if player is on escalator, let's move him
				lda #STATUS_ESCALATOR
				bit cop.status
				beq !next+
	
				lda escalator_clock
				and #3
				bne !skp+
	
				dec copy
				inc copx
			!skp:	
				lda escalator_clock
				bne !next+
				
				lda cop.status
				and #[$ff - STATUS_ESCALATOR]
				sta cop.status
			
				dec copfloor
				
				ldx copfloor
				lda elevator_y - 1,x
				sta copy
				
			!next:
	
				//move the escalator chars
				lda escalator_clock
			
				and #%00001100 
				tax
				
				.for (var c = 0; c < 3; c++)
				{
					lda escalator_map_right + c,x
					.for (var i = 0; i < 3; i++)
					{
						sta $4400 + 19 + c - i * 2 + (12 + i) * 40
						
					}
				
				}
				
				//if the cop is not already on the escalator
				lda #STATUS_ESCALATOR
				bit cop.status
				bne !alreadyescalator+
				
				lda copx
				cmp #$7e/2
				bcc !noescalator+
				lda copfloor
				cmp #2
				bne !noescalator+
			
				ldx cop.jumpclock
				lda cop.jumppath,x
				clc
				adc #$7e/2
				cmp copx
				bcs !noescalator+
			
				//on the escalator we go!
					
				lda copy
				sec
				sbc cop.jumppath,x
				sta copy
				
				lda cop.jumppath,x
				asl
				asl
				sta escalator_clock
				
				lda #0
				sta cop.jumpclock
				
				lda cop.status
				and #[$ff - STATUS_JUMPING - STATUS_MOVING]
				ora #STATUS_ESCALATOR
				sta cop.status
			
			!noescalator:	
			!alreadyescalator:
			
				lda escalator_clock
				clc
				adc #1
				and #127
				sta escalator_clock
			
				rts
				
	}
	

}

