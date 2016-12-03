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
test: .ascii "test: "
newLine: .ascii "\n"
commaSpace: .ascii " , "
doubleBSpace: .ascii "\b\b "
test1: .ascii "123000000"
test2: .ascii "000050009"
test3: .ascii "000000700"
.text
.global _start
_start:
	ldr r0, =test1
	bl printPosValues

	ldr r0, =test2
	bl printPosValues

	ldr r0, =test3
	bl printPosValues

	mov r0, #0
	mov r7, #EXIT
	svc #0

printPosValues: //takes address of posValues in r0, no return
        push {r4, lr}

        mov r4, r0 //keep address safe
        mov r2, #0 //loop counter
        ldr r3, =commaSpace //for display
.Ldis:
        ldrb r1, [r4, r2] //load possible value
        cmp r1, #48 //see if it is zero change to 0 ofr final program
        beq .LdisCont //if yes skip it
                      //if not display it
       // add r1, r1, #48 //convert to ascii
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


