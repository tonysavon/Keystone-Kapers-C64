//#define INVINCIBLE

.const p0start = $02
.var p0current = p0start
.function reservep0(n)
{
	.var result = p0current
	.eval p0current = p0current + n
	.return result	
}

.const sid = LoadSid("..\sid\keystone_kapers_8000.sid")

.const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
.var kla = LoadBinary("../assets/kkload1.kla", KOALA_TEMPLATE)

.const copx = reservep0(1) //the cop moves at 2pixel per frame, so one byte will do
.const copy = reservep0(1)
.const copf = reservep0(1)

.const robberxl = reservep0(1)
.const robberxh = reservep0(1)
.const robberroom = reservep0(1)

.const robberfloor = reservep0(1) //0 - #03

.const robberxdir = reservep0(1)

//sprite 4 to 7 are always allocated to cop and robber
.const sprxl0 = reservep0(4)
.const sprxh0 = reservep0(4)
.const spry0 = reservep0(4)
.const sprc0 = reservep0(1)	//sprites on the same level always have the same extra color
.const sprf0 = reservep0(4)

.const STRIDE = p0current - sprxl0 


.const sprxl = sprxl0
.const sprxh = sprxh0
.const spry	 = spry0
.const sprc  = sprc0
.const sprf = sprf0

.const sprxl1 = reservep0(4)
.const sprxh1 = reservep0(4)
.const spry1 = reservep0(4)
.const sprc1 = reservep0(1)
.const sprf1 = reservep0(4)

.const sprxl2 = reservep0(4)
.const sprxh2 = reservep0(4)
.const spry2 = reservep0(4)
.const sprc2 = reservep0(1)
.const sprf2 = reservep0(4)

.const sprxl3 = reservep0(4)
.const sprxh3 = reservep0(4)
.const spry3 = reservep0(4)
.const sprc3 = reservep0(1)
.const sprf3 = reservep0(4)

.const ld01e = reservep0(4)

.const currentroom = reservep0(1)
.const copfloor = reservep0(1)

.const gamelevel = reservep0(1)
.const menulevel = reservep0(1)

.const huddone = reservep0(1) //signal that the hud at the top has been drawn

.const redraw = reservep0(1)

.const p0tmp = reservep0(4)

.const clock = reservep0(1)

.const key_clock = reservep0(1)
.const hud_clock = reservep0(1)
.const music_on = reservep0(1)

.const score = reservep0(6) //6 digits

.const timer_value = reservep0(3) //2 digits, plus sub 128th of time unit. One time unit both on the A8 and vcs version is exactly 128 frames
								  //this is big-endian, unlike the other multi-byte values
.print timer_value

.const lives = reservep0(3)

.pc = $0801 
:BasicUpstart($0820)


.macro setirq(addr,line)
{
		lda #<addr
		sta $fffe
		lda #>addr
		sta $ffff
		lda #line
		sta $d012
}

.pc = $0820 "main"

				sei
				lda #$35
				sta $01
				
				lda #0
				sta $d020
				
				jsr showpic

				jsr waitbutton
				
				lda #$0b
				sta $d011
	
				lda #$01
				sta menulevel					
	splashloop:

				jsr splash

				lda menulevel
				sta gamelevel
								
				jsr vsync
				lda #$0b
				sta $d011
				
				jsr set_game_screen
				
				jsr clear_irq
				
				:setirq(irq_00, $08)
	
				lda #$0b
				sta $d011
				
				cli			
				
				jsr game_init
				
				jsr environment.init //in the original the elevator is only initialized once per game, so each level
									 //starts with the elevator in the position it was at the previous level 

	levelloop:	
						
				jsr level_init
				jsr cop.init
				jsr robber.init
				
				jsr get_ready
				
				
	gameloop:
				
				jsr controls
				jsr cop.update
				jsr robber.update
				jsr environment.update
				jmp collision_detection
		return_from_collision_detection:
				
				jsr timer.tick

				jsr panelvsync
		
				inc clock		
				jmp gameloop			
			
				
				
.import source "controls.asm"
.import source "hero.asm"
.import source "actors.asm"
.import source "environment.asm"
.import source "hud.asm"
.import source "misc.asm"
.import source "splash.asm"
.import source "sfx.asm"
				


.macro place_level_sprites(lev)
{

					lda $d010
					and #%11110000
					sta $d010
					
				.for (var i = 0; i < (lev == 0 ? 4 : 3); i++)
				{					
					lda.zp sprxl + lev * STRIDE + i
					sta $d000 + i * 2
					lda.zp sprxh + lev * STRIDE + i
					beq !skp+
					
					lda $d010
					ora #[%00000001 << i]
					sta $d010	
				!skp:
					lda.zp spry + lev * STRIDE + i
					sta $d001 + i * 2
					
					lda.zp sprc + lev * STRIDE// + i	//sprites on the same level always have the same color
					sta $d027 + i
					lda.zp sprf + lev * STRIDE + i
					sta $47f8 + i
				}
				
				!done:
}



