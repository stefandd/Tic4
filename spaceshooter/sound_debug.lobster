def sound_channels(): // how many open channels are available, what is the total number of channels available
    play_wav("") // force sound init
    var i, avail = 1, 0
    var st = sound_status(i)
    while st != -1:
        if st == 0: // free channel?
            avail++
        i++
        st = sound_status(i)
    return avail, i - 1 // available channels, total number of channels

let free_channels, num_channels = sound_channels()
def sound_info(): // see the entire channel activity as map
    return map(num_channels) i:
        sound_status(i + 1)

