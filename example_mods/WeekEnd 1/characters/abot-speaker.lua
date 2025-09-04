local characterType = ''
local characterName = ''
local looksAtPlayer = true
local offsetData = {0, 0}
local propertyTracker = {
    {'x', nil},
    {'y', nil},
    {'color', nil},
    {'scrollFactor.x', nil},
    {'scrollFactor.y', nil},
    {'angle', nil},
    {'alpha', nil},
    {'antialiasing', nil},
    {'visible', nil}
}

--[[ 
    Self explanatory, creates the speaker based on if if's attached to a character or not,
    and the inputted offsets. Wait, why did I explain it still?
    Because it also sets up everything needed for the script to work, duh.
]]
function createSpeaker(attachedCharacter, offsetX, offsetY)
    characterName = attachedCharacter
    offsetData = {offsetX, offsetY}
    if getCharacterType(attachedCharacter) ~= nil then
        characterType = getCharacterType(attachedCharacter)
    end

    makeLuaSprite('AbotSpeakerBG', 'characters/abot/stereoBG')
    if characterType ~= '' then
        setObjectOrder('AbotSpeakerBG', getObjectOrder(characterType..'Group'))
    end
    addLuaSprite('AbotSpeakerBG')

    for bar = 1, 7 do
        makeAnimatedLuaSprite('AbotSpeakerVisualizer'..bar, 'characters/abot/aBotViz')
        addAnimationByPrefix('AbotSpeakerVisualizer'..bar, 'idle', 'viz'..bar, 24, false)
        if characterType ~= '' then
            setObjectOrder('AbotSpeakerVisualizer'..bar, getObjectOrder(characterType..'Group'))
        end
        addLuaSprite('AbotSpeakerVisualizer'..bar)
    end

    makeLuaSprite('AbotEyes')
    makeGraphic('AbotEyes', 140, 60)
    if characterType ~= '' then
        setObjectOrder('AbotEyes', getObjectOrder(characterType..'Group'))
    end
    addLuaSprite('AbotEyes')

    makeFlxAnimateSprite('AbotPupils')
    loadAnimateAtlas('AbotPupils', 'characters/abot/systemEyes')
    if characterType ~= '' then
        setObjectOrder('AbotPupils', getObjectOrder(characterType..'Group'))
    end
    addLuaSprite('AbotPupils')

    looksAtPlayer = getPropertyFromClass('states.PlayState', 'SONG.notes['..curSection..'].mustHitSection')
    if looksAtPlayer == false then
        setProperty('AbotPupils.anim.curFrame', 17)
        pauseAnim('AbotPupils')
    else
        setProperty('AbotPupils.anim.curFrame', 0)
        pauseAnim('AbotPupils')
    end
    
    makeFlxAnimateSprite('AbotSpeaker')
    loadAnimateAtlas('AbotSpeaker', 'characters/abot/abotSystem')
    if characterType ~= '' then
        setObjectOrder('AbotSpeaker', getObjectOrder(characterType..'Group'))
    end
    addLuaSprite('AbotSpeaker')

    for property = 1, 2 do
        if characterType ~= '' then
            propertyTracker[property][2] = getProperty(characterType..'.'..propertyTracker[property][1])
            setAbotSpeakerProperty(propertyTracker[property][1], propertyTracker[property][2])
        else
            propertyTracker[property][2] = getProperty('AbotSpeaker.'..propertyTracker[property][1])
            setProperty('AbotSpeaker.'..propertyTracker[property][1], offsetData[property])
        end
    end

    if characterName ~= '' then
        if _G[characterType..'Name'] ~= characterName then
            destroySpeaker()
        end
    end
end

-- Self explanatory again.
function destroySpeaker()
    runHaxeCode([[
        game.variables.get('AbotSpeaker').destroy();
        game.variables.remove('AbotSpeaker');
        game.variables.get('AbotPupils').destroy();
        game.variables.remove('AbotPupils');
    ]])
    removeLuaSprite('AbotSpeakerBG')
    for bar = 1, 7 do
        removeLuaSprite('AbotSpeakerVisualizer'..bar)
    end
    removeLuaSprite('AbotEyes')
end

