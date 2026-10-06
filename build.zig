const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // LLVM MODULE
    const llvm_module = b.addModule("llvm", .{
        .root_source_file = b.path("src/llvm-bindings.zig"),
        .target = target,
        .optimize = optimize,
    });

    llvm_module.addCMacro("_FILE_OFFSET_BITS", "64");
    llvm_module.addCMacro("__STDC_CONSTANT_MACROS", "");
    llvm_module.addCMacro("__STDC_FORMAT_MACROS", "");
    llvm_module.addCMacro("__STDC_LIMIT_MACROS", "");
    llvm_module.linkSystemLibrary("z", .{});

    if (target.result.abi != .msvc)
        llvm_module.link_libc = true
    else
        llvm_module.link_libcpp = true;

    switch (target.result.os.tag) {
        .linux => llvm_module.linkSystemLibrary("LLVM-21", .{}), // Ubuntu
        .macos => {
            llvm_module.addLibraryPath(.{
                .cwd_relative = "/opt/homebrew/opt/llvm/lib",
            });
            llvm_module.linkSystemLibrary("LLVM", .{
                .use_pkg_config = .no,
            });
        },
        else => llvm_module.linkSystemLibrary("LLVM", .{
            .use_pkg_config = .no,
        }),
    }

    // CLANG MODULE
    const clang_module = b.addModule("clang", .{
        .root_source_file = b.path("src/clang.zig"),
        .target = target,
        .optimize = optimize,
    });
    switch (target.result.os.tag) {
        .linux => clang_module.linkSystemLibrary("clang", .{}), // Ubuntu
        .macos => {
            clang_module.addLibraryPath(.{
                .cwd_relative = "/opt/homebrew/opt/llvm/lib",
            });
            clang_module.linkSystemLibrary("clang", .{
                .use_pkg_config = .no,
            });
        },
        else => clang_module.linkSystemLibrary("clang", .{
            .use_pkg_config = .no,
        }),
    }
    if (target.result.abi != .msvc)
        clang_module.link_libc = true
    else
        clang_module.link_libcpp = true;

    const examples = b.option(bool, "examples", "Build all examples [default: false]") orelse false;

    // zig-cov coverage (see zig-cov README): zig-gate --cov passes these
    const coverage = b.option(bool, "coverage", "Enable zig-cov") orelse false;
    const cov_rt = b.option([]const u8, "coverage-rt", "zig-cov-rt path") orelse null;
    if (examples) {
        buildExample(b, .{
            .filepath = "examples/sum_module.zig",
            .target = target,
            .optimize = optimize,
        });
        buildExample(b, .{
            .filepath = "examples/factorial_module.zig",
            .target = target,
            .optimize = optimize,
        });
        buildExample(b, .{
            .filepath = "examples/kaleidoscope.zig",
            .target = target,
            .optimize = optimize,
        });
    }

    buildTests(b, target, coverage, cov_rt);
}

fn buildExample(b: *std.Build, i: BuildInfo) void {
    const exe = b.addExecutable(.{
        .name = i.filename(),
        .root_module = b.createModule(.{
            .root_source_file = b.path(i.filepath),
            .target = i.target,
            .optimize = i.optimize,
        }),
    });
    exe.root_module.addImport("llvm", b.modules.get("llvm").?);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(i.filename(), b.fmt("Run the {s}", .{i.filename()}));
    run_step.dependOn(&run_cmd.step);
}

const BuildInfo = struct {
    filepath: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.splitSequence(u8, std.fs.path.basename(self.filepath), ".");
        return split.first();
    }
};

fn buildTests(b: *std.Build, target: std.Build.ResolvedTarget, coverage: bool, cov_rt: ?[]const u8) void {
    const custom_test_runner: std.Build.Step.Compile.TestRunner = .{
        .path = b.dependency("test_runner", .{}).path("test_runner.zig"),
        .mode = .simple,
    };
    const llvm_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/llvm-bindings.zig"),
            .target = target,
            .optimize = .Debug,
        }),
        .name = "llvm-tests",
        .test_runner = custom_test_runner,
    });
    const clang_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/clang.zig"),
            .target = target,
            .optimize = .Debug,
        }),
        .name = "clang-tests",
        .test_runner = custom_test_runner,
    });
    llvm_tests.root_module.addImport("llvm", b.modules.get("llvm").?);
    clang_tests.root_module.addImport("clang", b.modules.get("clang").?);

    if (coverage) {
        llvm_tests.use_llvm = true; // required: only the LLVM backend emits sancov counters
        llvm_tests.root_module.fuzz = true; // emits __sancov_cntrs + __sancov_pcs1
        llvm_tests.root_module.link_libc = true; // atexit handler writes the .zcov
        if (cov_rt) |p| llvm_tests.root_module.addObjectFile(.{ .cwd_relative = p });

        clang_tests.use_llvm = true; // required: only the LLVM backend emits sancov counters
        clang_tests.root_module.fuzz = true; // emits __sancov_cntrs + __sancov_pcs1
        clang_tests.root_module.link_libc = true; // atexit handler writes the .zcov
        if (cov_rt) |p| clang_tests.root_module.addObjectFile(.{ .cwd_relative = p });
    }

    llvm_tests.step.dependOn(&b.addRunArtifact(clang_tests).step);
    const run_llvm_tests = b.addRunArtifact(llvm_tests);
    const test_llvm_step = b.step("test", "Run LLVM-binding tests");
    test_llvm_step.dependOn(&run_llvm_tests.step);
}
