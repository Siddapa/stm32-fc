const debug = @import("../tools/debug.zig");

const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;

const RCC_AHBENR: u32 = RCC + 0x14;

const ISR_OFFSET: u32 =   0x000;
const IFCR_OFFSET: u32 =  0x004;
const CCR_OFFSET: u32 =   0x008;
const CNDTR_OFFSET: u32 = 0x00C;
const CPAR_OFFSET: u32 =  0x010;
const CMAR_OFFSET: u32 =  0x014;


pub const CONFIG = struct {
    dma: DMA,
    channel: CHANNEL,
    transfer_count: u16,
    peripheral_addr: u32,
    memory_addr: u32,
    priority: enum(u2) {
        LOW =       0b00,
        MEDIUM =    0b01,
        HIGH =      0b10,
        VERY_HIGH = 0b11
    },
    memory_size: enum(u2) { // In bytes
        ONE =  0b00,
        TWO =  0b01,
        FOUR = 0b10,
    },
    peripheral_size: enum(u2) { // In bytes
        ONE =  0b00,
        TWO =  0b01,
        FOUR = 0b10,
    },
    memory_increment: bool,
    circular_mode: bool,
    transfer_direction: enum(u1) {
        FROM_PERIPHERAL = 0,
        FROM_MEMORY     = 1
    },
    error_interrupt: bool,
    transfer_complete_interrupt: bool,
    enable: bool
};

const DMA_MAP = [2]u32 {
    PERIPHERAL + 0x0002_0000, // Controller 1
    PERIPHERAL + 0x0002_0400  //    ""      2
};


const DMA = enum(u1) {
    ONE = 0,
    TWO = 1
};

const CHANNEL = enum(u3) {
    ONE =   1,
    TWO =   2,
    THREE = 3,
    FOUR =  4,
    FIVE =  5,
    SIX =   6,
    SEVEN = 7
};



pub fn setup(comptime config: CONFIG) void {
    const rcc_ahbenr_reg: *volatile u32 = @ptrFromInt(RCC_AHBENR);
    const cndtr_reg: *volatile u32 = get_cndtr_reg(config.dma, config.channel);
    const cpar_reg: *volatile u32 = get_cpar_reg(config.dma, config.channel);
    const cmar_reg: *volatile u32 = get_cmar_reg(config.dma, config.channel);
    const ccr_reg: *volatile u32 = get_ccr_reg(config.dma, config.channel);

    rcc_ahbenr_reg.* &= ~(@as(u32, 0b1) << @intFromEnum(config.dma));
    rcc_ahbenr_reg.* |=  (@as(u32, @intFromBool(config.enable)) << @intFromEnum(config.dma));

    cndtr_reg.* &= ~(@as(u32, 0xFFFF));
    cndtr_reg.* |=  (@as(u32, config.transfer_count));

    cpar_reg.* &= ~(@as(u32, 0xFFFFFFFF));
    cpar_reg.* |=  (@as(u32, config.peripheral_addr));

    cmar_reg.* &= ~(@as(u32, 0xFFFFFFFF));
    cmar_reg.* |=  (@as(u32, config.memory_addr));

    ccr_reg.* &= ~((@as(u32, 0b11) << 12) |
                   (@as(u32, 0b11) << 10) |
                   (@as(u32, 0b11)  << 8) |
                   (@as(u32, 0b1)   << 7) |
                   (@as(u32, 0b1)   << 5) |
                   (@as(u32, 0b1)   << 4) |
                   (@as(u32, 0b1)   << 3) |
                   (@as(u32, 0b1)   << 1) |
                   (@as(u32, 0b1)   << 0));
    ccr_reg.* |=  ((@as(u32, @intFromEnum(config.priority))                   << 12) |
                   (@as(u32, @intFromEnum(config.memory_size))                << 10) |
                   (@as(u32, @intFromEnum(config.peripheral_size))             << 8) |
                   (@as(u32, @intFromBool(config.memory_increment))            << 7) |
                   (@as(u32, @intFromBool(config.circular_mode))               << 5) |
                   (@as(u32, @intFromEnum(config.transfer_direction))          << 4) |
                   (@as(u32, @intFromBool(config.error_interrupt))             << 3) |
                   (@as(u32, @intFromBool(config.transfer_complete_interrupt)) << 1) |
                   (@as(u32, @intFromBool(config.enable))                      << 0));
}

pub fn get_isr_reg(dma: DMA) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(DMA_MAP[@intFromEnum(dma)] + ISR_OFFSET));
}

pub fn get_ifcr_reg(dma: DMA) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(DMA_MAP[@intFromEnum(dma)] + IFCR_OFFSET));
}

pub fn get_ccr_reg(dma: DMA, channel: CHANNEL) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(DMA_MAP[@intFromEnum(dma)] + CCR_OFFSET + (20 * @as(u32, @intCast(@intFromEnum(channel) - 1)))));
}

// TODO Remove pub
pub fn get_cndtr_reg(dma: DMA, channel: CHANNEL) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(DMA_MAP[@intFromEnum(dma)] + CNDTR_OFFSET + (20 * @as(u32, @intCast(@intFromEnum(channel) - 1)))));
}

fn get_cpar_reg(dma: DMA, channel: CHANNEL) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(DMA_MAP[@intFromEnum(dma)] + CPAR_OFFSET + (20 * @as(u32, @intCast(@intFromEnum(channel) - 1)))));
}

fn get_cmar_reg(dma: DMA, channel: CHANNEL) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(DMA_MAP[@intFromEnum(dma)] + CMAR_OFFSET + (20 * @as(u32, @intCast(@intFromEnum(channel) - 1)))));
}

// Doesn't support DMA2
pub fn transfer_complete(channel: CHANNEL) bool {
    const check_bit: u5 = switch(channel) {
        .ONE => 1,
        .TWO => 5,
        .THREE => 9,
        .FOUR => 13,
        .FIVE => 17,
        .SIX => 21,
        .SEVEN => 25
    };

    return ((get_isr_reg(.ONE).* & (@as(u32, 0b1) << check_bit)) > 0);
}

// Doesn't support DMA2
pub fn clear_transfer_complete(channel: CHANNEL) void {
    const check_bit: u5 = switch(channel) {
        .ONE => 1,
        .TWO => 5,
        .THREE => 9,
        .FOUR => 13,
        .FIVE => 17,
        .SIX => 21,
        .SEVEN => 25
    };

    get_ifcr_reg(.ONE).* |= (@as(u32, 0b1) << check_bit);
}
