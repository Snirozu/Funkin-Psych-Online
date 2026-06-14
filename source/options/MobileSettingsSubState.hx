package options;

import haxe.io.Path;

class MobileSettingsSubState extends BaseOptionsMenu
{
    #if android
    final lastStorageType:String = ClientPrefs.data.storageType;
    #end
	public function new()
	{
		title = 'Mobile';
		rpcTitle = 'Mobile Settings Menu'; //for Discord Rich Presence

        #if FEATURE_TOUCH_CONTROLS
		var option:Option = new Option('Control Alpha',
			"Pretty self explanatory, isn't it?",
			'controlAlpha',
			'percent');
		addOption(option);
		option.minValue = 0;
		option.maxValue = 1;
		option.onChange = function() { Main.mobileControls.alpha = ClientPrefs.data.controlAlpha; };

        var option:Option = new Option('Extra Control',
			"Pretty self explanatory, isn't it?",
			'extraControl',
			'int');
		addOption(option);
		option.minValue = 0;
		option.maxValue = 2;
        #end

        #if android
        var option:Option = new Option('Storage Type',
			"'Which folder Psych Online should use?",
			'storageType',
			'string',
			['EXTERNAL_DATA', 'EXTERNAL_OBB', 'EXTERNAL_MEDIA', "EXTERNAL"]);
		addOption(option);
        #end

		super();
	}

    override public function destroy() {
		super.destroy();

		#if android
		if (ClientPrefs.data.storageType != lastStorageType) {
			File.saveContent(lime.system.System.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.data.storageType);
			ClientPrefs.saveSettings();
			StorageUtil.initExternalStorageDirectory();
		}
		#end
	}
}