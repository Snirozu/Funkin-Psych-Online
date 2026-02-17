package states.stages.objects;

import online.GameClient;
import objects.Character;

class Nene extends Character {
	public var state:NeneState = NORMAL;

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
        if (state == DIRE && !Force) {
			if ((animation.name != 'idleKnife' || animation.finished) && AnimName.startsWith('dance') && FlxG.random.bool(20))
                super.playAnim('idleKnife', true);
            return;
        }
        super.playAnim(AnimName, Force, Reversed, Frame);
    }

    override public function onHealth(from:Float, to:Float) {
        if (!GameClient.isConnected() && !PlayState.playsAsBF())
            return;

		if (to <= 0.5 && state != DIRE) {
            state = DIRE;

            playAnim('raiseKnife', true);
            return;
		}
        
		if (to > 0.5 && state != NORMAL) {
            state = NORMAL;

            playAnim('lowerKnife', true);
            specialAnim = true;
            return;
        }
    }

    override public function onCombo(from:Int, to:Int) {
        if (to % 50 == 0) {
            if (to != 0) {
                if (to % 200 == 0) {
                    playAnim('combo200', false);
                    specialAnim = true;
                }
                else if (to == 50) {
                    playAnim('combo50', false);
                    specialAnim = true;
                }
            }

			if (to == 0 && from >= 70) {
				playAnim('laughCutscene', false);
                specialAnim = true;
            }
		}
    }
}

enum NeneState {
    NORMAL;
    DIRE;
}