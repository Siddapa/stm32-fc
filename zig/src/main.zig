// const gpio = @import("gpio.zig");
// 
// 
// export fn _start() void {
//     gpio.port_setup(2, 1);
//     gpio.pin_setup(2, 13, 0b00, 0b01);
//     while (true) {
//         gpio.set_pin(2, 13, 0);
//         for (0..100000) |i| { _ = i; }
//         gpio.set_pin(2, 13, 1);
//         for (0..100000) |i| { _ = i; }
//     }
// }

pub const RCC_APB2ENR = @as(*volatile u32, @ptrFromInt(0x40021018));

pub const GPIOB_CRL = @as(*volatile u32, @ptrFromInt(0x40010C00));
pub const GPIOB_ODR = @as(*volatile u32, @ptrFromInt(0x40010C0C));

pub const GPIOC_CRH = @as(*volatile u32, @ptrFromInt(0x40011004));
pub const GPIOC_ODR = @as(*volatile u32, @ptrFromInt(0x4001100C));

export fn _start() void {
    RCC_APB2ENR.* &= ~@as(u32, 0x8);
    RCC_APB2ENR.* |= @as(u32, 0x8);
    RCC_APB2ENR.* &= ~@as(u32, 0x10);
    RCC_APB2ENR.* |= @as(u32, 0x10);
        
    // GPIOB_CRL.* &= ~@as(u32, 0b1111 << 24);
    // GPIOB_CRL.* |= @as(u32, 0b0001 << 24);
    GPIOC_CRH.* &= ~@as(u32, 0b1111 << 20);
    GPIOC_CRH.* |= @as(u32, 0b0001 << 20);
    // GPIOC_CRH.* &= ~(@as(u32, 0x00F00000));
    // GPIOC_CRH.* |= @as(u32, 0x00100000);

    GPIOC_ODR.* &= ~@as(u32, 0x00001000);
    GPIOC_ODR.* |= @as(u32, 0x00000000);

    // while (true) {
    //     var i: u32 = 0;

    //     // GPIOC_ODR.* &= ~@as(u32, 0x00001020);
    //     // GPIOC_ODR.* |= @as(u32, 0x00000000);
    //     while (i < 100000) {
    //         i += 1;
    //     }
    //     i = 0;

    //     // GPIOC_ODR.* &= ~@as(u32, 0x00001020);
    //     // GPIOC_ODR.* |= @as(u32, 0x00001020);
    //     while (i < 100000) {
    //         i += 1;
    //     }
    // }
}
