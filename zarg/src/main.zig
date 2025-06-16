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

    // pass the flag config to the arg manager
    // NOTE that this is a mutable variable
    var argMgr = zarg.argManager{ .params = &opts };

    // process the args
    try argMgr.process(argV);

    // and now use the option structs as normal
    if (helpOpt.isPresent.?) {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();
        try stdout.print("the help option is present\n", .{});
        try bw.flush();
    }
    if (outputOpt.optArg) |arg| {
        std.debug.print("the -o option is given as: {?s}\n", .{arg});
    }
}
