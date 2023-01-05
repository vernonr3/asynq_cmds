CLIENT_SOURCES := $(wildcard *.go kmclient/*/*.go)
SERVER_SOURCES := $(wildcard *.go kmserver/*/*.go)

VERSION=$(shell git describe --tags --long --dirty 2>/dev/null)

## we must have tagged the repo at least once for VERSION to work
ifeq ($(VERSION),)
	VERSION = UNKNOWN
endif

km_client: $(CLIENT_SOURCES) kmclient
	go build -ldflags "-X main.version=${VERSION}" -o $@ ./kmclient

km_server: $(SERVER_SOURCES)
	go build -ldflags "-X main.version=${VERSION}" -o $@ ./kmserver

.PHONY: lint
lint:
	/home/vernon/go/bin/golangci-lint run kmclient/... kmserver/...

# note the -C we're running the git diff outside the working tree - because we want the makefile to refer to build instructions for docker which aren't inside
# the working tree for the asynq_cmds... perhaps they should be - but that's for later..
.PHONY: committed
committed:
	@git diff --exit-code > /dev/null || (echo "** COMMIT YOUR CHANGES FIRST **"; exit 1)

docker: $(SOURCES) build/dkr.kmclient build/dkr.kmserver
	docker build -t kmclient:latest . -f build/dkr.kmclient --build-arg VERSION=$(VERSION)
	docker build -t kmserver:latest . -f build/dkr.kmserver --build-arg VERSION=$(VERSION)

.PHONY: publish
publish: committed lint
	make docker
	docker tag  kmclient:latest vernonr3/kmclient:$(VERSION)
## docker push matthol2/sort-anim:$(VERSION) - not looking to do this for now..
