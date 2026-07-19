.PHONY: all fmt build check test docs servedocs release deb appimage install uninstall clean

all: build

test:
	cargo nextest run 2>/dev/null || cargo test --workspace
	cargo test -p terminux-escape-parser 2>/dev/null || true

check:
	cargo check
	cargo check -p terminux-escape-parser 2>/dev/null || true
	cargo check -p terminux-cell 2>/dev/null || true
	cargo check -p terminux-surface 2>/dev/null || true
	cargo check -p terminux-ssh 2>/dev/null || true

build:
	cargo build $(BUILD_OPTS) -p terminux
	cargo build $(BUILD_OPTS) -p terminux-gui
	cargo build $(BUILD_OPTS) -p terminux-mux-server
	cargo build $(BUILD_OPTS) -p strip-ansi-escapes

release:
	cargo build --release -p terminux -p terminux-gui

deb: release
	./packaging/debian/build-deb.sh

appimage: release
	./packaging/appimage/build-appimage.sh

install:
	sudo ./scripts/install.sh

uninstall:
	sudo ./scripts/uninstall.sh

fmt:
	cargo +nightly fmt

docs:
	ci/build-docs.sh

servedocs:
	ci/build-docs.sh serve

clean:
	rm -rf dist/
