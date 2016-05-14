//--*-coding:utf-8-*--

package {
    import mx.containers.Box;
    
    public interface InitiativedPiece {
        function getName():String;
        function getAdditionalInfos():Array;
        function getInfo():String;
        function isCounterExist(key:String):Boolean;
        function getCounter(key:String):int;
        function setCounter(key:String, value:int):int;
        function setInfo(info_:String):void;
        function getJsonData():Object;
        function getInitiative():Number;
        function setInitiative(initiative_:Number):void;
        function isHideMode():Boolean;
        function isDead():Boolean;
        function popUpChangeWindow():void;
        function popUpDeleteWindow():void;
        function setClickEvent(func:Function):void;
        function getToolTipMessage():String;
        function pickup():void;
        function pickupToCenter():void;
        function pickupOnInitiative():void;
        function canDeleteOnInitiativeList():Boolean;
        function sendDelete():void;
        function hasStatus():Boolean;
        function getStatusName(key:String):String;
        function getUrl():String;
        function updateRefresh():void;
    }
}
