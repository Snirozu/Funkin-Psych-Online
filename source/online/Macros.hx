package online;

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
                    if (meta.name == ":forwardField") {
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
								expr: macro {
									if (${meta.params[0]} == null)
										${meta.params[0]} = ${meta.params[1]};

                                    return ${meta.params[0]}
                                }
                            }),
                            pos: pos,
                        });

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
}