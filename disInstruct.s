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
instructions:	.ascii "Options:\n"
		.ascii "   D  Display the board\n"
		.ascii "   E  Edit one square\n"
		.ascii "   S  Show the possible values for a square\n"
		.ascii "   Q  Save and Quit\n\n"
.text
.global _start
_start:
	//display test
	ldr r0, =instructions
	mov r1, #120
	bl display

	mov r0, #0
	mov r7, #EXIT
	svc #0

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

