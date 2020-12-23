import console2 
import date_time
import sound_debug

// console setup
let c:console = console{border_show:true, border_cells_x:2, border_cells_y:2, num_cells_x:40, num_cells_y:40, fontheight:20, fontwidth_:20, lineheight:20, text_color:color{0.2, 1.0, 0.2, 1}, background_color:color{0.2, 0.2, 0.2, 1}}
c.init("Space Attack -- press ESC to surrender", "data/fonts/Px437_IBM/Px437_IBM_BIOS.ttf", gl_window_init_no_vsync)

// class definitions
class Intro:
    txt = "\n\n[INCOMING MESSAGE FROM H.Q.]:\n\n\nWelcome Pilot! You have been recruited\nto defend earth from a fleet of alien\ninvasion ships.\nWe have reliable intel on the strategy\nof the alien ships. The enemy will send waves of drone ships that are equipped \nwith laser turrets. When close to each \nother, these ships learn how to fire\nlaser bolts at you. In each swarm, more\nand more ships will already initially\nknow how to shoot,and over time, they\nwill also improve their laser rechargingprocess, resulting in more rapid fire.\n\nKill as many as you can, soldier!\n\nYour remote controlled viper is moved\nusing the arrow keys and the hypersonic\nprojectile gun fires with SPACE.\n\n\n\n\n[PRESS RETURN TO CONTINUE]"
    cursor = cp437_to_unicode[0xdb]
    screen_cpy:region = region{}
    intro_stage = 0
    def run():
        if intro_stage == 0:
            c.text_color = color{0.66405, 1.0, 0.88235, 1}
            sound_volume(play_wav("data/sounds/AlienNostromoStartup_.wav", 0, 1), 1.0) // explosion sound
            for (txt.length) i:
                c.writexy(0, 0, substring(txt, 0, i + 1) + unicode_to_string([cursor]))
                sound_volume(play_wav("data/sounds/AlienWrite.wav", 0, 1), 0.05) // explosion sound
                if i <= 34: // header line a bit slower
                    c.sleep(0.08)
                else:
                    c.sleep(0.02)
            screen_cpy = c.getscreen()
            intro_stage = 1
        elif intro_stage == 1: // wait for ENTER to be pressed
            c.writexy(0, 0, txt + unicode_to_string([cursor]))
            if gl_button("return") >= 1:
                intro_stage++
        else: // animate message removal
            for (c.num_cells_x + 1) i:
                c.clr()
                c.blit(screen_cpy, -i, 0)
                c.sleep(0.03)
            intro_stage++
        
class UFO : sprite
    health_state = 0 // 0 - alive, 1 - xplosion 1, 2 - explosion 2
    activated = false
    activation_counter = 0
    activation_thresh = 1
    t_fired = 0.0
    fire_delay = 0.2
    t_state_chg = 0.0
    t_moved = 0.0
    move_delay = 0.1
    def clone() -> UFO:
        let cp = UFO{}
        cp.text_rbuffer = text_rbuffer.copy()
        cp.text_c1buffer = text_c1buffer.copy()
        cp.text_c2buffer = text_c2buffer.copy()
        cp.chr_vecs = chr_vecs.copy()
        cp.extend = extend
        cp.pos = pos
        // also copy difficulty level-relevant fields
        cp.activation_counter = activation_counter
        cp.activation_thresh = activation_thresh
        cp.fire_delay = fire_delay 
        return cp

class Projectile : sprite
    t_moved = 0.0
    move_delay = 0.01 // on slow computers this might mean (as fast as possible)
    def clone() -> Projectile:
        let cp = Projectile{}
        cp.move_delay = move_delay // need to copy since there are 2 different types of Projectile with diff. speeds
        cp.text_rbuffer = text_rbuffer.copy()
        cp.text_c1buffer = text_c1buffer.copy()
        cp.text_c2buffer = text_c2buffer.copy()
        cp.chr_vecs = chr_vecs.copy()
        cp.extend = extend
        cp.pos = pos
        return cp
        
class Player : sprite
    health_state = 0
    bullet_spawn_posx = 0
    t_fired = 0.0
    fire_delay = 0.1
    t_state_chg = 0.0
    t_moved = 0.0
    move_delay = 0.02
    
