# Macrobenchmarks

Here are some programs that are written in a concurrent style and that may be suitable to convert to running on WasmFX:

## OCaml
* [eio library example projects](https://github.com/ocaml-multicore/eio/#example-applications)

## Go

* [ebiten examples](https://github.com/hajimehoshi/ebiten/tree/main/examples)
* [concurrent-raytracer-go](https://github.com/JoshElkind/concurrent-raytracer-go)

## Kotlin

* [compose-multiplatform](https://github.com/jetbrains/compose-multiplatform)

## C

* WAEIO [httpserver](https://github.com/wasmfx/waeio/tree/main/examples/httpserver), matches OCaml example from that benchmarking paper.
* Ezra's [ray tracer](https://github.com/wasmfx/fiber-c/tree/ray)
* nginx (big task, converting from non-blocking I/O to fiber-c; going to use Codex)
