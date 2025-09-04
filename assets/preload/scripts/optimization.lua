function onCreate()
    addHaxeLibrary('Assets','openfl.utils');
end
function removeFromMemory(path,removeImageInstantly)
    if(path ~= nil) then
        if removeImageInstantly == nil then
            removeImageInstantly = true
        end
        runHaxeCode(
            [[
                var foundPath = Paths.getPath("images/]]..path..[[.png");
                if(Assets.cache.hasBitmapData(foundPath)){
                    Assets.cache.removeBitmapData(foundPath);
                }
                if(!FlxG.bitmap._cache.exists(foundPath)){
                    foundPath = Paths.modsImages("]]..path..[[");
                }
                if(!FlxG.bitmap._cache.exists(foundPath)){
                    foundPath = '';
                }

                if(foundPath == ''){
                    return;
                }
        
                var modGraphic = FlxG.bitmap._cache.get(foundPath);
                if(modGraphic != null){
                    FlxG.bitmap.removeByKey(foundPath);
                    if(Paths.currentTrackedAssets.exists(foundPath)){
                        Paths.currentTrackedAssets.remove(foundPath);
                    }
                    if(Paths.localTrackedAssets.contains(foundPath)){
                        Paths.localTrackedAssets.remove(Paths.localTrackedAssets.indexOf(foundPath));
                    }
                    modGraphic.persist = false;
                    modGraphic.destroyOnNoUse = true;
                    if(]]..tostring(removeImageInstantly)..[[){
                        modGraphic.destroy();
                    }
                }
            ]]
        )
    end
end

function removeCharacterFromMemory(character,removeImageInstantly)
    local foundedImage = runHaxeCode(
        [[
            var imageFile = '';
            var charName = "]]..character..[[";
            var char = null;

            if(game.boyfriendMap.exists(charName)){
                char = game.boyfriendMap.get(charName);
                game.boyfriendGroup.remove(char,true);
                game.boyfriendMap.remove(charName);
            }
            if(game.dadMap.exists(charName)){
                char = game.dadMap.get(charName);
                game.dadGroup.remove(char,true);
                game.dadMap.remove(charName);
            }
            if(game.gfMap.exists(charName)){
                char = game.gfMap.get(charName);
                game.gfGroup.members.remove(char,true);
                game.gfGroup.remove(char,true);
                game.gfMap.remove(charName);
            }
            
            if(char != null){
                imageFile = char.imageFile;
                char.kill();
                char.destroy();
            }

            if(imageFile != null && imageFile != ''){
                return imageFile;
            }
            return false;
        ]]
    )

    if foundedImage ~= false then
        removeFromMemory(foundedImage,removeImageInstantly ~= false)
    end
end

function onCreatePost()
    removeCharacterFromMemory('bf-dead')
    removeFromMemory('logo');
    runHaxeCode(
        [[
            if(!game.isPixelStage){
                Assets.cache.clear('assets/shared/images/pixelUI');
            }
            return;
        ]]
    )
end