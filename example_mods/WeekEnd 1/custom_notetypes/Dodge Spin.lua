-- This is currently unused within the chart file of Blazin'.
function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Dodge Spin' then
        playAnim('boyfriend', 'dodge', true)
        playAnim('dad', 'punchHigh'..alternateDadpunch(), true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Dodge Spin' then
        playAnim('boyfriend', 'hitSpin', true)
        playAnim('dad', 'punchHigh'..alternateDadpunch(), true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
        cameraShake('game', 0.0025, 0.15)
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