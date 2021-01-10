#####################################################################
#
# CSCB58 Fall 2020 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Yining Wang
#
# Bitmap Display Configuration:
# - Unit width in pixels: 16					     
# - Unit height in pixels: 16
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission? 
# (See the assignment handout for descriptions of the milestones)
# - Milestone 12345
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. scoreboard
# 2. dynamic increase in dufficulty
# 3. opponents
# 4. shooting (of doodler)
# 5. shield (for protection of doodler)
#
#
#####################################################################

.data
displayAddress:	.word	0x10008000  # base address for display
bgcolor: .word 0xffffff  # white
diecolor: .word 0x000000 # black
pfcolor: .word 0x00ff00  # green
ddcolor: .word 0x0000ff  # blue
ddpos_x: .word 60  # x of doodler
x_up: .word 0   # if >0, x go up  if =0 x go down
ddpos_y: .word 10  # y of doodler
pfpos: .space 24  # array for platform pos: [x1, y1, x2, y2, x3, y3]
move_pf_index: .word 0, 0, 0  # corresponding to i th pf can move 

score: .word 0
collide_pf: .space 8  # store address of current collide pf in pfpos
add_score: .word 0  # if 1, then add score

pix_0: .word 1,1,1,1,0,1,1,0,1,1,0,1,1,1,1  # 0 on screen with 15 pix
pix_1: .word 0,0,1,0,0,1,0,0,1,0,0,1,0,0,1
pix_2: .word 1,1,1,0,0,1,1,1,1,1,0,0,1,1,1
pix_3: .word 1,1,1,0,0,1,1,1,1,0,0,1,1,1,1
pix_4: .word 1,0,1,1,0,1,1,1,1,0,0,1,0,0,1
pix_5: .word 1,1,1,1,0,0,1,1,1,0,0,1,1,1,1
pix_6: .word 1,1,1,1,0,0,1,1,1,1,0,1,1,1,1
pix_7: .word 1,1,1,1,0,1,0,0,1,0,0,1,0,0,1
pix_8: .word 1,1,1,1,0,1,1,1,1,1,0,1,1,1,1
pix_9: .word 1,1,1,1,0,1,1,1,1,0,0,1,1,1,1
scoreAddress: .word 0x10008010  # base address for score (one's)

ms_pos: .word 0, 0  # x, y position of monster 0,0 means no monster
mscolor: .word 0x785027  # brown

bl_pos: .word 0,0,0,0,0,0,0,0  # bullet [x1, y1, x2, y2, x3, y3, x4, y4]
blcolor: .word 0x9932cc  # purple

shd_pos: .word 0, 0  # x, y pos of shield
shdcolor: .word 0x1e7b5c  # dark green
dd_protected: .word 0  # 0 means not protected

newline: .asciiz "\n"

.text

main:
	# initialize platform
	la $t1, pfpos
	addi $t2, $zero, 64   # add x1 to pfpos
	addi $t3, $zero, 30    # add y1 to pfpos
	sw $t2, 0($t1)
	sw $t3, 4($t1)
	
	
	li $v0, 42
	li $a0, 0
	li $a1, 21  # random x2 <= 21
	syscall
	move $t2, $a0
	sll $t2, $t2, 2
	sw $t2, 8($t1)

	addi $t3, $zero, 20
	sw $t3, 12($t1)
	
	li $v0, 42
	li $a0, 0
	li $a1, 21  # random x3 <= 21
	syscall
	move $t2, $a0
	sll $t2, $t2, 2
	sw $t2, 16($t1)

	addi $t3, $zero, 10
	sw $t3, 20($t1)

	
draw:
	# draw background
	lw $t0, displayAddress	# base address for display
	lw $t1, bgcolor		# white 
	
	add $t2, $zero, $zero  # offset
	add $t3, $zero, 4096  # limit
bg:	
	bge $t2, $t3, endbg
	add $t4, $t2, $t0 
	sw $t1, 0($t4)  # paint white background
	addi $t2, $t2, 4
	j bg
	
endbg:
	
	# check keyboard press
	lw $t8, 0xffff0000
 	beq $t8, 1, keyboard_input
 	j end_key
