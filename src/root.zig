const std = @import("std");

const stdin_file = std.io.getStdIn().writer();
const stdout_file = std.io.getStdOut().writer();
const stderr_file = std.io.getStdErr().writer();

pub const version = "0.1";

pub const World = struct {
    stdin: std.io.BufferedReader(4096, @TypeOf(stdin_file)),
    stdout: std.io.BufferedWriter(4096, @TypeOf(stdout_file)),
    stderr: std.io.BufferedWriter(4096, @TypeOf(stderr_file)),

    pub fn init() World {
        return .{
            .stdin = std.io.bufferedReader(stdin_file),
            .stdout = std.io.bufferedWriter(stdout_file),
            .stderr = std.io.bufferedWriter(stderr_file),
        };
    }

    pub fn deinit(self: *World) !void {
        try self.stdout.flush();
        try self.stderr.flush();
    }
};
