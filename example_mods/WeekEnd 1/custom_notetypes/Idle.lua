function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Idle' then
        playAnim('boyfriend', 'idle', true)
        playAnim('dad', 'idle', true)
    end
end