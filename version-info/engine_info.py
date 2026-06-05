#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///

"""This script dumps: 
        1) Version information for the three wasm engines installed in this container
        2) Their flags for running fiber-c benchmarks
    into /results/engine_info.json.
    
    Run with ``python3 engine_info.py`` from the version-info directory."""

import yaml
import subprocess
import json
import os

config = yaml.safe_load(open("../fiber-c/config.yml"))

# Set up environment variables for directory containing engines, defaulting to `/opt/wasmfx`` if not set
ENGINE_ROOT_DIR = os.getenv("ENGINE_ROOT_DIR", "/opt/wasmfx")

# Run --version on each engine and write the output to a file.
wasmtime_ver = subprocess.check_output([ENGINE_ROOT_DIR + config["WASMTIME_PATH"], "--version"])
wasmtime_ver = wasmtime_ver.decode().split('\n', 1)[0]

wizard_ver = subprocess.check_output([ENGINE_ROOT_DIR + config["WIZARD_PATH"], "--version"])
wizard_ver = wizard_ver.decode().split('\n', 1)[0]

v8_ver = subprocess.check_output(
    [ENGINE_ROOT_DIR + config["D8_PATH"]],
    input="quit()\n",
    text=True
)
v8_ver = v8_ver.split('\n', 1)[0]

# Write this stuff to a json
with open("../results/engine_info.json", "w") as f:
    json.dump({
        "wasmtime_ver": wasmtime_ver,
        "wasmtime_flags": config["WASMTIME_OPTIONS"],
        "wizard_ver": wizard_ver,
        "wizard_flags": config["WIZARD_OPTIONS"],
        "v8_ver": v8_ver,
        "v8_flags": config["D8_OPTIONS"],
    }, f)