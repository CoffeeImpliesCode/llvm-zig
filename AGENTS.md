# llvm-zig

Active Zig 0.16.0 bindings for LLVM and Clang C APIs, also used to learn LLVM. The build exports `llvm` and `clang` modules. Linux links LLVM 21 and libclang. `src/llvm-bindings.zig` and `src/clang.zig` are module roots; `src/core.zig`, `src/types.zig`, `src/orc.zig`, and related files mirror LLVM APIs. `examples/` contains `sum_module`, `factorial_module`, and `kaleidoscope`.

## Binding rules

- Consult upstream LLVM/Clang C headers or docs before binding changes. Match names, types, ownership, and errors. Pair every created LLVM object with its upstream disposal function.
- Keep `extern` declarations ABI-compatible. Compare C struct sizes and alignments with headers; add comptime assertions for new C struct layouts.
- Export new files from the correct module root and include them in root compile tests.
- Preserve platform linking: Linux uses `LLVM-21` and `clang`; macOS uses Homebrew's LLVM path.
- `devenv.nix` supplies Zig 0.16, LLVM 21, libclang, and `gate`. Declare dependencies there; run `direnv allow` after environment changes or use `devenv shell`.

## Commands

- `devenv shell` enters the pinned environment.
- `gate` runs the configured `zig-gate` command.
- `zig build test` runs Clang tests, then LLVM binding tests.
- `zig build -Dexamples=true` builds and installs all examples.
- `zig build -Dexamples=true kaleidoscope` runs that example. Other run steps: `sum_module`, `factorial_module`.

See `README.md` for consumer imports.
