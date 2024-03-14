const std = @import("std");

const NB: usize = 6;
const SQUARE: bool = true;
const HASH: bool = true;

const HASH_NB_BITS: u8 = 29;
const VALS_NB_BITS: u8 = 29;
const MAXV = 1000;

const Ht = u128;
const Ht2 = u120;

const Nb = struct {
    x: u64,
    nb: u8,
};

const Nbs = [NB]Nb;

const HASH_SIZE: usize = 1 << HASH_NB_BITS;
const HASH_MASK: Ht = HASH_SIZE - 1;

const VALS_SIZE: usize = 1 << VALS_NB_BITS;

var hashes: []Ht = undefined;
var hashesv: []Ht = undefined;
var reached: [MAXV]bool = undefined;

fn add(a: u64, b: u64) ?u64 {
    const res = @addWithOverflow(a, b);
    if (res[1] == 0) return res[0];
    return null;
}

fn sub(a: u64, b: u64) ?u64 {
    if ((a != b) and ((a - b) != b)) return a - b;
    return null;
}

fn mul(a: u64, b: u64) ?u64 {
    if (b != 1) {
        const res = @mulWithOverflow(a, b);
        if (res[1] == 0) return res[0];
    }
    return null;
}

fn div(a: u64, b: u64) ?u64 {
    if ((b != 1) and ((a % b) == 0) and ((a / b) != b)) return a / b;
    return null;
}

const ops = [_]*const fn (u64, u64) ?u64{ add, sub, mul, div };
const nops = [_][]const u8{ "+", "-", "*", "/" };

pub fn essai(tab2: *Nbs, n: u64, res: u64, hv: Ht) bool {
    return ((res == 0) and (tab2[0].x == 0) and (n == 0) and (hv == 0));
}

pub fn compte(tab2: *Nbs, res: u64) bool {
    var hv: Ht = 0;
    if (HASH) {
        for (tab2) |e| {
            hv += hashesv[e.x];
        }
        //        for (hashes) |*a| a.* = 0;
        @memset(hashes, 0);
    }
    for (&reached) |*b| b.* = false;
    return essai(tab2, NB, res, hv);
}

pub fn main() !void {
    if (HASH) {
        const allocator = std.heap.page_allocator;
        const RndGen = std.rand.DefaultPrng;
        hashes = try allocator.alloc(Ht, HASH_SIZE);
        //        defer allocator.free(hashes);
        var rnd = RndGen.init(0);
        hashesv = try allocator.alloc(Ht, VALS_SIZE);
        //        defer allocator.free(hashesv);
        for (hashesv) |*a| a.* = rnd.random().int(Ht2);
    }

    var tab2 = Nbs{
        Nb{ .x = 1, .nb = 2 },
        Nb{ .x = 10, .nb = 2 },
        Nb{ .x = 75, .nb = 1 },
        Nb{ .x = 100, .nb = 1 },
        Nb{ .x = 7, .nb = 0 },
        Nb{ .x = 8, .nb = 0 },
    };
    tab2[0].x += 1;
    std.debug.print("{d}\n", .{tab2[0].x});

    const res: u64 = 0;

    var t = std.time.milliTimestamp();
    if (compte(&tab2, res)) {
        std.debug.print("OK\n", .{});
    } else {
        std.debug.print("NOK\n", .{});
    }
    t = std.time.milliTimestamp() - t;

    for (reached, 0..) |b, i| {
        if ((!b) and (i != 0)) std.debug.print("{d} ", .{i});
    }

    std.debug.print("\n{d}ms\n", .{t});
}
