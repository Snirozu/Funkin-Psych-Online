function onCreate()
    precacheSound('Pico_Bonk')
    for num = 1, 4 do
        precacheSound('shot'..num)
    end
    for note = 0, getProperty('unspawnNotes.length') - 1 do
        if getPropertyFromGroup('unspawnNotes', note, 'noteType') == 'Fire Gun' then
            -- This is how much the player loses health when they miss this note.
            setPropertyFromGroup('unspawnNotes', note, 'missHealth', 0.5)
        end
    end
end

function goodNoteHitPre(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Fire Gun' then
        -- Since the player didn't hit the last note, then this one will count as a miss too.
        if gunCocked ~= true then
            setPropertyFromGroup('notes', membersIndex, 'hitCausesMiss', true)
            setPropertyFromGroup('notes', membersIndex, 'noteSplashData.disabled', true)
        end
    end
end

function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Fire Gun' then
        if gunCocked == true then
            playAnim('boyfriend', 'shoot')
            setProperty('boyfriend.specialAnim', true)
            local num = getRandomInt(1, 4)
            playSound('shot'..num)
            
            playAnim('sprayCan')
            setProperty('sprayCan.anim.curFrame', 26)
            setOnLuas('canEndFrame', 42) -- Makes the variables available to all the Lua scipts with those values.
            setOnLuas('gunCocked', false)
            runTimer('darkenStageTween', 1 / 24)
        end
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Fire Gun' then    
        playAnim('boyfriend', 'shootMISS')
        setProperty('boyfriend.specialAnim', true)
        playSound('Pico_Bonk')
        setOnLuas('gunCocked', false)
        
        if getHealth() <= 0 then
            --[[
                Since any versions below 1.0 doesn't support Atlas characters for Game Over,
                I'm not gonna change it, and do it by myself elsewhere.
                    
                setPropertyFromClass('substates.GameOverSubstate', 'characterName', 'pico-player-dead-explode')
            ]]
            setPropertyFromClass('substates.GameOverSubstate', 'deathSoundName', 'fnf_loss_sfx-pico-explode')
            blackenStage()
        end
    end
end

function onUpdate(elapsed)
    if getProperty('boyfriend.animation.name') == 'shootMISS' then
        if getProperty('boyfriend.animation.finished') == true then
            runTimer('flickeringTween1', 1 / 30, 30)
        end
    end
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
    'street',
    'sprayCans'
}
function blackenStage()
    setProperty('dad.color', 0x000000)
    setProperty('gf.color', 0x000000)
    for object = 1, #stageObjects do
        setProperty(stageObjects[object]..'.color', 0x000000)
    end
    for num = 1, casingNum do
        setProperty('casing'..num..'.color', 0x000000)
    end
    runTimer('resetBlacken', 1)
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'darkenStageTween' then
        for object = 1, #stageObjects do
            setProperty(stageObjects[object]..'.color', 0x111111)
        end
        for num = 1, casingNum do
            setProperty('casing'..num..'.color', 0x111111)
        end
        runTimer('resetDarkenTween', 1 / 24)
    end
    if tag == 'resetDarkenTween' then
        for object = 1, #stageObjects do
            setProperty(stageObjects[object]..'.color', 0x222222)
            doTweenColor(stageObjects[object]..'LightenTween', stageObjects[object], '0xFFFFFF', 1.4, 'linear')
        end
        for num = 1, casingNum do
            setProperty('casing'..num..'.color', 0x222222)
            doTweenColor('casing'..num..'LightenTween', 'casing'..num, '0xFFFFFF', 1.4, 'linear')
        end
    end
    if tag == 'resetBlacken' then
        setProperty('dad.color', 0xFFFFFF)
        setProperty('gf.color', 0xFFFFFF)
        for object = 1, #stageObjects do
            setProperty(stageObjects[object]..'.color', 0xFFFFFF)
        end
        for num = 1, casingNum do
            setProperty('casing'..num..'.color', 0xFFFFFF)
        end
    end
    if tag == 'flickeringTween1' then
        local visible = not getProperty('boyfriend.visible')
        setProperty('boyfriend.visible', visible)
        if loopsLeft == 0 then
            runTimer('flickeringTween2', 1 / 60, 30)
        end
    end
    if tag == 'flickeringTween2' then
        local visible = not getProperty('boyfriend.visible')
        setProperty('boyfriend.visible', visible)
        if loopsLeft == 0 then
            setProperty('boyfriend.visible', true)
        end
    end
end