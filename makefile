TARGET=HTBinstall
SRC=$(TARGET).asm htbinstall.asm htbinstall.inc data.asm thread.asm
OBJS=$(TARGET).obj
INC=
RES=rsrc.res
AFLAGS=-w+orphan-labels -w+macro-params -O2

LFLAGS=/NOLOGO /SUBSYSTEM:WINDOWS /MERGE:.rdata=.text

all: $(TARGET).exe

$(TARGET).exe: $(TARGET).obj $(RES)
	link $(LFLAGS) $(OBJS) $(RES)

$(TARGET).obj: $(SRC) $(INC)
	nasm.exe $(AFLAGS) htbinstall.asm
