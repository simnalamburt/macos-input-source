const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("Carbon/Carbon.h");
});

const Input = union(enum) {
    current: struct {
        localized_name: bool,
    },
    list: struct {
        localized_name: bool,
    },
    set: struct {
        localized_name: bool,
        input_source: [*:0]const u8,
    },
};

pub fn main() !void {
    const input = parseArgv(std.os.argv);

    // Initialize the GeneralPurposeAllocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    switch (input) {
        .current => |*opt| {
            const source = c.TISCopyCurrentKeyboardInputSource();
            defer c.CFRelease(source);

            try printInputSource(allocator, source, opt.localized_name);
        },
        .list => |*opt| {
            const list = try querySources(.{
                c.kTISPropertyInputSourceCategory,        c.kTISCategoryKeyboardInputSource,
                c.kTISPropertyInputSourceIsSelectCapable, c.kCFBooleanTrue,
                c.kTISPropertyInputSourceIsEnabled,       c.kCFBooleanTrue,
            }) orelse return;
            defer c.CFRelease(list);

            for (0..len(list)) |i| {
                const source = getRetained(list, i);
                defer c.CFRelease(source);

                try printInputSource(allocator, source, opt.localized_name);
            }
        },
        .set => |*opt| {
            const id = try fromStringCreate(opt.input_source);
            defer c.CFRelease(id);

            const list = try querySources(.{
                if (opt.localized_name) c.kTISPropertyLocalizedName else c.kTISPropertyInputSourceID, id,
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
        },
    }
}

fn parseArgv(args: [][*:0]const u8) Input {
    if (args.len < 2) return showHelpThenExit();

    return if (strEqZ(args[1], "current"))
        parseCurrent(args[2..])
    else if (strEqZ(args[1], "list"))
        parseList(args[2..])
    else if (strEqZ(args[1], "set"))
        parseSet(args[2..])
    else
        showHelpThenExit();
}

fn parseCurrent(args: [][*:0]const u8) Input {
    return if (args.len == 0)
        Input{ .current = .{ .localized_name = false } }
    else if (args.len == 1 and strEqZ(args[0], "--localized-name"))
        Input{ .current = .{ .localized_name = true } }
    else
        showHelpThenExit();
}

fn parseList(args: [][*:0]const u8) Input {
    return if (args.len == 0)
        Input{ .list = .{ .localized_name = false } }
    else if (args.len == 1 and strEqZ(args[0], "--localized-name"))
        Input{ .list = .{ .localized_name = true } }
    else
        showHelpThenExit();
}

fn parseSet(args: [][*:0]const u8) Input {
    if (args.len < 1) return showHelpThenExit();

    if (strEqZ(args[0], "--localized-name")) {
        if (args.len != 2) return showHelpThenExit();

        return Input{ .set = .{ .localized_name = true, .input_source = args[1] } };
    } else {
        if (args.len != 1) return showHelpThenExit();

        return Input{ .set = .{ .localized_name = false, .input_source = args[0] } };
    }
}

fn showHelpThenExit() noreturn {
    std.debug.print(
        \\tiny input source manager
        \\
        \\Usage: input-source <command> [--localized-name] [<args>]
        \\
        \\Commands:
        \\  current           Show current input source
        \\  list              List available input sources
        \\  set <Source>      Change input source to <source>
        \\
        \\Options:
        \\  --localized-name  Use LocalizedName instead of InputSourceID
        \\
        \\Examples:
        \\  input-source current
        \\  input-source current --localized-name
        \\  input-source list
        \\  input-source list --localized-name
        \\  input-source set com.apple.keylayout.ABC
        \\  input-source set --localized-name ABC
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

fn printInputSource(allocator: Allocator, source: c.TISInputSourceRef, localized_name: bool) Allocator.Error!void {
    const id: c.CFStringRef = @ptrCast(c.CFRetain(c.TISGetInputSourceProperty(source, if (localized_name) c.kTISPropertyLocalizedName else c.kTISPropertyInputSourceID)));
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
