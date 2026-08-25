# llvm-zig

This active Zig 0.16.0 project provides bindings for the LLVM and Clang C APIs.
It is also a learning project for LLVM compiler infrastructure. The build exports
modules named `llvm` and `clang`. Linux builds link LLVM 21 and libclang.

## Repository

- `src/llvm-bindings.zig` exports the LLVM binding modules and contains root tests.
- `src/clang.zig` exports bindings from `src/clang/`.
- `src/core.zig`, `src/types.zig`, `src/orc.zig`, and related files mirror LLVM APIs.
- `examples/` contains `sum_module`, `factorial_module`, and `kaleidoscope`.
- `build.zig` defines both modules, optional examples, and the custom test runner.
- `build.zig.zon` requires Zig 0.16.0 and pins the test-runner dependency.
- `devenv.nix` supplies Zig 0.16, LLVM 21, libclang, and the `gate` command.
- `README.md` documents consumer imports for the `llvm` and `clang` modules.

## Local rules

- Consult upstream LLVM and Clang C API headers or documentation before changing bindings.
- Match upstream names, types, ownership, error values, and disposal semantics.
- Keep `extern` declarations ABI-compatible. Verify C structure sizes and alignments against headers.
- Add comptime size and alignment assertions when a binding introduces a C structure layout.
- Pair created LLVM objects with their upstream disposal functions.
- Export new binding files from the applicable root module and include them in root compile tests.
- Preserve platform linking: Linux uses `LLVM-21` and `clang`; macOS uses Homebrew's LLVM path.

## Commands

- `devenv shell` loads the pinned Zig and LLVM development environment.
- `gate` runs the configured `zig-gate` command inside the devenv shell.
- `zig build test` runs the Clang tests, then the LLVM binding tests.
- `zig build -Dexamples=true` builds and installs all three examples.
- `zig build -Dexamples=true kaleidoscope` runs an example. The other run steps are
  `sum_module` and `factorial_module`.

## NixOS, Development Environment & Shared Notes

- The host is NixOS. Never install system or development libraries imperatively.
- Declare Zig, LLVM, Clang, headers, runtime libraries, and development tools in `devenv.nix`.
- `devenv.nix` provides Zig 0.16, LLVM 21, libclang, and `gate`. Use its direnv/devenv environment. Run `direnv allow` after environment changes and `devenv shell` for one-off shells.
- Store durable project architecture, design, protocol, and experiment notes under `docs/`.
- Store cross-project or private agent handoff notes in `~/.agents/agent-notes/`. Never commit those notes.
