package externs;

// class from another fnf mod that i made, bringing this here because my eyes burn
// anyway some code from
// https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/apply-windows-themes

#if (windows && cpp)
@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows" />
	<lib name="shell32.lib" if="windows" />
</target>
')

@:cppFileCode('
#include <iostream>
#include "dwmapi.h"
#include "winuser.h"
#include "windows.h"
#include "shellapi.h"

#define WM_SETICON 0x0080

HICON hWindowIcon = NULL;
HICON hWindowIconBig = NULL;
')
#end
class WinAPI {
	#if (windows && cpp)
	@:functionCode('
	HWND window = FindWindowA(NULL, title.c_str());
	if (window == NULL) 
		window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());

	int value = enabled ? 1 : 0;

	if (window != NULL) {
		DwmSetWindowAttribute(window, 20, &value, sizeof(value));

		ShowWindow(window, 0);
		ShowWindow(window, 1);
		SetFocus(window);
	}
	')
	#end
	public static function setDarkMode(title:String, enabled:Bool):Void {}

	#if (windows && cpp)
	@:functionCode('
	HWND window = FindWindowA(NULL, title.c_str());
	if (window == NULL) 
		window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());

	if (window != NULL) {
		if(hWindowIcon!=NULL)
		   DestroyIcon(hWindowIcon);
		if(hWindowIconBig!=NULL)
		   DestroyIcon(hWindowIconBig);

		if (stricon.c_str() == "")
		{
			SendMessage( window, WM_SETICON, ICON_SMALL, (LPARAM)NULL );
			SendMessage( window, WM_SETICON, ICON_BIG, (LPARAM)NULL );
		}
		else
		{
			hWindowIcon = (HICON)LoadImage(NULL, stricon.c_str(), IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
			hWindowIconBig =(HICON)LoadImage(NULL, stricon.c_str(), IMAGE_ICON, 32, 32, LR_LOADFROMFILE);
			SendMessage( window, WM_SETICON, ICON_SMALL, (LPARAM)hWindowIcon );
			SendMessage( window, WM_SETICON, ICON_BIG, (LPARAM)hWindowIconBig );
		}
	}
	')
	#end
	public static function setIcon(title:String, stricon:String):Void {}

	// TaskDialog doesn't work on haxe for some reason
	#if (windows && cpp)
	@:functionCode('
	int msgboxID = MessageBox(NULL, content.c_str(), title.c_str(), MB_ICONERROR | MB_OKCANCEL | MB_DEFBUTTON2);
	switch (msgboxID) {
		case IDOK:
			yesCallback();
			break;
		case IDCANCEL:
			break;
	}
	')
	#end
	public static function alert(title:String, content:String, yesCallback:Void->Void):Void {}

	#if (windows && cpp)
	@:functionCode('
	int msgboxID = MessageBox(NULL, content.c_str(), title.c_str(), MB_ICONERROR | MB_YESNOCANCEL | MB_DEFBUTTON3);
	switch (msgboxID) {
		case IDYES:
			yesCallback();
			break;
		case IDNO:
			noCallback();
			break;
		case IDCANCEL:
			break;
	}
	')
	#end
	public static function ask(title:String, content:String, yesCallback:Void->Void, noCallback:Void->Void):Void {}

	#if (windows && cpp)
	@:functionCode('
		HINSTANCE hInst = ShellExecute(NULL, "runas", command.c_str(), args.c_str(), NULL, SW_SHOWDEFAULT);
		return (INT_PTR)hInst > 32;
	')
	#end
	@:unreflective
	public static function commandAsAdministrator(command:String, args:String):Bool
	{
		return false;
	}
}