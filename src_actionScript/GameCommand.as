//--*-coding:utf-8-*--

package {
    public interface GameCommand {
        function executeCommand(params:Object):void;
        function getGameType():String;
   }
}