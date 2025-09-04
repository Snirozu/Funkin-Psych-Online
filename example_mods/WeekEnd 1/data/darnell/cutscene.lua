local stopCountdown = true
local videoFinished = false

function onCreatePost()
    if isStoryMode == true and seenCutscene == false then
        if getModSetting('cutscenes', currentModDirectory) ~= 'Disabled' then
            if not isRunning('custom_events/Set Camera Target') then
                addLuaScript('custom_events/Set Camera Target')
            end
            if not isRunning('custom_events/Set Camera Zoom') then
                addLuaScript('custom_events/Set Camera Zoom')
            end

            makeLuaSprite('blackScreen')
            makeGraphic('blackScreen', 2000, 2500, '000000')
            screenCenter('blackScreen')
            setObjectCamera('blackScreen', 'camOther')
            addLuaSprite('blackScreen', true)

            makeAnimatedLuaSprite('sprayCan', 'phillyStreets/wked1_cutscene_1_can', getProperty('sprayCans.x') + 30, getProperty('sprayCans.y') - 320)
            addAnimationByPrefix('sprayCan', 'forward', 'can kick quick0', 24, false)
            addAnimationByPrefix('sprayCan', 'up', 'can kicked up0', 24, false)
            setObjectOrder('sprayCan', getObjectOrder('sprayCans'))
            addLuaSprite('sprayCan')
            setProperty('sprayCan.visible', false)

            makeFlxAnimateSprite('sprayCanExplosion')
            loadAnimateAtlas('sprayCanExplosion', 'phillyStreets/spraycanAtlas')
            setProperty('sprayCanExplosion.x', getProperty('sprayCans.x') - 430)
            setProperty('sprayCanExplosion.y', getProperty('sprayCans.y') - 840)
            setObjectOrder('sprayCanExplosion', getObjectOrder('sprayCans'))
            addLuaSprite('sprayCanExplosion')
            setProperty('sprayCanExplosion.visible', false)

            triggerEvent('Set Camera Zoom', '1.3', '')
            setProperty('camHUD.visible', false)
            if getModSetting('cutscenes', currentModDirectory) ~= 'In-Game Only' then
                makeVideoSprite('darnellCutscene', 'darnellCutscene', 0, 0, 'camOther', false)
                setProperty('darnellCutscene.antialiasing', true)
                --startVideo('darnellCutscene') -- Before I used the Video Sprite script.
            end
        end
    end
end

function onVideoFinished(tag) -- Exclusive to the Video Sprite script.
    if tag == 'darnellCutscene' then
        videoFinished = true
        startCountdown()
    end
end

function onStartCountdown()
    if isStoryMode == true and seenCutscene == false then
        if getModSetting('cutscenes', currentModDirectory) ~= 'Disabled' then
            if videoFinished == false and getModSetting('cutscenes', currentModDirectory) ~= 'In-Game Only' then
                return Function_Stop
            elseif stopCountdown == true then
                playCutscene()
                return Function_Stop
            end
        end
    end
    return Function_Continue
end

function playCutscene()
    setProperty('inCutscene', true)
    setVar('cutsceneMode', true) -- Exclusive variable from custom camera events, more info there.
    playAnim('boyfriend', 'pissed')
    runTimer('setUpCutscene', 0.1)
    runTimer('startCutscene', 0.7)
    runTimer('moveOutCamera', 2)
    runTimer('lightCan', 5)
    runTimer('cockGun', 6)
    runTimer('kickCan', 6.4)
    runTimer('kneeCan', 6.9)
    runTimer('fireGun', 7.1)
    runTimer('darnellLaugh', 7.9)
    runTimer('neneLaugh', 8.2)
    runTimer('endCutscene', 10)
end

function onUpdatePost(elapsed)
    if getProperty('inCutscene') == true then
        if getProperty('boyfriend.animation.name') == 'cockCutscene' then
            if getProperty('boyfriend.animation.curAnim.curFrame') == 3 then
                makeAnimatedLuaSprite('casing', 'phillyStreets/PicoBullet', getProperty('boyfriend.x') + 250, getProperty('boyfriend.y') + 100)
                addAnimationByPrefix('casing', 'pop', 'Pop0', 24, false)
                addAnimationByPrefix('casing', 'anim', 'Bullet0', 24, false)
                addLuaSprite('casing', true)
                playAnim('casing', 'pop')
            end
        end
        if getProperty('casing.animation.name') == 'pop' then
            if getProperty('casing.animation.curAnim.curFrame') == 40 then
                startRoll('casing') 
            end
        end

        if getProperty('sprayCanExplosion.anim.finished') then
            setProperty('sprayCanExplosion.visible', false)
        end
        -- This is how we control the animations' speed depending on the 'playbackRate' for Atlas Sprites.
        setProperty('sprayCanExplosion.anim.framerate', 24 * playbackRate)
    end
end

