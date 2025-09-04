function onCreate()
    -- Sets up the haxe commands needed for the event to work.
    runHaxeCode([[
        function enableFollowPoint() FlxG.camera.target = game.camFollow;
        function disableFollowPoint() FlxG.camera.target = null;
        function snapCameraToTarget() FlxG.camera.snapToTarget();
    ]])

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
    if eventName == 'Set Camera Target' then
        if value1 == '' then
            -- Resets the camera's behaviour, making it lose its focus on the target
            setProperty('isCameraOnForcedPos', false)
            cancelTween('moveCamera')
            runHaxeFunction('enableFollowPoint')
        else
            -- This will force the camera to lock on target, despite 'mustHitSection'
            setProperty('isCameraOnForcedPos', true)
            cancelTween('moveCamera')

            -- Sets up the data for the target and removes any empty space in the string.
            local targetData = stringSplit(value1, ',')
            for i = 1, #targetData do
                targetData[i] = stringTrim(targetData[i])
            end
            
            -- Determines the target by the chosen character and/or offsets
            if targetData[1] == '0' or string.lower(targetData[1]) == 'bf' or string.lower(targetData[1]) == 'boyfriend' then
                targetX = getMidpointX('boyfriend') - getProperty('boyfriend.cameraPosition[0]') + getProperty('boyfriendCameraOffset[0]') - 100
                targetY = getMidpointY('boyfriend') + getProperty('boyfriend.cameraPosition[1]') + getProperty('boyfriendCameraOffset[1]') - 100
            elseif targetData[1] == '1' or string.lower(targetData[1]) == 'dad' or string.lower(targetData[1]) == 'opponent' then
                targetX = getMidpointX('dad') + getProperty('dad.cameraPosition[0]') + getProperty('opponentCameraOffset[0]') + 150
                targetY = getMidpointY('dad') + getProperty('dad.cameraPosition[1]') + getProperty('opponentCameraOffset[1]') - 100
            elseif targetData[1] == '2' or string.lower(targetData[1]) == 'gf' or string.lower(targetData[1]) == 'girlfriend' then
                targetX = getMidpointX('gf') + getProperty('gf.cameraPosition[0]') + getProperty('girlfriendCameraOffset[0]')
                targetY = getMidpointY('gf') + getProperty('gf.cameraPosition[1]') + getProperty('girlfriendCameraOffset[1]')
            else
                targetX = 0
                targetY = 0
            end
            if targetData[2] ~= nil then
                targetX = targetX + tonumber(targetData[2])
                if targetData[3] ~= nil then
                    targetY = targetY + tonumber(targetData[3])
                end
            end

            if value2 == '' then
                -- Simply moves the camera to target like it does usually
                runHaxeFunction('enableFollowPoint')
                setProperty('camFollow.x', targetX)
                setProperty('camFollow.y', targetY)
            else
                -- Sets up the data for the tween and removes any empty space in the string.
                local tweenData = stringSplit(value2, ',')
                for i = 1, #tweenData do
                    tweenData[i] = stringTrim(tweenData[i])
                end

                if tweenData[1] == '0' then
                    -- Instantly places the camera to target
                    runHaxeFunction('enableFollowPoint')
                    setProperty('camFollow.x', targetX)
                    setProperty('camFollow.y', targetY)
                    runHaxeFunction('snapCameraToTarget')
                else
                    -- Moves the camera to target by using a tween
                    runHaxeFunction('disableFollowPoint')
                    setProperty('camFollow.x', targetX - screenWidth / 2)
                    setProperty('camFollow.y', targetY - screenHeight / 2)

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
                    startTween(tweenNameAdd..'moveCamera', 'camGame.scroll', {x = getProperty('camFollow.x'), y = getProperty('camFollow.y')}, duration, {ease = tweenData[2]})
                end
            end
        end
    end   
end