// i/o
.set STDIN, 0
.set STDOUT, 1

// system calls
.set READ, 3
.set WRITE, 4
.set EXIT, 1

// constants
.set SIZE_BUFFER, 256
.set SIZE_PROMPT_GET_FILENAME, 32

.data
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

// temp variables to be used for testing
.balign 4
read: 
	.skip 256

.text
.global _start
_start:
	ldr  r0, =read
	bl   func_get_filename

	mov  r2, r0
	mov  r0, #STDOUT
	ldr  r1, =read
	mov  r7, #WRITE
	svc  #0

	mov  r7, #EXIT
	svc  #0


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
