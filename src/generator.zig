const std = @import("std");
const Perlin3d = @import("perlin3d.zig");
const Output = @import("output.zig");
const Utils = @import("utils.zig");

const Biome = Utils.Biome;
const MAP_SIZE = Utils.MAP_SIZE;
const F_MAP_SIZE = Utils.F_MAP_SIZE;

const SeedType = enum { elevation, moisture };

fn biome(sea_level: f64, forest_level: f64, elevation: f64, moisture: f64) Biome {
    if (elevation < sea_level) return .WATER;
    if (elevation < sea_level + sea_level * 0.1) return .BEACH;
    if (moisture > forest_level) {
        return .FOREST;
    }
    return .LAND;
}

fn generate_seed(world_seed: u32, seed_type: SeedType) u32 {
    const f_world_seed: f64 = @floatFromInt(world_seed);
    return switch (seed_type) {
        .elevation => safe_seed(
            std.math.cos(f_world_seed) * std.math.atan(f_world_seed) * std.math.sin(f_world_seed * std.math.e) * f_world_seed,
        ),
        .moisture => safe_seed(
            std.math.asin(std.math.sin(f_world_seed)) * std.math.tan(f_world_seed) * std.math.acos(std.math.cos(f_world_seed * std.math.e)) * f_world_seed,
        ),
    };
}

// The seed formulas have two failure modes that would panic on the u32 cast:
//  1. The result can be negative (cos/sin change sign per seed)
//  2. The result can be NaN (asin/acos only accept inputs in [-1, 1])
// Instead of panicking, fold both into a valid u32 seed:
//  - NaN -> 0
//  - anything else -> wrapped into [0, 2^32) with a float modulo
fn safe_seed(raw: f64) u32 {
    if (std.math.isNan(raw)) return 0;
    return @intFromFloat(@mod(@trunc(raw), 4294967296.0));
}

pub fn generate(allocator: std.mem.Allocator, io: std.Io, world_seed: u32) !void {
    const elevation_seed = generate_seed(world_seed, .elevation);
    const moisture_seed = generate_seed(world_seed, .moisture);

    std.debug.print("elevation seed: {d}\n", .{elevation_seed});
    std.debug.print("moisture seed: {d}\n", .{moisture_seed});

    var elevation_perlin = try Perlin3d.PerlinGenerator.init(allocator, elevation_seed);
    var moisture_perlin = try Perlin3d.PerlinGenerator.init(allocator, moisture_seed);

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

    elevation_perlin.octaves = 8;
    elevation_perlin.falloff = 0.25;
    moisture_perlin.octaves = 2;
    moisture_perlin.falloff = 0.65;

    for (0..MAP_SIZE * MAP_SIZE) |i| {
        const y: usize = i / MAP_SIZE;
        const x: usize = i % MAP_SIZE;

        const fx: f64 = @floatFromInt(x);
        const fy: f64 = @floatFromInt(y);
        const nx: f64 = fx / wavelength;
        const ny: f64 = fy / wavelength;

        const e: f64 = elevation_perlin.get(nx, ny, 0.0);
        const m: f64 = moisture_perlin.get(nx, ny, 0.0);

        elevation[y * MAP_SIZE + x] = std.math.pow(f64, e * fudge_factor, exponent);
        moisture[y * MAP_SIZE + x] = std.math.pow(f64, m * m_fudge_factor, m_exponent);
    }

    // biome selection
    const biome_elevation = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(biome_elevation);
    @memcpy(biome_elevation, elevation);
    std.sort.block(f64, biome_elevation, .{}, less_than);

    const biome_cuttoff_quartile: usize = @trunc(((F_MAP_SIZE * F_MAP_SIZE) * 0.33));
    const biome_cutoff = biome_elevation[biome_cuttoff_quartile];

    const moisture_elevation = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(moisture_elevation);
    @memcpy(moisture_elevation, moisture);
    std.sort.block(f64, moisture_elevation, .{}, less_than);

    // should at least be > 0.5
    const moisture_cuttoff_quartile: usize = @trunc(((F_MAP_SIZE * F_MAP_SIZE) * 0.8));
    const moisture_cutoff = moisture_elevation[moisture_cuttoff_quartile];

    for (0..MAP_SIZE * MAP_SIZE) |i| {
        const y: usize = i / MAP_SIZE;
        const x: usize = i % MAP_SIZE;
        biome_points[y * MAP_SIZE + x] = biome(biome_cutoff, moisture_cutoff, elevation[y * MAP_SIZE + x], moisture[y * MAP_SIZE + x]);
    }

    // writing the output to a file
    try Output.to_ppm_6(io, allocator, biome_points);
    try Output.to_ply(io, allocator, biome_points);
}

fn less_than(nothing: @TypeOf(.{}), a: f64, b: f64) bool {
    _ = nothing;
    return a < b;
}