keyboard_input:  # key is pressed
	lw $t2, 0xffff0004
	beq $t2, 0x6A, respond_to_J
	beq $t2, 0x6B, respond_to_K
	beq $t2, 0x20, respond_to_SPACE
	j end_key
respond_to_J:  # j is pressed, player should go left
	lw $t3, ddpos_x
	addi $t3, $t3, -4
	blez $t3, go_to_right
	j save_x_J
go_to_right:  # go to right of screen
	addi $t3, $t3, 128
save_x_J:
	sw $t3, ddpos_x
	j end_key
	
respond_to_K:  # k is pressed, player should go right
	lw $t3, ddpos_x
	addi $t3, $t3, 4
	addi $t4, $zero, 128
	bge $t3, $t4, go_to_left
	j save_x_K
go_to_left:  # go to left of screen
	addi $t3, $t3, -128
save_x_K:
	sw $t3, ddpos_x
	j end_key
	
respond_to_SPACE:  # add a bullet to bl_pos
	jal add_bullet
	j end_key

end_key:
	# draw platforms
	jal drawpf
	# draw bullet
	jal draw_bullet
	# draw shield pixel
	jal draw_shield
	
	# calcullate loc of doodler
	lw $t3, ddpos_x
	lw $t4, ddpos_y
	sll $t4, $t4, 7
	
	
	# push loc of doodler to stack, draw doodler
	add $t2, $t3, $t4
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal drawdd	
	
	
	
	# randomly generate monster (<=1)
	la $t2, ms_pos  # address of ms_pos
	lw $t4, 4($t2)  # y of ms pos
	bnez $t4, go_draw_ms  # y != 0 -> have a monster now
	j not_draw_ms
go_draw_ms:
	jal draw_ms  # function to draw monster
	# update position of mos if score > 15
	lw $s0, score
	addi $s1, $zero, 15
	blt $s0, $s1, not_move_ms  # skip update ms
	# x move left and right, y together with pf until > 32, then become 0
	jal update_ms_x
	# check if doodler collide with monster, if return 1, then die
not_move_ms:
	jal is_collide_with_ms
	lw $t2, 0($sp)
	addi $sp, $sp, 4 
	
	addi $t3, $zero, 1
	bne $t2, $t3, no_collide_ms
	jal died
no_collide_ms:
	j end_ms
	
not_draw_ms:
	li $v0, 42
	li $a0, 0
	li $a1, 30  # if a1 is 1, then generate monster
	syscall
	addi $t1, $zero, 1  # constant 1
	beq $a0, $t1, generate_ms
	j end_ms
generate_ms:
	li $v0, 42
	li $a0, 0
	li $a1, 21  # random ms xi <= 21
	syscall
	move $t3, $a0
	sll $t3, $t3, 2
	sw $t3, 0($t2)  # x of ms
	sw $t1, 4($t2)  # y of ms is 1 by default
	
end_ms:	

	

	# check collide, return 1 if collide with platform
	la $t4, x_up
	lw $t5, 0($t4)
	
	bgtz $t5, update_dd
	
	jal is_collide
	lw $t2, 0($sp)
	addi $sp, $sp, 4 
	
	addi $t3, $zero, 1
	beq $t2, $t3, pf_collide
	j update_dd
	
# update new loc of doodler (increase) if collide
pf_collide:
	lw $t5, x_up
	addi $t5, $t5, 12  # go up for 12 times
	sw $t5, x_up
	
	# if add_score != 0, score += 1
	
	lw $t7, add_score
	lw $t6, score
	beqz $t7, update_dd
	addi $t6, $t6, 1
	sw $t6, score
	
	
update_dd:
	lw $t4, x_up
	beqz $t4, update_no_collide
	j update_is_collide
update_no_collide:	
	# update new loc of doodler (drop) if no collide
	lw $t4, ddpos_y
	addi $t4, $t4, 1
	sw $t4, ddpos_y
	j sleep
update_is_collide:
	# if dd_y < 9, then dd_y remain same, but all platform drop
	lw $t4, ddpos_y
	addi $t6, $zero, 9
	bge $t4, $t6, dd_rise
	j pf_drop
	
