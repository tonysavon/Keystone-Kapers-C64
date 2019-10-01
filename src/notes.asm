/*
Few noticeable design choices. These notes are the result of the RE of the A8 Code.

Time: the clock decreases by one unit every 128 frames.

The beachballs always move at one pix/frame. They do a low bounce initially, but after level 5 they bounce all the way up

The the thief must always be ahead of you. if you surpass the robber (e.g. you are on the same floor and in the direction he is running towards, he changes direction. Which means that if you are on the top floor, and he goes down, there is no way to catch him)

The elevator always spends 127 * 8 frames at a level. If you are on board, it only spends 24*8 frames.
After level 8, the elevator starts to be "smart". It still spends 128 frames on a level, unless you are on the same level. In which case, it doubles the frame count. So it can be as quick as 64 frames.
In the original, the elevator's position is not initialized at every game, which is quite likely a bug. This allows you to start a game when the elevator is in a convenient position. Also, upon finishing a level, the elevator starts from the same floor you left it on the previous level.
The laster "feature" has been preserved, but the initial positioning of the elevator is now pseudo-random:
	Starting floor is now randomly chosen between level 1 and 2, Level 0 being the one at which the cop starts.
	Starting elevator-clock is a random number between 0 and 127 (at 128 the elevator moves to another floor)
	In case the starting level is 1, the direction is random. if the starting level is 2, the direction is of course down.

	 

-------------------
Objects positioning

B  = ball
P  = plane	 p = random direction plane
C  = case
G  = gold
T  = trolley t = random direction trolley
A  = alarm


level1	room0	room1	room2	room3	room4	room5	room6	room7
	 0:									G
	 1:									B		C
	 2:							B				G
	 3:					B						C		B
	 	 												
	 	 												
level2	room0	room1	room2	room3	room4	room5	room6	room7
	 0:			A								A		A
	 1:			A						B		C
	 2:							B		A		G
	 3:					B						C		B
	 
	 
level3	room0	room1	room2	room3	room4	room5	room6	room7
	 0:			A		G		T		T		A		A
	 1:			A				T		B		C
	 2:					T		B		A		G		T
	 3:			T		B						C		B

	 	 
level4	room0	room1	room2	room3	room4	room5	room6	room7
	 0:			A		A		T		T		A		G
	 1:			A		P		T		B		C		P
	 2:			P		T		B		A		G		T
	 3:			T		B				P		C		B

	 	 
level5	room0	room1	room2	room3	room4	room5	room6	room7
	 0:			A		A		T		T		G		A
	 1:			A		P		T		B		C		P
	 2:			P		T		B		A		G		T
	 3:			T		B				P		C		B
	
	 
level6	room0	room1	room2	room3	room4	room5	room6	room7
	 0:			AA		G		T		T		AA		AA
	 1:			AA		P		T		B		C		P
	 2:			P		T		B		AA		G		T
	 3:			T		B		AA		P		C		B
	

level7	room0	room1	room2	room3	room4	room5	room6	room7	//trolleys speed is now 4 pix/frame and direction is random
	 0:			AA		AA		t		t		G		AA
	 1:			AA		P		t		B		C		P
	 2:			G		T		B		AA		G		t
	 3:			T		B		AA		P		C		B
		 
	 	 
level8	room0	room1	room2	room3	room4	room5	room6	room7	//planes are now 4 pix/frame and random direction
	 0:			AA		AA		t		t		G		AA
	 1:			AA		p		t		C		AA		p
	 2:			p		G		B		AA		p		t
	 3:			T		B		AA		P		C		B	 
	 

After level 8 objects are always in the same position.
	 
level 7 / trolleys now move at 4 pixels/frame and direction is random	 
level 8 / planes now move at 4 pixels/frame and direction is random
level 11/ trolleys are back to 2 pixels/frame, but it's two of them per level.
level 12/ planes now move at 6 pix/frame
level 15/ trolleys are back to 1 trolley per floor, but they move at 8 pixels per frame!
level 16/ planes now move at 8 pixels per frame	 
	 
*/