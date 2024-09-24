package online.macro;

import haxe.rtti.Meta;
import haxe.macro.Context;

//
// from v-slice source code
//

@:unreflective
class CompiledClassList
{
  public static macro function listClassesInPackage(targetPackage:String, includeSubPackages:Bool = true):ExprOf<Iterable<Class<Dynamic>>>
  {
    if (!onGenerateCallbackRegistered)
    {
      onGenerateCallbackRegistered = true;
    }

    var request:String = 'package~${targetPackage}~${includeSubPackages ? "recursive" : "nonrecursive"}';

    classListsToGenerate.push(request);

		return macro CompiledClassList.get($v{request});
  }

	@:unreflective static var classLists:Map<String, List<Class<Dynamic>>>;

  /**
   * Class lists are injected into this class's metadata during the typing phase.
   * This function extracts the metadata, at runtime, and stores it in `classLists`.
   */
  static function init():Void
  {
    classLists = [];

    // Meta.getType returns Dynamic<Array<Dynamic>>.
    var metaData = Meta.getType(CompiledClassList);

    if (metaData.classLists != null)
    {
      for (list in metaData.classLists)
      {
        var data:Array<Dynamic> = cast list;

        // First element is the list ID.
        var id:String = cast data[0];

        // All other elements are class types.
        var classes:List<Class<Dynamic>> = new List();
        for (i in 1...data.length)
        {
          var className:String = cast data[i];
          // var classType:Class<Dynamic> = cast data[i];
          var classType:Class<Dynamic> = cast Type.resolveClass(className);
          classes.push(classType);
        }

        classLists.set(id, classes);
      }
    }
    else
    {
      throw "Class lists not properly generated. Try cleaning out your export folder, restarting your IDE, and rebuilding your project.";
    }
  }

  public static function get(request:String):List<Class<Dynamic>>
  {
    if (classLists == null) init();

    if (!classLists.exists(request))
    {
      trace('[WARNING] Class list $request not properly generated. Please debug the build macro.');
      classLists.set(request, new List()); // Make the error only appear once.
    }

    return classLists.get(request);
  }

  public static inline function getTyped<T>(request:String, type:Class<T>):List<Class<T>>
  {
    return cast get(request);
  }

	static var onGenerateCallbackRegistered:Bool = false;
	static var classListsToGenerate:Array<String> = [];
}
