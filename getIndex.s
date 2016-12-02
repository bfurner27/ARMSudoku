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
prompt: .ascii "Enter coordinate (num num): "
read: .skip 4
.text
.global _start
main:
_start:
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

        add r0, r0, #48 //move into ascii range
        ldr r1, =read
        strb r0, [r1] //store result
        mov r0, #10
        strb r0, [r1, #1] //add a new line
        mov r0, r1
        mov r1, #2
        bl display //show the result

        mov r0, #0
        mov r7, #EXIT
        svc #0


getIndex: //address of zero indexed numbers in r0
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



display: //address in r0, numBytes in r1
        push {lr}

        mov r2, r1 //place numBytes
        mov r1, r0 //place address
        //set up display
        mov r0, #STDOUT
        mov r7, #WRITE
        svc #0 //display

        pop {lr}
        bx lr


input: //r0 as addres, numBytes in r1
        push {lr}

        mov r2, r1 //place numBytes
        mov r1, r0 //place address
        //setup read
        mov r0, #STDIN
        mov r7, #READ
        svc #0 //read

        pop {lr}
        bx lr