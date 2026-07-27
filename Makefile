# This Makefile helps with building the container itself, or building things outside the container to then simply include in the container build.

# Not working yet
v8:
	export PATH=$(PATH):$(PWD)/depot_tools
	cd depot_tools
	gclient config
	gclient --verbose sync

go_itersum.wasm:
	GOOS=wasip1 GOARCH=wasm /usr/lib/go-1.23/bin/go build  -o /go-examples/itersum.wasm /go-examples/itersum.go

# Building the base V8 container should be necessary only when there are v8
# changes to pick up, which is rare. The other build ("container") will base
# itself on the V8 container and include that.
v8-base-container:
	docker build . -f v8.Dockerfile -t benchtainer-v8:latest

container:
	docker build . -t $(SUDO_USER)-benchtainer:latest

BIND_MOUNTS=--mount type=bind,src=$(PWD)/go-examples,dst=/go-examples --mount type=bind,src=$(PWD)/fiber-c/examples,dst=/fiber-c/examples --mount type=bind,src=$(PWD)/fiber-c/bench_results,dst=/fiber-c/bench_results --mount type=bind,src=$(PWD)/results,dst=/results

launch_container_shell launch:
	sudo docker run -it $(BIND_MOUNTS) $(USER)-benchtainer bash

launch_container_shell_privileged:
	sudo docker run --privileged -it $(BIND_MOUNTS) $(USER)-benchtainer bash


######## Stuff for building the Go examples outside the container. ########
#### TODO: Clean this up.

%.wasm:
        sudo docker run -it  -w / gotainer make -f /go/src/Makefile $@
