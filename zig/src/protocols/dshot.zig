const std = @import("std");

const Err = @import("../tools/error.zig");
const time = @import("../tools/time.zig");
const timer = @import("../tools/peripherals/timer.zig");
const gpio = @import("../tools/peripherals/gpio.zig");
const dma = @import("../tools/peripherals/dma.zig");
const debug = @import("../tools/debug.zig");

// TODO Bit time might be completely arbitrary and not tied to a specific DSHOT version
// Assming clock is 100Mhz we can just use a thousandth of DSHOT150's
// bit_time that's in microseconds. We have no clock that runs that 
// fast though so we'll have to use an approximation from our incoming 8MHz clock:
// 6.67/0.125 = 53.3 ~= 52 + (1.333)
const BIT_TIME: u16 = 104;
const HIGH_TIME: u16 = 80;
const LOW_TIME: u16 = 40;

const ENABLE_TELEMETRY: u16 = 0;

const TELEMETRY_OFFSET: u32 = 44;
const CRC_OFFSET: u32 = 48;

pub const BUF_SIDE = enum(u2) {
    LEFT,
    RIGHT,
    BOTH,
    AUTO
};

const MOTOR_COUNT: u32 = 4;
const BUF_SIZE: u32 = 64;
const motors_addr: u32 = 0x2000_0030;
var motors_buffer: []volatile u16 = create_slice(motors_addr, BUF_SIZE);

pub fn setup() void {
    // Setting up for DSHOT150 which runs at around 9KHz
    // Counting up to 667 to match bit time in microseconds

    timer.setup(.ONE, BIT_TIME);
    timer.disable(.ONE);

    dma.setup(.ONE, .FIVE, BUF_SIZE, @intFromPtr(timer.get_dmar_reg(.ONE)), motors_addr, .MEDIUM, .TWO, .TWO, true, true, .FROM_MEMORY, false, false, true);
    dma.clear_transfer_complete(.FIVE);
}

// Pulsing is a blocking operation since a certain number of frames
// need to be precisely sent which requires full availability of cpu
// time for poll-based checking
// Only use in operations other completion of other events aren't necessary
pub fn pulse_frames(comptime CNT: u32, motor_vals: [CNT][MOTOR_COUNT]u16) void {
    timer.disable(.ONE);

    // Disable DMA
    dma.get_ccr_reg(.ONE, .FIVE).* &= ~(@as(u32, 0b1) << 0);
    dma.get_ccr_reg(.ONE, .FIVE).* |=  (@as(u32, 0b0) << 0);

    // Load DMA with exact number of frames desired
    dma.get_cndtr_reg(.ONE, .FIVE).* &= ~(@as(u32, 0xFFFF));
    dma.get_cndtr_reg(.ONE, .FIVE).* |=  (@as(u32, BUF_SIZE*(CNT+1)));

    // Disable circular mode
    dma.get_ccr_reg(.ONE, .FIVE).* &= ~(@as(u32, 0b1) << 5);
    dma.get_ccr_reg(.ONE, .FIVE).* |=  (@as(u32, 0b0) << 5);

    // Enable DMA
    dma.get_ccr_reg(.ONE, .FIVE).* &= ~(@as(u32, 0b1) << 0);
    dma.get_ccr_reg(.ONE, .FIVE).* |=  (@as(u32, 0b1) << 0);

    // Buffered slice to match count of pulse_frames
    // Pulsed transmission needs extra frame of 0s
    var scaled_buffer: []volatile u16 = create_slice(motors_addr, BUF_SIZE*(CNT + 1));
    for (0..CNT) |i| {
        const start_bound: u32 = (i*BUF_SIZE);
        const end_bound: u32 = ((i+1)*BUF_SIZE);
        write_frame(scaled_buffer[start_bound..end_bound], motor_vals[i]);
    }
    @memset(scaled_buffer[(CNT*BUF_SIZE)..((CNT+1)*BUF_SIZE)], 0);

    timer.enable(.ONE);
    while (!dma.transfer_complete(.FIVE)) {}
    timer.disable(.ONE);
    dma.clear_transfer_complete(.FIVE);
}


// Takes a speed value between 1-2000
// Will write to DMA buffer during a transmission which will corrupt
// the active buffer
pub fn set_motor_speeds(motor_speeds: [MOTOR_COUNT]u16, offset: bool) void {
    // Disable DMA
    dma.get_ccr_reg(.ONE, .FIVE).* &= ~(@as(u32, 0b1) << 0);
    dma.get_ccr_reg(.ONE, .FIVE).* |=  (@as(u32, 0b0) << 0);

    // Reset transmit counter to BUF_SIZE for clean start
    dma.get_cndtr_reg(.ONE, .FIVE).* &= ~(@as(u32, 0xFFFF));
    dma.get_cndtr_reg(.ONE, .FIVE).* |=  (@as(u32, BUF_SIZE));

    // Enable circular mode
    dma.get_ccr_reg(.ONE, .FIVE).* &= ~(@as(u32, 0b1) << 5);
    dma.get_ccr_reg(.ONE, .FIVE).* |=  (@as(u32, 0b1) << 5);

    // Enable DMA
    dma.get_ccr_reg(.ONE, .FIVE).* &= ~(@as(u32, 0b1) << 0);
    dma.get_ccr_reg(.ONE, .FIVE).* |=  (@as(u32, 0b1) << 0);

    if (offset) {
        write_frame(motors_buffer, .{
            motor_speeds[0] + 47,
            motor_speeds[1] + 47,
            motor_speeds[2] + 47,
            motor_speeds[3] + 47
        });
    } else {
        write_frame(motors_buffer, motor_speeds);
    }

    timer.enable(.ONE);
}

