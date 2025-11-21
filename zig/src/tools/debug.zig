const std = @import("std");
const usart = @import("peripherals/usart.zig");



pub fn setup() void {
    // Decoding from USART RX1 - A10
    // PCLK2 defaulted to 8 MH
    
    usart.setup(.ONE, .OUTPUT, .EIGHT, false, .EVEN_OR_NULL, .ONE, false, 0b0000_0000_0100_0101, true);
}

pub fn print(comptime str: []const u8, args: anytype) void {
    var format_buffer: [2028]u8 = undefined;
    const formatted_str = std.fmt.bufPrint(&format_buffer, str, args) catch unreachable;

    for (formatted_str) |char| {
        while (usart.shifting_data(.ONE)) {}
        usart.get_data_reg(.ONE).* &= ~@as(u32, 0b1111_1111);
        usart.get_data_reg(.ONE).* |=  @as(u32, char);
    }

    // Unnecessary for single-byte transmissions since
    // there's no large, connected frame
    // while (!usart.finished_transmission()) {}
}





