function onCreate()
    -- Needed variables and values to make the custom zoom behaviour work
    defaultStageZoom = getProperty('defaultCamZoom')
    camZoomingDecay = getProperty('camZoomingDecay')
    setProperty('camZoomingMult', 0)
    setProperty('camZoomingDecay', 0)

    --[[
        IN-GAME CUTSCENES EXCLUSIVE:
        Set it to true in other scripts if you want to use the event for a cutscene,
        making 'duration' work in seconds instead of steps (since there's no BPM in cutscenes).
        WARNING: Remember to set it back to false once the cutscene has ended.
    ]]
    if getVar('cutsceneMode') == nil then
        setVar('cutsceneMode', false)
    end
end

function onEvent(eventName, value1, value2, strumTime)
    if eventName == 'Set Camera Zoom' then
        cancelTween('camZoom')
        
        -- Sets up the data for the zoom and removes any empty space in the string.
        local zoomData = stringSplit(value1, ',')
        for i = 1, #zoomData do
            zoomData[i] = stringTrim(zoomData[i])
        end

        if zoomData[2] == 'stage' then
            -- The 'targetZoom' is the value multiplied by the stage's original zoom
            targetZoom = tonumber(zoomData[1]) * defaultStageZoom
        else
            -- The 'targetZoom' is just the value
            targetZoom = tonumber(zoomData[1])
        end
        
        -- Sets up the data for the tween and removes any empty space in the string.
        local tweenData = stringSplit(value2, ',')
        for i = 1, #tweenData do
            tweenData[i] = stringTrim(tweenData[i])
        end

        if tweenData[1] <= '0' then
            -- Zooms instantly to the inputted value
            setProperty('defaultCamZoom', targetZoom)
        else
            -- Zooms to the inputted value by using a tween
            local duration = 0
            if getVar('cutsceneMode') == true then
                -- Duration is in seconds
                duration = tonumber(tweenData[1])
            else
                -- Duration is in steps (related to BPM)
                duration = stepCrochet * tonumber(tweenData[1]) / 1000
            end

            if tweenData[2] == nil then
                tweenData[2] = 'linear'
            end
            if version >= '1.0' then
                tweenNameAdd = 'tween_' -- Shadow Mario fucked it up.
            else
                tweenNameAdd = ''
            end
            startTween(tweenNameAdd..'camZoom', 'this', {defaultCamZoom = targetZoom}, duration, {ease = tweenData[2]})
        end
    end

    -- Compability for this event with the custom zoom behaviour
    if eventName == 'Add Camera Zoom' then
        if cameraZoomOnBeat == true and getProperty('camGame.zoom') < 1.35 then
            zoomAdd = tonumber(value1)
            if zoomAdd == nil then
                zoomAdd = 0.015
            end
            zoomMultiplier = zoomMultiplier + zoomAdd
        end
    end
end

--[[
    Everything from down here is how this event handles the custom zoom behaviour.
    This was needed to make sure the camera doesn't spasm
    when the zoom changes over time while bopping.
]]

zoomMultiplier = 1
-- Those 2 variables below are used and changed by the 'Set Camera Bop' event
cameraZoomRate = 4
cameraZoomMult = 1
function onBeatHit()
    if cameraZoomRate > 0 and cameraZoomOnBeat == true then
        if getProperty('camGame.zoom') < 1.35 and curBeat % cameraZoomRate == 0 then
            zoomMultiplier = zoomMultiplier + 0.015 * cameraZoomMult
            setProperty('camHUD.zoom', getProperty('camHUD.zoom') + 0.03 * cameraZoomMult)
        end
    end
end

function onUpdatePost(elapsed)
    if (getProperty('startedCountdown') == true and getProperty('endingSong') == false) or getVar('cutsceneMode') == true then
        if cameraZoomRate > 0 then
            zoomMultiplier = math.lerp(1, zoomMultiplier, math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate))
            setProperty('camGame.zoom', getProperty('defaultCamZoom') * zoomMultiplier)
            setProperty('camHUD.zoom', math.lerp(1, getProperty('camHUD.zoom'), math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate)))
        end
    end
end

function math.lerp(a, b, ratio)
    return a + ratio * (b - a)
end