function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Darnell Uppercut Prep' then
        playAnim('boyfriend', 'idle', true)
        playAnim('dad', 'uppercutPrep', true)
        setObjectOrder('boyfriendGroup', getObjectOrder('gfGroup') + 1)
        setObjectOrder('dadGroup', getObjectOrder('gfGroup') + 2)
    end
end