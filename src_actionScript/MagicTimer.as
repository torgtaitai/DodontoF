//--*-coding:utf-8-*--

package {
    import mx.containers.Box;
    import mx.events.CloseEvent;
    import mx.controls.Alert;
    
    public class MagicTimer implements Piece, InitiativedPiece {
        private var imgId:String = "0";
        private var name:String = "";
        private var info:String = "";
        private var initiative:Number = 0;
        private var timeRange:int = 0;
        private var createRound:int = 0;
        
        private var thisObj:MagicTimer;
        
        public static function getTypeStatic():String {
            return "MagicTimer"
        }
        
        public function getType():String {
            return getTypeStatic();
        }
        
        public function getTypeName():String {
            return "魔法タイマー";
        }
        
        public static function getJsonData(name_:String,
                                           timeRange_:Number,
                                           createRound_:Number,
                                           initiative_:Number,
                                           info_:String):Object {
            var jsonData:Object = new Object();
            
            jsonData.type = getTypeStatic();
            jsonData.imgId = 0;
            jsonData.name = name_;
            jsonData.info = info_;
            jsonData.initiative = initiative_;
            jsonData.createRound = createRound_;
            jsonData.timeRange = timeRange_;
            
            return jsonData;
        }
        
        public function getJsonData():Object {
            var jsonData:Object = new Object();//super.getJsonData();
            
            jsonData.type = this.getType();
            jsonData.imgId = this.getId();
            jsonData.name = this.name;
            jsonData.info = this.info;
            jsonData.initiative = this.initiative;
            jsonData.createRound = this.createRound;
            jsonData.timeRange = this.timeRange;
            
            return jsonData;
        }
        
        public function setName(name_:String):void {
            this.name = name_;
        }
        
        public function setInfo(info_:String):void {
            this.info = info_;
        }
        
        public function setInitiative(initiative_:Number):void {
            this.initiative = initiative_;
        }
        
        public function setTimeRange(timeRange_:int):void {
            this.timeRange = timeRange_;
        }
        
        public function setCreateRound(createRound_:int):void {
            this.createRound = createRound_;
        }
        
        public function MagicTimer(params:Object):void {
            this.imgId = params.imgId;
            setParams(params);
            
            thisObj = this;
        }
        
        public function getName():String {
            return name;
        }
        
        public function getAdditionalInfos():Array {
            return ["魔法タイマー 残り：" + getRestRoundLocal()  + "ラウンド"];
        }
        
        public function getInitiativeListInfo():String {
            var infoText:String = "";
            infoText += info;
            return infoText;
        }
        
        public function isHideMode():Boolean {
            return false;
        }
        
        public function getInfo():String {
            return info;
        }
        
        public function getCounter(key:String):int {
            return 0;
        }
        
        public function setCounter(key:String, value:int):void {
        }
        
        public function getInitiative():Number {
            return initiative;
        }
        
        private function getRestRoundLocal():int {
            return MagicRange.getRestRound(this.timeRange, this.createRound, this.initiative);
        }
        
        public function isDead():Boolean {
            return ( getRestRoundLocal() <= 0 );
        }
        
        public function popUpChangeWindow():void {
            var dodontoF:DodontoF = DodontoF_Main.getInstance().getDodontoF();
            
            ChangeMagicTimerWindow.setMagicTimer(this);
            DodontoF.popup(ChangeMagicTimerWindow, true);
        }
        
        public function sendDelete():void {
            DodontoF_Main.getInstance().getMap().removeExistPieces(this);
            DodontoF_Main.getInstance().getInitiativeWindow().refresh();
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.removeCharacter(thisObj);
        }
        
        public function isGotoGraveyard():Boolean {
            return true;
        }
        
        public function popUpDeleteWindow():void {
            Alert.show("魔法タイマー「" + this.name + "」を削除してもよろしいですか？", "削除確認",
                       Alert.OK | Alert.CANCEL,
                       null,
                       function(e : CloseEvent) : void {
                           if (e.detail == Alert.OK) {
                               sendDelete();
                           }
                       });
        }
        
        private var lastParams:Object = null;
        public function analyzeChangedCharacter(params:Object):Boolean {
            if( ! MovablePiece.isChangedParam(params, this.lastParams) ) {
                return false;
            }
            
            setParams(params);
            return true;
        }
        
        public function getTimeRange():int {
            return this.timeRange;
        }
        
        public function getCreateRound():int {
            return this.createRound;
        }
        
        private function setParams(params:Object):void {
            this.name = params.name;
            this.info = params.info;
            this.initiative = params.initiative;
            this.createRound = params.createRound;
            this.timeRange = params.timeRange;
        }
        
        public function getId():String {
            return imgId;
        }
        
        public function canDeleteOnInitiativeList():Boolean {
            return true;
        }
        
        public function getToolTipMessage():String {
            return Utils.getToolTipMessage(this);
        }
        
        //動かさない場合は不要なIF
        //public function setInitiativeItem(initiativeItem_:Box):void {}
        public function setClickEvent(func:Function):void {}
        public function pickup():void {}
        public function pickupToCenter():void {}
        public function pickupOnInitiative():void {}
        public function init(map_:Map, x:Number, y:Number):void {}
        public function getX():Number {return 0;}
        public function getY():Number {return 0;}
        public function getViewX():Number {return 0;}
        public function getViewY():Number {return 0;}
        public function getDraggable():Boolean {return false;}
        public function setDraggable(value:Boolean):void {}
        public function stopDragging():void {}
        public function setViewForeground():void {}
        public function move(x:Number, y:Number, isForce:Boolean = false):Boolean {return false;}
        public function isOnlyOwnMap():Boolean {return false;}
        public function remove():void {}
        public function hasStatus():Boolean {return false;}
        public function getStatusName(key:String):String {return "";}
        public function getUrl():String {return "";}
   }
}