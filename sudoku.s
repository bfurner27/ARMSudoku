/*============================================
* Global Constant Declarations
*=============================================*/

// i/o
.set STDIN, 0
.set STDOUT, 1

// system calls
.set EXIT, 1
.set READ, 3
.set WRITE, 4
.set BRK, 45


// constants
.set SIZE_BUFFER, 256
.set SIZE_PROMPT_GET_FILENAME, 32
.set SIZE_BASIC_STR, 256


/*============================================
* Data Section
*=============================================*/
.data
/*START***********  MAIN_DATA ***************************/
.balign 4
filename_read_addr: 
	.word 0
.balign 4
filename_write_addr:
	.word 0
.balign 4
sudoku_board_addr:
	.word 0
/*END****/

/*START***********ReadConsoleInputData*******************/
.balign 4
read_console_temp_buffer:
	.skip 256
.balign 4
read_console_end_buffer:
	.word 0
.balign 4
read_console_flag:
	.word 0 // 0 is no additional characters need to be read, 
	        // 1 is additional characters need to be read
.balign 4
prompt_get_filename:
	.asciz "Please enter the game filename: "
/*END****/


/*START*********InteractData***************************/
.balign 4
interact_user_command:
	.skip 256 // the command will be stored in this variable
.balign 4
interact_user_command_prompt:
	.asciz "> "	// size 2

interact_invalid_input_message:
	.asciz "Error: invalid input\n"	// size 21

/*END*****/


/*START***********malloc******************************/
	.data
heap_prev:
	.word 0
heap_end:
	.word 0
heap_start:
	.word 0
/*END*****/

/*============================================
* Code Section
*=============================================*/
.text
.global _start
_start:
	ldr   r4, =filename_read_addr

	// the start routine
	mov   r0, #SIZE_BASIC_STR
	bl    malloc
	str   r0, [r4]	// store the address of the read_filename

	

	bl    func_interact
	
	mov   r7, #EXIT
	svc   #0

func_interact:
	push {r4, r5, r6, r7, lr}
	ldr  r4, =interact_user_command 	// store the command
	ldr  r5, =interact_user_command_prompt	// store the prompt
  .Linteract_command_input_loop:
  	// prompt the user for the next command
  	mov  r0, #STDOUT
  	mov  r1, r5
  	mov  r2, #2
  	mov  r7, #WRITE
  	svc  #0

  	// call fin >> command
  	mov  r0, r4	// store the command
  	bl   read_console_input_to_space
  	cmp  r0, #2
  	bne  .Linteract_default

  	// call to_upper to ensure that the command is upper case
  	ldrb r0, [r4]	// store the byte into r0
  	bl   func_to_upper

  	// switch statement to call correct command
  	mov  r6, r0 	// save the command in r6
  	cmp  r6, #'?'	// display options
  	beq  .Linteract_display_option
  	cmp  r6, #'E'	// edit square
  	beq  .Linteract_edit_square
  	cmp  r6, #'P'	// display possible values
  	beq  .Linteract_display_pos_vals
  	cmp  r6, #'D' 	// display board
  	beq  .Linteract_display_board
  	cmp  r6, #'Q'
  	beq  .Linteract_quit_game
  	b    .Linteract_default	// if all else fails go to the default case


  .Linteract_display_option: 
  	// TODO displays the options
  	b   .Linteract_command_input_loop
  .Linteract_edit_square: 
  	// TODO edit the square
  	b   .Linteract_command_input_loop
  .Linteract_display_pos_vals:
  	// TODO checks the possible values
  	b   .Linteract_command_input_loop
  .Linteract_display_board: 
  	// TODO displays the board 
  	b   .Linteract_command_input_loop
  .Linteract_quit_game: 
  	// TODO quit the game and save the board to a file
  	b  .Linteract_end
  .Linteract_default: 
  	// deal with the default case
  	mov  r0, #STDOUT
  	ldr  r1, =interact_invalid_input_message
  	mov  r2, #21
  	mov  r7, #WRITE
  	svc  #0
  	b   .Linteract_command_input_loop

  .Linteract_end:
	pop  {r4, r5, r6, r7, pc}

/************************************
* r0 - the character to be converted to upper
* r0 - the upper character value, -1 if it is not a valid character for conversion

* Flow of this program
* if (char >= A && char <= Z)
*    return char
* else 
*    char - 32 - converts from lower to upper case
*    if (char < A)
*       return originalChar
* return char
*************************************/
func_to_upper:
	push  {lr}
	cmp  r0, #'A'
	bge  .Lto_upper_if_already_upper
	b    .Lto_upper_end
  .Lto_upper_if_already_upper:
  	cmp  r0, #'Z'
  	ble  .Lto_upper_end	// check if it is already upper if it is return
  .Lto_upper_convert:
  	sub  r0, r0, #32
  	cmp  r0, #'A'
  	bge  .Lto_upper_end
  	add  r0, r0, #32
  .Lto_upper_end:
	pop   {pc}



