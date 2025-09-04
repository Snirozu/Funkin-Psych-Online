function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Taunt' then
        if picoFakeOutHit == true then
            playAnim('boyfriend', 'taunt', true)
            playAnim('dad', 'pissed', true)
        else
            playAnim('boyfriend', 'punchHigh'..alternateBFpunch(), true)
            playAnim('dad', 'hitHigh', true)
            setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 2)
            setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 1)
            cameraShake('game', 0.0025, 0.15)
        end
        setOnLuas('picoFakeOutHit', false)
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Taunt' then
        if picoFakeOutHit == true then
            playAnim('boyfriend', 'taunt', true)
            playAnim('dad', 'pissed', true)
        else
            playAnim('boyfriend', 'hitHigh', true)
            playAnim('dad', 'punchHigh'..alternateDadpunch(), true)
            setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
            setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
            cameraShake('game', 0.0025, 0.15)
        end
        setOnLuas('picoFakeOutHit', false)
    end
end

-- This is to alternate the fists Pico uses when punching Darnell.
function alternateBFpunch()
    setOnLuas('isOneBF', not isOneBF)
    if isOneBF == true then
        return '1'
    else
        return '2'
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