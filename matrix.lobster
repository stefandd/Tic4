// Writen by Attractive Chaos; distributed under the MIT license // converted to Lobster

def T(a:[[float]]):
    let m, n, x = a.length, a[0].length, []
    for (n) i:
        x.push([])
        for (m) j:
            x[i].push(a[j][i])
    return x

def mul(a:[[float]], b:[[float]]):
    assert a[0].length == b.length
    let m, n, p, x = a.length, a[0].length, b[0].length, []
    let c = T(b) // transpose for efficiency
    for (m) i:
        x.push([])
        let xi = x[i]
        for (p) j:
            var sum, ai, cj = 0.0, a[i], c[j]
            for (n) k:
                sum = sum + ai[k] * cj[k]
            xi.push(sum)
    return x

def matgen(n):
    let a, tmp = [], 1.0 / n / n
    for (n) i:
        a.push([])        
        for (n) j:
            a[i].push(tmp * (i - j) * (i + j)) // in the Lua version it says -2 here, but the indices in Lobster are 0-based
    return a

let n = 800
let a, b = matgen(n), matgen(n)
let t0 = seconds_elapsed()
let c = mul(a, b)
let t1 = seconds_elapsed()

print(c[0][0])
print(t1-t0)
