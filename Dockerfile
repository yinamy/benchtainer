FROM benchtainer-v8:latest

# For golang, 1.23 is the first version that supports generators in the language.
RUN apt-get update && apt-get install -y make curl wget cmake git g++-multilib ocaml-dune ocaml menhir opam rustup hyperfine linux-tools-generic golang-1.23 wabt

## Unpack wasi-sdk

WORKDIR /
## curl doesn't work for some reason (0 bytes return). So I use wget.
# RUN curl -O https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-30/wasi-sdk-30.0-x86_64-linux.tar.gz
RUN wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-30/wasi-sdk-30.0-x86_64-linux.tar.gz
RUN tar xzf wasi-sdk-30.0-x86_64-linux.tar.gz

## build binaryen

COPY binaryen /binaryen
WORKDIR /binaryen
# RUN CC=../wasi-sdk-30.0-x86_64-linux/bin/clang cmake . && make
RUN CXX=g++ CC=gcc cmake . && CXX=g++ CC=gcc make -j12

## Build custom (stack-switching) version of reference interpreter

## opam is needed for the reference interpreter build
# Disable-sandboxing was recommended here for use inside Docker containers: https://github.com/ocaml/opam/issues/4327#issuecomment-678630182
RUN opam init --yes --disable-sandboxing
RUN opam install --yes js_of_ocaml-compiler js_of_ocaml-ppx

## Build ref interpreter

COPY stack-switching /stack-switching
WORKDIR /stack-switching/interpreter
RUN eval $(opam env) make

## Build wasm(fx)time

COPY wasmfxtime /wasmfxtime
WORKDIR /wasmfxtime
# With ubuntu:questing these env vars weren't needed but with noble they are.
# Not sure what they do. Setting them this way allows it to succeed.
ENV CARGO_HOME=/
ENV RUSTUP_HOME=/usr/bin
RUN rustup update 1.82.0   # version that wasmfxtime is written to.
RUN cargo build --release --features=default,wasmfx_pooling_allocator
RUN cargo build --release -p wasmtime-c-api

## Virgil

COPY virgil /virgil
WORKDIR /virgil
RUN PATH=$PATH:/virgil/bin make

## Wizard

COPY wizard-engine /wizard-engine
WORKDIR /wizard-engine
RUN PATH=$PATH:/virgil/bin make -j
COPY run-virgilly /run-virgilly

## Wasmfx-tools

COPY wasmfx-tools /wasmfx-tools
WORKDIR /wasmfx-tools
RUN cargo install --locked --path .

## Build fiber-c

ENV ROOT=
COPY fiber-c /fiber-c
WORKDIR /fiber-c
RUN make

## Go code to run. Normally we will bind-mount these, but the state as of the container
## build is copied in in case you want to run them anyway.

COPY go-examples /go-examples

## The contents/Makefile has some useful commands for running things in the container.
ADD contents/Makefile /Makefile
## Other useful scripts from contents/
## This one is for running a command and logging the output (e.g. for perf stat runs).
ADD contents/run_and_log.sh /run_and_log.sh
ADD contents/justfile /justfile

WORKDIR /

## Create a python virtual environment and dependencies of our test driver script.

RUN apt-get update && apt install -y python3-venv
RUN python3 -m venv /venv
RUN /venv/bin/pip install pyyaml matplotlib numpy
ENV PATH="/venv/bin:$PATH"

RUN apt-get update && apt-get install -y just

##
## To start up the container, see commands in the benchtainer Makefile.
##

