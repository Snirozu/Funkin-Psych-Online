local neneComboAnim = nil
local animOptions = {Disabled = 'none', Psych = 'psych', Vanilla = 'vanilla'}
function onCreate()
    --[[
        This is how the script recognizes which option you chose to use.
        However, if you decide to take Nene inside another mod,
        the 'neneComboAnim' variable will default to 'none' to avoid any bugs or issues.
        If that's the case, you can manually choose which option to pick by putting a string from 'animOptions'.
    ]]
    for optionName, optionStr in pairs(animOptions) do
        if getModSetting('neneComboAnim', currentModDirectory) == optionName then
            neneComboAnim = optionStr
        elseif getModSetting('neneComboAnim', currentModDirectory) == nil then
            neneComboAnim = 'none'
        end
    end
end

--[[
    If you ever want to use Abot Speaker on another character,
    just copy and paste this below, and change what's between '{}'.
    
    WARNING: The speaker can only get attached to BF, Dad, or GF type characters.
    Else, the offsets act as simple x and y positions.
    Go check the Abot Speaker's script for more information at line 217.
]]
function onCreatePost()
    addLuaScript('characters/abot-speaker')
    callScript('characters/abot-speaker', 'createSpeaker', {'nene', 0, 0}) -- {characterName, offsetX, offsetY}
end

local comboAnimActive = true
function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if neneComboAnim ~= 'none' and comboAnimActive == true then
        if neneComboAnim == 'vanilla' then
            if combo == 50 then
                playAnim('gf', 'combo50')
                setProperty('gf.specialAnim', true)
            end
            if combo == 200 then
                playAnim('gf', 'combo200')
                setProperty('gf.specialAnim', true)
            end
        end
        lastCombo = combo
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    if neneComboAnim ~= 'none' and comboAnimActive == true then
        if neneComboAnim == 'vanilla' then
            if lastCombo >= 70 then
                playAnim('gf', 'drop70')
                setProperty('gf.specialAnim', true)
            end
        end
        if neneComboAnim == 'psych' then
            if lastCombo > 5 then
                playAnim('gf', 'drop70')
                setProperty('gf.specialAnim', true)
            end
        end
        lastCombo = 0
    end
end

function noteMissPress(direction)
    if neneComboAnim ~= 'none' and comboAnimActive == true then
        if neneComboAnim == 'vanilla' then
            if lastCombo >= 70 then
                playAnim('gf', 'drop70')
                setProperty('gf.specialAnim', true)
            end
        end
        if neneComboAnim == 'psych' then
            if lastCombo > 5 then
                playAnim('gf', 'drop70')
                setProperty('gf.specialAnim', true)
            end
        end
        lastCombo = 0
    end
end

function onUpdatePost(elapsed)
    if songName ~= "Blazin'" then
        transitionAnim()
    end
end

--[[
    This function is what controls Nene's animations dependently of the player's health.
    When the player's health is low, Nene will smoothly go to her 'raiseKnife' anim.
    If the player gains enough health, Nene will go back to bopping her head.
]]
local animTrans = 0
local blinkDelay = 3
function transitionAnim()
    if animTrans == 0 then -- Nene noticed the player being low on health.
        if getHealth() <= 0.5 then
            animTrans = 1
        else
            animTrans = 0
        end
    elseif animTrans == 1 then -- Nene stops bopping her head and raises her knife.
        if getHealth() > 0.5 then
            animTrans = 0
        elseif getProperty('gf.animation.name') == 'danceLeft' then
            comboAnimActive = false
            setProperty('gf.specialAnim', true)
            if getProperty('gf.animation.finished') then
                animTrans = 2
                playAnim('gf', 'raiseKnife')
                setProperty('gf.specialAnim', true)
                changedBeat = curBeat
            end
        end
    elseif animTrans == 2 then -- Nene keeps raising her knife while randomly blinking on beat, or lowers her knife.
        if getHealth() > 0.5 then
            animTrans = 3
            playAnim('gf', 'lowerKnife')
            setProperty('gf.specialAnim', true)
        elseif getProperty('gf.animation.finished') then
            if getProperty('gf.animation.name') ~= 'idleKnife' or curBeat - changedBeat == blinkDelay then
                blinkDelay = getRandomInt(3, 7)
                changedBeat = curBeat
                playAnim('gf', 'idleKnife')
                setProperty('gf.specialAnim', true)
            else
                lastFrame = getProperty('gf.animation.numFrames')
                playAnim('gf', 'idleKnife', false, false, lastFrame)
                setProperty('gf.specialAnim', true)
            end
        end
    elseif animTrans == 3 then -- Nene goes back to bopping her head.
        if getProperty('gf.animation.finished') then
            animTrans = 0
            comboAnimActive = true
            setProperty('gf.danced', false)
            characterDance('gf')
        end   
    end
end