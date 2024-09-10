package online;

import online.schema.Player;

class Debug {
	public static var fakePlayer1:Player = createFakePlayer();
	public static var fakePlayer2:Player = createFakePlayer();

    public static function createFakePlayer() {
		var player = Type.createInstance(Player, []);
		player.score = FlxG.random.int(50, 10000);
		player.misses = FlxG.random.int(0, 100);
		player.sicks = FlxG.random.int(0, 500);
		player.goods = FlxG.random.int(0, 500);
		player.bads = FlxG.random.int(0, 500);
		player.shits = FlxG.random.int(0, 500);
		player.name = "Boyfriend";
		player.points = FlxG.random.int(0, 30);
        return player;
    }
}