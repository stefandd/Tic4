import std
import gl
import imgui
import texture
import color
import vec

// crt shader
var pixshader =
"""
SHADER simplecrt // Shader based on https://the8bitpimp.wordpress.com/2014/07/17/retro-crt-shader/
    VERTEX
        INPUTS apos:4 atc:2
        UNIFORMS mvp
        gl_Position = mvp * apos;
        itc = atc;
    PIXEL
        INPUTS itc:2
        UNIFORMS tex0
        UNIFORM float time
        float f  = sin( itc.y * 320.f * 3.14f ); // per row offset
        float o  = f * (0.35f / 320.f); // scale to per pixel
        float s  = f * .06f + 0.94f; // scale for subtle effect
        float l  = sin( time * 32.f )*.03f + 0.97f; // scan line fading
        // sample in 3 colour offset
        float r = texture( tex0, vec2( itc.x+o, itc.y+o ) ).x;
        float g = texture( tex0, vec2( itc.x-o, itc.y+o ) ).y;
        float b = texture( tex0, vec2( itc.x  , itc.y-o ) ).z;
        frag_color = vec4( 1.0f*l*r, l*g, 1.0f*l*b, 1 ) * s; // vec4( 0.7f*l*r, l*g, 0.9f*l*b, 1 ) * s;
        //frag_color = vec4( l*r, l*g, l*b, 1) * s;
"""

//----------- misc. -------------

def string_find(s:string, pat:string) -> int: // slow brute force
    let N:int = s.length
    let M:int = pat.length
    for (N - M + 1) i:
        for (M) j:
            if substring(s, i+j, 1) != substring(pat, j, 1): // no match -> abort
                break
            elif j == M - 1: // still matching at last loop cycle? -> match
                return i // return position
    return -1 // no match

def string_replace(s:string, search:string, replace:string) -> string:
    // recursive solution
    let slen = s.length
    let srchlen = search.length
    for (slen - srchlen + 1) i:
        if substring(s, i, srchlen) == search:
            if i == 0:
                return replace + string_replace(substring(s, srchlen, -1), search, replace)
            else:
                return substring(s, 0, i) + replace + string_replace(substring(s, i + srchlen, -1), search, replace)
    return s
    
//----------- region ------------

