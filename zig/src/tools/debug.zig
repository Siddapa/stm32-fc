// Decoding from USART RX1 - A10
// PCLK2 defaulted to 8 MH
const std = @import("std");

const Err = @import("../tools/error.zig").Err;
const gpio = @import("../tools/gpio.zig");
const timer = @import("../tools/timer.zig");


const PERIPHERAL: u32 = 0x4000_0000;

const RCC: u32 = PERIPHERAL + 0x0002_1000;
const RCC_CR_REG: *volatile u32 = @ptrFromInt(RCC + 0x00);
const RCC_CFGR_REG: *volatile u32 = @ptrFromInt(RCC + 0x04);
const RCC_APB2ENR_REG: *volatile u32 = @ptrFromInt(RCC + 0x18);

const USART1: u32 = PERIPHERAL + 0x0001_3800;
const USART1_SR_REG:   *volatile u32 = @ptrFromInt(USART1 + 0x00);
const USART1_DATA_REG: *volatile u32 = @ptrFromInt(USART1 + 0x04);
const USART1_BRR_REG:  *volatile u32 = @ptrFromInt(USART1 + 0x08);
const USART1_CR1_REG:  *volatile u32 = @ptrFromInt(USART1 + 0x0C);
const USART1_CR2_REG:  *volatile u32 = @ptrFromInt(USART1 + 0x10);


pub fn setup() Err!void {
    // //               Disable PLL              Enable HSE
    // RCC_CR_REG.* &= ~((@as(u32, 0b1) << 24) | (@as(u32, 0b1) << 16));
    // RCC_CR_REG.* |=  ((@as(u32, 0b0) << 24) | (@as(u32, 0b1) << 16));

    // //                 PLL x 9                     PLL Input Clock
    // RCC_CFGR_REG.* &= ~((@as(u32, 0b1111) << 18) | (@as(u32, 0b1) << 16));
    // RCC_CFGR_REG.* |=  ((@as(u32, 0b0111) << 18) | (@as(u32, 0b1) << 16));

    // //               Re-enable PLL
    // RCC_CR_REG.* &= ~(@as(u32, 0b1) << 24);
    // RCC_CR_REG.* |=  (@as(u32, 0b1) << 24);

    // USART1's RX on A10 is a GPIO so that also must be enabled
    try gpio.port_setup(.A, 1);
    try gpio.pin_setup(.A, 9, @as(u32, 0b10), @as(u32, 0b01)); // Alternate push-pull output

    //                    Enable USART1 in RCC     Enable Alternate Function in RCC
    RCC_APB2ENR_REG.* &= ~((@as(u32, 0b1) << 14) | (@as(u32, 0b1) << 0));
    RCC_APB2ENR_REG.* |=  ((@as(u32, 0b1) << 14) | (@as(u32, 0b1) << 0));

    //                   8-bit Word Length        Parity Disabled
    USART1_CR1_REG.* &= ~((@as(u32, 0b1) << 12) | (@as(u32, 0b1) << 10));
    USART1_CR1_REG.* |=  ((@as(u32, 0b0) << 12) | (@as(u32, 0b0) << 10));

    //                   1 Stop Bit
    USART1_CR2_REG.* &= ~((@as(u32, 0b11) << 12));
    USART1_CR2_REG.* |=  ((@as(u32, 0b00) << 12));

    //                   Mantissa of 0x27 from 39             Fraction of 0x1 from (16 * 0.0625)
    USART1_BRR_REG.* &= ~((@as(u32, 0b1111_1111_1111) << 4) | (@as(u32, 0b1111) << 0));
    USART1_BRR_REG.* |=  ((@as(u32, 0b0000_0000_0100) << 4) | (@as(u32, 0b0101) << 0));
    // 4 5

    //                   Enable USART             Transmitter Enable
    USART1_CR1_REG.* &= ~((@as(u32, 0b1) << 13) | (@as(u32, 0b1) << 3));
    USART1_CR1_REG.* |=  ((@as(u32, 0b1) << 13) | (@as(u32, 0b1) << 3));
}

pub fn print(comptime str: []const u8, args: anytype) !void {
    var buffer: [1024]u8 = undefined;
    const formatted_str = try std.fmt.bufPrint(&buffer, str, args);

    for (formatted_str) |char| {
        while (shifting_DR()) {}
        USART1_DATA_REG.* &= ~@as(u32, 0b1111_1111);
        USART1_DATA_REG.* |=  @as(u32, char);
    }

    // Unnecessary for single-byte transmissions since
    // there's no large, connected frame
    // while (!finished_transmission()) {}
}


fn shifting_DR() bool {
    return (USART1_SR_REG.* & (@as(u32, 0b1) << 7)) == 0;
}

fn finished_transmission() bool {
    return (USART1_SR_REG.* & (@as(u32, 0b1) << 6)) == 1;
}
