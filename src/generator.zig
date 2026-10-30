const std = @import("std");
const Perlin3d = @import("perlin3d.zig");

const MAP_SIZE: u32 = 1000;
const F_MAP_SIZE: f64 = @floatFromInt(MAP_SIZE);

const Biome = enum(u1) {
    WATER,
    LAND,
};

const RGB = struct { r: u8, g: u8, b: u8 };

fn biome_color(b: Biome) RGB {
    return switch (b) {
        .LAND => .{ .r = 171, .g = 115, .b = 79 },
        .WATER => .{ .r = 52, .g = 110, .b = 235 },
    };
}

fn biome(value: f64) Biome {
    if (value < 0.37) return .WATER;
    return .LAND;
}

pub fn generate(allocator: std.mem.Allocator, io: std.Io, seed: u32) !void {
    var perlin = try Perlin3d.PerlinGenerator.init(allocator, seed);

    var elevation: [MAP_SIZE][MAP_SIZE]f64 = undefined;
    var biome_points: [MAP_SIZE][MAP_SIZE]Biome = undefined;

    const amplitudes: [5]f64 = .{ 1.0, 0.5, 0.25, 0.125, 0.0625 }; // gain / persistence - the ratio between the numbers
    const amplitudes_sum: f64 = blk: {
        var sum: f64 = 0;
        for (0..amplitudes.len) |i| {
            sum += amplitudes[i];
        }
        break :blk sum;
    };

    const frequency: f64 = 8;
    const wavelength = F_MAP_SIZE / frequency;

    const fudge_factor = 1.2;

    for (0..MAP_SIZE) |y| {
        for (0..MAP_SIZE) |x| {
            const fx: f64 = @floatFromInt(x);
            const fy: f64 = @floatFromInt(y);
            const nx: f64 = fx / wavelength;
            const ny: f64 = fy / wavelength;

            var e: f64 = 0;
            var freq: f64 = 1.0;
            for (0..amplitudes.len) |i| {
                e += amplitudes[i] * perlin.get(freq * nx, freq * ny, 0.0);
                freq *= 2;
            }
            e = e / (amplitudes_sum);
            biome_points[y][x] = biome(e);
            const exponent: f64 = 0.59;
            elevation[y][x] = std.math.pow(f64, e * fudge_factor, exponent);
        }
    }

    // writing the output to a file
    try to_html(io, allocator, &biome_points);
    try to_ppm_3(io, allocator, &biome_points);
    try to_ppm_6(io, allocator, &biome_points);
}

pub fn to_html(io: std.Io, allocator: std.mem.Allocator, map: *[MAP_SIZE][MAP_SIZE]Biome) !void {
    const cwd = std.Io.Dir.cwd();
    const name = "output";
    const cwd_path = try std.process.currentPathAlloc(io, allocator);
    const output_dir_path = try std.fs.path.joinZ(allocator, &.{ cwd_path, name });

    std.Io.Dir.createDir(cwd, io, name, .default_dir) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {},
            else => return e,
        }
    };

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
    const name = "output";
    const cwd_path = try std.process.currentPathAlloc(io, allocator);
    const output_dir_path = try std.fs.path.joinZ(allocator, &.{ cwd_path, name });

    std.Io.Dir.createDir(cwd, io, name, .default_dir) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {},
            else => return e,
        }
    };

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
    const name = "output";
    const cwd_path = try std.process.currentPathAlloc(io, allocator);
    const output_dir_path = try std.fs.path.joinZ(allocator, &.{ cwd_path, name });

    std.Io.Dir.createDir(cwd, io, name, .default_dir) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {},
            else => return e,
        }
    };

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
