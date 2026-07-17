const std = @import("std");

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