// define/load sprites, regions
var player = Player{}
let playersprite, playersprite_xp1, playersprite_xp2 = sprite{}, sprite{}, sprite{}
playersprite.fromREXPaint("data/textsprites/spaceship.csv")
playersprite_xp1.fromREXPaint("data/textsprites/spaceship_xp1.csv")
playersprite_xp2.fromREXPaint("data/textsprites/spaceship_xp2.csv")
let ufo_zero, ufosprite_xp1, ufosprite_xp2 = UFO{}, sprite{}, sprite{}
ufo_zero.fromREXPaint("data/textsprites/ufo.csv")
ufosprite_xp1.fromREXPaint("data/textsprites/ufo_xp1.csv")
ufosprite_xp2.fromREXPaint("data/textsprites/ufo_xp2.csv")
let nightsky = region{alpha_chr:-1  }
nightsky.fromREXPaint("data/textsprites/nightsky.csv")
let bulletsprite = Projectile{text_rbuffer:[cp437_to_unicode[249]], text_c1buffer:[color_white], text_c2buffer:[c.background_color], chr_vecs:[xy_i{0, 0}], move_delay: 0.01}
let lasersprite = Projectile{text_rbuffer:['|'], text_c1buffer:[color_red], text_c2buffer:[c.background_color], chr_vecs:[xy_i{0, 0}], move_delay: 0.05}
// game variables
let intro = Intro{}
var UFO_num = 16
var UFO_initially_activated = 0
var UFOs:[UFO], UFOs_lw:[UFO] = [], []
var UFOs_alive:[UFO] = []
var active_bullets:[Projectile] = []
var active_lasers:[Projectile] = []
var t_now = 0.0
let t_seed:int = date_time()[dt_epoch]
var game_stage = 0 // 0: pre-stage, 1: stage loaded/paused, 2: stage running, 3: stage over
let diff_initact:[int] =     [1, 2, 2, 2, 3  , 3  , 3  , 4  , 4  , 4  , 4  , 4  , 4  , 5  , 5  , 5  , 5  , 5  , 5  , 6  ]
let diff_actthresh:[int] =   [4, 4, 3, 3, 3  , 3  , 3  , 3  , 3  , 2  , 2  , 2  , 2  , 2  , 2  , 2  , 1]
let diff_firedelay:[float] = [1, 1, 1, 1, 0.8, 0.8, 0.8, 0.8, 0.8, 0.6, 0.6, 0.6, 0.6, 0.6, 0.4, 0.4, 0.4, 0.4, 0.4, 0.2]
var difficulty = 0
var score, score_lw, base_score = 0, 0, 0 // total score, level-based base score for UFO kill
var FPS_counter, FPS_sum, FPS_t0 = 0, 0.0, 0.0 // remove me later

def initialize(wave_repeat:bool = false):
    player = Player{}
    player.copyfrom(playersprite, false) // load undamaged ship
    player.pos = xy_i{ 18, 36}
    active_bullets = []
    active_lasers = []
    // inital placement UFOs
    if wave_repeat:
        UFOs = map(UFO_num) i: UFOs_lw[i].clone()
        for (UFOs) u: u.t_moved = t_now // reset move time flag on all UFOs
        score = score_lw // reset score
    else:
        base_score += 10
        // change the difficulty-related fields in the UFO (ufo_zero) from which all active ones are cloned
        UFO_initially_activated = diff_initact[min(difficulty, diff_initact.length - 1)]
        ufo_zero.activation_thresh = diff_actthresh[min(difficulty, diff_actthresh.length - 1)]
        ufo_zero.fire_delay = diff_firedelay[min(difficulty, diff_firedelay.length - 1)]
        difficulty++
        if difficulty > 20: UFO_num++ // make it really impossible to win by adding more UFOs past lvl 20
        UFOs = map(UFO_num): ufo_zero.clone() // many UFOs
        for (UFOs) u, i: // place UFOs collision-free
            var pos_OK = false
            while not pos_OK:
                u.pos = xy_i{rnd(c.num_cells_x), rnd(c.num_cells_y / 4) + 2} // put them into the upper third of the screen
                if i > 0: // 2nd UFO needs to also account for the 1st etc.
                    let collision_info = map(i) j: u.collisiontest(UFOs[j])
                    pos_OK = not any(collision_info) and not player.collisiontest(u)
                else:
                    pos_OK = not player.collisiontest(u) // 1st UFO we only check for collision with player
            u.t_moved = t_now // set move time flag
        for (UFO_initially_activated) i: // activate a certain initial number of UFOs
            var idx = rnd(UFO_num)
            while UFOs[idx].activation_counter: idx = rnd(UFO_num)
            UFOs[idx].activation_counter = UFOs[idx].activation_thresh
        UFOs_lw = map(UFO_num) i: UFOs[i].clone() // save the positions of this wave for a potential repeat!
        score_lw = score // save score in case a repeat of the wave is necessary
    
