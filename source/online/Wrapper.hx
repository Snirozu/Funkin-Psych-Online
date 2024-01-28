package online;

@:build(online.Macros.getSetForwarder())
class Wrapper {
    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.serverAddress 
        #else ClientPrefs.serverAddress #end
    )
    public static var prefServerAddress(get, set):String;

    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.antialiasing
		#else ClientPrefs.globalAntialiasing #end
    )
	public static var prefAntialiasing(get, set):Bool;

    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.nickname
		#else ClientPrefs.nickname #end
    )
	public static var prefNickname(get, set):String;

    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.modSkin
		#else ClientPrefs.modSkin #end
    )
	public static var prefModSkin(get, set):Array<String>;

	static var defAutoPause = false;
    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.autoPause
		#else defAutoPause #end
    )
	public static var prefAutoPause(get, set):Bool;

    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.trustedSources
		#else ClientPrefs.trustedSources #end
    )
	public static var prefTrustedSources(get, set):Array<String>;

    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.comboOffset
		#else ClientPrefs.comboOffset #end
    )
	public static var prefComboOffset(get, set):Array<Int>;

    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.comboOffsetOP1
		#else ClientPrefs.comboOffsetOP1 #end
    )
	public static var prefComboOffsetOP1(get, set):Array<Int>;

    @:forwardField(
        #if (PSYCH_VER >= "0.7") ClientPrefs.data.comboOffsetOP2
		#else ClientPrefs.comboOffsetOP2 #end
    )
	public static var prefComboOffsetOP2(get, set):Array<Int>;
}