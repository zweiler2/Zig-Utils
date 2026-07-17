const std = @import("std");
const hash = @import("../hash.zig");

const Entry = struct {
    number: u32,
    string: []const u8,

    pub fn deinit(self: *Entry, allocator: std.mem.Allocator) void {
        allocator.free(self.string);
    }
};

test "HashMap.deinit_empty" {
    var map: hash.HashMap(Entry) = .empty;
    map.deinit(std.testing.allocator);
}

test "HashMap.insert" {
    var map: hash.HashMap(Entry) = .empty;
    defer map.deinit(std.testing.allocator);

    _ = try map.insert(std.testing.allocator, "ABCDEFGH", .{
        .number = 10,
        .string = "Hi, There!\n",
    });
}

test "HashMap.get" {
    var map: hash.HashMap(Entry) = .empty;
    defer map.deinit(std.testing.allocator);

    _ = try map.insert(std.testing.allocator, "ABCDEFGH", .{
        .number = 10,
        .string = "Hi, There!\n",
    });

    const get_no = map.get("HGFEDCBA");
    try std.testing.expect(get_no == null);

    const get_gud = map.get("ABCDEFGH");
    try std.testing.expect(get_gud != null);
}

test "HashMap.delete" {
    var map: hash.HashMap(Entry) = .empty;
    defer map.deinit(std.testing.allocator);

    _ = try map.insert(std.testing.allocator, "ABCDEFGH", .{
        .number = 10,
        .string = "Hi, There!\n",
    });

    map.delete(std.testing.allocator, "ABCDEFGH");

    const get_no = map.get("ABCDEFGH");
    try std.testing.expect(get_no == null);
}
