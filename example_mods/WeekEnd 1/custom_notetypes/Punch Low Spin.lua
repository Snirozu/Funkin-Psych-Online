function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Punch Low Spin' then    
        playAnim('boyfriend', 'punchLow'..alternateBFpunch(), true)
        playAnim('dad', 'hitSpin', true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 2)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 1)
        cameraShake('game', 0.0025, 0.15)
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Punch Low Spin' then
        playAnim('boyfriend', 'hitSpin', true)
        playAnim('dad', 'punchLow'..alternateDadpunch(), true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
        cameraShake('game', 0.0025, 0.15)
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