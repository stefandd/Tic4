// Writen by Attractive Chaos; distributed under the MIT license // converted to Lobster
import std

def T(a:[[float]]):
    let m, n, x = a.length, a[0].length, []
    return map(n) i:
                map(m) j:
                    a[j][i]

def mul(a:[[float]], b:[[float]]):
    assert a[0].length == b.length
    let m, n, p, x = a.length, a[0].length, b[0].length, []
    let c = T(b) // transpose for efficiency
    return map(m) i: map(p) j:
                        var sum, ai, cj = 0.0, a[i], c[j]
                        for (n) k:
                            sum += ai[k] * cj[k]
                        sum

def mul2(a:[[float]], b:[[float]]):
    assert a[0].length == b.length
    let c = T(b) // transpose for efficiency
    let m, p = a.length, c.length
    return map(m) i: map(p) j: dot(a[i], c[j])

def matgen(n): // generate a square matrix
    let tmp = 1.0 / n / n
    return map(n) i:
                map(n) j:
                    tmp * (i - j) * (i + j)

let n = 800
let a, b = matgen(n), matgen(n)

let t0 = seconds_elapsed()
let c = mul(a, b)
let t1 = seconds_elapsed()
print c[0][0]
print "Slow multiplication " + (t1-t0) + "s"

let d = mul2(a, b)
let t2 = seconds_elapsed()
print d[0][0]
print "Fast multiplication " + (t2-t1) + "s"
