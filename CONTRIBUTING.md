# Contributing to Terminux

Thank you for your interest in contributing to Terminux!

Terminux is a modern, customizable terminal built on top of WezTerm. Whether you're fixing bugs, improving documentation, creating themes, developing plugins, or implementing new features, your contributions are welcome.

## Code of Conduct

By participating in this project, you agree to:

* Be respectful and constructive.
* Welcome newcomers and help others learn.
* Focus on improving the project.
* Avoid harassment, discrimination, or personal attacks.

## Ways to Contribute

### Report Bugs

Before opening an issue:

* Ensure you're using the latest version of Terminux.
* Search existing issues to avoid duplicates.
* Include reproduction steps.
* Include system information and logs when possible.

### Suggest Features

Feature requests should include:

* A clear description of the feature.
* The problem it solves.
* Alternative solutions considered.
* Mockups or examples when applicable.

### Improve Documentation

Documentation contributions are highly valued.

Examples:

* Fixing typos
* Clarifying instructions
* Creating tutorials
* Expanding API documentation
* Writing plugin development guides

### Contribute Code

Areas where contributions are welcome:

* Terminal features
* Performance improvements
* Theme development
* Plugin API enhancements
* Linux packaging
* Accessibility improvements
* UI and UX improvements
* Bug fixes

## Development Setup

### Clone the Repository

```bash
git clone --recursive https://github.com/YOUR_USERNAME/terminux.git
cd terminux
```

### Install Rust

```bash
curl https://sh.rustup.rs -sSf | sh
```

### Build Terminux

```bash
cargo build
```

### Run Terminux

```bash
cargo run
```

### Release Build

```bash
cargo build --release
```

## Branch Naming

Use descriptive branch names:

```text
feature/theme-manager
feature/plugin-api
fix/session-restore
fix/crash-on-startup
docs/readme-update
```

## Commit Message Guidelines

Use clear commit messages.

Examples:

```text
feat: add workspace session restore
feat: implement plugin loader
fix: resolve startup crash on Wayland
fix: improve font fallback handling
docs: update installation instructions
```

Recommended prefixes:

* feat
* fix
* docs
* refactor
* perf
* test
* build
* ci

## Pull Request Guidelines

Before opening a pull request:

* Ensure the project builds successfully.
* Run all tests.
* Update documentation if needed.
* Keep changes focused and relevant.
* Follow existing code style.

A good pull request should include:

* Summary of changes
* Reason for the change
* Screenshots (if UI changes are involved)
* Related issue references

## Coding Standards

### Rust

* Prefer idiomatic Rust.
* Avoid unnecessary allocations.
* Use descriptive names.
* Keep functions focused and maintainable.
* Add comments only when they improve understanding.

### Lua

* Keep plugin APIs stable.
* Document public functions.
* Maintain backward compatibility whenever possible.

## Themes

Theme contributions should:

* Include screenshots.
* Support ANSI color standards.
* Maintain readable contrast.
* Include a preview image.

Suggested structure:

```text
themes/
└── my-theme.lua
```

## Plugins

Plugins should:

* Be documented.
* Avoid unnecessary dependencies.
* Handle errors gracefully.
* Respect user privacy.

Suggested structure:

```text
plugin/
├── manifest.json
├── plugin.lua
└── README.md
```

## Testing

Before submitting code:

```bash
cargo test
cargo clippy
cargo fmt --check
```

Recommended:

```bash
cargo fmt
cargo clippy
```

## Security

If you discover a security vulnerability:

Do not create a public issue.

Instead, contact the maintainers privately and provide:

* A detailed description
* Reproduction steps
* Potential impact
* Suggested mitigation

## Recognition

All contributors are appreciated and will be recognized through:

* GitHub contributor listings
* Release notes
* Community acknowledgements

## License

By contributing to Terminux, you agree that your contributions will be licensed under the same license as the project.

Thank you for helping build Terminux.
