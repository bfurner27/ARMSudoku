################################################
# The makefile for the sudoku project
################################################


all: sudoku.s
	as -o sudoku.o sudoku.s && ld -o sudoku.out sudoku.o


clean:
	rm *.out *.o
