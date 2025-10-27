var tick_counter: u32 = 0;


pub export fn sleep(time: u32) void {
    const count = @as(*volatile u32, @ptrCast(&tick_counter));
    while (count.* < time) { count.* += 1; }
    count.* = 0;
}