pf_drop:
	# decrease y1, y2, y3
	# if yi > 32, randomly gererate new pair and replace
	la $t1, pfpos
	add $s0, $zero, $zero  # counter for pair i
	add $s1, $zero, 24  # limit for pair
	add $s4, $zero, 31  # lower bound of screen 
	
	# also decrease monster y
	la $s6, ms_pos
	lw $t8, 4($s6)
	beqz $t8, dec_pf_pair
	addi $t8, $t8, 1
	sw $t8, 4($s6)
	# if > 32, set to 0
	addi $t9, $zero, 32
	ble $t8, $t9, dec_pf_pair
	sw $zero, 4($s6)
	
	
dec_pf_pair:
	bge $s0, $s1, end_dec_pc_pair
	add $s3, $s0, $t1
	#lw $t3, 0($s3)  # xi
	lw $t4, 4($s3)  # yi
	addi $t4, $t4, 1
	bgt $t4, $s4, generate_new  # yi > 32, randomly generate x
	sw $t4, 4($s3)
	j cont_loop
generate_new:
	li $v0, 42
	li $a0, 0
	li $a1, 21  # random xi <= 21
	syscall
	move $t3, $a0
	sll $t3, $t3, 2
	sw $t3, 0($s3)
	addi $t4, $t4, -30
	sw $t4, 4($s3)

cont_loop:
	add $s0, $s0, 8
	j dec_pf_pair
	
end_dec_pc_pair:
	j decr_x_up
dd_rise:
	# update new loc of doodler (rise) if collide
	lw $t4, ddpos_y
	addi $t4, $t4, -1
	sw $t4, ddpos_y	
	j decr_x_up

decr_x_up:	
	# decrease x_up by 1
	lw $t5, x_up
	addi $t5, $t5, -1
	sw $t5, x_up

	j sleep	
	
sleep:	
	la $t0, shd_pos
	lw $t1, 0($t0)  # x
	lw $t2, 4($t0)  # y
	
	# generate shield if x = y = 0, dd_protected = 0
	bnez $t1, go_update_shd
	bnez $t2, go_update_shd
	jal generate_shd
	j end_update_shd
go_update_shd:
	# update pos of shield if x, y != 0, 0
	jal update_shd

end_update_shd:
	# check if shd collide with doodler
	# if collide, shd reset to (0, 0), dd_protected is 20
	# doodler become green for 20 times, change color, won't die on monster
	# dd_protected should decrease by 1 every loop until 0
	jal collide_shd_dd
	
	lw $t1, dd_protected
	bgtz $t1, dec_dd_protected
	j end_dec_dd_protected
dec_dd_protected:
	addi $t1, $t1, -1
	sw $t1, dd_protected

end_dec_dd_protected:

	# draw bullet
	jal update_bullet
	jal bullet_collide_ms

	# if score is 10 or 20 or 30, add a move block
	lw $t1, score
	
	addi $t2, $zero, 10
	addi $t5, $zero, 1
	beq $t1, $t2, add_move_one
	addi $t2, $t2, 10
	beq $t1, $t2, add_move_two
	addi $t2, $t2, 10
	beq $t1, $t2, add_move_three
	j end_add_move

add_move_one:
	la $t3, move_pf_index
	addi $t4, $zero, 8
	add $t4, $t3, $t4
	lw $t6, 0($t4)
	bne $t6, $zero, end_add_move
	sw $t5, 0($t4)
	j end_add_move

add_move_two:
	la $t3, move_pf_index
	addi $t4, $zero, 4
	add $t4, $t3, $t4
	lw $t6, 0($t4)
	bne $t6, $zero, end_add_move
	sw $t5, 0($t4)
	j end_add_move
	
add_move_three:
	la $t3, move_pf_index
	addi $t4, $zero, 0
	add $t4, $t3, $t4
	lw $t6, 0($t4)
	bne $t6, $zero, end_add_move
	sw $t5, 0($t4)
	j end_add_move


end_add_move:
	# if pf i is move, then update xi
	la $t1, move_pf_index
	add $t2, $zero, $zero  # counter
	addi $t3, $zero, 12  # limit of move_pf_index
	la $s1, pfpos
	
	
