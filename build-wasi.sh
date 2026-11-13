#!/usr/bin/env bash
# Rebuilds site/pip.wasm from the Pip-KeyPet repo with wasi-sdk (no Emscripten needed).
# Usage: tools/build-wasi.sh /path/to/Pip-KeyPet /path/to/wasi-sdk-25.0-x86_64-linux
# wasi-sdk: https://github.com/WebAssembly/wasi-sdk/releases (pick your OS). Needs cmake + ninja.
set -euo pipefail
R=$(cd "$1" && pwd); SDK=$(cd "$2" && pwd); HERE=$(cd "$(dirname "$0")" && pwd); B=${TMPDIR:-/tmp}/pipwasm
mkdir -p "$B/cm"
cat > "$B/cm/CMakeLists.txt" <<CM
cmake_minimum_required(VERSION 3.16)
project(pipwasm C ASM)
set(LV_BUILD_CONF_PATH $R/sim/lv_conf.h CACHE PATH "" FORCE)
set(CONFIG_LV_BUILD_DEMOS OFF CACHE BOOL "" FORCE)
set(CONFIG_LV_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(CONFIG_LV_USE_THORVG_INTERNAL OFF CACHE BOOL "" FORCE)
add_subdirectory($R/third_party/lvgl lvgl)
file(GLOB THEME_FONTS $R/ui/fonts/font_*_*.c)
foreach(f face imu pip doodle pet shell apps voice profile theme phone mic maze)
  list(APPEND UI $R/ui/\${f}.c)
endforeach()
add_executable(pip $R/sim/wasm.c $R/sim/fakephone.c \${UI} \${THEME_FONTS})
target_include_directories(pip PRIVATE $R/ui $HERE)
target_compile_options(pip PRIVATE -O2)
target_link_libraries(pip PRIVATE lvgl m)
set_target_properties(pip PROPERTIES SUFFIX ".wasm")
CM
(cd "$R" && git submodule update --init --depth 1)
cmake -S "$B/cm" -B "$B/b" -G Ninja -DCMAKE_TOOLCHAIN_FILE="$SDK/share/cmake/wasi-sdk.cmake" -DWASI_SDK_PREFIX="$SDK" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-I$HERE -fvisibility=hidden -O2 -DNDEBUG" \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,--export-dynamic -Wl,-z,stack-size=1048576 -Wl,--initial-memory=33554432 -Wl,--max-memory=1073741824 -Wl,--export-memory -Wl,--no-entry"
cmake --build "$B/b"
cp "$B/b/pip.wasm" "$HERE/../site/pip.wasm"
echo "done: site/pip.wasm"