// Will write to DMA buffer during a transmission which will corrupt
// the active buffer
pub fn empty_buffer() void {
    @memset(motors_buffer, 0);
}


// Updates DMA buffer to send DSHOT commands
fn write_frame(buf: []volatile u16, motor_vals: [MOTOR_COUNT]u16) void {
    for (motor_vals, 0..) |motor_val, motor_num| {
        switch (motor_val) {
            0 =>        return, // Disarm
            1...47 =>    return, // Special commands
            48...2047 => {
                // Loop through 11 bit motor_speed and 4 bit crc to convert
                // each set bit into a BIT_TIME in DMA buffer
                
                for (0..11) |speed_i| {
                    const bit_val: u16 = motor_val & (@as(u16, 0x1) << @intCast(10 - speed_i));
                    const buffer_i: u32 = (speed_i * 4) + motor_num;
                    buf[buffer_i] = switch (bit_val) {
                        0 => LOW_TIME,
                        else => HIGH_TIME,
                    };
                }

                buf[TELEMETRY_OFFSET + motor_num] = switch(ENABLE_TELEMETRY) {
                    0 => LOW_TIME,
                    1 => HIGH_TIME,
                    else => unreachable
                };

                // Reconstruct crc sum separetly rather than indexing buffer
                const sum: u16 = (motor_val << ENABLE_TELEMETRY) | ENABLE_TELEMETRY;
                const crc: u16 = (sum ^ (sum >> 4) ^ (sum >> 8)) & 0xF;
                for (0..4) |crc_i| {
                    const bit_val: u16 = crc & (@as(u16, 0x1) << @intCast(crc_i));
                    const buffer_i: u32 = CRC_OFFSET + (crc_i * 4) + motor_num;
                    buf[buffer_i] = switch (bit_val) {
                        0 => LOW_TIME,
                        else => HIGH_TIME,
                    };
                }
            },
            else => unreachable
        }
    }
}


pub fn display_motors_buffer(title: []const u8, buf: []const volatile u16) void {
    var motor1: u16 = 0;
    var motor2: u16 = 0;
    var motor3: u16 = 0;
    var motor4: u16 = 0;

    var motor1_telemetry: u16 = 0;
    var motor2_telemetry: u16 = 0;
    var motor3_telemetry: u16 = 0;
    var motor4_telemetry: u16 = 0;

    var motor1_crc: u16 = 0;
    var motor2_crc: u16 = 0;
    var motor3_crc: u16 = 0;
    var motor4_crc: u16 = 0;

    for (buf, 0..) |bit_time, i| {
        if (bit_time == LOW_TIME) continue;

        const bit_time_sized: u16 = @intCast(1);
        const bit_type: u4 = @intCast(@divTrunc(i, 4));
        const motor_type: u2 = @intCast(i % 4);
        
        switch (motor_type) {
            0 => switch (bit_type) {
                0...10 => motor1 |= bit_time_sized << (10 - bit_type),
                11 => motor1_telemetry = 1,
                12...15 => motor1_crc |= bit_time_sized << (15 - bit_type),
            },
            1 => switch (bit_type) {
                0...10 => motor2 |= bit_time_sized << (10 - bit_type),
                11 => motor2_telemetry = 1,
                12...15 => motor2_crc |= bit_time_sized << (15 - bit_type),
            },
            2 => switch (bit_type) {
                0...10 => motor3 |= bit_time_sized << (10 - bit_type),
                11 => motor3_telemetry = 1,
                12...15 => motor3_crc |= bit_time_sized << (15 - bit_type),
            },
            3 => switch (bit_type) {
                0...10 => motor4 |= bit_time_sized << (10 - bit_type),
                11 => motor4_telemetry = 1,
                12...15 => motor4_crc |= bit_time_sized << (15 - bit_type),
            }
        }
    }

    // Bugging out when doing it neatly for some stupid reason
    debug.print(
        // Column headers are mismatched to account for string formatting
        \\ {s}:
        \\          Command               T   Checksum
        \\ Motor 1: {:4} - 0b{b:011}, {:1}, {:2} - {b:04} 
        \\ Motor 2: {:4} - 0b{b:011}, {:1}, {:2} - {b:04}
        \\ Motor 3: {:4} - 0b{b:011}, {:1}, {:2} - {b:04}
        \\ Motor 4: {:4} - 0b{b:011}, {:1}, {:2} - {b:04}
    , .{
        title,
        motor1, motor1, motor1_telemetry, motor1_crc, motor1_crc,
        motor2, motor2, motor2_telemetry, motor2_crc, motor2_crc,
        motor3, motor3, motor3_telemetry, motor3_crc, motor3_crc,
        motor4, motor4, motor4_telemetry, motor4_crc, motor4_crc,
    });
    debug.print("\n", .{});
}

fn create_slice(comptime addr: u32, comptime size: u32) []volatile u16 {
    return @as([*]volatile u16, @ptrFromInt(addr))[0..size];
}


// Interrupt to disable timer when command is finished being transmitted
// pub export fn DMA1_Channel5_IRQHandler() callconv(.c) void {
//     // TODO Clear interrupt flag in DMA IFCR
//     timer.disable(.ONE);
//     gpio.set_pin(.C, 13, 0);
// }
