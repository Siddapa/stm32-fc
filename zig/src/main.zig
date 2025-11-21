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
    debug.print("\n\n\n\n\n", .{}); // Break terminal from prior program run

    debug.print("Setup onboard LED...\n", .{});
    gpio.port_setup(.C, 1);
    gpio.pin_setup(.C, 13, 0b00, 0b11);
    gpio.set_pin(.C, 13, 1);

    debug.print("Setup DMA for iBUS Receiver...\n", .{});
    ibus.setup();
 
    dshot.setup();

    dshot_test();
}

fn rcc_setup() void {
    // Overclock system to 64MHz while keeping peripherals at 8MHz
    const flash_acr_reg: *volatile u32 = @ptrFromInt(FLASH_ACR);
    flash_acr_reg.* &= ~((@as(u32, 0b1) << 4) | (@as(u32, 0b111) << 0));
    flash_acr_reg.* |=  ((@as(u32, 0b1) << 4) | (@as(u32, 0b010) << 0));

    const rcc_cfgr_reg: *volatile u32 = @ptrFromInt(RCC + CFGR_OFFSET);
    rcc_cfgr_reg.* &= ~((@as(u32, 0b1111) << 18) | (@as(u32, 0b1) << 16) | (@as(u32, 0b111) << 11) | (@as(u32, 0b111) << 8) | (@as(u32, 0b1111) << 4) | (@as(u32, 0b11) << 0));
    rcc_cfgr_reg.* |=  ((@as(u32, 0b0110) << 18) | (@as(u32, 0b1) << 16) | (@as(u32, 0b110) << 11) | (@as(u32, 0b110) << 8) | (@as(u32, 0b0000) << 4) | (@as(u32, 0b10) << 0));

    const rcc_cr_reg: *volatile u32 = @ptrFromInt(RCC + CR_OFFSET);
    rcc_cr_reg.* &= ~((@as(u32, 0b1) << 24) | (@as(u32, 0b1) << 16));
    rcc_cr_reg.* |=  ((@as(u32, 0b1) << 24) | (@as(u32, 0b1) << 16));
}

fn dshot_test() void {
    const test_speeds = [_][4]u16{ 
        .{ 0b11110000000, 0b11100000000, 0b11000000000, 0b10000000000 },
        .{ 0b10000000000, 0b11000000000, 0b11100000000, 0b11110000000 },
        .{ 0b11111000000, 0b11111000000, 0b11111000000, 0b11111000000 },
        .{ 0b00000111111, 0b00000111111, 0b00000111111, 0b00000111111 },
    };
    dshot.pulse_frames(4, test_speeds);
    time.sleep(100);

    dshot.set_motor_speeds(test_speeds[2], false);
    time.sleep(1500);

    dshot.set_motor_speeds(test_speeds[3], false);
    time.sleep(2000);
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
