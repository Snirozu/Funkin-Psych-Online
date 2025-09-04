function onCreate()
    addHaxeLibrary('LuaUtils', 'psychlua')
    if lowQuality == false then
        for i = 0, 2 do
            makeLuaSprite('sky'..(i + 1), 'phillyStreets/phillySkybox', -650, -375)
            scaleObject('sky'..(i + 1), 0.65, 0.65, false)
            setScrollFactor('sky'..(i + 1), 0.1, 0.1)
            addLuaSprite('sky'..(i + 1))
            setProperty('sky'..(i + 1)..'.x', getProperty('sky'..(i + 1)..'.x') + (getProperty('sky'..(i + 1)..'.width') * 0.65) * i)
        end
    else
        for i = 0, 1 do
            makeLuaSprite('sky'..(i + 1), 'phillyStreets/phillySkybox', -450, -375)
            scaleObject('sky'..(i + 1), 0.65, 0.65, false)
            setScrollFactor('sky'..(i + 1), 0.1, 0.1)
            addLuaSprite('sky'..(i + 1))
            setProperty('sky'..(i + 1)..'.x', getProperty('sky'..(i + 1)..'.x') + (getProperty('sky'..(i + 1)..'.width') * 0.65) * i)
        end
    end

    makeLuaSprite('skyline', 'phillyStreets/phillySkyline', -545, -273)
    setScrollFactor('skyline', 0.2, 0.2)
    addLuaSprite('skyline')

    makeLuaSprite('city', 'phillyStreets/phillyForegroundCity', 625, 94)
    setScrollFactor('city', 0.3, 0.3)
    addLuaSprite('city')
    
    if lowQuality == false then
        makeLuaSprite('constructionSite', 'phillyStreets/phillyConstruction', 1800, 364)
        setScrollFactor('constructionSite', 0.7, 1)
        addLuaSprite('constructionSite')

        makeLuaSprite('highwayLights', 'phillyStreets/phillyHighwayLights', 284, 305)
        addLuaSprite('highwayLights')

        makeLuaSprite('highwayLightMap', 'phillyStreets/phillyHighwayLights_lightmap', 284, 305)
        setBlendMode('highwayLightMap', 'ADD')
        addLuaSprite('highwayLightMap')
        setProperty('highwayLightMap.alpha', 0.6)

        makeLuaSprite('highway', 'phillyStreets/phillyHighway', 139, 209)
        addLuaSprite('highway')

        makeLuaSprite('smog', 'phillyStreets/phillySmog', -6, 245)
        setScrollFactor('smog', 0.8, 1)
        addLuaSprite('smog')
    end

    makeAnimatedLuaSprite('cars1', 'phillyStreets/phillyCars', 1200, 818)
    setScrollFactor('cars1', 0.9, 1)
    addAnimationByPrefix('cars1', 'normal', 'car1', 24, false)
    addOffset('cars1', 'normal', 0, 0)
    addAnimationByPrefix('cars1', 'sport', 'car2', 24, false)
    addOffset('cars1', 'sport', 20, -15)
    addAnimationByPrefix('cars1', 'van', 'car3', 24, false)
    addOffset('cars1', 'van', 30, 50)
    addAnimationByPrefix('cars1', 'suv', 'car4', 24, false)
    addOffset('cars1', 'suv', 10, 60)
    addLuaSprite('cars1')
    
    makeAnimatedLuaSprite('cars2', 'phillyStreets/phillyCars', 1200, 818)
    setScrollFactor('cars2', 0.9, 1)
    addAnimationByPrefix('cars2', 'normal', 'car1', 24, false)
    addOffset('cars2', 'normal', 0, 0)
    addAnimationByPrefix('cars2', 'sport', 'car2', 24, false)
    addOffset('cars2', 'sport', 20, -15)
    addAnimationByPrefix('cars2', 'van', 'car3', 24, false)
    addOffset('cars2', 'van', 30, 50)
    addAnimationByPrefix('cars2', 'suv', 'car4', 24, false)
    addOffset('cars2', 'suv', 10, 60)
    setObjectOrder('cars2', getObjectOrder('cars1'))
    setProperty('cars2.flipX', true)
    addLuaSprite('cars2')

    makeAnimatedLuaSprite('trafficLight', 'phillyStreets/phillyTraffic', 1840, 608)
    addAnimationByPrefix('trafficLight', 'redTrans', 'greentored', 24, false)
    addAnimationByPrefix('trafficLight', 'greenTrans', 'redtogreen', 24, false)
    setScrollFactor('trafficLight', 0.9, 1)
    addLuaSprite('trafficLight')
    
    if lowQuality == false then
        makeLuaSprite('trafficLightMap', 'phillyStreets/phillyTraffic_lightmap', 1840, 608)
        setScrollFactor('trafficLightMap', 0.9, 1)
        setBlendMode('trafficLightMap', 'ADD')
        addLuaSprite('trafficLightMap')
        setProperty('trafficLightMap.alpha', 0.6)
    end
    
    makeLuaSprite('street', 'phillyStreets/phillyForeground', 88, 317)
    addLuaSprite('street')

    makeLuaSprite('sprayCans', 'phillyStreets/SpraycanPile', 920, 1045)
    addLuaSprite('sprayCans', true)
