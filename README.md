# FastNoise2

This is [FastNoise2](https://github.com/Auburn/FastNoise2), packaged for [Zig](https://ziglang.org/).
FastNoise2 is a SIMD-accelerated noise generation library with runtime dispatch to the fastest available instruction set (AVX512, AVX2, SSE4.1, SSE2, NEON).

## How to use it

First, update your `build.zig.zon`:

```
zig fetch --save=FastNoise2 git+https://github.com/rudedogg/FastNoise2
```

Then add this to your `build.zig`:

```zig
const fastnoise2_dep = b.dependency("FastNoise2", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("zfastnoise2", fastnoise2_dep.module("zfastnoise2"));
```

This gives you the idiomatic Zig API via `@import("zfastnoise2")`.

If you only need the raw C API via `@cImport`, you can link the artifact directly instead:

```zig
exe.linkLibrary(fastnoise2_dep.artifact("FastNoise2"));
```

### Build options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `strict_fp` | `bool` | `false` | Disable fast-math and FMA for reproducible output across SIMD levels |
| `linkage` | `enum` | `static` | `static` or `dynamic` library linkage |

## Usage

### Generate a grid of noise

```zig
const std = @import("std");
const fn2 = @import("zfastnoise2");

pub fn main() !void {
    const node = try fn2.Node.fromType(.simplex);
    defer node.deinit();

    const width = 128;
    const height = 128;
    var noise: [width * height]f32 = undefined;

    const result = node.genUniformGrid2D(&noise, width, height, .{}).?;
    // noise[y * width + x] contains values typically in [-1, 1]
    std.debug.print("min: {d:.4}, max: {d:.4}\n", .{ result.min, result.max });
}
```

### Build a noise graph

```zig
const std = @import("std");
const fn2 = @import("zfastnoise2");

pub fn main() !void {
    const simplex = try fn2.Node.fromType(.simplex);
    defer simplex.deinit();

    const fractal = try fn2.Node.fromType(.fractal_fbm);
    defer fractal.deinit();

    // Wire simplex as the fractal's source input
    try fractal.set(fn2.FractalFBm.Source.source, simplex);

    // Set octave count to 5
    try fractal.set(fn2.FractalFBm.Var.octaves, 5);

    // Hybrid parameters accept both float values and node sources
    try fractal.set(fn2.FractalFBm.Hybrid.gain, 0.6);

    const width = 256;
    const height = 256;
    var noise: [width * height]f32 = undefined;

    _ = fractal.genUniformGrid2D(&noise, width, height, .{
        .x_offset = 100,
        .y_offset = 100,
        .seed = 42,
    });
    std.debug.print("fractal noise[0]: {d:.4}\n", .{noise[0]});
}
```

Every node type has a corresponding struct (e.g. `FractalFBm`, `CellularDistance`, `DomainOffset`) with `Var`, `Source`, and/or `Hybrid` enums listing its named parameter indices. Use `NodeParams(.node_type)` to get the struct for a given `NodeType`. Raw integer indices still work for all setters.

### Configure with type-safe enums

```zig
const fn2 = @import("zfastnoise2");

pub fn main() !void {
    const cell = try fn2.Node.fromType(.cellular_distance);
    defer cell.deinit();

    try cell.set(fn2.CellularDistance.Var.distance_function, fn2.DistanceFunction.manhattan);
    try cell.set(fn2.CellularDistance.Var.return_type, fn2.CellularReturnType.index0_sub1);

    var noise: [64 * 64]f32 = undefined;
    _ = cell.genUniformGrid2D(&noise, 64, 64, .{});
}
```

### Decode an encoded node tree

```zig
const fn2 = @import("zfastnoise2");

pub fn main() !void {
    // FastNoise2's NoiseTool exports base64-encoded node trees
    const node = try fn2.Node.fromEncoded("BgQ=");
    defer node.deinit();

    var noise: [128 * 128]f32 = undefined;
    _ = node.genUniformGrid2D(&noise, 128, 128, .{});
}
```

### Raw C API access

The underlying C API is always available via `fn2.c` for advanced use:

```zig
const std = @import("std");
const fn2 = @import("zfastnoise2");

pub fn main() !void {
    const count = fn2.c.fnGetMetadataCount();
    std.debug.print("Available nodes: {d}\n", .{count});
}
```

## Upstream version

FastNoise2 [v1.1.0](https://github.com/Auburn/FastNoise2/releases/tag/v1.1.0)
