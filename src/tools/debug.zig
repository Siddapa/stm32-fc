const std = @import("std");
const usart = @import("peripherals/usart.zig");


// ANSI Escpae sequences to reset putty terminal
// Send spaces just to clear out shift registers and start fresh
const RESET_BUF = [_]u8{ 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x1B, 0x5B, 0x32, 0x4A, 0x1B, 0x5B, 0x48 };


pub fn setup() void {
    // Decoding from USART RX1 - A10
    // BRR is tuned to 24MHz, matching timer for DSHOT
    
    usart.setup(.ONE, .OUTPUT, .EIGHT, false, .EVEN_OR_NULL, .ONE, false, 0b11010000, true);
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


pub fn reset_terminal() void {
    for (RESET_BUF) |char| {
        while (usart.shifting_data(.ONE)) {}
        usart.get_data_reg(.ONE).* &= ~@as(u32, 0b1111_1111);
        usart.get_data_reg(.ONE).* |=  @as(u32, char);
    }
}
