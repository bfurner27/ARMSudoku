
// on open file flags
.set O_WRONLY, 1
.set O_RDONLY, 0
.set O_CREAT, 64

// file permissions
.set S_IRUSR, 0400
.set S_IWUSR, 0200

// i/o
.set STDIN, 0
.set STDOUT, 1

// system calls
.set READ, 3
.set WRITE, 4
.set OPEN, 5
.set CLOSE, 6
.set EXIT, 1

//global numbers
.set ERROR_MESSAGE_SIZE, 33
.set ERROR_MESSAGE_CLOSE_SIZE, 33

.data
.balign 4
data:
	.skip 1
.balign 4
fileHandle:
	.word 0
.balign 4
error_message:
	.asciz "ERROR: Failed to open the file\n"
.balign 4
error_message_close:
	.asciz "ERROR: File could not be closed\n"
	

// filename test variables
.balign 4
filename:
	.asciz "sudokutest.txt"

sudoku_board:
	.skip 82

temp_read:
	.skip 6

.text
.global _start
_start:

	ldr r0, =filename
	ldr r1, =sudoku_board
  	bl  func_read_sudoku_board

  	mov r5, r0
  	mov r4, r1
  	// add an endline at the end so the text is not confusing
  	// on output
  	mov r0, #10
  	str r0, [r5, r4]
  	add r4, r4, #1

	// display the read info/sudoku array
  	mov r0, #STDOUT
  	mov r1, r5
  	mov r2, r4
  	mov r7, #WRITE
  	svc #0
	
  	mov r7, #EXIT
  	svc #0

/****************************************
* PARAMS: r0, filename
*         r1, sudoku_board, array of 81 chars
* RETURN: r0, the sudoku_board array filled with vals
*         r1, the number of read values
*****************************************/
func_read_sudoku_board:
	push {r4, r5, r6, lr}
	mov  r5, r1	// stores the sudoku_array

	// r0 already the filename 
	bl  read_file_open

	
	ldr r6, =temp_read

	mov r4, #0 	// turn this into our i
  .Lfor_i:
  	mov r0, r6
  	bl  read_file_to_space

  	// if eof then jump out of the loop
  	cmp r0, #0
    	beq .Lend_for_i

  	// store the file in the array
  	ldrb r1, [r6]
  	// TODO do the math here to turn this into a number
  	// ex: sub r1, r1, #48 aka char - '0'
  	strb r1, [r5, r4]

    	add r4, r4, #1
    	b   .Lfor_i
  .Lend_for_i:

  	bl  read_file_close

  	mov r0, r5
  	mov r1, r4

  	pop  {r4, r5, r6, pc}

/***************************
* r0 - pointer to the filename to open
***************************/
read_file_open:
	push {lr}
	@mov r0, r0 // filename address is in r0
	mov  r1, #(O_RDONLY)
	mov  r2, #(S_IRUSR | S_IWUSR)
	mov  r7, #OPEN
	svc  #0

	ldr  r1, =fileHandle
	str  r0, [r1]
	
	cmp r0, #-1
	bgt .Lend
  .Lerror:
	mov  r0, #STDOUT
	ldr  r1, =error_message
	mov  r2, #ERROR_MESSAGE_SIZE
	mov  r7, #WRITE
	svc  #0
  .Lend:
	pop  {pc}
	
/************************
* r0, where to store the character array this needs to be up to 256 chars
* note: the file should already have been opened in order to work correctly
*
* returns in r0 - 0 if end of file, 1 otherwise
**************************/
read_file_to_space:
	push { r4, r5, r6, lr }
	ldr r6, =data 	// the location to store one character
	mov r4, r0	// store the pointer to the data
	ldr r5, =fileHandle	// where the fileHandle's stored
	ldr r5, [r5]		// retrieve the filehandle

  .Lloop_read_until_space:
	mov r0, r5	// ensure the address of the file handle is correct
	mov r1, r6	// ensure that the address of the char is there
	mov r2, #1
	mov r7, #READ
	svc #0

	// if it is the end of the file then jump
	cmp r0, #0
	beq .Lend_of_file
	
	ldrb r3, [r1]

	// if (char == ' ' || char == '\n')
	//    end loop
	cmp  r3, #' '
	beq  .Lnot_end_of_file
	cmp  r3, #'\n'
	beq  .Lnot_end_of_file

	// store the character into the array provided by the user
	strb r3, [r4]

	// add 1 to the address provided by the user
	add r4, r4, #1
	b   .Lloop_read_until_space

  .Lnot_end_of_file:
	mov r0, #1
	b  .Lend_read_space
  .Lend_of_file:
	mov r0, #0
  .Lend_read_space:
	mov r3, #0
	strb r3, [r4]
	pop  { r4, r5, r6, pc }
	
/***********************************************
* PARAMS: NONE
* // note - the file has to have been opened for this to work
*************************************************/
read_file_close:
	push {lr}
	ldr r0, =fileHandle
	ldr r0, [r0]
	cmp r0, #-1
	bne .Lclose
	cmp r0, #0
	bne .Lclose
  .Lclose_error:
	mov  r0, #STDOUT
	ldr  r1, =error_message_close
	mov  r2, #ERROR_MESSAGE_CLOSE_SIZE
	mov  r7, #WRITE	
	b   .Lclose_end
  .Lclose:
	svc #0
	cmp r0, #0
	bne .Lclose_error
	ldr r1, =fileHandle
	str r0, [r1]
  .Lclose_end:
	pop  {pc}



	
