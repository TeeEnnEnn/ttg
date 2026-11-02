const std = @import("std");

pub const MAP_SIZE: u32 = 1000;
pub const F_MAP_SIZE: f64 = @floatFromInt(MAP_SIZE);

pub const Biome = enum(u2) {
    WATER,
    LAND,
    FOREST,
    BEACH,
};

pub const RGB = struct { r: u8, g: u8, b: u8 };

pub fn biome_color(b: Biome) RGB {
    return switch (b) {
        .LAND => .{ .r = 171, .g = 115, .b = 79 },
        .WATER => .{ .r = 52, .g = 110, .b = 235 },
        .FOREST => .{ .r = 0, .g = 145, .b = 0 },
        .BEACH => .{ .r = 235, .g = 213, .b = 152 },
    };
}

pub const Z_SCALE: f64 = 200.0;

pub const TTGConfig = struct {
    /// the threshold used when assigning beach near water bodies
    /// Domain: f64 [0, 1]
    beach_threshold: f64 = 0.1,
    /// percentile at which to sample the cutoff for water
    /// Domain: f64 [0, 1]
    allowed_water_percentile: f64 = 0.15,
    /// percentile at which to sample the cutoff for forest
    /// Domain: f64 [0, 1]
    allowed_forest_percentile: f64 = 0.85,
    /// the seed for the world
    /// Domain: u32
    world_seed: u32 = 0,
    /// frequency
    /// Domain: f64 [0.1, 10]
    frequency: f64 = 3.0,
    /// moisture octaves
    /// Domain: i32 [0, 16]
    moisture_octaves: i32 = 2,
    /// moisture falloff
    /// Domain: f64 [0, 10]
    moisture_falloff: f64 = 0.65,
    /// elevation octaves
    /// Domain: i32 [0, 16]
    elevation_octaves: i32 = 8,
    /// elevation falloff
    /// Domain: f64 [0, 10]
    elevation_falloff: f64 = 0.25,
};

pub const help_message =
    \\ ttg - Theo's Terrain Generator
    \\
    \\ usage:   ttg -flag value [-flag value ...]
    \\ example: ttg -seed 1 -freq 4
    \\
    \\ -seed    u32 full range  0     world seed
    \\ -beach   f64 [0, 1]      0.1   beach width near water bodies
    \\ -water   f64 [0, 1]      0.15  percentile below => water
    \\ -forest  f64 [0, 1]      0.85  percentile above => forest
    \\ -freq    f64 [0.1, 10]   3.0   noise frequency (feature density)
    \\ -moct    i32 [0, 16]     2     moisture octaves
    \\ -mfall   f64 [0, 10]     0.65  moisture falloff
    \\ -eoct    i32 [0, 16]     8     elevation octaves
    \\ -efall   f64 [0, 10]     0.25  elevation falloff
    \\
    \\
;

pub fn parse_with_bounds(T: type, name: []const u8, s: []const u8, min: T, max: T) !T {
    const value: T = switch (@typeInfo(T)) {
        .float => std.fmt.parseFloat(T, s) catch |e| {
            std.debug.print("Error: failed to parse value '{s}' for flag -{s}\n", .{ s, name });
            return e;
        },
        .int => std.fmt.parseInt(T, s, 10) catch |e| {
            std.debug.print("Error: failed to parse value '{s}' for flag -{s}\n", .{ s, name });
            return e;
        },
        else => {
            std.debug.print("Error: unsupported value type for flag -{s}\n", .{name});
            return error.InternalStateError;
        },
    };

    if (value < min or value > max) {
        std.debug.print("Error: value '{s}' is out of bounds for flag -{s}. Bounds: min {d}, max {d}\n", .{ s, name, min, max });
        return error.ValueOutOfBounds;
    }

    return value;
}
