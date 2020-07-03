import texture
import vec

let width, height = 320, 200 // 320, 200
let screen:[[xyzw_f]] = init_screen() // Works, but why? there is no return type, not even on the first use of screen in init_screen ???
//let screen:[[xyzw_f]] = vector_reserve(typeof [[xyzw_f]], width*height) // Works
//let screen:[[xyzw_f]] = vector_reserve(typeof [xyzw_f], width*height) // CRASHES! on typo with single []

def init_screen():
    // init screen texture vector
    return map(height):
                map(width):
                    xyzw { 0.0, 0.0, 0.0, 1.0 }

def randomize_texture():
    // randomize screen texture vector
    for (height) y:
        let screen_y = screen[y] // caching the row vector
        for (width) x:
            screen_y[x] = xyzw { rnd_float(), rnd_float(), rnd_float(), 1.0 }

//
// main
//
var t0 = gl_time()

fatal(gl_window("Lobster texture pixel access", width, height))
im_init(false)
assert im_add_font("data/fonts/Droid_Sans/DroidSans.ttf", 20.0)

while gl_frame():
    randomize_texture() // random pixel colors
    gl_clear(color_black)
    gl_set_primitive_texture(0, gl_create_texture(screen))
    gl_set_shader("textured")
    gl_color(color_white)
    gl_translate(float(gl_window_size())/2)
    gl_scale(float(gl_window_size())/2)
    gl_rect(xy_1, 1)
    // stats
    if gl_time()-t0 > 1:
        print "FPS: " + 1.0/gl_delta_time()
        t0 = gl_time()
