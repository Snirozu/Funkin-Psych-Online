function onCreate()
    precacheSound('Darnell_Lighter')
end

function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Light Can' then
        playAnim('dad', 'lightCan')
        setProperty('dad.specialAnim', true)
        playSound('Darnell_Lighter')

        -- Abot will look to the left (towards the opponent).
        playAnim('AbotPupils', '', true, false, 0)
    end
end