/*********************************
* RETURN: r0 - this will utilize the get coordinates function and
*              will return a number between 0-80 based on the index
***********************************/
func_get_coordinates:
	push {lr}
	// TODO write this function once it has been integrated better into the overall sudoku project

	pop  {lr}

/*************************
* r0 - the address of the filename array location
* note: make sure to store the address before this function is called because there
* is no guarantee that this function will preserve registers r0 - r3
*************************/
func_get_filename:
	push {r4, lr}

	mov  r4, r0

	// prompt the user for the
	mov  r0, #STDOUT
	ldr  r1, =prompt_get_filename
	mov  r2, #SIZE_PROMPT_GET_FILENAME
	mov  r7, #WRITE
	svc  #0

	// call fin >> filename
	mov  r0, r4
	bl  read_console_input_to_space
	pop  {r4, pc}


/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$     CONSOLE_INPUT      $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/***********
* PARAM: r0 - location of character array to populate
* RETURN: r0 - size of the array returned
***********/
read_console_input_to_space:
	push { r4, r5, r6, r7, lr }

	mov  r5, r0
	mov  r6, #3	// b11 clear the flags
	ldr  r4, =read_console_temp_buffer

  .Lread_console_buffer_populate:
	// make the first call to fill the buffer
	mov  r0, r4
	mov  r1, #SIZE_BUFFER
	bl   read_console_fill_buffer
	cmp  r0, #SIZE_BUFFER
	bge  .Lif_more_reading_is_needed
	and  r6, r6, #2 // set r6 by 10 so it clears the second bit, this means no more reading is needed
  .Lif_more_reading_is_needed:
  	// check that additional reading is still needed
  	ands r2, r6, #2  		// if the second bit is set then populate the array
  	bne  .Lread_console_buffer_loop_prep // if this 1 then the copy to the other array needs to be performed
  	ands r2, r6, #1 		// if the first bit is set then
  	bne  .Lread_console_buffer_populate	// read until this bit is no longer set
  	b    .Lread_console_buffer_end
  .Lread_console_buffer_loop_prep:
  	mov  r0, #0	// int i = 0
  .Lread_console_buffer_reading:
  	ldrb r1, [r4, r0]	// buffer[i]
  	
  	// end loop if (buffer[i] == ' ' || bufer[i] == '\n')
  	cmp  r1, #' '
  	beq  .Lread_console_buffer_reading_end
  	cmp  r1, #'\n'
  	beq  .Lread_console_buffer_reading_end

  	// if the number of characters input is greater than 
  	// 256 and there is no ' ' or '\n' then end the loop
  	cmp  r0, #255
  	beq  .Lread_console_buffer_reading_end

  	strb r1, [r5, r0]	// store the values in the provided array
  	add  r0, r0, #1	// i++
  	b    .Lread_console_buffer_reading
  .Lread_console_buffer_reading_end:
  	mov  r1, #0
  	strb r1, [r5, r0]	// store a null at the end of the read
  	add  r0, r0, #1		// add one to get the correct number of bytes
  	mov  r5, r0
  	and  r6, r6, #1	// and r6 by 01 so that it sets the second bit
  	b    .Lif_more_reading_is_needed
  .Lread_console_buffer_end:
  	mov  r0, r5	// return the number of characters read
	pop  { r4, r5, r6, r7, pc }

/**********
* PARAM [ref] r0 - pointer to the buffer to fill
* PARAM r1 - the size of the buffer
* RETURN r0 - the number of characters read
********/
read_console_fill_buffer:
	push {r7, lr}

	// prep for the system call
	mov  r2, r1
	mov  r1, r0
	mov  r0, #STDIN
	mov  r7, #READ
	svc  #0

	pop  {r7, pc}


/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    MALLOC      $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/********************************************
* PARAM: r0 - the number of bytes to allocate
* RETURN r0 - reference to the allocated space
*******************************************/
malloc:
	push {r4, r5, r6, r7, r8, lr}

	// store the number of bytes to allocate
	mov r4, r0

	//check if the break is already set
	ldr r5, =heap_prev 	// r1 becomes the heap address
	ldr r6, =heap_end	// r2 becomes the heap_end address
	ldr r7, =heap_start

	ldr r0, [r6]
	ldr r1, [r7]
	cmp r1, r0	// if the start and the end are the same then it has not been initalized before
	bne LskipInitializer	// make sure that this is never the same value again
