/* stub: lets sim/wasm.c build with wasi-sdk (clang --target=wasm32-wasi) instead of Emscripten */
#pragma once
#define EMSCRIPTEN_KEEPALIVE __attribute__((visibility("default"), used))
