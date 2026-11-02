const std = @import("std");
const Io = std.Io;

const ttg = @import("ttg");

const CollectedArg = struct {
    flag: ?[]const u8,
    value: ?[]const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const args = init.minimal.args;

    if (args.vector.len == 1) {
        std.debug.print(ttg.Utils.help_message, .{});
        std.process.exit(0);
    }

    var collected_args: std.ArrayList(CollectedArg) = .empty;

    var args_it = try args.iterateAllocator(allocator);
    _ = args_it.next(); // skip the program name;

    var last_flag = false;

    while (args_it.next()) |arg| {
        if (arg.len == 0) {
            std.debug.print("Error: Received unexpected empty argument\n", .{});
            std.process.exit(1);
        }
        if (arg[0] == '-' and last_flag) {
            std.debug.print("Error: Attempting to pass a flag after a flag\n", .{});
            std.process.exit(1);
        } else if (arg[0] == '-') {
            last_flag = true;
            // remove the `-`
            for (collected_args.items) |item| {
                if (item.flag) |f| {
                    if (std.mem.eql(u8, arg[1..], f)) {
                        std.debug.print("Error: Duplicate flag given: -{s}.\n", .{f});
                        std.process.exit(1);
                    }
                }
            }
            try collected_args.append(allocator, .{ .flag = arg[1..], .value = null });
        } else {
            if (collected_args.items.len == 0) {
                std.debug.print("Error: Expected flag to start arguments list.\n", .{});
                std.process.exit(1);
            }

            last_flag = false;
            collected_args.items[collected_args.items.len - 1].value = arg;
        }
    }

    if (last_flag) {
        std.debug.print("Error: Ended on flag -{s} without corresponding value", .{collected_args.items[collected_args.items.len - 1].flag.?});
        std.process.exit(1);
    }

    var config: ttg.Utils.TTGConfig = .{};

    for (collected_args.items) |collected_arg| {
        if (collected_arg.flag) |f| {
            if (std.mem.eql(u8, "beach", f)) {
                if (collected_arg.value) |v| {
                    config.beach_threshold = ttg.Utils.parse_with_bounds(f64, f, v, 0.0, 1.0) catch {
                        std.process.exit(1);
                    };
                }
            } else if (std.mem.eql(u8, "water", f)) {
                if (collected_arg.value) |v| {
                    config.allowed_water_percentile = ttg.Utils.parse_with_bounds(f64, f, v, 0.0, 1.0) catch {
                        std.process.exit(1);
                    };
                }
            } else if (std.mem.eql(u8, "forest", f)) {
                if (collected_arg.value) |v| {
                    config.allowed_forest_percentile = ttg.Utils.parse_with_bounds(f64, f, v, 0.0, 1.0) catch {
                        std.process.exit(1);
                    };
                }
            } else if (std.mem.eql(u8, "seed", f)) {
                if (collected_arg.value) |v| {
                    config.world_seed = ttg.Utils.parse_with_bounds(u32, f, v, 0, std.math.maxInt(u32)) catch {
                        std.process.exit(1);
                    };
                }
            } else if (std.mem.eql(u8, "freq", f)) {
                if (collected_arg.value) |v| {
                    // min 0.1: frequency 0 makes the wavelength infinite,
                    // which collapses the whole map to one flat value
                    config.frequency = ttg.Utils.parse_with_bounds(f64, f, v, 0.1, 10.0) catch {
                        std.process.exit(1);
                    };
                }
            } else if (std.mem.eql(u8, "moct", f)) {
                if (collected_arg.value) |v| {
                    config.moisture_octaves = ttg.Utils.parse_with_bounds(i32, f, v, 0, 16) catch {
                        std.process.exit(1);
                    };
                }
            } else if (std.mem.eql(u8, "mfall", f)) {
                if (collected_arg.value) |v| {
                    config.moisture_falloff = ttg.Utils.parse_with_bounds(f64, f, v, 0.0, 10.0) catch {
                        std.process.exit(1);
                    };
                }
            } else if (std.mem.eql(u8, "eoct", f)) {
                if (collected_arg.value) |v| {
                    config.elevation_octaves = ttg.Utils.parse_with_bounds(i32, f, v, 0, 16) catch {
                        std.process.exit(1);
                    };
                }
            } else if (std.mem.eql(u8, "efall", f)) {
                if (collected_arg.value) |v| {
                    config.elevation_falloff = ttg.Utils.parse_with_bounds(f64, f, v, 0.0, 10.0) catch {
                        std.process.exit(1);
                    };
                }
            } else {
                std.debug.print("Error: encountered an unexpected flag: -{s}\n", .{collected_arg.flag.?});
                std.process.exit(1);
            }
        } else {
            std.debug.print("Error: expected a flag, found nothing\n", .{});
            std.process.exit(1);
        }
    }

    try ttg.Generator.generate(allocator, io, config);
}