def kill_player(): // function because we need this in 2 places (UFO collision and laser hit)
    sound_volume(play_wav("data/sounds/player_killed.wav", 0, 1), 1.0) // explosion sound
    player.health_state = 1
    player.copyfrom(playersprite_xp1, false)
    player.t_state_chg = t_now

def update_ufos():
    // move one UFO but so that the UFOs don't collide with each other or the player and horizontally towards the player ship
    UFOs_alive = filter(UFOs) u: u.health_state == 0
    let num_alive = UFOs_alive.length
    if num_alive:
        for (UFOs_alive) u, ufo_idx:
            // 1st part -- firing at player
            if u.activated:
                if t_now - u.t_fired > u.fire_delay and player.health_state == 0: // shoot at player if they are alive
                    lasersprite.pos = u.pos + xy_i{2, 2}
                    u.text_c1buffer[5] = color{0.74902, 0.74902, 0.74902, 1} // reseting to original color
                    active_lasers.push(lasersprite.clone()) // put bullet in active bullets list
                    play_wav("data/sounds/126423__cabeeno-rossley__shoot-laser_short.wav", 0, 0) // make laser sound
                    u.t_fired = t_now
                else:
                    let normlz = 1 - (t_now - u.t_fired) / u.fire_delay // color animation showing the heating up of the laser gun
                    u.text_c1buffer[5] = color{1 + (0.74902 - 1) * normlz, 0.74902 * normlz, 0.74902 * normlz, 1} // laser pod is the 6th character
            else:
                if u.activation_counter >= u.activation_thresh:
                    u.activated = true
                    u.t_fired = t_now
            // 2nd part -- move attempt
            if t_now - u.t_moved > u.move_delay:
                let ufo_opos = u.pos
                if player.health_state == 0: // if player is alive, we horizontally move towards their position
                    u.pos = ufo_opos + xy_rndi(3) - 1 + xy{ 2 * (ufo_opos.x < player.pos.x) - 1, 0 }
                else:
                    u.pos = ufo_opos + xy_rndi(3) - 1
                while u.pos.y < 0 or u.pos.y > 3 * (c.num_cells_y / 4): u.pos = xy_i{u.pos.x, ufo_opos.y + rnd(3) - 1} // stay in upper 3/4 of screen vertically
                // test for collisions, first with player
                let player_ufo_collision = player.collisiontest(u) and player.health_state == 0 // UFO-player collision on attempted move?
                if player_ufo_collision: kill_player()
                let collision_info = filter(num_alive) i: i != ufo_idx and u.collisiontest(UFOs_alive[i]) // collisions with other UFOs
                // if this UFO is activated already, bumping into another one increases the chances for that one to be activated
                for (collision_info) i:
                    if u.activated: UFOs_alive[i].activation_counter++ 
                if collision_info.length or player_ufo_collision: // abandon move attempt if UFO-UFO collision
                    u.pos = ufo_opos
                u.t_moved = t_now // move attempts count as move
    elif active_lasers.length == 0: // decide stage outcome only after last UFO laser bolts are off the screen!
        game_stage = 3 // one side won
    // update sprite stages and show sprites
    for (UFOs) u:
        if u.health_state == 1 and t_now - u.t_state_chg > 0.2:
            u.health_state = 2
            u.copyfrom(ufosprite_xp2, false)
            u.t_state_chg = t_now            
        if u.health_state == 2 and t_now - u.t_state_chg > 0.2:
            u.health_state = 3
            //c.breakpoint("UFO killed")
        if u.health_state < 3:
            c.blit(u, 1)

