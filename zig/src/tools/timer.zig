const debug = @import("debug.zig");
const Err = @import("error.zig").Err;


var tick_counter: u32 = 0;


pub fn sleep(time: u32) void {
    const count = @as(*volatile u32, @ptrCast(&tick_counter));
    while (count.* < time) { count.* += 1; }
    count.* = 0;
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
