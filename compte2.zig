const std = @import("std");
const assert = std.debug.assert;

const NB: usize = 6;
const SQUARE: bool = true;
const DO_HASH: bool = true;

const HASH_NB_BITS: u8 = 25;
const VALS_NB_BITS: u8 = 25;
const MAXV = 1000;

const Ht = u128;

const Nb = struct {
    x: u64,
    nb: u8,
};

const Nbs = [NB]Nb;

const HASH_SIZE: usize = 1 << HASH_NB_BITS;
const HASH_MASK: Ht = HASH_SIZE - 1;

const VALS_SIZE: usize = 1 << VALS_NB_BITS;
const VALS_SIZE2: usize = VALS_SIZE / 8;

var hashes: []Ht = undefined;
var hashesv: [NB][]Ht = undefined;
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

pub fn test_hash(hv: Ht) bool {
    const mask: Ht = hv & HASH_MASK;
    const ind: usize = @intCast(mask);
    if (hashes[ind] != hv) {
        hashes[ind] = hv;
        return false;
    }
    return true;
}

pub fn print_t(tab: *Nbs, size: usize) void {
    std.debug.print("size = {d}\n", .{size});
    for (0..NB) |i| {
        std.debug.print("({d},{d}) ", .{ tab[i].nb, tab[i].x });
    }
    std.debug.print("\n", .{});
}

pub fn compute_hash(tab2: *Nbs) Ht {
    var hv: Ht = 0;
    for (0..NB) |i| {
        const t = tab2[i];
        if ((t.nb > 0) and (t.x < VALS_SIZE)) hv ^= hashesv[t.nb - 1][t.x];
    }
    return hv;
}

pub fn essai(tab: *Nbs, size: usize, r: u64, hv: Ht) bool {
    var nhv: Ht = undefined;
    var nhv2: Ht = undefined;
    var nhv3: Ht = undefined;
    const thv: Ht = compute_hash(tab);
    if ((DO_HASH) and (thv != hv)) {
        std.debug.print("Echec\n", .{});
        std.process.exit(0);
    }
    if ((DO_HASH) and (test_hash(hv))) return false;
    for (0..NB) |i| {
        if (tab[i].nb == 0) continue;
        const a = tab[i].x;
        if (DO_HASH) nhv = hv ^ hashesv[tab[i].nb - 1][tab[i].x];
        tab[i].nb -= 1;
        if ((DO_HASH) and (tab[i].nb > 0)) nhv ^= hashesv[tab[i].nb - 1][tab[i].x];
        const jmin = if (tab[i].nb == 0) (i + 1) else i;
        for (jmin..NB) |j| {
            if (tab[j].nb == 0) continue;
            const b = tab[j].x;
            if (DO_HASH) nhv2 = nhv ^ hashesv[tab[j].nb - 1][tab[j].x];
            tab[j].nb -= 1;
            if ((DO_HASH) and (tab[j].nb > 0)) nhv2 ^= hashesv[tab[j].nb - 1][tab[j].x];
            const a1: u64 = @max(a, b);
            const a2: u64 = @min(a, b);
            for (ops, 0..) |f, k| {
                if (f(a1, a2)) |res| {
                    if (res >= VALS_SIZE) continue;
                    if (res < MAXV) reached[res] = true;
                    if (res == r) {
                        std.debug.print("{d} {s} {d} = {d}\n", .{ a1, nops[k], a2, res });
                        return true;
                    }
                    if (size >= 3) {
                        var ind: usize = 0;
                        for (0..size) |l| {
                            if (tab[l].nb == 0) ind = l;
                            if ((tab[l].nb > 0) and (tab[l].x == res)) {
                                nhv3 = nhv2 ^ hashesv[tab[l].nb - 1][tab[l].x];
                                tab[l].nb += 1;
                                nhv3 ^= hashesv[tab[l].nb - 1][tab[l].x];
                                ind = l;
                                break;
                            }
                        } else {
                            tab[ind].nb += 1;
                            tab[ind].x = res;
                            nhv3 = nhv2 ^ hashesv[tab[ind].nb - 1][tab[ind].x];
                        }
                        if (essai(tab, size - 1, r, nhv3)) {
                            std.debug.print("{d} {s} {d} = {d}\n", .{ a1, nops[k], a2, res });
                            return true;
                        }
                        tab[ind].nb -= 1;
                    }
                }
            }
            tab[j].x = b;
            tab[j].nb += 1;
        }
        tab[i].x = a;
        tab[i].nb += 1;
    }
    return false;
}

pub fn compte(tab2: *Nbs, size: usize, res: u64) bool {
    const hv: Ht = compute_hash(tab2);
    return essai(tab2, size, res, hv);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const RndGen = std.Random.DefaultPrng;
    var rnd = RndGen.init(0);
    hashes = try allocator.alloc(Ht, HASH_SIZE);
    hashesv[0] = try allocator.alloc(Ht, VALS_SIZE);
    for (1..NB) |i| {
        hashesv[i] = try allocator.alloc(Ht, VALS_SIZE2);
    }
    for (0..NB) |i| {
        const m = if (i == 0) VALS_SIZE else VALS_SIZE2;
        for (0..m) |j| {
            hashesv[i][j] = rnd.random().int(Ht);
        }
    }

    var dt: i64 = 0;
    for (0..1) |_| {
        @memset(&reached, false);
        @memset(hashes, 0);
        var tab2 = Nbs{
            Nb{ .x = 1, .nb = 2 },
            Nb{ .x = 10, .nb = 2 },
            Nb{ .x = 75, .nb = 1 },
            Nb{ .x = 100, .nb = 1 },
            Nb{ .x = 7, .nb = 0 },
            Nb{ .x = 8, .nb = 0 },
        };
        const size: usize = NB;
        const res: u64 = 181;
        var t = std.time.milliTimestamp();
        if (compte(&tab2, size, res)) {
            //            std.debug.print("OK\n", .{});
        } else {
            //          std.debug.print("NOK\n", .{});
        }
        t = std.time.milliTimestamp() - t;
        dt += t;
        //        std.debug.print("\n{d}:{d}ms\n", .{ i, t });
    }
    std.debug.print("\n{d}ms\n", .{dt});
    for (reached, 0..) |b, i| {
        if ((!b) and (i != 0)) std.debug.print("{d} ", .{i});
    }
}
