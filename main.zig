const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("Carbon/Carbon.h");
});

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const argv = std.os.argv;
    if (argv.len == 2 and strEqZ(argv[1], "current")) {
        const source = c.TISCopyCurrentKeyboardInputSource();
        defer c.CFRelease(source);

        try printID(allocator, source);
    } else if (argv.len == 2 and strEqZ(argv[1], "list")) {
        const list = try querySources(.{
            c.kTISPropertyInputSourceCategory,        c.kTISCategoryKeyboardInputSource,
            c.kTISPropertyInputSourceIsSelectCapable, c.kCFBooleanTrue,
            c.kTISPropertyInputSourceIsEnabled,       c.kCFBooleanTrue,
        }) orelse return;
        defer c.CFRelease(list);

        for (0..len(list)) |i| {
            const source = getRetained(list, i);
            defer c.CFRelease(source);

            try printID(allocator, source);
        }
    } else if (argv.len == 3 and strEqZ(argv[1], "set")) {
        const id = try fromStringCreate(argv[2]);
        defer c.CFRelease(id);

        const list = try querySources(.{
            c.kTISPropertyInputSourceID, id,
        }) orelse {
            std.debug.print("input-source: No such input source exists.\n", .{});
            std.posix.exit(1);
        };
        defer c.CFRelease(list);

        if (len(list) != 1) {
            std.debug.print("input-source: Multiple input sources found with the given ID.\n", .{});
            std.posix.exit(1);
        }

        const source = getRetained(list, 0) orelse return error.Unreachable; // TODO: error
        defer c.CFRelease(source);

        const status = c.TISSelectInputSource(source);
        if (status != 0) {
            std.debug.print("input-source: Could not change input language (OSStatus = {})", .{status});
            std.posix.exit(1);
        }
    } else {
        showHelpThenExit();
    }
}

fn showHelpThenExit() noreturn {
    std.debug.print(
        \\tiny input source manager
        \\
        \\Usage: input-source <command>
        \\
        \\Commands:
        \\  current       Show current input source
        \\  list          List available input sources
        \\  set <Source>  Change input source to <source>
        \\
        \\Examples:
        \\  input-source list
        \\  input-source set com.apple.keylayout.ABC
        \\
    , .{});
    std.posix.exit(1);
}

inline fn toUsize(long: c_long) usize {
    return @truncate(@as(c_ulong, @bitCast(long)));
}

inline fn fromUsize(size: usize) c.CFIndex {
    return @bitCast(@as(c_ulong, size));
}

inline fn strEqZ(lhs: [*:0]const u8, rhs: [*:0]const u8) bool {
    return std.mem.orderZ(u8, lhs, rhs) == .eq;
}

fn toStringAlloc(allocator: Allocator, string: c.CFStringRef) Allocator.Error![]const u8 {
    const length: c.CFIndex = c.CFStringGetLength(string);
    const maxSize: c.CFIndex = c.CFStringGetMaximumSizeForEncoding(length, c.kCFStringEncodingUTF8);
    const size = toUsize(maxSize);

    var buf = try allocator.alloc(u8, size);

    if (c.CFStringGetCString(string, &buf[0], maxSize, c.kCFStringEncodingUTF8) != c.TRUE) {
        // TODO: error
        return error.OutOfMemory;
    }

    return buf;
}

fn fromStringCreate(string: [*:0]const u8) !c.CFStringRef {
    return c.CFStringCreateWithBytes(@ptrFromInt(0), string, fromUsize(std.mem.len(string)), c.kCFStringEncodingUTF8, c.FALSE) orelse return error.Unreachable; // TODO: error
}

fn printID(allocator: Allocator, source: c.TISInputSourceRef) Allocator.Error!void {
    const id: c.CFStringRef = @ptrCast(c.CFRetain(c.TISGetInputSourceProperty(source, c.kTISPropertyInputSourceID)));
    defer c.CFRelease(id);

    const buf = try toStringAlloc(allocator, id);
    errdefer allocator.free(buf);

    std.debug.print("{s}\n", .{buf});
}

fn querySources(args: anytype) !c.CFArrayRef {
    comptime std.debug.assert(args.len % 2 == 0);

    const filter = c.CFDictionaryCreateMutable(@ptrFromInt(0), 0, @ptrFromInt(0), @ptrFromInt(0)) orelse return error.Unreachable; // TODO: error
    defer c.CFRelease(filter);

    inline for (0..args.len / 2) |i| {
        c.CFDictionarySetValue(filter, args[i * 2], args[i * 2 + 1]);
    }

    return c.TISCreateInputSourceList(filter, c.FALSE);
}

inline fn len(list: c.CFArrayRef) usize {
    return toUsize(c.CFArrayGetCount(list));
}

inline fn getRetained(list: c.CFArrayRef, index: usize) c.TISInputSourceRef {
    return @constCast(@ptrCast(c.CFRetain(c.CFArrayGetValueAtIndex(list, fromUsize(index)))));
}
