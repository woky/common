export GO111MODULE=off

GO ?= go
GO_BUILD=$(GO) build
# Go module support: set `-mod=vendor` to use the vendored sources
ifeq ($(shell go help mod >/dev/null 2>&1 && echo true), true)
	GO_BUILD=GO111MODULE=on $(GO) build -mod=vendor
endif
BUILDTAGS :=
DESTDIR ?=
PREFIX := /usr/local
CONFIGDIR := ${PREFIX}/share/containers
PROJECT := github.com/containers/common

# If GOPATH not specified, use one in the local directory
ifeq ($(GOPATH),)
export GOPATH := $(CURDIR)/_output
unexport GOBIN
endif
FIRST_GOPATH := $(firstword $(subst :, ,$(GOPATH)))
GOPKGDIR := $(FIRST_GOPATH)/src/$(PROJECT)
GOPKGBASEDIR ?= $(shell dirname "$(GOPKGDIR)")

GOBIN := $(shell $(GO) env GOBIN)
ifeq ($(GOBIN),)
GOBIN := $(FIRST_GOPATH)/bin
endif

define go-get
	env GO111MODULE=off \
		$(GO) get -u ${1}
endef

define go-build
	GOOS=$(1) GOARCH=$(2) $(GO) build -tags "$(3)" ./...
endef

.PHONY:
build-cross:
	$(call go-build,linux,386,${BUILDTAGS})
	$(call go-build,linux,arm,${BUILDTAGS})
	$(call go-build,linux,arm64,${BUILDTAGS})
	$(call go-build,linux,ppc64le,${BUILDTAGS})
	$(call go-build,linux,s390x,${BUILDTAGS})
	$(call go-build,darwin,amd64,${BUILDTAGS})
	$(call go-build,windows,amd64,remote ${BUILDTAGS})
	$(call go-build,windows,386,remote ${BUILDTAGS})

.PHONY: all
all: build-amd64 build-386

.PHONY: build
build: build-amd64 build-386

.PHONY: build-amd64
build-amd64:
	GOARCH=amd64 $(GO_BUILD) ./...

.PHONY: build-386
build-386:
ifneq ($(shell uname -s), Darwin)
	GOARCH=386 $(GO_BUILD) ./...
endif

.PHONY: docs
docs:
	$(MAKE) -C docs

.PHONY: validate
validate: build/golangci-lint
	./build/golangci-lint run

vendor-in-container:
	podman run --privileged --rm --env HOME=/root -v `pwd`:/src -w /src golang make vendor

.PHONY: vendor
vendor:
	GO111MODULE=on $(GO) mod tidy
	GO111MODULE=on $(GO) mod vendor
	GO111MODULE=on $(GO) mod verify

.PHONY: install.tools
install.tools: build/golangci-lint .install.md2man

build/golangci-lint:
	export \
		VERSION=v1.30.0 \
		URL=https://raw.githubusercontent.com/golangci/golangci-lint \
		BINDIR=build && \
	curl -sfL $$URL/$$VERSION/install.sh | sh -s $$VERSION


.install.md2man:
	if [ ! -x "$(GOBIN)/go-md2man" ]; then \
		   $(call go-get,github.com/cpuguy83/go-md2man); \
	fi

.PHONY: install
install:
	install -d ${DESTDIR}/${CONFIGDIR}
	install -m 0644 pkg/config/containers.conf ${DESTDIR}/${CONFIGDIR}/containers.conf

	$(MAKE) -C docs install

.PHONY: test
test: test-unit

.PHONY: test-unit
test-unit:
	go test -v $(PROJECT)/pkg/...
	go test --tags remote,seccomp -v $(PROJECT)/pkg/...

clean: ## Clean artifacts
	$(MAKE) -C docs clean
	find . -name \*~ -delete
	find . -name \#\* -delete

.PHONY: seccomp.json
seccomp.json: $(sources)
	$(GO) run ./cmd/seccomp/generate.go