move_loop:
	bge $t2, $t3, finish_move
	add $t4, $t2, $t1  # index of move_pf_index
	lw $t5, 0($t4)  # 0 or 1 or -1
	bgt $t5, $zero, move_right_pf_x  # 1, then update xi
	blt $t5, $zero, move_left_pf_x
	j no_update_x
move_right_pf_x:
	sll $s2, $t2, 1
	add $s3, $s2, $s1 
	lw $s4, 0($s3)  # x_i
	addi $s4, $s4, 4
	# if x_i >= 92, then change move_pf_index to -1(move to left)
	sw $s4, 0($s3)
	addi $s6, $zero, 92
	bge $s4, $s6, change_to_left
	j no_update_x
change_to_left:
	addi $s5, $zero, -1
	sw $s5, 0($t4)
	
move_left_pf_x:
	sll $s2, $t2, 1
	add $s3, $s2, $s1 
	lw $s4, 0($s3)  # x_i
	addi $s4, $s4, -4
	# if x_i < 0, then change move_pf_index to 1(move to right)
	sw $s4, 0($s3)
	ble $s4, $zero, change_to_right
	j no_update_x
change_to_right:
	addi $s5, $zero, 1
	sw $s5, 0($t4)
	
no_update_x:
	addi $t2, $t2, 4
	j move_loop
	
finish_move:

	

display_score:
	# display score
	jal drawsc
	
	# sleep
	# sleep time = min{60 - score, 30}
	lw $t0, score
	addi $t1, $zero, 60
	#sll $t0, $t0, 1
	sub $t0, $t1, $t0
	addi $t2, $zero, 30
	blt $t0, $t2, max_speed
	j end_adjust_speed
max_speed:
	addi $t0, $zero, 30
end_adjust_speed:
	li $v0, 32
	#li $a0, 80
	move $a0, $t0
	syscall
	
        # check if doodler die (y > 32), if die, end central loop
        lw $t2, ddpos_y
        
        addi $t1, $zero, 32
        bgt $t2, $t1, die
        j redraw
die:
	jal died
        
redraw:
        j draw


#=========draw the platform================

drawpf: 
	# load loc from stack
	lw $t0, displayAddress  # base address
	lw $t1, pfcolor  # green
	la $t2, pfpos  # array
	
	add $s0, $zero, $zero  # counter for pair i
	add $s1, $zero, 24  # limit for pair
	
pf_pair:
	bge $s0, $s1, end_pf_pair
	add $s3, $s0, $t2
	lw $t3, 0($s3)  # x1
	lw $t4, 4($s3)  # y1

	sll $t4, $t4, 7
	add $t4, $t3, $t4
	
	# draw platform, length is 10 units
	add $t5, $zero, $zero  # offset
	add $t6, $zero, 40  # limit
	
	
pf:
	bge $t5, $t6, endpf
	add $t7, $t0, $t4  # new loc
	add $t7, $t7, $t5
	sw $t1, 0($t7) # paint green platform
	addi $t5, $t5, 4
	j pf
	
endpf:
	addi $s0, $s0, 8
	j pf_pair
	
end_pf_pair:
	jr $ra
	
	
#=========draw the doodler================
drawdd: 
	# load loc from stack
	lw $t2, 0($sp)  # start point
	lw $t0, displayAddress
	addi $sp, $sp, 4
	
	# draw player with particular shape
	lw $t1, ddcolor  # blue
	# if dd_protected > 0, draw with dark green
	lw $t3, dd_protected
	beqz $t3, cont_draw_dd
draw_dd_gr:
	lw $t1, shdcolor
cont_draw_dd:
	add $t2, $t2, $t0

	sw $t1, 0($t2) # paint blue player
	sw $t1, 124($t2) 
	sw $t1, 128($t2) 
	sw $t1, 132($t2)
	sw $t1, 252($t2)
	sw $t1, 260($t2)
	
	jr $ra
	