def update_player():
    // helper function to detect collisions
    def move_check_collisions(testpos):
        let origpos = player.pos
        player.pos = testpos
        let collision_info = map(UFOs_alive) ufo: player.collisiontest(ufo)
        if any(collision_info):
            player.pos = origpos // move player back

    // first check for player health:
    if player.health_state == 0: // alive
        if t_now - player.t_moved > player.move_delay: // limit the player key repeat rate
            var newpos = player.pos
            if gl_button("right") >= 1: newpos += xy_i{1, 0}
            if gl_button("left") >= 1: newpos -= xy_i{1, 0}
            if gl_button("up") >= 1: newpos -= xy_i{0, 1}
            if gl_button("down") >= 1 and player.pos.y < c.num_cells_y - 2:
                newpos += xy_i{0, 1} // don't let the player fully disappear at the screen bottom
            move_check_collisions(newpos)
            player.t_moved = t_now
        if t_now - player.t_fired > player.fire_delay:
            if gl_button("space") >= 1:
                play_wav("data/sounds/laser_buzz.wav", 0, 1) // make buzzer sound
                bulletsprite.pos = player.pos + xy_i{player.bullet_spawn_posx, 1}
                active_bullets.push(bulletsprite.clone()) // put bullet in active bullets list
                player.bullet_spawn_posx = 4 - player.bullet_spawn_posx // activate other barrel
                player.t_fired = t_now
    else:
        game_stage = 3 // one side won
    // update sprite stages and show sprites
    if player.health_state == 1 and t_now - player.t_state_chg > 0.2:
        player.health_state = 2
        player.copyfrom(playersprite_xp2, false)
        player.pos -= xy_i{1, 1} // bigger explosion cloud needs to be shifted a bit
        player.t_state_chg = t_now            
    if player.health_state == 2 and t_now - player.t_state_chg > 0.2:
        player.health_state = 3
    if player.health_state < 3:
        c.blit(player, 1)

def update_projectiles():
    // bullet movement (player projectiles)
    active_bullets = filter(active_bullets) ab: (ab.pos.y >= 0)
    for (active_bullets) b:
        if t_now - b.t_moved > b.move_delay:
            b.pos -= xy_i{0, 1}
            b.t_moved = t_now
        for (UFOs) ufo:
            if b.collisiontest(ufo) and ufo.health_state == 0:
                play_wav("data/sounds/player_killed.wav", 0, 1) // explosion sound
                ufo.health_state = 1
                ufo.copyfrom(ufosprite_xp1, false)
                ufo.t_state_chg = t_now
                b.pos = xy_i{0, -1} // move out of screen (it will be removed on the next filter call)
                if ufo.activated: score += int(1.5*base_score) else: score += base_score
        c.blit(b, 1) // level 1 = character and text color
    // laser bolt movement (UFO projectiles)
    active_lasers = filter(active_lasers) al: (al.pos.y < c.num_cells_y)
    for (active_lasers) l:
        if t_now - l.t_moved > l.move_delay:
            l.pos += xy_i{0, 1}
            l.t_moved = t_now
        if l.collisiontest(player) and player.health_state == 0:
            kill_player()
            l.pos = xy_i{0, c.num_cells_y} // move laser out of screen (it will be removed on the next filter call)
        c.blit(l, 1)

// main loop
FPS_t0 = gl_time()
c.run_crt():
    t_now = gl_time()
    switch game_stage:
        case 0:
            //intro.intro_stage = 3// skip intro
            intro.run()
            if intro.intro_stage > 2:
                let bgmusic = play_wav("data/sounds/Cyber-Dream-Loop short.wav", -1) // by Eric Matyas from https://soundimage.org/looping-music/
                if bgmusic: sound_volume(bgmusic, 0.5) else: print "can\'t load music!"
                game_stage = 1
        case 1:
            c.text_color = color{rnd_float(), rnd_float(), rnd_float(), 1}
            c.writexy(9, 10, "PRESS <RETURN> TO START", 1)
            if gl_button("return") >= 1:
                initialize()
                game_stage++
        case 2,3:
            c.blit(nightsky, 0, 0)
            c.text_color = color_light_blue
            c.writexy(0, 0, "SCORE: ", 1); c.write(string(score), 1)
            c.writexy(0, 1, "LEVEL: ", 1); c.write(string(difficulty), 1)
            update_ufos()
            update_projectiles()
            update_player()
            switch game_stage:
                case 2:
                    pass() //c.writexy(0, 38, string(sound_info()), 1) // sound debug info
                case 3:
                    c.text_color = color{rnd_float(), rnd_float(), rnd_float(), 1}
                    if player.health_state == 0:
                        c.writexy(5, 10, "PRESS <RETURN> FOR NEXT WAVE", 1)
                    else:
                        c.writexy(4, 10, "PRESS <RETURN> TO REPEAT THIS WAVE", 1)
                    if gl_button("return") >= 1:
                        initialize(player.health_state != 0) // wave repeat flag based on player health
                        rnd_seed(t_seed) // make sure that even subtle effects are identical
                        game_stage =  2 // 0: pre-stage, 1: stage loaded/paused, 2: stage running, 3: stage over
    // stats (turn off vsync to measure)
    FPS_sum += c.FPS
    FPS_counter++
    if t_now-FPS_t0 > 2: // only every 2 secs
        print "avg. FPS: " + FPS_sum / FPS_counter
        FPS_t0, FPS_counter, FPS_sum = t_now, 0, 0.0