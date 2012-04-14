//--*-coding:utf-8-*--

package {
    public interface Piece {
        function getType():String;
        function getTypeName():String;
        function getX():Number;
        function getY():Number;
        function getViewX():Number;
        function getViewY():Number;
        function getDraggable():Boolean;
        function getJsonData():Object;
        function init(map_:Map, x:Number, y:Number):void;
        function remove():void;
        function setDraggable(value:Boolean):void;
        function setViewForeground():void;
        function stopDragging():void;
        function analyzeChangedCharacter(params:Object):Boolean;
        function move(x:Number, y:Number, isForce:Boolean = false):Boolean;
        function getId():String;
        function isOnlyOwnMap():Boolean;
        function isGotoGraveyard():Boolean;
        function getName():String;
   }
}