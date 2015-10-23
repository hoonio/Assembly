MPNAME=mp4

all: $(MPNAME).exe

clean: 
	-rm $(MPNAME).exe

remake: clean all

%.exe: %.o
	gcc -o $(MPNAME) $(MPNAME).o v:/ece291/pmodelib/lib291.a libmp4.a

%.o: %.asm
	nasm -f coff -iv:/ece291/pmodelib/include/ -o $ $*.o $< -l $*.lst
