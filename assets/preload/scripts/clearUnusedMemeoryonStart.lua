function onSongStart() -- dont want the game using over 1.2 GBs
    runHaxeCode([[ 
        Paths.clearUnusedMemory();
    ]])
end

function onEndSong() -- same with up above but on end instead of start
    runHaxeCode([[ 
        Paths.clearUnusedMemory();
    ]])
end