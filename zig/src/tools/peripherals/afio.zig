const gpio = @import("gpio.zig");
const USART = @import("usart.zig").USART;
const DIRECTION = @import("usart.zig").DIRECTION;


const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;
const AFIO: u32 = PERIPHERAL + 0x0001_0000;

const MAPR_OFFSET: u32 = 0x04;


pub fn remap_usart(comptime usart: USART, comptime dir: DIRECTION, comptime pin_setting: gpio.PIN_SETTING) void {
    const apb2_reg: *volatile u32 = @ptrFromInt(RCC + 0x18);

    apb2_reg.* &= ~(@as(u32, 0b1) << 0);
    apb2_reg.* |=  (@as(u32, 0b1) << 0);

    get_mapr_reg().* &= ~(@as(u32, 0b1) << (@intFromEnum(usart) + 2));
    get_mapr_reg().* |=  (@as(u32, 0b1) << (@intFromEnum(usart) + 2));

    switch (usart) {
        .ONE => {
            const pin: u32 = 6 + @as(u32, @intFromEnum(dir));
            gpio.port_setup(.B, 1);
            gpio.pin_setup(.B, pin, pin_setting.cnf, pin_setting.mode);
        },
        else => unreachable
    }    
}


fn get_mapr_reg() *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(AFIO + MAPR_OFFSET));
}
