# This makefile does the substitutions in the config file for fiber-c
# very dumb strat but it gets the job done

CONFIG=../fiber-c/make.config
include ${CONFIG}

dump:
	@echo wasm_opt = $(WASM_OPT)
	@echo wasm_opt_flags = $(WASM_OPT_FLAGS)
	@echo asyncify = $(ASYNCIFY)
	@echo asyncify_flags = $(ASYNCIFY_FLAGS)
	@echo wasm_merge = $(WASM_MERGE)
	@echo wasm_merge_flags = $(WASM_MERGE_FLAGS)
	@echo wasicc = $(WASICC)
	@echo wasi_flags = $(WASI_FLAGS)
	@echo wasm_interp = $(WASM_INTERP)
	@echo wasmfxtime = $(WASMTIME)
	@echo wasmtime = $(WASMTIME_SWITCH)
