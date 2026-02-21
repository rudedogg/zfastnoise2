const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const strict_fp = b.option(bool, "strict_fp", "Use strict floating point (disable fast-math and FMA)") orelse false;

    const Linkage = enum { static, dynamic };
    const linkage = b.option(Linkage, "linkage", "Library linkage") orelse .static;

    const fastnoise2 = b.dependency("fastnoise2", .{});
    const fastsimd = b.dependency("fastsimd", .{});

    // Create module and library
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    const lib = b.addLibrary(.{
        .name = "FastNoise2",
        .linkage = switch (linkage) {
            .static => .static,
            .dynamic => .dynamic,
        },
        .root_module = mod,
    });

    // Include paths (shared across all modules)
    const include_paths = [_]std.Build.LazyPath{
        fastnoise2.path("include"),
        fastsimd.path("include"),
        fastsimd.path("dispatch"),
        fastnoise2.path("src"),
    };
    for (&include_paths) |p| {
        mod.addIncludePath(p);
    }

    // Compile definitions
    mod.addCMacro("FASTNOISE2_VERSION", "\"1.1.0\"");
    mod.addCMacro("FASTSIMD_DISPATCH_CLASS", "1");
    switch (linkage) {
        .static => {
            mod.addCMacro("FASTNOISE_STATIC_LIB", "1");
            mod.addCMacro("FASTSIMD_STATIC_LIB", "1");
        },
        .dynamic => {
            mod.addCMacro("FASTNOISE_EXPORT", "1");
            mod.addCMacro("FASTSIMD_EXPORT", "1");
        },
    }

    // Core C++ sources
    const core_flags: []const []const u8 = &.{"-std=c++17"};
    mod.addCSourceFile(.{ .file = fastsimd.path("src/FastSIMD.cpp"), .flags = core_flags });
    mod.addCSourceFile(.{ .file = fastnoise2.path("src/FastNoise/Metadata.cpp"), .flags = core_flags });
    mod.addCSourceFile(.{ .file = fastnoise2.path("src/FastNoise/SmartNode.cpp"), .flags = core_flags });
    mod.addCSourceFile(.{ .file = fastnoise2.path("src/FastNoise/FastNoise_C.cpp"), .flags = core_flags });

    // SIMD dispatch
    const wf = b.addWriteFiles();
    mod.addIncludePath(wf.getDirectory());

    const FeatureLevel = struct { name: []const u8 };

    const cpu_arch = target.result.cpu.arch;
    const levels: []const FeatureLevel = switch (cpu_arch) {
        .x86_64, .x86 => &.{
            .{ .name = "SSE2" },
            .{ .name = "SSE41" },
            .{ .name = "AVX2" },
            .{ .name = "AVX512" },
        },
        .aarch64 => &.{
            .{ .name = "AARCH64" },
        },
        .arm => &.{
            .{ .name = "NEON" },
        },
        .wasm32, .wasm64 => &.{
            .{ .name = "WASM" },
        },
        else => &.{},
    };

    // Build feature list string for config header
    var feature_list: []const u8 = "";
    for (levels) |level| {
        feature_list = b.fmt("{s},FastSIMD::FeatureSet::{s}\n", .{ feature_list, level.name });
    }

    // Generate config header
    _ = wf.add("FastSIMD/FastSIMD_FastNoise_config.h", b.fmt(
        "#pragma once\n\n" ++
            "#include <FastSIMD/Utility/ArchDetect.h>\n" ++
            "#include <FastSIMD/Utility/FeatureSetList.h>\n\n" ++
            "namespace FastSIMD {{\n" ++
            "namespace FastSIMD_FastNoise {{\n" ++
            "using CompiledFeatureSets = FeatureSetList<0\n" ++
            "{s}>;\n" ++
            "}}\n" ++
            "}}\n",
        .{feature_list},
    ));

    // Common dispatch C flags (non-target-related)
    var common_flags_list: std.ArrayList([]const u8) = .empty;
    common_flags_list.ensureTotalCapacity(b.allocator, 8) catch @panic("OOM");
    common_flags_list.appendAssumeCapacity("-std=c++17");
    common_flags_list.appendAssumeCapacity("-fno-stack-protector");
    common_flags_list.appendAssumeCapacity("-Wno-nan-infinity-disabled");
    common_flags_list.appendAssumeCapacity("-DFASTSIMD_LIBRARY_NAME=FastSIMD_FastNoise");
    if (!strict_fp) common_flags_list.appendAssumeCapacity("-ffast-math");
    const dispatch_flags = common_flags_list.items;

    // Generate and compile per-SIMD dispatch files
    for (levels) |level| {
        const dispatch_content = b.fmt(
            "#define FASTSIMD_MAX_FEATURE_SET {s}\n" ++
                "#include <FastSIMD/Utility/ArchDetect.h>\n" ++
                "#if 1\n" ++
                "#include <FastSIMD/FastSIMD_FastNoise_config.h>\n" ++
                "#include <impl/DispatchClassImpl.h>\n" ++
                "#include <FastNoise/FastSIMD_Build.inl>\n" ++
                "#endif\n",
            .{level.name},
        );

        const dispatch_file = wf.add(
            b.fmt("FastSIMD_FastNoise_{s}.cpp", .{level.name}),
            dispatch_content,
        );

        // Create a target with appropriate CPU features for this SIMD level
        var query = target.query;
        if (cpu_arch == .x86_64 or cpu_arch == .x86) {
            const x86 = std.Target.x86;
            if (std.mem.eql(u8, level.name, "SSE41")) {
                query.cpu_features_add = x86.featureSet(&.{.sse4_1});
            } else if (std.mem.eql(u8, level.name, "AVX2")) {
                query.cpu_features_add = if (!strict_fp)
                    x86.featureSet(&.{ .avx2, .fma })
                else
                    x86.featureSet(&.{.avx2});
            } else if (std.mem.eql(u8, level.name, "AVX512")) {
                query.cpu_features_add = if (!strict_fp)
                    x86.featureSet(&.{ .avx512f, .avx512dq, .avx512vl, .avx512bw, .evex512, .fma })
                else
                    x86.featureSet(&.{ .avx512f, .avx512dq, .avx512vl, .avx512bw, .evex512 });
            }
            // SSE2 is baseline for x86_64; no extra features needed

            // Explicitly disable FMA when strict_fp is requested
            if (strict_fp and (std.mem.eql(u8, level.name, "AVX2") or std.mem.eql(u8, level.name, "AVX512"))) {
                query.cpu_features_sub = x86.featureSet(&.{.fma});
            }
        }
        const level_target = b.resolveTargetQuery(query);

        // Create a separate module for this dispatch level
        const dispatch_mod = b.createModule(.{
            .target = level_target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        });

        // Add include paths
        for (&include_paths) |p| {
            dispatch_mod.addIncludePath(p);
        }
        dispatch_mod.addIncludePath(wf.getDirectory());

        // Add compile definitions
        dispatch_mod.addCMacro("FASTNOISE2_VERSION", "\"1.1.0\"");
        dispatch_mod.addCMacro("FASTSIMD_DISPATCH_CLASS", "1");
        switch (linkage) {
            .static => {
                dispatch_mod.addCMacro("FASTNOISE_STATIC_LIB", "1");
                dispatch_mod.addCMacro("FASTSIMD_STATIC_LIB", "1");
            },
            .dynamic => {
                dispatch_mod.addCMacro("FASTNOISE_EXPORT", "1");
                dispatch_mod.addCMacro("FASTSIMD_EXPORT", "1");
            },
        }

        // Add dispatch source file
        dispatch_mod.addCSourceFile(.{
            .file = dispatch_file,
            .flags = dispatch_flags,
        });

        // Compile as object and add to library
        const obj = b.addObject(.{
            .name = b.fmt("fn2_{s}", .{level.name}),
            .root_module = dispatch_mod,
        });
        lib.addObjectFile(obj.getEmittedBin());
    }

    // Idiomatic Zig wrapper module
    const zfastnoise2 = b.addModule("zfastnoise2", .{
        .root_source_file = b.path("src/zfastnoise2.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    const options = b.addOptions();
    options.addOption(bool, "static_lib", linkage == .static);
    zfastnoise2.addOptions("zfastnoise2_options", options);
    zfastnoise2.linkLibrary(lib);

    // Tests
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/zfastnoise2.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        }),
    });
    lib_tests.root_module.addOptions("zfastnoise2_options", options);
    lib_tests.root_module.linkLibrary(lib);
    const run_tests = b.addRunArtifact(lib_tests);
    b.step("test", "Run unit tests").dependOn(&run_tests.step);

    // Install headers and artifact
    // Patch FastNoise_C.h: upstream uses `bool` without #include <stdbool.h>
    lib.installHeader(fastnoise2.path("include/FastNoise/FastNoise_C.h"), "FastNoise/FastNoise_C_impl.h");
    lib.installHeader(wf.add("FastNoise_C.h",
        "#include <stdbool.h>\n" ++
            "#include \"FastNoise_C_impl.h\"\n",
    ), "FastNoise/FastNoise_C.h");
    lib.installHeader(fastnoise2.path("include/FastNoise/FastNoise.h"), "FastNoise/FastNoise.h");
    lib.installHeader(fastnoise2.path("include/FastNoise/Metadata.h"), "FastNoise/Metadata.h");
    lib.installHeadersDirectory(fastnoise2.path("include/FastNoise/Generators"), "FastNoise/Generators", .{});
    lib.installHeadersDirectory(fastnoise2.path("include/FastNoise/Utility"), "FastNoise/Utility", .{});
    lib.installHeadersDirectory(fastsimd.path("include/FastSIMD/Utility"), "FastSIMD/Utility", .{});
    lib.installHeader(fastsimd.path("include/FastSIMD/DispatchClass.h"), "FastSIMD/DispatchClass.h");
    b.installArtifact(lib);
}
