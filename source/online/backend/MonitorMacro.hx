package online.backend;

import haxe.macro.Context;
import haxe.macro.Expr;

class MonitorMacro {
	public static macro function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();

		#if macro
		var pos:Position = Context.currentPos();

		switch (Context.getLocalType()) {
			case TInst(t, params):
				if (t.get().isInterface || t.get().isExtern || t.get().meta.has(':generic'))
					return fields;
			default:
				return fields;
		}

		var newFields = [];
		for (field in fields) {
			if (field.access.contains(AMacro) || field.access.contains(AExtern) || field.access.contains(AInline) || field.kind.getName() != "FFun")
				continue;

			if (!isMetaAllowed(field.meta)) {
				continue;
			}

			var func:Function = field.kind.getParameters()[0];
			if (func.expr == null)
				continue;

			switch (func.expr.expr) {
				case EBlock(_):
				default:
					continue;
			}

			var hasInjectedToReturn = injectBefoReturn(func.expr,
				macro online.backend.MonitorMacro.setTime($v{Context.getLocalClass().get().name + "." + field.name},
					haxe.Timer.stamp() - ___callTime));
			
			// log(Context.getLocalClass().get().pack.join('.') + Context.getLocalClass().get().name + "." + field.name);
			// log(func.expr?.expr);
			
			if (hasInjectedToReturn) {
				func.expr = macro {
					final ___callTime = haxe.Timer.stamp();
					${func.expr};
				};
			}
			else {
				func.expr = macro {
					final ___callTime = haxe.Timer.stamp();
					${func.expr};
					online.backend.MonitorMacro.setTime($v{Context.getLocalClass().get().name + "." + field.name}, haxe.Timer.stamp() - ___callTime);
				};
			}

			field.kind = FFun(func);
			fields.remove(field);
			newFields.push(field);
		}

		fields = fields.concat(newFields);
		#end

		return fields;
	}

	static function isMetaAllowed(meta:Metadata) {
		for (meta in meta) {
			if (meta.name == ':op')
				return false;
		}
		return true;
	}

	static function injectBefoReturn(expr:haxe.macro.Expr, inj:haxe.macro.Expr, ?injected:Bool = false, ?out:Bool = false) {
		switch (expr?.expr) {
			case EWhile(_, expr, _), EFor(_, expr), EUntyped(expr), EParenthesis(expr):
				if (injectBefoReturn(expr, inj, injected))
					injected = true;

			case EIf(_, expr, eelse):
				if (injectBefoReturn(expr, inj, injected))
					injected = true;

				if (eelse != null)
					if (injectBefoReturn(eelse, inj, injected))
						injected = true;

			case ETry(expr, catches):
				for (cat in catches) {
					if (injectBefoReturn(cat.expr, inj, injected))
						injected = true;
				}

				if (injectBefoReturn(expr, inj, injected))
					injected = true;

			case ETernary(_, expr, eelse):
				if (injectBefoReturn(expr, inj, injected))
					injected = true;

				if (eelse != null)
					if (injectBefoReturn(eelse, inj, injected))
						injected = true;

			case ESwitch(expr, cases, _):
				for (cas in cases) {
					if (cas.expr != null)
						if (injectBefoReturn(cas.expr, inj, injected))
							injected = true;
				}

				if (injectBefoReturn(expr, inj, injected))
					injected = true;

			case EBlock(exprs):
				for (e in exprs.copy()) {
					// if (inj != e) {
					// 	if (injectBefoReturn(e, inj, injected))
					// 		injected = true;
					// }

					if (inj != e && isReturn(e)) {
						exprs.insert(exprs.indexOf(e), inj);
						injected = true;
					}
					else {
						if (injectBefoReturn(e, inj, injected))
							injected = true;
					}
				}

			// case EReturn(_):
			// how to inject before this expr?
			// 	exprs.insert(exprs.indexOf(expr.expr), inj);
			// 	injected = true;

			default:
		}
		return injected;
	}

	static function isReturn(expr:haxe.macro.Expr):Bool {
		switch (expr?.expr) {
			case EReturn(_):
				return true;
			default:
				return false;
		}
	}

	public static function setTime(k:String, v:Float) {
		if (v < 0.05)
			return;
		#if !macro
		log('[!] Lag: $k -> ${flixel.math.FlxMath.roundDecimal(v, 2)}s');
		#end
	}

	static var logOutput:sys.io.FileOutput;
	public static inline function log(o:Dynamic) {
		Sys.println(o);
		if (logOutput == null) {
			// sys.io.File.saveContent('monitor_output.txt', '');
			logOutput = sys.io.File.append('monitor_output.txt', false);
		}
		logOutput.writeString(Std.string(o) + '\n');
		logOutput.flush();
	}
}