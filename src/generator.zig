const std = @import("std");
const Perlin3d = @import("perlin3d.zig");
const Output = @import("output.zig");
const Utils = @import("utils.zig");

const Biome = Utils.Biome;
const MAP_SIZE = Utils.MAP_SIZE;
const F_MAP_SIZE = Utils.F_MAP_SIZE;

fn biome(cutoff: f64, value: f64) Biome {
    if (value < cutoff) return .WATER;
    return .LAND;
}

pub fn generate(allocator: std.mem.Allocator, io: std.Io, seed: u32) !void {
    var perlin = try Perlin3d.PerlinGenerator.init(allocator, seed);

    var elevation: []f64 = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(elevation);
    var biome_points: []Biome = try allocator.alloc(Biome, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(biome_points);

    const frequency: f64 = 3;
    const wavelength = F_MAP_SIZE / frequency;

    const fudge_factor = 1.5;

    for (0..MAP_SIZE * MAP_SIZE) |i| {
        const y: usize = i / MAP_SIZE;
        const x: usize = i % MAP_SIZE;

        const fx: f64 = @floatFromInt(x);
        const fy: f64 = @floatFromInt(y);
        const nx: f64 = fx / wavelength;
        const ny: f64 = fy / wavelength;

        const e: f64 = perlin.get(nx, ny, 0.0);
        const exponent: f64 = 2.5;
        elevation[y * MAP_SIZE + x] = std.math.pow(f64, e * fudge_factor, exponent);
    }

    // biome selection
    const biome_elevation = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(biome_elevation);
    @memcpy(biome_elevation, elevation);
    std.sort.block(f64, biome_elevation, .{}, less_than);

    const thirtieth: usize = @intFromFloat(((F_MAP_SIZE * F_MAP_SIZE) * 0.33));
    const biome_cutoff = biome_elevation[thirtieth];

    for (0..MAP_SIZE * MAP_SIZE) |i| {
        const y: usize = i / MAP_SIZE;
        const x: usize = i % MAP_SIZE;
        biome_points[y * MAP_SIZE + x] = biome(biome_cutoff, elevation[y * MAP_SIZE + x]);
    }

    // writing the output to a file
    try Output.to_html(io, allocator, &biome_points);
    try Output.to_ppm_3(io, allocator, &biome_points);
    try Output.to_ppm_6(io, allocator, &biome_points);
}

fn less_than(nothing: @TypeOf(.{}), a: f64, b: f64) bool {
    _ = nothing;
    return a < b;
}
