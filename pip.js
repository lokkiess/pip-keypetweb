/* Loader for pip.wasm (built with wasi-sdk). Gives the page the same API the Emscripten build had:
   M._sim_*(), M.HEAPU8, M.HEAPU16, M.UTF8ToString(). */
export default async function createPip(opts = {}) {
  const loc = opts.locateFile ? opts.locateFile('pip.wasm') : 'pip.wasm';
  let mem;
  const dec = new TextDecoder();
  let outBuf = '';
  const wasi = {
    args_sizes_get: (argc, size) => { const v = new DataView(mem.buffer); v.setUint32(argc, 0, true); v.setUint32(size, 0, true); return 0; },
    args_get: () => 0,
    fd_close: () => 0,
    fd_seek: () => 70, // ESPIPE: not seekable
    fd_write: (fd, iovs, n, nwritten) => {
      const v = new DataView(mem.buffer);
      let total = 0;
      for (let i = 0; i < n; i++) {
        const p = v.getUint32(iovs + i * 8, true), len = v.getUint32(iovs + i * 8 + 4, true);
        outBuf += dec.decode(new Uint8Array(mem.buffer, p, len));
        total += len;
      }
      const nl = outBuf.lastIndexOf('\n');
      if (nl >= 0) { (fd === 2 ? console.warn : console.log)(outBuf.slice(0, nl)); outBuf = outBuf.slice(nl + 1); }
      v.setUint32(nwritten, total, true);
      return 0;
    },
    proc_exit: (c) => { throw new Error('pip.wasm exited with code ' + c); },
  };
  const imports = { wasi_snapshot_preview1: wasi };
  let inst;
  if (opts.wasmBinary) {
    inst = (await WebAssembly.instantiate(opts.wasmBinary, imports)).instance;
  } else {
    const url = new URL(loc, import.meta.url);
    const resp = await fetch(url);
    if (!resp.ok) throw new Error('cannot load ' + url + ': ' + resp.status);
    try { inst = (await WebAssembly.instantiateStreaming(resp.clone(), imports)).instance; }
    catch { inst = (await WebAssembly.instantiate(await resp.arrayBuffer(), imports)).instance; }
  }
  mem = inst.exports.memory;
  const M = {
    get HEAPU8() { return new Uint8Array(mem.buffer); },
    get HEAPU16() { return new Uint16Array(mem.buffer); },
    UTF8ToString(p) {
      const u8 = new Uint8Array(mem.buffer);
      let e = p;
      while (u8[e]) e++;
      return dec.decode(u8.subarray(p, e));
    },
  };
  for (const [k, f] of Object.entries(inst.exports)) if (k.startsWith('sim_')) M['_' + k] = f;
  return M;
}
