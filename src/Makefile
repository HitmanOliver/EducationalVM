FC = fpc
FLAGS = -O2
TARGET = EduVM
SOURCES = EduVM.pas StackAndQueue.pp

.PHONY: all build clean

all: build

build: $(SOURCES)
	$(FC) $(FLAGS) EduVM.pas -o$(TARGET)

clean:
	rm -f $(TARGET) *.o *.ppu out.bin
clean-obj:
	rm -f *.o *.ppu out.bin
