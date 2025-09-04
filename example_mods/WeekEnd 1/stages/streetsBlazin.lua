function onCreate()
    if lowQuality == false then
        for i = 0, 2 do
            makeLuaSprite('sky'..(i + 1), 'phillyBlazin/skyBlur', -500, -120)
            setScrollFactor('sky'..(i + 1), 0, 0)
            addLuaSprite('sky'..(i + 1))
            setProperty('sky'..(i + 1)..'.x', getProperty('sky'..(i + 1)..'.x') + getProperty('sky'..(i + 1)..'.width') * i)
        end
    else
        for i = 0, 1 do
            makeLuaSprite('sky'..(i + 1), 'phillyBlazin/skyBlur', -500, -120)
            setScrollFactor('sky'..(i + 1), 0, 0)
            addLuaSprite('sky'..(i + 1))
            setProperty('sky'..(i + 1)..'.x', getProperty('sky'..(i + 1)..'.x') + getProperty('sky'..(i + 1)..'.width') * i)
        end
    end

    if flashingLights == true then
        makeLuaSprite('skyAdd', 'phillyBlazin/skyBlur', -600, -175)
        setScrollFactor('skyAdd', 0, 0)
        scaleObject('skyAdd', 1.75, 1.75)
        setBlendMode('skyAdd', 'ADD')
        addLuaSprite('skyAdd')
        setProperty('skyAdd.alpha', 0)
    end

    makeAnimatedLuaSprite('lighting', 'phillyBlazin/lightning', 50, -300)
    addAnimationByPrefix('lighting', 'anim', 'lightning0', 24, false)
    setScrollFactor('lighting', 0, 0)
    scaleObject('lighting', 1.75, 1.75)
    addLuaSprite('lighting')
    setProperty('lighting.visible', false)

    makeLuaSprite('streets', 'phillyBlazin/streetBlur', -600, -175)
    setScrollFactor('streets', 0, 0)
    scaleObject('streets', 1.75, 1.75)
    addLuaSprite('streets')

    if flashingLights == true then
        makeLuaSprite('streetsMultiply', 'phillyBlazin/streetBlur', -600, -175)
        setScrollFactor('streetsMultiply', 0, 0)
        scaleObject('streetsMultiply', 1.75, 1.75)
        setBlendMode('streetsMultiply', 'MULTIPLY')
        addLuaSprite('streetsMultiply')
        setProperty('streetsMultiply.alpha', 0)

        makeLuaSprite('lightenAdd', '', -600, -175)
        makeGraphic('lightenAdd', 2500, 2000)
        setScrollFactor('lightenAdd', 0, 0)
        setBlendMode('lightenAdd', 'ADD')
        addLuaSprite('lightenAdd')
        setProperty('lightenAdd.alpha', 0)
    end

    for num = 1, 3 do
        precacheSound('Lightning'..num)
    end
end

function onCreatePost()
    -- Sets up the haxe commands needed for the stage to work.
    runHaxeCode([[
        function activateRainShader() FlxG.camera.setFilters([new ShaderFilter(game.getLuaObject('rainFilter').shader)]);
        function deactivateRainShader() FlxG.camera.setFilters([]);
    ]])

    if shadersEnabled == true then
        initLuaShader('rain')
        makeLuaSprite('rainFilter')
        setSpriteShader('rainFilter', 'rain')
        setShaderFloat('rainFilter', 'uScale', screenHeight / 200)
        setShaderFloat('rainFilter', 'uIntensity', 0.5)
        setShaderFloatArray('rainFilter', 'uRainColor', {102 / 255, 128 / 255, 204 / 255})
        setShaderFloatArray('rainFilter', 'uFrameBounds', {0, 0, screenWidth, screenHeight})
        runHaxeFunction('activateRainShader')
    end
    
    local cameraTargetGF = {
        x = getMidpointX('gf') + getProperty('gf.cameraPosition[0]') + getProperty('girlfriendCameraOffset[0]'),
        y = getMidpointY('gf') + getProperty('gf.cameraPosition[1]') + getProperty('girlfriendCameraOffset[1]')
    }
    setProperty('camFollow.x', cameraTargetGF.x + 125)
    setProperty('camFollow.y', cameraTargetGF.y - 100)
    runHaxeCode('FlxG.camera.snapToTarget();')
    runHaxeCode('FlxG.camera.target = null;') -- To make sure the camera never moves during the song.
    
    setProperty('boyfriend.color', 0xDEDEDE)
    setProperty('dad.color', 0xDEDEDE)
    setProperty('gf.color', 0x888888)
    cameraFlash('game', '0x000000', 1.5, true)
