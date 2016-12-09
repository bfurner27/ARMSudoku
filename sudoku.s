/*============================================
* Global Constant Declarations
*=============================================*/

// i/o
.set STDIN, 0
.set STDOUT, 1

// on open file flags
.set O_RDONLY, 0
.set O_WRONLY, 1
.set O_CREAT, 64

// file permissions
.set S_IRUSR, 0400
.set S_IWUSR, 0200

// system calls
.set EXIT, 1
.set READ, 3
.set WRITE, 4
.set OPEN, 5
.set CLOSE, 6
.set BRK, 45


// constants
.set SIZE_BUFFER, 256
.set SIZE_PROMPT_GET_FILENAME, 32
.set SIZE_BASIC_STR, 256
.set SUDOKU_BOARD_SIZE, 81
.set ERROR_MESSAGE_SIZE, 33
.set ERROR_MESSAGE_CLOSE_SIZE, 33
.set SIZE_PROMPT_GET_COORDINATES, 30
.set SIZE_ERROR_GET_COORDINATES, 28


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


/*START*********** Display Data ***************************/
.balign 4
header: .ascii "   A B C D E F G H I\n"
.balign 4
space: .ascii "  "
.balign 4
numSpace: .ascii "  "
.balign 4
num2Space: .ascii "   "
.balign 4
vertBar: .ascii "\b|"
.balign 4
horizBreak: .ascii "   -----+-----+-----\n"
/*END****/

/*START*********** dispPosValues ***************************/
.balign 4
newLine: .ascii "\n"
.balign 4
doubleBSpace: .ascii "\b\b "
/*END****/

/*START*********** dispInstructions ***************************/
instructions: .ascii "Options:\n"
    .ascii "   D  Display the board\n"
    .ascii "   E  Edit one square\n"
    .ascii "   S  Show the possible values for a square\n"
    .ascii "   Q  Save and Quit\n"
/*END****/

/*START*********** ComputePosValues ***************************/
.balign 4
posValues: .skip 9 //possible values array
.balign 4
commaSpace: .ascii " , "
.balign 4
endl: .ascii "\n"
/*END****/

/*START*********** EditSquare ***************************/
.balign 4
badVal: .ascii "Value is invalid\n"
.balign 4
errVal: .ascii "Value is out of range (1 - 9)\n"
.balign 4
errFull: .ascii "Location is occupied\n"
.balign 4
prompt: .ascii "Enter coordinate (row col): "
.balign 4
prompt2: .ascii "Enter value: "
.balign 4
read: .skip 256
/*END****/

/*START***********ifstreamData*******************/
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
.balign 4
sudoku_board_temp_read:
	.skip 6
/*END****/


/*START***********ofstreamData*******************/
.balign 4
write_file_handle:
	.word 0
.balign 4
write_error_message:
	.asciz "ERROR: Failed to open the file\n"
.balign 4
write_error_message_close:
	.asciz "ERROR: File could not be closed\n"
// needed for the write_sudoku_board_to_work
.balign
sudoku_write_temp_write:
	.skip 6
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
.balign 4
get_coordinate_temp_read:
	.skip 256
.balign 4
prompt_get_coordinates:
	.asciz "  enter coordinates (ex: a7): "	// size 30
.balign 4
error_get_coordinates:
	.asciz "\tERROR: invalid coordinates\n" // size 28
/*END****/


/*START*********InteractData***************************/
.balign 4
interact_user_command:
	.skip 256 // the command will be stored in this variable
.balign 4
interact_user_command_prompt:
	.asciz "\n> "	// size 3

interact_invalid_input_message:
	.asciz "  Error: invalid input\n"	// size 23

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
	// r6 - the filename
	// r7 - the sudoku board
	ldr   r4, =filename_read_addr
	ldr   r5, =sudoku_board_addr
	ldr   r6, =filename_write_addr	// this will only be used temporarily until the address is stored

	// allocate space for the write filename
	mov   r0, #SIZE_BASIC_STR
	bl    malloc
	str   r0, [r6]

	// the start routine
	mov   r0, #SIZE_BASIC_STR
	bl    malloc
	str   r0, [r4]	// store the address of the read_filename
	mov   r6, r0

	// call the readfile function
	bl    func_get_filename

	// set aside space for the sudoku board
	mov   r0, #SUDOKU_BOARD_SIZE
	bl    malloc
	str   r0, [r5]
	mov   r7, r0

	// call the func_read_sudoku_board
	mov   r0, r6	// pass in the filename
	mov   r1, r7 	// pass in the sudoku board
	bl    func_read_sudoku_board

        // display commands goes here
        bl    func_displayInstructions
        ldr  r0, =endl
        mov  r1, #3
        bl   display

	// display sudoku board goes here
	ldr   r0, [r5]
	bl    func_displayBoard

	// this will start the interact process
	bl    func_interact
	
	mov   r7, #EXIT
	svc   #0


