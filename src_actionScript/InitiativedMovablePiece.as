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
    
    public class InitiativedMovablePiece extends MovablePiece implements InitiativedPiece {
        
        protected var name:String = "";
        protected var info:String = "";
        protected var initiative:Number = 0;
        protected var counters:Object = new Object();
        
        //private var initiativeItem:mx.containers.Box;
        private var clickEvent:Function = null;
        private var thisObj:InitiativedMovablePiece;

        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.name = getName();
            jsonData.initiative = getInitiative();
            jsonData.info = getInfo();
            jsonData.counters = counters;
            
            return jsonData;
        }
        
        
        public function InitiativedMovablePiece(params:Object) {
            name = params.name;
            initiative = params.initiative;
            info = params.info;
            setCounters( params.counters );
            
            thisObj = this;
            
            super(params);
        }
        
        public function setCounters(obj:Object):void {
            if( obj == null ) {
                counters = new Object();
            } else {
                counters = obj;
            }
        }
        
        public function getName():String {
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
        
        public function getInitiative():Number {
            return initiative;
        }
        
        public function setInitiative(initiative_:Number):void {
            this.initiative = initiative_;
        }
        
        public function isDead():Boolean {
            return false;
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
            
            setToolTip();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged Initiatived changed End");
        }
        
        public function setToolTip():void {
            view.toolTip = getToolTipMessage();
        }
        
        public function getToolTipMessage():String {
            return Utils.getToolTipMessage(this);
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
            this.snapMovablePieceViewPosition();
            
            DodontoF_Main.getInstance().getDodontoF().getGlowEffect().end();
            DodontoF_Main.getInstance().getDodontoF().getGlowEffect().play( [view] );
        }
        
        public function pickupToCenter():void {
            getMap().centeringFromPiece(this);
        }
        
        public function canDeleteOnInitiativeList():Boolean {
            return false;
        }
   }
}