function onCreatePost()
    --[[ 
        Needed if you only use this event during a song,
        as the 'Set Camera Zoom' event normally is the one to set up all this.
    ]]
    if not isRunning('custom_events/Set Camera Zoom') then
        camZoomingDecay = getProperty('camZoomingDecay')
        setProperty('camZoomingMult', 0)
        setProperty('camZoomingDecay', 0)

        zoomMultiplier = 1
        cameraZoomRate = 4
        cameraZoomMult = 1
    end
end

function onEvent(eventName, value1, value2, strumTime)
    if eventName == 'Set Camera Bop' then
        -- How many beats seperate the camera bops
        if value1 == '' then
            rate = 4
        else
            rate = tonumber(value1)
        end
        -- How intense the camera bop will be (basically a multiplier to be simple)
        if value2 == '' then
            intensity = 1
        else
            intensity = tonumber(value2)
        end
        setOnLuas('cameraZoomRate', rate)
        setOnLuas('cameraZoomMult', intensity)
    end

    -- Compability for this event with the custom zoom behaviour
    if not isRunning('custom_events/Set Camera Zoom') then
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
end

--[[
    Everything from down here is how this event handles the custom zoom behaviour.
    This below will only be active if you only use this event, 
    otherwise the 'Set Camera Zoom' event will handle everything.
]]

function onBeatHit()
    if not isRunning('custom_events/Set Camera Zoom') then
        if cameraZoomRate > 0 and cameraZoomOnBeat == true then
            if getProperty('camGame.zoom') < 1.35 and curBeat % cameraZoomRate == 0 then
                zoomMultiplier = zoomMultiplier + 0.015 * cameraZoomMult
                setProperty('camHUD.zoom', getProperty('camHUD.zoom') + 0.03 * cameraZoomMult)
            end
        end
    end
end

function onUpdatePost(elapsed)
    if not isRunning('custom_events/Set Camera Zoom') then
        if getProperty('startedCountdown') == true and getProperty('endingSong') == false then 
            if cameraZoomRate > 0 then
                zoomMultiplier = math.lerp(1, zoomMultiplier, math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate))
                setProperty('camGame.zoom', getProperty('defaultCamZoom') * zoomMultiplier)
                setProperty('camHUD.zoom', math.lerp(1, getProperty('camHUD.zoom'), math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate)))
            end
        end
    end
end

function math.lerp(a, b, ratio)
    return a + ratio * (b - a)
end