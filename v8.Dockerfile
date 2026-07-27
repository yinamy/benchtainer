FROM ubuntu:noble

# For golang, 1.23 is the first version that supports generators in the language.
RUN apt-get update && apt-get install -y make curl wget cmake git g++-multilib ocaml-dune ocaml menhir opam rustup hyperfine linux-tools-generic golang-1.23 wabt

## Build v8
##   (first because it is very slow; first makes it less likely to rebuild)
## Instructions from https://v8.dev/docs/build

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
