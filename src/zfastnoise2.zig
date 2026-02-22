const std = @import("std");
const build_options = @import("zfastnoise2_options");

pub const c = @cImport({
    if (build_options.static_lib) {
        @cDefine("FASTNOISE_STATIC_LIB", "1");
    }
    @cInclude("FastNoise/FastNoise_C.h");
});

const max_feature_set = ~@as(c_uint, 0);

/// Min and max values computed during noise generation.
pub const MinMax = struct { min: f32, max: f32 };

/// Options for 2D uniform grid generation.
pub const Grid2D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    x_step: f32 = 0.01,
    y_step: f32 = 0.01,
    seed: i32 = 1337,
    min_max: bool = true,
};

/// Options for 3D uniform grid generation.
pub const Grid3D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    z_offset: f32 = 0,
    x_step: f32 = 0.01,
    y_step: f32 = 0.01,
    z_step: f32 = 0.01,
    seed: i32 = 1337,
    min_max: bool = true,
};

/// Options for 4D uniform grid generation.
pub const Grid4D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    z_offset: f32 = 0,
    w_offset: f32 = 0,
    x_step: f32 = 0.01,
    y_step: f32 = 0.01,
    z_step: f32 = 0.01,
    w_step: f32 = 0.01,
    seed: i32 = 1337,
    min_max: bool = true,
};

/// Options for 2D tileable noise generation.
pub const Tileable2D = struct {
    x_step: f32 = 0.01,
    y_step: f32 = 0.01,
    seed: i32 = 1337,
    min_max: bool = true,
};

/// Options for 2D position array generation.
pub const PosArray2D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    seed: i32 = 1337,
    min_max: bool = true,
};

/// Options for 3D position array generation.
pub const PosArray3D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    z_offset: f32 = 0,
    seed: i32 = 1337,
    min_max: bool = true,
};

/// Options for 4D position array generation.
pub const PosArray4D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    z_offset: f32 = 0,
    w_offset: f32 = 0,
    seed: i32 = 1337,
    min_max: bool = true,
};

/// All available FastNoise2 node types. Values match metadata IDs.
pub const NodeType = enum(c_int) {
    // Basic Generators
    constant = 0,
    white = 1,
    checkerboard = 2,
    sine_wave = 3,
    gradient = 4,
    distance_to_point = 5,
    // Coherent Noise
    simplex = 6,
    super_simplex = 7,
    perlin = 8,
    value = 9,
    // Cellular
    cellular_value = 10,
    cellular_distance = 11,
    cellular_lookup = 12,
    // Fractal
    fractal_fbm = 13,
    ping_pong = 14,
    fractal_ridged = 15,
    // Domain Warp
    domain_warp_simplex = 16,
    domain_warp_super_simplex = 17,
    domain_warp_gradient = 18,
    domain_warp_fractal_progressive = 19,
    domain_warp_fractal_independent = 20,
    // Operators
    add = 21,
    subtract = 22,
    multiply = 23,
    divide = 24,
    // Math Modifiers
    abs = 25,
    min = 26,
    max = 27,
    min_smooth = 28,
    max_smooth = 29,
    signed_square_root = 30,
    pow_float = 31,
    pow_int = 32,
    // Domain Modifiers
    domain_scale = 33,
    domain_offset = 34,
    domain_rotate = 35,
    domain_axis_scale = 36,
    // Utility
    seed_offset = 37,
    convert_rgba8 = 38,
    generator_cache = 39,
    // Blends & Other
    fade = 40,
    remap = 41,
    terrace = 42,
    add_dimension = 43,
    remove_dimension = 44,
    modulus = 45,
    domain_rotate_plane = 46,

    /// Returns the display name for this node type (e.g. "Simplex").
    pub fn name(self: NodeType) ?[:0]const u8 {
        return Metadata.name(@intFromEnum(self));
    }
};

/// Distance function used by cellular noise nodes.
pub const DistanceFunction = enum(c_int) {
    euclidean = 0,
    euclidean_squared = 1,
    manhattan = 2,
    hybrid = 3,
    max_axis = 4,
    minkowski = 5,
};

/// Return type for cellular distance nodes, combining distance indices.
pub const CellularReturnType = enum(c_int) {
    index0 = 0,
    index0_add1 = 1,
    index0_sub1 = 2,
    index0_mul1 = 3,
    index0_div1 = 4,
};

/// Interpolation method for fade/blend operations.
pub const Interpolation = enum(c_int) {
    linear = 0,
    hermite = 1,
    quintic = 2,
};

/// Vectorization scheme for domain warp nodes.
pub const VectorizationScheme = enum(c_int) {
    orthogonal_gradient_matrix = 0,
    gradient_outer_product = 1,
};

/// Plane rotation type for domain warp plane rotation.
pub const PlaneRotationType = enum(c_int) {
    improve_xy_planes = 0,
    improve_xz_planes = 1,
};

/// Spatial dimension, used for per-dimension parameter variants.
pub const Dimension = enum(c_int) {
    x = 0,
    y = 1,
    z = 2,
    w = 3,
};

/// Discriminates parameter index categories for compile-time kind checking.
pub const IndexKind = enum { variable, source, hybrid };

// Per-node index enums — gives names to variable/source/hybrid indices.
// Only non-empty categories are included per node.

