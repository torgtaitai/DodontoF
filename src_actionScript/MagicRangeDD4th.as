//--*-coding:utf-8-*--

package {
    
    public class MagicRangeDD4th  extends MagicRange {
        public function MagicRangeDD4th(params:Object) {
            super(params);
        }
        
        
        public static function getTypeStatic():String {
            return "magicRangeMarkerDD4th"
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return "魔法範囲D&D4版";
        }
        
        public static function getJsonData(name:String,
                                           feets:int,
                                           type:String,
                                           color:String,
                                           timeRange:Number,
                                           createRound:Number,
                                           initiative:Number,
                                           info:String,
                                           characterPositionX:int,
                                           characterPositionY:int):Object {
            var characterJsonData:Object = {
                "feets": feets,
                "rangeType": type,
                "color": color,
                "createRound": createRound,
                "timeRange": timeRange,
                
                "imageName": "",
                "name": name,
                "size": 0,
                "initiative": initiative,
                "info": info,

                "imgId": "0",
                "type": getTypeStatic(),
                "x": characterPositionX,
                "y": characterPositionY,
                "draggable": true
            };
            
            return characterJsonData;
        }
        
        static private var closeBurst:Object = {data:"closeBurstDD4th",
                                               label: "爆発"};
        
        static private var blast:Object = {data:"blastDD4th",
                                           label: "噴射"};
        
        [Bindable]
            static public var rangeTypes:Array = [closeBurst, blast];
        
        override public function popUpChangeWindow():void {
            try {
                var window:ChangeMagicRangeDD4thWindow =
                    DodontoF.popup(ChangeMagicRangeDD4thWindow, true) as ChangeMagicRangeDD4thWindow;
                
                window.setMagicRange(this);
            } catch(e:Error) {
                Log.loggingException("MagicRange.popUpChangeWindow()", e);
            }
        }
        
        override protected function initDrawRange():void {
            loadViewImage();
            initDrawSquareDD4th();
        }
        
        override public function loadViewImage():void {
            var size:int = 0;
            if( this.getRangeType() == closeBurst.data ) {
                size = 1;
            }
            view.setIsDrawRound(false);
            view.loadImage(this.name, getCenterImageUrl(), size);
        }
        
        private function initDrawSquareDD4th():void {
            view.graphics.lineStyle(0, 0x000000);
            view.graphics.beginFill(getColor(), 0.5);
            
            var radius:int = getRadius();
            
            if( this.getRangeType() == closeBurst.data ) {
                view.graphics.drawRect( radius * getSquareLength() * -1,
                                        radius * getSquareLength() * -1,
                                        (radius * 2 + 1) * getSquareLength(),
                                        (radius * 2 + 1) * getSquareLength() );
                                        
            } else if( this.getRangeType() == blast.data ) {
                view.graphics.drawRect( 0,
                                        0,
                                        radius * getSquareLength(),
                                        radius * getSquareLength() );
            } else {
                Log.loggingError("MagicRangeDD4th.initDrawSquareDD4th rangeType is invalid", this.getRangeType());
            }
            
            view.graphics.endFill();
        }
        
    }
}

