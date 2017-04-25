# Connect 4

# Written by:
# Matthew Dumler
# Brandon Penny
# Chris Wilson

# Licensed under:
# MIT License

# Copyright (c) 2017 Matthew Dumler, Brandon Penny, Chris Wilson

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

 	.data
pc_cnt: .byte 0:7   # array storing the number of pieces in each column
prompt: .asciiz "Please enter a column number to place your piece (1-7) or 666 to return to main menu: "
bad_in:	.asciiz "Bad input, column full or out of bounds, please retry!\n"
win_1: 	.asciiz "Player 1 Wins/nEnter 'y' to play again or 'n' to quit: "
win_2:	.asciiz "Player 2 Wins!\nEnter 'y' to play again or 'n' to quit:"
intro:  .asciiz "CONNECT 4\nEnter 'y' to play against a computer opponent, 'p' for 2 human players, or 'n' to quit: "
yn_er:  .asciiz "Error! Invalid Input!\nPlease enter 'y' or 'n': "
board1: .byte 0:37      # array for storing move positions for player 1
board2: .byte 0:37      # array for storing move positions for player 2
display:.asciiz "| _ | _ | _ | _ | _ | _ | _ |\n| _ | _ | _ | _ | _ | _ | _ |\n| _ | _ | _ | _ | _ | _ | _ |\n| _ | _ | _ | _ | _ | _ | _ |\n| _ | _ | _ | _ | _ | _ | _ |\n| _ | _ | _ | _ | _ | _ | _ |\n"
newln:  .asciiz "\n"
	
	.text
main:	li $v0, 4		# display introduction menu with options 
	la $a0, intro
	syscall
	
menu_in:li $v0, 12		# player inputs y or n or p
	syscall
	
	beq $v0, 121, start_c	# if y go to loop
	beq $v0, 110, exit
	beq $v0, 112, start_p	# if n go to exit
	
	li $v0, 4		# display error if input isnt y or n
	la $a0, yn_er
	syscall
	
	j menu_in		# receive new input
	
start_c:li $v0, 4
	la $a0, newln
	syscall
	
	la $a0, display
	syscall
	
loop_c:	jal p_in		# call p_in, v0 = col_index, v1 = pc_cnt[col_index]
	move $a0, $v0		# a0 = v0 
	move $a1, $v1		# a1 = v1
	li $a3, 79		# a3 = O, to place player char into ASCII display 
	jal ds_brd		# update board
	la $a2, board1		# a2 = address of player position binary array
	jal wn_chk		# check for win
	jal ds_prnt		# print board
	
	jal c_in		# get random move from computer
	move $a0, $v0
	move $a1, $v1
	li $a3, 88		# a3 = X
	jal ds_brd
	move $a0, $v0
	la $a2, board2		# a2 = address of player position binary array
	jal wn_chk
	jal ds_prnt		# ?? Print before win check and put a0 on the stack
	
	j loop_c		# loop until win check jumps to wn_msg
	
start_p:li $v0, 4
	la $a0, newln
	syscall
	
	la $a0, display
	syscall
	
loop_p:	jal p_in		# call p_in, v0 = col_index, v1 = pc_cnt[col_index]
	move $a0, $v0		# a0 = v0 
	move $a1, $v1		# a1 = v1
	li $a3, 79		# a3 = O, to place player char into ASCII display 
	jal ds_brd		# update board
	la $a2, board1		# a2 = address of player position binary array
	jal wn_chk		# check for win
	jal ds_prnt		# print board
	
	jal p_in		# get random move from computer
	move $a0, $v0
	move $a1, $v1
	li $a3, 88		# a3 = X
	jal ds_brd
	move $a0, $v0
	la $a2, board2		# a2 = address of player position binary array
	jal wn_chk
	jal ds_prnt		# print before win check and put $a0 onto the stack
	
	j loop_p		# loop until win check jumps to wn_msg
	
exit:	li $v0, 10		# used to exit program
	syscall
	
###-- WIN MESSAGE --###
wn_msg:	beq $a3, 79, p2_wn	# if player char is X, go to victory
	
	li $v0, 4		# if player char is O, display player 1 win message 
	la $a0, win_1
	syscall
	
	j wn_in			# jump to wn_in 

p2_wn: li $v0, 4		# display player 2 win message
	la $a0, win_2
	syscall
	
	j wn_in			# jump ro wn_in
	
wn_in:  li $v0, 12		# get y or n as input
	syscall
	
	beq $v0, 121, main	# if y, go to main menu
	beq $v0, 110, exit	# if n, exit
	
	li $v0, 4		# if not y or n
	la $a0, yn_er		# display error message
	syscall
	
	j wn_in			# jump back to input

###-- GET PLAYER MOVE --###

	# return: v0 = col_index, v1 = pc_cnt[col_index]
	# print prompt
p_in:	li $v0, 4
	la $a0, prompt
	syscall
	# get column
	li $v0, 5
	syscall
	# 0-align input
	beq $v0, 666, main # branch back to menu if player enters 666
	addi $v0, $v0, -1 # col_input - 1 = col_index
		# validate column is 0-6
