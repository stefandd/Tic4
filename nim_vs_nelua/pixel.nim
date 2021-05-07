import ptrmath
import random
import nimraylib_now/raylib

# Initialization
const
    screen_width: int32 = 1024
    screen_height: int32 = 768

initWindow(screen_width, screen_height, "raylib pixel fill test")

# NOTE: Textures/Images must be loaded after Window initialization (OpenGL context is required)
var image = genImageColor(screen_width, screen_height, BLACK)
imageFormat(addr image, 7) # PixelFormat.UNCOMPRESSED_R8G8B8A8)  # Format image to RGBA 32bit (required for screentex update) <-- ISSUE
var
    screentex = loadTextureFromImage(image) # Image converted to screentex, GPU memory (VRAM)
    screenptr : ptr Color = loadImageColors(image) # Get pixel data from image (RGBA 32bit)
    t_last = getTime()
    frames : int32 = 0

ptrMath:
    proc randpixel() =
        for i in 0 ..< screen_width * screen_height:
            screenptr[i] = Color(r:cast[uint8](rand(255)), g:cast[uint8](rand(255)), b:cast[uint8](rand(255)), a:255)

while not windowShouldClose(): # Detect window close button or ESC key
    frames = frames + 1
    randpixel()
    updateTexture(screentex, screenptr)
    beginDrawing()
    clearBackground(BLACK)
    drawTexture(screentex, 0, 0, WHITE)
    drawFPS(0, 0)
    endDrawing()        
    var t_now = getTime()
    if t_now - t_last > 1.0:
        echo "FPS:", frames
        t_last = t_now
        frames = 0

unloadTexture(screentex)
unloadImage(image)
closeWindow() # Close window and OpenGL context
