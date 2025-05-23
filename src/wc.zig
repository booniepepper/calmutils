//! wc - print newline, word, and byte counts for each file
//!
//! Primary reference: https://pubs.opengroup.org/onlinepubs/9799919799/utilities/wc.html

const std = @import("std");
const calmutils = @import("root.zig");

const WCError = error{UnknownOption};

const Files = std.ArrayList([]const u8);

const WC = struct {
    files: Files,
    default: bool,
    bytes: bool,
    chars: bool,
    lines: bool,
    max_lines: bool,
    words: bool,
    help: bool,
    version: bool,
};

const FileCounts = struct {
    bytes: u64,
    chars: u64,
    lines: u64,
    max_line: u64,
    words: u64,

    pub fn add(self: *FileCounts, other: FileCounts) void {
        self.bytes += other.bytes;
        self.chars += other.chars;
        self.lines += other.lines;
        self.words += other.words;

        if (other.max_line > self.max_line)
            self.max_line = other.max_line;
    }

    pub fn print(self: FileCounts, plan: WC, stdout: anytype) !void {
        if (plan.lines or plan.default)
            try stdout.print("{}\t", .{self.lines});
        if (plan.words or plan.default)
            try stdout.print("{}\t", .{self.words});
        if (plan.chars)
            try stdout.print("{}\t", .{self.chars});
        if (plan.bytes or plan.default)
            try stdout.print("{}\t", .{self.bytes});
        if (plan.max_lines)
            try stdout.print("{}\t", .{self.max_line});
    }
};

pub fn main() !void {
    var world = calmutils.World.init();
    const stdout = world.stdout.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const plan = try parseArgs(allocator);
    defer plan.files.deinit();

    try go(plan, stdout, allocator);

    try world.deinit();
}

fn go(plan: WC, stdout: anytype, allocator: std.mem.Allocator) !void {
    if (plan.help) {
        return try help(stdout);
    }

    if (plan.version) {
        return try version(stdout);
    }

    if (plan.files.items.len == 0) {
        const counts = try countFile(std.io.getStdIn(), allocator);
        try counts.print(plan, stdout);
        return stdout.print("\n", .{});
    }

    const cwd = std.fs.cwd();
    var total: FileCounts = .{
        .bytes = 0,
        .chars = 0,
        .lines = 0,
        .max_line = 0,
        .words = 0,
    };

    for (plan.files.items) |file| {
        const f = if (std.mem.eql(u8, file, "-"))
            std.io.getStdIn()
        else
            try cwd.openFile(file, .{});

        const counts = try countFile(f, allocator);

        try counts.print(plan, stdout);
        try stdout.print("{s}\n", .{file});
        total.add(counts);
    }

    if (plan.files.items.len > 1) {
        try total.print(plan, stdout);
        try stdout.print("total\n", .{});
    }
}

fn help(out: anytype) !void {
    const long_help = @embedFile("wc/help_long.txt");
    try out.print(long_help, .{});
}

fn version(out: anytype) !void {
    try out.print("wc (calmutils) {s}\n", .{calmutils.version});
}

fn countFile(f: std.fs.File, allocator: std.mem.Allocator) !FileCounts {
    var read_state = std.io.bufferedReader(f.reader());
    const read = read_state.reader();

    var counts: FileCounts = .{
        .bytes = 0,
        .chars = 0,
        .lines = 0,
        .max_line = 0,
        .words = 0,
    };

    while (try read.readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize))) |line| {
        counts.bytes += line.len + 1;
        counts.lines += 1;

        var words = std.mem.splitAny(u8, line, &std.ascii.whitespace);
        while (words.next()) |word| {
            if (word.len > 0) counts.words += 1;
        }

        if (line.len > counts.max_line) counts.max_line = line.len;
    }

    return counts;
}

fn parseArgs(allocator: std.mem.Allocator) !WC {
    var args = std.process.args();
    var plan: WC = .{
        .files = Files.init(allocator),
        .default = false,
        .bytes = false,
        .chars = false,
        .lines = false,
        .max_lines = false,
        .words = false,
        .help = false,
        .version = false,
    };

    const eql = struct {
        pub fn call(a: []const u8, b: []const u8) bool {
            return std.mem.eql(u8, a, b);
        }
    }.call;

    // Discard the argv[0] program name.
    _ = args.next();

    while (args.next()) |arg| {
        if (eql(arg, "--help")) {
            plan.help = true;
        } else if (eql(arg, "--version")) {
            plan.version = true;
        } else if (eql(arg, "--bytes")) {
            plan.bytes = true;
        } else if (eql(arg, "--chars")) {
            plan.chars = true;
        } else if (eql(arg, "--lines")) {
            plan.lines = true;
        } else if (eql(arg, "--words")) {
            plan.words = true;
        } else if (arg.len > 1 and std.mem.startsWith(u8, arg, "-")) {
            for (arg[1..]) |c| {
                switch (c) {
                    'c' => plan.bytes = true,
                    'l' => plan.lines = true,
                    'L' => plan.max_lines = true,
                    'm' => plan.chars = true,
                    'w' => plan.words = true,
                    else => return WCError.UnknownOption,
                }
            }
        } else {
            try plan.files.append(arg);
        }
    }

    plan.default = !plan.bytes and !plan.chars and !plan.words and !plan.lines;

    return plan;
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
