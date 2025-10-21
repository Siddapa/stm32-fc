const std = @import("std");
const expect = std.testing.expect;


const PERIPHERAL_BASE: u32 = 0x40000000;
const RCC_BASE: u32 = PERIPHERAL_BASE + 0x00021000;
const RCC_APB2: u32 = RCC_BASE + 0x18;

const CRL_OFFSET: u32 = 0x00;
const CRH_OFFSET: u32 = 0x04;
const ODR_OFFSET: u32 = 0x0C;

const MODE_CNF_MASK: u32 = 0b1111;

const PORT_MAP = [7]u32{
    PERIPHERAL_BASE + 0x00010800, // Port A
    PERIPHERAL_BASE + 0x00010C00, //      B
    PERIPHERAL_BASE + 0x00011000, //      C
    PERIPHERAL_BASE + 0x00011400, //      D
    PERIPHERAL_BASE + 0x00011800, //      E
    PERIPHERAL_BASE + 0x00011C00, //      F
    PERIPHERAL_BASE + 0x00012000, //      G
};


pub export fn port_setup(port: u32, able: u32) void {
    if (!(able == 0 or able == 1)) { unreachable; }

    const apb2_addr: *volatile u32 = @as(*volatile u32, @ptrFromInt(RCC_APB2));

    const port_offset: u5 = @intCast(port + 2);
    apb2_addr.* &= ~(@as(u32, 1) << port_offset);
    apb2_addr.* |= able << port_offset;
}

pub export fn pin_setup(port: u32, pin: u32, cnf: u32, mode: u32) void {
    if (!(0b00 <= cnf and cnf <= 0b11)) { unreachable; }
    if (!(0b00 <= mode and mode <= 0b11)) { unreachable; }

    const cr_addr: *volatile u32 = switch (pin) {
        0...7 => get_crl_addr(port),
        8...15 => get_crh_addr(port),
        else => unreachable
    };

    const pin_offset: u5 = @intCast((pin % 8) * 4);
    cr_addr.* &= ~(MODE_CNF_MASK << pin_offset);
    cr_addr.* |= ((mode << pin_offset) | (cnf << (pin_offset + 2)));
}

pub export fn set_pin(port: u32, pin: u32, output: u32) void {
    if (!(output == 0 or output == 1)) { unreachable; }
    if (!(0 <= pin and pin <= 15)) { unreachable; }

    const odr_addr: *volatile u32 = get_odr_addr(port);

    odr_addr.* &= ~(@as(u32, 1) << @intCast(pin));
    odr_addr.* |= output << @intCast(pin);
}

pub inline fn get_crl_addr(port: u32) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(PORT_MAP[port] + CRL_OFFSET));
}

pub inline fn get_crh_addr(port: u32) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(PORT_MAP[port] + CRH_OFFSET));
}

pub inline fn get_odr_addr(port: u32) *volatile u32 {
    return @as(*volatile u32, @ptrFromInt(PORT_MAP[port] + ODR_OFFSET));
}