// cp437 translation table, needed for the REXPaint import function in cp437_DOSLatinUS order
let cp437_to_unicode:[int] = [
    0x0000 , // NULL
    0x0001 , // START OF HEADING
    0x0002 , // START OF TEXT
    0x0003 , // END OF TEXT
    0x0004 , // END OF TRANSMISSION
    0x0005 , // ENQUIRY
    0x0006 , // ACKNOWLEDGE
    0x0007 , // BELL
    0x0008 , // BACKSPACE
    0x0009 , // HORIZONTAL TABULATION
    0x000a , // LINE FEED
    0x000b , // VERTICAL TABULATION
    0x000c , // FORM FEED
    0x000d , // CARRIAGE RETURN
    0x000e , // SHIFT OUT
    0x000f , // SHIFT IN
    0x0010 , // DATA LINK ESCAPE
    0x0011 , // DEVICE CONTROL ONE
    0x0012 , // DEVICE CONTROL TWO
    0x0013 , // DEVICE CONTROL THREE
    0x0014 , // DEVICE CONTROL FOUR
    0x0015 , // NEGATIVE ACKNOWLEDGE
    0x0016 , // SYNCHRONOUS IDLE
    0x0017 , // END OF TRANSMISSION BLOCK
    0x0018 , // CANCEL
    0x0019 , // END OF MEDIUM
    0x001a , // SUBSTITUTE
    0x001b , // ESCAPE
    0x001c , // FILE SEPARATOR
    0x001d , // GROUP SEPARATOR
    0x001e , // RECORD SEPARATOR
    0x001f , // UNIT SEPARATOR
    0x0020 , // SPACE
    0x0021 , // EXCLAMATION MARK
    0x0022 , // QUOTATION MARK
    0x0023 , // NUMBER SIGN
    0x0024 , // DOLLAR SIGN
    0x0025 , // PERCENT SIGN
    0x0026 , // AMPERSAND
    0x0027 , // APOSTROPHE
    0x0028 , // LEFT PARENTHESIS
    0x0029 , // RIGHT PARENTHESIS
    0x002a , // ASTERISK
    0x002b , // PLUS SIGN
    0x002c , // COMMA
    0x002d , // HYPHEN-MINUS
    0x002e , // FULL STOP
    0x002f , // SOLIDUS
    0x0030 , // DIGIT ZERO
    0x0031 , // DIGIT ONE
    0x0032 , // DIGIT TWO
    0x0033 , // DIGIT THREE
    0x0034 , // DIGIT FOUR
    0x0035 , // DIGIT FIVE
    0x0036 , // DIGIT SIX
    0x0037 , // DIGIT SEVEN
    0x0038 , // DIGIT EIGHT
    0x0039 , // DIGIT NINE
    0x003a , // COLON
    0x003b , // SEMICOLON
    0x003c , // LESS-THAN SIGN
    0x003d , // EQUALS SIGN
    0x003e , // GREATER-THAN SIGN
    0x003f , // QUESTION MARK
    0x0040 , // COMMERCIAL AT
    0x0041 , // LATIN CAPITAL LETTER A
    0x0042 , // LATIN CAPITAL LETTER B
    0x0043 , // LATIN CAPITAL LETTER C
    0x0044 , // LATIN CAPITAL LETTER D
    0x0045 , // LATIN CAPITAL LETTER E
    0x0046 , // LATIN CAPITAL LETTER F
    0x0047 , // LATIN CAPITAL LETTER G
    0x0048 , // LATIN CAPITAL LETTER H
    0x0049 , // LATIN CAPITAL LETTER I
    0x004a , // LATIN CAPITAL LETTER J
    0x004b , // LATIN CAPITAL LETTER K
    0x004c , // LATIN CAPITAL LETTER L
    0x004d , // LATIN CAPITAL LETTER M
    0x004e , // LATIN CAPITAL LETTER N
    0x004f , // LATIN CAPITAL LETTER O
    0x0050 , // LATIN CAPITAL LETTER P
    0x0051 , // LATIN CAPITAL LETTER Q
    0x0052 , // LATIN CAPITAL LETTER R
    0x0053 , // LATIN CAPITAL LETTER S
    0x0054 , // LATIN CAPITAL LETTER T
    0x0055 , // LATIN CAPITAL LETTER U
    0x0056 , // LATIN CAPITAL LETTER V
    0x0057 , // LATIN CAPITAL LETTER W
    0x0058 , // LATIN CAPITAL LETTER X
    0x0059 , // LATIN CAPITAL LETTER Y
    0x005a , // LATIN CAPITAL LETTER Z
    0x005b , // LEFT SQUARE BRACKET
    0x005c , // REVERSE SOLIDUS
    0x005d , // RIGHT SQUARE BRACKET
    0x005e , // CIRCUMFLEX ACCENT
    0x005f , // LOW LINE
    0x0060 , // GRAVE ACCENT
    0x0061 , // LATIN SMALL LETTER A
    0x0062 , // LATIN SMALL LETTER B
    0x0063 , // LATIN SMALL LETTER C
    0x0064 , // LATIN SMALL LETTER D
    0x0065 , // LATIN SMALL LETTER E
    0x0066 , // LATIN SMALL LETTER F
    0x0067 , // LATIN SMALL LETTER G
    0x0068 , // LATIN SMALL LETTER H
    0x0069 , // LATIN SMALL LETTER I
    0x006a , // LATIN SMALL LETTER J
    0x006b , // LATIN SMALL LETTER K
    0x006c , // LATIN SMALL LETTER L
    0x006d , // LATIN SMALL LETTER M
    0x006e , // LATIN SMALL LETTER N
    0x006f , // LATIN SMALL LETTER O
    0x0070 , // LATIN SMALL LETTER P
    0x0071 , // LATIN SMALL LETTER Q
    0x0072 , // LATIN SMALL LETTER R
    0x0073 , // LATIN SMALL LETTER S
    0x0074 , // LATIN SMALL LETTER T
    0x0075 , // LATIN SMALL LETTER U
    0x0076 , // LATIN SMALL LETTER V
    0x0077 , // LATIN SMALL LETTER W
    0x0078 , // LATIN SMALL LETTER X
    0x0079 , // LATIN SMALL LETTER Y
    0x007a , // LATIN SMALL LETTER Z
    0x007b , // LEFT CURLY BRACKET
    0x007c , // VERTICAL LINE
    0x007d , // RIGHT CURLY BRACKET
    0x007e , // TILDE
    0x007f , // DELETE
    0x00c7 , // LATIN CAPITAL LETTER C WITH CEDILLA
    0x00fc , // LATIN SMALL LETTER U WITH DIAERESIS
    0x00e9 , // LATIN SMALL LETTER E WITH ACUTE
    0x00e2 , // LATIN SMALL LETTER A WITH CIRCUMFLEX
    0x00e4 , // LATIN SMALL LETTER A WITH DIAERESIS
    0x00e0 , // LATIN SMALL LETTER A WITH GRAVE
    0x00e5 , // LATIN SMALL LETTER A WITH RING ABOVE
    0x00e7 , // LATIN SMALL LETTER C WITH CEDILLA
    0x00ea , // LATIN SMALL LETTER E WITH CIRCUMFLEX
    0x00eb , // LATIN SMALL LETTER E WITH DIAERESIS
    0x00e8 , // LATIN SMALL LETTER E WITH GRAVE
    0x00ef , // LATIN SMALL LETTER I WITH DIAERESIS
    0x00ee , // LATIN SMALL LETTER I WITH CIRCUMFLEX
    0x00ec , // LATIN SMALL LETTER I WITH GRAVE
    0x00c4 , // LATIN CAPITAL LETTER A WITH DIAERESIS
    0x00c5 , // LATIN CAPITAL LETTER A WITH RING ABOVE
    0x00c9 , // LATIN CAPITAL LETTER E WITH ACUTE
    0x00e6 , // LATIN SMALL LIGATURE AE
    0x00c6 , // LATIN CAPITAL LIGATURE AE
    0x00f4 , // LATIN SMALL LETTER O WITH CIRCUMFLEX
    0x00f6 , // LATIN SMALL LETTER O WITH DIAERESIS
    0x00f2 , // LATIN SMALL LETTER O WITH GRAVE
    0x00fb , // LATIN SMALL LETTER U WITH CIRCUMFLEX
    0x00f9 , // LATIN SMALL LETTER U WITH GRAVE
    0x00ff , // LATIN SMALL LETTER Y WITH DIAERESIS
    0x00d6 , // LATIN CAPITAL LETTER O WITH DIAERESIS
    0x00dc , // LATIN CAPITAL LETTER U WITH DIAERESIS
    0x00a2 , // CENT SIGN
    0x00a3 , // POUND SIGN
    0x00a5 , // YEN SIGN
    0x20a7 , // PESETA SIGN
    0x0192 , // LATIN SMALL LETTER F WITH HOOK
    0x00e1 , // LATIN SMALL LETTER A WITH ACUTE
    0x00ed , // LATIN SMALL LETTER I WITH ACUTE
    0x00f3 , // LATIN SMALL LETTER O WITH ACUTE
    0x00fa , // LATIN SMALL LETTER U WITH ACUTE
    0x00f1 , // LATIN SMALL LETTER N WITH TILDE
    0x00d1 , // LATIN CAPITAL LETTER N WITH TILDE
    0x00aa , // FEMININE ORDINAL INDICATOR
    0x00ba , // MASCULINE ORDINAL INDICATOR
    0x00bf , // INVERTED QUESTION MARK
    0x2310 , // REVERSED NOT SIGN
    0x00ac , // NOT SIGN
    0x00bd , // VULGAR FRACTION ONE HALF
    0x00bc , // VULGAR FRACTION ONE QUARTER
    0x00a1 , // INVERTED EXCLAMATION MARK
    0x00ab , // LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
    0x00bb , // RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
    0x2591 , // LIGHT SHADE
    0x2592 , // MEDIUM SHADE
    0x2593 , // DARK SHADE
    0x2502 , // BOX DRAWINGS LIGHT VERTICAL
    0x2524 , // BOX DRAWINGS LIGHT VERTICAL AND LEFT
    0x2561 , // BOX DRAWINGS VERTICAL SINGLE AND LEFT DOUBLE
    0x2562 , // BOX DRAWINGS VERTICAL DOUBLE AND LEFT SINGLE
    0x2556 , // BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE
    0x2555 , // BOX DRAWINGS DOWN SINGLE AND LEFT DOUBLE
    0x2563 , // BOX DRAWINGS DOUBLE VERTICAL AND LEFT
    0x2551 , // BOX DRAWINGS DOUBLE VERTICAL
    0x2557 , // BOX DRAWINGS DOUBLE DOWN AND LEFT
    0x255d , // BOX DRAWINGS DOUBLE UP AND LEFT
    0x255c , // BOX DRAWINGS UP DOUBLE AND LEFT SINGLE
    0x255b , // BOX DRAWINGS UP SINGLE AND LEFT DOUBLE
    0x2510 , // BOX DRAWINGS LIGHT DOWN AND LEFT
    0x2514 , // BOX DRAWINGS LIGHT UP AND RIGHT
    0x2534 , // BOX DRAWINGS LIGHT UP AND HORIZONTAL
    0x252c , // BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
    0x251c , // BOX DRAWINGS LIGHT VERTICAL AND RIGHT
    0x2500 , // BOX DRAWINGS LIGHT HORIZONTAL
    0x253c , // BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
    0x255e , // BOX DRAWINGS VERTICAL SINGLE AND RIGHT DOUBLE
    0x255f , // BOX DRAWINGS VERTICAL DOUBLE AND RIGHT SINGLE
    0x255a , // BOX DRAWINGS DOUBLE UP AND RIGHT
    0x2554 , // BOX DRAWINGS DOUBLE DOWN AND RIGHT
    0x2569 , // BOX DRAWINGS DOUBLE UP AND HORIZONTAL
    0x2566 , // BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL
    0x2560 , // BOX DRAWINGS DOUBLE VERTICAL AND RIGHT
    0x2550 , // BOX DRAWINGS DOUBLE HORIZONTAL
    0x256c , // BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL
    0x2567 , // BOX DRAWINGS UP SINGLE AND HORIZONTAL DOUBLE
    0x2568 , // BOX DRAWINGS UP DOUBLE AND HORIZONTAL SINGLE
    0x2564 , // BOX DRAWINGS DOWN SINGLE AND HORIZONTAL DOUBLE
    0x2565 , // BOX DRAWINGS DOWN DOUBLE AND HORIZONTAL SINGLE
    0x2559 , // BOX DRAWINGS UP DOUBLE AND RIGHT SINGLE
    0x2558 , // BOX DRAWINGS UP SINGLE AND RIGHT DOUBLE
    0x2552 , // BOX DRAWINGS DOWN SINGLE AND RIGHT DOUBLE
    0x2553 , // BOX DRAWINGS DOWN DOUBLE AND RIGHT SINGLE
    0x256b , // BOX DRAWINGS VERTICAL DOUBLE AND HORIZONTAL SINGLE
    0x256a , // BOX DRAWINGS VERTICAL SINGLE AND HORIZONTAL DOUBLE
    0x2518 , // BOX DRAWINGS LIGHT UP AND LEFT
    0x250c , // BOX DRAWINGS LIGHT DOWN AND RIGHT
    0x2588 , // FULL BLOCK
    0x2584 , // LOWER HALF BLOCK
    0x258c , // LEFT HALF BLOCK
    0x2590 , // RIGHT HALF BLOCK
    0x2580 , // UPPER HALF BLOCK
    0x03b1 , // GREEK SMALL LETTER ALPHA
    0x00df , // LATIN SMALL LETTER SHARP S
    0x0393 , // GREEK CAPITAL LETTER GAMMA
    0x03c0 , // GREEK SMALL LETTER PI
    0x03a3 , // GREEK CAPITAL LETTER SIGMA
    0x03c3 , // GREEK SMALL LETTER SIGMA
    0x00b5 , // MICRO SIGN
    0x03c4 , // GREEK SMALL LETTER TAU
    0x03a6 , // GREEK CAPITAL LETTER PHI
    0x0398 , // GREEK CAPITAL LETTER THETA
    0x03a9 , // GREEK CAPITAL LETTER OMEGA
    0x03b4 , // GREEK SMALL LETTER DELTA
    0x221e , // INFINITY
    0x03c6 , // GREEK SMALL LETTER PHI
    0x03b5 , // GREEK SMALL LETTER EPSILON
    0x2229 , // INTERSECTION
    0x2261 , // IDENTICAL TO
    0x00b1 , // PLUS-MINUS SIGN
    0x2265 , // GREATER-THAN OR EQUAL TO
    0x2264 , // LESS-THAN OR EQUAL TO
    0x2320 , // TOP HALF INTEGRAL
    0x2321 , // BOTTOM HALF INTEGRAL
    0x00f7 , // DIVISION SIGN
    0x2248 , // ALMOST EQUAL TO
    0x00b0 , // DEGREE SIGN
    0x2219 , // BULLET OPERATOR
    0x00b7 , // MIDDLE DOT
    0x221a , // SQUARE ROOT
    0x207f , // SUPERSCRIPT LATIN SMALL LETTER N
    0x00b2 , // SUPERSCRIPT TWO
    0x25a0 , // BLACK SQUARE
    0x00a0 , // NO-BREAK SPACE
    ]

