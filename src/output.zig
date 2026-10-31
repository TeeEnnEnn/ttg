const std = @import("std");
const Utils = @import("utils.zig");

const MAP_SIZE = Utils.MAP_SIZE;
const Biome = Utils.Biome;
const biome_color = Utils.biome_color;

fn make_directory(io: std.Io, allocator: std.mem.Allocator, cwd: std.Io.Dir) ![:0]u8 {
    const name = "output";
    const cwd_path = try std.process.currentPathAlloc(io, allocator);
    const output_dir_path = try std.fs.path.joinZ(allocator, &.{ cwd_path, name });

    std.Io.Dir.createDir(cwd, io, name, .default_dir) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {},
            else => return e,
        }
    };
    return output_dir_path;
}

pub fn to_ppm_6(io: std.Io, allocator: std.mem.Allocator, map: []Biome) !void {
    const cwd = std.Io.Dir.cwd();
    const output_dir_path = try make_directory(io, allocator, cwd);

    const output_file_path = try std.fs.path.joinZ(allocator, &.{ output_dir_path, "render_p6.ppm" });
    _ = try cwd.createFile(io, output_file_path, .{});
    const out_file = try cwd.openFile(io, output_file_path, .{ .mode = .read_write });

    const file_header = try std.mem.Allocator.print(allocator, "P6\n{d} {d}\n{d}\n", .{ MAP_SIZE, MAP_SIZE, 255 });

    // buffer for the file writer, it flushes automatically when full
    var write_buffer: [64 * 1024]u8 = undefined;
    var file_writer = out_file.writer(io, &write_buffer);
    const w = &file_writer.interface;

    try w.writeAll(file_header);

    for (0..MAP_SIZE * MAP_SIZE) |i| {
        const y: usize = i / MAP_SIZE;
        const x: usize = i % MAP_SIZE;

        const color = biome_color(map[y * MAP_SIZE + x]);
        try w.writeByte(color.r);
        try w.writeByte(color.g);
        try w.writeByte(color.b);
    }

    try w.flush();
    out_file.close(io);
}

pub fn to_ply(io: std.Io, allocator: std.mem.Allocator, map: []Biome) !void {
    _ = map;
    const cwd = std.Io.Dir.cwd();
    const output_dir_path = try make_directory(io, allocator, cwd);

    const output_file_path = try std.fs.path.joinZ(allocator, &.{ output_dir_path, "render_ply.ply" });
    _ = try cwd.createFile(io, output_file_path, .{});
    const out_file = try cwd.openFile(io, output_file_path, .{ .mode = .read_write });

    // buffer for the file writer, it flushes automatically when full
    var write_buffer: [64 * 1024]u8 = undefined;
    var file_writer = out_file.writer(io, &write_buffer);
    const w = &file_writer.interface;

    try w.print("ply\nformat binary_little_endian 1.0\n", .{});
    try w.flush();
    out_file.close(io);
}
