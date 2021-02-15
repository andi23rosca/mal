const Builder = @import("std").build.Builder;
const LibExeObjStep = @import("std").build.LibExeObjStep;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exes = [_]*LibExeObjStep{
        b.addExecutable("step0_repl", "step0_repl.zig"),
        b.addExecutable("step1_read_print", "step1_read_print.zig"),
        // b.addExecutable("step2_eval", "step2_eval.zig"),
        // b.addExecutable("step3_env", "step3_env.zig"),
        // b.addExecutable("step4_if_fn_do", "step4_if_fn_do.zig"),
        // b.addExecutable("step5_tco", "step5_tco.zig"),
        // b.addExecutable("step6_file", "step6_file.zig"),
        // b.addExecutable("step7_quote", "step7_quote.zig"),
        // b.addExecutable("step8_macros", "step8_macros.zig"),
        // b.addExecutable("step9_try", "step9_try.zig"),
        // b.addExecutable("stepA_mal", "stepA_mal.zig"),
    };

    for (exes) |exe| {
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();
        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }
}
