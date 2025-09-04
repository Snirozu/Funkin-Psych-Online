function onCreate()
    precacheSound('Kick_Can_UP')

    makeFlxAnimateSprite('sprayCan')
    loadAnimateAtlas('sprayCan', 'phillyStreets/spraycanAtlas')
    setProperty('sprayCan.x', getProperty('sprayCans.x') - 430)
    setProperty('sprayCan.y', getProperty('sprayCans.y') - 840)
    setObjectOrder('sprayCan', getObjectOrder('sprayCans'))
    addLuaSprite('sprayCan')
    
    makeAnimatedLuaSprite('explosion', 'phillyStreets/spraypaintExplosionEZ')
    addAnimationByPrefix('explosion', 'anim', 'explosion round 1 short0', 24, false)
    setProperty('explosion.x', getProperty('sprayCan.x') + 1050)
    setProperty('explosion.y', getProperty('sprayCan.y') + 150)
    setObjectOrder('explosion', getObjectOrder('sprayCans'))
    addLuaSprite('explosion')
    setProperty('explosion.visible', false)
end

function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Kick Can' then
        playAnim('dad', 'kickCan')
        setProperty('dad.specialAnim', true)
        playSound('Kick_Can_UP')

        playAnim('sprayCan')
        setProperty('sprayCan.anim.curFrame', 0)
        setProperty('sprayCan.visible', true)
        setOnLuas('canEndFrame', 25) -- Makes the variable available to all the Lua scipts with that value.
    end
end

canEndFrame = 0
function onUpdate(elapsed)
    -- This is how we control the animations' speed depending on the 'playbackRate' for Atlas Sprites.
    setProperty('sprayCan.anim.framerate', 24 * playbackRate)
    --[[
        This make it so the animation stop when it's supposed to be,
        instead of continuing on, and looping endlessly.
    ]]
    if getProperty('sprayCan.anim.curFrame') == canEndFrame then
        pauseAnim('sprayCan')
        setProperty('sprayCan.visible', false)
    end
    -- This is for the explosion when the can hits Pico.
    if getProperty('sprayCan.anim.curFrame') == 23 then
        playAnim('explosion', 'anim')
        setProperty('explosion.visible', true)
    end
    if getProperty('explosion.animation.finished') == true then
        setProperty('explosion.visible', false)
    end
end
    
function pauseAnim(object)
    runHaxeCode("game.getLuaObject('"..object.."').anim.pause();")
end