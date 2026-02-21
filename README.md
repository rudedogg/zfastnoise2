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
exe.linkLibrary(fastnoise2_dep.artifact("FastNoise2"));
```

This provides FastNoise2 as a static library with C headers available via `@cImport`.

### Build options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `strict_fp` | `bool` | `false` | Disable fast-math and FMA for reproducible output across SIMD levels |
| `linkage` | `enum` | `static` | `static` or `dynamic` library linkage |

## Usage

Import the C API with `@cImport`:

```zig
const fn2 = @cImport(@cInclude("FastNoise/FastNoise_C.h"));
```

### Generate a grid of noise

```zig
const std = @import("std");
const fn2 = @cImport(@cInclude("FastNoise/FastNoise_C.h"));

pub fn main() !void {
    // Create a Simplex noise node from an encoded node tree.
    // Use the FastNoise2 NoiseTool to design and export these strings.
    const node = fn2.fnNewFromEncodedNodeTree("BgQ=", std.math.maxInt(c_uint)) orelse return error.NodeCreationFailed;
    defer fn2.fnDeleteNodeRef(node);

    const width = 128;
    const height = 128;
    var noise: [width * height]f32 = undefined;
    var min_max: [2]f32 = undefined;

    // Generate a 128x128 grid of noise values
    fn2.fnGenUniformGrid2D(
        node,
        &noise,
        0, 0,           // x/y start offset
        width, height,   // grid dimensions
        0.01, 0.01,      // step size (controls zoom)
        1337,            // seed
        &min_max,
    );

    // noise[y * width + x] contains values typically in [-1, 1]
    std.debug.print("min: {d:.4}, max: {d:.4}\n", .{ min_max[0], min_max[1] });
}
```

### Build a noise graph programmatically

```zig
const std = @import("std");
const fn2 = @cImport(@cInclude("FastNoise/FastNoise_C.h"));

fn findNodeId(name: [:0]const u8) ?c_int {
    const count = fn2.fnGetMetadataCount();
    for (0..@intCast(count)) |i| {
        const id: c_int = @intCast(i);
        if (std.mem.orderZ(u8, fn2.fnGetMetadataName(id), name.ptr) == .eq) return id;
    }
    return null;
}

pub fn main() !void {
    const simplex_id = findNodeId("Simplex") orelse return error.NodeNotFound;
    const fractal_id = findNodeId("FractalFBm") orelse return error.NodeNotFound;

    // Create nodes
    const simplex = fn2.fnNewFromMetadata(simplex_id, std.math.maxInt(c_uint)) orelse return error.NodeCreationFailed;
    defer fn2.fnDeleteNodeRef(simplex);

    const fractal = fn2.fnNewFromMetadata(fractal_id, std.math.maxInt(c_uint)) orelse return error.NodeCreationFailed;
    defer fn2.fnDeleteNodeRef(fractal);

    // Wire simplex as the fractal's source input
    _ = fn2.fnSetNodeLookup(fractal, 0, simplex);

    // Configure: 5 octaves
    _ = fn2.fnSetVariableIntEnum(fractal, 0, 5);

    // Generate
    const width = 256;
    const height = 256;
    var noise: [width * height]f32 = undefined;

    fn2.fnGenUniformGrid2D(fractal, &noise, 0, 0, width, height, 0.01, 0.01, 42, null);

    std.debug.print("fractal noise[0]: {d:.4}\n", .{noise[0]});
}
```

## Upstream version

FastNoise2 [v1.1.0](https://github.com/Auburn/FastNoise2/releases/tag/v1.1.0)
