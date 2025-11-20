const std = @import("std");
const meta = @import("../meta.zig");

const Entry = struct {
    number: u32,
    string: []const u8,

    pub const num: u32 = 0;
    pub const str: []const u8 = "Hello there!";

    pub fn deinit(self: *Entry, allocator: std.mem.Allocator) void {
        allocator.free(self.string);
    }

    pub fn clone(self: *const Entry, allocator: std.mem.Allocator) anyerror!Entry {
        return .{
            .number = self.number,
            .string = try allocator.dupe(u8, self.string),
        };
    }

    pub fn eql(self: *const Entry, other: *const Entry) bool {
        return self.number == other.number and
            std.mem.eql(u8, self.string, other.string);
    }
};

test "requireField" {
    meta.requireField(Entry, "number", u32);
    meta.requireField(Entry, "string", []const u8);
}

test "requireDecl" {
    meta.requireDecl(Entry, "num", u32);
    meta.requireDecl(Entry, "str", []const u8);
    meta.requireDecl(Entry, "deinit", fn (*Entry, std.mem.Allocator) void);
    meta.requireDecl(Entry, "clone", fn (*const Entry, std.mem.Allocator) anyerror!Entry);
    meta.requireDecl(Entry, "eql", fn (*const Entry, *const Entry) bool);
}

test "checkFunctionSignature" {
    meta.checkFunctionSignature(Entry, "deinit", &.{ *Entry, std.mem.Allocator }, void, false);
    meta.checkFunctionSignature(Entry, "clone", &.{ *const Entry, std.mem.Allocator }, Entry, true);
    meta.checkFunctionSignature(Entry, "eql", &.{ *const Entry, *const Entry }, bool, false);
}
