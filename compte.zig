const std = @import("std");

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

const NB: usize = 6;

fn essai(v: *[NB]u64, size: usize, r: u64) bool {
    var i: usize = 0;
    while (i < size) {
        var a: u64 = v[i];
        var j: usize = i + 1;
        while (j < size) {
            var b: u64 = v[j];
            var a1: u64 = @max(a, b);
            var a2: u64 = @min(a, b);
            for (ops, 0..) |f, k| {
                if (f(a1, a2)) |res| {
                    if (res == r) {
                        std.debug.print("{d} {s} {d} = {d}\n", .{ a1, nops[k], a2, res });
                        return true;
                    }
                    if (size > 2) {
                        v[i] = res;
                        v[j] = v[size - 1];
                        if (essai(v, size - 1, r)) {
                            std.debug.print("{d} {s} {d} = {d}\n", .{ a1, nops[k], a2, res });
                            return true;
                        }
                        v[j] = b;
                        v[i] = a;
                    }
                }
            }
            j += 1;
        }
        i += 1;
    }
    i = 0;
    while (i < size) {
        var a: u64 = v[i];
        if (a != 1) {
            var res = @mulWithOverflow(a, a);
            if (res[1] == 0) {
                if (res[0] == r) {
                    std.debug.print("{d}^2 = {d}\n", .{ a, res[0] });
                    return true;
                }
                v[i] = res[0];
                if (essai(v, size, r)) {
                    std.debug.print("{d}^2 = {d}\n", .{ a, res[0] });
                    return true;
                }
                v[i] = a;
            }
        }
        i += 1;
    }
    return false;
}

pub fn main() void {
    var tab: [NB]u64 = undefined;
    var res: u64 = 858;
    tab[0] = 1;
    tab[1] = 1;
    tab[2] = 10;
    tab[3] = 10;
    tab[4] = 25;
    tab[5] = 100;

    if (essai(&tab, NB, res)) {
        std.debug.print("{d}\n", .{res});
    }
}
