all: flash

flash: bin/blink.bin
	st-flash --reset write bin/blink.bin 0x08000000

bin/blink.bin: main.c
	~/apps/gcc-ane/bin/arm-none-eabi-gcc -o main.o -c -g -mcpu=cortex-m4 -mthumb -nostdlib main.c
	~/apps/gcc-ane/bin/arm-none-eabi-gcc -o bin/blink.elf -Wl,-Tmemory.ld -nostartfiles main.o
	~/apps/gcc-ane/bin/arm-none-eabi-objcopy -O binary bin/blink.elf bin/blink.bin

clean:
	rm -f bin/*