end

function onCreatePost()
    -- Sets up the haxe commands needed for the stage to work.
    runHaxeCode([[
        import psychlua.LuaUtils;
        function activateRainShader() FlxG.camera.setFilters([new ShaderFilter(game.getLuaObject('rainFilter').shader)]);
        function deactivateRainShader() FlxG.camera.setFilters([]);
        function quadMotionTween(object:String, fromX:Float, fromY:Float, controlX:Float, controlY:Float, toX:Float, toY:Float, duration:Float, ease:String) {
            FlxTween.quadMotion(game.getLuaObject(object), fromX, fromY, controlX, controlY, toX, toY, duration, true, {ease: LuaUtils.getTweenEaseByString(ease)});
        }
    ]])

    if shadersEnabled == true then
        initLuaShader('rain')
        makeLuaSprite('rainFilter')
        setSpriteShader('rainFilter', 'rain')
        setShaderFloat('rainFilter', 'uScale', screenHeight / 200)
        if stringStartsWith(songName:gsub('-', ' '):lower(), 'darnell') then
            intensityStart = 0
            intensityEnd = 0.1
        elseif stringStartsWith(songName:gsub('-', ' '):lower(), 'lit up') then
            intensityStart = 0.1
            intensityEnd = 0.2
        elseif stringStartsWith(songName:gsub('-', ' '):lower(), '2hot') then
            intensityStart = 0.2
            intensityEnd = 0.4
        else
            intensityStart = 0.1
            intensityEnd = 0.15
        end
        setShaderFloat('rainFilter', 'uIntensity', intensityStart)
        setShaderFloatArray('rainFilter', 'uRainColor', {102 / 255, 128 / 255, 204 / 255})
        setShaderFloatArray('rainFilter', 'uFrameBounds', {0, 0, screenWidth, screenHeight})
        runHaxeFunction('activateRainShader')
    end
end

local elapsedTime = 0
function onUpdate(elapsed)
    --[[
        This is to make the skyBox dynamic by using the 3 'sky' sprites,
        and move them right behind eachother. When one of them goes offscreen,
        it moves them behind the pack to make the skyBox seemless.
    ]]
    if lowQuality == false then
        for i = 1, 3 do
            if getProperty('sky'..i..'.x') < -(getProperty('sky'..i..'.width') * 0.65) * 2 then
                setProperty('sky'..i..'.x', getProperty('sky'..i..'.x') + (getProperty('sky'..i..'.width') * 0.65) * 3)
            end
            setProperty('sky'..i..'.x', getProperty('sky'..i..'.x') - elapsed * 22)
        end
    end
    
    -- Makes the rain active and increase its intensity from 'intensityStart' to 'intensityEnd'.
    if shadersEnabled == true then
        intensityValue = math.remapToRange(getSongPosition(), 0, songLength, intensityStart, intensityEnd)
        setShaderFloat('rainFilter', 'uIntensity', intensityValue)
        elapsedTime = elapsedTime + elapsed
        setShaderFloat('rainFilter', 'uTime', elapsedTime)
        setShaderFloatArray('rainFilter', 'uScreenResolution', {screenWidth, screenHeight})
        setShaderFloatArray('rainFilter', 'uCameraBounds', {getProperty('camGame.viewLeft'), getProperty('camGame.viewTop'), getProperty('camGame.viewRight'), getProperty('camGame.viewBottom')})
    end
end

function onGameOver()
    -- Needed if we don't want the rain to affect the Game Over screen.
    if shadersEnabled == true then
        runHaxeFunction('deactivateRainShader')
    end
end

function math.remapToRange(value, start1, stop1, start2, stop2)
    return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1))
end

-- This part of the script is where you can see how the cars and traffic light work.
isRedLight = false
lastChange = 0
changeInterval = 8

isCarWaiting = false
cars1CanBeReset = true
cars2CanBeReset = true
function onBeatHit()
    if getRandomBool(10) and curBeat ~= lastChange + changeInterval and cars1CanBeReset == true then
        if isRedLight == false then
            driveCarFromLeft()
        else
            driveCarToLight()
        end
    end
    if getRandomBool(10) and curBeat ~= lastChange + changeInterval and cars2CanBeReset == true then
        if isRedLight == false then
            driveCarFromRight()
        end
    end
    if curBeat == lastChange + changeInterval then
        changeLights()
    end
end

-- Changes the light from red to green, or vice-versa.
function changeLights()
    lastChange = curBeat
    isRedLight = not isRedLight
    if isRedLight == true then
        playAnim('trafficLight', 'redTrans')
        changeInterval = 20
    else
        playAnim('trafficLight', 'greenTrans')
        changeInterval = 30
        if isCarWaiting == true then
            driveCarFromLight()
        end
    end
end

