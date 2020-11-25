#####################################################################
#
# CSCB58 Fall 2020 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Yining Wang, 1005723175
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
# - Milestone 1/2/3/4/5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). 
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp) #

.data
displayAddress:	.word	0x10008000  # base address for display
bgcolor: .word 0xffffff  # white
diecolor: .word 0x000000 # black
pfcolor: .word 0x00ff00  # green
ddcolor: .word 0x0000ff  # blue
ddpos_x: .word 100  # x of doodler
x_up: .word 0   # if >0, x go up  if =0 x go down
ddpos_y: .word 10  # y of doodler
pfpos: .space 80  # array for platform pos: [x1, y1, x2, y2, ...]


.text

main:
	# initialize first platform
	la $t1, pfpos
	addi $t2, $zero, 64   # add x1 to pfpos
	addi $t3, $zero, 20   # add y1 to pfpos
	sw $t2, 0($t1)
	sw $t3, 4($t1)

draw:
	# draw background
	#jal drawbg
	#drawbg:        
	lw $t0, displayAddress	# base address for display
	lw $t1, bgcolor		# red 
	
	add $t2, $zero, $zero  # offset
	add $t3, $zero, 4096  # limit
bg:	
	bge $t2, $t3, endbg
	add $t4, $t2, $t0 
	sw $t1, 0($t4)  # paint white background
	addi $t2, $t2, 4
	j bg
	
endbg:
	#jr $ra
	
	# check keyboard press
	lw $t8, 0xffff0000
 	beq $t8, 1, keyboard_input
 	j end_key
keyboard_input:  # a key is pressed
	lw $t2, 0xffff0004
	beq $t2, 0x6A, respond_to_J
	beq $t2, 0x6B, respond_to_K
	j end_key
respond_to_J:  # j is pressed, player should go left
	lw $t3, ddpos_x
	addi $t3, $t3, -4
	blez $t3, go_to_right
	j save_x_J
go_to_right:
	addi $t3, $t3, 128
save_x_J:
	sw $t3, ddpos_x
	j end_key
	
respond_to_K:  # k is pressed, player should go right
	lw $t3, ddpos_x
	addi $t3, $t3, 4
	addi $t4, $t4, 128
	bge $t3, $t4, go_to_left
	j save_x_K
go_to_left:
	addi $t3, $t3, -128
save_x_K:
	sw $t3, ddpos_x
	j end_key

end_key:

	# push random loc of platform to pfpos, draw platforms

	
	
	jal drawpf

	
	# calcullate loc
	lw $t3, ddpos_x
	lw $t4, ddpos_y
	sll $t4, $t4, 7
	
	# push loc of player to stack, draw player
	add $t2, $t3, $t4
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal drawdd	
	
	# check collide, return 1 if collide with platform
	jal is_collide
	lw $t2, 0($sp)
	addi $sp, $sp, 4 
	
	addi $t3, $zero, 1
	beq $t2, $t3, pf_collide
	j update_dd
	
# update new loc of doodler (increase) if collide
pf_collide:
	lw $t5, x_up
	addi $t5, $t5, 10  # go up for 10 times
	sw $t5, x_up
	
	
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
	# update new loc of doodler (rise) if collide
	lw $t4, ddpos_y
	addi $t4, $t4, -1
	sw $t4, ddpos_y	
	# decrease x_up by 1
	lw $t5, x_up
	addi $t5, $t5, -1
	sw $t5, x_up
	
	j sleep	
	
sleep:	
	# sleep
	li $v0, 32
	li $a0, 50
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
	lw $t3, 0($t2)  # x1
	lw $t4, 4($t2)  # y1

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
	jr $ra
	
	
#=========draw the doodler================
drawdd: 
	# load loc from stack
	lw $t2, 0($sp)  # start point
	lw $t0, displayAddress
	addi $sp, $sp, 4
	
	# draw player with particular shape
	lw $t1, ddcolor  # blue
	add $t2, $t2, $t0

	sw $t1, 0($t2) # paint blue player
	addi $t2, $t2, 124
	sw $t1, 0($t2) 
	addi $t2, $t2, 4
	sw $t1, 0($t2) 
	addi $t2, $t2, 4
	sw $t1, 0($t2)
	addi $t2, $t2, 120
	sw $t1, 0($t2)
	addi $t2, $t2, 8
	sw $t1, 0($t2)
	
	jr $ra

#=======check if doodler collide with platform======
is_collide:
	lw $t1, ddpos_x  # x of dd
	lw $t2, ddpos_y  # y of dd
	la $t3, pfpos    # array of platform pos
	
	add $t4, $zero, $zero  # counter
	addi $t5, $zero, 80  # limit for loop over pfpos
	
loop_pfpos:
	bge $t4, $t5, end_loop_pfpos
	add $s3, $t3, $t4  # s3: index of xi of pf
	lw $t6, 0($s3)  #t6: xi of pf
	addi $s4, $s3, 4  # t7: index of yi of pf
	lw $t7, 0($s4)  #t7: yi of pf
	
	# y_pf=y_dd+3
	addi $s0, $t2, 3  #y_dd+3
	bne $s0, $t7, end_if
	
	# x_pf - 4 <= x_dd <= x_pf + 40
	addi $s0, $t6, -4
	bgt $s0, $t1, end_if
	addi $s1, $t6, 40
	blt $s1, $t1, end_if
	
	# yes! they collide, push 1, end loop
	addi $s2, $zero, 1
	addi $sp, $sp, -4
	sw $s2, 0($sp)
	jr $ra
	
end_if:
	addi $t4, $t4, 8
	j loop_pfpos
	
	
end_loop_pfpos:
	addi $s2, $zero, 0
	addi $sp, $sp, -4
	sw $s2, 0($sp)
	jr $ra

#==============doodler died=============
died:
	# paint BYE, check if r is pressed
	lw $t0, displayAddress  # base address
	lw $t1, diecolor  # black
	
	addi $t2, $zero, 1340
	add $t2, $t2, $t0
	sw $t1, 0($t2) 

die_loop:
	
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
	# restart
	addi $t1, $zero, 100
	addi $t2, $zero, 10
	sw $t1, ddpos_x
	sw $t2, ddpos_y
	jr $ra


Exit:
	li $v0, 10 # terminate the program gracefully
	syscall