irq_00:
{
				sta savea + 1
				stx savex + 1
				sty savey + 1
	
				
				lda #$1b
				sta $d011
				
				jsr sid.play
				
				jsr random_	
				

				lda #%00011100 //sets the HUD font for the next frame
				sta $d018
							
							
				lda #$0b
				sta $d021
				
				lda #$0e	
				sta $d022	
	
				lda #$0a
				
				sta $d023
	
				//all sprites mc
				lda #$ff
				sta $d01c 
							
				lda #0
				sta $d010
				
				//extra life badge sprites. Just one pixel! But we accept nothing less than perfection.
				
				lda #[badge_sprite & $3fff] / 64
				.for (var i = 0; i < 5; i++)
					sta $47f8 + i
				.for (var i = 0; i < 5; i++)
				{
					lda #24 + 8 + 2 + 16 * i
					sta $d000 + i * 2
				} 
				
				lda #38
				.for (var i = 0; i < 5; i++)
					sta $d001 + i * 2
				
				lda #$0b
				sta $d025
				lda #$01
				sta $d026
				
				lda #$0f
				sta $d027 + 5		
				
				ldx lives
				beq !skp+
				dex
			!skp:
				lda lormask,x
				sta $d015
				
				//stopwatch / level
				lda #140
				sta $d000 + 5 * 2
				lda #45
				sta $d001 + 5 * 2
sworlv:				
				lda #[stopwatch_sprite & $3fff] / 64
				sta $47f8 + 5
				
				//note sprites
			
				lda #112
				sta $d000 + 6 * 2
				lda #48
				sta $d001 + 6 * 2
				
				lda #2
				sta $d027 + 6
				
		
note_sprf:		lda #[note_sprites & $3fff] / 64 + 0
				sta $47f8 + 6
			
			
				lsr $d019
				:setirq(irq_01, 51 + 16)
		savea:	lda #0
		savex:	ldx #0
		savey:	ldy #0
				rti		
				
	lormask:
	.byte %01100000, %01100001, %01100011, %01100111, %01101111, %01111111			
				
}

								
irq_01:
{
				sta savea + 1
				stx savex + 1
				lda #%00011110
				sta $d018
	
				lda $d01e //clears hw spr collision register
				
				lda #$ff
				sta $d015
				
				lda #1
				sta huddone
				
				//place level 0 sprites
				:place_level_sprites(0)
				
				//lda #$0e	
				//sta $d022	
				lda #$04
				sta $d023

				lda #0
				sta $d025
				lda #10
				sta $d026
				
				lda #%11001111
				sta $d015
							
				//places robber
				lda robberroom
				cmp currentroom
				bne !next+
				
				lda #%11111111
				sta $d015
				
				lda robberxl
				sta $d000 + 4 * 2
				sta $d000 + 5 * 2
				
				lda robberxh
				beq !skp+
				lda #%00110000
				ora $d010
				sta $d010
			!skp:				
				lda robberfloor

				asl
				asl
				asl
				asl
				asl
				adc #50 + 38
				sta $d001 + 4 * 2
				sta $d001 + 5 * 2
				
				lda #8
				sta $d027 + 4
				lda #1
				sta $d027 + 5
				
				lda robber.robberframe
				lsr
				lsr
				clc
				adc #[robber_sprites & $3fff] /64
				sta $47f8 + 5
				adc #5
				sta $47f8 + 4
				
				lda robberxdir
				anc #1
				beq !next+
				lda $47f8 + 5
				adc #10
				sta $47f8 + 5
				
				lda $47f8 + 4
				adc #10
				sta $47f8 + 4
				
			!next:	
				//places hero
				
				lda #6
				sta $d027 + 7
				lda #$01
				sta $d027 + 6
				
				lda copx
				asl
				sta $d000 + 6 * 2
				sta $d000 + 7 * 2
				
				bcc !skp+

				lda $d010
				ora #%11000000
				sta $d010
			!skp:
		
			
				lda cop.status
				and #STATUS_ELEVATOR
				beq !noelevator+
				
				lda copy
				sec
				sbc #3
				
				jmp !nojump+
				
				
			!noelevator:	
				lda copy
				
				ldx cop.jumpclock
				beq !nojump+
				sec
				sbc cop.jumppath,x
				
			!nojump:	
				sta $d001 + 6 * 2
				sta $d001 + 7 * 2
								
				lda copf
				sta $47f8 + 7
				clc
				adc #12
				sta $47f8 + 6
							
				lsr $d019
				:setirq(irq_02, 51 + 30)
				
		savea:	lda #0
		savex:	ldx #0
				
				rti
}				
							
						
irq_02:
{
				sta savea + 1
				stx savex + 1
				//sty savey + 1
							
				
				lda #$0a
				sta $d022
				
				ldx #$08
				lda #51 + 30
			!:	cmp $d012
				bcs !-

				stx $d023
				
				ldx #$03
				lda #51 + 32
			!:	cmp $d012
				bcs !-
				stx $d023

				
				ldx #$0d		
				lda #51 + 33
			!:	cmp $d012
				bcs !-
				stx $d022
				
				ldx #$07
				lda #51 + 34
			!:	cmp $d012
				bcs !-
				stx $d023
				
				ldx #$01
				lda #51 + 35
			!:	cmp $d012
				bcs !-
				stx $d022

				lda #51 + 38
			!:	cmp $d012
				bcs !-
				lda #$0f
				sta $d022
				lda #$0c
				sta $d023	

			!noobj:
	
				lda $d01e //clear hw spr spr collision		
				
				:setirq(irq_03, 51 + 57)
				lsr $d019
		savea:	lda #0
		savex:	ldx #0
//		savey:	ldy #0
				
				rti
				
				
}
		

