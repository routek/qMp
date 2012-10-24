PROGRAM_NAME=encrypt
PROGRAM_NAME2=decrypt
CC = gcc
CFLAGS = -g -O2 

OBJ = $(PROGRAM_NAME).o
OBJ2 = $(PROGRAM_NAME2).o

all: compile 

clean:
	rm -f *.o $(PROGRAM_NAME) $(PROGRAM_NAME2)

compile: $(OBJ) $(OBJ2)
	$(CC) -o $(PROGRAM_NAME) $(OBJ)  -lcrypto
	$(CC) -o $(PROGRAM_NAME2) $(OBJ2)  -lcrypto

.c.o:
	$(CC) -c $(CFLAGS) $<

