const Err = @import("tools/error.zig");

const debug = @import("tools/debug.zig");
const gpio = @import("tools/gpio.zig");
const timer = @import("tools/timer.zig");

const ibus_decoder = @import("ibus/decoder.zig");

export fn _start() callconv(.c) void {
    // Terminal printing
    debug.setup() catch unreachable;

    // Setup for onboard LED
    gpio.port_setup(.C, 1) catch unreachable;
    gpio.pin_setup(.C, 13, 0b00, 0b11) catch unreachable;
    gpio.set_pin(.C, 13, 1) catch unreachable;
    
    // debug_test() catch unreachable;
}

// VECTOR TABLE CALLBACKS

export fn ibus_decode() callconv(.c) void {
    // ibus_decoder.decode();
}

fn debug_test() !void {
    var i: u8 = 0;
    while (true) {
        try debug.print("{d}\n", .{i});
        i += 1;
    }
}

fn blinky() !void {
    const wait_time = 1_000_000;

    while (true) {
        try gpio.set_pin(.C, 13, 0);
        timer.sleep(wait_time);
        try gpio.set_pin(.C, 13, 1);
        timer.sleep(wait_time);
    }
}
