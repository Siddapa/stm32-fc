const std = @import("std");
const assert = std.deubg.assert;

const gpio = @import("gpio.zig");
const debug = @import("../debug.zig");


const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;

const RCC_CR:      u32 = RCC + 0x00;
const RCC_CFGR:    u32 = RCC + 0x04;
const RCC_APB2ENR: u32 = RCC + 0x18;
const RCC_APB1ENR: u32 = RCC + 0x1C;

const SR_OFFSET:   u32 = 0x00;
const DATA_OFFSET: u32 = 0x04;
const BRR_OFFSET:  u32 = 0x08;
const CR1_OFFSET:  u32 = 0x0C;
const CR2_OFFSET:  u32 = 0x10;
const CR3_OFFSET:  u32 = 0x14;


pub const USART = enum (u2){
    ONE =   0,
    TWO =   1,
    THREE = 2,
};

pub const DIRECTION = enum(u1) {
    INPUT,
    OUTPUT
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

pub const USART_MAP = [3]u32 {
    PERIPHERAL + 0x0001_3800, // USART1
    PERIPHERAL + 0x0000_4400, //      2
    PERIPHERAL + 0x0000_4800, //      3
};


pub fn setup(
    comptime usart: USART,
    comptime dir: DIRECTION,
    comptime word_len: WORD_LEN,
    comptime parity: bool,
    comptime parity_type: PARITY_TYPE,
    comptime stop_bits: STOP_BITS,
    comptime dma: bool,
    comptime brr: u12
) void {
    const rcc_en_reg: *volatile u32 = switch (usart) {
        .ONE =>        @as(*volatile u32, @ptrFromInt(RCC_APB2ENR)),
        .TWO,.THREE => @as(*volatile u32, @ptrFromInt(RCC_APB1ENR)),
    };

    const usart_offset: u5 = switch(usart) {
        .ONE =>        14,
        .TWO,.THREE => (@as(u5, @intCast(@intFromEnum(usart))) + 16),
    };

    const port: gpio.PORT = switch (usart) {
        .ONE,.TWO => .A,
        .THREE =>    .B,
    };
    
    // Initially set to output pin but +1 if desired pin should be input
    const pin: u32 = switch (usart) {
        .ONE   => 9,
        .TWO   => 2,
        .THREE => 10
    } + @as(u32, @intFromBool(dir == .INPUT));

    const pin_setting: struct { cnf: u32, mode: u32 } = switch(dir) {
        .INPUT =>  .{ .cnf = 0b01, .mode = 0b00 },
        .OUTPUT => .{ .cnf = 0b10, .mode = 0b01 }
    };
    
    const dir_bit: u5 = switch (dir) {
        .INPUT => 2,
        .OUTPUT => 3,
    };

    const dma_bit: u5 = dir_bit + 4;

    rcc_en_reg.* &= ~(@as(u32, 1) << usart_offset);
    rcc_en_reg.* |=  (@as(u32, 1) << usart_offset);

    gpio.port_setup(port, 1);
    gpio.pin_setup(port, pin, pin_setting.cnf, pin_setting.mode);

    //                                   Mantissa       Frac
    get_brr_reg(usart).* &= ~(@as(u32, 0b1111_1111_1111_1111) << 0);
    get_brr_reg(usart).* |=  (@as(u32, brr) << 0);
    
    get_cr1_reg(usart).* &= ~((@as(u32, 0b1) << 13) |
                              (@as(u32, 0b1) << 12) |
                              (@as(u32, 0b1) << 10) |
                              (@as(u32, 0b1) << 9) |
                              (@as(u32, 0b1) << dir_bit));

    get_cr1_reg(usart).* |=  ((@as(u32, 0b1) << 13) |                      // Enable USART
                              (@as(u32, @intFromEnum(word_len)) << 12) |   // Word Length
                              (@as(u32, @intFromBool(parity)) << 10) |     // Parity
                              (@as(u32, @intFromEnum(parity_type)) << 9) | // Even/Odd Parity
                              (@as(u32, 0b1) << dir_bit));                 // Transmitter/Receiver

    //                       Stop Bits
    get_cr2_reg(usart).* &= ~((@as(u32, 0b11) << 12));
    get_cr2_reg(usart).* |=  ((@as(u32, @intFromEnum(stop_bits)) << 12));

    //                       Enable DMA
    get_cr3_reg(usart).* &= ~(@as(u32, 0b1) << dma_bit);
    get_cr3_reg(usart).* |=  (@as(u32, @intFromBool(dma)) << dma_bit);
}


pub fn get_sr_reg(usart: USART) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(USART_MAP[@intFromEnum(usart)] + SR_OFFSET));
}


pub fn get_data_reg(usart: USART) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(USART_MAP[@intFromEnum(usart)] + DATA_OFFSET));
}

pub fn get_brr_reg(usart: USART) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(USART_MAP[@intFromEnum(usart)] + BRR_OFFSET));
}


pub fn get_cr1_reg(usart: USART) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(USART_MAP[@intFromEnum(usart)] + CR1_OFFSET));
}

pub fn get_cr2_reg(usart: USART) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(USART_MAP[@intFromEnum(usart)] + CR2_OFFSET));
}

pub fn get_cr3_reg(usart: USART) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(USART_MAP[@intFromEnum(usart)] + CR3_OFFSET));
}


pub fn shifting_data(usart: USART) bool {
    return (get_sr_reg(usart).* & (@as(u32, 0b1) << 7)) == 0;
}

pub fn reading_data(usart: USART) bool {
    return (get_sr_reg(usart).* & (@as(u32, 0b1) << 5)) == 0;
}

pub fn finished_transmission(usart: USART) bool {
    return (get_sr_reg(usart).* & (@as(u32, 0b1) << 6)) == 1;
}
