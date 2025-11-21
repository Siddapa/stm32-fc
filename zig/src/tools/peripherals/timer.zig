const gpio = @import("gpio.zig");


const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;

const RCC_APB2ENR: *volatile u32 = @ptrFromInt(RCC + 0x18);

const CR1_OFFSET:       u32 = 0x00;
const CR2_OFFSET:       u32 = 0x04;
const DIER_OFFSET:      u32 = 0x0C;
const EGR_OFFSET:       u32 = 0x14;
const CCMR1_OFFSET:     u32 = 0x18;
const CCMR2_OFFSET:     u32 = 0x1C;
const CCER_OFFSET:      u32 = 0x20;
const CNT_OFFSET:       u32 = 0x24;
const PRESCALER_OFFSET: u32 = 0x28;
const ARR_OFFSET:       u32 = 0x2C;
const RCR_OFFSET:       u32 = 0x30;
const CCR1_OFFSET:      u32 = 0x34;
const CCR2_OFFSET:      u32 = 0x38;
const CCR3_OFFSET:      u32 = 0x3C;
const CCR4_OFFSET:      u32 = 0x40;
const BDTR_OFFSET:      u32 = 0x44;
const DCR_OFFSET:       u32 = 0x48;
const DMAR_OFFSET:      u32 = 0x4C;


const TIMER = enum(u1) {
    ONE = 0,
    EIGHT = 1
};

const TIMER_MAP = [2]u32{
    PERIPHERAL + 0x0001_2C00, // Timer 1
    PERIPHERAL + 0x0001_3400, //       8
};


pub fn setup(comptime timer: TIMER, comptime arr: u16) void {
    const rcc_en = switch (timer) {
        .ONE => 11,
        .EIGHT => 13
    };

    RCC_APB2ENR.* &= ~(@as(u32, 0b1) << rcc_en);
    RCC_APB2ENR.* |=  (@as(u32, 0b1) << rcc_en);

    switch (timer) {
        .ONE => {
            gpio.port_setup(.A, 1);
            gpio.pin_setup(.A, 8, 0b10, 0b01);
            gpio.pin_setup(.A, 9, 0b10, 0b01);
            gpio.pin_setup(.A, 10, 0b10, 0b01);
            gpio.pin_setup(.A, 11, 0b10, 0b01);
        },
        else => unreachable
    }

    get_ccmr1_reg(timer).* &= ~((@as(u32, 0b111) << 12) | // CC2 PWM 1 Mode
                                (@as(u32, 0b1)   << 11) | // CC2 Preload
                                (@as(u32, 0b11)  << 8)  | // CC2 Output
                                (@as(u32, 0b111) << 4)  | // CC1 PWM 1 Mode
                                (@as(u32, 0b1)   << 3)  | // CC1 Preload
                                (@as(u32, 0b11)  << 0));  // CC1 Output
    get_ccmr1_reg(timer).* |=  ((@as(u32, 0b110) << 12) |
                                (@as(u32, 0b1)   << 11) |
                                (@as(u32, 0b00)  << 8)  |
                                (@as(u32, 0b110) << 4)  |
                                (@as(u32, 0b1)   << 3)  |
                                (@as(u32, 0b00)  << 0));

    get_ccmr2_reg(timer).* &= ~((@as(u32, 0b111) << 12) | // CC4 PWM 1 Mode
                                (@as(u32, 0b1)   << 11) | // CC4 Preload
                                (@as(u32, 0b11)  << 8)  | // CC4 Output
                                (@as(u32, 0b111) << 4)  | // CC3 PWM 1 Mode
                                (@as(u32, 0b1)   << 3)  | // CC3 Preload
                                (@as(u32, 0b11)  << 0));  // CC3 Output
    get_ccmr2_reg(timer).* |=  ((@as(u32, 0b110) << 12) |
                                (@as(u32, 0b1)   << 11) |
                                (@as(u32, 0b00)  << 8)  |
                                (@as(u32, 0b110) << 4)  |
                                (@as(u32, 0b1)   << 3)  |
                                (@as(u32, 0b00)  << 0));    

    //                       Auto-Reload
    get_arr_reg(timer).* &= ~@as(u32, 0xFFFF);
    get_arr_reg(timer).* |=  @as(u32, arr);

    //                       Repitition Count
    get_rcr_reg(timer).* &= ~@as(u32, 0xFF);
    get_rcr_reg(timer).* |=  @as(u32, 0);

    get_dcr_reg(timer).* &= ~((@as(u32, 0b11111) << 8) | // # of DMA Transfers
                              (@as(u32, 0b11111) << 0)); // DMA Base Address
    get_dcr_reg(timer).* |=  ((@as(u32, 0b00011) << 8) |
                              (@as(u32, 0b01101) << 0));
}

