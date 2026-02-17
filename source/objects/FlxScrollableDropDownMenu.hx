package objects;

import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.FlxUIButton;
import flixel.FlxG;
import flixel.addons.ui.FlxUIDropDownMenu;

/**
 * A FlxUIDropDownMenu that is extended to have scrolling capabilities.
 * @author Vortex, larsiusprime (original  scroll code)
 * @see https://github.com/Vortex2Oblivion/LeatherEngine-LTS/blob/main/source/ui/FlxScrollableDropDownMenu.hx
 */
class FlxScrollableDropDownMenu extends FlxUIDropDownMenu  {

    private var currentScroll:Int = 0; //Handles the scrolling
    public var canScroll:Bool = true;

	public function new(X:Float = 0, Y:Float = 0, DataList:Array<flixel.addons.ui.StrNameLabel>, ?Callback:String -> Void, ?Header:FlxUIDropDownHeader, ?DropPanel:flixel.addons.ui.FlxUI9SliceSprite, ?ButtonList:Array<FlxUIButton>, ?UIControlCallback:(Bool, FlxUIDropDownMenu) -> Void) {
		super(X, Y, DataList, Callback, Header, DropPanel, ButtonList, UIControlCallback);
		dropDirection = Down;
	}
    
    override private function set_dropDirection(dropDirection):FlxUIDropDownMenuDropDirection
        {
            this.dropDirection = Down;
            updateButtonPositions();
            return dropDirection;
        }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        #if FLX_MOUSE
		if (dropPanel.visible)
		{
			if(list.length > 1 && canScroll) {
				if(FlxG.mouse.wheel > 0 || FlxG.keys.justPressed.UP) {
					// Go up
					--currentScroll;
					if(currentScroll < 0) currentScroll = 0;
					updateButtonPositions();
				}
				else if (FlxG.mouse.wheel < 0 || FlxG.keys.justPressed.DOWN) {
					// Go down
					currentScroll++;
					if(currentScroll >= list.length) currentScroll = list.length-1;
					updateButtonPositions();
				}
			}
		}
		#end
    }
    override function updateButtonPositions():Void{
        super.updateButtonPositions();
        var buttonHeight = header.background.height;
		dropPanel.y = header.background.y;
		if (dropsUp())
			dropPanel.y -= getPanelHeight();
		else
			dropPanel.y += buttonHeight;

		var offset = dropPanel.y;
        for (i in 0...currentScroll) { //Hides buttons that goes before the current scroll
			var button:FlxUIButton = list[i];
			if(button != null) {
				button.y = -99999;
			}
		}
		for (i in currentScroll...list.length)
		{
			var button:FlxUIButton = list[i];
			if(button != null) {
				button.y = offset;
				offset += buttonHeight;
			}
		}
    }

	/**
	 * Helper function to easily create a data list for a dropdown menu from an array of strings.
	 *
	 * @param	StringArray		The strings to use as data - used for both label and string ID.
	 * @param	UseIndexID		Whether to use the integer index of the current string as ID.
	 * @return	The StrIDLabel array ready to be used in FlxUIDropDownMenuCustom's constructor
	 */
	 public static function makeStrIdLabelArray(StringArray:Array<String>, UseIndexID:Bool = false):Array<StrNameLabel>
		{
			var strIdArray:Array<StrNameLabel> = [];
			for (i in 0...StringArray.length)
			{
				var ID:String = StringArray[i];
				if (UseIndexID)
				{
					ID = Std.string(i);
				}
				strIdArray[i] = new StrNameLabel(ID, StringArray[i]);
			}
			return strIdArray;
		}
}