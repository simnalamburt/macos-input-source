const std = @import("std");
const c = @cImport({
    @cInclude("Carbon/Carbon.h");
});

pub fn helpThenExit() void {
    std.debug.print(
        \\tiny input source manager
        \\
        \\Usage: input-source <command>
        \\
        \\Commands:
        \\  current       Show current input source
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

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = allocator.allocator();

    const argv = std.os.argv;
    if (argv.len == 2 and std.mem.orderZ(u8, argv[1], "current") == .eq) {
        const current = c.TISCopyCurrentKeyboardInputSource();

        const name: c.CFStringRef = @ptrCast(c.CFRetain(c.TISGetInputSourceProperty(current, c.kTISPropertyLocalizedName)));
        defer c.CFRelease(name);

        const length: c.CFIndex = c.CFStringGetLength(name);
        const maxSize: c.CFIndex = c.CFStringGetMaximumSizeForEncoding(length, c.kCFStringEncodingUTF8);
        const size_ulong: c_ulong = @bitCast(maxSize);
        const size: usize = @truncate(size_ulong);

        var buf = try alloc.alloc(u8, size);
        errdefer alloc.free(buf);

        const ret = c.CFStringGetCString(name, &buf[0], maxSize, c.kCFStringEncodingUTF8);
        if (ret != c.TRUE) {
            // TODO: error
            return error.Unreachable;
        }

        std.debug.print("{s}\n", .{buf});
    } else if (argv.len == 2 and std.mem.orderZ(u8, argv[1], "list") == .eq) {
        // TODO
        std.debug.print("List input sources\n", .{});
    } else if (argv.len == 3 and std.mem.orderZ(u8, argv[1], "set") == .eq) {
        // TODO
        std.debug.print("Set input source to {s}\n", .{argv[2]});
    } else {
        helpThenExit();
    }
}
