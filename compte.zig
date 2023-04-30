const std = @import("std");

fn add(a: u64, b: u64) ?u64 {
    var res = @addWithOverflow(a, b);
    if (res[1] == 0) return res[0];
    return null;
}

fn sub(a: u64, b: u64) ?u64 {
    if (a != b) return a - b;
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
    if ((b != 1) and ((a % b) == 0)) return a / b;
    return null;
}

const ops = [4]*const fn (u64, u64) ?u64{ add, sub, mul, div };

const NB: usize = 6;
fn essai(v: [NB]u64, size: usize, r: u64) void {
    var nv: [NB]u64 = undefined;
    var i: usize = 0;
    while (i < v.len) {
        var a: u64 = v[i];
        var j: usize = i + 1;
        while (j < v.len) {
            var b: u64 = v[j];
            var a1: u64 = @max(a, b);
            var a2: u64 = @min(a, b);
            for (ops) |f| {
                var reso: ?u64 = f(a1, a2);
                if (reso) |res| {
                    if (res == r) {
                        std.debug.print("{d}\n", .{res});
                    }
                    if (size > 2) {
                        var k1: usize = 0;
                        var k2: usize = 0;
                        while (k1 < v.len) {
                            if ((k1 != i) and (k1 != j)) {
                                nv[k2] = v[k1];
                                k2 += 1;
                            }
                            k1 += 1;
                        }
                        nv[k2] = res;
                        essai(nv, size - 1, r);
                    }
                }
            }
            j += 1;
        }
        i += 1;
    }
}

pub fn main() void {
    var tab: [NB]u64 = undefined;
    tab[0] = 1;
    tab[1] = 2;
    tab[2] = 3;
    tab[3] = 4;
    tab[4] = 5;
    tab[5] = 6;

    essai(tab, NB, 999);
}
