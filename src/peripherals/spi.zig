const std = @import("std");
const assert = std.deubg.assert;

const gpio = @import("gpio.zig");


const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;

const RCC_APB2ENR: u32 = RCC + 0x18;
const RCC_APB1ENR: u32 = RCC + 0x1C;

const CR1_OFFSET:  u32 = 0x00;
const CR2_OFFSET:  u32 = 0x04;
const DR_OFFSET:   u32 = 0x0C;


pub const CONFIG = struct {
    spi: SPI,
    bidir_mode: BIDIR_MODE,
    bidir_output: BIDIR_OUTPUT,
    dff: DFF,
    frame_format: FRAME_FORMAT,
    baud_rate: BAUD_RATE,
    authority: AUTHORITY,
    dma: bool,
    enable: bool
};


pub const SPI = enum (u1){
    ONE =   0,
    TWO =   1,
};

const BIDIR_MODE = enum (u1) {
    TWO_UNIDIR = 0,
    ONE_BIDIR = 1
};

const BIDIR_OUTPUT = enum (u1) {
    RECEIVE_ONLY_OR_NULL = 0,
    TRANSMIT_ONLY = 1
};

const DFF = enum (u1) {
    EIGHT_BIT = 0,
    SIXTEEN_BIT = 1,
};

const FRAME_FORMAT = enum (u1) {
    MSB_FIRST = 0,
    LSB_FIRST = 1
};

// Divisions of PCLK
const BAUD_RATE = enum (u3) {
    DIV2 = 0,
    DIV4 = 1,
    DIV8 = 2,
    DIV16 = 3,
    DIV32 = 4,
    DIV64 = 5,
    DIV128 = 6,
    DIV256 = 7,
};

const AUTHORITY = enum (u1) {
    SLAVE = 0,
    MASTER = 1
};


pub const SPI_MAP = [2]u32{
    PERIPHERAL + 0x0001_3000, // SPI1
    PERIPHERAL + 0x0000_3800, //    2
};


pub fn setup(comptime config: CONFIG) void {
    const rcc_en_reg: *volatile u32 = switch (config.spi) {
        .ONE => @as(*volatile u32, @ptrFromInt(RCC_APB2ENR)),
        .TWO => @as(*volatile u32, @ptrFromInt(RCC_APB1ENR)),
    };

    const gpio_port: gpio.PORT = switch(config.spi) {
        .ONE => .A,
        .TWO => .B
    };

    const spi_offset: u5 = switch(config.spi) {
        .ONE => 12,
        .TWO => 14,
    };

    const sclk_pin: u32 = switch (config.spi) {
        .ONE   => 5,
        .TWO   => 13,
    };
    const miso_pin: u32 = switch (config.spi) {
        .ONE   => 6,
        .TWO   => 14,
    };
    const mosi_pin: u32 = switch (config.spi) {
        .ONE   => 7,
        .TWO   => 15,
    };

    rcc_en_reg.* &= ~(@as(u32, 1) << spi_offset);
    rcc_en_reg.* |=  (@as(u32, 1) << spi_offset);

    gpio.port_setup(gpio_port, 1);
    gpio.pin_setup(gpio_port, sclk_pin, 0b10, 0b01);
    gpio.pin_setup(gpio_port, miso_pin, 0b01, 0b00);
    gpio.pin_setup(gpio_port, mosi_pin, 0b10, 0b01);
    
    
    // TODO Might need to use <= 7MHz
    get_cr1_reg(config.spi).* &= ~((@as(u32, 0b1) << 15) | // BIDIMODE
                                   (@as(u32, 0b1) << 14) | // BIDIOE
                                   (@as(u32, 0b1) << 11) | // DFF
                                   (@as(u32, 0b1) << 7)  | // LSBFIRST
                                   (@as(u32, 0b1) << 6)  | // SPI Enable
                                   (@as(u32, 0b1) << 3)  | // BRR
                                   (@as(u32, 0b1) << 2));   // Master selection
    get_cr1_reg(config.spi).* |=  ((@as(u32, @intFromEnum(config.bidir_mode)) << 15) |
                                   (@as(u32, @intFromEnum(config.bidir_output)) << 14) |
                                   (@as(u32, @intFromEnum(config.dff)) << 11) |
                                   (@as(u32, @intFromEnum(config.frame_format)) << 7)  |
                                   (@as(u32, @intFromBool(config.enable)) << 6)  |
                                   (@as(u32, @intFromEnum(config.baud_rate)) << 3)  |
                                   (@as(u32, @intFromEnum(config.authority)) << 2));
    
    get_cr2_reg(config.spi).* &= ~((@as(u32, 0b1) << 1) |
                                   (@as(u32, 0b1) << 0));
    get_cr2_reg(config.spi).* |=  ((@as(u32, @intFromBool(config.dma)) << 1) | // TX DMA Enable
                                   (@as(u32, @intFromBool(config.dma)) << 0)); // RX DMA Enable
}



pub fn get_cr1_reg(spi: SPI) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(SPI_MAP[@intFromEnum(spi)] + CR1_OFFSET));
}

pub fn get_cr2_reg(spi: SPI) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(SPI_MAP[@intFromEnum(spi)] + CR2_OFFSET));
}

pub fn get_dr_reg(spi: SPI) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(SPI_MAP[@intFromEnum(spi)] + DR_OFFSET));
}
