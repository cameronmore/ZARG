// ZARG 'hello world'
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

    // pass the flag config to the arg manager,
    // NOTE that this is a mutable variable
    var argMgr = zarg.argManager{ .params = &opts };

    // process the args in three steps

    // 1. set up an allocator for the positional arguments
    const alc = std.heap.page_allocator;
    // 2. initialize an array list to hold the arguments
    var myPositionalArgs = std.ArrayList([*:0]u8).init(alc);
    defer myPositionalArgs.deinit();
    // 3. process the argv args and pass the array list to hold
    // positional args and handle the FlagBasedArgMissing error
    argMgr.process(argV, &myPositionalArgs) catch |err| switch (err) {
        error.FlagBasedArgMissing => {
            std.debug.print("flag based arg missing\n", .{});
            return;
        },
        error.UnrecognizedFlag => {
            std.debug.print("an unrecognized flag was given\n", .{});
        },
        else => {
            return;
        },
    };

    // and now use the option structs as normal
    if (outputOpt.optArg) |arg| {
        std.debug.print("the -o option is given as: {?s}\n", .{arg});
    }
    // argManager has a built in self.help() method that prints a formatted
    // usage message to stdout. If you provide null, the default usage message will be printed,
    // otherwise you can provide a custom headline help message
    if (helpOpt.isPresent.?) {
        try argMgr.help(null);
        return;
    }
    // and we can access our leftover positional args like so:
    for (myPositionalArgs.items, 0..) |ar, idx| {
        std.debug.print("Non positional arg {d} given: {?s}\n", .{ idx, ar });
    }
}
