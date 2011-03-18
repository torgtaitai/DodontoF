package {
    import flash.external.ExternalInterface;
    import flash.utils.getQualifiedClassName;

    public function logAny(... args):void {
        var inspect:Function = function(arg:*, bracket:Boolean = true):String {
            var className:String = getQualifiedClassName(arg);
            var str:String;

            switch(getQualifiedClassName(arg)) {
                case 'Array':
                    var results:Array = [];
                    for (var i:uint = 0; i < arg.length; i++) {
                        results.push(inspect(arg[i]));
                    }
                    if (bracket) {
                        str = '[' + results.join(', ') + ']';
                    } else {
                        str = results.join(', ');
                    }
                    break;
                case 'int':
                case 'uint':
                case 'Number':
                    str = arg.toString();
                    break;
                case 'String':
                    str = arg;
                    break;
                default:
                    str = '#<' + className + ':' + String(arg) + '>';
            }
            return str;
        }

        var r:String = inspect(args, false);
        trace(r);
        ExternalInterface.call('console.log', r);
    }
}
