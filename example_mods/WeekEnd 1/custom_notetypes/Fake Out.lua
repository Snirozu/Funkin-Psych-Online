function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Fake Out' then
        playAnim('boyfriend', 'fakeout', true)
        playAnim('dad', 'cringe', true)
        setOnLuas('picoFakeOutHit', true) -- Makes the variables available to all the Lua scipts with those values.
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Fake Out' then
        playAnim('boyfriend', 'punchHigh'..alternateBFpunch(), true)
        playAnim('dad', 'hitHigh', true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 2)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 1)
        cameraShake('game', 0.0025, 0.15)
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