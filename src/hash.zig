const std = @import("std");
const meta = @import("meta.zig");

pub const HashError = error{
    InputTooSmall,
};

pub fn createHash(input: []const u8) HashError![8]u8 {
    const charset = "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    var hash: [8]u8 = [_]u8{'0'} ** 8;
    var seed: u32 = 2_166_136_261;

    if (input.len < hash.len) {
        return HashError.InputTooSmall;
    }

    // FNV-1a over bytes; perform multiplication in u64 and truncate
    for (input) |b| {
        seed ^= @intCast(b);
        seed = @truncate(@as(u64, seed) * 16_777_619);
    }

    for (0..hash.len) |i| {
        // compute pos_hash with truncating 32-bit behavior
        var pos_hash: u32 = seed ^ @as(u32, @truncate(i * 0x9E_37_79_B9));

        pos_hash = @truncate(@as(u64, pos_hash) * 0x85_EB_CA_6B);
        pos_hash ^= pos_hash >> 13;
        pos_hash = @truncate(@as(u64, pos_hash) * 0xC2_B2_AE_35);
        pos_hash ^= pos_hash >> 16;

        const idx: usize = @intCast(pos_hash % charset.len);
        hash[i] = charset[idx];

        seed = pos_hash;
    }

    return hash;
}

pub fn HashMap(comptime T: type) type {
    const T_has_deinit: bool = meta.hasDecl(T, "deinit", fn (*const T, std.mem.Allocator) anyerror!T);
    return struct {
        const Self = @This();

        first: ?*Node = null,

        pub const empty: Self = .{};

        pub const Kvp = struct {
            key: [8]u8,
            value: T,
        };

        pub const Node = struct {
            kvp: Kvp,
            next: ?*@This(),
        };

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            if (self.first == null) {
                return;
            }
            var current: *Node = self.first.?;
            var next: ?*Node = current.next;
            while (next) |next_node| {
                if (T_has_deinit) {
                    current.kvp.value.deinit(allocator);
                }
                allocator.destroy(current);
                current = next_node;
                next = next_node.next;
            }
            if (T_has_deinit) {
                current.kvp.value.deinit(allocator);
            }
            allocator.destroy(current);
        }

        /// Inserts the given kvp into the hash map and returns a pointer to the value in the newly created (or already existent) kvp
        /// Note: Does not clone the value, just shallow-copies it into the map
        pub fn insert(self: *Self, allocator: std.mem.Allocator, key: *const [8]u8, value: T) !*T {
            if (self.first == null) {
                self.first = try allocator.create(Node);
                self.first.?.* = Node{
                    .kvp = .{
                        .key = key.*,
                        .value = value,
                    },
                    .next = null,
                };
                return &self.first.?.kvp.value;
            }
            var node: *Node = self.first.?;
            if (std.mem.eql(u8, &node.kvp.key, key)) {
                return &node.kvp.value;
            }
            while (node.next) |next| {
                node = next;
                if (std.mem.eql(u8, &node.kvp.key, key)) {
                    return &node.kvp.value;
                }
            }
            node.next = try allocator.create(Node);
            node = node.next.?;
            node.next = null;
            node.kvp.key = key.*;
            return &node.kvp.value;
        }

        /// Does nothing if the key is not present in the hash map
        pub fn delete(self: *Self, allocator: std.mem.Allocator, key: *const [8]u8) void {
            if (self.first == null) {
                return;
            }
            var current: *Node = self.first.?;
            if (std.mem.eql(u8, &current.kvp.key, key)) {
                self.first = current.next;
                allocator.destroy(current);
                return;
            }
            var next: ?*Node = current.next;
            while (next) |next_node| {
                if (std.mem.eql(u8, &next_node.kvp.key, key)) {
                    if (T_has_deinit) {
                        next_node.kvp.value.deinit(allocator);
                    }
                    current.next = next_node.next;
                    allocator.destroy(next_node);
                    return;
                }
                next = next_node.next;
            }
        }

        /// Returns a pointer to the value stored at the given key, if the key is present in the map
        pub fn get(self: *Self, key: *const [8]u8) ?*T {
            var current: ?*Node = self.first;
            while (current) |value| {
                if (std.mem.eql(u8, &value.kvp.key, key)) {
                    return &value.kvp.value;
                }
                current = value.next;
            }
            return null;
        }
    };
}