//pavement of level 0 (rooftop)
irq_03:

				pha
				lda #$07
				sta $d022
			
				//only for this level, (possibly) expand sprites and make them single color.
				//used to write game over or get ready
				
				
				lda #51 + 59
			!:	cmp $d012
				bcs !-
				lda #$08
				sta $d023
				lda #$05
				sta $d021
				
				lda $d01e
				sta ld01e

				mcspriteslevel1:
				lda #%11111111
				sta $d01c
xexpandedspriteslevel1:		
				lda #%00000000
				sta $d01d
				
								
prioritylevel0: lda #0
				sta $d01b
								
				//place level 1 sprites
				:place_level_sprites(1)
				
				lda #51 + 60
			!:	cmp $d012
				bcs !-		
level0mc10:
				lda #8
				sta $d022
				
				
				
				
				lda #51 + 63
			!:	cmp $d012
				bcs !-
			
			//end of pavement	
				
level0mc20:		lda #$0c
				sta $d023

				
									
				//:setirq(irq_03, 51 + 83)
				:setirq(irq_04, 51 + 89)
				lsr $d019
				pla
				rti
				

//pavement of level 1
irq_04:

				pha
				lda #$07
				sta $d022
				
				//reset x-xpanded and mc
				lda #%11111111
				sta $d01c
	
				lda #%00000000
				sta $d01d
								
				lda #51 + 89 + 1
			!:	cmp $d012
				bcs !-
				lda #$08
				sta $d023

prioritylevel1: lda #0
				sta $d01b

				lda $d01e
				sta ld01e + 1
				
				//place level 2 sprites
				:place_level_sprites(2)
																
				:setirq(irq_05, 51 + 95)
				lsr $d019
				pla
				rti

//sets the umbrella color
irq_05:

				pha
	level1mc10:				
				lda #$02
				sta $d022
					
			
				lda #51 + 95
			!:	cmp $d012
				bcs !-
				
				//end of pavement	
	level1mc20:			
				lda #$09
				sta $d023	
					
				:setirq(irq_06, 51 + 101)
//				:setirq(irq_07, 51 + 121)
				lsr $d019
				pla
				rti




//this sets the umbrella shade and the umbrella decoration color
irq_06:


				pha
	level1mc21:				
				lda #$0f
				sta $d023
				
				lda #51 + 104
			!:	cmp $d012
				bcs !-
	level1mc22:	lda #$09
				sta $d023
	level1mc11:	lda #$08
				sta $d022

				:setirq(irq_75, 51 + 111)
				lsr $d019
				pla
				rti

				
// for rooom 4, it sets the plant and vase color
irq_75:
				
				pha
				
	level1mc23: lda #$09
				sta $d023
				
				lda #51 + 115
			!:	cmp $d012
				bcs !-
				
	level1mc24:	lda #$0b
				sta $d023
				
				:setirq(irq_07, 51 + 120)
				lsr $d019
				pla
				rti
				
				
//pavement of central floor, level 2
irq_07:

				pha
				lda #$07
				sta $d022

								
				lda #51 + 122
			!:	cmp $d012
				bcs !-
				
				lda #$08
				sta $d023

prioritylevel2: lda #0
				sta $d01b				
											
				lda #51 + 124
			!:	cmp $d012
				bcs !-		

				lda $d01e
				sta ld01e + 2
								
				//place level 3 sprites
				:place_level_sprites(3)
								
level2mc10:		lda #8
				sta $d022
				
				lda #51 + 127
			!:	cmp $d012
				bcs !-
			
			//end of pavement	
				
level2mc20:		lda #$09
				sta $d023
				
				:setirq(irq_08,51 + 153)
				lsr $d019
				pla
				rti


//pavement of level 3, last one
irq_08:				
	
				pha
				
				lda #$07
				sta $d022
				
				lda #51 + 154
			!:	cmp $d012
				bcs !-
				
				lda #$08
				sta $d023
				
				lda #$0c
				sta $d021
				
				lda $d01e
				sta ld01e + 3
				
							
				:setirq(panel_irq_0, 51 + 160)
		
				lsr $d019
				
				
				pla
				rti


				