// the initialize section will just set the values if they are equal
	mov r7, #BRK
	mov r0, #0
	svc #0

	ldr r7, =heap_start

	str r0, [r5]
	str r0, [r6]
	str r0, [r7]
	b   Lallocate
  LskipInitializer:

  // search through the list and find open positions if none are available then allocate more space
  Lsearch: // searches the linked list for open positions that are big enough
  	ldr r1, [r7]	// load the start of the linked list
    Lloop_while:
    	ldr r3, [r1]	// load the info about that data section
    	mov r0, #1
    	ands r0, r0, r3
    	bne Lendif_checkSize  // check if the true bit is set
      Lif_checkSize: 		// if the true bit is not set then check the size
      	mov r2, r3, LSR #8
    	cmp r2, r4		// check if the value is big enough to fit in the data section
    	bpl LreturnPointer
      Lendif_checkSize:
    	ldr r1, [r1, #4]	// load in the next address
    	cmp r1, #0
    	bne Lloop_while	// branches as long as the address of the next location is not null
    Lloop_while_end:
    b Lallocate // if it made it out of the loop then it hit a null and there is no space big enough

  LreturnPointer:
  	ldr r0, [r1]
  	add r0, r0, #1
  	str r0, [r1]
  	add r0, r1, #8		// give the reference to the data section
  	b Lendallocate		// jump to the end

  // initialize the space
  Lallocate: 
  	add r0, r4, #8	// stores the number of bytes to allocate - 
			// byte 0 - true/false for set, byte 1-3 size of allocation max size is 2^24
			// the way this works is the size will be shifted over by 4 and it will be added to 1
			// when it is deallocated the value will be subtracted by one that way only the one bit
			// needs to be checked to see if it is set
			// byte 4-7 - the address to the next pointer
	ldr r1, [r6]
	add r0, r0, r1	// set the next memory location to be set
  	mov r7, #BRK
  	svc #0

  	ldr r1, [r6]	// load the old end address
  	ldr r2, [r5]	// get the previous pointer location

  	// set the true flag and store the number of bytes allocated
  	mov  r3, r4, LSL #8
  	add  r3, r3, #1
  	str  r3, [r1]

  	// set the pointer to null for the next memory location
  	mov r3, #0
  	str r3, [r1, #4]

  	// set the previous locations pointer to the current memory location
  	cmp r1, r2
  	beq .Lif_first_time
  	str r1, [r2, #4]
    .Lif_first_time:
  	str r0, [r6]	// store the new end value
  	str r1, [r5]	// store the prev value

  	add r0, r1, #8	// give the reference to memory that does not include the linked list information

  Lendallocate:
  	pop  {r4, r5, r6, r7, r8, pc}


/*************************
* r0 - the address to the location of memory to free
*
**************************/
deallocate:
	push {r4, r5, r6, r7, lr}
	sub r0, r0, #8
	ldr r5, =heap_prev
	ldr r6, =heap_end
	ldr r1, =heap_start	// get the start of the linked list
	ldr r1, [r1]
	cmp r1, r0
	beq  .Lendloop_search_list
  .Lloop_search_list:
  	mov r2, r1	// store the previous pointer location
  	ldr r1, [r1, #4]	// load the next pointer
  	cmp r1, #0
  	beq .Lif_null
  	cmp r1, r0
  	bne .Lloop_search_list
  .Lendloop_search_list:
  	//check if the deallocated item is at the top
  	ldr r3, [r1, #4] 	// get the next pointer
  	cmp r3, #0
  	beq .Lelse_not_end
  .Lif_not_end:
  	ldr r2, [r1]
  	sub r2, r2, #1
  	str r2, [r1]
  	mov r0, #1 	// returns 1 on success
  	b   .Lendif_null
  .Lelse_not_end:
  	mov r0, #0
  	str r0, [r2, #4]	// set the previous address to null
  	str r1, [r6]	// store the new end of the heap
  	str r2, [r5]	// store the previous pointer so we can access that data
  	ldr r0, [r1]		// load in the data for r1 or the pointer to the last element
  	
  	mov r0, r0, LSR #8 	// shift he data by 4 because we are using 8 bits for the flag
  	add r0, r0, #8 		// add 8 so that when we subtract later it will deallocate the correct space
  	ldr r1, [r6]
  	sub r0, r1, r0
  	mov r7, #BRK
  	svc #0

  	mov r0, #1
  	b   .Lendif_null
  .Lif_null:
  	mov  r0, #0	// returns 0 on failure
  .Lendif_null:
  	pop  {r4, r5, r6, r7, pc}
