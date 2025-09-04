function onCreate()
    precacheSound('Kick_Can_FORWARD')
end

function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Knee Can' then
        playAnim('dad', 'kneeCan')
        setProperty('dad.specialAnim', true)
        playSound('Kick_Can_FORWARD')
    end
end