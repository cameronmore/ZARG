const std = @import("std");
const testing = std.testing;

/// captures non-positional flag-based parameters and options
pub const params: type = struct {
    /// short and long flags are optional, but if they are not given,
    /// zarg has nothing to try and match...
    shortFlag: ?[]const u8 = null,
    /// short and long flags are optional, but if they are not given,
    /// zarg has nothing to try and match...
    longFlag: ?[]const u8 = null,
    /// user-supplied usage help message
    helpMsg: []const u8,
    /// this is false by default and made true if the flag is changed by the
    /// argManager struct when processing the command line arguments
    isPresent: ?bool = false,
    /// tells ZARG whether or not to expect an argument that accompanies this flag
    /// like -o OUTPUT_LOCATION
    hasArg: ?bool = false,
    /// populated by argManager.process() when processing the command line arguments
    optArg: ?[]const u8 = null,

    // todo consider whether we should do some validation with the given argument
    // to make sure an expected bool is a bool or expected number is a number
    // optArgType: type,
    // hasValue? like - o OUTPUT

};

/// main struct to hold user defined parameters and arguments.
/// NOTE, only `params` field should be supplied by the user.
pub const argManager = struct {
    /// populated on runtime with the first argv given on self.process()
    programName: ?[]const u8 = null,

    // takes an array of param structs
    params: []const *params,

    /// populated on runtime with .process()
    /// NOTE, this will remain null if no positional args are
    /// given such that the user can determine whether
    /// they want to throw an error
    positionalArgs: ?[][*:0]u8 = null,

    /// a helpful internal field to keep track of parsing flag
    /// based arguments
    paramArgToAdd: ?usize = null,

    // determine whether this should return a formatted string or
    // actually print to stdout
    /// prints a formatted help message to stdout. NOTE users must provide `""` as an argument
    /// to use to built-in usage headline message, otherwise, one can be suppplied here
    pub fn help(self: *argManager, usageMsg: ?([]const u8)) !void {
        //
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();
        if (!(std.mem.eql(u8, usageMsg.?, ""))) {
            try stdout.print("{?s}", .{usageMsg.?});
        } else {
            try stdout.print("usage of {?s}:\n", .{self.programName});
        }
        for (self.params) |param| {
            try stdout.print("{?s}, {?s}\t\t{?s}\n", .{ param.shortFlag, param.longFlag, param.helpMsg });
        }
        try bw.flush();
    }

    /// processes argv args from stdin
    pub fn process(self: *argManager, argv: [][*:0]u8, arrayList: ?*std.ArrayList([*:0]u8)) !void {

        // convert the c-style string to zig style
        // by convention, the first command line arg is the name of the program itself
        // so it really should never error
        self.programName = std.mem.span(argv[0]);

        if (argv.len > 1) {
            // only iterate if there are params/flags/args to iterate over
            // and skip the first item (1.. rather than 0..)

            // also build a reference array of flags once here and use
            // to match below

            for (argv, 0..) |value, i| {
                if (i == 0) {
                    continue;
                }

                const inputItem = std.mem.span(value);

                // if the paramArgToAdd is not null, add that next arg to the param
                if (self.paramArgToAdd != null) {
                    self.params[self.paramArgToAdd.?].optArg = inputItem;
                    self.paramArgToAdd = null;
                    continue;
                }

                // look for long flag options first, then match short ones

                if (std.mem.startsWith(u8, inputItem, "--")) {
                    // here, try to match on self.params.longFlag
                    // std.debug.print("Starts with -: {?s}\n", .{value});
                    continue;
                }

                if (std.mem.startsWith(u8, inputItem, "-")) {
                    // here, try to match on self.params.shortFlag
                    // std.debug.print("Starts with -: {?s}\n", .{value});

                    for (self.params, 0..) |param, argi| {
                        if (param.shortFlag) |sf| {
                            //std.debug.print("I compared {?s} with {?s}\n", .{ sf, inputItem });
                            if (std.mem.eql(u8, sf, inputItem)) {
                                param.isPresent = true;
                                //std.debug.print("and found that {?s} is {?any}\n", .{ sf, param.isPresent });
                                if (param.hasArg.? == true) {
                                    self.paramArgToAdd = argi;
                                    continue;
                                }
                                continue;
                            }
                        }
                    }

                    continue;
                }
                if (arrayList) |ar| {
                    try ar.append(inputItem);
                }
            }
        }
        return;
    }
};

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