panel_irq_0:
{
				sta savea + 1
				stx savex + 1

				
				lda #$0b
				sta $d022
				lda #3
				sta $d023
				
				
				//place radar sprites here!
				lda #0
				sta $d01b
				sta $d010
				
				sta huddone
	
				
				lda #$ff
				sta $d015
	
				//player:
				
				lda copy
				sec
				sbc #50 + 38
				lsr
				lsr
				lsr
				clc
				adc #222 - 3 
				sta $d001
				
				lda copx
				ldx currentroom	
/*				sec
				sbc #12
*/				lsr
				lsr
				lsr
				clc
				adc radaroffset,x
				sta $d000
				
				lda #[radar_man_sprite & $3fff] / 64
				sta $47f8 + 0
				
				lda #6
				sta $d027 + 0
				
					
				//robber:

				lda robberfloor
				
				asl
				asl
				
				
				adc #222 - 3 
				sta $d003
				
				lda robberxh
				lsr
				lda robberxl
				ror
				
				ldx robberroom	
				lsr
				lsr
				lsr
				clc
				adc radaroffset,x
				sta $d002
				
				lda #[radar_man_sprite & $3fff] / 64
				sta $47f8 + 1
				
				lda #1
				sta $d027 + 1
				
				
				lda #1
				sta redraw
				
						
				//escalators
				lda #80 + 24 + 8
				sta $d004
				lda #80 + 24 + 16 * 8 + 2
				sta $d006
				lda #[radar_escalator_sprites & $3fff] / 64
				sta $47f8 + 2
				lda #[radar_escalator_sprites & $3fff] / 64 + 1
				sta $47f8 + 3
				lda #222			
				sta $d005
				sta $d007
				//no need to set the spr color as they only use mc
				
				//elevator:
				lda #[radar_elevator_sprites & $3fff] / 64
				sta $47f8 + 4
				
				lda environment.elevator_level
				asl
				asl
							
				adc #222
				sta $d009
				lda #80 + 24 + 3 * 20 + 10 //each room is 20 pixel
				sta $d008
				lda #$09
				sta $d027 + 4
				
				
				//place the logo shadow
				lda #%00011111 //logo shadow is hires
				sta $d01c
				
				lda #228
				sta $d001 + 5 * 2
				sta $d001 + 6 * 2
				sta $d001 + 7 * 2
				
				lda #144
				sta $d000 + 5 * 2
				lda #144 + 24
				sta $d000 + 6 * 2
				lda #144 + 48
				sta $d000 + 7 * 2
				
				lda #0
				sta $d027 + 5
				sta $d027 + 6
				sta $d027 + 7
				
				lda #[logo_shadow_sprites & $3fff] / 64
				sta $47f8 + 5
				lda #[logo_shadow_sprites & $3fff] / 64 + 1
				sta $47f8 + 6
				lda #[logo_shadow_sprites & $3fff] / 64 + 2
				sta $47f8 + 7
				
				:setirq(panel_irq_1, 51 + 170)
				
				lsr $d019
				
	savea:		lda #$00
	savex:		ldx #$00

				
				rti
				
radaroffset:
.fill 8, 80+2 + 20 * i				
}				


panel_irq_1:
{
				pha
				
				
				lda #$08
				sta $d022
				lda #$05
				sta $d023
				
				:setirq(logo_irq, 51 + 191)
				
				lsr $d019
				pla
				rti
}

logo_irq:
{
				pha
				lda #2
				sta $d023				
				lda #8
				sta $d022
				
				lda #51 + 192
			!:	cmp $d012
				bcs !-
				
				lda #7
				sta $d023
				
				lda #51 + 193
			!:	cmp $d012
				bcs !-
				
				lda #5
				sta $d022
				
				lda #51 + 194
			!:	cmp $d012
				bcs !-
				
				lda #3
				sta $d023
				
				lda #51 + 195
			!:	cmp $d012
				bcs !-
				
				lda #6
				sta $d022
				
			
				:setirq(irq_00, 8)
				
				lsr $d019
				pla
				rti
}



clear_irq:
{
				lda #$7f                    //CIA interrupt off
				sta $dc0d
				sta $dd0d
				lda $dc0d
				lda $dd0d
				
				lda #$01                    //Raster interrupt on
				sta $d01a
				lsr $d019
				rts
}			
			


game_init:
{

				lda #0
				ldx #5
			!:	sta score,x
				dex
				bpl !-
				
				lda #4
				sta lives

				lda #0
				sta key_clock
		
				lda #127
				sta hud_clock
				
				lda #[note_sprites & $3fff] / 64 + 0
				sta irq_00.note_sprf + 1
				
				lda #1
				sta music_on
						
				jsr set_sfx_routine
								
				jsr put_score
				jsr put_lives
				
				rts
}

		
level_init:
{
				lda #1
				ldx music_on
				bne !skp+
				lda #2
			!skp:
				jsr sid.init

				ldx #31
				lda #0
			!:	sta item_collected,x
				dex
				bpl !-
				
				lda #%11111111
				sta mcspriteslevel1 + 1
			
				lda #%00000000
				sta xexpandedspriteslevel1 + 1		
		
				lda #9
				sta $d800 + 40 + 18
				sta $d800 + 40 + 19
				sta $d800 + 40 + 20
				sta $d800 + 40 + 21
						
				rts	
}


	
set_game_screen:
{
				lda #1 
				sta redraw
				
				lda #5
				sta $d021

				lda #%00011110
				sta $d018
			
				lda #2
				sta $dd00
					
				lda #$d8
				sta $d016
				

				lda #0
				sta $d025
				lda #10
				sta $d026
				
				//draw the radar
				
				ldy #200
			!:	lda radar_map - 1,y
				sta $4400 + 20 * 40 - 1,y
				sec
				sbc #(radar_chars - chars)/8
				tax
				lda radar_color,x
				sta $d800 + 20 * 40 - 1,y
				dey
				bne !-				
		
				//draw the top 3 charlines
				jsr hud_init
			
				rts
}			