end

local elapsedTime = 0
local timeScale = 1
local lightingActive = true
local lightingTimer = 3
function onUpdate(elapsed)
    --[[
        This is to make the skyBox dynamic by using the 3 'sky' sprites,
        and move them right behind eachother. When one of them goes offscreen,
        it moves them behind the pack to make the skyBox seemless.
    ]]
    if lowQuality == false then
        for i = 1, 3 do
            if getProperty('sky'..i..'.x') < -getProperty('sky'..i..'.width') * 1.5 then
                setProperty('sky'..i..'.x', getProperty('sky'..i..'.x') + getProperty('sky'..i..'.width') * 3)
            end
            setProperty('sky'..i..'.x', getProperty('sky'..i..'.x') - elapsed * 35)
        end
    end

    -- Makes the rain active and will increasingly slow down if a note isn't hit.
    if shadersEnabled == true then
        elapsedTime = elapsedTime + (elapsed * timeScale)
        setShaderFloat('rainFilter', 'uTime', elapsedTime)
        timeScale = math.coolLerp(timeScale, 0.02, 0.05, elapsed)
        setShaderFloatArray('rainFilter', 'uScreenResolution', {screenWidth, screenHeight})
        setShaderFloatArray('rainFilter', 'uCameraBounds', {getProperty('camGame.viewLeft'), getProperty('camGame.viewTop'), getProperty('camGame.viewRight'), getProperty('camGame.viewBottom')})
    end

    -- This is where we randomize the apparition of the lighting strike.
    if lightingActive == true then
        lightingTimer = lightingTimer - elapsed
        if lightingTimer <= 0 then
            strikeLighting()
            lightingTimer = getRandomFloat(7, 15)
        end
    end
end

function onGameOver()
    -- Needed if we don't want the rain and lighting to affect the Game Over screen.
    lightingActive = false
    if shadersEnabled == true then
        runHaxeFunction('deactivateRainShader')
    end
end

function onEndSong()
    lightingActive = false -- Needed since we don't want the lighting to be active during a cutscene.
end

-- Speeds up the rain's speed with each note hit, both from the opponent and the player.
function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if shadersEnabled == true then
        timeScale = timeScale + 0.7
    end
end

function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if shadersEnabled == true then
        timeScale = timeScale + 0.7
    end
end

function math.coolLerp(base, target, ratio, elapsed)
    return base + (ratio * (elapsed / (1 / 60))) * (target - base)
end

-- This is the function that makes the lighting strike and affect the background and characters.
local lightingOffset = 0
function strikeLighting()
    if getRandomBool(65) then
        lightingOffset = getRandomInt(-250, 280)
    else
        lightingOffset = getRandomInt(780, 900)
    end
    local num = getRandomInt(1, 3)
    setProperty('lighting.visible', true)
    setProperty('lighting.x', lightingOffset)
    playAnim('lighting', 'anim')
    playSound('Lightning'..num)

    if flashingLights == true then
        setProperty('skyAdd.alpha', 0.7)
        setProperty('streetsMultiply.alpha', 0.64)
        setProperty('lightenAdd.alpha', 0.3)
        doTweenAlpha('removeSkyAdd', 'skyAdd', 0, 1.5, 'linear')
        doTweenAlpha('removeStreetsMultiply', 'streetsMultiply', 0, 1.5, 'linear')
        doTweenAlpha('removeLightenAdd', 'lightenAdd', 0, 0.3, 'linear')

        setProperty('boyfriend.color', 0x606060)
        setProperty('dad.color', 0x606060)
        setProperty('gf.color', 0x606060)
        doTweenColor('resetColorBF', 'boyfriend', '0xDEDEDE', 0.3, 'linear')
        doTweenColor('resetColorDad', 'dad', '0xDEDEDE', 0.3, 'linear')
        doTweenColor('resetColorGF', 'gf', '0x888888', 0.3, 'linear')
    end
end