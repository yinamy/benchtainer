# The generated javascript files must be run from inside the bin directory
cd bin

# run hyperfine on the two binaries on v8
#hyperfine --warmup 1 -L mode cps,wasmfx "/opt/wasmfx/v8/v8/out/x64.release/d8 --experimental-wasm-wasmfx -e \"load('../load.mjs');load('scheduler_{mode}.js');\""

# actual benchmarking commands
hyperfine --warmup 1 --runs 3 --export-json ../results/ocaml_wasmfx.json -L benchmark itersum,treesum,pi -L engine d8 -L style wasmfx ../run-scripts/{benchmark}_{engine}_wasmfx.sh

hyperfine --warmup 1 --runs 3 --export-json ../results/ocaml_cps.json -L benchmark itersum,treesum,pi -L engine d8 -L style cps ../run-scripts/{benchmark}_{engine}_cps.sh