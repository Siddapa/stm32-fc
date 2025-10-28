// Decoding from USART RX1 - A10
// PCLK2 defaulted to 8 MHz


const gpio = @import("../tools/gpio.zig");


const PERIPHERAL: u32 = 0x4000_0000;

const RCC: u32 = PERIPHERAL + 0x0002_1000;
const RCC_APB2ENR_REG: *volatile u32 = @ptrFromInt(RCC + 0x18);

const USART1: u32 = PERIPHERAL + 0x0001_3800;
const USART1_DATA_REG: *volatile u32 = @ptrFromInt(USART1 + 0x04);
const USART1_BRR_REG: *volatile u32 = @ptrFromInt(USART1 + 0x08);
const USART1_CR1_REG: *volatile u32 = @ptrFromInt(USART1 + 0x0C);
const USART1_CR2_REG: *volatile u32 = @ptrFromInt(USART1 + 0x10);

const built_frame: [32]u8 = undefined;
const frame_buffer: [32]u8 = undefined;
var byte_pos: u5 = 0;

pub fn setup() !void {
    // USART1's RX on A10 is a GPIO so that also must be enabled
    try gpio.port_setup(0, 1);
    try gpio.pin_setup(0, 10, @as(u32, 0b01), @as(u32, 0b00)); // Supposedly must be a floating input

    //                    Enable USART1 in RCC     Enable Alternate Function in RCC
    RCC_APB2ENR_REG.* &= ~((@as(u32, 0b1) << 14) | (@as(u32, 0b1) << 0));
    RCC_APB2ENR_REG.* |=  ((@as(u32, 0b1) << 14) | (@as(u32, 0b1) << 0));

    //                   Enable USART             Word Length             Parity Enable           Even Parity            Receive Enable
    USART1_CR1_REG.* &= ~((@as(u32, 0b1) << 13) | (@as(u32, 0b1) << 12) | (@as(u32, 0b1) << 10) | (@as(u32, 0b1) << 9) | (@as(u32, 0b1) << 2));
    USART1_CR1_REG.* |=  ((@as(u32, 0b1) << 13) | (@as(u32, 0b0) << 12) | (@as(u32, 0b1) << 10) | (@as(u32, 0b0) << 9) | (@as(u32, 0b1) << 2));

    //                   2 Stop Bits
    USART1_CR2_REG.* &= ~((@as(u32, 0b11) << 12));
    USART1_CR2_REG.* |=  ((@as(u32, 0b10) << 12));

    //                   Total BRR Value of 69
    USART1_BRR_REG.* &= ~((@as(u32, 0b1111_1111_1111) << 4) | (@as(u32, 0b1111) << 0));
    USART1_BRR_REG.* |=  ((@as(u32, 0b0000_0010_0100) << 4) | (@as(u32, 0b0101) << 0));
}


pub fn decode() void {
    frame_buffer[byte_pos] = @as(u32, USART1_DATA_REG.* & 0xFF);
    byte_pos = (byte_pos + 1) % 32;
}
