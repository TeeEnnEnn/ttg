const std = @import("std");
const Perlin3d = @import("perlin3d.zig");
const Output = @import("output.zig");
const Utils = @import("utils.zig");

const Biome = Utils.Biome;
const MAP_SIZE = Utils.MAP_SIZE;
const F_MAP_SIZE = Utils.F_MAP_SIZE;
const TTGConfig = Utils.TTGConfig;

const SeedType = enum { elevation, moisture };

fn biome(sea_level: f64, forest_level: f64, elevation: f64, moisture: f64, beach_threshold: f64) Biome {
    if (elevation < sea_level) return .WATER;
    if (elevation < sea_level + sea_level * beach_threshold) return .BEACH;
    if (moisture > forest_level) {
        return .FOREST;
    }
    return .LAND;
}

fn generate_seed(world_seed: u32, seed_type: SeedType) u32 {
    var wyhash = std.hash.Wyhash.init(world_seed);
    const final: u64 = wyhash.final();

    return switch (seed_type) {
        .elevation => blk: {
            const high: u64 = final >> 32;
            var elevation_hasher = std.hash.Wyhash.init(high);
            break :blk @truncate(elevation_hasher.final());
        },
        .moisture => blk: {
            const low: u64 = @intCast(final & 0xFFFFFFFF);
            var moisture_hasher = std.hash.Wyhash.init(low);
            break :blk @truncate(moisture_hasher.final());
        },
    };
}

pub fn generate(allocator: std.mem.Allocator, io: std.Io, config: TTGConfig) !void {
    const elevation_seed = generate_seed(config.world_seed, .elevation);
    const moisture_seed = generate_seed(config.world_seed, .moisture);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const w = &stdout_writer.interface;

    try w.print("elevation seed: {d}\n", .{elevation_seed});
    try w.print("moisture seed: {d}\n", .{moisture_seed});
    try w.flush();

    std.Io.File.stdout().close(io);

    var elevation_perlin = try Perlin3d.PerlinGenerator.init(allocator, elevation_seed);
    var moisture_perlin = try Perlin3d.PerlinGenerator.init(allocator, moisture_seed);

    var elevation: []f64 = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(elevation);
    var biome_points: []Biome = try allocator.alloc(Biome, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(biome_points);
    var moisture: []f64 = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(moisture);

    const frequency: f64 = config.frequency;
    const wavelength = F_MAP_SIZE / frequency;

    const fudge_factor = 1.5;
    const exponent: f64 = 2.5;

    const m_fudge_factor = 1.25;
    const m_exponent: f64 = 2.75;

    elevation_perlin.octaves = config.elevation_octaves;
    elevation_perlin.falloff = config.elevation_falloff;
    moisture_perlin.octaves = config.moisture_octaves;
    moisture_perlin.falloff = config.moisture_falloff;

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

    const biome_cuttoff_percentile: usize = @min(
        @as(usize, @trunc(((F_MAP_SIZE * F_MAP_SIZE) * config.allowed_water_percentile))),
        MAP_SIZE * MAP_SIZE - 1,
    );
    const biome_cutoff = biome_elevation[biome_cuttoff_percentile];

    const moisture_elevation = try allocator.alloc(f64, @intCast(MAP_SIZE * MAP_SIZE));
    defer allocator.free(moisture_elevation);
    @memcpy(moisture_elevation, moisture);
    std.sort.block(f64, moisture_elevation, .{}, less_than);

    // should at least be > 0.5
    const moisture_cuttoff_percentile: usize = @min(
        @as(usize, @trunc(((F_MAP_SIZE * F_MAP_SIZE) * config.allowed_forest_percentile))),
        MAP_SIZE * MAP_SIZE - 1,
    );
    const moisture_cutoff = moisture_elevation[moisture_cuttoff_percentile];

    for (0..MAP_SIZE * MAP_SIZE) |i| {
        const y: usize = i / MAP_SIZE;
        const x: usize = i % MAP_SIZE;
        biome_points[y * MAP_SIZE + x] = biome(biome_cutoff, moisture_cutoff, elevation[y * MAP_SIZE + x], moisture[y * MAP_SIZE + x], config.beach_threshold);
    }

    // writing the output to a file
    try Output.to_ppm_6(io, allocator, biome_points);
    try Output.to_ply(io, allocator, biome_points, elevation);
}

fn less_than(nothing: @TypeOf(.{}), a: f64, b: f64) bool {
    _ = nothing;
    return a < b;
}
