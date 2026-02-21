const std = @import("std");
const build_options = @import("zfastnoise2_options");

pub const c = @cImport({
    if (build_options.static_lib) {
        @cDefine("FASTNOISE_STATIC_LIB", "1");
    }
    @cInclude("FastNoise/FastNoise_C.h");
});

const max_feature_set = ~@as(c_uint, 0);

pub const MinMax = struct { min: f32, max: f32 };

pub const Grid2D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    x_step: f32 = 0.01,
    y_step: f32 = 0.01,
    seed: i32 = 1337,
};

pub const Grid3D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    z_offset: f32 = 0,
    x_step: f32 = 0.01,
    y_step: f32 = 0.01,
    z_step: f32 = 0.01,
    seed: i32 = 1337,
};

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
};

pub const Tileable2D = struct {
    x_step: f32 = 0.01,
    y_step: f32 = 0.01,
    seed: i32 = 1337,
};

pub const PosArray2D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    seed: i32 = 1337,
};

pub const PosArray3D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    z_offset: f32 = 0,
    seed: i32 = 1337,
};

pub const PosArray4D = struct {
    x_offset: f32 = 0,
    y_offset: f32 = 0,
    z_offset: f32 = 0,
    w_offset: f32 = 0,
    seed: i32 = 1337,
};

pub const Node = struct {
    handle: *anyopaque,

    pub fn fromEncoded(encoded: [*:0]const u8) error{DecodeFailed}!Node {
        return .{ .handle = c.fnNewFromEncodedNodeTree(encoded, max_feature_set) orelse return error.DecodeFailed };
    }

    pub fn fromMetadata(id: i32) error{InvalidId}!Node {
        return .{ .handle = c.fnNewFromMetadata(id, max_feature_set) orelse return error.InvalidId };
    }

    pub fn fromName(name: [*:0]const u8) error{NodeNotFound}!Node {
        const id = Metadata.idFromName(name) orelse return error.NodeNotFound;
        return .{ .handle = c.fnNewFromMetadata(id, max_feature_set) orelse return error.NodeNotFound };
    }

    pub fn deinit(self: Node) void {
        c.fnDeleteNodeRef(self.handle);
    }

    // Configuration

    pub fn setFloat(self: Node, variable_index: i32, value: f32) error{SetFailed}!void {
        if (!c.fnSetVariableFloat(self.handle, variable_index, value)) return error.SetFailed;
    }

    pub fn setInt(self: Node, variable_index: i32, value: i32) error{SetFailed}!void {
        if (!c.fnSetVariableIntEnum(self.handle, variable_index, value)) return error.SetFailed;
    }

    pub fn setSource(self: Node, lookup_index: i32, source: Node) error{SetFailed}!void {
        if (!c.fnSetNodeLookup(self.handle, lookup_index, source.handle)) return error.SetFailed;
    }

    pub fn setHybridSource(self: Node, index: i32, source: Node) error{SetFailed}!void {
        if (!c.fnSetHybridNodeLookup(self.handle, index, source.handle)) return error.SetFailed;
    }

    pub fn setHybridFloat(self: Node, index: i32, value: f32) error{SetFailed}!void {
        if (!c.fnSetHybridFloat(self.handle, index, value)) return error.SetFailed;
    }

    // Query

    pub fn activeFeatureSet(self: Node) c_uint {
        return c.fnGetActiveFeatureSet(self.handle);
    }

    pub fn metadataId(self: Node) i32 {
        return c.fnGetMetadataID(self.handle);
    }

    // Generation

    pub fn genUniformGrid2D(self: Node, output: []f32, x_count: i32, y_count: i32, opts: Grid2D) MinMax {
        std.debug.assert(x_count >= 0 and y_count >= 0);
        std.debug.assert(output.len >= @as(usize, @intCast(x_count)) * @as(usize, @intCast(y_count)));
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
            &mm,
        );
        return .{ .min = mm[0], .max = mm[1] };
    }

    pub fn genUniformGrid3D(self: Node, output: []f32, x_count: i32, y_count: i32, z_count: i32, opts: Grid3D) MinMax {
        std.debug.assert(x_count >= 0 and y_count >= 0 and z_count >= 0);
        std.debug.assert(output.len >= @as(usize, @intCast(x_count)) * @as(usize, @intCast(y_count)) * @as(usize, @intCast(z_count)));
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
            &mm,
        );
        return .{ .min = mm[0], .max = mm[1] };
    }

    pub fn genUniformGrid4D(self: Node, output: []f32, x_count: i32, y_count: i32, z_count: i32, w_count: i32, opts: Grid4D) MinMax {
        std.debug.assert(x_count >= 0 and y_count >= 0 and z_count >= 0 and w_count >= 0);
        std.debug.assert(output.len >= @as(usize, @intCast(x_count)) * @as(usize, @intCast(y_count)) * @as(usize, @intCast(z_count)) * @as(usize, @intCast(w_count)));
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
            &mm,
        );
        return .{ .min = mm[0], .max = mm[1] };
    }

    pub fn genPositionArray2D(self: Node, output: []f32, x_pos: []const f32, y_pos: []const f32, opts: PosArray2D) MinMax {
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
            &mm,
        );
        return .{ .min = mm[0], .max = mm[1] };
    }

    pub fn genPositionArray3D(self: Node, output: []f32, x_pos: []const f32, y_pos: []const f32, z_pos: []const f32, opts: PosArray3D) MinMax {
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
            &mm,
        );
        return .{ .min = mm[0], .max = mm[1] };
    }

    pub fn genPositionArray4D(self: Node, output: []f32, x_pos: []const f32, y_pos: []const f32, z_pos: []const f32, w_pos: []const f32, opts: PosArray4D) MinMax {
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
            &mm,
        );
        return .{ .min = mm[0], .max = mm[1] };
    }

    pub fn genTileable2D(self: Node, output: []f32, x_size: i32, y_size: i32, opts: Tileable2D) MinMax {
        std.debug.assert(x_size >= 0 and y_size >= 0);
        std.debug.assert(output.len >= @as(usize, @intCast(x_size)) * @as(usize, @intCast(y_size)));
        var mm: [2]f32 = undefined;
        c.fnGenTileable2D(
            self.handle,
            output.ptr,
            x_size,
            y_size,
            opts.x_step,
            opts.y_step,
            opts.seed,
            &mm,
        );
        return .{ .min = mm[0], .max = mm[1] };
    }

    pub fn genSingle2D(self: Node, x: f32, y: f32, seed: i32) f32 {
        return c.fnGenSingle2D(self.handle, x, y, seed);
    }

    pub fn genSingle3D(self: Node, x: f32, y: f32, z: f32, seed: i32) f32 {
        return c.fnGenSingle3D(self.handle, x, y, z, seed);
    }

    pub fn genSingle4D(self: Node, x: f32, y: f32, z: f32, w: f32, seed: i32) f32 {
        return c.fnGenSingle4D(self.handle, x, y, z, w, seed);
    }
};

