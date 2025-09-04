local cutsceneFinished = false

function onEndSong()
    if isStoryMode == true and cutsceneFinished == false then
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
            setProperty('blackScreen.visible', false)

            setProperty('camHUD.visible', false)
            makeVideoSprite('2hotCutscene', '2hotCutscene', 0, 0, 'camOther', false)
            setProperty('2hotCutscene.antialiasing', true)
            playCutscene()
            return Function_Stop
        end
    end
    return Function_Continue
end

function onVideoFinished(tag) -- Exclusive to the Video Sprite script.
    if tag == '2hotCutscene' then
        cutsceneFinished = true
        endSong()
    end
end

function playCutscene()
    setProperty('2hotCutscene.visible', false)
    setProperty('inCutscene', true)
    setVar('cutsceneMode', true) -- Exclusive variable from custom camera events, more info there.
    setProperty('boyfriend.stunned', true)
    setProperty('dad.stunned', true)
    setProperty('gf.stunned', true)
    runTimer('beatHit', 60 / 168, 0)
    runTimer('setUpCutscene', 1)
    runTimer('picoPissed', 3)
    runTimer('darnellPissed', 3.5)
    runTimer('showVideo', 6)
end

local curLoop = 0 -- Used to make Pico and Darnell smoothly go to their 'pissed' animation without cutting off another animation. 
function onTimerCompleted(tag, loops, loopsLeft)
    -- This is to make the characters bop their head to the beat of the cutscene's music.
    if tag == 'beatHit' then
        curLoop = curLoop + 1
        if curLoop <= 7 and getProperty('boyfriend.animation.finished') then
            characterDance('boyfriend')
        end
        if curLoop <= 10 and getProperty('dad.animation.finished') then
            characterDance('dad')
        end
        if getProperty('gf.animation.finished') then
            characterDance('gf')
        end
    end
    -- Moves the camera and zooms it out in preparation for the cutscene.
    if tag == 'setUpCutscene' then
        triggerEvent('Set Camera Target', 'None,1539,833.5', '2,quadInOut')
        triggerEvent('Set Camera Zoom', '0.69', '2,quadInOut')
    end
    -- Pico gets pissed off.
    if tag == 'picoPissed' then
        playAnim('boyfriend', 'pissed', true)
    end
    -- Darnell gets pissed off.
    if tag == 'darnellPissed' then
        playAnim('dad', 'pissed', true)
    end
    -- Makes the video show up while the 'blackScreen' gets added behind.
    if tag == 'showVideo' then
        setProperty('2hotCutscene.visible', true)
        setProperty('blackScreen.visible', true)
    end
end