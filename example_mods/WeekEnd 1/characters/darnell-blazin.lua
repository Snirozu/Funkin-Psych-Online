local animToLoop = {'uppercut'}
function onUpdate(elapsed)
    --[[ 
        Makes the character play the '-loop' variation of their animation.
        The animation's name must be put into the 'animToLoop' variable,
        and their '-loop' variation must be present within the character's JSON file.
        WARNING: THIS IS FOR ATLAS CHARACTERS ONLY!!!
    ]]
    for name = 0, #animToLoop do
        character = getCharacterType('darnell-blazin')
        if getProperty(character..'.atlas.anim.finished') then
            if getProperty(character..'.atlas.anim.lastPlayedAnim') == animToLoop[name] then
                playAnim(character, animToLoop[name]..'-loop', true)
            end
        end
    end

    -- This is how we control the animations' speed depending on the 'playbackRate' for Atlas Sprites.
    setProperty(getCharacterType('darnell-blazin')..'.atlas.anim.framerate', 24 * playbackRate)
end

function getCharacterType(characterName)
    if boyfriendName == characterName then
        return 'boyfriend'
    elseif dadName == characterName then
        return 'dad'
    elseif gfName == characterName then
        return 'gf'
    end
end