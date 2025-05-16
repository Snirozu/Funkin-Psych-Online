package online.away;

using StringTools;

@:publicFields
class AnimationDataParser {
	static function parseSparrowXML(data:String, animFrames:AnimationFrameDataMap):AnimationFrameDataMap {
		animFrames ??= new AnimationFrameDataMap();

		var xml = Xml.parse(data);
		
		var root = xml.firstElement();
		if (root != null && root.nodeName != null && root.nodeName == "TextureAtlas") {
			for (node in root) {
				if (node != null && node.nodeType == Element) {
					var animName = node.get("name").substring(0, node.get("name").length - 4);

					if (!animFrames.exists(animName))
						animFrames.set(animName, []);

					animFrames.get(animName).push({
						rawName: node.get("name"),
						x: Std.parseInt(node.get("x")),
						y: Std.parseInt(node.get("y")),
						width: Std.parseInt(node.get("width")),
						height: Std.parseInt(node.get("height")),

						frameX: node.exists("frameX") ? Std.parseInt(node.get("frameX")) : 0,
						frameY: node.exists("frameY") ? Std.parseInt(node.get("frameY")) : 0,
						frameWidth: node.exists("frameWidth") && node.get("frameWidth") != '0' ? Std.parseInt(node.get("frameWidth")) : null,
						frameHeight: node.exists("frameHeight") && node.get("frameHeight") != '0' ? Std.parseInt(node.get("frameHeight")) : null
					});
				}
			}
		}
		return animFrames;
	}

	static function parsePackerTXT(data:String, animFrames:AnimationFrameDataMap):AnimationFrameDataMap {
		animFrames ??= new AnimationFrameDataMap();

		for (rawFrame in data.split('\n')) {
			if (rawFrame.trim() == '')
				continue;

			var rawProps = rawFrame.split('=');
			var animName = sepNameFromIndex(rawProps[0].trim())[0];
			var rawNums = rawProps[1].trim().split(' ');

			if (!animFrames.exists(animName))
				animFrames.set(animName, []);

			animFrames.get(animName).push({
				rawName: rawProps[0].trim(),
				x: Std.parseInt(rawNums[0]),
				y: Std.parseInt(rawNums[1]),
				width: Std.parseInt(rawNums[2]),
				height: Std.parseInt(rawNums[3]),
				frameX: 0,
				frameY: 0,
			});
		}
		return animFrames;
	}

	private static function sepNameFromIndex(str:String):Array<Dynamic> {
		var index = '';
		var name = '';

		var endedNums = false;
		var charCode = 0;
		var i = str.length;
		while (i > 0) {
			i--;
			charCode = str.charCodeAt(i);

			if (charCode < 48 || charCode > 57)
				endedNums = true;

			if (endedNums)
				name = str.charAt(i) + name;
			else
				index = str.charAt(i) + index;
		}

		return [name, Std.parseInt(index)];
	}
}