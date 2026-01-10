const debug = @import("tools/debug.zig");
const time = @import("tools/time.zig");
const Err = @import("tools/error.zig").Err;
const gpio = @import("tools/peripherals/gpio.zig");
const dma = @import("tools/peripherals/dma.zig");
const usart = @import("tools/peripherals/usart.zig");
const timer = @import("tools/peripherals/timer.zig");

const ibus = @import("protocols/ibus.zig");
const dshot = @import("protocols/dshot.zig");

const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;

const CR_OFFSET:   u32 = 0x00;
const CFGR_OFFSET: u32 = 0x04;

const FLASH_ACR: u32 = 0x4002_2000;

// comptime {
//     @import("startup.zig").exportStartSymbol();
//     @import("vector_table.zig").exportVectorTable();
// }
//

export fn _start() callconv(.c) void {
    rcc_setup();

    // Terminal printing
    debug.setup();
    debug.reset_terminal();

    debug.print("Setup onboard LED...\n", .{});
    gpio.port_setup(.C, 1);
    gpio.pin_setup(.C, 13, 0b00, 0b11);
    gpio.set_pin(.C, 13, 0);

    gpio.port_setup(.A, 1);
    gpio.pin_setup(.A, 7, 0b00, 0b11);
    gpio.set_pin(.A, 7, 1);

    debug.print("Setup DMA for iBUS Receiver...\n", .{});
    ibus.setup();
 
    dshot.setup();
    
    dshot.arm();

    // var data = ibus.get_transmit_data();
    // debug.print("{f}\n", .{data});
    // while (data.swa == false) : (ibus.decode() catch unreachable) {
    //     data = ibus.get_transmit_data();
    //     debug.print("{f}\r", .{data});
    //     time.sleep(10000);
    // }

}

fn ibus_dshot_test() void {
    ibus.decode() catch debug.print("Corrupted iBUS frame!\n", .{});
    
    const data = ibus.get_transmit_data();

    // TRUE TEST
    dshot.set_motor_speeds(.{
        throttle_to_speed(data.left_y),
        throttle_to_speed(data.left_x),
        throttle_to_speed(data.right_y),
        throttle_to_speed(data.right_x)
    });

    // RAW THROTTLE VALUES
    // dshot.set_motor_speeds(.{
    //     data.left_y,
    //     data.left_x,
    //     data.right_y,
    //     data.right_x
    // }, false);
}

fn throttle_to_speed(throttle: u16) u16 {
    return @as(u16, @intCast(@as(i16, -2000) + 2 * @as(i16, @intCast(throttle)) + 47));
}

// WARNING: This test is susceptible to prints which mess up the timing
// gaps between each transmission mode
fn dshot_test() void {
    const test_speeds = [_][4]u16{ 
        .{ 0b10000000000, 0b11000000000, 0b11100000000, 0b11110000000 },
        .{ 0b11110000000, 0b11100000000, 0b11000000000, 0b10000000000 },
        .{ 0b11111000000, 0b11111000000, 0b11111000000, 0b11111000000 },
        .{ 0b00000111111, 0b00000111111, 0b00000111111, 0b00000111111 },
    };
    dshot.pulse_frames(4, test_speeds);

    dshot.set_motor_speeds(test_speeds[2], false);
    time.sleep(1000);

    dshot.empty_buffer();
    time.sleep(1000);

    dshot.set_motor_speeds(test_speeds[3], false);
    time.sleep(1000);
}

fn ibus_test() void {
    ibus.decode() catch debug.print("Corrupted iBUS frame!\n", .{});

    debug.print("{f}\r", .{ ibus.get_transmit_data() });
}

fn debug_test() void {
    var i: u8 = 0;
    while (true) {
        debug.print("{d}\n", .{i});
        time.sleep(100_000);
        i += 1;
    }
}

fn blinky() void {
    const wait_time = 1_000_000;

    while (true) {
        try gpio.set_pin(.C, 13, 0);
        time.sleep(wait_time);
        try gpio.set_pin(.C, 13, 1);
        time.sleep(wait_time);
    }
}

// TODO Make an "rcc" and "flash" tool
fn rcc_setup() void {
    // Overclock system to 64MHz while keeping peripherals at 8MHz
    const flash_acr_reg: *volatile u32 = @ptrFromInt(FLASH_ACR);
    flash_acr_reg.* &= ~((@as(u32, 0b1) << 4) | (@as(u32, 0b111) << 0));
    flash_acr_reg.* |=  ((@as(u32, 0b1) << 4) | (@as(u32, 0b010) << 0));

    const rcc_cfgr_reg: *volatile u32 = @ptrFromInt(RCC + CFGR_OFFSET);
    rcc_cfgr_reg.* &= ~((@as(u32, 0b1111) << 18) |
                        (@as(u32, 0b1)    << 17) |
                        (@as(u32, 0b1)    << 16) |
                        (@as(u32, 0b111)  << 11) |
                        (@as(u32, 0b111)  << 8) |
                        (@as(u32, 0b1111) << 4) |
                        (@as(u32, 0b11)   << 0));
    rcc_cfgr_reg.* |=  ((@as(u32, 0b0100) << 18) | // PLL Multiplier
                        (@as(u32, 0b1)    << 17) | // HSE -> PLL
                        (@as(u32, 0b1)    << 16) | // PLL Source (HSE)
                        (@as(u32, 0b000)  << 11) | // APB2 Prescaler
                        (@as(u32, 0b110)  << 8) |  // APB1 Prescaler
                        (@as(u32, 0b0000) << 4) |  // AHB Prescaler
                        (@as(u32, 0b10)   << 0));  // SYCLK

    const rcc_cr_reg: *volatile u32 = @ptrFromInt(RCC + CR_OFFSET);
    rcc_cr_reg.* &= ~((@as(u32, 0b1) << 24) | (@as(u32, 0b1) << 16));
    rcc_cr_reg.* |=  ((@as(u32, 0b1) << 24) | (@as(u32, 0b1) << 16));
}
