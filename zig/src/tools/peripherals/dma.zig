const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;

const RCC_AHBENR: u32 = RCC + 0x14;

const ISR_OFFSET: u32 =   0x000;
const IFCR_OFFSET: u32 =  0x004;
const CCR_OFFSET: u32 =   0x008;
const CNDTR_OFFSET: u32 = 0x00C;
const CPAR_OFFSET: u32 =  0x010;
const CMAR_OFFSET: u32 =  0x014;


const DMA = enum(u1) {
    ONE = 0,
    TWO = 1
};

const PRIORITY = enum(u2) {
    LOW =       0b00,
    MEDIUM =    0b01,
    HIGH =      0b10,
    VERY_HIGH = 0b11
};

const DATA_SIZE = enum(u2) { // In bytes
    ONE =  0b00,
    TWO =  0b01,
    FOUR = 0b10,
};

const TRANSFER_DIRECTION = enum(u1) {
    FROM_PERIPHERAL = 0,
    FROM_MEMORY     = 1
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

const DMA_MAP = [2]u32 {
    PERIPHERAL + 0x0002_0000, // Controller 1
    PERIPHERAL + 0x0002_0400  //            2
};


pub fn setup(
    comptime dma: DMA,
    comptime channel: CHANNEL,
    comptime transfer_count: u16,
    comptime peripheral_addr: u32,
    comptime memory_addr: u32,
    comptime priority: PRIORITY,
    comptime memory_size: DATA_SIZE,
    comptime peripheral_size: DATA_SIZE,
    comptime memory_increment: bool,
    comptime circular_mode: bool,
    comptime transfer_direction: TRANSFER_DIRECTION,
    comptime error_interrupt: bool,
    comptime transfer_complete_interrupt: bool,
    comptime enable: bool
) void {
    const rcc_ahbenr_reg: *volatile u32 = @ptrFromInt(RCC_AHBENR);
    const cndtr_reg: *volatile u32 = get_cndtr_reg(dma, channel);
    const cpar_reg: *volatile u32 = get_cpar_reg(dma, channel);
    const cmar_reg: *volatile u32 = get_cmar_reg(dma, channel);
    const ccr_reg: *volatile u32 = get_ccr_reg(dma, channel);

    rcc_ahbenr_reg.* &= ~(@as(u32, 0b1) << @intFromEnum(dma));
    rcc_ahbenr_reg.* |=  (@as(u32, @intFromBool(enable)) << @intFromEnum(dma));

    cndtr_reg.* &= ~(@as(u32, 0xFFFF));
    cndtr_reg.* |=  (@as(u32, transfer_count));

    cpar_reg.* &= ~(@as(u32, 0xFFFFFFFF));
    cpar_reg.* |=  (@as(u32, peripheral_addr));

    cmar_reg.* &= ~(@as(u32, 0xFFFFFFFF));
    cmar_reg.* |=  (@as(u32, memory_addr));

    ccr_reg.* &= ~((@as(u32, 0b11) << 12) |
                   (@as(u32, 0b11) << 10) |
                   (@as(u32, 0b11)  << 8) |
                   (@as(u32, 0b1)   << 7) |
                   (@as(u32, 0b1)   << 5) |
                   (@as(u32, 0b1)   << 4) |
                   (@as(u32, 0b1)   << 3) |
                   (@as(u32, 0b1)   << 1) |
                   (@as(u32, 0b1)   << 0));
    ccr_reg.* |=  ((@as(u32, @intFromEnum(priority))                   << 12) |
                   (@as(u32, @intFromEnum(memory_size))                << 10) |
                   (@as(u32, @intFromEnum(peripheral_size))             << 8) |
                   (@as(u32, @intFromBool(memory_increment))            << 7) |
                   (@as(u32, @intFromBool(circular_mode))               << 5) |
                   (@as(u32, @intFromEnum(transfer_direction))          << 4) |
                   (@as(u32, @intFromBool(error_interrupt))             << 3) |
                   (@as(u32, @intFromBool(transfer_complete_interrupt)) << 1) |
                   (@as(u32, @intFromBool(enable))                      << 0));
}


fn get_ccr_reg(dma: DMA, channel: CHANNEL) *volatile u32 {
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
