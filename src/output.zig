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

pub fn to_html(io: std.Io, allocator: std.mem.Allocator, map: *[MAP_SIZE][MAP_SIZE]Biome) !void {
    const cwd = std.Io.Dir.cwd();
    const output_dir_path = try make_directory(io, allocator, cwd);

    const output_file_path = try std.fs.path.joinZ(allocator, &.{ output_dir_path, "render.html" });
    _ = try cwd.createFile(io, output_file_path, .{});
    const out_file = try cwd.openFile(io, output_file_path, .{ .mode = .read_write });

    const file_header =
        \\ <!DOCTYPE html>
        \\ <html>
        \\ <head>
        \\ <title>Rendered</title>
        \\ </head>
        \\ <body>
    ;
    const div_open = try std.mem.Allocator.print(allocator,
        \\ <div style="display: grid; grid-template-columns:repeat({d},1fr); grid_template_rows:repeat({d},1fr); height: 100%">
    , .{ MAP_SIZE, MAP_SIZE });

    // buffer for the file writer, it flushes automatically when full
    var write_buffer: [64 * 1024]u8 = undefined;
    var file_writer = out_file.writer(io, &write_buffer);
    const w = &file_writer.interface;

    try w.writeAll(file_header);
    try w.writeAll(div_open);

    for (0..MAP_SIZE) |y| {
        for (0..MAP_SIZE) |x| {
            const color = biome_color(map[y][x]);
            const this_div = try std.mem.Allocator.print(allocator,
                \\ <div style="background: rgb({d}, {d}, {d}); min-width:2px; min-height:2px;"></div>
            , .{ color.r, color.g, color.b });
            try w.writeAll(this_div);
        }
        try w.writeByte('\n');
    }

    const file_footer =
        \\ </div>
        \\ </body>
        \\ </html>
    ;

    try w.writeAll(file_footer);

    try w.flush();
    out_file.close(io);
}

pub fn to_ppm_3(io: std.Io, allocator: std.mem.Allocator, map: *[MAP_SIZE][MAP_SIZE]Biome) !void {
    const cwd = std.Io.Dir.cwd();
    const output_dir_path = try make_directory(io, allocator, cwd);

    const output_file_path = try std.fs.path.joinZ(allocator, &.{ output_dir_path, "render_p3.ppm" });
    _ = try cwd.createFile(io, output_file_path, .{});
    const out_file = try cwd.openFile(io, output_file_path, .{ .mode = .read_write });

    const file_header = try std.mem.Allocator.print(allocator, "P3\n{d} {d}\n{d}\n", .{ MAP_SIZE, MAP_SIZE, 255 });

    // buffer for the file writer, it flushes automatically when full
    var write_buffer: [64 * 1024]u8 = undefined;
    var file_writer = out_file.writer(io, &write_buffer);
    const w = &file_writer.interface;

    try w.writeAll(file_header);

    for (0..MAP_SIZE) |y| {
        for (0..MAP_SIZE) |x| {
            const color = biome_color(map[y][x]);
            const this_px = try std.mem.Allocator.print(allocator, "{d} {d} {d}\n", .{ color.r, color.g, color.b });
            try w.writeAll(this_px);
        }
    }

    try w.flush();
    out_file.close(io);
}

pub fn to_ppm_6(io: std.Io, allocator: std.mem.Allocator, map: *[MAP_SIZE][MAP_SIZE]Biome) !void {
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

    for (0..MAP_SIZE) |y| {
        for (0..MAP_SIZE) |x| {
            const color = biome_color(map[y][x]);
            try w.writeByte(color.r);
            try w.writeByte(color.g);
            try w.writeByte(color.b);
        }
    }

    try w.flush();
    out_file.close(io);
}