/************************************
*
*
***************************************/
func_interact:
	push {r4, r5, r6, r7, r8, lr}
	ldr  r4, =interact_user_command 	// store the command
	ldr  r5, =interact_user_command_prompt	// store the prompt

	// load the sudoku board address and board
	ldr  r8, =sudoku_board_addr
	ldr  r8, [r8]

  .Linteract_command_input_loop:
  	// prompt the user for the next command
  	mov  r0, r5
  	mov  r1, #3
        bl   display


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
  	cmp  r6, #'S'	// display possible values
  	beq  .Linteract_display_pos_vals
  	cmp  r6, #'D' 	// display board
  	beq  .Linteract_display_board
  	cmp  r6, #'Q'
  	beq  .Linteract_quit_game
  	b    .Linteract_default	// if all else fails go to the default case


  .Linteract_display_option: 
        bl  func_displayInstructions
  	b   .Linteract_command_input_loop
  .Linteract_edit_square: 
  	bl  func_get_coordinates	// returns r0 the coordinates as a number
    mov r1, r0
    mov r0, r8
    bl  func_editSquare
  	b   .Linteract_command_input_loop
  .Linteract_display_pos_vals:
  	bl  func_get_coordinates	// returns r0 the coordinates as a number
  	mov r1, r0
  	mov r0, r8	// move the sudoku board into r0
  	bl  func_calcPosValues
  	bl  func_printPosValues
  	b   .Linteract_command_input_loop
  .Linteract_display_board: 
  	mov   r0, r8
	  bl    func_displayBoard
  	b   .Linteract_command_input_loop
  .Linteract_quit_game: 
  	ldr r0, =filename_write_addr
  	ldr r0, [r0]
  	bl  func_get_filename	// r0 will have the address of the string
  	ldr r1, =sudoku_board_addr
  	ldr r1, [r1]
  	bl  func_write_sudoku_board_to_file
  	b  .Linteract_end
  .Linteract_default: 
  	ldr  r0, =interact_invalid_input_message
  	mov  r1, #23
        bl   display
  	b   .Linteract_command_input_loop

  .Linteract_end:
	pop  {r4, r5, r6, r7, r8, pc}


/**********************************
*
***********************************/
func_displayInstructions:
        push {lr}
        ldr r0, =instructions
        mov r1, #119
        bl display
        pop   {pc}

