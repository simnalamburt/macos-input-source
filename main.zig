const std = @import("std");
const carbon = @cImport({
    @cInclude("Carbon/Carbon.h");
});

pub fn helpThenExit() void {
    std.debug.print(
        \\tiny input source manager
        \\
        \\Usage: input-source <command>
        \\
        \\Commands:
        \\  list          List available input sources
        \\  set <source>  Change input source to <source>
        \\
        \\Examples:
        \\  input-source list
        \\  input-source set ABC
        \\
    , .{});
    std.os.exit(1);
}

pub fn main() void {
    const argv = std.os.argv;
    if (argv.len == 2 and std.mem.orderZ(u8, argv[1], "list") == .eq) {
        //const inputSource = carbon.TISCreateInputSourceList();
        //_ = inputSource;

        // TODO
        std.debug.print("List input sources\n", .{});
    } else if (argv.len == 3 and std.mem.orderZ(u8, argv[1], "set") == .eq) {
        // TODO
        std.debug.print("Set input source to {s}\n", .{argv[2]});
    } else {
        helpThenExit();
    }
}