pub const Constant = struct {
    pub const Var = enum(c_int) {
        value = 0,
        pub const kind: IndexKind = .variable;
    };
};

pub const White = struct {
    pub const Var = enum(c_int) {
        seed_offset = 0,
        output_min = 1,
        output_max = 2,
        pub const kind: IndexKind = .variable;
    };
};

pub const Checkerboard = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        output_min = 1,
        output_max = 2,
        pub const kind: IndexKind = .variable;
    };
};

pub const SineWave = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        output_min = 1,
        output_max = 2,
        pub const kind: IndexKind = .variable;
    };
};

pub const Gradient = struct {
    pub const Var = enum(c_int) {
        multiplier_x = 0,
        multiplier_y = 1,
        multiplier_z = 2,
        multiplier_w = 3,
        pub const kind: IndexKind = .variable;
    };
    pub const Hybrid = enum(c_int) {
        offset_x = 0,
        offset_y = 1,
        offset_z = 2,
        offset_w = 3,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const DistanceToPoint = struct {
    pub const Var = enum(c_int) {
        distance_function = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Hybrid = enum(c_int) {
        point_x = 0,
        point_y = 1,
        point_z = 2,
        point_w = 3,
        minkowski_p = 4,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Simplex = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        output_min = 2,
        output_max = 3,
        pub const kind: IndexKind = .variable;
    };
};

pub const SuperSimplex = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        output_min = 2,
        output_max = 3,
        pub const kind: IndexKind = .variable;
    };
};

pub const Perlin = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        output_min = 2,
        output_max = 3,
        pub const kind: IndexKind = .variable;
    };
};

pub const Value = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        output_min = 2,
        output_max = 3,
        pub const kind: IndexKind = .variable;
    };
};

