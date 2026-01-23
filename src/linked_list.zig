const std = @import("std");
const meta = @import("meta.zig");

pub const SinglyLinkedListError = error{ IdxOutOfBounds, Dupe };

pub fn SinglyLinkedList(
    comptime T: type,
    comptime deinit_fn: ?fn (*T, std.mem.Allocator) void,
    comptime dupe_fn: ?fn (*const T, std.mem.Allocator) anyerror!T,
    comptime eql_fn: ?fn (*const T, *const T) bool,
) type {
    return struct {
        const Self = @This();
        const NodeType = Node(T, deinit_fn, dupe_fn);

        pub const Iterator = struct {
            current: ?*NodeType,

            pub fn next(self: *Iterator) ?*T {
                if (self.current) |current| {
                    self.current = current.next;
                    return &current.value;
                }
                return null;
            }
        };

        head: ?*NodeType = null,

        pub fn fromSlice(allocator: std.mem.Allocator, slice: []const T) anyerror!Self {
            const dupe_function = comptime if (dupe_fn) |dupe_func|
                dupe_func
            else blk: {
                meta.requireDecl(T, "dupe", fn (*const T, std.mem.Allocator) anyerror!T);
                meta.checkFunctionSignature(T, "dupe", &.{ *const T, std.mem.Allocator }, T, true);
                break :blk T.dupe;
            };

            var list: Self = .{};
            var i: usize = slice.len;
            while (i > 0) : (i -= 1) {
                try list.prepend(
                    allocator,
                    try dupe_function(&slice[i - 1], allocator),
                );
            }
            return list;
        }

        pub fn fromOwnedSlice(allocator: std.mem.Allocator, slice: []const T) std.mem.Allocator.Error!Self {
            var list: Self = .{};
            var i: usize = slice.len;
            while (i > 0) : (i -= 1) {
                try list.prepend(allocator, slice[i - 1]);
            }
            return list;
        }

        pub fn clearAndFree(self: *Self, allocator: std.mem.Allocator) void {
            if (self.head) |head| {
                head.clearAndFreeAll(allocator);
                allocator.destroy(head);
                self.head = null;
            }
        }

        pub fn toOwnedSlice(self: *const Self, allocator: std.mem.Allocator) anyerror![]T {
            const dupe_function = comptime if (dupe_fn) |dupe_func|
                dupe_func
            else blk: {
                meta.requireDecl(T, "dupe", fn (*const T, std.mem.Allocator) anyerror!T);
                meta.checkFunctionSignature(T, "dupe", &.{ *const T, std.mem.Allocator }, T, true);
                break :blk T.dupe;
            };

            if (self.head == null) {
                return error.EmptyList;
            }
            var list: []T = try allocator.alloc(T, self.len());
            var current: ?*NodeType = self.head;
            var i: usize = 0;
            while (current) |node| : (i += 1) {
                list[i] = try dupe_function(&node.value, allocator);
                current = node.next;
            }
            return list;
        }

        pub fn append(self: *Self, allocator: std.mem.Allocator, value: T) std.mem.Allocator.Error!void {
            const new_node: *NodeType = try allocator.create(NodeType);
            new_node.* = .{ .next = null, .value = value };
            if (self.head) |head_value| {
                // Find last element
                var current: *NodeType = head_value;
                while (current.next) |next_value| {
                    current = next_value;
                }
                current.next = new_node;
            } else {
                self.head = new_node;
            }
        }

        pub fn prepend(self: *Self, allocator: std.mem.Allocator, value: T) std.mem.Allocator.Error!void {
            const new_head: *NodeType = try allocator.create(NodeType);
            new_head.* = .{ .next = self.head, .value = value };
            self.head = new_head;
        }

        pub fn dupe(self: *const Self, allocator: std.mem.Allocator) anyerror!Self {
            var new_list: Self = .{};
            if (self.head) |head| {
                new_list.head = try head.dupe(allocator);
            }
            return new_list;
        }

        pub fn getIdxOf(self: *const Self, search_for: *const T) ?usize {
            const eql_function = comptime if (eql_fn) |eql_func|
                eql_func
            else blk: {
                meta.requireDecl(T, "eql", fn (*const T, *const T) bool);
                meta.checkFunctionSignature(T, "eql", &.{ *const T, *const T }, bool, false);
                break :blk T.eql;
            };

            var current: ?*NodeType = self.head;
            var i: usize = 0;
            while (current) |node| : (i += 1) {
                if (eql_function(&node.value, search_for)) {
                    return i;
                }
                current = node.next;
            }
            return null;
        }

        pub fn getAt(self: *const Self, idx: usize) ?*T {
            if (self.getNodeAt(idx)) |node| {
                return &node.value;
            }
            return null;
        }

        pub fn insertAt(self: *Self, allocator: std.mem.Allocator, idx: usize, value: T) (SinglyLinkedListError || std.mem.Allocator.Error)!void {
            if (idx == 0) {
                const new_head: *NodeType = try allocator.create(NodeType);
                new_head.* = .{ .next = self.head, .value = value };

                self.head = new_head;
                return;
            }
            var insert_after: *NodeType = self.getNodeAt(idx - 1) orelse
                return SinglyLinkedListError.IdxOutOfBounds;
            const inserted_ptr: *NodeType = try allocator.create(NodeType);
            inserted_ptr.* = .{ .next = insert_after.next, .value = value };
            insert_after.next = inserted_ptr;
        }

        pub fn removeAt(self: *Self, allocator: std.mem.Allocator, idx: usize) SinglyLinkedListError!void {
            if (idx == 0) {
                const old_head: *NodeType = self.head orelse
                    return SinglyLinkedListError.IdxOutOfBounds;
                self.head = old_head.next;
                old_head.deinit(allocator);
                allocator.destroy(old_head);
                return;
            }
            var remove_after: *NodeType = self.getNodeAt(idx - 1) orelse
                return SinglyLinkedListError.IdxOutOfBounds;
            const item_to_remove: *NodeType = remove_after.next orelse
                return SinglyLinkedListError.IdxOutOfBounds;
            const next: ?*NodeType = item_to_remove.next;
            remove_after.next = next;
            item_to_remove.deinit(allocator);
            allocator.destroy(item_to_remove);
        }

        pub fn len(self: *const Self) usize {
            if (self.head) |head_value| {
                var length: usize = 0;
                var next: ?*NodeType = head_value;
                while (next) |next_value| {
                    length += 1;
                    next = next_value.next;
                }
                return length;
            }
            return 0;
        }

        pub fn getNodeAt(self: *const Self, idx: usize) ?*NodeType {
            if (self.head) |head_value| {
                var length: usize = idx;
                var current: ?*NodeType = head_value;
                while (length > 0) {
                    if (current == null) {
                        return null;
                    }
                    length -= 1;
                    current = current.?.next;
                }
                return current;
            }
            return null;
        }

        pub fn iter(self: *Self) Iterator {
            return .{ .current = self.head };
        }
    };
}

