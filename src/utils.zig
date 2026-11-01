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

pub const Z_SCALE: f64 = 150.0;
