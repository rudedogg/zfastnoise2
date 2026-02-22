const std = @import("std");
const fn2 = @import("zfastnoise2");

pub fn main() !void {
    // === Example 1: Decode an encoded node tree ===
    //
    // FastNoise2's NoiseTool exports base64-encoded node trees.
    // Decode one directly and generate a 2D noise grid.
    std.debug.print("=== Example 1: Encoded node tree ===\n", .{});
    {
        const node = try fn2.Node.fromEncoded("BgQ="); // Simplex
        defer node.deinit();

        const width = 128;
        const height = 128;
        var noise: [width * height]f32 = undefined;

        const result = node.genUniformGrid2D(&noise, width, height, .{}).?;
        std.debug.print("  {d} x {d} Simplex grid — min: {d:.4}, max: {d:.4}\n", .{
            width, height, result.min, result.max,
        });
    }

    // === Example 2: Build a fractal noise graph (typed API) ===
    //
    // Create nodes with type-safe enums, wire them together, and configure parameters.
    std.debug.print("\n=== Example 2: Fractal noise graph ===\n", .{});
    {
        const simplex = try fn2.Node.fromType(.simplex);
        defer simplex.deinit();

        const fractal = try fn2.Node.fromType(.fractal_fbm);
        defer fractal.deinit();

        // Wire Simplex as the source for FractalFBm
        try fractal.set(fn2.FractalFBm.Source.source, simplex);

        // Set octave count to 5
        try fractal.set(fn2.FractalFBm.Var.octaves, 5);

        const width = 256;
        const height = 256;
        var noise: [width * height]f32 = undefined;

        const result = fractal.genUniformGrid2D(&noise, width, height, .{
            .x_offset = 100,
            .y_offset = 100,
            .seed = 42,
        }).?;
        std.debug.print("  {d} x {d} FBm grid — min: {d:.4}, max: {d:.4}\n", .{
            width, height, result.min, result.max,
        });
        std.debug.print("  noise[0] = {d:.6}\n", .{noise[0]});
    }

    // === Example 3: Single-point sampling ===
    //
    // genSingle is handy when you only need one value (note: slower than grid).
    std.debug.print("\n=== Example 3: Single-point sampling ===\n", .{});
    {
        const node = try fn2.Node.fromType(.perlin);
        defer node.deinit();

        const val = node.genSingle2D(1.23, 4.56, 1337);
        std.debug.print("  Perlin(1.23, 4.56) = {d:.6}\n", .{val});

        const val3d = node.genSingle3D(1.0, 2.0, 3.0, 1337);
        std.debug.print("  Perlin(1.0, 2.0, 3.0) = {d:.6}\n", .{val3d});
    }

    // === Example 4: Query node metadata ===
    //
    // Inspect available nodes, variables, and enum options at runtime.
    std.debug.print("\n=== Example 4: Metadata inspection ===\n", .{});
    {
        const total = fn2.Metadata.count();
        std.debug.print("  Available noise nodes: {d}\n", .{total});

        // Print first 5 nodes and their variables
        const limit: i32 = @min(total, 5);
        var id: i32 = 0;
        while (id < limit) : (id += 1) {
            const name = fn2.Metadata.name(id) orelse continue;
            const var_count = fn2.Metadata.variableCount(id);
            std.debug.print("  [{d}] {s} — {d} variable(s)\n", .{ id, name, var_count });

            var vi: i32 = 0;
            while (vi < var_count) : (vi += 1) {
                const vname = fn2.Metadata.variableName(id, vi) orelse continue;
                const vtype = fn2.Metadata.variableType(id, vi) orelse continue;
                switch (vtype) {
                    .float => std.debug.print("       {s}: float (default {d:.2})\n", .{
                        vname, fn2.Metadata.variableDefaultFloat(id, vi),
                    }),
                    .int => std.debug.print("       {s}: int (default {d})\n", .{
                        vname, fn2.Metadata.variableDefaultInt(id, vi),
                    }),
                    .enum_value => {
                        const enum_count = fn2.Metadata.enumCount(id, vi);
                        std.debug.print("       {s}: enum ({d} options)\n", .{ vname, enum_count });
                    },
                }
            }
        }
    }

    // === Example 5: Raw C API access ===
    //
    // The underlying C API is always available via fn2.c for advanced use.
    std.debug.print("\n=== Example 5: Raw C API ===\n", .{});
    {
        const raw_count = fn2.c.fnGetMetadataCount();
        std.debug.print("  fnGetMetadataCount() = {d}\n", .{raw_count});
    }
}
