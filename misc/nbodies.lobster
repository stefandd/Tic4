import std
import vec

let PI = 3.1415926535897932384626433
let SOLAR_MASS = 4.*PI*PI
let DAYS_PER_YEAR = 365.24

struct body:
  x:xyz_f
  v:xyz_f
  mass:float

let bodies:[body] = [
                        //sun
                        body{ x : xyz_f{0,0,0}, v : xyz_f{0,0,0}, mass : SOLAR_MASS },
                        //jupiter
                        body{ x : xyz_f{4.84143144246472090,-1.16032004402742839,-1.03622044471123109e-01},
                              v : xyz_f{1.66007664274403694e-03 * DAYS_PER_YEAR, 7.69901118419740425e-03 * DAYS_PER_YEAR, -6.90460016972063023e-05 * DAYS_PER_YEAR},
                              mass : 9.54791938424326609e-04 * SOLAR_MASS },
                        //saturn
                        body{ x : xyz_f{8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01},
                              v : xyz_f{ -2.76742510726862411e-03 * DAYS_PER_YEAR, 4.99852801234917238e-03 * DAYS_PER_YEAR, 2.30417297573763929e-05 * DAYS_PER_YEAR },
                              mass : 2.85885980666130812e-04 * SOLAR_MASS },
                        //uranus
                        body{ x : xyz_f{ 1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01 },
                              v : xyz_f{ 2.96460137564761618e-03 * DAYS_PER_YEAR, 2.37847173959480950e-03 * DAYS_PER_YEAR, -2.96589568540237556e-05 * DAYS_PER_YEAR },
                              mass : 4.36624404335156298e-05 * SOLAR_MASS },
                        //neptune
                        body{ x : xyz_f{ 1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01 },
                              v : xyz_f{ 2.68067772490389322e-03 * DAYS_PER_YEAR, 1.62824170038242295e-03 * DAYS_PER_YEAR, -9.51592254519715870e-05 * DAYS_PER_YEAR },
                              mass : 5.15138902046611451e-05 * SOLAR_MASS }
                    ] 
let nbodies = 5

def offset_momentum():
    var px:xyz_f = xyz_f{0, 0, 0}
    for (bodies) b:
        px -= b.v * b.mass
    bodies[0] = body{ bodies[0].x, px / SOLAR_MASS, bodies[0].mass}


def advance():
    for (bodies.length) i:
        let b = bodies[i]
        var b_v:xyz_f = b.v
        for_range(i + 1, nbodies) j:
            let b2:body = bodies[j]
            let dx = b.x - b2.x
            let inv_distance = 1.0 / magnitude(dx)
            let mag = inv_distance * inv_distance * inv_distance
            b_v -= dx * (b2.mass * mag)
            bodies[j] = body { b2.x, b2.v + dx * (b.mass * mag), b2.mass}
        bodies[i] = body {b.x + b_v, b_v, b.mass}


def energy() -> float:
    var e = 0.0
    var i = 0
    for (bodies) b:
        e += 0.5 * b.mass * dot(b.v, b.v) // length_sq(x) = dot(x, x)
        ++i
        for_range(i, nbodies) j:
            let b2 = bodies[j]
            e -= (b.mass * b2.mass) / magnitude(b.x - b2.x)
    return e
/*
 * Rescale certain properties of bodies. That allows doing
 * consequential advance()'s as if dt were equal to 1.0.
 *
 * When all advances done, rescale bodies back to obtain correct energy.
 */
def scale_bodies(scale):
    for (bodies.length) i:
        let b = bodies[i]
        bodies[i] = body{b.x, b.v * scale, (scale * scale) * b.mass}
    //print bodies[0] + "\n" + bodies[1]

def nbodies(n):
    scale_bodies(0.01)
    for(n) i:
        advance()
    scale_bodies(1./0.01)

def main():
    offset_momentum()
    print("\ninitial energy " + energy() + "\n")
    let t0 = seconds_elapsed()
    nbodies(5000000)
    print("\nresulting energy " + energy() + "\n")
    print seconds_elapsed() - t0

main()