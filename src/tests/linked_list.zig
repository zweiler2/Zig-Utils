const std = @import("std");
const linked_list = @import("../linked_list.zig");

const Entry = struct {
    number: u32,
    string: []const u8,

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

test "SinglyLinkedList.fromSlice" {
    const slice = &[_]Entry{
        .{ .number = 0, .string = "zero" },
        .{ .number = 1, .string = "one" },
        .{ .number = 2, .string = "two" },
    };
    var list: linked_list.SinglyLinkedList(Entry) = try .fromSlice(std.testing.allocator, slice);
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 3);

    var entry_at_0: ?*Entry = list.getAt(0);
    var entry_at_1: ?*Entry = list.getAt(1);
    var entry_at_2: ?*Entry = list.getAt(2);
    try std.testing.expect(entry_at_0.?.number == slice[0].number);
    try std.testing.expect(entry_at_1.?.number == slice[1].number);
    try std.testing.expect(entry_at_2.?.number == slice[2].number);
    try std.testing.expect(&entry_at_0.?.string != &slice[0].string);
    try std.testing.expect(&entry_at_1.?.string != &slice[1].string);
    try std.testing.expect(&entry_at_2.?.string != &slice[2].string);
    try std.testing.expectEqualStrings(slice[0].string, entry_at_0.?.string);
    try std.testing.expectEqualStrings(slice[1].string, entry_at_1.?.string);
    try std.testing.expectEqualStrings(slice[2].string, entry_at_2.?.string);

    entry_at_0.?.number = 5;
    entry_at_1.?.number = 4;
    entry_at_2.?.number = 3;
    try std.testing.expect(entry_at_0.?.number != slice[0].number);
    try std.testing.expect(entry_at_1.?.number != slice[1].number);
    try std.testing.expect(entry_at_2.?.number != slice[2].number);

    std.testing.allocator.free(entry_at_0.?.string);
    std.testing.allocator.free(entry_at_1.?.string);
    std.testing.allocator.free(entry_at_2.?.string);
    entry_at_0.?.string = try std.testing.allocator.dupe(u8, "five");
    entry_at_1.?.string = try std.testing.allocator.dupe(u8, "four");
    entry_at_2.?.string = try std.testing.allocator.dupe(u8, "three");
    try std.testing.expect(!std.mem.eql(u8, entry_at_0.?.string, slice[0].string));
    try std.testing.expect(!std.mem.eql(u8, entry_at_1.?.string, slice[1].string));
    try std.testing.expect(!std.mem.eql(u8, entry_at_2.?.string, slice[2].string));
}

test "SinglyLinkedList.toOwnedSlice" {
    var list: linked_list.SinglyLinkedList(Entry) = .{};
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 0);

    try list.append(std.testing.allocator, .{
        .number = 0,
        .string = "zero",
    });
    try std.testing.expect(list.len() == 1);
    try list.append(std.testing.allocator, .{
        .number = 1,
        .string = "one",
    });
    try std.testing.expect(list.len() == 2);

    const entry_at_0: *Entry = list.getAt(0).?;
    const entry_at_1: *Entry = list.getAt(1).?;

    const slice: []Entry = try list.toOwnedSlice(std.testing.allocator);
    defer {
        for (slice) |*entry| {
            entry.deinit(std.testing.allocator);
        }
        std.testing.allocator.free(slice);
    }
    try std.testing.expect(slice.len == 2);
    try std.testing.expect(slice[0].number == entry_at_0.number);
    try std.testing.expect(slice[1].number == entry_at_1.number);
    try std.testing.expect(&slice[0].string != &entry_at_0.string);
    try std.testing.expect(&slice[1].string != &entry_at_1.string);
    try std.testing.expectEqualStrings(entry_at_0.string, slice[0].string);
    try std.testing.expectEqualStrings(entry_at_1.string, slice[1].string);
}

test "SinglyLinkedList.append" {
    var list: linked_list.SinglyLinkedList(Entry) = .{};
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 0);

    try list.append(std.testing.allocator, .{
        .number = 1,
        .string = "one",
    });
    try std.testing.expect(list.len() == 1);
}

test "SinglyLinkedList.prepend" {
    var list: linked_list.SinglyLinkedList(Entry) = .{};
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 0);

    try list.prepend(std.testing.allocator, .{
        .number = 0,
        .string = "zero",
    });
    try std.testing.expect(list.len() == 1);

    try list.append(std.testing.allocator, .{
        .number = 2,
        .string = "two",
    });
    try std.testing.expect(list.len() == 2);

    try list.prepend(std.testing.allocator, .{
        .number = 1,
        .string = "one",
    });
    try std.testing.expect(list.len() == 3);
}

