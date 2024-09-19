const std = @import("std");

const SQUARE: bool = true;
const VAL_MAX: u64 = 1 << 9;
const NB: usize = 6;
const MAXV = 1000;

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
const nops2 = [_]u8{ '+', '-', '*', '/' };

fn essai(v: *[NB]u64, size: usize, r: u64) bool {
    var i: usize = 0;
    while (i < size) {
        const a: u64 = v[i];
        var j: usize = i + 1;
        while (j < size) {
            const b: u64 = v[j];
            const a1: u64 = @max(a, b);
            const a2: u64 = @min(a, b);
            for (ops, 0..) |f, k| {
                if (f(a1, a2)) |res| {
                    if (res < MAXV) reached[res] = true;
                    if (res == r) {
                        std.debug.print("{d} {c} {d} = {d}\n", .{ a1, nops2[k], a2, res });
                        return true;
                    }
                    if (size > 2) {
                        v[i] = res;
                        v[j] = v[size - 1];
                        const tmp: bool = essai(v, size - 1, r);
                        v[j] = b;
                        v[i] = a;
                        if (tmp) {
                            std.debug.print("(", .{});
                            for (0..size) |l| {
                                if ((l != i) and (l != j)) std.debug.print("{d} ", .{v[l]});
                            }
                            std.debug.print("{d}) ", .{res});
                            std.debug.print("{d} {c} {d} = {d}\n", .{ a1, nops2[k], a2, res });
                            return true;
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
            const a: u64 = v[i];
            if ((a != 1) and (a < VAL_MAX)) {
                const res = @mulWithOverflow(a, a);
                if (res[1] == 0) {
                    if (res[0] < MAXV) reached[res[0]] = true;
                    if (res[0] == r) {
                        std.debug.print("{d}^2 = {d}\n", .{ a, res[0] });
                        return true;
                    }
                    v[i] = res[0];
                    const tmp: bool = essai(v, size, r);
                    v[i] = a;
                    if (tmp) {
                        std.debug.print("(", .{});
                        for (0..size) |l| {
                            if (l != i) std.debug.print("{d} ", .{v[l]});
                        }
                        std.debug.print("{d}) ", .{res[0]});
                        std.debug.print("{d}^2 = {d}\n", .{ a, res[0] });
                        return true;
                    }
                }
            }
            i += 1;
        }
    }
    return false;
}

pub fn compte(tab: *[NB]u64, res: u64) bool {
    for (&reached) |*b| b.* = false;
    return essai(tab, NB, res);
}

pub fn main() !void {
    var tab = [NB]u64{ 1, 1, 10, 10, 75, 100 };
    const res: u64 = 0;

    var t = std.time.milliTimestamp();
    if (compte(&tab, res)) {
        std.debug.print("OK\n", .{});
    } else {
        std.debug.print("NOK\n", .{});
        for (reached, 0..) |b, i| {
            if ((!b) and (i != 0)) std.debug.print("{d} ", .{i});
        }
    }
    t = std.time.milliTimestamp() - t;

    std.debug.print("\n{d}ms\n", .{t});
}
