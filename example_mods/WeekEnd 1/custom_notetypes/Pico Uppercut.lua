function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Pico Uppercut' then
        if picoUppercutReady == true then
            playAnim('boyfriend', 'uppercut', true)
            playAnim('dad', 'uppercutHit', true)
            setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 2)
            setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 1)
            cameraShake('game', 0.005, 0.25)
        else
            playAnim('boyfriend', 'block', true)
            playAnim('dad', 'punchHigh'..alternateDadpunch(), true)
            setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
            setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
            cameraShake('game', 0.002, 0.1)
        end
        setOnLuas('picoUppercutReady', false) -- Makes the variables available to all the Lua scipts with those values.
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Pico Uppercut' then
        if picoUppercutReady == true then
            playAnim('boyfriend', 'uppercut', true)
            playAnim('dad', 'dodge', true)
            setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 2)
            setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 1)
        else
            playAnim('boyfriend', 'hitHigh', true)
            playAnim('dad', 'punchHigh'..alternateDadpunch(), true)
            setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
            setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
            cameraShake('game', 0.0025, 0.15)
        end
        setOnLuas('picoUppercutReady', false)
    end
end

-- This is to alternate the fists Darnell uses when punching Pico.
function alternateDadpunch()
    setOnLuas('isOneDad', not isOneDad)
    if isOneDad == true then
        return '1'
    else
        return '2'
    end
end