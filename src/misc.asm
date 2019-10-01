//this is the classic vblank. For all those cases where panelvsync is not needed  			
vsync:
{
				bit $d011
				bmi * -3
				bit $d011
				bpl * -3
				rts
}			

				
//we override the classic vblank with this. Our blank really starts at the Radar, and we need all the rastertime we can have
panelvsync:
{
			!:	lda redraw
				beq !-				
				lda #0
				sta redraw
				rts
}	

waitbutton:
{
			!:	jsr vsync
				
				lda  $dc00
				and #%00010000
				bne !-
				
				
			!:	jsr vsync
			
				lda $dc00
				and #%00010000
				beq !-
				
				rts	
}

//32 bit random number generator
random_:
{
		        asl random
		        rol random+1
		        rol random+2
		        rol random+3
		        bcc nofeedback
		        lda random
		        eor #$b7
		        sta random
		        lda random+1
		        eor #$1d
		        sta random+1
		        lda random+2
		        eor #$c1
		        sta random+2
		        lda random+3
		        eor #$04
		        sta random+3
		nofeedback:
        		rts

random: .byte $ff,$ff,$ff,$ff
}

//carves out spr1 from spr0)
.function carve(spr0,spr1)
{
	.var result = List()
	.for (var i = 0; i < 64; i++)
	{
		.var b0 = spr0.get(i)
		.var b1 = spr1.get(i)
		.var mask = 0
		.for (var m = %00000011; m < 256; m = m << 2)
		{
			.if ((b1 & m) != 0)
				.eval mask = mask | m	
		} 
		.eval result.add(b0 & $ff - mask)	
	}
	.return result
}

