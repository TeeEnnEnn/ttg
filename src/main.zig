const std = @import("std");
const Io = std.Io;

const ttg = @import("ttg");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const args = init.minimal.args;
    const expected: u32 = 1;

    const args_slice = try args.toSlice(allocator);
    if (args_slice.len != expected + 1) {
        std.debug.print("Expected {d} arguments, got {d}\n", .{ expected, args_slice.len });
        return error.InvalidArgumentCount;
    }

    var seed: u32 = 0;
    var args_it = try args.iterateAllocator(allocator);
    _ = args_it.next(); // skip the program name;
    while (args_it.next()) |arg| {
        seed = std.fmt.parseInt(u32, arg, 10) catch blk: {
            break :blk 0;
        };
    }

    try ttg.Generator.generate(allocator, io, seed);
}