-- This is to prevent the speaker from still appearing when the attached character's gone.
function onEvent(eventName, value1, value2, strumTime)
    if eventName == 'Change Character' then
        if getCharacterType(value2) == characterType and value2 ~= characterName then
            destroySpeaker()
        elseif characterName ~= '' then
            createSpeaker(characterName, offsetData[1], offsetData[2])
        end
    end
    if eventName == 'Set Camera Target' then
        for _, startStringBF in ipairs({'0', 'bf', 'boyfriend'}) do
            if stringStartsWith(string.lower(value1), startStringBF) then
                if looksAtPlayer == false then
                    playAnim('AbotPupils', '', true, false, 17)
                end
            end
        end
        for _, startStringDad in ipairs({'1', 'dad', 'opponent'}) do
            if stringStartsWith(string.lower(value1), startStringDad) then
                if looksAtPlayer == true then
                    playAnim('AbotPupils', '', true, false, 0)
                end
            end
        end
    end
end

function onCountdownTick(swagCounter)
    --[[
        Makes the speaker bop at the same time as the character.
        Ex: If the character only bops their head when the beat is even,
        then the speaker will also do the same.
        This will only work during the countdown.
    ]]
    if characterType == 'gf' then
        characterSpeed = getProperty('gfSpeed')
    else
        characterSpeed = 1
    end
    if characterType ~= '' then
        danceEveryNumBeats = getProperty(characterType..'.danceEveryNumBeats')
    else
        danceEveryNumBeats = 1
    end
    if swagCounter % (danceEveryNumBeats * characterSpeed) == 0 then
        playAnim('AbotSpeaker', '', true, false, 1)
        for bar = 1, 7 do
            playAnim('AbotSpeakerVisualizer'..bar, 'idle', true)
        end
    end
end

function onBeatHit()
    --[[
        Same here, but it works for the entirety of the song.
    ]]
    if characterType == 'gf' then
        characterSpeed = getProperty('gfSpeed')
    else
        characterSpeed = 1
    end
    if characterType ~= '' then
        danceEveryNumBeats = getProperty(characterType..'.danceEveryNumBeats')
    else
        danceEveryNumBeats = 1
    end
    if curBeat % (danceEveryNumBeats * characterSpeed) == 0 then
        playAnim('AbotSpeaker', '', true, false, 1)
        for bar = 1, 7 do
            playAnim('AbotSpeakerVisualizer'..bar, 'idle', true)
        end
    end
end

function onMoveCamera(character)
    -- Abot will look to the right (towards the player).
    if character == 'boyfriend' then
        if looksAtPlayer == false then
            playAnim('AbotPupils', '', true, false, 17)
        end
    end
    -- Abot will look to the left (towards the opponent).
    if character == 'dad' then
        if looksAtPlayer == true then
            playAnim('AbotPupils', '', true, false, 0)
        end
    end
end

function onUpdatePost(elapsed)
    for property = 1, #propertyTracker do
        if characterType ~= '' then
            if propertyTracker[property][2] ~= getProperty(characterType..'.'..propertyTracker[property][1]) then
                propertyTracker[property][2] = getProperty(characterType..'.'..propertyTracker[property][1])
                setAbotSpeakerProperty(propertyTracker[property][1], propertyTracker[property][2])
            end
        else
            if propertyTracker[property][2] ~= getProperty('AbotSpeaker.'..propertyTracker[property][1]) then
                propertyTracker[property][2] = getProperty('AbotSpeaker.'..propertyTracker[property][1])
                setAbotSpeakerProperty(propertyTracker[property][1], propertyTracker[property][2])
            end
        end
    end
    --[[
        These make it so the animations stop when they're supposed to be,
        instead of looping endlessly.
    ]] 
    if getProperty('AbotSpeaker.anim.curFrame') >= 15 then
        pauseAnim('AbotSpeaker')
    end
    if looksAtPlayer == true then
        if getProperty('AbotPupils.anim.curFrame') >= 17 then
            looksAtPlayer = false
            pauseAnim('AbotPupils')
        end
    end
    if looksAtPlayer == false then
        if getProperty('AbotPupils.anim.curFrame') >= 31 then
            looksAtPlayer = true
            pauseAnim('AbotPupils')
        end
    end
    -- This is how we control the animations' speed depending on the 'playbackRate' for Atlas Sprites.
    setProperty('AbotSpeaker.anim.framerate', 24 * playbackRate)
    setProperty('AbotPupils.anim.framerate', 24 * playbackRate)
end

