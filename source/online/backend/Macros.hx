package online.backend;

import haxe.macro.Context;
import haxe.macro.Expr;

class Macros {
	public static macro function getSetForwarder():Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();

        for (field in fields) {
			if (field.meta != null)
                for (meta in field.meta) {
                    // for some reason semicolon is needed
                    if (meta.name == ":forwardField" || meta.name == ":forwardGetter") {
						if (meta.params[0] == null)
                            break;

                        var fieldAccess:Array<Access> = [APrivate, AInline];
						if (field.access.contains(Access.AStatic))
                            fieldAccess.push(Access.AStatic);

                        fields.push({
                            name: "get_" + field.name,
                            access: fieldAccess,
                            kind: FieldType.FFun({
                                args: [],
								expr: meta.name == ":forwardGetter" || meta.params[1] == null ?
									macro {
										return ${meta.params[0]}
									}
								: macro {
									if (${meta.params[0]} == null)
										${meta.params[0]} = ${meta.params[1]};

                                    return ${meta.params[0]}
                                }
                            }),
                            pos: pos,
                        });

						if (meta.name != ":forwardGetter") {
							fields.push({
								name: "set_" + field.name,
								access: fieldAccess,
								kind: FieldType.FFun({
									args: [
										{
											name: "value"
										}
									],
									expr: macro return ${meta.params[0]} = value
								}),
								pos: pos,
							});
						}
                        break;
                    }
                }
        }

        return fields;
    }

	// from https://code.haxe.org/category/macros/add-git-commit-hash-in-build.html
	public static macro function getGitCommitHash():ExprOf<String> {
		var process = new sys.io.Process('git', ['rev-parse', 'HEAD']);
		if (process.exitCode() != 0) {
			var message = process.stderr.readAll().toString();
			var pos = Context.currentPos();
			Context.error("Cannot execute `git rev-parse HEAD`. " + message, pos);
		}

		// read the output of the process
		var commitHash:String = process.stdout.readLine();

		// Generates a string expression
		return macro $v{commitHash};
	}

	public static macro function hasNoCapacity():ExprOf<Bool> {
		var p = new sys.io.Process("git", ["config", "--get", "remote.origin.url"]);
		return macro $v{false};
	}

    
	public static macro function nullFallFields():Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();

		for (field in fields) {
			if (field.meta != null)
				for (meta in field.meta) {
					if (meta.name == ":fall") {
						switch (field.kind) {
							case FProp(get, set, type, expr):
								if (meta.params[0] == null) {
									throw 'no fall value set for field: ' + field.name;
                                }

								var fieldAccess:Array<Access> = [APrivate, AInline];
								if (field.access.contains(Access.AStatic))
									fieldAccess.push(Access.AStatic);

								fields.push({
									name: "get_" + field.name,
									access: fieldAccess,
									kind: FieldType.FFun({
										args: [],
										expr: macro {
											if ($i{field.name} == null)
												return cast ${meta.params[0]};

											return $i{field.name};
										},
                                        ret: type
									}),
									pos: pos,
								});
                                break;
                            // todo: add FVar to automatically convert it to FProp
							default:
								throw field.kind + " unsupported, make sure it's " + field.name + '(get, ...)';
                        }
					}
				}
		}

		return fields;
	}
}