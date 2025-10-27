// Decoding from USART RX1 - A10
// PCLK2 defaulted to 8 MHz


const gpio = @import("../tools/gpio.zig");


const PERIPHERAL: u32 = 0x4000_0000;

const RCC: u32 = PERIPHERAL + 0x0002_1000;
const RCC_CR_REG: *volatile u32 = @ptrFromInt(RCC + 0x00);
const RCC_CFGR_REG: *volatile u32 = @ptrFromInt(RCC + 0x04);

const USART1: u32 = PERIPHERAL + 0x0001_3800;
const USART1_DATA_REG: *volatile u32 = @ptrFromInt(USART1 + 0x04);
const USART1_BRR_REG: *volatile u32 = @ptrFromInt(USART1 + 0x08);
const USART1_CR1_REG: *volatile u32 = @ptrFromInt(USART1 + 0x0C);
const USART1_CR2_REG: *volatile u32 = @ptrFromInt(USART1 + 0x10);


const frame_buffer: [4]u8 = undefined;

pub fn setup() !void {
    // Disable PLL, Enable HSE
    RCC_CR_REG.* &= ~((@as(u32, 0b1) << 24) | (@as(u32, 0b1) << 16));
    RCC_CR_REG.* |=  ((@as(u32, 0b0) << 24) | (@as(u32, 0b1) << 16));

    // HSE as MCO, PLL x 9, PLL Input Clock
    RCC_CFGR_REG.* &= ~((@as(u32, 0b111) << 24) | (@as(u32, 0b1111) << 18) | (@as(u32, 0b1) << 16));
    RCC_CFGR_REG.* |=  ((@as(u32, 0b110) << 24) | (@as(u32, 0b0111) << 18) | (@as(u32, 0b1) << 16));

    // Re-enable PLL
    RCC_CR_REG.* &= ~(@as(u32, 0b1) << 24);
    RCC_CR_REG.* |=  (@as(u32, 0b1) << 24);

    // USART1's RX on A10 is a GPIO so that also must be enabled
    try gpio.port_setup(0, 1);
    try gpio.pin_setup(0, 10, @as(u32, 0b01), @as(u32, 0b00)); // Supposedly must be a floating input

    // Enable USART, Word Length, Parity Enable, Even Parity, Receive Interrupt, Receive Enable
    USART1_CR1_REG.* &= ~((@as(u32, 0b1) << 13) | (@as(u32, 0b1) << 12) | (@as(u32, 0b1) << 10) | (@as(u32, 0b1) << 9) | (@as(u32, 0b1) << 5) | (@as(u32, 0b1) << 2));
    USART1_CR1_REG.* |=  ((@as(u32, 0b1) << 13) | (@as(u32, 0b0) << 12) | (@as(u32, 0b1) << 10) | (@as(u32, 0b0) << 9) | (@as(u32, 0b1) << 5) | (@as(u32, 0b1) << 2));

    // 2 Stop Bits
    USART1_CR2_REG.* &= ~((@as(u32, 0b11) << 12));
    USART1_CR2_REG.* |=  ((@as(u32, 0b10) << 12));

    // Mantissa of 0x27 from 37, Fraction of 0x1 from (16 * 0.0625)
    USART1_BRR_REG.* &= ~((@as(u32, 0b1111_1111_1111) << 4) | (@as(u32, 0b1111) << 0));
    USART1_BRR_REG.* |=  ((@as(u32, 0b0000_0010_0111) << 4) | (@as(u32, 0b0001) << 0));
}


pub fn decode() void {

}