nm_val:	slt $t0, $v0, $zero	# if col_index < 0, t0 = 1
	beq $t0, 1, nv_bad  # if t0 = 0 (if col_index < 0), go to nv_bad
	slti $t0, $v0, 7	# if col_index < 8, t0 = 0
	bne $t0, 1, nv_bad	# if t0 =! 0 (if col_index >= 8), go to nv_bad
	
	la $t1, pc_cnt		# load base address of pc_cnt
	add $t1, $t1, $v0 	# offset by col_index
	lb $v1, ($t1)		# load pc_cnt for col_index into t2
	beq $v1, 6, nv_bad	# if t2 = 6 (col is full), go to nv_bad
	add $v1, $v1, 1		# add 1 to pc_cnt (add piece to column)
	sb $v1, ($t1)		# store updated pc_count into postion of array
	# return column
	jr $ra 
	# error retry input
nv_bad:	beq $a1, 88, c_in
	li $v0, 4
	la $a0, bad_in
	syscall	# print bad input
	j p_in

###-- GET RANDOM COMPUTER MOVE --###

c_in: 	# return: v0 = computer column selection
	# random number generation
	li $a1, 7
	li $v0, 42
	syscall	
	move $v0, $a0
	# return column
	j nm_val
	jr $ra
	
#-- DISPLAY UPDATE --#

#args : a0 = col_index , a1 = pc_cnt, a3 = player char
ds_brd: la $t0, display 	# load the base address of the board string
        addi $t1, $zero, 6 
	sub $t1, $t1, $a1 	# load 6 - pc_cnt to get the number of rows from top of board to move
	
dr_beg: beq $t1, $zero, dr_end 	# add 30 until the number of rows to be moved reaches 0
	addi $t0, $t0, 30
	addi $t1, $t1, -1 
	j dr_beg
	
dr_end: addi $t0, $t0, 2 	# get to the address of first char in row
	add $t2, $a0, $zero 	# put col_index into t2
	
dc_beg: beq $t2, $zero, dc_end 	# move by 4 * col_index charecters to the right
	addi $t0, $t0, 4
	addi $t2, $t2, -1
	j dc_beg
	
dc_end:	sb $a3, ($t0) 		# update the charecter at address obtained
	jr $ra

ds_prnt:li $v0, 4		# print the updated ASCII board into the console 
	la $a0, display
	syscall

	jr $ra
	
###-- UPDATE AND WIN CHECK --###
wn_chk:
	#-- Horizonal Position Binary Update --#
	# args: a0 = col_index, a1 = pc_cnt, a2 = board1 or board 2 base address
	# t0 = base address of board position binaries (horizontal block)
	# t1 = offset to obtain position binary (horizontal row)
	# t2 = shift amount for 1 to be added to position binary (column)
	# t3 = position binary to be updated
	# t4 = number to add (update) position binary
	# t5 = comparison for win checking
	
	la $t0, ($a2) 		# no offset required b/c horizontals are the first chunk
	addi $t1, $a1, -1 	# create offset to select horizontal row to manipulate
	add $t0, $t0, $t1 	# add to arrive at position binary (row)
	lb  $t3, ($t0) 		# obtain position binary from memory
	addi $t4, $zero, 1 	# t4 holds one in LSB to be adjusted, then added to position binary (t3)
	add $t2, $zero, $a0 	# t2 is the col_index, or number of shifts needed for t2 to represent piece placement
hstart:	beq $t2, $zero, hend	# if t2 is 0, no shifting is needed for additional bit (t4) to be added to position binary
	sll $t4, $t4, 1		# sll t2 times
	addi $t2, $t2, -1 	# decrement t2 as a counter
	j hstart
hend:	add $t3, $t3, $t4	# update the position binary with the addition shifted bit
	
	##-- Horizontal Position Binary Check --##
	andi $t5, $t3, 15	# Preserves winning bits 00001111
	beq $t5, 15, wn_msg	# Checks for winning bits
	
	andi $t5, $t3, 30	# Preserves winning bits 00011110
	beq $t5, 30, wn_msg	# Checks for winning bits
	
	andi $t5, $t3, 60	# Preserves winning bits 00111100
	beq $t5, 60, wn_msg	# Checks for winning bits
	
	andi $t5, $t3, 120	# Preserves winning bits 01111000
	beq $t5, 120, wn_msg	# Checks for winning bits
	
	sb $t3, ($t0)		# Stores updated position binary back into the memory location it was from originally
	
	##-- Vertical Position Binary Update --##
	# args: a0 = col_index, a1 = pc_cnt, a2 = board1 or board 2 base address
	# t0 = base address of board position binaries (horizontal block)
	# t1 = offset to obtain position binary (horizontal row)
	# t2 = shift amount for 1 to be added to position binary (column)
	# t3 = position binary to be updated
	# t4 = number to add (update) position binary
	# t5 = comparison for win checking
	
	la $t0, 6($a2)		# offset to beginning of vertical position binary block
	add $t1, $a0, $zero 	# store col_index into t1 as offset to vertical position binary (column)
	add $t0, $t0, $t1 	# add t1 to t0, t0 = address of position binary to be manipulated
	lb  $t3, ($t0)		# load position binary into t3
	addi $t4, $zero, 1 	# add 1 into LSB of t4 to be shifted (represents row of piece)
	addi $t2, $a1, -1 	# load pc_cnt - 1, into t2 for counter (shift amount)
