const std = @import("std");
const Io = std.Io;

const ttg = @import("ttg");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    try ttg.Generator.generate(allocator, io, 1);
}
