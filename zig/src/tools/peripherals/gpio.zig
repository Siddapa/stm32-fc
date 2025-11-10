const std = @import("std");
const assert = std.debug.assert;

const Err = @import("../error.zig").Err;


const PERIPHERAL: u32 = 0x4000_0000;
const RCC: u32 = PERIPHERAL + 0x0002_1000;
const RCC_APB2ENR: u32 = RCC + 0x18;

const CRL_OFFSET: u32 = 0x00;
const CRH_OFFSET: u32 = 0x04;
const ODR_OFFSET: u32 = 0x0C;

const MODE_CNF_MASK: u32 = 0b1111;

pub const PORT = enum(u3) {
    A = 0,
    B = 1,
    C = 2,
    D = 3,
    E = 4,
    F = 5,
    G = 6,
};

const PORT_MAP = [7]u32{
    PERIPHERAL + 0x0001_0800, // Port A
    PERIPHERAL + 0x0001_0C00, //      B
    PERIPHERAL + 0x0001_1000, //      C
    PERIPHERAL + 0x0001_1400, //      D
    PERIPHERAL + 0x0001_1800, //      E
    PERIPHERAL + 0x0001_1C00, //      F
    PERIPHERAL + 0x0001_2000, //      G
};


pub fn port_setup(comptime port: PORT, comptime output: u32) void {
    comptime {
        assert(output_bounds(output));
    }

    const apb2_addr: *volatile u32 = @as(*volatile u32, @ptrFromInt(RCC_APB2ENR));

    const port_offset: u5 = @intCast(@intFromEnum(port) + 2);
    apb2_addr.* &= ~(@as(u32, 1) << port_offset);
    apb2_addr.* |= output << port_offset;
}

pub fn pin_setup(comptime port: PORT, comptime pin: u4, comptime cnf: u32, comptime mode: u32) void {
    comptime {
        assert(setting_bounds(cnf));
        assert(setting_bounds(mode));
    }

    const cr_addr: *volatile u32 = switch (pin) {
        0...7 => get_crl_addr(port),
        8...15 => get_crh_addr(port),
    };

    const pin_offset: u5 = @as(u5, @intCast(pin % 8)) * 4;
    cr_addr.* &= ~(MODE_CNF_MASK << pin_offset);
    cr_addr.* |= ((mode << pin_offset) | (cnf << (pin_offset + 2)));
}

pub fn set_pin(comptime port: PORT, comptime pin: u5, comptime output: u32) void {
    comptime {
        assert(output_bounds(output));
    }

    const odr_addr: *volatile u32 = get_odr_addr(port);

    odr_addr.* &= ~(@as(u32, 1) << @intCast(pin));
    odr_addr.* |= output << @intCast(pin);
}


fn output_bounds(comptime output: u32) bool {
    return (0 <= output and output <= 1);
}

fn setting_bounds(comptime setting: u32) bool {
    return (0b00 <= setting and setting <= 0b11);
}


fn get_crl_addr(port: PORT) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(PORT_MAP[@intFromEnum(port)] + CRL_OFFSET));
}

fn get_crh_addr(port: PORT) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(PORT_MAP[@intFromEnum(port)] + CRH_OFFSET));
}

fn get_odr_addr(port: PORT) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(PORT_MAP[@intFromEnum(port)] + ODR_OFFSET));
}
