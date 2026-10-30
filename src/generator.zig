const std = @import("std");
const Perlin3d = @import("perlin3d.zig");
const Output = @import("output.zig");
const Utils = @import("utils.zig");

const Biome = Utils.Biome;
const MAP_SIZE = Utils.MAP_SIZE;
const F_MAP_SIZE = Utils.F_MAP_SIZE;

fn biome(value: f64) Biome {
    if (value < 0.30) return .WATER;
    return .LAND;
}

pub fn generate(allocator: std.mem.Allocator, io: std.Io, seed: u32) !void {
    var perlin = try Perlin3d.PerlinGenerator.init(allocator, seed);

    var elevation: [MAP_SIZE][MAP_SIZE]f64 = undefined;
    var biome_points: [MAP_SIZE][MAP_SIZE]Biome = undefined;

    const frequency: f64 = 3;
    const wavelength = F_MAP_SIZE / frequency;

    const fudge_factor = 1.5;

    for (0..MAP_SIZE) |y| {
        for (0..MAP_SIZE) |x| {
            const fx: f64 = @floatFromInt(x);
            const fy: f64 = @floatFromInt(y);
            const nx: f64 = fx / wavelength;
            const ny: f64 = fy / wavelength;

            const e: f64 = perlin.get(nx, ny, 0.0);
            const exponent: f64 = 2.5;
            elevation[y][x] = std.math.pow(f64, e * fudge_factor, exponent);
            biome_points[y][x] = biome(elevation[y][x]);
        }
    }

    // writing the output to a file
    try Output.to_html(io, allocator, &biome_points);
    try Output.to_ppm_3(io, allocator, &biome_points);
    try Output.to_ppm_6(io, allocator, &biome_points);
}