//set room at currentroom
set_room:
{

				lda #[empty_sprite & $3fff] / 64
				ldy #0
				ldx #3
			!:
				sta sprf0,x
				sta sprf1,x
				sta sprf2,x
				sta sprf3,x
				sty spry0,x
				sty spry1,x
				sty spry2,x
				sty spry3,x
				sty sprxh0,x
				sty sprxh1,x
				sty sprxh2,x
				sty sprxh3,x
				dex
				bpl !-

				ldx #[end_object_list - object_list] - 1
				lda #0
			!:	sta object_list,x
				dex
				bpl !-
				
				ldx currentroom
				
				lda l0mc10,x
				sta level0mc10 + 1
				lda l0mc20,x
				sta level0mc20 + 1
				
				lda l1mc10,x
				sta level1mc10 + 1
				lda l1mc20,x
				sta level1mc20 + 1
				lda l1mc21,x
				sta level1mc21 + 1
				lda l1mc22,x
				sta level1mc22 + 1
				lda l1mc11,x
				sta level1mc11 + 1
				lda l1mc23,x
				sta level1mc23 + 1
				lda l1mc24,x
				sta level1mc24 + 1
				
				lda l2mc10,x
				sta level2mc10 + 1
				lda l2mc20,x
				sta level2mc20 + 1
				
				lda l0prio,x
				sta prioritylevel0 + 1
				
				lda l1prio,x
				sta prioritylevel1 + 1
				
				lda l2prio,x
				sta prioritylevel2 + 1
				
				
				lda map_idx.lo,x
				sta src0 + 1
				lda map_idx.hi,x
				sta src0 + 2
				
				lda src0 + 1
				clc
				adc #170
				sta src1 + 1
				lda src0 + 2
				adc #0
				sta src1 + 2
				
				lda src1 + 1
				clc
				adc #170
				sta src2 + 1
				lda src1 + 2
				adc #0
				sta src2 + 2
						
				lda src2 + 1
				clc
				adc #170
				sta src3 + 1
				lda src2 + 2
				adc #0
				sta src3 + 2
				
				ldy #0
				
		src0:	lax gamemap,y
				sta $4400 + 120 + 170 * 0,y
				beq src1			//41% of the chars in a map are zero, and for thòse you don't need to set char color.
									//so here on average we use 0.41 * 3 + 0.59 * 11 = 7.7 cycles instead of 9 cycles
				lda colortable,x
				sta $d800 + 120 + 170 * 0,y
				
		src1:	lax gamemap,y
				sta $4400 + 120 + 170 * 1,y
				beq src2
				lda colortable,x
				sta $d800 + 120 + 170 * 1,y
				
		src2:	lax gamemap,y
				sta $4400 + 120 + 170 * 2,y
				beq src3
				lda colortable,x
				sta $d800 + 120 + 170 * 2,y
				
		src3:	lax gamemap,y
				sta $4400 + 120 + 170 * 3,y
				beq !skp+		
				lda colortable,x
				sta $d800 + 120 + 170 * 3,y
			!skp:	
				iny
				cpy #170
				bne src0
		
				ldx currentroom
				
				lda environment.jumptable.lo,x
				sta environment.update.roomcode + 1
				lda environment.jumptable.hi,x
				sta environment.update.roomcode + 2

				
				lda environment.inittable.lo,x
				sta initcode + 1
				lda environment.inittable.hi,x
				sta initcode + 2
						
		initcode:
				jmp $2020
}


//manages several aspects related to collision, such as collecting stuff or being stopped or killed by enemies.
//make sure that you first test for robber being caught
collision_detection:
{
				lda key_clock
				beq !skp+
				dec key_clock
			!skp:

				lda hud_clock
				beq !skp+
				
				dec hud_clock
				bne !skp+
				
				lda #[empty_sprite & $3fff] / 64
				sta irq_00.note_sprf + 1
				
			!skp:	
			
				//check keypress for various things, such as pause or music on/off
				lda $dc01
				cmp #239
				bne !skp+

				jsr  pause
				lda #255
				
			!skp:
			
				cmp #253
				bne !skp+
				
				jsr toggle_music
			
				
			!skp:		
				
			
			#if INVINCIBLE
				jmp return_from_collision_detection
			#endif

			
				//test time_out
				lda timer_value
				bpl !skp+

				jmp death
				
			!skp:		
				lda cop.status
				and #STATUS_ELEVATOR
				bne !notest+
				
				//test catch the robber first, using software collision detection. This will also eliminate ambiguity 	
				jsr robber.test_caught
				cmp #1
				bne !skp+
				
				jsr level_complete_sequence
				
				inc gamelevel
				lda #99
				cmp gamelevel
				bcs !noov+
				sta gamelevel
			!noov:
				
				
				jmp levelloop
			!skp:		
				
				lda currentroom
				cmp #7
				beq !notest+
				cmp #0
				beq !notest+
				jmp !skp+
			!notest:	
				jmp !done+
			!skp:	
				ldy copfloor
		
				lda ld01e,y
				and #%11000000
				beq !done+
					
				//collided with a sprite at level x
				lda object_list.type,y
				cmp #OBJECT_RADIO
				bcc !bonus+
				beq !radio+
				
				cmp #OBJECT_PLANE
				bcc !non_deadly_enemy+
				
		!deadly_enemy:
		
				jmp death
		
		!non_deadly_enemy:
				//freeze the cop and subtract 9 seconds
				jsr freeze
				jmp !done+		
				 
		!bonus:
				jsr clear_object
				
				tya
				asl
				asl
				asl
				clc
				adc currentroom
				tax
				lda #1
				sta item_collected,x
				
				//add 50 points
				jsr add_score_50
				
				:sfx(SFX_CASH)
				jmp !done+
				
		!radio:		
				//we have to test that collision didn't happen with the rays. 
				//We must approximate what we do is that if the cop is jumping, and if he is above a certain height, we test collision with the button sprite, not the feet
				ldx cop.jumpclock
				lda cop.jumppath,x
				cmp #7
				bcc !non_deadly_enemy-
				//only test button sprite
				lda ld01e,y
				and #%01000000
				bne !non_deadly_enemy-
				jmp !done+

				
		!done:		
			
				jmp return_from_collision_detection
				
}

