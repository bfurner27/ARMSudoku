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
header: .ascii "   A B C D E F G H I\n"
space: .ascii "  "
numSpace: .ascii "  "
num2Space: .ascii "   "
vertBar: .ascii "\b|"
horizBreak: .ascii "   -----+-----+-----\n"
testBoard:
        .ascii "123406789123456789123456789123456789123456789023456789123456780123469789103456789"

read: .skip 32
.text
.global _start
main:
_start:
        ldr r0, =testBoard //load board
        bl displayBoard

        mov r0, #0
        mov r7, #EXIT
        svc #0

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
.Loop:  ldrb r2, [r4, r5] //load byte from board
        //add r1, r1, #48 //change to ascii
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