#=========draw the monster================
draw_ms:
	lw $t0, displayAddress
	la $t1, ms_pos
	lw $t2, mscolor  # brown
	lw $t3, 0($t1)  # x of ms
	lw $t4, 4($t1)  # y of ms
	
	# draw brown pixel at x, y
	
	sll $t4, $t4, 7
	add $t5, $t3, $t4 
	add $t5, $t5, $t0  # address of ms
	sw $t2, 0($t5)
	
	jr $ra

#=========update x of monster=======================
update_ms_x:
	la $t1, ms_pos
	lw $t2, 0($t1)  # x of ms
	addi $t2, $t2, 4
	sw $t2, 0($t1)
	
	addi $t3, $zero, 128
	bge $t2, $t3, monster_to_left
	jr $ra
monster_to_left:
	sw $zero, 0($t1)
	jr $ra


#=======check if doodler collide with platform======
is_collide:
	lw $t1, ddpos_x  # x of dd
	lw $t2, ddpos_y  # y of dd
	la $t3, pfpos    # array of platform pos

	
	add $t4, $zero, $zero  # counter
	addi $t5, $zero, 24  # limit for loop over pfpos
	
loop_pfpos:
	bge $t4, $t5, end_loop_pfpos
	add $s3, $t3, $t4  # s3: index of xi of pf
	lw $t6, 0($s3)  #t6: xi of pf
	addi $s4, $s3, 4  # s4: index of yi of pf
	lw $t7, 0($s4)  #t7: yi of pf
	
	# y_pf = y_dd + 3
	addi $s0, $t2, 3  # y_dd + 3
	bne $s0, $t7, end_if
	
	# x_pf - 4 <= x_dd <= x_pf + 40
	addi $s0, $t6, -4
	bgt $s0, $t1, end_if
	addi $s1, $t6, 40
	blt $s1, $t1, end_if
	
	# yes! they collide, push 1 to stack, end loop
	addi $s2, $zero, 1
	addi $sp, $sp, -4
	sw $s2, 0($sp)
	# check if collide with same platform
	la $t8, collide_pf
	lw $s5, 0($t8)  # previous colliding xi
	lw $s6, 4($t8)  # previous colliding yi
	# if same as current, add_score is 0
	# else add_score is 1, update collide_pf
	bne $s5, $s3, do_add_score
	bne $s6, $s4, do_add_score
	# not add score
	sw $zero, add_score
	j after_score
	# store the address [xi, yi] into collide_pf
do_add_score:
	sw $s2, add_score  # 1
	sw $s3, 0($t8)
	sw $s4, 4($t8)
after_score:
	jr $ra
	
end_if:
	addi $t4, $t4, 8
	j loop_pfpos
	
	
end_loop_pfpos:
	# not collide, push 0 to stack
	addi $s2, $zero, 0
	addi $sp, $sp, -4
	sw $s2, 0($sp)
	jr $ra
	
#=============check if ms collide with doodler=================
is_collide_with_ms:
	# return 1 if collide, return 0 if not
	# if dd_protected > 0, return 0
	lw $s0, dd_protected
	bgtz $s0, not_collide_ms
	
	la $t0, ms_pos
	lw $t1, ddpos_x  # x of doodler
	lw $t2, ddpos_y  # y of doodler
	lw $t3, 0($t0)  # x of monster
	lw $t4, 4($t0)  # y of monster
	
	addi $s1, $t3, -4
	addi $s2, $t3, 4
	addi $s3, $t4, -2
	
	blt $t1, $s1, not_collide_ms
	bgt $t1, $s2, not_collide_ms
	bgt $t2, $t4, not_collide_ms
	blt $t2, $s3, not_collide_ms
	# yes! they collide, return 1
	addi $s4, $zero, 1
	addi $sp, $sp, -4
	sw $s4, 0($sp)
	jr $ra
not_collide_ms:
	addi $s4, $zero, 0
	addi $sp, $sp, -4
	sw $s4, 0($sp)
	jr $ra
#===========draw score=================
drawsc:
	lw $t0, score
	addi $t1, $zero, 10
	div $t0, $t1
	mfhi $t2  # t2: remainder, one place
	mflo $t3  # t3: quotient, ten place
	addi $t1, $zero, 1 # initialize t1 to 1
	
	lw $t4, scoreAddress  # address for score
	add $t9, $zero, $zero  # initialize t9 to 0