class region:

    text_rbuffer:[int] = []
    text_c1buffer:[color] = []
    text_c2buffer:[color] = []
    extend_x = 0
    extend_y = 0
    alpha_chr = 32

    def fromREXPaint(REXPaint_csv):
        //read_file(file:string, textmode:int = 0) -> string?
        let content = read_file(REXPaint_csv, 1)
        var col_min, col_max = 99999999, -1
        var row_min, row_max = 99999999, -1
        text_rbuffer, text_c1buffer, text_c2buffer = [], [], []
        extend_x, extend_y = 0, 0
        if content:
            // 1st pass -- bounding box
            for (slice(tokenize(content, "\n", " "), 1, -1)) line, lnum: // slice to skip the header line
                let args = tokenize(line, ",", " ")
                if args.length == 5:
                    let x, y, chr = string_to_int(args[0]), string_to_int(args[1]), string_to_int(args[2])
                    // determine bounding box
                    if chr != alpha_chr:
                        if x < col_min: col_min = x 
                        if x > col_max: col_max = x 
                        if y < row_min: row_min = y 
                        if y > row_max: row_max = y 
                        //print "debug: char " + chr + " found in: " + x + ", " + y
                else:
                    print "Error parsing file " + REXPaint_csv + ", line " + lnum
                    return
            // 2nd pass capture region
            for (slice(tokenize(content, "\n", " "), 1, -1)) line:
                let args = tokenize(line, ",", " ")
                let x, y, chr, fgcol, bgcol = string_to_int(args[0]), string_to_int(args[1]), string_to_int(args[2]), args[3], args[4]
                if x >= col_min and x <= col_max and y >= row_min and y <= row_max: // inside bounding box
                    let c1_r = float(string_to_int(substring(args[3], 1, 2), 16)) / 255.0
                    let c1_g = float(string_to_int(substring(args[3], 3, 2), 16)) / 255.0
                    let c1_b = float(string_to_int(substring(args[3], 5, 2), 16)) / 255.0
                    let c2_r = float(string_to_int(substring(args[4], 1, 2), 16)) / 255.0
                    let c2_g = float(string_to_int(substring(args[4], 3, 2), 16)) / 255.0
                    let c2_b = float(string_to_int(substring(args[4], 5, 2), 16)) / 255.0
                    text_rbuffer.push(cp437_to_unicode[chr])
                    text_c1buffer.push(color{c1_r, c1_g, c1_b, 1.0})
                    text_c2buffer.push(color{c2_r, c2_g, c2_b, 1.0})            
                    //print(x + "  " + y + "  " + cp437_to_unicode[chr] + "  " + string_to_int(substring(args[3], 1, 6), 16) + "  " + string_to_int(substring(args[4], 1, 6), 16) + "       " + 255*c1_r + "  " + 255*c1_g + "  " + 255*c1_b)
            extend_x = col_max - col_min + 1
            extend_y = row_max - row_min + 1
            assert text_rbuffer.length == extend_x * extend_y
        else:
            print "Error reading file " + REXPaint_csv
            return

    def scaledcopy(tgt_extend_x, tgt_extend_y) -> region:
        if tgt_extend_x < 2 or tgt_extend_y < 2:
            print "Error: illegal operands to scaledcopy!"
            return region{} // returns empty region
        let t2s_sc_x = float(extend_x) / tgt_extend_x // target-to-source (inverse) scaling factor
        let t2s_sc_y = float(extend_y) / tgt_extend_y
        let scopy = region{}
        scopy.extend_x = tgt_extend_x
        scopy.extend_y = tgt_extend_y
        scopy.alpha_chr = alpha_chr
        let bufferlimit = text_rbuffer.length
        //print "Source dimensions: " + extend_x + ", " + extend_y
        //print "Target dimensions: " + tgt_extend_x + ", " + tgt_extend_y
        //print "Debug: scales: " + t2s_sc_x + ", " + t2s_sc_y
        for (tgt_extend_y) i:
            for (tgt_extend_x) j:
                //print "Debug: tgt vec: " + j + ", " + i + ",  src vec: " + int(t2s_sc_x * j + 0.5) + ", " + int(t2s_sc_y * i + 0.5)
                let src_idx = clamp(round(t2s_sc_y * i) * extend_x + round(t2s_sc_x * j), 0, bufferlimit - 1)
                scopy.text_rbuffer.push(text_rbuffer[src_idx])
                scopy.text_c1buffer.push(text_c1buffer[src_idx])
                scopy.text_c2buffer.push(text_c2buffer[src_idx])
        assert scopy.text_rbuffer.length == tgt_extend_x * tgt_extend_y
        return scopy

