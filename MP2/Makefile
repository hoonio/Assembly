MPNAME=mp2

all: $(MPNAME).exe

clean: 
	rm -f $(MPNAME).exe $(MPNAME).obj $(MPNAME).lst $(MPNAME).map

%.exe: %.obj
	tlink /c /v $<, $*.exe, $*.map, lib291.lib libmp2.lib

%.obj: %.asm
	nasm -g -f obj -o $*.obj $< -l $*.lst

