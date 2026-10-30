const std = @import("std");
const Perlin3d = @import("perlin3d.zig");
const Output = @import("output.zig");
const Utils = @import("utils.zig");

const Biome = Utils.Biome;
const MAP_SIZE = Utils.MAP_SIZE;
const F_MAP_SIZE = Utils.F_MAP_SIZE;

fn biome(sea_level: f64, forest_level: f64, elevation: f64, moisture: f64) Biome {
    if (elevation < sea_level) return .WATER;

    if (moisture > forest_level) {
        return .FOREST;
    }
    return .LAND;
}

pub fn generate(allocator: std.mem.Allocator, io: std.Io, seed: u32) !void {
    var perlin = try Perlin3d.PerlinGenerator.init(allocator, seed);

    var elevation: []f64 = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(elevation);
    var biome_points: []Biome = try allocator.alloc(Biome, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(biome_points);
    var moisture: []f64 = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(moisture);

    const frequency: f64 = 3;
    const wavelength = F_MAP_SIZE / frequency;

    const fudge_factor = 1.5;
    const exponent: f64 = 2.5;

    const m_fudge_factor = 1.25;
    const m_exponent: f64 = 2.75;

    for (0..MAP_SIZE * MAP_SIZE) |i| {
        const y: usize = i / MAP_SIZE;
        const x: usize = i % MAP_SIZE;

        const fx: f64 = @floatFromInt(x);
        const fy: f64 = @floatFromInt(y);
        const nx: f64 = fx / wavelength;
        const ny: f64 = fy / wavelength;

        perlin.octaves = 8;
        perlin.falloff = 0.25;
        const e: f64 = perlin.get(nx, ny, 0.0);
        perlin.octaves = 2;
        perlin.falloff = 0.65;
        const m: f64 = perlin.get(nx, ny, 0.0);

        elevation[y * MAP_SIZE + x] = std.math.pow(f64, e * fudge_factor, exponent);
        moisture[y * MAP_SIZE + x] = std.math.pow(f64, m * m_fudge_factor, m_exponent);
    }

    // biome selection
    const biome_elevation = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(biome_elevation);
    @memcpy(biome_elevation, elevation);
    std.sort.block(f64, biome_elevation, .{}, less_than);

    const biome_cuttoff_quartile: usize = @intFromFloat(((F_MAP_SIZE * F_MAP_SIZE) * 0.33));
    const biome_cutoff = biome_elevation[biome_cuttoff_quartile];

    const moisture_elevation = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(moisture_elevation);
    @memcpy(moisture_elevation, elevation);
    std.sort.block(f64, moisture_elevation, .{}, less_than);

    // should at least be > 0.5
    const moisture_cuttoff_quartile: usize = @intFromFloat(((F_MAP_SIZE * F_MAP_SIZE) * 0.8));
    const moisture_cutoff = moisture_elevation[moisture_cuttoff_quartile];

    for (0..MAP_SIZE * MAP_SIZE) |i| {
        const y: usize = i / MAP_SIZE;
        const x: usize = i % MAP_SIZE;
        biome_points[y * MAP_SIZE + x] = biome(biome_cutoff, moisture_cutoff, elevation[y * MAP_SIZE + x], moisture[y * MAP_SIZE + x]);
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