pause:
{
			!:	jsr panelvsync
				lda $dc01
				cmp #239
				beq !-
				
			!:	jsr panelvsync
				lda $dc01
				cmp #239
				bne !-
				
			!:	jsr panelvsync
				lda $dc01
				cmp #239
				beq !-
					
				rts
}


toggle_music:
{
				lda key_clock
				beq !skp+
				rts
				
			!skp:
				lda #$3f
				sta key_clock
					
				jsr erase_sid

	
				lda music_on 
				beq !switch_on+
				
				//switch off
				
				lda #0
				sta music_on
				
				lda #5	//mute tune
				jsr sid.init 
				
				lda #[note_sprites & $3fff] / 64 + 1 // crossed note
				
				jmp !next+
			!switch_on:	
			
				lda #1
				sta music_on
			
				lda #$0f
				sta $d418
				
				lda #0 //music on
				jsr sid.init
				
				lda #[note_sprites & $3fff] / 64 //full note
				
			!next:	
				sta irq_00.note_sprf + 1
				lda #127
				sta hud_clock

				jsr set_sfx_routine
				rts
				
}


erase_sid:
{
				ldx #$1f
				lda #0
			!:	sta $d400,x
				dex
				bpl !-
				rts
}

level_complete_sequence:
{
				//from the manual:
				//robbers 1 to 8:  100 times the amount of time unites left
				//robbers 9 to 16: 200
				//after level 17:  300 
	
				//there can be a split second where the timer is -1 and and we caught the robber just then.
				//or maybe crackers will implement unlimited time without actually blocking the timer.
				//whatever the case, just make sure the timer is not negative
				
				lda timer_value
				bpl !skp+
		
				lda #0
				sta timer_value
				sta timer_value + 1		
		!skp:
			
				lda #05
				jsr sid.init // switch music off
						
				lda #1
				sta p0tmp
				lda gamelevel
				cmp #9
				bcc !skp+
				inc p0tmp
				cmp #17
				bcc !skp+
				inc p0tmp
				
		 !skp:	
		 		lda timer_value
		 		ora timer_value + 1
		 		beq !done+
		 		
		 		//play a ding here, we use all three voices
		 		//:sfx(SFX_BONUS)
		 		ldx #SFX_BONUS
		 		jsr play_no_music
		 		
		 		dec timer_value + 1
		 		bpl !ok+
		 		lda #9
		 		sta timer_value + 1
		 		dec timer_value
		 	!ok:
		 		jsr timer.update 
		 		
		 		lda p0tmp
		 		jsr add_score_x
		 		
		 		lda #5
		 		sta p0tmp + 1
		 		
		 	!:	jsr panelvsync
		 		dec p0tmp + 1
		 		bne !-
		 		
		 		jmp !skp-
		 		
		 !done:
		 
		 		lda #50
		 		sta p0tmp + 1
		 	!:	jsr panelvsync
		 		dec p0tmp + 1
		 		bne !- 
		 		
		 
		 		rts		
				
//again, it should be impossible to complete the game with more than 49 seconds left		 		
times_ten:
.fill 5,i * 10
.byte $ff //if you complete the game with 50 seconds left you are a cheater or a wizard. We compensate you with zero points.
}

game_over:
{
				lda #4
				jsr sid.init

				ldy #1
				jsr clear_object
				
				lda #9
				sta $d800 + 40 + 18
				sta $d800 + 40 + 19
				sta $d800 + 40 + 20
				sta $d800 + 40 + 21
				
				lda #[gameover_sprites & $3fff] / 64
				sta sprf1
				lda #[gameover_sprites & $3fff] / 64 + 1
				sta sprf1 + 1
				lda #[gameover_sprites & $3fff] / 64 + 2
				sta sprf1 + 2
				
				lda prioritylevel0 + 1
				and #%11110000
				sta prioritylevel0 + 1

opt:

				jsr put_level
								

				lda #0
				sta sprc1
				
				lda #%00000111
				sta xexpandedspriteslevel1 + 1
				lda #%11111000
				sta mcspriteslevel1 + 1
						
				lda #160 - 48
				sta sprxl1
				lda #160 
				sta sprxl1 + 1
				lda #160 + 48
				sta sprxl1 + 2
				
				lda #0
				sta sprxh1
				sta sprxh1 + 1
				sta sprxh1 + 2
				
				lda environment.elevator_y // -1 + 1
				sta spry1
				sta spry1 + 1
				sta spry1 + 2
		
				
				ldx #0
				stx p0tmp
				
			!:	jsr panelvsync
				ldx p0tmp
				lda fadein,x
				sta sprc1
				inx
				stx p0tmp
				cpx #19
				bne !-
			
				lda #170 //three sec
				sta p0tmp
			!:	jsr panelvsync
	
				dec p0tmp
				bne !-
				
				rts
				
fadein:
.byte 0,$0b,$04,$04,$0c,$0c,$0c,$0a,$0a,$0a,$0f,$0f,$0f,$0f,$0d,$0d,$0d,$0d,$01			
}

