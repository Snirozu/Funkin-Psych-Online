function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Darnell Uppercut' then
        playAnim('boyfriend', 'uppercutHit', true)
        playAnim('dad', 'uppercut', true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
        cameraShake('game', 0.005, 0.25)
    end
end