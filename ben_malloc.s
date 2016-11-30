//Globals
.set BRK, 45

.data
heap_prev:
	.word 0
heap_end:
	.word 0
heap_start:
	.word 0

.text
.global _start
_start:
	push {r4, r5, r6, r7, lr}
	mov r0, #24
	bl  malloc
	mov r4, r0

	mov r0, #32
	bl  malloc
	mov r5, r0

	mov r0, #16
	bl  malloc
	mov r6, r0

	mov r0, r5
	bl  deallocate

	mov r0, #24
	bl  malloc
	mov r5, r0

	mov r0, r6
	bl  deallocate

  mov r0, #1
  lsl r0, r0, #13
  bl  malloc

	push {r4, r5, r6, r7, lr}

	mov r7, #1
	svc #0


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
