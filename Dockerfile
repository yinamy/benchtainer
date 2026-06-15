FROM ubuntu:noble

RUN apt-get update

# For golang, 1.23 is the first version that supports generators in the language.
RUN apt-get install -y make curl wget cmake git g++-multilib ocaml-dune ocaml menhir opam rustup hyperfine linux-tools-generic golang-1.23 wabt libx11-dev libxft-dev

## Build v8
##   (first because it is very slow; first makes it less likely to rebuild)
## Instructions from https://v8.dev/docs/build

COPY .git /.git
COPY depot_tools /depot_tools
ENV PATH=$PATH:/depot_tools
WORKDIR /v8
RUN fetch v8
WORKDIR /v8/v8

RUN apt-get install -y sudo  # Seems ridiculous but the below needs to run sudo.
RUN ./build/install-build-deps.sh

# what nonsense
RUN git config --global --add safe.directory /v8/v8
RUN git config --global --add safe.directory /depot_tools
RUN git checkout main
RUN git pull && gclient sync

RUN tools/dev/gm.py x64.release
# Or, to compile the source and immediately run the tests:
# tools/dev/gm.py x64.release.check

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

ENV PATH="$PATH:/binaryen/bin"

# Install node, which is a dependency for js_of_ocaml

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
ENV NVM_DIR="/root/.nvm"
# Everything that needs node in the environment must be run after `"${NVM_DIR}/nvm.sh"`
RUN . "${NVM_DIR}/nvm.sh" && \
     nvm install 26
RUN . "${NVM_DIR}/nvm.sh" && \
     node -v

## Build js_of_ocaml from source

COPY js_of_ocaml /js_of_ocaml
WORKDIR /js_of_ocaml
RUN opam init --yes --disable-sandboxing
## Make opam switch for ocaml 5.4.1 (effect handlers are only supported in ocaml 5.0 or later)
RUN opam switch create 5.4.1 ocaml-base-compiler.5.4.1
RUN opam switch set 5.4.1
RUN eval $(opam env --switch=5.4.1)
## Now do the rest of the stuff
RUN opam install --yes --deps-only -t js_of_ocaml js_of_ocaml-lwt js_of_ocaml-compiler js_of_ocaml-toplevel js_of_ocaml-ppx js_of_ocaml-ppx_deriving_json js_of_ocaml-tyxml
RUN opam install --yes odoc lwt_log yojson ocp-indent graphics higlo opam-format
RUN . "${NVM_DIR}/nvm.sh" && \
    eval $(opam env --switch=5.4.1) make all

## Build custom (stack-switching) version of reference interpreter

## opam is needed for the reference interpreter build
# Disable-sandboxing was recommended here for use inside Docker containers: https://github.com/ocaml/opam/issues/4327#issuecomment-678630182
# RUN opam init --yes --disable-sandboxing
#RUN opam install --yes js_of_ocaml-compiler js_of_ocaml-ppx

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
RUN cargo build --release  # Note --release, without which we get the debug build, not good for benching.

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
ENV ENGINE_ROOT_DIR=..
COPY fiber-c /fiber-c
WORKDIR /fiber-c
RUN make

## Go code to run. Normally we will bind-mount these, but the state as of the container
## build is copied in in case you want to run them anyway.

COPY go-examples /go-examples

## OCaml code to run

COPY ocaml-examples /ocaml-examples

## The contents/Makefile has some useful commands for running things in the container.
ADD contents/Makefile /Makefile
## Other useful scripts from contents/
## This one is for running a command and logging the output (e.g. for perf stat runs).
ADD contents/run_and_log.sh /run_and_log.sh
ADD contents/justfile /justfile

WORKDIR /

## Create a python virtual environment and dependencies of our test driver script.

RUN apt install -y python3-venv
RUN python3 -m venv /venv
RUN /venv/bin/pip install pyyaml matplotlib numpy

RUN apt-get install -y just

##
## To start up the container, see commands in the benchtainer Makefile.
##
