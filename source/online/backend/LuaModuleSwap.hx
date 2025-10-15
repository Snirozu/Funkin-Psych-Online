package online.backend;

import sys.io.FileOutput;
import sys.io.FileInput;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

class LuaModuleSwap {
	public static function doLua(lua:llua.State, ?stopFunc:Void->Void) {
		var launchTime:Float = haxe.Timer.stamp();

		set(lua, 'os', {
			clock: function() {
				return haxe.Timer.stamp() - launchTime;
			},
			date: function(?format:String = "%a %b %d %H:%M:%S %Y", ?time:Float) {
				var date = time == null ? Date.now() : Date.fromTime(time);
				return DateTools.format(date, format);
			},
			difftime: function(t2:Float, t1:Float) {
				return t2 - t1;
			},
			execute: function(?command:String) {
				return null;
			},
			exit: function(?code:Int, ?close:Bool) {
				if (stopFunc != null)
					stopFunc();
				else {
					try {
						Lua.error(lua);
					} catch (exc) {}
					Lua.close(lua);
				}
			},
			getenv: function(varname:String) {
				return Sys.getEnv(varname);
			},
			remove: function(filename:String) {
				return File.getContent(filePath(filename));
			},
			rename: function(oldname:String, newname:String) {
				FileSystem.rename(filePath(oldname), filePath(newname));
			},
			setlocale: function(locale:String, ?category:String) {
				return null;
			},
			time: function(?table:Dynamic) {
				table ??= {};
				return new Date(table.year ?? 1970, (table.month ?? 0) + 1, table.day ?? 1, table.hour ?? 0, table.min ?? 0, table.sec ?? 0);
			},
			tmpname: function() {
				return null;
			}
		});

		// note that this isn't supposed to replicate how luas file handling works accurately
		// there are some missing functionalities but it should work for most if not all mods
		var files:Map<String, Dynamic> = new Map();
		function newFile(input:FileInput, output:FileOutput) {
			return {
				close: function() {
					if (input != null)
						input.close();
					if (output != null)
						output.close();
				},
				flush: function() {
					if (output != null)
						output.flush();
				},
				lines: function(?format:Any) {
					if (input == null)
						return null;
					return [for (char in bytesToStr(cast input.readAll().getData()).split('')) char];
				},
				read: function(?mode:Any = 'a') {
					if (input == null)
						return null;

					switch (mode) {
						case "*all", 'a':
							return bytesToStr(input.readAll().getData());
						case "*line", 'l':
							var str = '';
							for (char in bytesToStr(cast input.readAll().getData()).split('')) {
								if (char == '\n') {
									break;
								}
							}
							return str;
					}
					return bytesToStr(input.read(mode).getData());
				},
				seek: function(?whence:String = 'set', ?offset:Int = 0) {
					switch (whence) {
						case "set":
							if (input != null)
								input.seek(offset, sys.io.FileSeek.SeekBegin);
							if (output != null)
								output.seek(offset, sys.io.FileSeek.SeekBegin);
						case "cur":
							if (input != null)
								input.seek(offset, sys.io.FileSeek.SeekCur);
							if (output != null)
								output.seek(offset, sys.io.FileSeek.SeekCur);
						case "end":
							if (input != null)
								input.seek(offset, sys.io.FileSeek.SeekEnd);
							if (output != null)
								output.seek(offset, sys.io.FileSeek.SeekEnd);
					}
				},
				setvbuf: function(mode:String, ?size:Float) {
					throw 'Not implemented yet.';
				},
				write: function(str:String) {
					output.writeString(str);
				}
			};
		}

		set(lua, 'io', {
			open: function(filename:String, ?mode:String = 'r') {
				var fileInput:FileInput = null;
				var fileOutput:FileOutput = null;
				switch (mode) {
					case 'r', 'rb':
						fileInput = File.read(filePath(filename), mode.endsWith('b'));
						fileOutput = null;
					case 'w', 'wb':
						fileInput = null;
						fileOutput = File.write(filePath(filename), mode.endsWith('b'));
					case 'a', 'ab':
						fileInput = null;
						fileOutput = File.append(filePath(filename), mode.endsWith('b'));
					case 'r+', 'r+b':
						fileInput = File.read(filePath(filename), mode.endsWith('b'));
						fileOutput = File.update(filePath(filename), mode.endsWith('b'));
					case 'w+', 'w+b':
						fileInput = File.read(filePath(filename), mode.endsWith('b'));
						fileOutput = File.write(filePath(filename), mode.endsWith('b'));
					case 'a+', 'a+b':
						fileInput = File.read(filePath(filename), mode.endsWith('b'));
						fileOutput = File.append(filePath(filename), mode.endsWith('b'));
				}
				var file = newFile(fileInput, fileOutput);
				files.set(filename, file);
				file.close = function() {
					if (fileInput != null)
						fileInput.close();
					if (fileOutput != null)
						fileOutput.close();
					files.remove(filename);
				};
				return file;
			},
			close: function(?filename:String) {
				files.get(filename).close();
			},
			flush: function(?filename:String) {
				files.get(filename).flush();
			},
			input: function(?filename:String) {
				return files.get(filename);
			},
			lines: function(?filename:String, ?format:Any) {
				return files.get(filename).lines(format);
			},
			output: function(?filename:String) {
				return files.get(filename);
			},
			popen: function(prog:String, ?mode:String) {
				throw 'Not implemented yet.';
			},
			read: function(?filename:String, ?mode:Any = 'a') {
				return files.get(filename).read(mode);
			},
			tmpfile: function(?filename:String) {
				throw 'Not implemented yet.';
			},
			type: function(obj:Any) {
				if (obj == null) {
					return null;
				}
				if (files.exists(obj)) {
					return 'file';
				}
				return 'closed file';
			},
			write: function(?filename:String, ?str:String) {
				return files.get(filename).write(str);
			}
		});
		set(lua, 'require', function(?module:String) {
			return null;
		});
		set(lua, 'debug', null);
	}

	static function set(lua:llua.State, name:String, value:Dynamic) {
		if (Reflect.isFunction(value)) {
			Lua_helper.add_callback(lua, name, value);
			return;
		}

		Convert.enableUnsupportedTraces = true;
		Convert.toLua(lua, value);
		Lua.setglobal(lua, name);
	}

	static function filePath(path:String) {
		path = path.trim();
		if (path.endsWith('dll') || path.endsWith('exe')) {
			return null;
		}
		return Path.join([Sys.getCwd(), path]);
	}

	static function bytesToStr(byte:haxe.io.BytesData) {
		return haxe.io.Bytes.ofData(byte).toString();
	}
}

#if lumod
class LumodModuleAddon extends lumod.addons.LumodAddon {
	override function init() {
		LuaModuleSwap.doLua(instance.__lua);
	}
}
#end