draw_digit:
	# know decimal num, get pix_i
	# one place
	beqz $t2, loadzero
	beq $t2, $t1, loadone
	addi $t1, $t1, 1
	beq $t2, $t1, loadtwo
	addi $t1, $t1, 1
	beq $t2, $t1, loadthree
	addi $t1, $t1, 1
	beq $t2, $t1, loadfour
	addi $t1, $t1, 1
	beq $t2, $t1, loadfive
	addi $t1, $t1, 1
	beq $t2, $t1, loadsix
	addi $t1, $t1, 1
	beq $t2, $t1, loadseven
	addi $t1, $t1, 1
	beq $t2, $t1, loadeight
	addi $t1, $t1, 1
	j loadnine  
	
loadzero:
	la $s0, pix_0
	j finish_load
loadone:
	la $s0, pix_1
	j finish_load
loadtwo:
	la $s0, pix_2
	j finish_load
loadthree:
	la $s0, pix_3
	j finish_load
loadfour:
	la $s0, pix_4
	j finish_load
loadfive:
	la $s0, pix_5
	j finish_load
loadsix:
	la $s0, pix_6
	j finish_load
loadseven:
	la $s0, pix_7
	j finish_load
loadeight:
	la $s0, pix_8
	j finish_load
loadnine:
	la $s0, pix_9
	j finish_load

	

finish_load: 
	# len 15 array is in s0 now
	lw $t5, diecolor  # black
	# first calculate x,y ([0,0] to [4,2])
	add $t1, $zero, $zero  # counter
	addi $t6, $zero, 60  # limit
	addi $t7, $zero, 12  # divider
scoreloop:
	bge $t1, $t6, end_scoreloop
	add $t8, $t1, $s0  # index in array
	lw $t8, 0($t8)   # 0 or 1 in array
	beqz $t8, not_draw_pix
	div $t1, $t7
	mfhi $a1  # y
	mflo $a2  # x
	sll $a2, $a2, 7
	add $a1, $a2, $a1  # 128x + y is offset
	add $a3, $a1, $t4  # address to draw
	sw $t5, 0($a3)  # draw black
not_draw_pix:
	addi $t1, $t1, 4
	j scoreloop
	
end_scoreloop:
        bnez $t9, end_drawsc  # if t9 is 1, end function
	move $t2, $t3   # draw ten's place
	lw $t4, displayAddress  # address of ten's place
	addi $t9, $zero, 1  # set t9 to 1
	addi $t1, $zero, 1  # reset t1
	j draw_digit
end_drawsc:	
	jr $ra
						
#=============add a bullet===============
add_bullet:
	lw $t0, ddpos_x  # x of dd
	lw $t1, ddpos_y  # y of dd
	la $t2, bl_pos  # array of pos of bullet
	# loop through to find 0,0 
	add $t3, $zero, $zero  # counter
	addi $t4, $zero, 32
	
add_bl_loop:
	bge $t3, $t4, end_add_bl_loop
	add $t5, $t3, $t2  # address of xi
	lw $t6, 0($t5)  # xi
	lw $t7, 4($t5)  # yi
	
	bnez $t6, skip_add_bl_loop
	bnez $t7, skip_add_bl_loop
	# xi = yi = 0, xi = ddpos_x, y = ddpos_y-1, end loop
	sw $t0, 0($t5)
	addi $t8, $t1, -1
	sw $t8, 4($t5)
	j end_add_bl_loop
skip_add_bl_loop:
	addi $t3, $t3, 8
	j add_bl_loop
	
end_add_bl_loop:
	
	jr $ra

#==============draw bullet==============
draw_bullet:
	la $t0, bl_pos
	lw $t1, blcolor # color
	lw $t2, displayAddress
	# if xi, yi != 0, draw bullet
	add $t3, $zero, $zero  # counter
	addi $t4, $zero, 32
	
draw_bl_loop:	
	bge $t3, $t4, end_draw_bl_loop
	add $t5, $t3, $t0
	lw $t6, 0($t5)  # xi
	lw $t7, 4($t5)  # yi
	
	bnez $t6, draw_a_bl
	bnez $t7, draw_a_bl
	j end_draw_a_bl
	
