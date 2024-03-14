const std = @import("std");
const assert = std.debug.assert;

const NB: usize = 6;
const SQUARE: bool = true;

const HASH_NB_BITS: u8 = 29;
const VALS_NB_BITS: u8 = 29;
const MAXV = 1000;

const Ht = u64;

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
var hashesv2: [NB][]Ht = undefined;
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

pub fn essai(tab: *Nbs, size: usize, res: u64, hv: Ht) bool {
    for (0..size) |i| {
        assert(tab[i].nb>0);
        const a = tab[i].x;
        var nhv = hv^hashesv[tab[i].nb-1][tab[i].x];
        tab[i].nb-=1;
        if (tab[i].nb>0) nhv^=hashesv[tab[i].nb-1][tab[i].x];
        const jmin = if (tab[i].nb==0) then i+1 else i;
        for (jmin..size) |j| {
            assert(tab[j].nb>0);
            const b = tab[j].x;
            var nhv2 = nhv^hashesv[tab[j].nb-1][tab[j].x];
            tab[j].nb-=1;
            if (tab[i].nb>0) nhv2^=hashesv[tab[j].nb-1][tab[j].x];
            const a1: u64 = @max(a, b);
            const a2: u64 = @min(a, b);
            for (ops, 0..) |f, k| {
                if (f(a1, a2)) |res| {
                    if (res < MAXV) reached[res] = true;
                    if (res == r) {
                        std.debug.print("{d} {s} {d} = {d}\n", .{ a1, nops[k], a2, res });
                        return true;
                    }
                    for (0..size) |l| {
                        if ((tab[l].nb>0) and (tab[l].x==res)) {
                            
                            break;
                        }
                    } else {
                    }

                    
                    
                    if () {
                        if (size > 2) {
                            v[i] = res;
                            v[j] = v[size - 1];
                            var tmp: bool = undefined;
                            if (!HASH)
                                tmp = essai(v, size - 1, r, nhv)
                            else
                                tmp = essai(v, size - 1, r, nhv + hashesv[res]);

            
        }
    }
    return ((res == 0) and (tab2[0].x == 0) and (size == 0) and (hv == 0));
}

pub fn compte(tab2: *Nbs, size: usize, res: u64) bool {
    var hv: Ht = 0;
    if (HASH) {
        for (0..size) |i| {
            const t = tab2[i];
            hv ^= hashesv2[t.nb - 1][t.x];
        }
        //        for (hashes) |*a| a.* = 0;
        @memset(hashes, 0);
    }
    for (&reached) |*b| b.* = false;
    return essai(tab2, size, res, hv);
}

pub fn main() !void {
    if (HASH) {
        const allocator = std.heap.page_allocator;
        const RndGen = std.rand.DefaultPrng;
        var rnd = RndGen.init(0);
        hashes = try allocator.alloc(Ht, HASH_SIZE);
        hashesv2[0] = try allocator.alloc(Ht, VALS_SIZE);
        for (1..NB) |i| {
            hashesv2[i] = try allocator.alloc(Ht, VALS_SIZE2);
        }
        for (0..NB) |i| {
            const m = if (i == 0) VALS_SIZE else VALS_SIZE2;
            for (0..m) |j| {
                hashesv2[i][j] = rnd.random().int(Ht);
            }
        }
    }

    var tab2 = Nbs{
        Nb{ .x = 1, .nb = 2 },
        Nb{ .x = 10, .nb = 2 },
        Nb{ .x = 75, .nb = 1 },
        Nb{ .x = 100, .nb = 1 },
        Nb{ .x = 7, .nb = 0 },
        Nb{ .x = 8, .nb = 0 },
    };
    const size: usize = 4;
    std.debug.print("{d}\n", .{tab2[0].x});

    const res: u64 = 0;

    var t = std.time.milliTimestamp();
    if (compte(&tab2, size, res)) {
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
