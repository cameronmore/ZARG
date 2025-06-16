const std = @import("std");
const testing = std.testing;

// captures non-positional flag-based parameters and options
pub const params: type = struct {
    // short and long flags are optional, but if they are not given,
    // zarg has nothing to try and match...
    shortFlag: ?[]const u8 = null,
    longFlag: ?[]const u8 = null,
    helpMsg: []const u8,
    isPresent: ?bool = false,
    // because any flag based arguments are read from stdin,
    // they are stored in this struct as a string
    hasArg: ?bool = false,
    optArg: ?[]const u8 = null,
    // todo consider whether we should do some validation with the given argument
    // to make sure an expected bool is a bool or expected number is a number
    // optArgType: type,
    // hasValue? like - o OUTPUT
};

pub const argManager = struct {

    // populated on runtime with the first argV given on .process()
    programName: ?[]const u8 = null,

    // takes param structs
    params: []const *params,

    // populated on runtime with .process()
    // note, this will remain null if no positional args are
    // given such that the user can determine whether
    // they want to throw an error
    positionalArgs: ?[]u8 = null,

    paramArgToAdd: ?usize = null,

    /// processes params and args to populate the user defined structs
    pub fn process(self: *argManager, argv: [][*:0]u8) !void {

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
                                }
                                continue;
                            }
                        }
                    }

                    continue;
                }
            }
        }

        // create a counter to keep track ofwhere we are in processing the args

        // for loop over argV items given (skipping the 0th index)

        // for simple boolean args, do a switch (?) over both the long and short options

        // for args that take sub args like -o OUTPUT, use the index above to move the cursor/counter
        // and throw an error if the next arg matches any of the flags like
        // the user said "command -o -v [blah]" where -o took an arg that
        // was not supplied

        return;
    }
};

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
