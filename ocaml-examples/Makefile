.PHONY: all $(BENCHMARKS)

BENCHMARKS= itersum treesum pi scheduler c10m

all: $(BENCHMARKS)

$(BENCHMARKS): %: bin/%.byte bin/%_wasmfx.js bin/%_cps.js

bin/%.byte: bin/%.ml
	ocamlfind ocamlc -package js_of_ocaml -package js_of_ocaml-ppx -linkpkg -o $@ $<

bin/%_wasmfx.js: bin/%.byte
	~/wasmfx/js_of_ocaml/_build/default/compiler/bin-wasm_of_ocaml/wasm_of_ocaml.exe --effects=native -o $@ $<

bin/%_cps.js: bin/%.byte
	~/wasmfx/js_of_ocaml/_build/default/compiler/bin-wasm_of_ocaml/wasm_of_ocaml.exe --effects=cps -o $@ $<

.PHONY: clean
clean:
	rm -f bin/*.cmi
	rm -f bin/*.cmo
	rm -f bin/*.cmx
	rm -f bin/*.byte
	rm -f bin/*.js
	rm -rf bin/*.assets