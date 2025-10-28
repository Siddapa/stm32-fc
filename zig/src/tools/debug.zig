const std = @import("std");
const usart = @import("../tools/usart.zig");


pub fn setup() !void {
    // Decoding from USART RX1 - A10
    // PCLK2 defaulted to 8 MH
    
    try usart.setup(.ONE, .OUTPUT, 0b0, 0b0, 0b00, 0b0000_0000_0100_0101);
}

pub fn print(comptime str: []const u8, args: anytype) !void {
    var buffer: [1024]u8 = undefined;
    const formatted_str = try std.fmt.bufPrint(&buffer, str, args);

    for (formatted_str) |char| {
        while (usart.shifting_data(.ONE)) {}
        usart.get_data_reg(.ONE).* &= ~@as(u32, 0b1111_1111);
        usart.get_data_reg(.ONE).* |=  @as(u32, char);
    }

    // Unnecessary for single-byte transmissions since
    // there's no large, connected frame
    // while (!usart.finished_transmission()) {}
}





