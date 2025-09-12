package backend;

#if sys
import sys.FileSystem;
import sys.io.File;
#else
import lime.utils.Assets;
#end
import tjson.TJSON as Json;
import haxe.ds.StringMap;

typedef ModsList = {
    enabled:Array<String>,
    disabled:Array<String>,
    all:Array<String>
};

typedef ModPack = {
    ?runsGlobally:Bool,
};

class Mods {
    public static var currentModDirectory:String = '';
    private static var globalMods:Array<String> = [];
    private static var cachedModsList:ModsList = null;
    private static var modsListLastRead:Float = 0;
    public static var updatedOnState:Bool = false;

    public static var ignoreModFolders:Array<String> = [
        'characters','custom_events','custom_notetypes','data','songs','music','sounds',
        'shaders','videos','images','stages','weeks','fonts','scripts','achievements','lumod'
    ];

    inline public static function getGlobalMods() return globalMods;

    inline public static function pushGlobalMods() {
        globalMods = [];
        for (mod in parseList().enabled) {
            var pack = getPack(mod);
            if (pack != null && pack.runsGlobally) globalMods.push(mod);
        }
        return globalMods;
    }

    inline public static function getModDirectories():Array<String> {
        var list:Array<String> = [];
        #if MODS_ALLOWED
        var modsFolder = Paths.mods();
        if (FileSystem.exists(modsFolder)) {
            for (folder in FileSystem.readDirectory(modsFolder)) {
                var path = haxe.io.Path.join([modsFolder, folder]);
                if (FileSystem.isDirectory(path)) {
                    var lower = folder.toLowerCase();
                    if (!ignoreModFolders.contains(lower)) list.push(folder);
                }
            }
        }
        #end
        return list;
    }

    inline public static function mergeAllTextsNamed(path:String, defaultDirectory:String = null, allowDuplicates:Bool = false) {
        if (defaultDirectory == null) defaultDirectory = Paths.getPreloadPath();
        defaultDirectory = defaultDirectory.trim();
        if (!defaultDirectory.endsWith('/')) defaultDirectory += '/';
        if (!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

        var mergedList:Array<String> = [];
        var seen:StringMap<Bool> = new StringMap();
        var paths = directoriesWithFile(defaultDirectory, path);
        var defaultPath = defaultDirectory + path;
        if (paths.remove(defaultPath)) paths.insert(0, defaultPath);

        for (file in paths) {
            var list = CoolUtil.coolTextFile(file);
            for (value in list) if (value.length > 0) {
                if (allowDuplicates || !seen.exists(value)) {
                    mergedList.push(value);
                    if (!allowDuplicates) seen.set(value, true);
                }
            }
        }
        return mergedList;
    }

    inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true) {
        var foldersToCheck:Array<String> = [];
        inline function check(path:String) {
            #if sys if (FileSystem.exists(path)) #end foldersToCheck.push(path);
        }
        check(path + fileToFind);
        #if MODS_ALLOWED
        if (mods) {
            for (mod in getGlobalMods()) check(Paths.mods(mod + '/' + fileToFind));
            check(Paths.mods(fileToFind));
            if (currentModDirectory.length > 0) check(Paths.mods(currentModDirectory + '/' + fileToFind));
        }
        #end
        return foldersToCheck;
    }

    public static function getPack(?folder:String = null):Null<ModPack> {
        #if MODS_ALLOWED
        if (folder == null) folder = currentModDirectory;
        var path = Paths.mods(folder + '/pack.json');
        if (FileSystem.exists(path)) {
            try {
                #if sys var raw = File.getContent(path); #else var raw = Assets.getText(path); #end
                if (raw != null && raw.length > 0) return Json.parse(raw);
            } catch (e:Dynamic) trace(e);
        }
        #end
        return null;
    }

    inline public static function parseList():ModsList {
        #if MODS_ALLOWED
        var filePath = 'modsList.txt';
        var modTime = FileSystem.exists(filePath) ? FileSystem.stat(filePath).mtime.getTime() : 0;
        if (cachedModsList == null || modTime > modsListLastRead) {
            cachedModsList = loadModsList(filePath);
            modsListLastRead = modTime;
        }
        return cachedModsList;
        #else
        return {enabled: [], disabled: [], all: []};
        #end
    }

    private static function loadModsList(filePath:String):ModsList {
        var list:ModsList = {enabled: [], disabled: [], all: []};
        try {
            for (mod in CoolUtil.coolTextFile(filePath)) {
                if (mod.trim().length < 1) continue;
                var dat = mod.split("|");
                list.all.push(dat[0]);
                if (dat[1] == "1") list.enabled.push(dat[0]);
                else list.disabled.push(dat[0]);
            }
        } catch (e) trace(e);
        return list;
    }

    private static function updateModList() {
        #if MODS_ALLOWED
        var list:Array<Array<Dynamic>> = [];
        var added = new StringMap<Bool>();
        try {
            for (mod in CoolUtil.coolTextFile('modsList.txt')) {
                var dat = mod.split("|");
                var folder = dat[0];
                if (folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) && !added.exists(folder)) {
                    added.set(folder, true);
                    list.push([folder, (dat[1] == "1")]);
                }
            }
        } catch (e) trace(e);

        for (folder in getModDirectories()) {
            if (folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) && !ignoreModFolders.contains(folder.toLowerCase()) && !added.exists(folder)) {
                added.set(folder, true);
                list.push([folder, true]);
            }
        }

        var fileStr = list.map(function(values) return values[0] + '|' + (values[1] ? '1' : '0')).join('\n');
        if (!FileSystem.exists('modsList.txt') || File.getContent('modsList.txt') != fileStr)
            File.saveContent('modsList.txt', fileStr);
        updatedOnState = true;
        #end
    }

    public static function loadTopMod() {
        currentModDirectory = '';
        #if MODS_ALLOWED
        var list = parseList().enabled;
        if (list != null && list.length > 0) currentModDirectory = list[0];
        #end
    }

    static var tempArray:Array<String> = [];
    public static function listStages(?allMods:Bool = false):Array<Array<String>> {
        tempArray = [];
        #if MODS_ALLOWED
        var directories = [
            Paths.mods('stages/'),
            Paths.mods(currentModDirectory + '/stages/'),
            Paths.getPreloadPath('stages/')
        ];
        for (mod in (allMods ? parseList().enabled : getGlobalMods()))
            directories.push(Paths.mods(mod + '/stages/'));
        #else
        var directories = [Paths.getPreloadPath('stages/')];
        #end

        var stageFile = mergeAllTextsNamed('data/stageList.txt', Paths.getPreloadPath());
        var stages:Array<String> = [];
        var stagePaths:Array<String> = [];
        var seen = new StringMap<Bool>();

        for (stage in stageFile) if (stage.trim().length > 0) {
            stages.push(stage);
            stagePaths.push('');
            seen.set(stage, true);
        }

        #if MODS_ALLOWED
        for (directory in directories) if (FileSystem.exists(directory)) {
            for (file in FileSystem.readDirectory(directory)) if (!FileSystem.isDirectory(haxe.io.Path.join([directory, file])) && file.endsWith('.json')) {
                var stageToCheck = file.substr(0, file.length - 5);
                if (stageToCheck.trim().length > 0 && !seen.exists(stageToCheck)) {
                    seen.set(stageToCheck, true);
                    stages.push(stageToCheck);
                    stagePaths.push(directory.substr('mods/'.length, directory.length - ('/stages/'.length + 'mods/'.length)));
                }
            }
        }
        #end

        if (stages.length < 1) {
            stages.push('stage');
            stagePaths.push('');
        }
        return [stages, stagePaths];
    }
}