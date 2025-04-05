CC=gcc
ASMBIN=nasm

imgt : image_test.o image.o convert.o 

convert.o : convert.asm
	$(ASMBIN) -o convert.o -f elf64 -g -F dwarf convert.asm

image.o : image.h image.c
	$(CC) -no-pie  -c -g -O0 -m64 -fPIC image.c

image_test.o : image.h image_test.c
	$(CC) -no-pie  -c -g -O0 -m64 -fPIC image_test.c

imgt : image_test.o image.o convert.o
	$(CC) -no-pie  -g -o imgt -m64 -fPIC image_test.o image.o convert.o

clean :
	rm *.o
	rm imgt