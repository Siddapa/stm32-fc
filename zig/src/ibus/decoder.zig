const std = @import("std");

const usart = @import("../tools/peripherals/usart.zig");
const gpio = @import("../tools/peripherals/gpio.zig");
const dma = @import("../tools/peripherals/dma.zig");
const debug = @import("../tools/debug.zig");
const Err = @import("../tools/error.zig").Err;

const TRANSMIT_CHANNEL = enum (u4) {
    LEFT_Y  = 3,
    LEFT_X  = 4,
    RIGHT_X = 1,
    RIGHT_Y = 2,
    SWA     = 5,
    SWB     = 6,
};

const CHANNEL_DATA = struct {
    left_y:  u16,  // 1000-2000
    left_x:  u16,  // 1000-2000
    right_y: u16,  // 1000-2000
    right_x: u16,  // 1000-2000
    swa:     bool, // 1000|2000
    swb:     bool, // 1000|2000

    pub fn format(
        self: CHANNEL_DATA,
        writer: anytype
    ) !void {
        try writer.print("Left_Y: {d}, Left_X: {d}, Right_Y: {d}, Right_X: {d}, SWA: {}, SWB: {}", .{
            self.left_y,
            self.left_x,
            self.right_y,
            self.right_x,
            self.swa,
            self.swb
        });
    }
};

var transmit_data: CHANNEL_DATA = .{
    .left_y  = 0,
    .left_x  = 0,
    .right_y = 0,
    .right_x = 0,
    .swa     = false,
    .swb     = false,
};

const frame_buffer_addr: u32 = 0x2000_0030; // 0x20000_0000 - 0x20000_0020
// const transmit_data_addr: u32 = 0x2000_0030;
const frame_buffer: []volatile u8 = @as([*]volatile u8, @ptrFromInt(frame_buffer_addr))[0..32];
// const transmit_data: *volatile CHANNEL_DATA = @ptrFromInt(transmit_data_addr);


pub fn setup() void {
    dma.setup(.ONE, .SIX, 32, @intFromPtr(usart.get_data_reg(.TWO)), frame_buffer_addr, .HIGH, .ONE, .ONE, true, true, .FROM_PERIPHERAL, false, true, true);
    usart.setup(.TWO, .INPUT, .EIGHT, false, .EVEN_OR_NULL, .TWO, true, 0b0000_0000_0100_0101);
}

pub fn decode() !void {
    // TODO Finish checksum validation
    // Calculate checksum from non-checksum frame bytes
    // Relying on checksum to invalidate corrupted frames where invariants of channel types exist (e.g. <1000 or >2000)
    // const checksum: u16 = @as(u16, frame_buffer[30]) | (@as(u16, frame_buffer[31]) << 8);
    // var sum: u32 = 0; // TODO Find more efficient way to calculate checksum
    // for (frame_buffer[0..30]) |frame_byte| {
    //     sum += frame_byte;
    // }

    // if (checksum != sum) {
    //     debug.print("{} {}\n", .{checksum, sum});
    //     return Err.CorruptedIBUSFrame;
    // }

    transmit_data.left_y  =  decode_channel(.LEFT_Y);
    transmit_data.left_x  =  decode_channel(.LEFT_X);
    transmit_data.right_y =  decode_channel(.RIGHT_Y);
    transmit_data.right_x =  decode_channel(.RIGHT_X);
    transmit_data.swa     = (decode_channel(.SWA) == 2000);
    transmit_data.swb     = (decode_channel(.SWB) == 2000);
}

fn decode_channel(channel: TRANSMIT_CHANNEL) u16 {
    const first_byte: u4 = @intFromEnum(channel) * 2;
    return @as(u16, frame_buffer[first_byte]) |
          (@as(u16, frame_buffer[first_byte + 1]) << 8);
}

pub fn get_frame_buffer() []volatile const u8 {
    return frame_buffer;
}

pub fn get_transmit_data() CHANNEL_DATA {
    return transmit_data;
}
