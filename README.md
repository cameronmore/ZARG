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
- ✅ Missing flag-based argument error handling
- ❌ Multiple same-flag arguments (like `-f Arg1 -f Arg2`)
- ❌ Equal sign style arument parsing (like `--style=MLA`)

### Documentation and Usage

Please see USAGE.md for a full example of usage (really a starter template). Below is a quickstart guide. I also wrote a simple program, called `zat` that implements the library for reference ([here](https://github.com/cameronmore/zat)).

To pull and use, run:
```shell
zig fetch --save git+https://github.com/cameronmore/ZARG
```
And then in your build.zig file, add:
```zig
const zargDep = b.dependency("zarg", .{.target=target,.optimize=optimize});

exe_mod.addImport("zarg", zargDep.module("zarg"));
```
After importing it into your code files (as `const zarg = @import("zarg");`), ZARG exposes two structs, an `zarg.argManager` and a `zarg.params`. To use the module, we want to (1) declare the params we want to include, (2) pass them to an `argManager` struct, and call the `argManager.process(argv)` method and pass it `std.os.argv` as `argv` from the Zig standard library.

Suppose we have a program called `widget`. Suppose we want to add a verbose option and an output option that takes an argument itself. Create two `zarg.params{}` structs:

```zig
var verboseOpt = zarg.params{ .shortFlag = "-v", .longFlag = "--verbose", .helpMsg = "performs widget verbosely"};

var outputOpt = zarg.params{ .shortFlag = "-o", .longFlag = "--output", .helpMsg = "output location for the program", hasArg = true };

```

Then, make an options or config array and pass it to the `zig.argManager{}` struct in the `.params` field:
```zig
const opts = [_]*zarg.params{ &verboseOpt, &outputOpt };

var argMgr = zarg.argManager{ .params = &opts };
```

Now, call the `zig.argManager`'s `.process()` method, passing the standard library's os args and an allocator to hold the positional args (i.e., arguments after the flags):
```zig
var positionalArgArray = std.ArrayList([*:0]u8).init(alc);
defer positionalArgArray.deinit();

try argMgr.process(std.os.argv, &positionalArgArray);
```
This populates each of the `zarg.params`'s fields, namely: `zarg.params.isPresent()` to know whether the flag was present or `zarg.params.optArg` that holds any flag based arguments like output in the `outputOpt` struct, like so:
```zig
if (outputOpt.optArg) |arg| {
    std.debug.print("the -o option is given as: {?s}\n", .{arg});
}
```

### Use of Artificial Intelligence

This project was developed with the aid of artificial intelligence (AI) but not AI code-completion. I started this project to solve a practical problem I was having as well as learning Zig, so I used AI sparingly in writing the actual code.

### Contributing and Licensing

ZARG welcomes bug reports, feature requests, and pull-requests! Please create a GitHub issue describing the problem or task and optionally link a pull request.

**NOTE: ZARG is an Apache-2.0 project, and all contributions to this repository must comply with that license.**
