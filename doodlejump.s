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
displayAddress:	.word	0x10008000
bgcolor: .word 0xffffff  # white
pfcolor: .word 0x00ff00  # green
ddcolor: .word 0x0000ff  # blue
ddpos_x: .word 100
ddpos_y: .word 15
	
.text

main:

draw:
	# draw background
	jal drawbg
	
	# check keyboard press
	lw $t8, 0xffff0000
 	beq $t8, 1, keyboard_input
 	j end_key
keyboard_input:
	lw $t2, 0xffff0004
	beq $t2, 0x6A, respond_to_J
	beq $t2, 0x6B, respond_to_K
	j end_key
respond_to_J:  # player should go left
	li $v0, 1		  
	la $a0, 7	
	syscall	
	j end_key
respond_to_K:  # player should go right
	li $v0, 1		  
	la $a0, 8	
	syscall	
	j end_key

end_key:
	# push loc of platform to stack, draw platforms
	add $t2, $zero, 1288
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal drawpf
	
	add $t2, $zero, 2200
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	jal drawpf
	
	add $t2, $zero, 3000
	addi $sp, $sp, -4
	sw $t2, 0($sp)
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
	
	# update new loc (drop)
	lw $t4, ddpos_y
	addi $t4, $t4, 1
	sw $t4, ddpos_y
	
	
	# sleep
	#li $v0, 32
	#li $a0, 1
	#syscall
	
        
        j draw

drawbg:        
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
	jr $ra
	
	

   
drawpf: 
	# load loc from stack
	lw $t2, 0($sp)  # start point
	lw $t0, displayAddress
	addi $sp, $sp, 4
	
	# draw platform, length is 4 pixels
	add $t3, $zero, $zero  # offset
	add $t4, $zero, 40  # limit
	lw $t1, pfcolor  # green
	
pf:
	bge $t3, $t4, endpf
	add $t5, $t3, $t2  # new loc
	add $t5, $t0, $t5
	sw $t1, 0($t5) # paint green platform
	addi $t3, $t3, 4
	j pf
	
endpf:
	jr $ra
	
	
	
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


Exit:
	li $v0, 10 # terminate the program gracefully
	syscall