pub const Metadata = struct {
    pub const VariableType = enum(c_int) {
        float = 0,
        int = 1,
        enum_value = 2,
    };

    pub fn count() i32 {
        return c.fnGetMetadataCount();
    }

    pub fn name(id: i32) ?[*:0]const u8 {
        return c.fnGetMetadataName(id);
    }

    pub fn idFromName(target: [*:0]const u8) ?i32 {
        const n = count();
        var i: i32 = 0;
        while (i < n) : (i += 1) {
            const node_name = c.fnGetMetadataName(i) orelse continue;
            if (std.mem.orderZ(u8, node_name, target) == .eq) return i;
        }
        return null;
    }

    pub fn description(id: i32) ?[*:0]const u8 {
        return c.fnGetMetadataDescription(id);
    }

    pub fn variableCount(id: i32) i32 {
        return c.fnGetMetadataVariableCount(id);
    }

    pub fn variableName(id: i32, index: i32) ?[*:0]const u8 {
        return c.fnGetMetadataVariableName(id, index);
    }

    pub fn variableType(id: i32, index: i32) ?VariableType {
        const t = c.fnGetMetadataVariableType(id, index);
        return if (t < 0 or t > @intFromEnum(VariableType.enum_value)) null else @enumFromInt(t);
    }

    pub fn variableDimensionIdx(id: i32, index: i32) i32 {
        return c.fnGetMetadataVariableDimensionIdx(id, index);
    }

    pub fn enumCount(id: i32, variable_index: i32) i32 {
        return c.fnGetMetadataEnumCount(id, variable_index);
    }

    pub fn enumName(id: i32, variable_index: i32, enum_index: i32) ?[*:0]const u8 {
        return c.fnGetMetadataEnumName(id, variable_index, enum_index);
    }

    pub fn variableDescription(id: i32, index: i32) ?[*:0]const u8 {
        return c.fnGetMetadataVariableDescription(id, index);
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

    pub fn nodeLookupName(id: i32, index: i32) ?[*:0]const u8 {
        return c.fnGetMetadataNodeLookupName(id, index);
    }

    pub fn nodeLookupDimensionIdx(id: i32, index: i32) i32 {
        return c.fnGetMetadataNodeLookupDimensionIdx(id, index);
    }

    pub fn nodeLookupDescription(id: i32, index: i32) ?[*:0]const u8 {
        return c.fnGetMetadataNodeLookupDescription(id, index);
    }

    pub fn hybridCount(id: i32) i32 {
        return c.fnGetMetadataHybridCount(id);
    }

    pub fn hybridName(id: i32, index: i32) ?[*:0]const u8 {
        return c.fnGetMetadataHybridName(id, index);
    }

    pub fn hybridDimensionIdx(id: i32, index: i32) i32 {
        return c.fnGetMetadataHybridDimensionIdx(id, index);
    }

    pub fn hybridDescription(id: i32, index: i32) ?[*:0]const u8 {
        return c.fnGetMetadataHybridDescription(id, index);
    }

    pub fn hybridDefault(id: i32, index: i32) f32 {
        return c.fnGetMetadataHybridDefault(id, index);
    }

    pub fn groupCount(id: i32) i32 {
        return c.fnGetMetadataGroupCount(id);
    }

    pub fn groupName(id: i32, index: i32) ?[*:0]const u8 {
        return c.fnGetMetadataGroupName(id, index);
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
    const mm = node.genUniformGrid2D(&output, 16, 16, .{});
    try std.testing.expect(mm.min <= mm.max);
    try std.testing.expect(mm.min >= -2.0);
    try std.testing.expect(mm.max <= 2.0);
}

