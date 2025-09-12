function onUpdatePost(elapsed)
    local bfFrames = getProperty('iconP1.frames.frames.length') -- total frames in the player's icon
    local bfHealth = getProperty('healthBar.percent')

    if bfHealth >= 80 and bfFrames > 2 then
        setProperty('iconP1.animation.curAnim.curFrame', 2) 
    elseif bfHealth <= 20 and bfFrames > 1 then
        setProperty('iconP1.animation.curAnim.curFrame', 1) 
    else
        setProperty('iconP1.animation.curAnim.curFrame', 0) 
    end

    local dadFrames = getProperty('iconP2.frames.frames.length') 
    local dadHealth = getProperty('healthBar.percent')

    if dadHealth <= 20 and dadFrames > 2 then
        setProperty('iconP2.animation.curAnim.curFrame', 2) 
    elseif dadHealth >= 80 and dadFrames > 1 then
        setProperty('iconP2.animation.curAnim.curFrame', 1) 
    else
        setProperty('iconP2.animation.curAnim.curFrame', 0) 
    end
end