--[[
    This function is useful if you change any of the properties of the attached character, 
    or the speaker itself if it's not attached to any character, instead of changing it manually. 
    This only works for the properties present in 'propertyTracker', though.

    WARNING: Do not use this function if you want to change Abot Speaker's properties,
    as it is only meant to be used inside this script.
    Instead, use the 'setProperty' function as usual.
    Examples:
    setProperty('boyfriend.alpha', 0.5)     --> If attached to the BF character type.
    setProperty('dad.alpha', 0.5)           --> If attached to the Dad character type.
    setProperty('gf.alpha', 0.5)            --> If attached to the GF character type.
    setProperty('AbotSpeaker.alpha', 0.5)   --> If not attached to any character type.

    'doTween' functions also work the same way. 
]]
function setAbotSpeakerProperty(property, value)
    if property == 'x' then
        if characterType ~= '' then
            value = value + offsetData[1]
            setProperty('AbotSpeaker.'..property, value - 100)
        end
        for bar = 1, 7 do
            setProperty('AbotSpeakerVisualizer'..bar..'.'..property, getProperty('AbotSpeaker.'..property) + 200 + visualizerOffsetX(bar))
        end
        setProperty('AbotSpeakerBG.'..property, getProperty('AbotSpeaker.'..property) + 165)
        setProperty('AbotEyes.'..property, getProperty('AbotSpeaker.'..property) + 30)
        setProperty('AbotPupils.'..property, getProperty('AbotSpeaker.'..property) - 507)
    elseif property == 'y' then
        if characterType ~= '' then
            value = value + offsetData[2]
            setProperty('AbotSpeaker.'..property, value + 316)
        end
        for bar = 1, 7 do
            setProperty('AbotSpeakerVisualizer'..bar..'.'..property, getProperty('AbotSpeaker.'..property) + 84 + visualizerOffsetY(bar))
        end
        setProperty('AbotSpeakerBG.'..property, getProperty('AbotSpeaker.'..property) + 30)
        setProperty('AbotEyes.'..property, getProperty('AbotSpeaker.'..property) + 230)
        setProperty('AbotPupils.'..property, getProperty('AbotSpeaker.'..property) - 492)
    else
        if characterType ~= '' then
            setProperty('AbotSpeaker.'..property, value)
        end
        for bar = 1, 7 do
            setProperty('AbotSpeakerVisualizer'..bar..'.'..property, value)
        end
        setProperty('AbotSpeakerBG.'..property, value)
        setProperty('AbotEyes.'..property, value)
        setProperty('AbotPupils.'..property, value)
    end
end

--[[ Old version of the function above.
function updateSpeaker(property)
    if property == 'x' then
        setProperty('AbotSpeaker.'..property, offset.x - 100)
        for bar = 1, 7 do
            setProperty('AbotSpeakerVisualizer'..bar..'.'..property, offset.x + 100 + visualizerOffsetX(bar))
        end
        setProperty('AbotSpeakerBG.'..property, offset.x + 65)
        setProperty('AbotEyes.'..property, offset.x - 60)
        setProperty('AbotPupils.'..property, offset.x - 607)
    elseif property == 'y' then
        setProperty('AbotSpeaker.'..property, offset.y + 316)
        for bar = 1, 7 do
            setProperty('AbotSpeakerVisualizer'..bar..'.'..property, offset.y + 400 + visualizerOffsetY(bar))
        end
        setProperty('AbotSpeakerBG.'..property, offset.y + 347)
        setProperty('AbotEyes.'..property, offset.y + 567)
        setProperty('AbotPupils.'..property, offset.y - 176)
    elseif characterType ~= '' then
        setProperty('AbotSpeaker.'..property, getProperty(characterType..'.'..property))
        for bar = 1, 7 do
            setProperty('AbotSpeakerVisualizer'..bar..'.'..property, getProperty(characterType..'.'..property))
        end
        setProperty('AbotSpeakerBG.'..property, getProperty(characterType..'.'..property))
        setProperty('AbotEyes.'..property, getProperty(characterType..'.'..property))
        setProperty('AbotPupils.'..property, getProperty(characterType..'.'..property))
    end
end
]]

--[[
    This handles the offsets for each visualizer bar.
    Again, it is to make things automatic instead of doing everything manually.
]]
local visualizerPosX = {0, 59, 56, 66, 54, 52, 51}
local visualizerPosY = {0, -8, -3.5, -0.4, 0.5, 4.7, 7}
function visualizerOffsetX(bar)
    local i = 1
    local offsetX = 0
    while i <= bar do
        offsetX = offsetX + visualizerPosX[i]
        i = i + 1
    end
    return offsetX
end

function visualizerOffsetY(bar)
    local i = 1
    local offsetY = 0
    while i <= bar do
        offsetY = offsetY + visualizerPosY[i]
        i = i + 1
    end
    return offsetY
end

function pauseAnim(object)
    runHaxeCode("game.getLuaObject('"..object.."').anim.pause();")
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