//----------- sprite ------------

class sprite:

    text_rbuffer:[int] = []
    text_c1buffer:[color] = []
    text_c2buffer:[color] = []
    chr_vecs:[xy_i] = []
    extend = xy_i{0, 0}
    pos = xy_i{0, 0}
    
    def fromregion(r:region):
        text_rbuffer, text_c1buffer, text_c2buffer, chr_vecs = [], [], [], []
        let extend_x, extend_y = r.extend_x, r.extend_y
        for (extend_y) i:
            for (extend_x) j:                
                let src_idx = i * extend_x + j
                let curr_chr = r.text_rbuffer[src_idx]
                if curr_chr != r.alpha_chr:
                    chr_vecs.push(xy_i{j, i})
                    text_rbuffer.push(curr_chr)
                    text_c1buffer.push(r.text_c1buffer[src_idx])
                    text_c2buffer.push(r.text_c2buffer[src_idx])
        extend = xy_i{extend_x, extend_y}
                
    def fromREXPaint(REXPaint_csv:string):
        let r = region{}
        r.fromREXPaint(REXPaint_csv)
        this.fromregion(r)
        
    def copyfrom(s:sprite, copy_pos:bool = true):
        text_rbuffer = s.text_rbuffer.copy()
        text_c1buffer = s.text_c1buffer.copy()
        text_c2buffer = s.text_c2buffer.copy()
        chr_vecs = s.chr_vecs.copy()
        extend = s.extend
        if copy_pos:
            pos = s.pos

    def clone() -> sprite:
        let scopy = sprite{}
        scopy.text_rbuffer = text_rbuffer.copy()
        scopy.text_c1buffer = text_c1buffer.copy()
        scopy.text_c2buffer = text_c2buffer.copy()
        scopy.chr_vecs = chr_vecs.copy()
        scopy.extend = extend
        scopy.pos = pos
        return scopy

    def collisiontest_slow(s:sprite) -> bool:
        let s_pos = s.pos
        let s_chr_vecs = s.chr_vecs
        for (s_chr_vecs.length) j: // loop over the other sprite's chars
            let testpos = s_pos - pos + s_chr_vecs[j]
            for (chr_vecs.length) i: // loop over our chars
                if chr_vecs[i] == testpos:
                    return true
        return false

    def collisiontest(s:sprite) -> bool:
        // 1st -- bounding box overlap test, and only if overlap in bounding box then proceed
        // with the detailed character collision test --> gains ~20% performance in collisiontest
        let extmax = max(extend, s.extend)
        let s_pos = s.pos
        // test both the vector joining the upper left corners and the vector joining the lower right corners to be shorter than the maximum of the extends in each dimension.
        // the plus replaces the missing logical AND, so 4 after manhattan() means true in both terms and in both dimensions
        if manhattan( (abs(s_pos - pos) <= extmax) + (abs(s_pos + s.extend - pos  - extend) <= extmax) ) == 4:
            // 2nd -- detailed test collisions in the character coordinate vectors, only performed if the bounding boxes collided
            let s_chr_vecs = s.chr_vecs
            for (s_chr_vecs.length) j: // loop over the other sprite's chars
                let testpos = s_pos - pos + s_chr_vecs[j]
                for (chr_vecs.length) i: // loop over our chars
                    if chr_vecs[i] == testpos:
                        return true
        return false
    
//----------- console -----------


