-- This is currently unused within the chart file of Blazin'.
function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Punch High Dodged' then    
        playAnim('boyfriend', 'punchHigh'..alternateBFpunch(), true)
        playAnim('dad', 'dodge', true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 2)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 1)
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Punch High Dodged' then
        playAnim('boyfriend', 'hitHigh', true)
        playAnim('dad', 'punchHigh'..alternateDadpunch(), true)
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