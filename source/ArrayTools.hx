package;

@:publicFields
class ArrayTools {
    static function pushOnce<T>(array:Array<T>, v:T) {
        if (array.contains(v))
            return array.length;
        return array.push(v);
    }
}