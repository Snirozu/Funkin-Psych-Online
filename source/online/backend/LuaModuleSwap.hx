package online.backend;

import psychlua.FunkinLua;
import sys.io.FileOutput;
import sys.io.FileInput;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

class LuaModuleSwap {
	public static function doLua(lua:llua.State, originPath:String, ?stopFunc:Void->Void) {
		originPath = Path.normalize(originPath);

		var launchTime:Float = haxe.Timer.stamp();
		
		//ignore fields of the module that is require'd
		final ignoreFields = [
			'jit',
			'bit',
			'package',
			'coroutine',
			'_G',
			'os',
			'string',
			'table',
			'io',
			'math'
		];

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
					// try {
					// 	Lua.error(lua);
					// } catch (exc) {}
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
		set(lua, 'require', function(?module:String):Dynamic {
			switch (module) {
				//have you ever wanted movies free
				case 'ffi':
					return {
						cdef: function(def:String) {
							return;
						},
						C: {},
						load: function(name:String, ?global:String) {
							return {};
						},
						"new": function(ct:Dynamic, ?nelem:Dynamic, ?init:Dynamic) {
							return {};
						},
						typeof: function(ct:Dynamic) {
							return {};
						},
						"cast": function(ct:Dynamic, init:Dynamic) {
							return {};
						},
						metatype: function(ct:Dynamic, metatable:Dynamic) {
							return null;
						},
						gc: function(cdata:Dynamic, finalizer:Dynamic) {
							return null;
						},
						sizeof: function(ct:Dynamic, ?nelem:Dynamic) {
							return haxe.Json.parse(ct)?.length;
						},
						alignof: function(ct:Dynamic) {
							return 0;
						},
						offsetof: function(ct:Dynamic, field:Dynamic) {
							return 0;
						},
						istype: function(ct:Dynamic, obj:Dynamic) {
							return false;
						},
						errno: function(?newerr:Dynamic) {
							return 0;
						},
						string: function(ptr:Dynamic, ?len:Dynamic) {
							return null;
						},
						copy: function(dst:Dynamic, ?srcOrStr:Dynamic, ?len:Dynamic) {
							return;
						},
						fill: function(dst:Dynamic, len:Dynamic, ?c:Dynamic) {
							return;
						},
						abi: function(param:String) {
							return false;
						},

						#if windows
						os: 'Windows',
						#elseif linux
						os: 'Linux',
						#elseif mac
						os: 'OSX',
						#else
						os: 'Other',
						#end

						#if (HXCPP_M32 || HXCPP_X86)
						arch: 'x86',
						#elseif HXCPP_M64
						arch: 'x64',
						#elseif (HXCPP_ARM64 || HXCPP_LINUX_ARM64)
						arch: 'arm64',
						#elseif (HXCPP_ARMV6 || HXCPP_ARMV7 || HXCPP_ARMV7S || HXCPP_LINUX_ARMV7) 
						arch: 'arm',
						#else
						arch: null
						#end
					};
			}

			if (!module.endsWith('.lua')) {
				module += '.lua';
			}

			if (!FileSystem.exists(filePath(module))) {
				var pathSplit = originPath.split('/');
				pathSplit.pop();
				var relativePath = pathSplit.join('/');
				module = Path.join([relativePath, module]);
			}

			if (FileSystem.exists(filePath(module))) {
				var funkinLua = new FunkinLua(module);
				var lua = funkinLua.lua;

				// https://stackoverflow.com/a/46374744
				var fields:Array<String> = [];
				Lua.pushvalue(lua, Lua.LUA_GLOBALSINDEX); // Get global table
				Lua.pushnil(lua); // put a nil key on stack
				while (Lua.next(lua, -2) != 0) { // key(-1) is replaced by the next key(-1) in table(-2)
					fields.push(Lua.tostring(lua, -2)); // Get key(-2) name
					Lua.pop(lua, 1); // remove value(-1), now key on top at(-1)
				}
				Lua.pop(lua, 1); // remove global table(-1)

				var obj:Dynamic = {};
				
				for (field in fields) {
					if (ignoreFields.contains(field))
						continue;

					Lua.getglobal(lua, field);
					var luaType = Lua.type(lua, -1);
					Lua.pop(lua, 1);

					switch (luaType) {
						case Lua.LUA_TFUNCTION:
							// doesn't workkkkggghh....
							// Reflect.setField(obj, field, function(...params:Dynamic) {
							// 	return funkinLua.call(field, params);
							// });

							// supports up to 10 arguments/parameters
							Reflect.setField(obj, field, function(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic, ?v6:Dynamic, ?v7:Dynamic, ?v8:Dynamic, ?v9:Dynamic, ?v10:Dynamic) {
								return funkinLua.call(field, [v1, v2, v3, v4, v5, v6, v7, v8, v9, v10]);
							});
						default:
							// global fields aren't really used in fnf scripts idk 
							// they will always have the initial value so use getfield() and setfield(v) instead when scripting
							// also if anyone knows how to make global fields work properly then do a cool pr

							try {
								Lua.getglobal(lua, field);
								var result = Convert.fromLua(lua, -1);
								Lua.pop(lua, 1);

								Reflect.setField(obj, field, result);
							} catch (exc) {
								if (backend.ClientPrefs.isDebug()) {
									trace(field);
									trace(exc);
								}
							}

							if (!Reflect.hasField(obj, 'get' + field))
								Reflect.setField(obj, 'get' + field, function() {
									Lua.getglobal(lua, field);
									var result = Convert.fromLua(lua, -1);
									Lua.pop(lua, 1);
									return result;
								});

							if (!Reflect.hasField(obj, 'set' + field))
								Reflect.setField(obj, 'set' + field, function(v:Dynamic) {
									funkinLua.set(field, v);
									return v;
								});
					}
				}

				return obj;
			}

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
		if (path.endsWith('lib') || path.endsWith('dll') || path.endsWith('exe')) {
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
		LuaModuleSwap.doLua(instance.__lua, instance.__scriptPath);
	}
}
#end