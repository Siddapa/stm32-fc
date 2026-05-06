const std = @import("std");

const gpio = @import("../peripherals/gpio.zig");
const spi = @import("../peripherals/spi.zig");
const dma = @import("../peripherals/dma.zig");


const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;

const RCC_APB2ENR: u32 = RCC + 0x18;
const RCC_APB1ENR: u32 = RCC + 0x1C;

const SR_OFFSET:   u32 = 0x00;
const DATA_OFFSET: u32 = 0x04;
const BRR_OFFSET:  u32 = 0x08;
const CR1_OFFSET:  u32 = 0x0C;
const CR2_OFFSET:  u32 = 0x10;
const CR3_OFFSET:  u32 = 0x14;


const IMU_DATA = struct {
    accel_x: u16,
    accel_y: u16,
    accel_z: u16,
    gyro_x: u16,
    gyro_y: u16,
    gyro_z: u16,
    temp: u16,
};


const IMU_DATA_SIZE: u32 = 14;
const BUFFER_SIZE: u32 = IMU_DATA_SIZE + 1;

// TX Buffer needs to have one extra byte for specifying starting address
const tx_buffer_addr: u32 = 0x2000_0040;
const tx_buffer: []volatile u8 = @as([*] volatile u8, @ptrFromInt(tx_buffer_addr))[0..BUFFER_SIZE];

const rx_buffer_addr: u32 = 0x2000_0050;
const rx_buffer: []volatile u8 = @as([*] volatile u8, @ptrFromInt(rx_buffer_addr))[0..BUFFER_SIZE];

const rx_data_addr: u32 = 0x2000_0060;
const rx_data: *volatile IMU_DATA = @ptrFromInt(rx_data_addr);


pub fn setup() void {
    @memset(tx_buffer, 0);      // Wipe with 0s
    tx_buffer[0] = 0b1010_1101; // 0x80 (Read from address) & 0x2D (Start of accel_x)

    spi.setup(.{
        .spi = .ONE,
        .bidir_mode = .TWO_UNIDIR,
        .bidir_output = .RECEIVE_ONLY_OR_NULL,
        .dff = .EIGHT_BIT,
        .frame_format = .MSB_FIRST,
        .baud_rate = .DIV16, // Lower baud rate keeps more stable frequency across jumper cables
        .authority = .MASTER,
        .dma = true,
        .enable = true
    });


    // Transmit
    dma.setup(.{
        .dma = .ONE,
        .channel = .THREE,
        .transfer_count = BUFFER_SIZE,
        .peripheral_addr = @intFromPtr(spi.get_dr_reg(.ONE)),
        .memory_addr = tx_buffer_addr,
        .priority = .HIGH,
        .memory_size = .ONE,
        .peripheral_size = .ONE,
        .memory_increment = true,
        .circular_mode = true,
        .transfer_direction = .FROM_MEMORY,
        .error_interrupt = false,
        .transfer_complete_interrupt = false,
        .enable = true
    });

    // Receive
    dma.setup(.{
        .dma = .ONE,
        .channel = .TWO,
        .transfer_count = BUFFER_SIZE,
        .peripheral_addr = @intFromPtr(spi.get_dr_reg(.ONE)),
        .memory_addr = rx_buffer_addr,
        .priority = .HIGH,
        .memory_size = .ONE,
        .peripheral_size = .ONE,
        .memory_increment = true,
        .circular_mode = true,
        .transfer_direction = .FROM_PERIPHERAL,
        .error_interrupt = false,
        .transfer_complete_interrupt = false,
        .enable = true
    });
}


pub fn decode() void {
    rx_data.accel_x = (@as(u16, rx_buffer[0]) << 8) &  rx_buffer[1];
    rx_data.accel_y = (@as(u16, rx_buffer[2]) << 8) &  rx_buffer[3];
    rx_data.accel_z = (@as(u16, rx_buffer[4]) << 8) &  rx_buffer[5];
    rx_data.gyro_x  = (@as(u16, rx_buffer[6]) << 8) &  rx_buffer[7];
    rx_data.gyro_y  = (@as(u16, rx_buffer[8]) << 8) &  rx_buffer[9];
    rx_data.gyro_z  = (@as(u16, rx_buffer[10]) << 8) & rx_buffer[11];
    rx_data.temp    = (@as(u16, rx_buffer[12]) << 8) & rx_buffer[13];
}

pub fn get_tx_buffer() []volatile u8 {
    return tx_buffer;
}

pub fn get_rx_buffer() []volatile u8 {
    return rx_buffer;
}

