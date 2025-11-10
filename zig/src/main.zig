const debug = @import("tools/debug.zig");
const timer = @import("tools/timer.zig");
const Err = @import("tools/error.zig").Err;
const gpio = @import("tools/peripherals/gpio.zig");
const dma = @import("tools/peripherals/dma.zig");
const usart = @import("tools/peripherals/usart.zig");

const ibus_decoder = @import("ibus/decoder.zig");

comptime {
    @import("startup.zig").exportStartSymbol();
    @import("vector_table.zig").exportVectorTable();
}

export fn main() callconv(.c) void {
    // Terminal printing
    debug.setup();

    debug.print("Setup onboard LED\n", .{});
    gpio.port_setup(.C, 1);
    gpio.pin_setup(.C, 13, 0b00, 0b11);
    gpio.set_pin(.C, 13, 1);


    debug.print("Setup DMA for iBUS Receiver\n", .{});
    ibus_decoder.setup();
    
    // debug_test();
    timer.loop(ibus_test, 50000, true);
}

fn ibus_test() void {
    ibus_decoder.decode() catch debug.print("Corrupted iBUS frame!\n", .{});

    debug.print("{f}\n", .{ ibus_decoder.get_transmit_data() });
    debug.print("\n", .{});
}

fn debug_test() void {
    var i: u8 = 0;
    while (true) {
        debug.print("{d}\n", .{i});
        timer.sleep(100_000);
        i += 1;
    }
}

fn blinky() void {
    const wait_time = 1_000_000;

    while (true) {
        try gpio.set_pin(.C, 13, 0);
        timer.sleep(wait_time);
        try gpio.set_pin(.C, 13, 1);
        timer.sleep(wait_time);
    }
}