get_ready:
{
				//play jingle here
			
				lda #[getready_sprites & $3fff] / 64
				sta sprf1
				lda #[getready_sprites & $3fff] / 64 + 1
				sta sprf1 + 1
				lda #[getready_sprites & $3fff] / 64 + 2
				sta sprf1 + 2
				
				jsr game_over.opt
						
				lda #0
				sta spry1
				sta spry1 + 1
				sta spry1 + 2
				
				lda #%00000000
				sta xexpandedspriteslevel1 + 1
				lda #%11111111
				sta mcspriteslevel1 + 1
				
				jsr timer.update
				rts
}

death:
{	
				//play the sfx
				lda #3
				jsr sid.init
				
				lda #140
				sta p0tmp
			!:  jsr panelvsync
				dec p0tmp
				bne !-
				
				dec lives
				beq !gameover+
				
				jsr put_lives
				jmp levelloop
			!gameover:
				
				jsr game_over
				
				//we must place the cop in stunned position here
				lda #0
				sta cop.jumpclock //land the cop
				
			!gloop:
				
				lda huddone
				beq !gloop-
				
				lda #[hero_stunned_sprites & $3fff] / 64
				sta p0tmp
				lda cop.status
				anc #STATUS_DIRECTION
				beq !skp+
				
				lda p0tmp
				adc #4
				sta p0tmp
				
			!skp:
			
			!:	
				lda clock
				lsr
				lsr
				lsr
				lsr
				anc #1
				adc p0tmp
				sta $47f8 + 7
				
				lda clock
				lsr
				lsr
				anc #1
				adc p0tmp
				adc #2
				sta $47f8 + 6
			
				lda #0
				sta huddone
			
				jsr environment.update
				jsr robber.update
				
				inc clock
				
				lda $dc00
				and #%00010000
				bne !gloop-		
	
			
				
				jmp	splashloop
}

freeze:
{
				//play the sfx
				:sfx(SFX_HIT)
				lda #50
				sta p0tmp
			!:  jsr panelvsync
				dec p0tmp
				bne !-
				
				ldy copfloor
				jsr clear_object
				
				
				lda timer_value + 1
				sec
				sbc #9
				bcs !ok+
				
				clc
				adc #10
				
				dec timer_value + 0
				
			!ok:
				sta timer_value + 1
				jsr timer.update
				
				rts
}



//room: 		room0	room1	room2	room3	room4	room5 	room6	room7

l0mc10:	.byte 	$01,	$08,	$08,	$03,	$08,	$08,	$08,	$ff
l0mc20: .byte	$ff,	$09,	$0c,	$09,	$09,	$09,	$0c,	$ff

l1mc10: .byte	$ff,	$02,	$08,	$03,	$08,	$02,	$08,	$01
l1mc20: .byte	$ff,	$09,	$09,	$09,	$0d,	$09,	$09,	$00
l1mc21: .byte	$ff,	$0f,	$09,	$09,	$0d,	$0f,	$09,	$00
l1mc22: .byte	$ff,	$09,	$09,	$09,	$0d,	$09,	$09,	$00
l1mc11: .byte	$ff,	$08,	$08,	$03,	$08,	$08,	$08,	$01
l1mc23: .byte	$ff,	$09,	$09,	$09,	$09,	$09,	$09,	$00
l1mc24: .byte	$ff,	$09,	$09,	$09,	$0b,	$09,	$09,	$00

l2mc10: .byte	$01,	$08,	$ff,	$03,	$08,	$08,	$ff,	$08
l2mc20: .byte	$ff,	$09,	$0c,	$09,	$09,	$09,	$0c,	$09

l0prio:	.byte	$c0,	$00,	$ff,	$00,	$00,	$00,	$ff,	$c0 
l1prio:	.byte	$c0,	$00,	$00,	$00,	$ff,	$00,	$00,	$c0
l2prio:	.byte 	$c0,	$00,	$ff,	$00,	$00,	$00,	$ff,	$00


//each room could have a collectable item.
//we keep track of that item being collected, so uppon re-entering a room we replace it with a radio
item_collected:
.fill 32,0

.pc = sid.location "sid"
.fill sid.size, sid.getData(i)

.pc = $7000 "hud font"
hud_font:
.fill 2*8,%01010101
.const digitpic = LoadPicture("..\assets\digits_shadow.png", List().add(0,$0000ff,$000001,$ffffff))
.for (var c = 0; c < 20; c++)
	.for (var b = 0; b < 8; b++)
		.byte digitpic.getMulticolorByte(c,b) 
/*		
.label SCORE_CHARS = (* - hud_font) / 8
.const scorepic = LoadPicture("..\assets\score.png", List().add($123456,$0000ff,$000000,$ffffff))
.for (var c = 0; c < 10; c++)
	.for (var b = 0; b < 8; b++)
		.byte scorepic.getMulticolorByte(c,b) 
*/				