/************************************
* r0 - the character to be converted to upper
* r0 - the upper character value, orignial if not a character

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



/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$     CONSOLE_INPUT      $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/*********************************
* RETURN: r0 - this will utilize the get coordinates function and
*              will return a number between 0-80 based on the index
***********************************/
func_get_coordinates:
	push {r4, r5, r7, lr}
	// TODO write this function once it has been integrated better into the overall sudoku project
  .Lget_coordinate_start_input_loop:
  	
  	// prompt the user for the - TODO call display once it is in place
	ldr  r0, =prompt_get_coordinates
	mov  r1, #SIZE_PROMPT_GET_COORDINATES
        bl   display


	ldr  r4, =get_coordinate_temp_read
	mov  r0, r4
	bl   read_console_input_to_space

	cmp r0, #3
	bne .Lget_coordinates_if_error_message

	ldrb r0, [r4]	// load in the first error message

	// get the first character and then check if it is in the valid range of A-I
	bl   func_to_upper
	cmp r0, #'A'
	blt .Lget_coordinates_if_error_message
	cmp r0, #'I'
	bgt .Lget_coordinates_if_error_message

	sub r0, r0, #'A'
	mov r5, r0 	// change col item to r5 so it can call getIndex
			// r5 is the column number converted from ascii

	// load in the second character check for valid input 1-9
	ldrb  r0, [r4, #1]
	cmp   r0, #'1'
	blt   .Lget_coordinates_if_error_message
	cmp   r0, #'9'
	bgt   .Lget_coordinates_if_error_message

	sub  r0, r0, #'1'	// convert from ascii

	mov  r1, r5
	bl   getIndex


	b   .Lget_coordinates_end

  .Lget_coordinates_if_error_message:
    	// prompt the user for the - TODO call display once it is in place
	mov  r0, #STDOUT
	ldr  r1, =error_get_coordinates
	mov  r2, #SIZE_ERROR_GET_COORDINATES
	mov  r7, #WRITE
	svc  #0
	b    .Lget_coordinate_start_input_loop

  .Lget_coordinates_end:

	pop  {r4, r5, r7, pc}

/*************************
* r0 - the address of the filename array location
* RETURN r0 - the address to the pointer that was written
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
	mov  r0, r4
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





/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$     EditSquare         $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
func_editSquare: //board in r0, 81 index in r1
        push {r4-r6, lr}

        //mov values for safe keeping
        mov r4, r0
        mov r5, r1
        mov r6, r2

        ldr r0, =space
        mov r1, #2
        bl  display

        //check if square is filled
        ldrb r0, [r4, r5]
        cmp r0, #0
        bne .LerrorFull //if filled don't edit it

        //show prompt
        ldr r0, =prompt2
        mov r1, #13
        bl display
        //get user input
        ldr r0, =read
        bl read_console_input_to_space //this will have to be modified to use Ben's input code
        ldr r0, =read
        ldrb r0, [r0]
        sub r0, r0, #48 //change to int value
        mov r6, r0 //keep it safe

        //check digit range
        cmp r6, #1
        blt .LerrorVal
        cmp r6, #9
        bhs .LerrorVal

        //call calcPosValues to find valid options
        mov r0, r4
        mov r1, r5
        bl func_calcPosValues

        mov r2, #0 //loop counter
.LcompLoop:
        ldrb r1, [r0, r2]
        cmp r6, r1
        beq .LgoodVal
        add r2, r2, #1
        cmp r2, #9
        blt .LcompLoop

        //if here, that means invalid value
        ldr r0, =badVal
        mov r1, #17
        bl display
        b .LexitEdit
.LgoodVal: //if here the value entered was good
        strb r6, [r4, r5] //place the value into the board
        b .LexitEdit

.LerrorVal:
        ldr r0, =errVal
        mov r1, #30
        bl display
        b .LexitEdit
.LerrorFull:
        ldr r0, =errFull
        mov r1, #21
        bl display

.LexitEdit:
        pop {r4-r6, lr}
        bx lr


/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$     CalcPosValues      $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
func_calcPosValues: //take board address in r0, 81 based index in r1
               //returns address of possible values in r0
        push {r4-r9, lr}
        mov r4, r0 //keep board address
        mov r5, r1 //keep index value
        ldr r6, =posValues //load possible values
        mov r1, #1
        mov r2, #0
        //load posValues with 1 - 9
.Load:  strb r1, [r6, r2]
        add r2, r2, #1
        add r1, r1, #1
        cmp r2, #9
        bne .Load

        //check row
        mov r0, r5 //get row start
        mov r1, #9
        bl mod
        mov r1, r0
        mov r0, r5
        sub r7, r0, r1 //r7 now has beginning of row index
        add r8, r7, #9 //r8 has compare value for loop
.Lrow:
        ldrb r0, [r4, r7]
        mov r1, r6 //load posValues array for checkVal
        bl checkVal
        add r7, r7, #1 //go to next in row
        cmp r7, r8
        blt .Lrow

        //check column
        mov r0, r5 //place index into r0
        b .LcolSubCheck
.LcolSub:
        sub r0, r0, #9
.LcolSubCheck:
        cmp r0, #9
        bhs .LcolSub
        //r0 has start of column index once loop is finished
        mov r7, r0
        mov r8, #0 //loop counter
.Lcol:
        ldrb r0, [r4, r7] //load board value
        mov r1, r6 //load posValues
        bl checkVal //check
        add r7, r7, #9 //go to next item in column
        add r8, r8, #1
        cmp r8, #9
        blt .Lcol

        //check square (this is intense!)
        mov r0, r5
        mov r1, #3
        bl mod
        sub r0, r5, r0 //r0 now has the index that is in the correct column
        mov r5, r0 //keep it safe, don't need original index anymore
.LrowNumCheck: //go to correct row index
        bl checkRowNum //see if num matches one of 9 correct locations
        cmp r0, #1
        bne .LrowNumSub //if it doesn't subtract 9 and trya again
        b .LsqCheckCont //if it does continue
.LrowNumSub:
        sub r5, r5, #9
        mov r0, r5
        b .LrowNumCheck //this should only ever happen once or twice
        //the correct index will be in r5
.LsqCheckCont:
//here we have an assembly interpretation of a nested loop
        mov r8, #0//first loop counter
        mov r9, #0//second loop counter
.LoopAcross: //checks values across the row
        ldrb r0, [r4, r5] //load board value
        mov r1, r6 //posValues address
        bl checkVal
        add r5, r5, #1
        add r8, r8, #1
        cmp r8, #3
        blt .LoopAcross
.LoopDown:
        add r9, r9, #1 //increment count
        cmp r9, #3
        beq .Ldone
        add r5, r5, #7 //go to next row
        b .LoopAcross ///go across next row
.Ldone:
        mov r0, r6 //move address of posValues to r0

        pop {r4-r9, lr} //return
        bx lr

checkVal: //takes value in r0, address of array in r1, no return
        push {lr}
        //check if zero
        cmp r0, #0
        beq .Lreturn

        sub r0, r0, #1 //change to zero index
        mov r2, #0
        strb r2, [r1, r0] //place zero into the proper spot

.Lreturn:
        pop {lr}
        bx lr


checkRowNum: //takes rowNum in r0, returns 0 or 1 in r0
        push {lr}

        cmp r0, #0
        beq .Ltrue
        cmp r0, #3
        beq .Ltrue
        cmp r0, #6
        beq .Ltrue
        cmp r0, #27
        beq .Ltrue
        cmp r0, #30
        beq .Ltrue
        cmp r0, #33
        beq .Ltrue
        cmp r0, #54
        beq .Ltrue
        cmp r0, #54
        beq .Ltrue
        cmp r0, #57
        beq .Ltrue
        cmp r0, #60
        beq .Ltrue
        b .Lfalse

.Ltrue:
        mov r0, #1
        b .Lexit
.Lfalse:
        mov r0, #0

.Lexit: pop {lr}
        bx lr


func_printPosValues: //takes address of posValues in r0, no return
        push {r4, lr}


        mov r4, r0 //keep address safe
        mov r2, #0 //loop counter
        ldr r3, =commaSpace //for display
        ldr r0, =space
        mov r1, #2
        bl  display
.Ldis:
        ldrb r1, [r4, r2] //load possible value
        cmp r1, #0  //see if it is zero change to 0 ofr final program
        beq .LdisCont //if yes skip it
                      //if not display it
        add r1, r1, #48 //convert to ascii
        strb r1, [r3]
        mov r0, r3
        mov r1, #3
        push {r2, r3}
        bl display
        pop {r2, r3}
.LdisCont:
        add r2, r2, #1 //increment counter
        cmp r2, #9
        blt .Ldis //show all possible values

	ldr r0, =doubleBSpace //get rid of extra ", "
	mov r1, #3
	bl display

	ldr r0, =newLine //put out a new line
	mov r1, #1
	bl display

        pop {r4, lr}
        bx lr



/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$     DisplayBoard       $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
func_displayBoard: //takes address of board in r0, no return
        push {r4 - r11, lr}
        //set up
        mov r4, r0 //keep address safe in r4
        mov r5, #0 //loopCount
        mov r6, #0 //loopCount + 1
        mov r7, #49 //lineCount, in ascii
        //keep commonly used addresses handy
        ldr r8, =num2Space
        ldr r9, =numSpace
        ldr r10, =vertBar
        ldr r11, =space
        //display header
        ldr r0, =header
        mov r1, #21
        bl display
        //begin first line
        mov r0, r8
        strb r7, [r0] //lineCount into num2Space
        mov r1, #3
        bl display //show the "1  "

        //start loop
.Loop:  ldrb r2, [r4, r5] //load byte from board
        add r2, r2, #'0' //change to ascii
        cmp r2, #48 //see if num is a 0
        bhi .Lnum //if not skip this
        mov r0, r11 //if is display a space
        mov r1, #2
        bl display
        b .LANum //don't display twice
.Lnum:  mov r0, r9 //if not zero put out "x "
        strb r2, [r0]
        mov r1, #2
        bl display
.LANum: add r6, r5, #1 //get loopCount + 1
        mov r0, r6 //prep for mod
        mov r1, #3
        bl mod //get mod
        cmp r0, #0
        beq .LVBar //if loop count + 1 % 3 == 0 display "| "
        b .LCont //if not continue
.LVBar: mov r0, r6 //prep for second mod
        mov r1, #9
        bl mod //if loopCount + 1 % 9 == 0, no Vbar
        cmp r0, #0
        beq .LNVBar //skip VBar at end of line
        mov r0, r10 ///load vertBar
        mov r1, #2
        bl display //show it
        b .LCont //continue normally
.LNVBar:mov r0, r6 //prep for mod
        mov r1, #9
        bl mod
        cmp r0, #0 //if loopCount + 1 % 9 == 0
        bhi .LCont //if not continue normally
        mov r1, #32 //for a space
        mov r0, r9 //mov numSpace into r0
        strb r1, [r0] //load space
        mov r1, #10
        strb r1, [r0, #1] //load new line
        mov r1, #2
        bl display //put out " \n"
        mov r0, r9 //put a space back in
        mov r1, #32
        strb r1, [r0, #1] //now numSpace is "  "
        add r7, r7, #1 //increment lineCount
        cmp r7, #52 //see if horizBreak is need
        beq .LHbreak //need horizBreak after 3 and 6
        cmp r7, #55 //52 and 55 in ascii
        beq .LHbreak
        b .LNHBreak
.LHbreak: //display a horizontal break if needed
        ldr r0, =horizBreak
        mov r1, #21
        bl display
.LNHBreak: //if no horizBreak, but a new line occurred
        mov r0, r8 //load num2Space
        cmp r7, #':'
        beq .LCont
        strb r7, [r0] //store line count in
        mov r1, #3
        bl display //show the line number
.LCont: add r5, r5, #1 //increment loopCount
        cmp r5, #81 //check if done
        blt .Loop //if not loop again
        pop {r4 - r11, lr} //when loop is done
        bx lr //exit function



display: //address in r0, numBytes in r1
        push {r7, lr}

        mov r2, r1 //place numBytes
        mov r1, r0 //place address
        //set up display
        mov r0, #STDOUT
        mov r7, #WRITE
        svc #0 //display

        pop {r7, lr}
        bx lr

mod: //num in r0, modder in r1. i.e. r0 % r1
        push {lr}

        cmp r0, r1
        blt .LDone

.LMod:  sub r0, r0, r1
        cmp r0, r1
        bhs .LMod

.LDone:
        pop {lr}
        bx lr


/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    GETINDEX      $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
getIndex: //row in r0, column in r1
          //returns indexNum in r0
        push {r4, r5, lr}

        //load data
        mov r4, r0
        mov r5, r1

        //calc index
        mov r0, #9
        mul r0, r4, r0
        add r0, r0, r5

        pop {r4, r5, lr}
        bx lr


/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    OFSTREAM      $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/******************************************************************
* PARAMS: r0 - the filename to be read to
* 	  r1 - the sudoku board to be written - a character array
*******************************************************************/
func_write_sudoku_board_to_file:
	push {r4, r5, r6, r7, lr}	// I am using the higher registers because
					// the system calls are not guaranteed to keep the
					// other registers the same

	mov  r4, r1 	// save the address of the sudoku board

	// open the filename, the filename was passed in as the r0 parameter
	bl  write_file_open

	// read in the sudoku board and the data
	ldr  r5, =sudoku_write_temp_write

	mov  r6, #0 	// i = 0
  .Lsudoku_write_for_i:
  	ldrb r1, [r4, r6]
  	
  	add  r1, r1, #'0'	// convert back to a character number
  	strb r1, [r5]


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
	mov  r1, #(O_WRONLY | O_CREAT)
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


/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    IFSTREAM      $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
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

	
	ldr r6, =sudoku_board_temp_read

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
  	sub  r1, r1, #'0'
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
