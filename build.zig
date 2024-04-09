const std = @import("std");

pub fn build(b: *std.Build) void {
    const aarch64 = b.addExecutable(.{
        .name = "input-source-aarch64",
        .root_source_file = .{ .path = "main.zig" },
        .target = std.zig.CrossTarget{ .cpu_arch = .aarch64, .os_tag = .macos },
        // TODO: standardOptimizeOption
    });

    const x86_64 = b.addExecutable(.{
        .name = "input-source-x86_64",
        .root_source_file = .{ .path = "main.zig" },
        .target = std.zig.CrossTarget{ .cpu_arch = .x86_64, .os_tag = .macos },
        // TODO: standardOptimizeOption
    });

    const lipo = b.addSystemCommand(&.{ "lipo", "-create" });
    lipo.addArtifactArg(aarch64);
    lipo.addArtifactArg(x86_64);
    lipo.addArg("-output");
    const universal = lipo.addOutputFileArg("input-source");

    const install = b.addInstallBinFile(universal, "input-source");
    b.default_step.dependOn(&install.step);
}
