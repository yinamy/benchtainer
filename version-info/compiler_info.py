#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///

"""This script dumps: 
        1) Version information for the compiler tools installed in this container
        2) The flags we use for these tools in the fiber-c build process
    into /results/compiler_info.json.
    
    Run with ``python3 compiler_info.py`` from the version-info directory."""

import subprocess
import json

# Run makefile which dumps the compiler info
data = subprocess.check_output(["make", "-f", "compiler_info.mk"], text=True)

# Process this info into a dict
config = {}

for line in data.splitlines():
    line = line.strip()
    key, value = line.split("=", 1)
    config[key.strip()] = value.strip()

# Get version numbers of things
wasm_opt_ver = subprocess.check_output([config["wasm_opt"], "--version"]).decode().split('\n', 1)[0]
wasm_merge_ver = subprocess.check_output([config["wasm_merge"], "--version"]).decode().split('\n', 1)[0]
wasicc_ver = subprocess.check_output([config["wasicc"], "-v"], stderr=subprocess.STDOUT).decode().split('\n', 1)[0]
wasm_interp_ver = "TODO: figure out how to get version" #subprocess.check_output([config["wasm_interp"],"-v", "-e", "\"\""]).decode().split('\n', 1)[0]
wasmfxtime_ver = subprocess.check_output([config["wasmfxtime"], "--version"]).decode().split('\n', 1)[0]
# and this is wasmtime
# wasmtime_ver = subprocess.check_output([config["wasmtime"], "--version"]).decode().split('\n', 1)[0]

# Write this stuff to a json
with open("../results/compiler_info.json", "w") as f:
    json.dump({
        "wasm_opt_ver" : wasm_opt_ver,
        "wasm_opt_flags" : config["wasm_opt_flags"],
        "asyncify_flags" : config["asyncify_flags"],
        "wasm_merge_ver" : wasm_merge_ver,
        "wasm_merge_flags" : config["wasm_merge_flags"],
        "wasicc_ver" : wasicc_ver,
        "wasicc_flags" : config["wasi_flags"],
        "wasm_interp_ver" : wasm_interp_ver,
        "wasmfxtime_ver" : wasmfxtime_ver,
        #"wasmtime_ver" : wasmtime_ver,
    }, f)