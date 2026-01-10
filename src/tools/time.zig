const debug = @import("debug.zig");
const Err = @import("error.zig").Err;


var tick_counter: *volatile u32 = @ptrFromInt(0x2000_0500);


pub fn sleep(time: u32) void {
    while (tick_counter.* < time) { tick_counter.* += 1; }
    tick_counter.* = 0;
}

pub fn loop(func: fn() void, idle_time: u32, log_index: bool) void {
    var i: u32 = 0;
    while (true) : (i += 1) {
        if (i % idle_time == 0) {
            if (log_index) {
                debug.print("Index: {}\n", .{i});
            }

            func();
        }
    }
}
