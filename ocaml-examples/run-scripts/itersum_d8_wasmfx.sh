#!/bin/bash

setarch -R /opt/wasmfx/v8/v8/out/x64.release/d8 --experimental-wasm-wasmfx -e "load('../load.mjs');load('itersum_wasmfx.js');"