fn Node(
    comptime T: type,
    comptime deinit_fn: ?fn (*T, std.mem.Allocator) void,
    comptime dupe_fn: ?fn (*const T, std.mem.Allocator) anyerror!T,
) type {
    return struct {
        const Self = @This();

        next: ?*@This(),
        value: T,

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            const deinit_function = comptime if (deinit_fn) |deinit_func|
                deinit_func
            else blk: {
                meta.requireDecl(T, "deinit", fn (*T, std.mem.Allocator) void);
                meta.checkFunctionSignature(T, "deinit", &.{ *T, std.mem.Allocator }, void, false);
                break :blk T.deinit;
            };

            deinit_function(&self.value, allocator);
        }

        pub fn dupe(self: *const Self, allocator: std.mem.Allocator) anyerror!*Self {
            const dupe_function = comptime if (dupe_fn) |dupe_func|
                dupe_func
            else blk: {
                meta.requireDecl(T, "dupe", fn (*const T, std.mem.Allocator) anyerror!T);
                meta.checkFunctionSignature(T, "dupe", &.{ *const T, std.mem.Allocator }, T, true);
                break :blk T.dupe;
            };

            const duped_node: *Self = try allocator.create(Self);
            if (self.next) |next| {
                duped_node.next = try next.dupe(allocator);
            } else {
                duped_node.next = null;
            }
            duped_node.value = try dupe_function(&self.value, allocator);
            return duped_node;
        }

        pub fn clearAndFreeAll(self: *Self, allocator: std.mem.Allocator) void {
            const deinit_function = comptime if (deinit_fn) |deinit_func|
                deinit_func
            else blk: {
                meta.requireDecl(T, "deinit", fn (*T, std.mem.Allocator) void);
                meta.checkFunctionSignature(T, "deinit", &.{ *T, std.mem.Allocator }, void, false);
                break :blk T.deinit;
            };

            if (self.next) |next| {
                next.clearAndFreeAll(allocator);
            }
            deinit_function(&self.value, allocator);
            if (self.next) |next| {
                allocator.destroy(next);
                self.next = null;
            }
        }
    };
}
