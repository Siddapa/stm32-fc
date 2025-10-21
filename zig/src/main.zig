const std = @import("std");
const gpio = @import("gpio.zig");


var tick_counter: u32 = 0;


export fn _start() callconv(.c) void {
    gpio.port_setup(2, 1);
    gpio.pin_setup(2, 13, 0b00, 0b01);
    while (true) {
        gpio.set_pin(2, 13, 0);
        sleep(1000000);
        gpio.set_pin(2, 13, 1);
        sleep(1000000);
    }
}

fn sleep(time: u32) void {
    const count = @as(*volatile u32, @ptrCast(&tick_counter));
    while (count.* < time) { count.* += 1; }
    count.* = 0;
}
