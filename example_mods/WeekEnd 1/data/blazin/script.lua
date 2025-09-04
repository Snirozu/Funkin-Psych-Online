function onCreatePost()
    --[[
        This is to force middlescroll and hide the opponents strums/notes
        without tempering with the player's save data.
    ]]
    for noteData = 0, getProperty('playerStrums.length') - 1 do
        setPropertyFromGroup('playerStrums', noteData, 'x', -278 + ((160 * 0.7) * noteData) + 50 + (screenWidth / 2))
    end
    for noteData = 0, getProperty('opponentStrums.length') - 1 do
        setPropertyFromGroup('opponentStrums', noteData, 'visible', false)
    end
    for noteData = 0, getProperty('unspawnNotes.length') - 1 do
        if getPropertyFromGroup('unspawnNotes', noteData, 'mustPress') == false then
            setPropertyFromGroup('unspawnNotes', noteData, 'visible', false)
        end
    end

    --[[
        This is to move aside the 'rating' and 'numScore' sprites.
        Unfortunately, we have to change the save data in this case to make it easier for us.
    ]]
    ogOffsets = getPropertyFromClass('backend.ClientPrefs', 'data.comboOffset')
    setPropertyFromClass('backend.ClientPrefs', 'data.comboOffset', {530, 50, 530, 50})

    --[[
        This is to set up some things for the song.
        'skipDance' makes it so that the game doesn't force the characters to play their 'idle' animation on beat.
        'isOne' variables are needed for the 'alternateBFPunch' and 'alternateDadPunch' functions also present inside the notetypes scripts.
    ]]
    setProperty('boyfriend.skipDance', true)
    setProperty('dad.skipDance', true)
    setOnLuas('isOneBF', false)
    setOnLuas('isOneDad', false)
end

function onDestroy()
    -- This is where we bring back the original save data once the script isn't loaded anymore.
    setPropertyFromClass('backend.ClientPrefs', 'data.comboOffset', ogOffsets)
end

function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    --[[
        SPECIAL EVENT: If the player hit the note poorly at a low health (with 30% chance), 
        Darnell will prepare his uppercut.
    ]]
    if darnellUppercutReady == true then
        darnellUppercutReady = false
    end
    local curRating = getPropertyFromGroup('notes', membersIndex, 'rating')
    if curRating == 'bad' or curRating == 'shit' then
        if getHealth() <= 0.6 and getRandomBool(30) == true then
            playAnim('boyfriend', 'punchHigh'..alternateBFpunch(), true)
            playAnim('dad', 'uppercutPrep', true)
            setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 2)
            setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 1)
            darnellUppercutReady = true
        end
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    --[[
        SPECIAL EVENT: If Darnell has prepared his uppercut and the player missed a note, 
        then Pico gets hit by Darnell's uppercut. Otherwise, things go back to normal.
    ]]
    if darnellUppercutReady == true then
        playAnim('boyfriend', 'uppercutHit', true)
        playAnim('dad', 'uppercut', true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
        cameraShake('game', 0.005, 0.25)
        darnellUppercutReady = false
    end

    if getHealth() <= 0.05 then
        playAnim('boyfriend', 'hitLow', true)
        playAnim('dad', 'punchLow'..alternateDadpunch(), true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
        cameraShake('game', 0.0025, 0.15)
    end
end

function noteMissPress(direction)
    if getHealth() <= 0.05 then
        playAnim('boyfriend', 'hitLow', true)
        playAnim('dad', 'punchLow'..alternateDadpunch(), true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
        cameraShake('game', 0.0025, 0.15)
    else
        playAnim('boyfriend', 'punchHigh'..alternateBFpunch(), true)
        if getRandomBool(50) == true then
            playAnim('dad', 'dodge', true)
        else
            playAnim('dad', 'block', true)
            cameraShake('game', 0.002, 0.1)
        end
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 2)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 1)
    end
end

-- This is to alternate the fists Pico uses when punching Darnell.
function alternateBFpunch()
    isOneBF = not isOneBF
    if isOneBF == true then
        return '1'
    else
        return '2'
    end
end

-- This is to alternate the fists Darnell uses when punching Pico.
function alternateDadpunch()
    isOneDad = not isOneDad
    if isOneDad == true then
        return '1'
    else
        return '2'
    end
end