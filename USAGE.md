# Usage

ZARG usage is relatively straight forward.

First, in your Zig project's root, run:
```shell
zig fetch --save git+https://github.com/cameronmore/ZARG
```
And then in your build.zig file, add:
```zig
const zargDep = b.dependency("zarg", .{.target=target,.optimize=optimize});
exe_mod.addImport("zarg", zargDep.module("zarg"));
```
Somewhere toward the end of the file.

## Quickstart

ZARG exposes two objects, an `argManager` struct and a `params` struct. to use the module, we want to (1) declare the params we want to include, (2) pass them to an `argManager` struct, and call the `argManager.process()` method and pass it `std.os.argv` from the Zig standard library.

Suppose we have a program called `widget`. Suppose we want to add a verbose option and an output option that takes an argument itself. Create two `zarg.params{}` structs:

```zig
var verboseOpt = zarg.params{ .shortFlag = "-v", .longFlag = "--verbose", .helpMsg = "performs widget verbosely"};
var outputOpt = zarg.params{ .shortFlag = "-o", .longFlag = "--output", .helpMsg = "output location for the program", hasArg = true };
```

Then, make an options or config array and pass it to the `zig.argManager{}` struct:
```zig
const opts = [_]*zarg.params{ &verboseOpt, &outputOpt };
var argMgr = zarg.argManager{ .params = &opts };
```

Now, call the `zig.argManager`'s `.process()` method, passing the standard library's os args and an allocator to hold the positional args:
```zig
var positionalArgArray = std.ArrayList([*:0]u8).init(alc);
defer positionalArgArray.deinit();
try argMgr.process(std.os.argv, &positionalArgArray);
```
This populates each of the `zarg.params`'s fields, namely: `zarg.params.isPresent()` to know whether the flag was present or `zarg.params.optArg` that holds any flag based arguments like output in the `outputOpt` struct.

## Limitations

There are many things that ZARG doesn't do, but one worth noting is that if a flag-based argument is given, (like `-o OUTPUT_LOCATION`), then ZARG will overwrite multiples with the last value given.

Further, if a flag-based argument is missing, ZARG will treat the next argument as the value for that argument. For example, suppose we want to specify an output location and verbose mode, but we forgot to provide an output location (like `my_tool -o -v MY_NON-POSITIONAL_INPUT`), then ZARG will treat `-v` as the argument for `-o` and `my_tool` will not run in verbose mode.

## Full Example

Below is a full example of using ZARG, tested with Zig 0.14.0.

```zig
const std = @import("std");
const zarg = @import("zarg_lib");

pub fn main() !void {

    // initialize the command line arguments given
    const argV = std.os.argv;

    // configure your flags
    // NOTE that these are mutable such that the argManager.process() method can modify them
    var helpOpt = zarg.params{ .shortFlag = "-h", .longFlag = "--help", .helpMsg = "prints a help message" };
    var verboseOpt = zarg.params{ .shortFlag = "-v", .longFlag = "--verbose", .helpMsg = "prints a verbose output" };
    var outputOpt = zarg.params{ .shortFlag = "-o", .longFlag = "--output", .helpMsg = "output location for the program", .hasArg = true };
    // add the flags to a config array
    const opts = [_]*zarg.params{ &helpOpt, &verboseOpt, &outputOpt };

    // pass the flag config to the arg manager
    // NOTE that this is a mutable variable
    var argMgr = zarg.argManager{ .params = &opts };

    // process the args
    // 1. set up an allocator for the positional arguments
    const alc = std.heap.page_allocator;
    // initialize an array list to hold the arguments
    var myPositionalArgs = std.ArrayList([*:0]u8).init(alc);
    defer myPositionalArgs.deinit();
    // process the argv args and optionally pass the array list to hold
    // positional args
    try argMgr.process(argV, &myPositionalArgs);

    // and now use the option structs as normal
    if (outputOpt.optArg) |arg| {
        std.debug.print("the -o option is given as: {?s}\n", .{arg});
    }
    // argManager has a build in self.help() message that prints a formatted
    // usage message. If you provide "", the default usage message will be printed.
    if (helpOpt.isPresent.?) {
        try argMgr.help("");
        return;
    }
    // and we can access our leftover positional args like so:
    for (myPositionalArgs.items, 0..) |ar, idx| {
        std.debug.print("Non positional arg {d} given: {?s}\n", .{ idx, ar });
    }
}
```