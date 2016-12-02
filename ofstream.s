//Global Constants

// the command flags associated with the file
.set O_WRONLY, 1
.set O_CREATE, 64

// permission flags
.set S_IRUSR, 0400
.set S_IWUSR, 0200

// i/o flags
.set STDOUT, 1

// system calls
.set EXIT, 1
.set WRITE, 4
.set OPEN, 5
.set CLOSE, 6

//global numbers
.set ERROR_MESSAGE_SIZE, 33
.set ERROR_MESSAGE_CLOSE_SIZE, 33

.data	// this is the data section
.balign 4
write_file_handle:
	.word 0
.balign 4
write_error_message:
	.asciz "ERROR: Failed to open the file\n"
.balign 4
write_error_message_close:
	.asciz "ERROR: File could not be closed\n"


// local variables to test this program
.balign 4
filename:
	.asciz "sudokutest1.txt"

sudoku_board:
	.asciz "000123000123000000000000123000456000456000000000000456000789000789000000000000789"

// needed for the write_sudoku_board_to_work
temp_write:
	.skip 6

.text
.global _start
_start:
	ldr  r0, =filename
	ldr  r1, =sudoku_board
	
	mov r2, #0
  .Lloop:
  	ldrb r3, [r1, r2]
  	sub  r3, r3, #'0'
  	strb r3, [r1, r2]
  	add  r2, r2, #1
  	cmp  r2, #81
  	bne  .Lloop

  	bl   write_sudoku_board_to_file
  	mov  r7, #EXIT
  	svc  #0

/******************************************************************
* PARAMS: r0 - the filename to be read to
* 	  r1 - the sudoku board to be written - a character array
*******************************************************************/
write_sudoku_board_to_file:
	push {r4, r5, r6, r7, lr}	// I am using the higher registers because
					// the system calls are not guaranteed to keep the
					// other registers the same

	mov  r4, r1 	// save the address of the sudoku board

	// open the filename, the filename was passed in as the r0 parameter
	bl  write_file_open

	// read in the sudoku board and the data
	ldr  r5, =temp_write

	mov  r6, #0 	// i = 0
  .Lsudoku_write_for_i:
  	ldrb r1, [r4, r6]
  	
  	add  r1, r1, #'0'	// convert back to a character number
  	str  r1, [r5]


  	// check if there should be an endline or a space
  	cmp  r6, #0
  	beq  .Lsudoku_write_else	// if (i != 0)

  	// set up the check
  	mov  r2, r6	// store the value here
  	add  r2, r2, #1
  	mov  r1, r2 
  	mov  r0, #9	// number to divide by
  	udiv r1, r1, r0 // r = i / 9 - integer division
  	mul  r1, r0, r1 // n = r * 9 - this will give us the nearest multiple of 9
  	subs r1, r2, r1	// i - n = i % 9
  	bne  .Lsudoku_write_else	// if (i % 9 == 0)
  .Lsudoku_write_if:
  	mov r1, #'\n'
  	b   .Lsudoku_write_if_end
  .Lsudoku_write_else:
  	mov  r1, #' '		// push a space in after the character to be output
  .Lsudoku_write_if_end:
	str  r1, [r5, #1]	// store a ' ' or a '\n'

  	// set up the call to my write function
  	mov  r0, r5
  	mov  r1, #2
  	bl   write_string_to_file

  	add r6, r6, #1
  	cmp r6, #81
  	bne .Lsudoku_write_for_i

 	bl  write_file_close
	pop  {r4, r5, r6, r7, pc}



/***************************
* r0 - pointer to the filename to open
***************************/
write_file_open:
	push {lr}
	@mov r0, r0 // filename address is in r0
	mov  r1, #(O_WRONLY | O_CREATE)
	mov  r2, #(S_IRUSR | S_IWUSR)
	mov  r7, #OPEN
	svc  #0

	ldr  r1, =write_file_handle
	str  r0, [r1]
	
	cmp r0, #-1
	bgt .Lwrite_open_end
  .Lwrite_open_error:
	mov  r0, #STDOUT
	ldr  r1, =write_error_message
	mov  r2, #ERROR_MESSAGE_SIZE
	mov  r7, #WRITE
	svc  #0
  .Lwrite_open_end:
	pop  {pc}


/*************************************************
*
* note - the write_open must have been succesfully called
* in order for this to work correctly. If it failed to open then
* there is an error and it will not be able to write the file
*
* PARAMS: r0 - string to write to the file
*         r1 - the number of characters to be written
**************************************************/
write_string_to_file:
	push {r7, lr}

	mov  r2, r1	// save the size of the array to pass in
	mov  r1, r0	// save the c_string that was passed in
	ldr  r0, =write_file_handle
	ldr  r0, [r0]	// get the file handle from memory so that it will know where to write
	mov  r7, #WRITE
	svc  #0	

	pop  {r7, pc}


/***********************************************
* PARAMS: NONE
* // note - the file has to have been opened for this to work
*************************************************/
write_file_close:
	push {lr}
	ldr r0, =write_file_handle
	ldr r0, [r0]
	cmp r0, #-1
	bne .Lwrite_close
	cmp r0, #0
	bne .Lwrite_close
  .Lwrite_close_error:
	mov  r0, #STDOUT
	ldr  r1, =write_error_message_close
	mov  r2, #ERROR_MESSAGE_CLOSE_SIZE
	mov  r7, #WRITE	
	b   .Lwrite_close_end
  .Lwrite_close:
	svc #0
	cmp r0, #0
	bne .Lwrite_close_error
	ldr r1, =write_file_handle
	str r0, [r1]
  .Lwrite_close_end:
	pop  {pc}



