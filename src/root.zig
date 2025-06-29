const std = @import("std");
const testing = std.testing;

/// error set for parsing command line args
pub const ArgParsingError = error{ FlagBasedArgMissing, UnrecognizedFlag };

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
    /// like -o OUTPUT_LOCATION. Only the next value is processed by ZARG (rather than,
    /// say, the next two or three). The arg.Manager.process() method will return and error if this is set
    /// to `true` but no arg is provided by the user
    hasArg: ?bool = false,
    /// populated by argManager.process() when processing the command line arguments
    optArg: ?[]const u8 = null,

    // todo consider whether we should do some validation with the given argument
    // to make sure an expected bool is a bool or expected number is a number.
    // a major con of that approach would be that it takes data validation
    // out of the developer's hands.
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

    /// the argManager.process() method will fail by default if it encounters an unrecognized flag,
    /// unless this is set to false. NOTE that if this is set to false, it will affect ZARG's ability to parse
    /// other flags that come after any possible unrecognized ones, but 
    /// the choice is yours.
    failOnUnrecognizedFlags: ?bool = true,

    // determine whether this should return a formatted string or
    // actually print to stdout
    /// prints a formatted help message to stdout. NOTE users must provide `null` as an argument
    /// to use to built-in usage headline message, otherwise, one can be suppplied here
    pub fn help(self: *argManager, usageMsg: ?([]const u8)) !void {
        //
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();
        // check if optional arg is null
        if (usageMsg) |um| {
            // if not null, use that as the first line of the help message
            try stdout.print("{?s}", .{um});
        } else {
            // if null, print default first line of usage message
            try stdout.print("usage of {?s}:\n", .{self.programName});
        }
        for (self.params) |param| {
            // print each flag param
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

        // this tracks whether we have finished parsing all of the flags
        // and if so, skips all the flag parsing logic
        var moreArgsToParse = true;

        if (argv.len > 1) {
            // only iterate if there are params/flags/args to iterate over
            // and skip the first item (1.. rather than 0..)

            // also build a reference array of flags once here and use
            // to match below

            mainArgLoop: for (argv, 0..) |value, i| {
                if (i == 0) {
                    continue;
                }

                const inputItem: [:0]u8 = std.mem.span(value);

                if (std.mem.eql(u8, "--", inputItem)) {
                    moreArgsToParse = !moreArgsToParse;
                    continue: mainArgLoop;
                }

                if (moreArgsToParse) {

                    // if the paramArgToAdd is not null, add that next arg to the param
                    if (self.paramArgToAdd != null) {
                        // first check if the arg is equal to any of the flags and
                        // return a FlagMissing error if so
                        for (self.params) |param| {
                            if (param.shortFlag) |sf| {
                                if (std.mem.eql(u8, sf, inputItem)) {
                                    return ArgParsingError.FlagBasedArgMissing;
                                }
                            }
                            if (param.longFlag) |lf| {
                                if (std.mem.eql(u8, lf, inputItem)) {
                                    return ArgParsingError.FlagBasedArgMissing;
                                }
                            }
                        }
                        // otherwise, add the arg to the correct param
                        self.params[self.paramArgToAdd.?].optArg = inputItem;
                        self.paramArgToAdd = null;
                        continue;
                    }

                    // look for long flag options first, then match short ones

                    if (std.mem.startsWith(u8, inputItem, "--")) {
                        // here, try to match on self.params.longFlag
                        // std.debug.print("Starts with -: {?s}\n", .{value});
                        for (self.params, 0..) |param, argi| {
                            if (param.longFlag) |sf| {
                                //std.debug.print("I compared {?s} with {?s}\n", .{ sf, inputItem });
                                if (std.mem.eql(u8, sf, inputItem)) {
                                    param.isPresent = true;
                                    //std.debug.print("and found that {?s} is {?any}\n", .{ sf, param.isPresent });
                                    if (param.hasArg.? == true) {
                                        self.paramArgToAdd = argi;
                                        // continue;
                                    }
                                    continue :mainArgLoop;
                                }
                            }
                        }
                        // if the user wants to keep trying to parse the flags even if
                        // an unrecognized one is encountered, then do so.
                        // this will mess up any flag parsing that comes after the
                        // unrecognized one though.
                        // todo, consider dropping this as an option
                        // todo consider making this a panic error
                        // todo consider whether this should print the unrecognized flag
                        // and same goes for the short flag version below
                        if (self.failOnUnrecognizedFlags == true) {
                            return ArgParsingError.UnrecognizedFlag;
                        }
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
                                        // continue;
                                    }
                                    continue :mainArgLoop;
                                }
                            }
                        }
                        // see note above
                        if (self.failOnUnrecognizedFlags == true) {
                            return ArgParsingError.UnrecognizedFlag;
                        }
                    }
                }
                // if this point is reached, then, in theory, all of the flags should be parsed.
                // this means that we should skip all of the above flag parsing for any args
                // that come after this point
                if (arrayList) |ar| {
                    try ar.append(inputItem);
                    // so set the more args to parse equal to false so that
                    // any flags given after this point are treated as positional args
                    moreArgsToParse = false;
                }
            }
        }
        // if there's still a flag based argument to parse and add,
        // throw an error here
        if (self.paramArgToAdd != null) {
            return ArgParsingError.FlagBasedArgMissing;
        }

        return;
    }
};