class console:

    private running = false
    fontheight:int = 22
    lineheight:int = 22
    fontwidth_:int = 22
    num_cells_x:int = 40
    num_cells_y:int = 25
    border_cells_x:int = 3
    border_cells_y:int = 2
    scale_x:float = 1.0
    scale_y:float = 1.0
    border_color = color{0.3, 0.3, 0.3, 1.0}
    border_show = false
    text_color = color_black
    background_color = color{0.2, 0.2, 1.0, 1.0}
    tab_num_spaces:int = 4
    tab_stops:[int] = [1, 11, 21, 31]
    ulc_buffer_idx:int = 0
    text_rbuffer:[int] = []
    text_c1buffer:[color] = []
    text_c2buffer:[color] = []
    cursor_chr = ['_', ' ']
    cursor_blink_time:float = 0.5
    cursor_pos_x:int = 1
    cursor_pos_y:int = 1
    autoscroll = true
    wait_for_keypress = false
    input_mode_on = false
    input_text = ""
    last_key_pressed = ""
    key_is_down = false
    input_start_lpointer:int = 1
    window_xy_ = xy_i{0, 0}
    ulc_x_px_:int = 0
    ulc_y_px_:int = 0
    rectsize_xy_ = xy_f{0, 0}
    dcell_x_ = xy_f{0, 0} // single char translation
    dcr_ = xy_f{0, 0} //  cr translation    
    input_backspace_semaphore_ = false
    time_:float = 0.0
    update_clients_ = []
    do_client_updates_ = false
    ignore_arg_err_ = false
    FPS:float = 0.0
    using_crt_shader = false
    esc_does_quit = true
    debug_window_enabled = false
    debug_bp_label = ""
    
    // internal funcs
    def textdraw_():
        // draw screen characters
        var bufferidx = ulc_buffer_idx
        gl_translate(xy_f{ulc_x_px_, ulc_y_px_})
        for (num_cells_y):
            for (num_cells_x):
                let curr_chr = text_rbuffer[bufferidx]
                // background cell
                gl_color(text_c2buffer[bufferidx])
                gl_rect(rectsize_xy_)
                if curr_chr != 32: // speed boost in sparse texts
                    // foreground text
                    gl_color(text_c1buffer[bufferidx])
                    gl_text(unicode_to_string([curr_chr]))
                gl_translate(dcell_x_)
                bufferidx++
            gl_translate(dcr_)
                
    def draw_():
        if border_show:
            gl_clear(border_color)
            gl_color(background_color)
        else:
            gl_clear(background_color)
        //draw__behind()
        textdraw_()
        //draw__in_front()
            
    def rescale_():
        window_xy_ = gl_window_size() // current window size
        var orig_width, orig_height = num_cells_x * fontwidth_, num_cells_y * lineheight // our space needs in the current font size and lineheight
        if border_show:
            orig_width += 2 * border_cells_x * fontwidth_
            orig_height += 2 * border_cells_y * lineheight
        scale_x, scale_y = float(window_xy_.x) / orig_width, float(window_xy_.y) / orig_height // resulting scaling factors
        // recalculate the upper left corner position in pixels to be centered in window
        //ulc_x_px_, ulc_y_px_ = 0, 0
        if scale_x < scale_y:
            scale_y = scale_x
            if border_show:
                ulc_x_px_ = int(scale_x * border_cells_x * fontwidth_)
                ulc_y_px_ = int(scale_y * border_cells_y * fontheight + (window_xy_.y - scale_y * orig_height)/2.0)
            else:
                ulc_x_px_ = 0
                ulc_y_px_ = int((window_xy_.y - scale_y * orig_height)/2.0)
        else:
            scale_x = scale_y
            if border_show:
                ulc_x_px_ = int(scale_x * border_cells_x * fontwidth_ + (window_xy_.x - scale_x * orig_width)/2.0)
                ulc_y_px_ = int(scale_y * border_cells_y * fontheight)
            else:
                ulc_x_px_ = int((window_xy_.x - scale_x * orig_width)/2.0)
                ulc_y_px_ = 0
        // precalculate the translation vectors and the textbox size
        rectsize_xy_ = xy_f{ scale_x * fontwidth_, scale_y * lineheight }
        dcell_x_ = xy_f{ scale_x * fontwidth_, 0 }
        dcr_ = xy_f{ -num_cells_x * scale_x * fontwidth_, scale_y * lineheight }
        // rescale the font
        gl_set_font_size(int(scale_y * fontheight + 0.5))


    def check_col_row_(col, row):
        if ignore_arg_err_ or (col >= 0 and col < num_cells_x and row >= 0 and row < num_cells_y):
            return true
        else:
            print "Illegal x, y operands: " + col + ", " + row
            return false

    // print functions
    def printxy_print_lv0_(col:int, row:int, s:string): // operands of col row must be checked before this is called; should also not call on empty strings
        var p1_text_rbuffer:[int] = []
        let p2_text_rbuffer:[int] = []
        let n_text_rbuffer:[int] = []
        let insertpos_buffer_idx = ulc_buffer_idx + col + num_cells_x * row
        var curr_col, curr_row = col, row
        var add_chr, add_chr_tot = 0, 0
        let chr_vec = string_to_unicode(s)
        if insertpos_buffer_idx > 0: // first save the buffer objects before the cursor position
            p1_text_rbuffer = slice(text_rbuffer, 0, insertpos_buffer_idx)
        for (chr_vec) chr:
            // filter special characters
            add_chr = 0
            switch chr:
                case 9: // \t
                    for (tab_num_spaces):
                        n_text_rbuffer.push(32)
                    add_chr += tab_num_spaces
                case 10: // \n
                    for (num_cells_x - curr_col):
                        n_text_rbuffer.push(32)
                    add_chr += num_cells_x - curr_col
                case 13: // \r
                    pass() // ignore
                default:
                    n_text_rbuffer.push(chr)
                    add_chr++
            // advance cursor position
            if curr_col + add_chr < num_cells_x:
                curr_col += add_chr
            else:
                curr_col = 0
                curr_row++
            add_chr_tot += add_chr
        // additional spaces for any newly started row to prefill the buffer full rows
        if curr_row > row:
                for (num_cells_x - curr_col):
                    n_text_rbuffer.push(32)
                add_chr_tot += num_cells_x - curr_col
        // the asserts are bug test
        if curr_row != row:
            assert (col + num_cells_x * row + add_chr_tot) % num_cells_x == 0
            assert (insertpos_buffer_idx + add_chr_tot) % num_cells_x == 0            
        // decide how to modify the class buffers
        assert n_text_rbuffer.length == add_chr_tot
        if insertpos_buffer_idx > 0:
            if insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length: // can we just overwrite the current buffers with the new text?
                text_rbuffer = append(p1_text_rbuffer, n_text_rbuffer)
            else:
                text_rbuffer = append(p1_text_rbuffer, append(n_text_rbuffer, slice(text_rbuffer, insertpos_buffer_idx + add_chr_tot, -1)))
        else:
            if insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length: // can we just overwrite the current buffers with the new text?
                text_rbuffer = n_text_rbuffer
            else:
                text_rbuffer = append(n_text_rbuffer, slice(text_rbuffer, add_chr_tot, -1))
        // update cursor position
        if (insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length) and autoscroll: // can we just overwrite the current buffers with the new text?
            ulc_buffer_idx = insertpos_buffer_idx + add_chr_tot - num_cells_x * num_cells_y
            cursor_pos_x, cursor_pos_y = curr_col, num_cells_y - 1
        else:
            cursor_pos_x, cursor_pos_y = curr_col, curr_row
        // more tests
        assert text_rbuffer.length % num_cells_x == 0
        return true

    def printxy_print_lv1_(col:int, row:int, s:string): // operands of col row must be checked before this is called; should also not call on empty strings
        var p1_text_rbuffer:[int] = []
        var p1_text_c1buffer:[color] = []
        let p2_text_rbuffer:[int] = []
        let p2_text_c1buffer:[color] = []
        let n_text_rbuffer:[int] = []
        let n_text_c1buffer:[color] = []
        let insertpos_buffer_idx = ulc_buffer_idx + col + num_cells_x * row
        var curr_col, curr_row = col, row
        var add_chr, add_chr_tot = 0, 0
        let chr_vec = string_to_unicode(s)
        if insertpos_buffer_idx > 0: // first save the buffer objects before the cursor position
            p1_text_rbuffer = slice(text_rbuffer, 0, insertpos_buffer_idx)
            p1_text_c1buffer = slice(text_c1buffer, 0, insertpos_buffer_idx)
        for (chr_vec) chr:
            // filter special characters
            add_chr = 0
            switch chr:
                case 9: // \t
                    for (tab_num_spaces):
                        n_text_rbuffer.push(32)
                        n_text_c1buffer.push(text_color)
                    add_chr += tab_num_spaces
                case 10: // \n
                    for (num_cells_x - curr_col):
                        n_text_rbuffer.push(32)
                        n_text_c1buffer.push(text_color)
                    add_chr += num_cells_x - curr_col
                case 13: // \r
                    pass() // ignore
                default:
                    n_text_rbuffer.push(chr)
                    n_text_c1buffer.push(text_color)
                    add_chr++
            // advance cursor position
            if curr_col + add_chr < num_cells_x:
                curr_col += add_chr
            else:
                curr_col = 0
                curr_row++
            add_chr_tot += add_chr
        // additional spaces for any newly started row to prefill the buffer full rows
        if curr_row > row:
                for (num_cells_x - curr_col):
                    n_text_rbuffer.push(32)
                    n_text_c1buffer.push(text_color)
                add_chr_tot += num_cells_x - curr_col
        // the asserts are bug test
        if curr_row != row:
            assert (col + num_cells_x * row + add_chr_tot) % num_cells_x == 0
            assert (insertpos_buffer_idx + add_chr_tot) % num_cells_x == 0            
        // decide how to modify the class buffers
        assert n_text_rbuffer.length == add_chr_tot
        if insertpos_buffer_idx > 0:
            if insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length: // can we just overwrite the current buffers with the new text?
                text_rbuffer = append(p1_text_rbuffer, n_text_rbuffer)
                text_c1buffer = append(p1_text_c1buffer, n_text_c1buffer)
            else:
                text_rbuffer = append(p1_text_rbuffer, append(n_text_rbuffer, slice(text_rbuffer, insertpos_buffer_idx + add_chr_tot, -1)))
                text_c1buffer = append(p1_text_c1buffer, append(n_text_c1buffer, slice(text_c1buffer, insertpos_buffer_idx + add_chr_tot, -1)))
        else:
            if insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length: // can we just overwrite the current buffers with the new text?
                text_rbuffer = n_text_rbuffer
                text_c1buffer = n_text_c1buffer
            else:
                text_rbuffer = append(n_text_rbuffer, slice(text_rbuffer, add_chr_tot, -1))
                text_c1buffer = append(n_text_c1buffer, slice(text_c1buffer, add_chr_tot, -1))
        // update cursor position
        if (insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length) and autoscroll: // can we just overwrite the current buffers with the new text?
            ulc_buffer_idx = insertpos_buffer_idx + add_chr_tot - num_cells_x * num_cells_y
            cursor_pos_x, cursor_pos_y = curr_col, num_cells_y - 1
        else:
            cursor_pos_x, cursor_pos_y = curr_col, curr_row
        // more tests
        assert text_rbuffer.length % num_cells_x == 0
        assert text_rbuffer.length == text_c1buffer.length
        return true

    def printxy_print_lv2_(col:int, row:int, s:string): // operands of col row must be checked before this is called; should also not call on empty strings
        var p1_text_rbuffer:[int] = []
        var p1_text_c1buffer:[color] = []
        var p1_text_c2buffer:[color] = []
        let p2_text_rbuffer:[int] = []
        let p2_text_c1buffer:[color] = []
        let p2_text_c2buffer:[color] = []        
        let n_text_rbuffer:[int] = []
        let n_text_c1buffer:[color] = []
        let n_text_c2buffer:[color] = []
        let insertpos_buffer_idx = ulc_buffer_idx + col + num_cells_x * row
        var curr_col, curr_row = col, row
        var add_chr, add_chr_tot = 0, 0
        let chr_vec = string_to_unicode(s)
        if insertpos_buffer_idx > 0: // first save the buffer objects before the cursor position
            p1_text_rbuffer = slice(text_rbuffer, 0, insertpos_buffer_idx)
            p1_text_c1buffer = slice(text_c1buffer, 0, insertpos_buffer_idx)
            p1_text_c2buffer = slice(text_c2buffer, 0, insertpos_buffer_idx)
        for (chr_vec) chr:
            // filter special characters
            add_chr = 0
            switch chr:
                case 9: // \t
                    for (tab_num_spaces):
                        n_text_rbuffer.push(32)
                        n_text_c1buffer.push(text_color)
                        n_text_c2buffer.push(background_color)
                    add_chr += tab_num_spaces
                case 10: // \n
                    for (num_cells_x - curr_col):
                        n_text_rbuffer.push(32)
                        n_text_c1buffer.push(text_color)
                        n_text_c2buffer.push(background_color)
                    add_chr += num_cells_x - curr_col
                case 13: // \r
                    pass() // ignore
                default:
                    n_text_rbuffer.push(chr)
                    n_text_c1buffer.push(text_color)
                    n_text_c2buffer.push(background_color)
                    add_chr++
            // advance cursor position
            if curr_col + add_chr < num_cells_x:
                curr_col += add_chr
            else:
                curr_col = 0
                curr_row++
            add_chr_tot += add_chr
        // additional spaces for any newly started row to prefill the buffer full rows
        if curr_row > row:
                for (num_cells_x - curr_col):
                    n_text_rbuffer.push(32)
                    n_text_c1buffer.push(text_color)
                    n_text_c2buffer.push(background_color)
                add_chr_tot += num_cells_x - curr_col
        // the asserts are bug test
        if curr_row != row:
            assert (col + num_cells_x * row + add_chr_tot) % num_cells_x == 0
            assert (insertpos_buffer_idx + add_chr_tot) % num_cells_x == 0            
        // decide how to modify the class buffers
        assert n_text_rbuffer.length == add_chr_tot
        if insertpos_buffer_idx > 0:
            if insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length: // can we just overwrite the current buffers with the new text?
                text_rbuffer = append(p1_text_rbuffer, n_text_rbuffer)
                text_c1buffer = append(p1_text_c1buffer, n_text_c1buffer)
                text_c2buffer = append(p1_text_c2buffer, n_text_c2buffer)
            else:
                text_rbuffer = append(p1_text_rbuffer, append(n_text_rbuffer, slice(text_rbuffer, insertpos_buffer_idx + add_chr_tot, -1)))
                text_c1buffer = append(p1_text_c1buffer, append(n_text_c1buffer, slice(text_c1buffer, insertpos_buffer_idx + add_chr_tot, -1)))
                text_c2buffer = append(p1_text_c2buffer, append(n_text_c2buffer, slice(text_c2buffer, insertpos_buffer_idx + add_chr_tot, -1)))
        else:
            if insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length: // can we just overwrite the current buffers with the new text?
                text_rbuffer = n_text_rbuffer
                text_c1buffer = n_text_c1buffer
                text_c2buffer = n_text_c2buffer
            else:
                text_rbuffer = append(n_text_rbuffer, slice(text_rbuffer, add_chr_tot, -1))
                text_c1buffer = append(n_text_c1buffer, slice(text_c1buffer, add_chr_tot, -1))
                text_c2buffer = append(n_text_c2buffer, slice(text_c2buffer, add_chr_tot, -1))
        // update cursor position
        if (insertpos_buffer_idx + add_chr_tot >= text_rbuffer.length) and autoscroll: // can we just overwrite the current buffers with the new text?
            ulc_buffer_idx = insertpos_buffer_idx + add_chr_tot - num_cells_x * num_cells_y
            cursor_pos_x, cursor_pos_y = curr_col, num_cells_y - 1
        else:
            cursor_pos_x, cursor_pos_y = curr_col, curr_row
        // more tests
        assert text_rbuffer.length % num_cells_x == 0
        assert text_rbuffer.length == text_c1buffer.length and text_rbuffer.length == text_c2buffer.length
        return true

    def writexy(col:int, row:int, s:string, level:int = 2): // operands of col row must be checked before this is called; should also not call on empty strings
        if not check_col_row_(col, row): return
        if level == 0:
            printxy_print_lv0_(col, row, s)
        elif level == 1:
            printxy_print_lv1_(col, row, s)
        else:
            printxy_print_lv2_(col, row, s)
        
    def write(s:string, level:int = 2): // operands of col row must be checked before this is called; should also not call on empty strings
        if level == 0:
            printxy_print_lv0_(cursor_pos_x, cursor_pos_y, s)
        elif level == 1:
            printxy_print_lv1_(cursor_pos_x, cursor_pos_y, s)
        else:
            printxy_print_lv2_(cursor_pos_x, cursor_pos_y, s)
        
    def writeln(s:string, level:int = 2): // operands of col row must be checked before this is called; should also not call on empty strings
        if level == 0:
            printxy_print_lv0_(cursor_pos_x, cursor_pos_y, s + '\n')
        elif level == 1:
            printxy_print_lv1_(cursor_pos_x, cursor_pos_y, s + '\n')
        else:
            printxy_print_lv2_(cursor_pos_x, cursor_pos_y, s + '\n')
            
    def inputxy(col:int, row:int, p:string, min_length:int = 0, max_length:int = 1024, level:int = 2) -> string:
        if not check_col_row_(col, row): return
        gl_start_text_input(xy_0i, xy_0i)
        var text = ""
        let initial_ulc = ulc_buffer_idx
        var cursor_idx = 0
        var t_blink = gl_time()
        while gl_button("return") < 1 or text.length < min_length:
            text = gl_text_input_state()
            if text.length > max_length:
                text = substring(text, 0, max_length)
            var add_space_char = false
            if gl_button("escape") >= 1 and esc_does_quit:
                running = false
                return ""
            if gl_key_repeat("backspace") == 1 and text.length:
                text = substring(text, 0, text.length - 1)
                gl_set_text_input(text)
                add_space_char = true
            ulc_buffer_idx = initial_ulc
            let outstr = p + text
            writexy(col, row, outstr, level)
            let add_lines = (string_to_unicode(outstr).length + col) / num_cells_x + row - (num_cells_y - 1)// how many lines have we had to scroll?
            if add_lines > 0: // correct buffer index to make sure we scroll back when we backspace...
                ulc_buffer_idx = initial_ulc + num_cells_x * add_lines
                cursor_pos_y = num_cells_y - 1
            if gl_time() - t_blink > cursor_blink_time: // blinking cursor
                cursor_idx = 1 - cursor_idx
                t_blink = gl_time()
            let cursor_buffidx = ulc_buffer_idx + cursor_pos_x + num_cells_x * cursor_pos_y
            text_rbuffer[cursor_buffidx] = cursor_chr[cursor_idx]
            if add_space_char:
                text_rbuffer[cursor_buffidx + 1] = 32
            sleep()
        gl_end_text_input()
        return text
        
    def clreol(level:int = 2):
        let base_idx = ulc_buffer_idx + cursor_pos_x + num_cells_x * cursor_pos_y
        if level == 0:
            for (num_cells_x - cursor_pos_x) i:
                text_rbuffer[base_idx + i] = 32
        elif level == 1:
            for (num_cells_x - cursor_pos_x) i:
                text_rbuffer[base_idx + i] = 32
                text_c1buffer[base_idx + i] = text_color
        else:
            for (num_cells_x - cursor_pos_x) i:
                text_rbuffer[base_idx + i] = 32
                text_c1buffer[base_idx + i] = text_color
                text_c2buffer[base_idx + i] = background_color

    def clr(level:int = 2):
        let num_cells = num_cells_x*num_cells_y
        if level == 0:
            text_rbuffer = map(num_cells): 32
        elif level == 1:
            text_rbuffer = map(num_cells): 32
            text_c1buffer = map(num_cells): text_color
        else:
            text_rbuffer = map(num_cells): 32
            text_c1buffer = map(num_cells): text_color
            text_c2buffer = map(num_cells): background_color
        ulc_buffer_idx = 0
        cursor_pos_x, cursor_pos_y = 0, 0
        
    def rnd_screen(level:int = 2):
        let num_cells = num_cells_x*num_cells_y
        if level == 0:
            text_rbuffer = map(num_cells):  32 + rnd(64)
        elif level == 1:
            text_rbuffer = map(num_cells):  32 + rnd(64)
            text_c1buffer = map(num_cells): color{rnd_float(), rnd_float(), rnd_float(), 1.0}
        else:
            text_rbuffer = map(num_cells):  32 + rnd(64)
            text_c1buffer = map(num_cells): color{rnd_float(), rnd_float(), rnd_float(), 1.0}
            text_c2buffer = map(num_cells): color{rnd_float(), rnd_float(), rnd_float(), 1.0}
        ulc_buffer_idx = 0
        cursor_pos_x, cursor_pos_y = 0, 0
        
    def putchar(col:int, row:int, c:int):
        if not check_col_row_(col, row): return
        text_rbuffer[ulc_buffer_idx + col + num_cells_x * row] = c

    def getchar(col:int, row:int) -> int:
        if not check_col_row_(col, row): return
        return text_rbuffer[ulc_buffer_idx + col + num_cells_x * row]

    def gotoxy(col:int, row:int):
        if not check_col_row_(col, row): return
        cursor_pos_x, cursor_pos_y = col, row
        
    def wherexy():
        return cursor_pos_x, cursor_pos_y
        
    // interface to regions and sprites (blit, retrieve screen regions)
    def blit(r:region, col:int, row:int, level:int = 2):
        var portion_x, portion_y = r.extend_x, r.extend_y
        var offset_x, offset_y = 0, 0
        if col + r.extend_x > num_cells_x:
            portion_x = num_cells_x - col
        elif col < 0:
            portion_x = portion_x + col
            offset_x = -col
            col = 0
        if row + portion_y > num_cells_y:
            portion_y = num_cells_y - row
        elif row < 0:
            portion_y = portion_y + row
            offset_y = -row
            row = 0
        //print "Debug: adjusted row, col: " + col + ", " + row
        //print "Debug: region offsets: " + offset_y + ", " + offset_x
        //print "Debug: region portions: " + portion_y + ", " + portion_x
        if level == 2:
            for (portion_y) i:
                for (portion_x) j:
                    let src_idx = (offset_y + i) * r.extend_x + offset_x + j
                    let curr_chr = r.text_rbuffer[src_idx]
                    if curr_chr != r.alpha_chr:
                        let tgt_idx = ulc_buffer_idx + (col + j) + num_cells_x * (row + i)
                        //print "Debug indices: src: " + src_idx + ", tgt: " + tgt_idx
                        text_rbuffer[tgt_idx] = curr_chr
                        text_c1buffer[tgt_idx] = r.text_c1buffer[src_idx]
                        text_c2buffer[tgt_idx] = r.text_c2buffer[src_idx]
        elif level == 1:
            for (portion_y) i:
                for (portion_x) j:
                    let src_idx = (offset_y + i) * r.extend_x + offset_x + j
                    let curr_chr = r.text_rbuffer[src_idx]
                    if curr_chr != r.alpha_chr:
                        let tgt_idx = ulc_buffer_idx + (col + j) + num_cells_x * (row + i)
                        text_rbuffer[tgt_idx] = curr_chr
                        text_c1buffer[tgt_idx] = r.text_c1buffer[src_idx]
        elif level == 0:
            for (portion_y) i:
                for (portion_x) j:
                    let curr_chr = r.text_rbuffer[(offset_y + i) * r.extend_x + offset_x + j]
                    if curr_chr != r.alpha_chr:
                        text_rbuffer[ulc_buffer_idx + (col + j) + num_cells_x * (row + i)] = curr_chr

    def blit(s:sprite, level:int = 2):
        let ulc = xy_i{0, 0}
        let lrc = xy_i{num_cells_x, num_cells_y}
        let chrs = s.chr_vecs
        let screensize = num_cells_x * num_cells_y
        //let within_screen = (s.pos.x < num_cells_x or (s.pos.x  + s.extend_x >= 0)) and (s.pos.y < num_cells_y or (s.pos.y  + s.extend_y >= 0))
        if level == 2:
            for (chrs.length) i:
                let chr_pos = chrs[i] + s.pos
                if manhattan((chr_pos >= ulc) + (chr_pos < lrc)) == 4: //  true on both in both dims makes 4
                    let tgt_idx = chr_pos.x + num_cells_x * chr_pos.y
                    text_rbuffer[tgt_idx] = s.text_rbuffer[i]
                    text_c1buffer[tgt_idx] = s.text_c1buffer[i]
                    text_c2buffer[tgt_idx] = s.text_c2buffer[i]
        elif level == 1:
            for (chrs.length) i:
                let chr_pos = chrs[i] + s.pos
                if manhattan((chr_pos >= ulc) + (chr_pos < lrc)) == 4:
                    let tgt_idx = chr_pos.x + num_cells_x * chr_pos.y
                    text_rbuffer[tgt_idx] = s.text_rbuffer[i]
                    text_c1buffer[tgt_idx] = s.text_c1buffer[i]
        elif level == 0:
            for (chrs.length) i:
                let chr_pos = chrs[i] + s.pos
                if manhattan((chr_pos >= ulc) + (chr_pos < lrc)) == 4:
                    text_rbuffer[chr_pos.x + num_cells_x * chr_pos.y] = s.text_rbuffer[i]

    def getscreenregion(col1:int, row1:int, col2:int, row2:int) -> region:
        if not check_col_row_(col1, row1) or not check_col_row_(col2, row2): return region{}
        // swap the parameter orders if col2 is smaller than col1 etc.
        if col1 > col2:
            col1, col2 = col2, col1
        if row1 > row2:
            row1, row2 = row2, row1
        let r = region{}
        r.extend_x = col2 - col1 + 1
        r.extend_y = row2 - row1 + 1        
        for (r.extend_y) i:
            for (r.extend_x) j:                
                let src_idx = ulc_buffer_idx + (col1 + j) + num_cells_x * (row1 + i) // parentheses for clarity!
                r.text_rbuffer.push(text_rbuffer[src_idx])
                r.text_c1buffer.push(text_c1buffer[src_idx])
                r.text_c2buffer.push(text_c2buffer[src_idx])
        assert r.text_rbuffer.length == r.extend_x * r.extend_y
        return r
        
    def getscreen() -> region:
        return getscreenregion(0, 0, num_cells_x - 1, num_cells_y - 1)

    // management functions
    def init(title:string, font_path:string, flags:int): // should add cols, rows, buffersize
        // init window
        var init_xs, init_ys = num_cells_x * fontwidth_, num_cells_y * lineheight
        if border_show:
            init_xs += 2 * border_cells_x * fontwidth_
            init_ys += 2 * border_cells_y * lineheight
        fatal(gl_window(title, init_xs, init_ys, flags))
        // init font
        check(gl_set_font_name(font_path), "can\'t load font!")
        fatal(gl_load_materials(pixshader, true))
        gl_set_font_size(fontheight)
        // init imgui debugger
        im_init(false)
        assert im_add_font("data/fonts/Droid_Sans/DroidSans.ttf", 20.0)
        // recalc frame size in px
        fontwidth_ = gl_text_size(" ").x
        rescale_()
        clr() // create empty buffer objects of size num_cells_x * num_cells_y
        running = true

    def sleep(t:float = 0.001):
        if running:
            if t <= 0.0: t = 0.001
            let t_now = gl_time()
            while gl_frame() and (gl_time() - t_now < t):
                if gl_button("escape") >= 1 and esc_does_quit:
                    running = false
                    break
                rescale_() // this also rescales the font
                if using_crt_shader:
                    post_process(nil, gl_window_size(), "simplecrt", false, texture_format_nomipmap): draw_()
                    gl_set_uniform("time", gl_time())
                else:
                    draw_()

    def run(body):
        running = true
        using_crt_shader = false
        while gl_frame() and running:
            if gl_button("escape") >= 1 and esc_does_quit:
                running = false
                return
            FPS = 1.0 / gl_delta_time()
            body()
            rescale_() // this also rescales the font
            draw_()
            im_frame(): pass()

    def run_crt(body):
        running = true
        using_crt_shader = true
        while gl_frame() and running:
            if gl_button("escape") >= 1 and esc_does_quit:
                running = false
                return
            FPS = 1.0 / gl_delta_time()
            body()
            rescale_() // this also rescales the font
            post_process(nil, gl_window_size(), "simplecrt", false, texture_format_nomipmap): draw_()
            gl_set_uniform("time", gl_time())
            im_frame(): pass()

    def breakpoint(lb:string = "1"):
        if running:
            var quit = false
            while gl_frame() and not quit:
                rescale_() // this also rescales the font
                if using_crt_shader:
                    post_process(nil, gl_window_size(), "simplecrt", false, texture_format_nomipmap): draw_()
                    gl_set_uniform("time", gl_time())
                else:
                    draw_()
                im_frame():
                    im_window("Debugger: BP " + lb + "Press [Cancel] to quit", im_window_always_autoresize):
                        im_show_engine_stats()
                        im_show_vars()
                        im_button("Cancel"): quit = true
        else:
            print "Cannot use breakpoint() before call to init()"