draw_a_bl:
	# compute address
	sll $t7, $t7, 7
	add $t7, $t6, $t7 
	add $t7, $t2, $t7
	sw $t1, 0($t7)
end_draw_a_bl:
	addi $t3, $t3, 8
	j draw_bl_loop
	
end_draw_bl_loop:
	jr $ra
	
#==============update position of bullet=============
update_bullet:
	la $t0, bl_pos
	# if xi, yi != 0, yi -= 1
	add $t3, $zero, $zero  # counter
	addi $t4, $zero, 32
	
update_bl_loop:
	bge $t3, $t4, end_update_bl
	
	add $t5, $t3, $t0
	lw $t6, 0($t5)  # xi
	lw $t7, 4($t5)  # yi
	
	bnez $t6, update_nl
	bnez $t7, update_nl
	j skip_update_nl
update_nl:
	addi $t7, $t7, -1
	sw $t7, 4($t5)
	# if yi < 0, then reset xi=yi=0
	beqz $t7, reset_bl
	j skip_update_nl
reset_bl:
	sw $zero, 0($t5)
	sw $zero, 4($t5)

skip_update_nl:
	addi $t3, $t3, 8
	j update_bl_loop
	
end_update_bl:
	jr $ra
	
	
#=============check if bullet collide with ms=========
bullet_collide_ms:
	la $t0, bl_pos
	la $t1, ms_pos
	
	lw $t2, 0($t1)  # x_ms
	lw $t3, 4($t1)  # y_ms
	
	# if x_ms = x_bl, y_ms = y_bl, then x_ms = y_ms = 0
	add $t4, $zero, $zero  # counter
	addi $t5, $zero, 32
bl_ms_loop:
	bge $t4, $t5, end_bl_ms_loop
	add $t6, $t0, $t4
	lw $s1, 0($t6)  # x_bl
	lw $s2, 4($t6)  # y_bl
	bne $s1, $t2, skip_bl_ms_loop
	bne $s2, $t3, skip_bl_ms_loop
	# reset ms
	sw $zero, 0($t1)
	sw $zero, 4($t1)
skip_bl_ms_loop:
	addi $t4, $t4, 8
	j bl_ms_loop

end_bl_ms_loop:

	jr $ra
	
	
#==============draw pixel of shield=========
draw_shield:
	lw $s0, dd_protected
	bgtz $s0, end_draw_a_shd

	la $t0, shd_pos
	lw $t1, shdcolor # color
	lw $t2, displayAddress
	# if xi, yi != 0, draw shield pix
	
	lw $t3, 0($t0)  # x
	lw $t4, 4($t0)  # y

	bnez $t3, draw_a_shd
	bnez $t4, draw_a_shd
	j end_draw_a_shd
	
draw_a_shd:
	# compute address
	sll $t4, $t4, 7
	add $t4, $t3, $t4
	add $t4, $t4, $t2
	sw $t1, 0($t4)

end_draw_a_shd:
	jr $ra


#=============randomly generate shield============
generate_shd:
	li $v0, 42
	li $a0, 0
	li $a1, 50
	syscall
	move $t0, $a0
	# if t0 is 1, then generate new shd
	addi $t1, $zero, 1
	bne $t0, $t1, end_generate_shd
	
	# always at pf:[x3 + 20, y3 - 1]
	la $t2, pfpos
	lw $s0, 16($t2)  # x3
	lw $s1, 20($t2)  # y3
	addi $s0, $s0, 20
	addi $s1, $s1, -1
	
	la $t3, shd_pos  # address of shd
	sw $s0, 0($t3)
	sw $s1, 4($t3)
	
end_generate_shd:
	jr $ra


#============update pos of shd============
update_shd:
	# always at pf:[x3 + 20, y3 - 1]
	la $t2, pfpos
	lw $s0, 16($t2)  # x3
	lw $s1, 20($t2)  # y3
	addi $s0, $s0, 20
	addi $s1, $s1, -1
	
	la $t3, shd_pos  # address of shd
	# if y > 32, become (0, 0)
	addi $t4, $zero, 30
	bge $s1, $t4, reset_shd

	# if dd_protected > 0, become (0, 0)
	lw $t5, dd_protected
	bgtz $t5, reset_shd
	j set_shd_pos
