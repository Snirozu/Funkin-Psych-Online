function onCreate()
    if boyfriendName == 'pico-player' then
        pauseMusic = getPropertyFromClass('backend.ClientPrefs', 'data.pauseMusic')
        setPropertyFromGameOver('characterName', 'pico-player-dead')
        setPropertyFromGameOver('deathSoundName', 'fnf_loss_sfx-pico')
        setPropertyFromGameOver('loopSoundName', 'gameOver-pico')
        setPropertyFromGameOver('endSoundName', 'gameOverEnd-pico')
        addCharacterToList('pico-player-dead-explode', 'boyfriend')
    end
end

function onPause()
    --[[
        Checks and replaces the Pause Menu music to the '-pico' version, if there's one.
        If not, it'll keep the original one.
        Ex: 'Tea Time' will stay the same since there isn't a 'tea-time-pico' present in the files.
    ]]
    if boyfriendName == 'pico-player' then
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
    if boyfriendName == 'pico-player' and stringEndsWith(getPropertyFromClass('backend.ClientPrefs', 'data.pauseMusic'), ' Pico') then
        setPropertyFromClass('backend.ClientPrefs', 'data.pauseMusic', pauseMusic)
    end
end

function onGameOverStart()
    if boyfriendName == 'pico-player' then
        if stringEndsWith(getPropertyFromGameOver('deathSoundName'), '-explode') then
            runTimer('delayDeathMusic', 3)
            setPropertyFromGameOver('boyfriend.visible', false)
            setPropertyFromGameOver('playingDeathSound', true) -- Despite what it could mean, it actually prevents 'loopSoundName' from playing.

            --[[
                Since any versions below 1.0 doesn't support Atlas characters for Game Over,
                I need to make it myself and play the animations manually.
            ]]
            makeFlxAnimateSprite('picoExplosionDeath', getProperty('boyfriend.x') + 325, getProperty('boyfriend.y') + 155)
            loadAnimateAtlas('picoExplosionDeath', 'characters/picoExplosionDeath')
            setObjectOrder('picoExplosionDeath', getObjectOrder('boyfriendGroup'))
            addAnimationBySymbolIndices('picoExplosionDeath', 'firstDeath', 'Pico Explosion Death',
            {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
            15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
            30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44,
            45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
            60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
            75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
            90, 91})
            addAnimationBySymbolIndices('picoExplosionDeath', 'deathLoop', 'Pico Explosion Death',
            {92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106,
            107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119}, 24, true)
            addAnimationBySymbolIndices('picoExplosionDeath', 'deathConfirm', 'Pico Explosion Death',
            {120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134,
            135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149,
            150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164,
            165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179,
            180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194,
            195, 196, 197, 198})
            playAnim('picoExplosionDeath', 'firstDeath')
            addLuaSprite('picoExplosionDeath', true)
        else
            makeAnimatedLuaSprite('gameOverRetry', 'characters/Pico_Death_Retry', getProperty('boyfriend.x') + 208, getProperty('boyfriend.y') - 84)
            addAnimationByPrefix('gameOverRetry', 'idle', 'Retry Text Loop0')
            addAnimationByPrefix('gameOverRetry', 'confirm', 'Retry Text Confirm0', 24, false)
            addOffset('gameOverRetry', 'confirm', 250, 200)
            addLuaSprite('gameOverRetry', true)
            setProperty('gameOverRetry.visible', false)
            
            makeAnimatedLuaSprite('neneDeathSprite', 'characters/NeneKnifeToss', getProperty('boyfriend.x') - 560, getProperty('boyfriend.y') - 280)
            addAnimationByPrefix('neneDeathSprite', 'throw', 'knife toss0', 24, false)
            addLuaSprite('neneDeathSprite', true)
        end
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'delayDeathMusic' then
        playMusic('gameOverStart-pico-explode')
        local musicLength = runHaxeCode("FlxG.sound.music.length;") / 1000
        runTimer('startMusicLoop', musicLength)
    end
    if tag == 'startMusicLoop' then
        setPropertyFromGameOver('playingDeathSound', false) -- That's when the 'loopSoundName' plays.
    end
end

function onUpdate(elapsed)
    if boyfriendName == 'pico-player' and inGameOver == true then
        if stringEndsWith(getPropertyFromGameOver('deathSoundName'), '-explode') then
            setProperty('camFollow.x', getMidpointX('boyfriend') - 240)
            setProperty('camFollow.y', getMidpointY('boyfriend') - 160)

            if getProperty('picoExplosionDeath.anim.lastPlayedAnim') == 'firstDeath' then
                if getProperty('picoExplosionDeath.anim.finished') == true then
                    playAnim('picoExplosionDeath', 'deathLoop')
                end
            end
        else
            setProperty('camFollow.x', getMidpointX('boyfriend') - 230)
            setProperty('camFollow.y', getMidpointY('boyfriend') - 90)

            if getProperty('neneDeathSprite.animation.finished') then
                setProperty('neneDeathSprite.visible', false)
            end
            if getPropertyFromGameOver('boyfriend.animation.curAnim.name') == 'firstDeath' then
                if getPropertyFromGameOver('boyfriend.animation.curAnim.curFrame') == 35 then
                    playAnim('gameOverRetry', 'idle')
                    setProperty('gameOverRetry.visible', true)
                end
            end
        end
    end
end

function onGameOverConfirm(isNotGoingToMenu)
    if isNotGoingToMenu == true and boyfriendName == 'pico-player' then
        if stringEndsWith(getPropertyFromGameOver('deathSoundName'), '-explode') then
            playAnim('picoExplosionDeath', 'deathConfirm')
        else
            playAnim('gameOverRetry', 'confirm')
            setProperty('gameOverRetry.visible', true)
        end
    end
end

function getPropertyFromGameOver(property)
    if getPropertyFromClass('substates.GameOverSubstate', property) ~= nil then
        return getPropertyFromClass('substates.GameOverSubstate', property)
    else
        return getPropertyFromClass('substates.GameOverSubstate', 'instance.'..property)
    end
end

function setPropertyFromGameOver(property, value)
    if getPropertyFromClass('substates.GameOverSubstate', property) ~= nil then
        setPropertyFromClass('substates.GameOverSubstate', property, value)
    else
        setPropertyFromClass('substates.GameOverSubstate', 'instance.'..property, value)
    end
end