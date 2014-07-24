//--*-coding:utf-8-*--

package {
    
    import flash.events.MouseEvent;
    import flash.display.Sprite;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.text.TextFieldAutoSize;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.geom.Point;
    import mx.managers.PopUpManager;
    import mx.containers.Box;
    import mx.effects.Glow;
    import mx.events.ToolTipEvent;
    
    public class InitiativedMovablePiece extends MovablePiece implements InitiativedPiece {
        
        protected var name:String = "";
        protected var info:String = "";
        protected var initiative:Number = 0;
        protected var counters:Object = new Object();
        protected var statusAlias:Object = new Object();
        
        //private var initiativeItem:mx.containers.Box;
        private var clickEvent:Function = null;
        private var thisObj:InitiativedMovablePiece;

        public static function getJsonData(type:String,
                                           name:String,
                                           initiative:Number,
                                           info:String,
                                           counters:Object,
                                           statusAlias:Object,
                                           createPositionX:Number,
                                           createPositionY:Number, 
                                           draggable:Boolean,
                                           rotation:Number = 0):Object {
            
            var jsonData:Object = MovablePiece.getJsonData(type,
                                                           createPositionX,
                                                           createPositionY,
                                                           draggable,
                                                           rotation);
            
            jsonData.name = name;
            jsonData.initiative = initiative;
            jsonData.info = info;
            jsonData.counters = counters;
            jsonData.statusAlias = statusAlias;
            
            return jsonData;
        }
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.name = getName();
            jsonData.initiative = getInitiative();
            jsonData.info = getInfo();
            jsonData.counters = counters;
            jsonData.statusAlias = statusAlias;
            
            return jsonData;
        }
        
        
        public function InitiativedMovablePiece(params:Object) {
            this.name = params.name;
            this.initiative = params.initiative;
            this.info = params.info;
            setCounters( params.counters );
            setStatusAlias( params.statusAlias );
            
            thisObj = this;
            
            super(params);
            
            view.addEventListener(ToolTipEvent.TOOL_TIP_CREATE, createCustomTip);
        }
        
        public function setCounters(obj:Object):void {
            this.counters = getObjectFromParamObject(obj);
        }
        
        public function setStatusAlias(obj:Object):void {
            Log.logging("setStatusAlias obj", obj);
            this.statusAlias = getObjectFromParamObject(obj);
            Log.logging("setStatusAlias statusAlias", statusAlias);
        }
        
        public function getObjectFromParamObject(obj:Object):Object {
            if( obj == null ) {
                return new Object();
            } else {
                return obj;
            }
        }
        
        override public function getName():String {
            return name;
        }
        
        public function setName(name_:String):void {
            this.name = name_;
        }
        
        public function getAdditionalInfos():Array {
            return [];
        }
        
        public function getInfo():String {
            return info;
        }
        
        public function setInfo(info_:String):void {
            this.info = info_;
        }
        
        public function getCounter(key:String):int {
            return parseInt(counters[key]);
        }
        
        public function setCounter(key:String, value:int):void {
            if( key == null ) {
                return;
            }
            counters[key] = value;
        }
        
        public function getStatusName(key:String):String {
            Log.logging("getStatusName key", key);
            
            var checkBoxInfo:Object = InitiativeWindow.getCheckBoxInfoFromCounterName(key);
            Log.logging("checkBoxInfo", checkBoxInfo);
            
            var name:String = statusAlias[checkBoxInfo.title];
            if( name == null ) {
                name = "";
            }
            
            Log.logging("getStatusName name", name);
            return name;
        }
        
        public function getStatusAlias():Object {
            return Utils.clone(this.statusAlias);
        }
        
        public function getInitiative():Number {
            return initiative;
        }
        
        public function setInitiative(initiative_:Number):void {
            this.initiative = initiative_;
        }
        
        public function isDead():Boolean {
            return false;
        }
        
        public function getUrl():String {
            return "";
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>InitiativedMovablePiece update Begin");
            
            super.update(params);
            
            Log.logging("params.name", params.name);
            Log.logging("params.initiative", params.initiative);
            Log.logging("params.info", params.info);
            this.name = params.name;
            this.initiative = params.initiative;
            this.info = params.info;
            setCounters( params.counters );
            setStatusAlias( params.statusAlias );
            
            setToolTip();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged Initiatived changed End");
        }
        
        public function getStatusInfos():Array {
            var window:InitiativeWindow = DodontoF_Main.getInstance().getInitiativeWindow();
            if( window == null ) {
                return [];
            }
            
            return window.getCheckBoxInfos();
        }
        
        private function createCustomTip(event:ToolTipEvent):void {
            var toolTip:PieceToolTip = new PieceToolTip();
            toolTip.setPiece(this);
            event.toolTip = toolTip;
        }
        
        private function positionTip(event:ToolTipEvent):void{
            event.toolTip.x = event.currentTarget.x + event.currentTarget.width + 10;
            event.toolTip.y = event.currentTarget.y;
        }
        
        
        public function setToolTip():void {
            view.toolTip = getToolTipMessage();
        }
        
        public function getToolTipMessage():String {
            return Config.getInstance().getToolTipMessage(this);
        }
        
        protected function getItemPopUpChangeWindow(event:ContextMenuEvent):void {
            popUpChangeWindow();
        }
        
        public function popUpChangeWindow():void {
            throwNotImplimentedError("popUpChangeWindow");
        }
        
        public function popUpDeleteWindow():void {
            throwNotImplimentedError("popUpDeleteWindow");
        }
        
        
        public function setClickEvent(clickEvent_:Function):void {
            clickEvent = clickEvent_;
        }
        
        override protected function initEvent():void {
            view.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
                    pickupOnInitiative();
                });
            view.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
                    pickupOnInitiative();
                });
        }
        
        public function pickupOnInitiative():void {
            if( thisObj.clickEvent == null ) {
                return;
            }
            
            thisObj.clickEvent();
        }
        
        public function pickup():void {
            //map.centeringFromPiece(this);
            
            setViewForeground();
            this.setPickuped();
            
            Utils.glowEffect( view );
        }
        
        public function pickupToCenter():void {
            getMap().centeringFromPiece(this);
        }
        
        public function canDeleteOnInitiativeList():Boolean {
            return false;
        }
        
        public function hasStatus():Boolean {
            return false;
        }
        
   }
}
