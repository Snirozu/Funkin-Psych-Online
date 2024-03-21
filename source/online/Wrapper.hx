package online;

class Wrapper {
    public static function wrapperField(field:String) {
        switch (field) {
			case "camFollowPos.x":
				//return "scrollXCenter"; // is psych engine wiki inaccurate or what
				return "camGame.scroll.x";
			case "camFollowPos.y":
				//return "scrollYCenter";
				return "camGame.scroll.y";
        }
        return field;
    }

    public static function wrapperClass(className:String) {
        switch (className) {
            case "ClientPrefs":
                return "backend.ClientPrefs";
        }
        return className;
    }

	public static function wrapperClassField(className:String, field:String) {
		if (className == "ClientPrefs") {
			switch (field) {
				case "downScroll":
					return "data.downScroll";
				case "middleScroll":
					return "data.middleScroll";
				case "opponentStrums":
					return "data.opponentStrums";
				case "showFPS":
					return "data.showFPS";
				case "flashing":
					return "data.flashing";
				case "globalAntialiasing":
					return "data.antialiasing";
				case "lowQuality":
					return "data.lowQuality";
				case "shaders":
					return "data.shaders";
				case "framerate":
					return "data.framerate";
				case "camZooms":
					return "data.camZooms";
				case "hideHud":
					return "data.hideHud";
				case "noteOffset":
					return "data.noteOffset";
				case "ghostTapping":
					return "data.ghostTapping";
				case "timeBarType":
					return "data.timeBarType";
				case "scoreZoom":
					return "data.scoreZoom";
				case "noReset":
					return "data.noReset";
				case "healthBarAlpha":
					return "data.healthBarAlpha";
				case "hitsoundVolume":
					return "data.hitsoundVolume";
				case "pauseMusic":
					return "data.pauseMusic";
				case "checkForUpdates":
					return "data.checkForUpdates";
				case "comboStacking":
					return "data.comboStacking";
				case "gameplaySettings":
					return "data.gameplaySettings";
				case "comboOffset":
					return "data.comboOffset";
				case "ratingOffset":
					return "data.ratingOffset";
				case "sickWindow":
					return "data.sickWindow";
				case "goodWindow":
					return "data.goodWindow";
				case "badWindow":
					return "data.badWindow";
				case "safeFrames":
					return "data.safeFrames";
			}
        }

        return field;
	}
}