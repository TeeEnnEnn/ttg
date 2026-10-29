const std = @import("std");
const Perlin3d = @import("perlin3d.zig");

const MAP_SIZE: u32 = 100;
const F_MAP_SIZE: f64 = @floatFromInt(MAP_SIZE);

pub fn generate(allocator: std.mem.Allocator, seed: u32) !void {
    var perlin = try Perlin3d.PerlinGenerator.init(allocator, seed);

    var elevation: [MAP_SIZE][MAP_SIZE]f64 = undefined;

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
            const exponent: f64 = 0.59;
            elevation[y][x] = std.math.pow(f64, e * fudge_factor, exponent);
        }
    }

    for (0..MAP_SIZE) |y| {
        for (0..MAP_SIZE) |x| {
            std.debug.print("{d} |", .{elevation[y][x]});
        }
        std.debug.print("\n", .{});
    }
}
