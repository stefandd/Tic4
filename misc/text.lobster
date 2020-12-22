// run with vsync off to see the performance impact!

import std
import vec
import color

var width, height = 640, 400
let char_cells_x, char_cells_y = 40, 25

fatal(gl_window("Text", width, height))
//check(gl_set_font_name("data/fonts/PetMe/PetMe.ttf"), "can\'t load font!")
check(gl_set_font_name("data/fonts/Square/Square.ttf"), "can\'t load font!")

var t0 = gl_time()
let bgcolor = xyzw_f {0.3, 0.5, 1, 1}

let colored = 0 // 0 - no color, 1 - foreground only, 2 - both colors

while gl_frame() and gl_button("escape") != 1:
    width = gl_window_size()[0]
    let font_size = width / char_cells_x
    gl_set_font_size(font_size)
    gl_clear(bgcolor)
    if colored > 0: // colored text?
        for (char_cells_y) y:
            for (char_cells_x) x:
                if colored == 2: // fore and background colors?
                    // background cell
                    gl_color(xyzw_f {rnd_float(), rnd_float(), rnd_float(), 1})
                    gl_rect(xy_f{ font_size, font_size })
                // foreground text
                gl_color(xyzw_f {rnd_float(), rnd_float(), rnd_float(), 1.0})
                gl_text(unicode_to_string([48 + rnd(75)]))
                gl_translate(xy_f { font_size, 0 })
            gl_translate(xy_f { -char_cells_x * font_size, font_size })
    else: // no color
        for (char_cells_y) y:
            gl_text(unicode_to_string(map(40): 48 + rnd(75)))
            gl_translate(xy_f {0, font_size })        
    // stats (turn off vsync to measure)
    if gl_time()-t0 > 2: // only every 2 secs
        print "FPS: " + 1.0/gl_delta_time()
        t0 = gl_time()