--[[
    Moves 'cars1' from left to right.
    The car is randomized along with their respective speed.
    (Ex: The sports car will always move faster than the van or suv)
    All the 'driveCar' functions work the same, only their starting and end point change.
]]
carVariants = {'normal', 'sport', 'van', 'suv'}
offset = {x = 306.6, y = 168.3}
function driveCarFromLeft()
    cars1CanBeReset = false
    selectedCars1 = getRandomInt(1, 4)
    playAnim('cars1', carVariants[selectedCars1])
    if selectedCars1 == 1 then
        durationCars1 = getRandomFloat(1, 1.7)
    elseif selectedCars1 == 2 then
        durationCars1 = getRandomFloat(0.6, 1.2)
    elseif selectedCars1 == 3 or selectedCars1 == 4 then
        durationCars1 = getRandomFloat(1.5, 2.5)
    end

    local rotation = {Start = -8, Finish = 18}
    local pathing = {
        {x = 1570 - offset.x, y = 1049 - offset.y - 30},
        {x = 2400 - offset.x, y = 980 - offset.y - 50},
        {x = 3102 - offset.x, y = 1127 - offset.y + 40}
    }
    setProperty('cars1.angle', rotation.Start)
    doTweenAngle('changeCars1Angle', 'cars1', rotation.Finish, durationCars1, 'linear') 
    doTweenQuadMotion('cars1', pathing, durationCars1, 'linear')
end

-- Moves 'cars2' from right to left.
function driveCarFromRight()
    cars2CanBeReset = false
    selectedCars2 = getRandomInt(1, 4)
    playAnim('cars2', carVariants[selectedCars2])
    if selectedCars2 == 1 then
        durationCars2 = getRandomFloat(1, 1.7)
    elseif selectedCars2 == 2 then
        durationCars2 = getRandomFloat(0.6, 1.2)
    elseif selectedCars2 == 3 or selectedCars2 == 4 then
        durationCars2 = getRandomFloat(1.5, 2.5)
    end

    local rotation = {Start = 18, Finish = -8}
    local pathing = {
        {x = 3102 - offset.x, y = 1127 - offset.y + 60},
        {x = 2400 - offset.x, y = 980 - offset.y - 30},
        {x = 1570 - offset.x, y = 1049 - offset.y - 10}
    }
    setProperty('cars2.angle', rotation.Start)
    doTweenAngle('changeCars2Angle', 'cars2', rotation.Finish, durationCars2, 'linear')
    doTweenQuadMotion('cars2', pathing, durationCars2, 'linear')
end

-- Moves 'cars1' from left and stops it at the traffic light.
function driveCarToLight()
    cars1CanBeReset = false
    selectedCars1 = getRandomInt(1, 4)
    playAnim('cars1', carVariants[selectedCars1])
    if selectedCars1 == 1 then
        durationCars1 = getRandomFloat(1, 1.7)
    elseif selectedCars1 == 2 then
        durationCars1 = getRandomFloat(0.9, 1.5)
    elseif selectedCars1 == 3 or selectedCars1 == 4 then
        durationCars1 = getRandomFloat(1.5, 2.5)
    end

    local rotation = {Start = -7, Finish = -5}
    local pathing = {
        {x = 1500 - offset.x - 20, y = 1049 - offset.y - 20},
        {x = 1770 - offset.x - 80, y = 994 - offset.y + 10},
        {x = 1950 - offset.x - 80, y = 980 - offset.y + 15}
    }
    setProperty('cars1.angle', rotation.Start)
    doTweenAngle('changeCarsLightAngle', 'cars1', rotation.Finish, durationCars1, 'cubeOut')
    doTweenQuadMotion('cars1', pathing, durationCars1, 'cubeOut')
end

-- Moves 'cars1' from the traffic light to the right.
function driveCarFromLight()
    isCarWaiting = false
    durationCars1 = getRandomFloat(1.8, 3)
    
    local rotation = {Start = -5, Finish = 18}
    local pathing = {
        {x = 1950 - offset.x - 80, y = 980 - offset.y + 15},
        {x = 2400 - offset.x, y = 980 - offset.y - 50},
        {x = 3102 - offset.x, y = 1127 - offset.y + 40}
    }
    setProperty('cars1.angle', rotation.Start)
    doTweenAngle('changeCars1Angle', 'cars1', rotation.Finish, durationCars1, 'sineIn')
    doTweenQuadMotion('cars1', pathing, durationCars1, 'sineIn')
end

--[[
    Works the same as 'quadPath', but doesn't use FlxPoint.
    Apparently, using FlxPoint just crashes the game for some reason,
    so I had to find an alternative.
]]
function doTweenQuadMotion(vars, point, duration, ease)
    runHaxeFunction('quadMotionTween', {vars, point[1].x, point[1].y, point[2].x, point[2].y, point[3].x, point[3].y, duration, ease})
end

function onTweenCompleted(tag)
    for i = 1, 2 do
        if tag == 'changeCars'..i..'Angle' then
            _G['cars'..i..'CanBeReset'] = true
        end
    end
    if tag == 'changeCarsLightAngle' then
        isCarWaiting = true
        if isRedLight == false then
            local delay = getRandomFloat(0.2, 1.2)
            runTimer('startDelay', delay)
        end
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'startDelay' then
        driveCarFromLight()
    end
end