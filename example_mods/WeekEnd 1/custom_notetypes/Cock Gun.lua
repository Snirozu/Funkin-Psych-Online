function onCreate()
    precacheSound('Gun_Prep')
end

gunCocked = false
function goodNoteHit(membersIndex, noteData, noteType, isSustainNote)
    if noteType == 'Cock Gun' then
        playAnim('boyfriend', 'cock')
        setProperty('boyfriend.specialAnim', true)
        makeFadingSprite()
        
        playSound('Gun_Prep')
        setOnLuas('gunCocked', true) -- Makes the variables available to all the Lua scipts with those values.
        setOnLuas('casingNum', casingNum + 1)

        -- Abot will look to the right (towards the player).
        playAnim('AbotPupils', '', true, false, 17)
    end
end

function noteMiss(membersIndex, noteData, noteType, isSustainNote)
    -- This is necessary since we want Abot to look towards the player in any case.
    if noteType == 'Cock Gun' then
        playAnim('AbotPupils', '', true, false, 17)
    end
end

function makeFadingSprite()
    makeAnimatedLuaSprite('picoFade', getProperty('boyfriend.imageFile'), getProperty('boyfriend.x'), getProperty('boyfriend.y'))
    addAnimationByPrefix('picoFade', 'anim', getProperty('boyfriend.animation.frameName'), getProperty('boyfriend.animation.frameIndex'), false)
    setObjectOrder('picoFade', getObjectOrder('boyfriendGroup') + 1)
    setProperty('picoFade.alpha', 0.3)
    addLuaSprite('picoFade')

    doTweenX('fadingTweenX', 'picoFade.scale', 1.3, 0.4, 'linear')
    doTweenY('fadingTweenY', 'picoFade.scale', 1.3, 0.4, 'linear')
    doTweenAlpha('fadingTweenAlpha', 'picoFade', 0, 0.4, 'linear')
    
    updateHitbox('picoFade')
    setProperty('picoFade.offset.x', getProperty('boyfriend.offset.x'))
    setProperty('picoFade.offset.y', getProperty('boyfriend.offset.y'))
end

casingNum = 0
function onUpdatePost(elapsed)
    if getProperty('boyfriend.animation.name') == 'cock' then
        if getProperty('boyfriend.animation.curAnim.curFrame') == 3 then
            makeAnimatedLuaSprite('casing'..casingNum, 'phillyStreets/PicoBullet', getProperty('boyfriend.x') + 250, getProperty('boyfriend.y') + 100)
            addAnimationByPrefix('casing'..casingNum, 'pop', 'Pop0', 24, false)
            addAnimationByPrefix('casing'..casingNum, 'anim', 'Bullet0', 24, false)
            addLuaSprite('casing'..casingNum, true)
            playAnim('casing'..casingNum, 'pop')
        end
    end
    for num = 1, casingNum do
        if getProperty('casing'..num..'.animation.name') == 'pop' then
            if getProperty('casing'..num..'.animation.curAnim.curFrame') == 40 then
                startRoll('casing'..num) 
            end
        end
    end
end

--[[
    This makes the bullet roll when the 'pop' animation is finished.
    The roll is randomized, so it won't always end up in the same position.
]]
function startRoll(spriteName)
    randomNum1 = getRandomFloat(3, 10)
    randomNum2 = getRandomFloat(1, 2)
    
    setProperty(spriteName..'.x', getProperty(spriteName..'.x') + getProperty(spriteName..'.frame.offset.x') - 1)
    setProperty(spriteName..'.y', getProperty(spriteName..'.y') + getProperty(spriteName..'.frame.offset.y') + 1)
    setProperty(spriteName..'.angle', 125.1)
    
    setProperty(spriteName..'.velocity.x', 20 * randomNum2)
    setProperty(spriteName..'.drag.x', randomNum1 * randomNum2)
    setProperty(spriteName..'.angularVelocity', 100)
    setProperty(spriteName..'.angularDrag', ((randomNum1 * randomNum2) / (20 * randomNum2)) * 100)

    playAnim(spriteName, 'anim')
end