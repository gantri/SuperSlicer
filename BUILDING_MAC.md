# Building SuperSlicer on macOS (Gantri fork)

Verified on: macOS 26 (Apple Silicon), Apple clang 21, August 2026.

This fork carries patches so the 2023-era codebase builds with modern
toolchains out of the box. Vendored dependency fixes live in `deps/*/*.patch`
and are applied automatically during the dependency build — you should never
need to edit dependency sources by hand. If a future compiler breaks a
dependency again, add a hunk to the matching patch file instead.

## Prerequisites

1. **Xcode Command Line Tools**
   ```sh
   xcode-select --install
   ```
2. **Homebrew packages**
   ```sh
   brew install zstd
   ```
3. **CMake 3.x — required for the dependency build.**
   CMake 4 refuses the old `cmake_minimum_required` declarations inside the
   *downloaded* dependency sources (Boost, libpng, ...), which we cannot patch
   before they are configured. Any CMake 3.13–3.31 works. If Homebrew only
   offers CMake 4, use the official portable binary:
   ```sh
   curl -LO https://github.com/Kitware/CMake/releases/download/v3.31.7/cmake-3.31.7-macos-universal.tar.gz
   tar xzf cmake-3.31.7-macos-universal.tar.gz
   export PATH="$PWD/cmake-3.31.7-macos-universal/CMake.app/Contents/bin:$PATH"
   ```
   (The main application configures fine with CMake 4 — e.g. from CLion —
   only the `deps/` step needs 3.x.)

## 1. Clone and fetch submodules

```sh
git clone https://github.com/gantri/SuperSlicer.git
cd SuperSlicer
git submodule update --init   # resources/profiles + src/ArcWelderLib
```

## 2. Build the dependencies (once, ~1 hour)

```sh
export LIBRARY_PATH="$LIBRARY_PATH:$(brew --prefix zstd)/lib"
mkdir -p deps/build && cd deps/build
cmake .. -DCMAKE_OSX_DEPLOYMENT_TARGET=11.3
make -j"$(sysctl -n hw.ncpu)"

# wxWidgets quirk: the build looks for the scintilla lib under another name
cp destdir/usr/local/lib/libwxscintilla-3.1.a \
   destdir/usr/local/lib/libwx_osx_cocoau_scintilla-3.1.a
cd ../..
```

You only redo this when a dependency recipe under `deps/` changes.

## 3. Build the slicer

```sh
mkdir -p build && cd build
cmake .. -DCMAKE_PREFIX_PATH="$PWD/../deps/build/destdir/usr/local" \
         -DCMAKE_OSX_DEPLOYMENT_TARGET=11.3 \
         -DSLIC3R_STATIC=1
make -j"$(sysctl -n hw.ncpu)" Slic3r
```

The binary lands at `build/src/superslicer`. Run it with no arguments to get
the GUI, or use the CLI, e.g.:

```sh
build/src/superslicer --export-gcode part.stl --output part.gcode
```

Incremental rebuilds after code changes take a couple of minutes at most.

## CLion setup

Open the repo root as a CMake project. In *Settings → Build, Execution,
Deployment → CMake* set **CMake options** to:

```
-DCMAKE_PREFIX_PATH=<repo>/deps/build/destdir/usr/local -DSLIC3R_STATIC=1 -DCMAKE_OSX_DEPLOYMENT_TARGET=11.3
```

(replace `<repo>` with the absolute repo path), build type `RelWithDebInfo`,
and build the `Slic3r` target. The bundled CMake 4 / Ninja defaults are fine
for the app — the deps must already be built via step 2.

## Troubleshooting

- **`Compatibility with CMake < 3.5 has been removed`** during step 2: you are
  running CMake 4 — put a CMake 3.x first in `PATH` (see prerequisites).
- **Linker can't find `libwx_osx_cocoau_scintilla`**: you skipped the `cp`
  at the end of step 2.
- **A dependency fails to compile with a brand-new Xcode**: extend that
  dependency's patch file in `deps/<Name>/` (see `deps/PNG/PNG.patch` for the
  pattern) — recipes apply patches with `git apply` right after download.