--[[
    This makes the bullet roll when the 'pop' animation is finished.
    The roll is randomized, so it won't always end up in the same position.
]]
function startRoll(spriteName)
    randomNum1 = getRandomFloat(3, 10)
    randomNum2 = getRandomFloat(1, 2)
    
    setProperty(spriteName..'.x', getProperty(spriteName..'.x') + getProperty(spriteName..'.frame.offset.x') - 1)
    setProperty(spriteName..'.y', getProperty(spriteName..'.y') + getProperty(spriteName..'.frame.offset.y') + 1)
    setProperty(spriteName..'.angle', 125.1)
    
    setProperty(spriteName..'.velocity.x', 20 * randomNum2)
    setProperty(spriteName..'.drag.x', randomNum1 * randomNum2)
    setProperty(spriteName..'.angularVelocity', 100)
    setProperty(spriteName..'.angularDrag', ((randomNum1 * randomNum2) / (20 * randomNum2)) * 100)

    playAnim(spriteName, 'anim')
end

local stageObjects = {
    'sky1',
    'sky2',
    'sky3',
    'skyline',
    'city',
    'constructionSite',
    'highwayLights',
    'highwayLightMap',
    'highway',
    'smog',
    'cars1',
    'cars2',
    'trafficLight',
    'trafficLightMap',
    'street'
}
function onTimerCompleted(tag, loops, loopsLeft)
    -- Places the camera in preparation for the cutscene.
    if tag == 'setUpCutscene' then
        triggerEvent('Set Camera Target', 'BF,250,30', '0')
    end
    -- The 'blackScreen' gets removed and the cutscene officially starts.
    if tag == 'startCutscene' then
        playMusic('darnellCanCutscene')
        runTimer('beatHit', 60 / 168, 0)
        startTween('removeBlackScreen', 'blackScreen', {alpha = 0}, 2, {startDelay = 0.3})
    end
    -- Moves the camera away to see the entire stage.
    if tag == 'moveOutCamera' then
        triggerEvent('Set Camera Target', 'Dad,150', '2.5,quadInOut')
        triggerEvent('Set Camera Zoom', '0.66', '2.5,quadInOut')
    end
    -- Darnell lights up a can. 
    if tag == 'lightCan' then
        playAnim('dad', 'lightCan', true)
        playSound('Darnell_Lighter')
    end
    -- Pico cocks his gun, ready to shoot.
    if tag == 'cockGun' then
        triggerEvent('Set Camera Target', 'Dad,230', '0.4,backOut')
        playAnim('boyfriend', 'cockCutscene')
        playSound('Gun_Prep')
    end
    -- Darnell kicks the can up.
    if tag == 'kickCan' then
        playAnim('dad', 'kickCan', true)
        playSound('Kick_Can_UP')
        playAnim('sprayCan', 'up')
        setProperty('sprayCan.visible', true)
    end
    -- Darnell hits the can towards Pico.
    if tag == 'kneeCan' then
        playAnim('dad', 'kneeCan', true)
        playSound('Kick_Can_FORWARD')
        playAnim('sprayCan', 'forward')
    end
    -- Pico shoots up the can and goes back to his 'idle' animation. 
    if tag == 'fireGun' then
        triggerEvent('Set Camera Target', 'Dad,150', '1,quadInOut')
        playAnim('boyfriend', 'shootCutscene')
        setProperty('boyfriend.specialAnim', true)
        local num = getRandomInt(1, 4)
        playSound('shot'..num)

        playAnim('sprayCanExplosion')
        setProperty('sprayCanExplosion.anim.curFrame', 26)
        setProperty('sprayCanExplosion.visible', true)
        setProperty('sprayCan.visible', false)
        runTimer('darkenStageTween', 1 / 24)
    end
    -- Darnell laughs.
    if tag == 'darnellLaugh' then
        playAnim('dad', 'laughCutscene', true)
        playSound('darnell_laugh', 0.6)
    end
    -- Nene spits and laughs.
    if tag == 'neneLaugh' then
        playAnim('gf', 'laughCutscene', true)
        playSound('nene_laugh', 0.6)
    end
    -- The camera focuses back on Pico as the cutscene ends.
    if tag == 'endCutscene' then
        stopCountdown = false
        cancelTimer('beatHit')
        startCountdown()
        triggerEvent('Set Camera Target', 'Dad,300', '2,sineInOut')
        triggerEvent('Set Camera Zoom', '0.77', '2,sineInOut')
        runTimer('resetCameraPosition', 2)
        setProperty('camHUD.visible', true)
    end
    -- This is to make the characters bop their head to the beat of the cutscene's music.
    if tag == 'beatHit' then
        if getProperty('dad.animation.finished') then
            if getProperty('dad.animation.curAnim.name') ~= 'lightCan' then
                characterDance('dad')
            end
        end
        if getProperty('gf.animation.finished') then
            characterDance('gf')
        end
    end
    -- Those are what makes the stage darken when Pico shoots.
    if tag == 'darkenStageTween' then
        for object = 1, #stageObjects do
            setProperty(stageObjects[object]..'.color', 0x111111)
        end
        runTimer('resetDarkenTween', 1 / 24)
    end
    if tag == 'resetDarkenTween' then
        for object = 1, #stageObjects do
            setProperty(stageObjects[object]..'.color', 0x222222)
            doTweenColor(stageObjects[object]..'LightenTween', stageObjects[object], '0xFFFFFF', 1.4, 'linear')
        end
    end
    -- This is how the camera resets its positioning when the song starts.
    if tag == 'resetCameraPosition' then
        setVar('cutsceneMode', false)
        triggerEvent('Set Camera Target', '', '')
        callMethod('moveCameraSection', {0})
    end
end