pub fn enable(timer: TIMER) void {
    // Channel outputs
    get_ccer_reg(timer).* &= ~((@as(u32, 0b1) << 12) | // CC4 Enable
                               (@as(u32, 0b1) << 8)  | // CC3 Enable
                               (@as(u32, 0b1) << 4)  | // CC2 Enable
                               (@as(u32, 0b1) << 0));  // CC1 Enable
    get_ccer_reg(timer).* |=  ((@as(u32, 0b1) << 12) |
                               (@as(u32, 0b1) << 8)  |
                               (@as(u32, 0b1) << 4)  |
                               (@as(u32, 0b1) << 0)); 

    // Main output
    get_bdtr_reg(timer).* &= ~(@as(u32, 0b1) << 15);
    get_bdtr_reg(timer).* |=  (@as(u32, 0b1) << 15);

    // DMA Requests
    get_dier_reg(timer).* &= ~((@as(u32, 0b1) << 8));
    get_dier_reg(timer).* |=  ((@as(u32, 0b1) << 8));

    // Counter
    get_cr1_reg(timer).* &= ~((@as(u32, 0b1) << 0));
    get_cr1_reg(timer).* |=  ((@as(u32, 0b1) << 0));

    // Counter Value
    get_cnt_reg(timer).* &= ~(@as(u32, 0xFFFF));
    get_cnt_reg(timer).* |=  (@as(u32, 0x0000));
}

pub fn disable(timer: TIMER) void {
    // Channel outputs
    get_ccer_reg(timer).* &= ~((@as(u32, 0b1) << 12) | // CC4 Enable
                               (@as(u32, 0b1) << 8)  | // CC3 Enable
                               (@as(u32, 0b1) << 4)  | // CC2 Enable
                               (@as(u32, 0b1) << 0));  // CC1 Enable
    get_ccer_reg(timer).* |=  ((@as(u32, 0b0) << 12) |
                               (@as(u32, 0b0) << 8)  |
                               (@as(u32, 0b0) << 4)  |
                               (@as(u32, 0b0) << 0)); 

    // Counter
    get_cr1_reg(timer).* &= ~((@as(u32, 0b1) << 0));
    get_cr1_reg(timer).* |=  ((@as(u32, 0b0) << 0));

    // Main output
    get_bdtr_reg(timer).* &= ~(@as(u32, 0b1) << 15);
    get_bdtr_reg(timer).* |=  (@as(u32, 0b0) << 15);

    // DMA Requests
    get_dier_reg(timer).* &= ~((@as(u32, 0b1) << 8));
    get_dier_reg(timer).* |=  ((@as(u32, 0b0) << 8));

    // Counter Value
    get_cnt_reg(timer).* &= ~(@as(u32, 0xFFFF));
    get_cnt_reg(timer).* |=  (@as(u32, 0x0000));

    // Compare Counters
    get_ccr1_reg(timer).* = 0;
    get_ccr2_reg(timer).* = 0;
    get_ccr3_reg(timer).* = 0;
    get_ccr4_reg(timer).* = 0;

    // Reload empty compare counters
    get_egr_reg(timer).* &= ~(@as(u32, 0b1) << 1);
    get_egr_reg(timer).* |=  (@as(u32, 0b1) << 1);
}



fn get_cr1_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CR1_OFFSET));
}

fn get_cr2_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CR2_OFFSET));
}

fn get_dier_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + DIER_OFFSET));
}

fn get_egr_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + EGR_OFFSET));
}

fn get_ccmr1_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CCMR1_OFFSET));
}

fn get_ccmr2_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CCMR2_OFFSET));
}

fn get_ccer_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CCER_OFFSET));
}

fn get_cnt_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CNT_OFFSET));
}

fn get_prescaler_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + PRESCALER_OFFSET));
}

fn get_arr_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + ARR_OFFSET));
}

fn get_rcr_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + RCR_OFFSET));
}

fn get_ccr1_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CCR1_OFFSET));
}

fn get_ccr2_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CCR2_OFFSET));
}

fn get_ccr3_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CCR3_OFFSET));
}

fn get_ccr4_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + CCR4_OFFSET));
}

fn get_bdtr_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + BDTR_OFFSET));
}

fn get_dcr_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + DCR_OFFSET));
}

pub fn get_dmar_reg(timer: TIMER) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(TIMER_MAP[@intFromEnum(timer)] + DMAR_OFFSET));
}
