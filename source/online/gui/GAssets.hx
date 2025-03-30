package online.gui;

class GAssets {
    public static function image(path:String) {
		var img = Paths.image(path, null, false);
		if (img == null)
            return null;

		return img.bitmap.clone();
    }    
}