pub const CellularValue = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        output_min = 2,
        output_max = 3,
        distance_function = 4,
        value_index = 5,
        pub const kind: IndexKind = .variable;
    };
    pub const Hybrid = enum(c_int) {
        minkowski_p = 0,
        grid_jitter = 1,
        size_jitter = 2,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const CellularDistance = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        output_min = 2,
        output_max = 3,
        distance_function = 4,
        distance_index_0 = 5,
        distance_index_1 = 6,
        return_type = 7,
        pub const kind: IndexKind = .variable;
    };
    pub const Hybrid = enum(c_int) {
        minkowski_p = 0,
        grid_jitter = 1,
        size_jitter = 2,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const CellularLookup = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        distance_function = 2,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        lookup = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        minkowski_p = 0,
        grid_jitter = 1,
        size_jitter = 2,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const FractalFBm = struct {
    pub const Var = enum(c_int) {
        octaves = 0,
        lacunarity = 1,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        gain = 0,
        weighted_strength = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const PingPong = struct {
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        ping_pong_strength = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const FractalRidged = struct {
    pub const Var = enum(c_int) {
        octaves = 0,
        lacunarity = 1,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        gain = 0,
        weighted_strength = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const DomainWarpSimplex = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        amplitude_scaling_x = 2,
        amplitude_scaling_y = 3,
        amplitude_scaling_z = 4,
        amplitude_scaling_w = 5,
        vectorization_scheme = 6,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        warp_amplitude = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const DomainWarpSuperSimplex = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        amplitude_scaling_x = 2,
        amplitude_scaling_y = 3,
        amplitude_scaling_z = 4,
        amplitude_scaling_w = 5,
        vectorization_scheme = 6,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        warp_amplitude = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const DomainWarpGradient = struct {
    pub const Var = enum(c_int) {
        feature_scale = 0,
        seed_offset = 1,
        amplitude_scaling_x = 2,
        amplitude_scaling_y = 3,
        amplitude_scaling_z = 4,
        amplitude_scaling_w = 5,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        warp_amplitude = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const DomainWarpFractalProgressive = struct {
    pub const Var = enum(c_int) {
        octaves = 0,
        lacunarity = 1,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        domain_warp_source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        gain = 0,
        weighted_strength = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const DomainWarpFractalIndependent = struct {
    pub const Var = enum(c_int) {
        octaves = 0,
        lacunarity = 1,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        domain_warp_source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        gain = 0,
        weighted_strength = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Add = struct {
    pub const Source = enum(c_int) {
        lhs = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        rhs = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Subtract = struct {
    pub const Hybrid = enum(c_int) {
        lhs = 0,
        rhs = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Multiply = struct {
    pub const Source = enum(c_int) {
        lhs = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        rhs = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Divide = struct {
    pub const Hybrid = enum(c_int) {
        lhs = 0,
        rhs = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Abs = struct {
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const Min = struct {
    pub const Source = enum(c_int) {
        lhs = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        rhs = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Max = struct {
    pub const Source = enum(c_int) {
        lhs = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        rhs = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const MinSmooth = struct {
    pub const Source = enum(c_int) {
        lhs = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        rhs = 0,
        smoothness = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const MaxSmooth = struct {
    pub const Source = enum(c_int) {
        lhs = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        rhs = 0,
        smoothness = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const SignedSquareRoot = struct {
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const PowFloat = struct {
    pub const Hybrid = enum(c_int) {
        value = 0,
        pow = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const PowInt = struct {
    pub const Var = enum(c_int) {
        pow = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        value = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const DomainScale = struct {
    pub const Var = enum(c_int) {
        scaling = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const DomainOffset = struct {
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        offset_x = 0,
        offset_y = 1,
        offset_z = 2,
        offset_w = 3,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const DomainRotate = struct {
    pub const Var = enum(c_int) {
        yaw = 0,
        pitch = 1,
        roll = 2,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const DomainAxisScale = struct {
    pub const Var = enum(c_int) {
        scaling_x = 0,
        scaling_y = 1,
        scaling_z = 2,
        scaling_w = 3,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const SeedOffset = struct {
    pub const Var = enum(c_int) {
        seed_offset = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const ConvertRGBA8 = struct {
    pub const Var = enum(c_int) {
        min = 0,
        max = 1,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const GeneratorCache = struct {
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const Fade = struct {
    pub const Var = enum(c_int) {
        interpolation = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        a = 0,
        b = 1,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        fade = 0,
        fade_min = 1,
        fade_max = 2,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Remap = struct {
    pub const Var = enum(c_int) {
        clamp_output = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        from_min = 0,
        from_max = 1,
        to_min = 2,
        to_max = 3,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const Terrace = struct {
    pub const Var = enum(c_int) {
        step_count = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        smoothness = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const AddDimension = struct {
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
    pub const Hybrid = enum(c_int) {
        new_dimension_position = 0,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const RemoveDimension = struct {
    pub const Var = enum(c_int) {
        remove_dimension = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

pub const Modulus = struct {
    pub const Hybrid = enum(c_int) {
        lhs = 0,
        rhs = 1,
        pub const kind: IndexKind = .hybrid;
    };
};

pub const DomainRotatePlane = struct {
    pub const Var = enum(c_int) {
        rotation_type = 0,
        pub const kind: IndexKind = .variable;
    };
    pub const Source = enum(c_int) {
        source = 0,
        pub const kind: IndexKind = .source;
    };
};

/// Maps a NodeType to its per-node parameter struct.
pub fn NodeParams(comptime node_type: NodeType) type {
    return switch (node_type) {
        .constant => Constant,
        .white => White,
        .checkerboard => Checkerboard,
        .sine_wave => SineWave,
        .gradient => Gradient,
        .distance_to_point => DistanceToPoint,
        .simplex => Simplex,
        .super_simplex => SuperSimplex,
        .perlin => Perlin,
        .value => Value,
        .cellular_value => CellularValue,
        .cellular_distance => CellularDistance,
        .cellular_lookup => CellularLookup,
        .fractal_fbm => FractalFBm,
        .ping_pong => PingPong,
        .fractal_ridged => FractalRidged,
        .domain_warp_simplex => DomainWarpSimplex,
        .domain_warp_super_simplex => DomainWarpSuperSimplex,
        .domain_warp_gradient => DomainWarpGradient,
        .domain_warp_fractal_progressive => DomainWarpFractalProgressive,
        .domain_warp_fractal_independent => DomainWarpFractalIndependent,
        .add => Add,
        .subtract => Subtract,
        .multiply => Multiply,
        .divide => Divide,
        .abs => Abs,
        .min => Min,
        .max => Max,
        .min_smooth => MinSmooth,
        .max_smooth => MaxSmooth,
        .signed_square_root => SignedSquareRoot,
        .pow_float => PowFloat,
        .pow_int => PowInt,
        .domain_scale => DomainScale,
        .domain_offset => DomainOffset,
        .domain_rotate => DomainRotate,
        .domain_axis_scale => DomainAxisScale,
        .seed_offset => SeedOffset,
        .convert_rgba8 => ConvertRGBA8,
        .generator_cache => GeneratorCache,
        .fade => Fade,
        .remap => Remap,
        .terrace => Terrace,
        .add_dimension => AddDimension,
        .remove_dimension => RemoveDimension,
        .modulus => Modulus,
        .domain_rotate_plane => DomainRotatePlane,
    };
}

fn resolveIndex(comptime expected: IndexKind, index: anytype) c_int {
    const T = @TypeOf(index);
    return switch (@typeInfo(T)) {
        .int, .comptime_int => @intCast(index),
        .@"enum" => blk: {
            if (@hasDecl(T, "kind")) {
                if (T.kind != expected) {
                    @compileError("expected a " ++ @tagName(expected) ++ " index, got a " ++ @tagName(T.kind) ++ " index");
                }
            }
            break :blk @intFromEnum(index);
        },
        else => @compileError("expected an integer or enum index"),
    };
}

/// A FastNoise2 noise generator node. Nodes form a graph that can be configured
/// and used to generate noise. Call `deinit` when done to free the underlying C++ object.
pub const Node = struct {
    handle: *anyopaque,

    /// Creates a node by decoding a base64-encoded node tree (from NoiseTool).
    pub fn fromEncoded(encoded: [*:0]const u8) error{DecodeFailed}!Node {
        return .{ .handle = c.fnNewFromEncodedNodeTree(encoded, max_feature_set) orelse return error.DecodeFailed };
    }

    /// Creates a node from a raw metadata ID.
    pub fn fromMetadata(id: i32) error{InvalidId}!Node {
        return .{ .handle = c.fnNewFromMetadata(id, max_feature_set) orelse return error.InvalidId };
    }

    /// Creates a node by looking up a display name (e.g. "Simplex").
    pub fn fromName(name: [*:0]const u8) error{NodeNotFound}!Node {
        const id = Metadata.idFromName(name) orelse return error.NodeNotFound;
        return .{ .handle = c.fnNewFromMetadata(id, max_feature_set) orelse return error.NodeNotFound };
    }

    /// Creates a node from a `NodeType` enum value.
    pub fn fromType(node_type: NodeType) error{NodeNotFound}!Node {
        return .{
            .handle = c.fnNewFromMetadata(
                @intFromEnum(node_type),
                max_feature_set,
            ) orelse return error.NodeNotFound,
        };
    }

    /// Releases the underlying C++ node reference.
    pub fn deinit(self: Node) void {
        c.fnDeleteNodeRef(self.handle);
    }

    /// Sets a float variable. `variable_index` accepts a raw `i32` or a typed `Var` enum.
    pub fn setFloat(self: Node, variable_index: anytype, value: f32) error{SetFailed}!void {
        if (!c.fnSetVariableFloat(self.handle, resolveIndex(.variable, variable_index), value))
            return error.SetFailed;
    }

    /// Sets an integer variable. `variable_index` accepts a raw `i32` or a typed `Var` enum.
    pub fn setInt(self: Node, variable_index: anytype, value: i32) error{SetFailed}!void {
        if (!c.fnSetVariableIntEnum(self.handle, resolveIndex(.variable, variable_index), value))
            return error.SetFailed;
    }

    /// Sets an enum variable (e.g. `DistanceFunction`). Both index and value are type-checked.
    pub fn setEnum(self: Node, variable_index: anytype, value: anytype) error{SetFailed}!void {
        if (@typeInfo(@TypeOf(value)) != .@"enum") @compileError("setEnum requires an enum value");
        if (!c.fnSetVariableIntEnum(self.handle, resolveIndex(.variable, variable_index), @intFromEnum(value)))
            return error.SetFailed;
    }

    /// Wires a source node input. `lookup_index` accepts a raw `i32` or a typed `Source` enum.
    pub fn setSource(self: Node, lookup_index: anytype, source: Node) error{SetFailed}!void {
        if (!c.fnSetNodeLookup(self.handle, resolveIndex(.source, lookup_index), source.handle))
            return error.SetFailed;
    }

    /// Wires a hybrid input as a node source. `index` accepts a raw `i32` or a typed `Hybrid` enum.
    pub fn setHybridSource(self: Node, index: anytype, source: Node) error{SetFailed}!void {
        if (!c.fnSetHybridNodeLookup(self.handle, resolveIndex(.hybrid, index), source.handle))
            return error.SetFailed;
    }

    /// Sets a hybrid input as a float constant. `index` accepts a raw `i32` or a typed `Hybrid` enum.
    pub fn setHybridFloat(self: Node, index: anytype, value: f32) error{SetFailed}!void {
        if (!c.fnSetHybridFloat(self.handle, resolveIndex(.hybrid, index), value))
            return error.SetFailed;
    }

    /// Unified setter that dispatches based on the index enum's `kind` and the value type.
    /// Requires a typed index enum (must have a `.kind` decl). For raw integer indices,
    /// use the explicit setters (`setFloat`, `setInt`, `setSource`, etc.) instead.
    pub fn set(self: Node, index: anytype, value: anytype) error{SetFailed}!void {
        const I = @TypeOf(index);
        if (@typeInfo(I) != .@"enum" or !@hasDecl(I, "kind"))
            @compileError("set() requires a typed index enum with a .kind decl; use setFloat/setInt/setSource/setHybridFloat/setHybridSource for raw indices");

        const V = @TypeOf(value);
        switch (I.kind) {
            .variable => {
                if (V == f32 or V == comptime_float)
                    return self.setFloat(index, value)
                else if (@typeInfo(V) == .@"enum")
                    return self.setEnum(index, value)
                else if (@typeInfo(V) == .int or @typeInfo(V) == .comptime_int)
                    return self.setInt(index, @intCast(value))
                else
                    @compileError("variable index expects an f32, integer, or enum value");
            },
            .source => {
                if (V == Node)
                    return self.setSource(index, value)
                else
                    @compileError("source index expects a Node value");
            },
            .hybrid => {
                if (V == f32 or V == comptime_float)
                    return self.setHybridFloat(index, value)
                else if (V == Node)
                    return self.setHybridSource(index, value)
                else
                    @compileError("hybrid index expects an f32 or Node value");
            },
        }
    }

    /// Returns the SIMD feature set this node will use at runtime.
    pub fn activeFeatureSet(self: Node) c_uint {
        return c.fnGetActiveFeatureSet(self.handle);
    }

    /// Returns the metadata ID for this node's type.
    pub fn metadataId(self: Node) i32 {
        return c.fnGetMetadataID(self.handle);
    }

    // Generation — assertions are precondition checks (programmer errors). They fire in
    // Debug/ReleaseSafe and compile out in ReleaseFast/ReleaseSmall, matching Zig stdlib conventions.

    /// Generates noise on a 2D uniform grid. Returns `null` when `opts.min_max` is `false`.
    pub fn genUniformGrid2D(self: Node, output: []f32, x_count: u31, y_count: u31, opts: Grid2D) ?MinMax {
        std.debug.assert(output.len >= @as(usize, x_count) * @as(usize, y_count));
        var mm: [2]f32 = undefined;
        c.fnGenUniformGrid2D(
            self.handle,
            output.ptr,
            opts.x_offset,
            opts.y_offset,
            x_count,
            y_count,
            opts.x_step,
            opts.y_step,
            opts.seed,
            if (opts.min_max) &mm else null,
        );
        return if (opts.min_max) .{ .min = mm[0], .max = mm[1] } else null;
    }

    /// Generates noise on a 3D uniform grid. Returns `null` when `opts.min_max` is `false`.
    pub fn genUniformGrid3D(self: Node, output: []f32, x_count: u31, y_count: u31, z_count: u31, opts: Grid3D) ?MinMax {
        std.debug.assert(output.len >= @as(usize, x_count) * @as(usize, y_count) * @as(usize, z_count));
        var mm: [2]f32 = undefined;
        c.fnGenUniformGrid3D(
            self.handle,
            output.ptr,
            opts.x_offset,
            opts.y_offset,
            opts.z_offset,
            x_count,
            y_count,
            z_count,
            opts.x_step,
            opts.y_step,
            opts.z_step,
            opts.seed,
            if (opts.min_max) &mm else null,
        );
        return if (opts.min_max) .{ .min = mm[0], .max = mm[1] } else null;
    }

    /// Generates noise on a 4D uniform grid. Returns `null` when `opts.min_max` is `false`.
    pub fn genUniformGrid4D(self: Node, output: []f32, x_count: u31, y_count: u31, z_count: u31, w_count: u31, opts: Grid4D) ?MinMax {
        std.debug.assert(output.len >= @as(usize, x_count) * @as(usize, y_count) * @as(usize, z_count) * @as(usize, w_count));
        var mm: [2]f32 = undefined;
        c.fnGenUniformGrid4D(
            self.handle,
            output.ptr,
            opts.x_offset,
            opts.y_offset,
            opts.z_offset,
            opts.w_offset,
            x_count,
            y_count,
            z_count,
            w_count,
            opts.x_step,
            opts.y_step,
            opts.z_step,
            opts.w_step,
            opts.seed,
            if (opts.min_max) &mm else null,
        );
        return if (opts.min_max) .{ .min = mm[0], .max = mm[1] } else null;
    }

    /// Generates noise at arbitrary 2D positions. Returns `null` when `opts.min_max` is `false`.
    pub fn genPositionArray2D(self: Node, output: []f32, x_pos: []const f32, y_pos: []const f32, opts: PosArray2D) ?MinMax {
        std.debug.assert(y_pos.len == x_pos.len);
        std.debug.assert(output.len >= x_pos.len);
        std.debug.assert(x_pos.len <= std.math.maxInt(c_int));
        var mm: [2]f32 = undefined;
        const count: c_int = @intCast(x_pos.len);
        c.fnGenPositionArray2D(
            self.handle,
            output.ptr,
            count,
            x_pos.ptr,
            y_pos.ptr,
            opts.x_offset,
            opts.y_offset,
            opts.seed,
            if (opts.min_max) &mm else null,
        );
        return if (opts.min_max) .{ .min = mm[0], .max = mm[1] } else null;
    }

    /// Generates noise at arbitrary 3D positions. Returns `null` when `opts.min_max` is `false`.
    pub fn genPositionArray3D(self: Node, output: []f32, x_pos: []const f32, y_pos: []const f32, z_pos: []const f32, opts: PosArray3D) ?MinMax {
        std.debug.assert(y_pos.len == x_pos.len);
        std.debug.assert(z_pos.len == x_pos.len);
        std.debug.assert(output.len >= x_pos.len);
        std.debug.assert(x_pos.len <= std.math.maxInt(c_int));
        var mm: [2]f32 = undefined;
        const count: c_int = @intCast(x_pos.len);
        c.fnGenPositionArray3D(
            self.handle,
            output.ptr,
            count,
            x_pos.ptr,
            y_pos.ptr,
            z_pos.ptr,
            opts.x_offset,
            opts.y_offset,
            opts.z_offset,
            opts.seed,
            if (opts.min_max) &mm else null,
        );
        return if (opts.min_max) .{ .min = mm[0], .max = mm[1] } else null;
    }

    /// Generates noise at arbitrary 4D positions. Returns `null` when `opts.min_max` is `false`.
    pub fn genPositionArray4D(self: Node, output: []f32, x_pos: []const f32, y_pos: []const f32, z_pos: []const f32, w_pos: []const f32, opts: PosArray4D) ?MinMax {
        std.debug.assert(y_pos.len == x_pos.len);
        std.debug.assert(z_pos.len == x_pos.len);
        std.debug.assert(w_pos.len == x_pos.len);
        std.debug.assert(output.len >= x_pos.len);
        std.debug.assert(x_pos.len <= std.math.maxInt(c_int));
        var mm: [2]f32 = undefined;
        const count: c_int = @intCast(x_pos.len);
        c.fnGenPositionArray4D(
            self.handle,
            output.ptr,
            count,
            x_pos.ptr,
            y_pos.ptr,
            z_pos.ptr,
            w_pos.ptr,
            opts.x_offset,
            opts.y_offset,
            opts.z_offset,
            opts.w_offset,
            opts.seed,
            if (opts.min_max) &mm else null,
        );
        return if (opts.min_max) .{ .min = mm[0], .max = mm[1] } else null;
    }

    /// Generates seamlessly tileable 2D noise. Returns `null` when `opts.min_max` is `false`.
    pub fn genTileable2D(self: Node, output: []f32, x_size: u31, y_size: u31, opts: Tileable2D) ?MinMax {
        std.debug.assert(output.len >= @as(usize, x_size) * @as(usize, y_size));
        var mm: [2]f32 = undefined;
        c.fnGenTileable2D(
            self.handle,
            output.ptr,
            x_size,
            y_size,
            opts.x_step,
            opts.y_step,
            opts.seed,
            if (opts.min_max) &mm else null,
        );
        return if (opts.min_max) .{ .min = mm[0], .max = mm[1] } else null;
    }

    /// Samples a single 2D point. Slower per-sample than batch gen functions.
    pub fn genSingle2D(self: Node, x: f32, y: f32, seed: i32) f32 {
        return c.fnGenSingle2D(self.handle, x, y, seed);
    }

    /// Samples a single 3D point. Slower per-sample than batch gen functions.
    pub fn genSingle3D(self: Node, x: f32, y: f32, z: f32, seed: i32) f32 {
        return c.fnGenSingle3D(self.handle, x, y, z, seed);
    }

    /// Samples a single 4D point. Slower per-sample than batch gen functions.
    pub fn genSingle4D(self: Node, x: f32, y: f32, z: f32, w: f32, seed: i32) f32 {
        return c.fnGenSingle4D(self.handle, x, y, z, w, seed);
    }
};

/// Runtime metadata for all registered FastNoise2 node types — names, descriptions,
/// variable counts, enum options, and dimension info.
pub const Metadata = struct {
    pub const VariableType = enum(c_int) {
        float = 0,
        int = 1,
        enum_value = 2,
    };

    pub fn count() i32 {
        return c.fnGetMetadataCount();
    }

    pub fn name(id: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataName(id) orelse return null);
    }

    pub fn idFromName(target: [*:0]const u8) ?i32 {
        for (0..@intCast(count())) |i| {
            const id: i32 = @intCast(i);
            const node_name = c.fnGetMetadataName(id) orelse continue;
            if (std.mem.orderZ(u8, node_name, target) == .eq) return id;
        }
        return null;
    }

    pub fn description(id: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataDescription(id) orelse return null);
    }

    pub fn variableCount(id: i32) i32 {
        return c.fnGetMetadataVariableCount(id);
    }

    pub fn variableName(id: i32, index: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataVariableName(id, index) orelse return null);
    }

    pub fn variableType(id: i32, index: i32) ?VariableType {
        const t = c.fnGetMetadataVariableType(id, index);
        return if (t < 0 or t > @intFromEnum(VariableType.enum_value)) null else @enumFromInt(t);
    }

    pub fn variableDimensionIdx(id: i32, index: i32) ?Dimension {
        const d = c.fnGetMetadataVariableDimensionIdx(id, index);
        return if (d < 0 or d > 3) null else @enumFromInt(d);
    }

    pub fn enumCount(id: i32, variable_index: i32) i32 {
        return c.fnGetMetadataEnumCount(id, variable_index);
    }

    pub fn enumName(id: i32, variable_index: i32, enum_index: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataEnumName(id, variable_index, enum_index) orelse return null);
    }

    pub fn variableDescription(id: i32, index: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataVariableDescription(id, index) orelse return null);
    }

    pub fn variableDefaultFloat(id: i32, index: i32) f32 {
        return c.fnGetMetadataVariableDefaultFloat(id, index);
    }

    pub fn variableDefaultInt(id: i32, index: i32) i32 {
        return c.fnGetMetadataVariableDefaultIntEnum(id, index);
    }

    pub fn variableMinFloat(id: i32, index: i32) f32 {
        return c.fnGetMetadataVariableMinFloat(id, index);
    }

    pub fn variableMaxFloat(id: i32, index: i32) f32 {
        return c.fnGetMetadataVariableMaxFloat(id, index);
    }

    pub fn nodeLookupCount(id: i32) i32 {
        return c.fnGetMetadataNodeLookupCount(id);
    }

    pub fn nodeLookupName(id: i32, index: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataNodeLookupName(id, index) orelse return null);
    }

    pub fn nodeLookupDimensionIdx(id: i32, index: i32) ?Dimension {
        const d = c.fnGetMetadataNodeLookupDimensionIdx(id, index);
        return if (d < 0 or d > 3) null else @enumFromInt(d);
    }

    pub fn nodeLookupDescription(id: i32, index: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataNodeLookupDescription(id, index) orelse return null);
    }

    pub fn hybridCount(id: i32) i32 {
        return c.fnGetMetadataHybridCount(id);
    }

    pub fn hybridName(id: i32, index: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataHybridName(id, index) orelse return null);
    }

    pub fn hybridDimensionIdx(id: i32, index: i32) ?Dimension {
        const d = c.fnGetMetadataHybridDimensionIdx(id, index);
        return if (d < 0 or d > 3) null else @enumFromInt(d);
    }

    pub fn hybridDescription(id: i32, index: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataHybridDescription(id, index) orelse return null);
    }

    pub fn hybridDefault(id: i32, index: i32) f32 {
        return c.fnGetMetadataHybridDefault(id, index);
    }

    pub fn groupCount(id: i32) i32 {
        return c.fnGetMetadataGroupCount(id);
    }

    pub fn groupName(id: i32, index: i32) ?[:0]const u8 {
        return std.mem.span(c.fnGetMetadataGroupName(id, index) orelse return null);
    }
};

test "metadata count is positive" {
    try std.testing.expect(Metadata.count() > 0);
}

test "node round-trip" {
    const node = try Node.fromName("Simplex");
    defer node.deinit();
    const id = node.metadataId();
    try std.testing.expect(id >= 0);
    try std.testing.expect(Metadata.name(id) != null);
}

test "genUniformGrid2D output" {
    const node = try Node.fromName("Simplex");
    defer node.deinit();
    var output: [16 * 16]f32 = undefined;
    const mm = node.genUniformGrid2D(&output, 16, 16, .{}).?;
    try std.testing.expect(mm.min <= mm.max);
    try std.testing.expect(mm.min >= -2.0);
    try std.testing.expect(mm.max <= 2.0);
}

test "NodeType enum count matches metadata" {
    const fields = @typeInfo(NodeType).@"enum".fields;
    try std.testing.expectEqual(fields.len, @as(usize, @intCast(Metadata.count())));
}

test "all NodeType variants create valid nodes" {
    inline for (@typeInfo(NodeType).@"enum".fields) |field| {
        const node = try Node.fromType(@enumFromInt(field.value));
        defer node.deinit();
        try std.testing.expectEqual(@as(i32, @intCast(field.value)), node.metadataId());
    }
}

test "fromType matches fromName" {
    const by_type = try Node.fromType(.simplex);
    defer by_type.deinit();
    const by_name = try Node.fromName("Simplex");
    defer by_name.deinit();
    try std.testing.expectEqual(by_type.metadataId(), by_name.metadataId());
}

test "setEnum works with parameter enums" {
    const node = try Node.fromType(.cellular_distance);
    defer node.deinit();
    try node.setEnum(0, DistanceFunction.euclidean);
    try node.setEnum(1, CellularReturnType.index0);
}

test "named index enums work with setters" {
    const simplex = try Node.fromType(.simplex);
    defer simplex.deinit();

    const fractal = try Node.fromType(.fractal_fbm);
    defer fractal.deinit();

    // Named variable indices
    try fractal.setInt(FractalFBm.Var.octaves, 5);
    try fractal.setFloat(FractalFBm.Var.lacunarity, 2.0);

    // Named source index
    try fractal.setSource(FractalFBm.Source.source, simplex);

    // Named hybrid index
    try fractal.setHybridFloat(FractalFBm.Hybrid.gain, 0.6);
    try fractal.setHybridFloat(FractalFBm.Hybrid.weighted_strength, 0.1);

    // Raw integers still work (backward compatibility)
    try fractal.setInt(0, 4);
    try fractal.setSource(0, simplex);
    try fractal.setHybridFloat(0, 0.5);
}

test "unified set() dispatches correctly" {
    const simplex = try Node.fromType(.simplex);
    defer simplex.deinit();

    const fractal = try Node.fromType(.fractal_fbm);
    defer fractal.deinit();

    // variable + integer → setInt
    try fractal.set(FractalFBm.Var.octaves, 5);

    // variable + f32 → setFloat
    try fractal.set(FractalFBm.Var.lacunarity, 2.0);

    // source + Node → setSource
    try fractal.set(FractalFBm.Source.source, simplex);

    // hybrid + f32 → setHybridFloat
    try fractal.set(FractalFBm.Hybrid.gain, 0.6);
    try fractal.set(FractalFBm.Hybrid.weighted_strength, 0.1);

    // hybrid + Node → setHybridSource
    const value_node = try Node.fromType(.value);
    defer value_node.deinit();
    try fractal.set(FractalFBm.Hybrid.gain, value_node);

    // variable + enum → setEnum
    const cell = try Node.fromType(.cellular_distance);
    defer cell.deinit();
    try cell.set(CellularDistance.Var.distance_function, DistanceFunction.manhattan);
}

test "named index enums via NodeParams" {
    const P = NodeParams(.fractal_fbm);
    const simplex = try Node.fromType(.simplex);
    defer simplex.deinit();

    const fractal = try Node.fromType(.fractal_fbm);
    defer fractal.deinit();

    try fractal.setInt(P.Var.octaves, 5);
    try fractal.setSource(P.Source.source, simplex);
    try fractal.setHybridFloat(P.Hybrid.gain, 0.6);
}

/// Converts a metadata name (e.g. "Feature Scale") to snake_case, appending a
/// dimension suffix (_x/_y/_z/_w) when dim >= 0.
fn metadataNameToSnakeCase(buf: []u8, name_str: [:0]const u8, dim: ?Dimension) []const u8 {
    var len: usize = 0;
    for (name_str) |ch| {
        if (len >= buf.len) break;
        buf[len] = if (ch == ' ') '_' else std.ascii.toLower(ch);
        len += 1;
    }
    if (dim) |d| {
        const suffixes = [_]u8{ 'x', 'y', 'z', 'w' };
        if (len + 2 <= buf.len) {
            buf[len] = '_';
            len += 1;
            buf[len] = suffixes[@intCast(@intFromEnum(d))];
            len += 1;
        }
    }
    return buf[0..len];
}

test "per-node Var enums match runtime metadata" {
    inline for (@typeInfo(NodeType).@"enum".fields) |field| {
        const node_type: NodeType = @enumFromInt(field.value);
        const id: i32 = @intCast(field.value);
        const S = NodeParams(node_type);

        if (@hasDecl(S, "Var")) {
            const VarEnum = S.Var;
            // Field count must match variable count
            const enum_fields = @typeInfo(VarEnum).@"enum".fields;
            const runtime_count: usize = @intCast(Metadata.variableCount(id));
            if (enum_fields.len != runtime_count) {
                std.debug.print("Var count mismatch for {s}: enum has {d}, runtime has {d}\n", .{
                    @tagName(node_type), enum_fields.len, runtime_count,
                });
                return error.CountMismatch;
            }

            inline for (enum_fields) |ef| {
                const idx: i32 = @intCast(ef.value);
                const meta_name = Metadata.variableName(id, idx) orelse {
                    std.debug.print("Missing variable name for {s}[{d}]\n", .{ @tagName(node_type), idx });
                    return error.MissingName;
                };
                const dim = Metadata.variableDimensionIdx(id, idx);
                var buf: [128]u8 = undefined;
                const expected = metadataNameToSnakeCase(&buf, meta_name, dim);
                if (!std.mem.eql(u8, expected, ef.name)) {
                    std.debug.print("Var name mismatch for {s}[{d}]: expected '{s}', got '{s}'\n", .{
                        @tagName(node_type), idx, expected, ef.name,
                    });
                    return error.NameMismatch;
                }
            }
        } else {
            // No Var enum — runtime should have 0 variables
            if (Metadata.variableCount(id) != 0) {
                std.debug.print("Expected Var enum for {s} (has {d} variables)\n", .{
                    @tagName(node_type), Metadata.variableCount(id),
                });
                return error.MissingEnum;
            }
        }
    }
}

test "per-node Source enums match runtime metadata" {
    inline for (@typeInfo(NodeType).@"enum".fields) |field| {
        const node_type: NodeType = @enumFromInt(field.value);
        const id: i32 = @intCast(field.value);
        const S = NodeParams(node_type);

        if (@hasDecl(S, "Source")) {
            const SrcEnum = S.Source;
            const enum_fields = @typeInfo(SrcEnum).@"enum".fields;
            const runtime_count: usize = @intCast(Metadata.nodeLookupCount(id));
            if (enum_fields.len != runtime_count) {
                std.debug.print("Source count mismatch for {s}: enum has {d}, runtime has {d}\n", .{
                    @tagName(node_type), enum_fields.len, runtime_count,
                });
                return error.CountMismatch;
            }

            inline for (enum_fields) |ef| {
                const idx: i32 = @intCast(ef.value);
                const meta_name = Metadata.nodeLookupName(id, idx) orelse {
                    std.debug.print("Missing source name for {s}[{d}]\n", .{ @tagName(node_type), idx });
                    return error.MissingName;
                };
                const dim = Metadata.nodeLookupDimensionIdx(id, idx);
                var buf: [128]u8 = undefined;
                const expected = metadataNameToSnakeCase(&buf, meta_name, dim);
                if (!std.mem.eql(u8, expected, ef.name)) {
                    std.debug.print("Source name mismatch for {s}[{d}]: expected '{s}', got '{s}'\n", .{
                        @tagName(node_type), idx, expected, ef.name,
                    });
                    return error.NameMismatch;
                }
            }
        } else {
            if (Metadata.nodeLookupCount(id) != 0) {
                std.debug.print("Expected Source enum for {s} (has {d} lookups)\n", .{
                    @tagName(node_type), Metadata.nodeLookupCount(id),
                });
                return error.MissingEnum;
            }
        }
    }
}

test "per-node Hybrid enums match runtime metadata" {
    inline for (@typeInfo(NodeType).@"enum".fields) |field| {
        const node_type: NodeType = @enumFromInt(field.value);
        const id: i32 = @intCast(field.value);
        const S = NodeParams(node_type);

        if (@hasDecl(S, "Hybrid")) {
            const HybEnum = S.Hybrid;
            const enum_fields = @typeInfo(HybEnum).@"enum".fields;
            const runtime_count: usize = @intCast(Metadata.hybridCount(id));
            if (enum_fields.len != runtime_count) {
                std.debug.print("Hybrid count mismatch for {s}: enum has {d}, runtime has {d}\n", .{
                    @tagName(node_type), enum_fields.len, runtime_count,
                });
                return error.CountMismatch;
            }

            inline for (enum_fields) |ef| {
                const idx: i32 = @intCast(ef.value);
                const meta_name = Metadata.hybridName(id, idx) orelse {
                    std.debug.print("Missing hybrid name for {s}[{d}]\n", .{ @tagName(node_type), idx });
                    return error.MissingName;
                };
                const dim = Metadata.hybridDimensionIdx(id, idx);
                var buf: [128]u8 = undefined;
                const expected = metadataNameToSnakeCase(&buf, meta_name, dim);
                if (!std.mem.eql(u8, expected, ef.name)) {
                    std.debug.print("Hybrid name mismatch for {s}[{d}]: expected '{s}', got '{s}'\n", .{
                        @tagName(node_type), idx, expected, ef.name,
                    });
                    return error.NameMismatch;
                }
            }
        } else {
            if (Metadata.hybridCount(id) != 0) {
                std.debug.print("Expected Hybrid enum for {s} (has {d} hybrids)\n", .{
                    @tagName(node_type), Metadata.hybridCount(id),
                });
                return error.MissingEnum;
            }
        }
    }
}


