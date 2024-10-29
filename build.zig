const std = @import("std");

pub fn build(b: *std.Build) void {
    const is_universal = b.option(bool, "universal-binary", "Whether to build a Universal Binary") orelse false;

    if (!is_universal) {
        const exe = b.addExecutable(.{
            .name = "input-source",
            .root_source_file = b.path("main.zig"),
            .target = b.standardTargetOptions(.{}),
            .optimize = .ReleaseSmall,
            .single_threaded = true,
        });
        exe.linkFramework("Carbon");

        b.installArtifact(exe);
        return;
    }

    const aarch64 = b.addExecutable(.{
        .name = "input-source-aarch64",
        .root_source_file = b.path("main.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .aarch64,
        }),
        .optimize = .ReleaseSmall,
        .single_threaded = true,
    });
    aarch64.linkFramework("Carbon");

    const x86_64 = b.addExecutable(.{
        .name = "input-source-x86_64",
        .root_source_file = b.path("main.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
        }),
        .optimize = .ReleaseSmall,
        .single_threaded = true,
    });
    x86_64.linkFramework("Carbon");

    const lipo = b.addSystemCommand(&.{ "lipo", "-create", "-output" });
    const universal = lipo.addOutputFileArg("input-source");
    lipo.addArtifactArg(aarch64);
    lipo.addArtifactArg(x86_64);

    b.default_step.dependOn(&b.addInstallBinFile(universal, "input-source").step);
}
