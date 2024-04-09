const std = @import("std");

pub fn build(b: *std.Build) void {
    const aarch64 = b.addExecutable(.{
        .name = "input-source-aarch64",
        .root_source_file = .{ .path = "main.zig" },
        .target = std.zig.CrossTarget{ .cpu_arch = .aarch64, .os_tag = .macos },
        .optimize = .ReleaseSmall,
        .single_threaded = true,
    });

    const x86_64 = b.addExecutable(.{
        .name = "input-source-x86_64",
        .root_source_file = .{ .path = "main.zig" },
        .target = std.zig.CrossTarget{ .cpu_arch = .x86_64, .os_tag = .macos },
        .optimize = .ReleaseSmall,
        .single_threaded = true,
    });

    const lipo = b.addSystemCommand(&.{ "lipo", "-create", "-output" });
    const universal = lipo.addOutputFileArg("input-source");
    lipo.addArtifactArg(aarch64);
    lipo.addArtifactArg(x86_64);

    b.default_step.dependOn(&b.addInstallArtifact(aarch64, .{}).step);
    b.default_step.dependOn(&b.addInstallArtifact(x86_64, .{}).step);
    b.default_step.dependOn(&b.addInstallBinFile(universal, "input-source").step);
}
