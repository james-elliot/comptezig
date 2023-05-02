const std = @import("std");

const NB: usize = 6;
const SQUARE: bool = true;
const HASH: bool = false;

const HASH_NB_BITS: u8 = 28;
const VALS_NB_BITS: u8 = 16;
const MAXV = 1000;

const HASH_SIZE: usize = 1 << HASH_NB_BITS;
const HASH_MASK: u64 = HASH_SIZE - 1;

const VALS_SIZE: usize = 1 << VALS_NB_BITS;

var hashes: []u64 = undefined;
var hashesv: []u64 = undefined;
var reached: [MAXV]bool = undefined;

fn add(a: u64, b: u64) ?u64 {
    var res = @addWithOverflow(a, b);
    if (res[1] == 0) return res[0];
    return null;
}

fn sub(a: u64, b: u64) ?u64 {
    if ((a != b) and ((a - b) != b)) return a - b;
    return null;
}

fn mul(a: u64, b: u64) ?u64 {
    if (b != 1) {
        var res = @mulWithOverflow(a, b);
        if (res[1] == 0) return res[0];
    }
    return null;
}

fn div(a: u64, b: u64) ?u64 {
    if ((b != 1) and ((a % b) == 0) and ((a / b) != b)) return a / b;
    return null;
}

const ops = [4]*const fn (u64, u64) ?u64{ add, sub, mul, div };
const nops = [_][]const u8{ "+", "-", "*", "/" };

fn update_hash(res: u64, hv: u64) bool {
    if (res < VALS_SIZE) {
        var nhv: u64 = hv + hashesv[res];
        if (hashes[nhv & HASH_MASK] != nhv) {
            hashes[nhv & HASH_MASK] = nhv;
            return true;
        }
    }
    return false;
}
fn essai(v: *[NB]u64, size: usize, r: u64, hv: u64) bool {
    var i: usize = 0;
    while (i < size) {
        var a: u64 = v[i];
        var j: usize = i + 1;
        while (j < size) {
            var b: u64 = v[j];
            var a1: u64 = @max(a, b);
            var a2: u64 = @min(a, b);
            var nhv = hv;
            if (HASH) nhv = nhv - hashesv[a1] - hashesv[a2];
            for (ops, 0..) |f, k| {
                if (f(a1, a2)) |res| {
                    if ((!HASH) or (update_hash(res, nhv))) {
                        if (res < MAXV) reached[res] = true;
                        if (res == r) {
                            std.debug.print("{d} {s} {d} = {d}\n", .{ a1, nops[k], a2, res });
                            return true;
                        }
                        if (size > 2) {
                            v[i] = res;
                            v[j] = v[size - 1];
                            var tmp: bool = undefined;
                            if (!HASH)
                                tmp = essai(v, size - 1, r, nhv)
                            else
                                tmp = essai(v, size - 1, r, nhv + hashesv[res]);
                            if (tmp) {
                                std.debug.print("{d} {s} {d} = {d}\n", .{ a1, nops[k], a2, res });
                                return true;
                            }
                            v[j] = b;
                            v[i] = a;
                        }
                    }
                }
            }
            j += 1;
        }
        i += 1;
    }
    if (SQUARE) {
        i = 0;
        while (i < size) {
            var a: u64 = v[i];
            var nhv = hv;
            if (HASH) nhv -= hashesv[a];
            if (a != 1) {
                var res = @mulWithOverflow(a, a);
                if ((res[1] == 0) and ((!HASH) or (update_hash(res[0], nhv)))) {
                    if (res[0] < MAXV) reached[res[0]] = true;
                    if (res[0] == r) {
                        std.debug.print("{d}^2 = {d}\n", .{ a, res[0] });
                        return true;
                    }
                    v[i] = res[0];
                    var tmp: bool = undefined;
                    if (!HASH)
                        tmp = essai(v, size, r, hv)
                    else
                        tmp = essai(v, size, r, hv + hashesv[res[0]]);
                    if (tmp) {
                        std.debug.print("{d}^2 = {d}\n", .{ a, res[0] });
                        return true;
                    }
                    v[i] = a;
                }
            }
            i += 1;
        }
    }
    return false;
}

pub fn compte(tab: *[NB]u64, res: u64) bool {
    var hv: u64 = 0;
    if (HASH) {
        for (tab) |x| {
            hv += hashesv[x];
        }
        //        for (hashes) |*a| a.* = 0;
        @memset(hashes, 0);
    }
    for (&reached) |*b| b.* = false;
    return essai(tab, NB, res, hv);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const RndGen = std.rand.DefaultPrng;
    hashes = try allocator.alloc(u64, HASH_SIZE);
    defer allocator.free(hashes);
    var rnd = RndGen.init(0);
    hashesv = try allocator.alloc(u64, VALS_SIZE);
    defer allocator.free(hashesv);
    if (HASH) {
        for (hashesv) |*a| a.* = rnd.random().int(u60);
    }

    var tab = [NB]u64{ 1, 1, 10, 10, 25, 100 };
    var res: u64 = 0;

    var t = std.time.milliTimestamp();
    if (compte(&tab, res)) {
        std.debug.print("OK\n", .{});
    } else {
        std.debug.print("NOK\n", .{});
    }
    t = std.time.milliTimestamp() - t;

    for (reached, 0..) |b, i| {
        if (!b) std.debug.print("{d} ", .{i});
    }

    std.debug.print("{d}ms\n", .{t});
}
