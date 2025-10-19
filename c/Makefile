GCC=~/apps/gcc-ane/bin/arm-none-eabi-gcc
OBJCPY=~/apps/gcc-ane/bin/arm-none-eabi-objcopy
BIN=bin/
OBJ=obj/

all: flash

flash: $(BIN)blink.bin
	st-flash --reset write $(BIN)blink.bin 0x08000000

bin/blink.bin: setup main.c
	$(GCC) -o $(OBJ)main.o -c -g -mcpu=cortex-m3 -mthumb -nostdlib main.c
	$(GCC) -o $(BIN)blink.elf -Wl,-Tmemory.ld -nostartfiles $(OBJ)main.o
	$(OBJCPY) -O binary $(BIN)blink.elf $(BIN)blink.bin

setup:
	mkdir -p $(BIN)
	mkdir -p $(OBJ)

clean: setup
	rm -f $(BIN)*
	rm -f $(OBJ)*
