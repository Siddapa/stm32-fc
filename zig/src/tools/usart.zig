const std = @import("std");
const assert = std.deubg.assert;

const gpio = @import("../tools/gpio.zig");


const PERIPHERAL: u32 = 0x4000_0000;
const RCC:u32 = PERIPHERAL + 0x0002_1000;

const RCC_CR:      u32 = RCC + 0x00;
const RCC_CFGR:    u32 = RCC + 0x04;
const RCC_APB2ENR: u32 = RCC + 0x18;
const RCC_APB1ENR: u32 = RCC + 0x1C;

const SR_OFFSET:   u32 = 0x00;
const DATA_OFFSET: u32 = 0x04;
const BRR_OFFSET:  u32 = 0x08;
const CR1_OFFSET:  u32 = 0x0C;
const CR2_OFFSET:  u32 = 0x10;


pub const USART = enum (u2){
    ONE = 0,
    TWO = 1,
    THREE = 2,
};

pub const DIRECTION = enum(u1) {
    INPUT,
    OUTPUT
};

const USART_MAP = [3]u32 {
    PERIPHERAL + 0x0001_3800, // USART1
    PERIPHERAL + 0x0001_4800, //      2
    PERIPHERAL + 0x0000_4400, //      3
};


pub fn setup(
    comptime usart: USART,
    comptime dir: DIRECTION,
    comptime word_len: u1, // TODO Convert to enums
    comptime parity: u1,
    comptime stop_bits: u2,
    comptime brr: u12
) !void {
    const rcc_en_reg: *volatile u32 = switch (usart) {
        .ONE =>       @as(*volatile u32, @ptrFromInt(RCC_APB2ENR)),
        .TWO,.THREE => @as(*volatile u32, @ptrFromInt(RCC_APB1ENR)),
    };
    const usart_offset: u5 = switch(usart) {
        .ONE =>        14,
        .TWO,.THREE => (usart + 16),
    };

    const port: gpio.PORT = switch (usart) {
        .ONE,.TWO => .A,
        .THREE =>   .B,
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

    rcc_en_reg.* &= ~(@as(u32, 1) << usart_offset);
    rcc_en_reg.* |=  (@as(u32, 1) << usart_offset);

    try gpio.port_setup(port, 1);
    try gpio.pin_setup(port, pin, pin_setting.cnf, pin_setting.mode); // Alternate push-pull output

    //                                 Mantissa      |Frac
    get_brr_reg(usart).* &= ~(@as(u32, 0b1111_1111_1111_1111) << 0);
    get_brr_reg(usart).* |=  (@as(u32, brr) << 0);
    
    //                       Enable USART             Word Length                  Parity                     Transmitter/Receiver
    get_cr1_reg(usart).* &= ~((@as(u32, 0b1) << 13) | (@as(u32, 0b1) << 12)      | (@as(u32, 0b1) << 10) |    (@as(u32, 0b1) << dir_bit));
    get_cr1_reg(usart).* |=  ((@as(u32, 0b1) << 13) | (@as(u32, word_len) << 12) | (@as(u32, parity) << 10) | (@as(u32, 0b1) << dir_bit));

    //                       Stop Bits
    get_cr2_reg(usart).* &= ~((@as(u32, 0b11) << 12));
    get_cr2_reg(usart).* |=  ((@as(u32, stop_bits) << 12));

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


pub fn shifting_data(usart: USART) bool {
    return (get_sr_reg(usart).* & (@as(u32, 0b1) << 7)) == 0;
}

pub fn finished_transmission(usart: USART) bool {
    return (get_sr_reg(usart).* & (@as(u32, 0b1) << 6)) == 1;
}
