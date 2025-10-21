const std = @import("std");


pub fn build(b: *std.Build) void {
    // const BIN: []const u8 = "bin/";

    const elf = b.addExecutable(.{
        .name = "blink.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .thumb,
                .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m3},
                .os_tag = .freestanding,
                .abi = .eabihf,
            }),
            .optimize = .ReleaseSmall
        }),
    });
    elf.setLinkerScript(b.path("linkers/memory.ld"));

    const bin_cmd = b.addSystemCommand(&[_][]const u8{
        "/home/siddappa/apps/gcc-ane/bin/arm-none-eabi-objcopy",
        "-O",
        "binary",
        "zig-out/bin/blink.elf",
        "zig-out/bin/blink.bin"
    });
    const bin_step = b.step("bin", "Generate binary file to be flashed");
    bin_step.dependOn(&bin_cmd.step);

    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        "st-flash",
        "--reset",
        "write",
        "zig-out/bin/blink.bin",
        "0x08000000",
    });
    const flash_step = b.step("flash", "Flash and reset STM32 board");
    flash_step.dependOn(&flash_cmd.step);

    b.default_step.dependOn(&elf.step);
    b.installArtifact(elf);
}