test "SinglyLinkedList.clone" {
    var list: linked_list.SinglyLinkedList(Entry) = .{};
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 0);

    try list.append(std.testing.allocator, .{
        .number = 0,
        .string = "zero",
    });
    try std.testing.expect(list.len() == 1);
    try list.append(std.testing.allocator, .{
        .number = 1,
        .string = "one",
    });
    try std.testing.expect(list.len() == 2);

    var list_clone: linked_list.SinglyLinkedList(Entry) = try list.clone(std.testing.allocator);
    defer list_clone.clearAndFree(std.testing.allocator);

    try std.testing.expect(list_clone.len() == 2);

    const entry_at_0_clone: ?*Entry = list_clone.getAt(0);
    try std.testing.expect(entry_at_0_clone != null);
    try std.testing.expect(entry_at_0_clone.?.number == 0);
    try std.testing.expectEqualStrings("zero", entry_at_0_clone.?.string);

    const entry_at_1_clone: ?*Entry = list_clone.getAt(1);
    try std.testing.expect(entry_at_1_clone != null);
    try std.testing.expect(entry_at_1_clone.?.number == 1);
    try std.testing.expectEqualStrings("one", entry_at_1_clone.?.string);

    entry_at_0_clone.?.number = 2;
    entry_at_1_clone.?.number = 3;
    std.testing.allocator.free(entry_at_0_clone.?.string);
    std.testing.allocator.free(entry_at_1_clone.?.string);
    entry_at_0_clone.?.string = try std.testing.allocator.dupe(u8, "two");
    entry_at_1_clone.?.string = try std.testing.allocator.dupe(u8, "three");
    const entry_at_0: ?*Entry = list.getAt(0);
    const entry_at_1: ?*Entry = list.getAt(1);
    try std.testing.expect(entry_at_0.?.number != entry_at_0_clone.?.number);
    try std.testing.expect(entry_at_1.?.number != entry_at_1_clone.?.number);
    try std.testing.expectEqualStrings("two", entry_at_0_clone.?.string);
    try std.testing.expectEqualStrings("three", entry_at_1_clone.?.string);
}

test "SinglyLinkedList.getIdxOf" {
    var list: linked_list.SinglyLinkedList(Entry) = .{};
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 0);

    const entry_0: Entry = .{
        .number = 0,
        .string = "zero",
    };
    const entry_1: Entry = .{
        .number = 1,
        .string = "one",
    };
    try list.append(std.testing.allocator, entry_0);
    try std.testing.expect(list.len() == 1);
    try list.append(std.testing.allocator, entry_1);
    try std.testing.expect(list.len() == 2);

    const idx_0: usize = list.getIdxOf(&entry_0).?;
    const idx_1: usize = list.getIdxOf(&entry_1).?;
    try std.testing.expect(idx_0 == entry_0.number);
    try std.testing.expect(idx_1 == entry_1.number);
}

test "SinglyLinkedList.getAt" {
    var list: linked_list.SinglyLinkedList(Entry) = .{};
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 0);

    try list.append(std.testing.allocator, .{
        .number = 0,
        .string = "zero",
    });
    try std.testing.expect(list.len() == 1);
    try list.append(std.testing.allocator, .{
        .number = 1,
        .string = "one",
    });
    try std.testing.expect(list.len() == 2);

    const entry_at_0: ?*Entry = list.getAt(0);
    try std.testing.expect(entry_at_0 != null);
    try std.testing.expect(entry_at_0.?.number == 0);

    const entry_at_1: ?*Entry = list.getAt(1);
    try std.testing.expect(entry_at_1 != null);
    try std.testing.expect(entry_at_1.?.number == 1);
}

test "SinglyLinkedList.insertAt" {
    var list: linked_list.SinglyLinkedList(Entry) = .{};
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 0);

    try list.insertAt(std.testing.allocator, 0, .{
        .number = 0,
        .string = "zero",
    });
    try std.testing.expect(list.len() == 1);

    try list.append(std.testing.allocator, .{
        .number = 3,
        .string = "three",
    });
    try std.testing.expect(list.len() == 2);

    try list.insertAt(std.testing.allocator, 1, .{
        .number = 2,
        .string = "two",
    });
    try std.testing.expect(list.len() == 3);

    try std.testing.expect(list.getAt(0).?.number == 0);
    try std.testing.expect(list.getAt(1).?.number == 2);
    try std.testing.expect(list.getAt(2).?.number == 3);
}

test "SinglyLinkedList.removeAt" {
    var list: linked_list.SinglyLinkedList(Entry) = .{};
    defer list.clearAndFree(std.testing.allocator);
    try std.testing.expect(list.len() == 0);

    try list.append(std.testing.allocator, .{
        .number = 0,
        .string = "zero",
    });
    try std.testing.expect(list.len() == 1);

    try list.append(std.testing.allocator, .{
        .number = 1,
        .string = "one",
    });
    try std.testing.expect(list.len() == 2);

    try list.removeAt(std.testing.allocator, 0);
    try std.testing.expect(list.len() == 1);

    try list.removeAt(std.testing.allocator, 0);
    try std.testing.expect(list.len() == 0);
}
