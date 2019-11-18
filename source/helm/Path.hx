package helm;

using StringTools;

@:forward(split)
abstract Path(String) to String
{
    @:from
    public static function fromString(path:String):Path
    {
        return cast(path, Path);
    }

    public var delimeter(get, never):String;
    private inline function get_delimeter():String
    {
        return this.indexOf('\\') == -1 ? '/' : '\\';
    }

    /**
     * Returns the last value of the path
     * @param extension Optional string to remove the extension from the result
     */
    public function basename(?extension:String):String
    {
        var parts = this.split(delimeter);
        var last = parts[parts.length - 1];
        return extension == null ? last : StringTools.replace(last, extension, '');
    }

    /**
     * Returns the first part of the
     */
    public function dirname():Path
    {
        var parts = this.split(delimeter);
        parts.pop();
        return parts.join(delimeter);
    }

    public function normalize():Path
    {
        var parts = this.split(delimeter);
        var result = [];
        for (i in 0...parts.length)
        {
            var part = parts[i];
            if (part == '..') // remove up one directory
            {
                result.pop();
            }
            else if (part == '') // remove empty paths, except first and last
            {
                if (i == 0 || i == parts.length - 1) {
                    result.push(part);
                }
            }
            else if (part == '.') // remove single dot paths, unless it comes first
            {
                if (i == 0) {
                    result.push(part);
                }
            }
            else // all other paths are ok to add
            {
                result.push(part);
            }
        }
        return result.join(delimeter);
    }

    public function join(path:Path):Path
    {
        var result = this;
        var delim = delimeter; // only call function once
        if (!result.endsWith(delim)) {
            result += delim;
        }
        return result + path.split(path.delimeter).join(delim);
    }
}
