# ⚡ ZARG ⚡

ZARG is a lightweight Zig command ling argument module. Zarg offers a simple API and allows the user decide how to handle missing flags and values.

### Why ZARG?

ZARG is simple. This makes ZARG easy to drop in to an existing project and update as the Zig programming language evolves and updates. ZARG is also lightweight enough to remove relatively easily if your needs change or want to swap in a different argument parsing module.

Staying true to Zig's core principles, ZARG does not make any hidden allocators, leaving the user to decide how to store argument flags.

### Features

- ✅ Short and long flag matching
- ✅ Help message printing
- ✅ Boolean flag support
- ✅ Sub-command argument support
- ✅ Positional argument capturing
- ❌ Multiple same-flag arguments

### Documentation and Usage

Please see USAGE.md for documentation.

### Use of Artificial Intelligence

This project was developed with the aid of artificial intelligence (AI) but not AI code-completion. I started this project to solve a practical problem I was having as well as learning Zig, so I used AI sparingly in writing the actual code.

### Contributing and Licensing

ZARG welcomes bug reports, feature requests, and pull-requests! Please create a GitHub issue describing the problem or task and optionally link a pull request.

**NOTE: ZARG is an Apache-2.0 project, and all contributions to this repository must comply with that license.**
