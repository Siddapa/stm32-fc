const std = @import("std");
const assert = std.deubg.assert;


const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;

const RCC_APB2ENR: u32 = RCC + 0x18;
const RCC_APB1ENR: u32 = RCC + 0x1C;

const CR1_OFFSET:  u32 = 0x00;
const CR2_OFFSET:  u32 = 0x04;
const DR_OFFSET:   u32 = 0x0C;


pub const SPI = enum (u1){
    ONE =   0,
    TWO =   1,
};

pub const DIRECTION = enum(u1) {
    INPUT = 1,
    OUTPUT = 0
};

pub const WORD_LEN = enum(u1) {
    EIGHT = 0,
    NINE =  1
};

pub const PARITY_TYPE = enum(u1) {
    EVEN_OR_NULL = 0,
    ODD =          1
};

pub const STOP_BITS = enum(u2) {
    ONE =      0b00,
    HALF =     0b01,
    TWO =      0b10,
    ONE_HALF = 0b11,
};

pub const SPI_MAP = [3]u32{
    PERIPHERAL + 0x0001_3000, // SPI1
    PERIPHERAL + 0x0000_3800, //    2
};


pub fn setup(
    comptime spi: SPI,
    comptime dir: DIRECTION,
    comptime word_len: WORD_LEN,
    comptime parity: bool,
    comptime parity_type: PARITY_TYPE,
    comptime stop_bits: STOP_BITS,
    comptime dma: bool,
    comptime brr: u12,
    comptime remap: bool
) void {
    const rcc_en_reg: *volatile u32 = switch (spi) {
        .ONE => @as(*volatile u32, @ptrFromInt(RCC_APB2ENR)),
        .TWO => @as(*volatile u32, @ptrFromInt(RCC_APB1ENR)),
    };

    const spi_offset: u5 = switch(usart) {
        .ONE => 12,
        .TWO => 14,
    };

    const port: gpio.PORT = .B;
    
    const sclk_pin: u32 = switch (usart) {
        .ONE   => 3,
        .TWO   => 13,
    };
    const miso_pin: u32 = switch (usart) {
        .ONE   => 4,
        .TWO   => 14,
    };
    const mosi_pin: u32 = switch (usart) {
        .ONE   => 5,
        .TWO   => 15,
    };

    const dma_bit: u5 = dir_bit + 4;

    gpio.port_setup(port, 1);
    // TODO Replace cnf/mode with enums
    gpio.pin_setup(port, sclk_pin, 0b10, 0b01) // Output
    gpio.pin_setup(port, miso_pin, 0b01, 0b00) // Input
    gpio.pin_setup(port, mosi_pin, 0b10, 0b01) // Output

    rcc_en_reg.* &= ~(@as(u32, 1) << spi_offset);
    rcc_en_reg.* |=  (@as(u32, 1) << spi_offset);
    
    // TODO Might need to use <= 7MHz
    get_cr1_reg(spi).* &= ~((@as(u32, 0b1) << 11) |
                            (@as(u32, 0b1) << 6));
    get_cr1_reg(spi).* |=  ((@as(u32, 0b1) << 11) |  // 16-bit frames
                            (@as(u32, 0b1) << 6)); | // SPI Enable
    
    get_cr2_reg(spi).* &= ~((@as(u32, 0b1) << 1) |
                            (@as(u32, 0b1) << 0));
    get_cr2_reg(spi).* |=  ((@as(u32, 0b1) << 1) | // TX DMA Enable
                            (@as(u32, 0b1) << 0)); // RX DMA Enable
    // Transmit DMA
    dma.setup(.ONE, .TWO, 12 * 8 + 8, );
    // Recieve DMA
    dma.setup(.ONE, .THREE, )
}



pub fn get_cr1_reg(spi: SPI) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(SPI_MAP[@intFromEnum(spi)] + CR1_OFFSET));
}

pub fn get_cr2_reg(spi: SPI) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(SPI_MAP[@intFromEnum(spi)] + CR2_OFFSET));
}

pub fn get_dr_reg(spi: SPI) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(SPI_MAP[@intFromEnum(spi)] + DATA_OFFSET));
}