reset_shd:
	sw $zero, 0($t3)
	sw $zero, 4($t3)
	jr $ra
set_shd_pos:	
	sw $s0, 0($t3)
	sw $s1, 4($t3)
	jr $ra

#===========check if shd pixel collide with dd==========
collide_shd_dd:
	la $t0, shd_pos
	lw $t1, 0($t0)  # x_shd
	lw $t2, 4($t0)  # y_shd
	lw $t3, ddpos_x # x_dd
	lw $t4, ddpos_y # y_dd
	
	addi $t5, $t3, -4  # x_dd - 4
	addi $t6, $t3, 4  # x_dd + 4
	addi $t7, $t4, 3  # y_dd + 3
	
	blt $t1, $t5, not_collide_shd_dd
	bgt $t1, $t6, not_collide_shd_dd
	blt $t2, $t4, not_collide_shd_dd
	bgt $t2, $t7, not_collide_shd_dd
	# yes! dd collide with shd
	addi $t7, $zero, 40
	sw $t7, dd_protected
	# reset shd to 0,0
	sw $zero, 0($t0)  # x_shd
	sw $zero, 4($t0)  # y_shd


not_collide_shd_dd:
	jr $ra
	
	

	
#==============doodler died=============
died:
die_loop:
	# paint BYE, check if r is pressed
	lw $t0, displayAddress  # base address
	lw $t1, diecolor  # black
	
	addi $t2, $zero, 1320
	add $t2, $t2, $t0
	sw $t1, 0($t2) 
	sw $t1, 128($t2) 
	sw $t1, 256($t2) 
	sw $t1, 260($t2) 
	sw $t1, 264($t2) 
	sw $t1, 392($t2)
	sw $t1, 520($t2)
	sw $t1, 516($t2)
	sw $t1, 512($t2)
	sw $t1, 384($t2) 
	
	sw $t1, 20($t2) 
	sw $t1, 148($t2) 
	sw $t1, 152($t2) 
	sw $t1, 156($t2) 
	sw $t1, 28($t2) 
	sw $t1, 284($t2)
	sw $t1, 412($t2)
	sw $t1, 540($t2)
	sw $t1, 536($t2)
	sw $t1, 532($t2) 
	
	sw $t1, 40($t2) 
	sw $t1, 44($t2) 
	sw $t1, 48($t2) 
	sw $t1, 168($t2) 
	sw $t1, 296($t2) 
	sw $t1, 300($t2) 
	sw $t1, 304($t2)
	sw $t1, 424($t2)
	sw $t1, 552($t2)
	sw $t1, 556($t2)
	sw $t1, 560($t2) 

	
	# check keyboard press
	lw $t8, 0xffff0000
 	beq $t8, 1, die_keyboard_input
 	j die_no_key
die_keyboard_input:  # a key is pressed
	lw $t2, 0xffff0004
	beq $t2, 0x73, respond_to_S
die_no_key:
	# sleep
	li $v0, 32
	li $a0, 50
	syscall
	j die_loop
	
respond_to_S:
	# restart the game
	addi $t1, $zero, 60
	addi $t2, $zero, 10
	sw $t1, ddpos_x
	sw $t2, ddpos_y
	sw $zero, score
	la $t3, collide_pf
	sw $zero, 0($t3)
	sw $zero, 4($t3)
	la $t1, move_pf_index
	sw $zero, 0($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	la $t1, ms_pos
	sw $zero, 0($t1)
	sw $zero, 4($t1)	
	la $t1, bl_pos
	sw $zero, 0($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	sw $zero, 12($t1)
	sw $zero, 16($t1)
	sw $zero, 20($t1)
	sw $zero, 24($t1)
	sw $zero, 28($t1)
	la $t1, shd_pos
	sw $zero, 0($t1)
	sw $zero, 4($t1)
	lw $zero, dd_protected
	jr $ra


Exit:
	li $v0, 10 # terminate the program gracefully
	syscall

