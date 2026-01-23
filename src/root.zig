const std = @import("std");

pub const meta = @import("meta.zig");

pub const SinglyLinkedList = @import("linked_list.zig").SinglyLinkedList;
pub const SinglyLinkedListError = @import("linked_list.zig").SinglyLinkedListError;

test {
    std.testing.refAllDecls(@import("tests/meta.zig"));
    std.testing.refAllDecls(@import("tests/linked_list.zig"));
}