vstart:	beq $t2, $zero, vend	# if t2 = 0, 1 is in correct position within t4, else sll by 1
	sll $t4, $t4, 1		
	addi $t2, $t2, -1 	# decrement t2 as counter
	j vstart
vend:	add $t3, $t3, $t4	# add shifted 1 to the position binary
	
	##-- Vertical Position Binary Check --##
	beq $t3, 15, wn_msg     # 00001111
	beq $t3, 30, wn_msg	# 00011110
	beq $t3, 60, wn_msg	# 00111100
	beq $t3, 61, wn_msg	# 00111101 #Check that shift pattern and winning bits are correct!
	
	sb $t3, ($t0)		# store the updated position binary into memory
	
	##-- Top Left Diagonal Position Binary Update --##
	# args: a0 = col_index, a1 = pc_cnt, a2 = board1 or board 2 base address
	# t0 = base address of board position binaries (horizontal block)
	# t1 = offset to obtain position binary (horizontal row)
	# t2 = shift amount for 1 to be added to position binary (column)
	# t3 = position binary to be updated
	# t4 = number to add (update) position binary
	# t5 = comparison for win checking
	
	la $t0, 13($a2)		# offset to beginning of top left diagonal block
	add $t1, $a0, $a1	# create offset to diagonal "row" as (col_index + pc_cnt)
	addi $t1, $t1, -1	# index the offset by subtracting 1
	add $t0, $t0, $t1	# add indexed offset to base address for address of position binary to be updated
	lb  $t3, ($t0)		# load position binary into t3
	addi $t4, $zero, 1 	# add 1 into LSB of t4
	add $t2, $zero, $a0 	# create a counter using col_index
lstart:	beq $t2, $zero, lend	# if the col_index is 0, just at the LSB 1
	sll $t4, $t4, 1		# shift 1 left col_index times
	addi $t2, $t2, -1 	# decrement counter
	j lstart
lend:	add $t3, $t3, $t4	# add shifted 1 into position binary
	
	##-- Top Left Position Binary Check --##
	andi $t5, $t3, 15	# preserves winning bits 00001111
	beq $t5, 15, wn_msg	# checks for winning bits
	
	andi $t5, $t3, 30	# preserves winning bits 00011110
	beq $t5, 30, wn_msg	# checks for winning bits
	
	andi $t5, $t3, 60	# preserves winning bits 00111100
	beq $t5, 60, wn_msg	# checks for winning bits
	
	andi $t5, $t3, 120	# preserves winning bits 01111000
	beq $t5, 120, wn_msg	# preserves winning bits 01111000
	
	sb $t3, ($t0)		# stores updated position binary into memory
	
	##-- Top Right Diagonal Position Binary Update --##
	# args: a0 = col_index, a1 = pc_cnt, a2 = board1 or board 2 base address
	# t0 = base address of board position binaries (horizontal block)
	# t1 = offset to obtain position binary (horizontal row)
	# t2 = shift amount for 1 to be added to position binary (column)
	# t3 = position binary to be updated
	# t4 = number to add (update) position binary
	# t5 = comparison for win checking
	la $t0, 25($a2)		# offset to the beginning of top right diagonal block
	add $t1, $zero, 6	# offset into block set to t1 = (6 - col_index) + pc_cnt 
	sub $t1, $t1, $a0	
	add $t1, $t1, $a1	
	add $t0, $t0, $t1	# adjusted offset added to base address to point to position binary for diagonal
	lb  $t3, ($t0) 		# load position binary into t3
	addi $t4, $zero, 1 	# add 1 in LSB to t4
	add $t2, $zero, $a0 	# get col_index as the left shift counter for t4
rstart: beq $t2, $zero, rend	# if col_index = 0, add t4 to t3 without shifting
	sll $t4, $t4, 1		# shift t4 left col_index times
	addi $t2, $t2, -1 	# decrement the counter
	j rstart
rend:	add $t3, $t3, $t4	# add shifted bit to position binary
	
	##-- Top Right Diagonal Position Binary Check --##
	andi $t5, $t3, 15	# preserve winning bits 00001111
	beq $t5, 15, wn_msg	# check for winning bits
	
	andi $t5, $t3, 30	# preserve winning bits 00011110
	beq $t5, 30, wn_msg	# check for winning bits
	
	andi $t5, $t3, 60	# preserve winning bits 00111100
	beq $t5, 60, wn_msg	# check for winning bits
	
	andi $t5, $t3, 120	# preserve winning bits 01111000
	beq $t5, 120, wn_msg	# check for winning bits
	
	sb $t3, ($t0)		# load updated position binary back into memory
	
	jr $ra
