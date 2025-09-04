local cutsceneFinished = false

function onEndSong()
    if isStoryMode == true and cutsceneFinished == false then
        if getModSetting('cutscenes', currentModDirectory) == 'Enabled' then
            makeLuaSprite('blackScreen')
            makeGraphic('blackScreen', 2000, 2500, '000000')
            screenCenter('blackScreen')
            setObjectCamera('blackScreen', 'camOther')
            addLuaSprite('blackScreen', true)

            makeVideoSprite('blazinCutscene', 'blazinCutscene', 0, 0, 'camOther', false)
            setProperty('blazinCutscene.antialiasing', true)
            return Function_Stop
        end
    end
    return Function_Continue
end

function onVideoFinished(tag) -- Exclusive to the Video Sprite script.
    if tag == 'blazinCutscene' then
        cutsceneFinished = true
        endSong()
    end
end