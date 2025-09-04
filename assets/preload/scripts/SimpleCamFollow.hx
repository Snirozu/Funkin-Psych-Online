final animIndexArray:Array<Array<Int>> = [[-1, 0], [0, 1], [0, -1], [1, 0]];
var offsetArray:Array<Float> = [];

final mult:Float = 20;

var forceCamera:Bool = false;

function setForceCamera(value:Bool)
{
    forceCamera = value;
}

function onUpdatePost(elapsed:Float)
{
    if (forceCamera || cameraSpeed == 999)
    {
        camGame.targetOffset.set(0, 0);
        return;
    }

    camGame.targetOffset.set(0, 0);
    offsetArray = [0, 0];

    for (i in 0...4)
    {
        for (strums in [playerStrums, opponentStrums])
        {
            if (strums != null && i < strums.members.length)
            {
                var strum = strums.members[i];

                if (strum != null && strum.animation != null && strum.animation.curAnim != null)
                {
                    if (strum.animation.curAnim.name == "confirm")
                    {
                        offsetArray = [
                            animIndexArray[i][0] * mult,
                            animIndexArray[i][1] * mult
                        ];
                    }
                }
            }
        }
    }

    camGame.targetOffset.set(
        camGame.targetOffset.x + offsetArray[0],
        camGame.targetOffset.y + offsetArray[1]
    );
}