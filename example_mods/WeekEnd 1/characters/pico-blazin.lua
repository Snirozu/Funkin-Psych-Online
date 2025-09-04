function onCreate()
    if boyfriendName == 'pico-blazin' then
        pauseMusic = getPropertyFromClass('backend.ClientPrefs', 'data.pauseMusic')
        --setPropertyFromGameOver('characterName', 'pico-blazin-dead')
        setPropertyFromGameOver('deathSoundName', 'fnf_loss_sfx-pico-gutpunch')
        setPropertyFromGameOver('loopSoundName', 'gameOver-pico')
        setPropertyFromGameOver('endSoundName', 'gameOverEnd-pico')
        addCharacterToList('pico-blazin-dead', 'boyfriend')
    end
end

function onPause()
    --[[
        Checks and replaces the Pause Menu music to the '-pico' version, if there's one.
        If not, it'll keep the original one.
        Ex: 'Tea Time' will stay the same since there isn't a 'tea-time-pico' present in the files.
    ]]
    if boyfriendName == 'pico-blazin' then
        fileName = pauseMusic:gsub(' ', '-'):lower()
        if checkFileExists(currentModDirectory..'/music/'..fileName..'-pico.ogg') then
            setPropertyFromClass('backend.ClientPrefs', 'data.pauseMusic', pauseMusic..' Pico')
        end
    end
end

function onDestroy()
    --[[ 
        Since we don't want the Pause Menu to stay stuck to the '-pico' version all the time,
        we revert it back to normal to avoid any issues and keep it exclusive to our character.
    ]]
    if boyfriendName == 'pico-blazin' and stringEndsWith(getPropertyFromClass('backend.ClientPrefs', 'data.pauseMusic'), ' Pico') then
        setPropertyFromClass('backend.ClientPrefs', 'data.pauseMusic', pauseMusic)
    end
end

function onGameOverStart()
    if boyfriendName == 'pico-blazin' then
        runTimer('delayDeathMusic', 1.25)
        setPropertyFromGameOver('boyfriend.visible', false)
        setPropertyFromGameOver('playingDeathSound', true) -- Despite what it could mean, it actually prevents 'loopSoundName' from playing.

        --[[
            Since any versions below 1.0 doesn't support Atlas characters for Game Over,
            I need to make it myself and play the animations manually.
        ]]
        makeFlxAnimateSprite('picoBlazinDeath', getProperty('boyfriend.x'), getProperty('boyfriend.y') - 400)
        loadAnimateAtlas('picoBlazinDeath', 'characters/picoBlazin')
        setObjectOrder('picoBlazinDeath', getObjectOrder('boyfriendGroup'))
        scaleObject('picoBlazinDeath', 1.75, 1.75)
        addAnimationBySymbolIndices('picoBlazinDeath', 'firstDeath', 'Pico Fighting ALL ANIMS',
        {85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
        100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114,
        115, 116})
        addAnimationBySymbolIndices('picoBlazinDeath', 'deathLoop', 'Pico Fighting ALL ANIMS',
        {122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136,
        137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151,
        152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166,
        167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181,
        182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196,
        197, 198}, 24, true)
        addAnimationBySymbolIndices('picoBlazinDeath', 'deathConfirm', 'Pico Fighting ALL ANIMS',
        {277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291,
        292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306,
        307, 308, 309, 310, 311, 312, 313, 314, 315, 316, 317, 318, 319, 320, 321,
        322, 323, 324, 325, 326, 327, 328, 329})
        playAnim('picoBlazinDeath', 'firstDeath')
        addLuaSprite('picoBlazinDeath', true)
    end
end

local hasDied = false
local timerStarted = false
local animToLoop = {'taunt', 'uppercut'}
local zoomValue = 0.75
function onUpdate(elapsed)
    --[[
        Delays the death of Pico slightly with the 'preTransitionDelay' value.
        This value can be found in the 'pico-blazin' JSON in the original game files.
    ]]
    if hasDied == false and getHealth() <= 0 then
        setHealth(0.01)
        if timerStarted == false then
            runTimer('deathDelay', 0.125)
            timerStarted = true
        end
    end

    --[[ 
        Makes the character play the '-loop' variation of their animation.
        The animation's name must be put into the 'animToLoop' variable,
        and their '-loop' variation must be present within the character's JSON file.
        WARNING: THIS IS FOR ATLAS CHARACTERS ONLY!!!
    ]]
    for name = 0, #animToLoop do
        character = getCharacterType('pico-blazin')
        if getProperty(character..'.atlas.anim.finished') then
            if getProperty(character..'.atlas.anim.lastPlayedAnim') == animToLoop[name] then
                playAnim(character, animToLoop[name]..'-loop', true)
            end
        end
    end

    -- This is how we control the animations' speed depending on the 'playbackRate' for Atlas Sprites.
    setProperty(getCharacterType('pico-blazin')..'.atlas.anim.framerate', 24 * playbackRate)

    if boyfriendName == 'pico-blazin' and inGameOver == true then
        -- This is to zoom out the camera smoothly during Game Over.
        zoomValue = math.smoothLerp(zoomValue, 0.6, elapsed, 0.5, 1 / 100)
        runHaxeCode("FlxG.camera.zoom = "..zoomValue..";")

        setProperty('camFollow.x', getMidpointX('boyfriend') - 70)
        setProperty('camFollow.y', getMidpointY('boyfriend') - 465)

        if getProperty('picoBlazinDeath.anim.lastPlayedAnim') == 'firstDeath' then
            if getProperty('picoBlazinDeath.anim.finished') == true then
                playAnim('picoBlazinDeath', 'deathLoop')
            end
        end
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'deathDelay' then
        hasDied = true
        setHealth(0)
    end
    if tag == 'delayDeathMusic' then
        playMusic('gameOver-pico')
        local musicLength = runHaxeCode("FlxG.sound.music.length;") / 1000
        runTimer('startMusicLoop', musicLength)
    end
    if tag == 'startMusicLoop' then
        setPropertyFromGameOver('playingDeathSound', false) -- That's when the 'loopSoundName' plays.
    end
end

function getCharacterType(characterName)
    if boyfriendName == characterName then
        return 'boyfriend'
    elseif dadName == characterName then
        return 'dad'
    elseif gfName == characterName then
        return 'gf'
    end
end

function math.smoothLerp(current, target, elapsed, duration, precision)
    if current == target then
        return target
    end
    local result = current + (1 - (precision ^ (elapsed / duration))) * (target - current)

    if math.abs(result - target) < precision * target then
        result = target
    end
    return result
end

function onGameOverConfirm(isNotGoingToMenu)
    if isNotGoingToMenu == true and boyfriendName == 'pico-blazin' then
        playAnim('picoBlazinDeath', 'deathConfirm')
    end
end

function setPropertyFromGameOver(property, value)
    if getPropertyFromClass('substates.GameOverSubstate', property) ~= nil then
        setPropertyFromClass('substates.GameOverSubstate', property, value)
    else
        setPropertyFromClass('substates.GameOverSubstate', 'instance.'..property, value)
    end
end