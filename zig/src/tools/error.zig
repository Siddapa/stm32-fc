const gpio = @import("peripherals/gpio.zig");

// TODO Log errors
// TODO More descriptive display of errors using bit-buffer of LEDs

pub const Err = error {
    ValueOutOfBounds,
    CorruptedIBUSFrame,
};


pub fn display_err() void {
    // Assumes that GPIO can't fail
    gpio.port_setup(2, 1) catch unreachable;
    gpio.pin_setup(2, 13, 0b00, 0b11) catch unreachable;
    gpio.set_pin(2, 13, 1) catch unreachable;
}
