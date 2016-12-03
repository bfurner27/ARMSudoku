/*
	CONSOLE I/O
*/

//input / output
.set STDIN, 0
.set STDOUT, 1

//read / write
.set READ, 3
.set WRITE, 4

//exit
.set EXIT, 1

.data
prompt: .ascii "Enter coordinate (row col): "
prompt2: .ascii "Enter value: "
read: .skip 4
board:	.ascii "406917832"
	.ascii "000600517"
	.ascii "187532000"
	.ascii "271495060"
	.ascii "835060429"
	.ascii "040823175"
	.ascii "000159283"
	.ascii "913006000"
	.ascii "528374601"
posValues: .skip 9 //possible values array
commaSpace: .ascii " , "
endl: .ascii "\n"
badVal: .ascii "Value is invalid\n"
errVal: .ascii "Value is out of range (1 - 9)\n"
errFull: .ascii "Location is occupied\n"
header: .ascii "   A B C D E F G H I\n"
space: .ascii "  "
numSpace: .ascii "  "
num2Space: .ascii "   "
vertBar: .ascii "\b|"
horizBreak: .ascii "   -----+-----+-----\n"
.text
.global _start
main:
_start:
	//convert board into byte range
	ldr r0, =board
	mov r2, #0 //counter
.LConv:
	ldrb r1, [r0, r2] //load byte
	sub r1, r1, #48 //convert byte
	strb r1, [r0, r2] //store modified byte
	add r2, r2, #1 //increment
	cmp r2, #81 //81 slots in soduku
	blt .LConv

	bl displayBoard //show the board

	///show prompt
	ldr r0, =prompt
	mov r1, #28
	bl display

	//get input
	ldr r0, =read
	mov r1, #4
	bl input

	ldr r0, =read //get the index
	bl getIndex
	mov r1, r0 //move for function call
	mov r4, r1 //keep safe for later
	ldr r0, =board //load board
	bl calcPosValues //calculate the values
	bl printPosValues

	//new line for clean output
	ldr r0, =endl
	mov r1, #1
	bl display

	ldr r0, =board
	mov r1, r4
	bl editSquare

	ldr r0, =board
	bl displayBoard

	mov r0, #0
	mov r7, #EXIT
	svc #0

editSquare: //board in r0, 81 index in r1
	push {r4-r6, lr}

	//mov values for safe keeping
	mov r4, r0
	mov r5, r1
	mov r6, r2

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
	mov r1, #2
	bl input //this will have to be modified to use Ben's input code
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
	bl calcPosValues

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


printPosValues: //takes address of posValues in r0, no return
	push {r4, lr}

	mov r4, r0 //keep address safe
	mov r2, #0 //loop counter
	ldr r3, =commaSpace //for display
.Ldis:
	ldrb r1, [r4, r2] //load possible value
	cmp r1, #0 //see if it is zero
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

	pop {r4, lr}
	bx lr


calcPosValues: //take board address in r0, 81 based index in r1
	       //returns address of possible values in r0
	push {r4-r9, lr}
	mov r4, r0 //keep board address
	mov r5, r1 //keep index value
	ldr r6, =posValues //load possible values
	mov r1, #1
	mov r2, #0
	//load posValues with 1 - 9
.Load:	strb r1, [r6, r2]
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

.Lexit:	pop {lr}
	bx lr


getIndex: //address of zero indexed numbers in r0 (row then coloumn)
	  //returns indexNum in r0
	push {r4, r5, lr}

	//load data
	ldrb r4, [r0]
	ldrb r5, [r0, #2]
	//change to ints
	sub r4, r4, #48
	sub r5, r5, #48

	//calc index
	mov r0, #9
	mul r0, r4, r0
	add r0, r0, r5

	pop {r4, r5, lr}
	bx lr


displayBoard: //takes address of board in r0, no return
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
.Loop:	ldrb r2, [r4, r5] //load byte from board
	add r2, r2, #48 //change to ascii
	cmp r2, #48 //see if num is a 0
	bhi .Lnum //if not skip this
	mov r0, r11 //if is display a space
	mov r1, #2
	bl display
	b .LANum //don't display twice
.Lnum:	mov r0, r9 //if not zero put out "x "
	strb r2, [r0]
	mov r1, #2
	bl display
.LANum:	add r6, r5, #1 //get loopCount + 1
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
	strb r7, [r0] //store line count in
	mov r1, #3
	bl display //show the line number
.LCont:	add r5, r5, #1 //increment loopCount
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


input: //r0 as addres, numBytes in r1
	push {r7, lr}

	mov r2, r1 //place numBytes
	mov r1, r0 //place address
	//setup read
	mov r0, #STDIN
	mov r7, #READ
	svc #0 //read

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
