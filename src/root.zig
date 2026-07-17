const std = @import("std");

pub const meta = @import("meta.zig");
pub const hash = @import("hash.zig");

pub const SinglyLinkedList = @import("linked_list.zig").SinglyLinkedList;
pub const SinglyLinkedListError = @import("linked_list.zig").SinglyLinkedListError;
pub const SegmentedList = @import("segmented_list.zig").SegmentedList;

test {
    std.testing.refAllDecls(@import("tests/meta.zig"));
    std.testing.refAllDecls(@import("tests/linked_list.zig"));
    std.testing.refAllDecls(@import("tests/hash.zig"));
}
