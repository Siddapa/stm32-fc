const Err = @import("tools/error.zig");

const debug = @import("tools/debug.zig");
const gpio = @import("tools/gpio.zig");
const timer = @import("tools/timer.zig");

const ibus_decoder = @import("ibus/decoder.zig");

export fn _start() callconv(.c) void {
    // ibus_decoder.setup() catch unreachable;
    debug_test() catch unreachable;
}

// VECTOR TABLE CALLBACKS

export fn ibus_decode() callconv(.c) void {
    // ibus_decoder.decode();
}

fn debug_test() !void {
    try debug.setup();

    try gpio.port_setup(.C, 1);
    try gpio.pin_setup(.C, 13, 0b00, 0b11);
    try gpio.set_pin(.C, 13, 1);

    // var i: u8 = 0;
    // while (true) {
    //     try debug.print("{d}\n", .{i});
    //     i += 1;
    // }
}

fn blinky() !void {
    const port1: gpio.PORTS = .C;
    const pin1: u32 = 13;
    const wait_time = 1_000_000;

    try gpio.port_setup(port1, 1);
    try gpio.pin_setup(port1, pin1, 0b00, 0b11);

    while (true) {
        try gpio.set_pin(port1, pin1, 0);
        timer.sleep(wait_time);
        try gpio.set_pin(port1, pin1, 1);
        timer.sleep(wait_time);
    }
}