.label HEAD_CHARS = (* - hud_font) / 8
.const headpic = LoadPicture("..\assets\head.png", List().add(0,$0000ff,$00ff00,$ff0000))
.fill 16, headpic.getMulticolorByte(0,i)
.fill 16, headpic.getMulticolorByte(1,i)



.pc = $7800 "charset"
chars:
.import binary "chars.bin"
.align 8
.pc = * "radar chars"
radar_chars:
.import binary "radar_chars.bin"




.pc = $4800 "sprites"
cop_sprites:
.const herospr = LoadBinary("..\sprites\hero.bin")
.for (var s = 0; s < 12; s++)
{
	.var spr0 = List()
	.var spr1 = List()
	.for (var j = 0; j < 64; j++)
	{
		.eval spr0.add(herospr.uget(s * 64 + j))
		.eval spr1.add(herospr.uget((s + 12) * 64 + j))
	}
	.fill 64, carve(spr0,spr1).get(i)
}
.fill 12 * 64, herospr.get(i + 12 * 64)

.for (var s = 0; s < 12; s++)
{
	.var spr0 = List()
	.var spr1 = List()
	.for (var j = 0; j < 64; j++)
	{
		.eval spr0.add(herospr.uget((s + 24) * 64 + j))
		.eval spr1.add(herospr.uget((s + 36) * 64 + j))
	}
	.fill 64, carve(spr0,spr1).get(i)
}
.fill 12 * 64, herospr.get(i + 36 * 64)



robber_sprites:
.import binary "..\sprites\robber.bin"
house_sprites:
.import binary "..\sprites\house.bin"
trolley_sprites:
.import binary "..\sprites\trolley.bin"
plane_sprites:
.import binary "..\sprites\plane.bin"
ball_sprites:
.import binary "..\sprites\ball.bin"
gold_sprite:
.import binary "..\sprites\gold.bin"
case_sprite:
.import binary "..\sprites\case.bin"
radio_sprites:
.import binary "..\sprites\radio.bin"

//this is just one single doublewidth pixel to be used on top of lives left sprites
badge_sprite:
.fill 3 * 20,0
.byte %11000000,0,0, 0

stopwatch_sprite:
.import binary "..\sprites\stopwatch.bin"

level_sprite:
.import binary "..\sprites\level.bin"

note_sprites:
.import binary "..\sprites\note.bin"

empty_sprite:
.fill 64,0

radar_escalator_sprites:
.import binary "..\sprites\radar_escalator.bin"
radar_elevator_sprites:
.import binary "..\sprites\radar_elevator.bin"
radar_man_sprite:
.byte 0,0,%00000010,0,0,%00000010
.align 64
logo_shadow_sprites:
.import binary "..\sprites\logo_shadow.bin"

//.pc = $7200 "sprites part 2"
getready_sprites:
.import binary "..\sprites\getready.bin"
gameover_sprites:
.import binary "..\sprites\gameover.bin"

hero_stunned_sprites:
.import binary "..\sprites\hero_stun.bin"

.pc = $3400 + 40 * 17 "credits"

//.text "                                        "
.text "             Adaptation by              "
.text "                                        "
.text "         A. Savona : Code               "
.text "            S. Day : Graphics           "
.text "          S. Cross : Music, Sfx         "
.text "                                        "
//.text " Copyright 1983, 1984  Activision, Inc. " 
.text "Joystick up / down : Selects level -    "
.text "       Fire button : Starts game        "

.pc = $b400 "splash screen scr"
.import binary "..\assets\credits.scr"
.pc = $a000 "splash screen map"
.const scm = LoadBinary("..\assets\credits.map")
.fill 16 * 320, scm.get(i)


//we put the rooms vertically. there's a lot of duplicate information, but the packer will take it away
.pc = $e400 "gamemap"
.var maplist = List()

gamemap:
.const mapf = LoadBinary("map.bin")

.for (var room = 0; room < 8; room++)
	.for (var y = 0; y < 20; y++)
		.for (var x = 0; x < 40; x++)
		{
			.var chr = mapf.uget(40 * room + x + 320 * y)
//			.var col = colf.uget(chr)
			.eval maplist.add(chr)
//			.eval collist.add(col)
		}

.fill maplist.size(), maplist.get(i)

.align $100
colortable:
.import binary "chars_color.bin"

map_idx:
.lohifill 8, [gamemap + 800 * i + 120]


radar_map:
.const rmf = LoadBinary("radar_map.bin")
.fill rmf.getSize(), rmf.uget(i) + (radar_chars - chars) / 8
radar_color:
.import binary "radar_color.bin"


elevator_map:
.fill 10,mapf.get(20 * 320 + i)
.fill 10,mapf.get(21 * 320 + i)
.fill 10,mapf.get(22 * 320 + i)


escalator_map_left:
.for (var j = 0; j < 4; j++)
{
	.fill 3, mapf.get(23 * 320 + j * 4 + i)
	.byte 0
}

escalator_map_right:
.for (var j = 0; j < 4; j++)
{
	.fill 3, mapf.get(16 + 23 * 320 + j * 4 + i)
	.byte 0
}

dial_map:
.fill 10,mapf.get(31 + 23 * 320 + i)

.pc = $c000 "loader bmp"
.fill 8000, kla.getBitmap(i)
.pc = $b800 "loader col"
.fill 1000, kla.getColorRam(i)
.pc = $e000 "loader scr"
.fill 1000, kla.getScreenRam(i)
