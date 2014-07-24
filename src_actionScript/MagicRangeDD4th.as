//--*-coding:utf-8-*--

package {
    
    public class MagicRangeDD4th extends MagicRange {
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
            return Language.s.magicRangeDD4th;
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
                                           characterPositionY:int,
                                           isHide:Boolean):Object {
            var draggable:Boolean = true;
            var counters:Object = null;
            var statusAlias:Object = null;
            var rotation:Number = 0;
            
            var jsonData:Object = 
                InitiativedMovablePiece.getJsonData(getTypeStatic(),
                                                    name, initiative, info, counters, statusAlias,
                                                    characterPositionX, characterPositionY,
                                                    draggable, rotation);
            jsonData.feets = feets;
            jsonData.rangeType = type;
            jsonData.color = color;
            jsonData.createRound = createRound;
            jsonData.timeRange = timeRange;
            jsonData.isHide = isHide;
                
            jsonData.imageName = "";
            jsonData.size = 0;
            
            return jsonData;
        }
        
        static public function get closeBurst():Object {
            return {data:"closeBurstDD4th",
                    label: Language.s.closeBurstDD4th};
        }
        
        static public function get blast():Object {
            return {data:"blastDD4th",
                    label: Language.s.blastDD4th};
        }
        
        override public function popUpChangeWindow():void {
            try {
                var window:ChangeMagicRangeDD4thWindow =
                    DodontoF.popup(ChangeMagicRangeDD4thWindow, true) as ChangeMagicRangeDD4thWindow;
                
                window.setMagicRange(this);
            } catch(e:Error) {
                Log.loggingException("MagicRange.popUpChangeWindow()", e);
            }
        }
        
        override public function loadViewImage():void {
            var size:int = 0;
            if( this.getRangeType() == closeBurst.data ) {
                size = Utils.getMapRangeSize();
            }
            view.setIsDrawRound(false);
            view.loadImage(Utils.getCenterImageUrl(), size);
        }
        
        
        override public function initDrawRangeSquare():void {
            
            var drawAlpha:Number = 0.5;
            view.graphics.beginFill(getColor(), drawAlpha);
            
            var radius:int = getRadius();
            var length:int = Utils.getMapRangeSquareLength();
            
            if( this.getRangeType() == closeBurst.data ) {
                view.graphics.drawRect( radius * length * -1,
                                        radius * length * -1,
                                        (radius * 2 + 1) * length,
                                        (radius * 2 + 1) * length );
                                        
            } else if( this.getRangeType() == blast.data ) {
                view.graphics.drawRect( 0,
                                        0,
                                        radius * length,
                                        radius * length );
            } else {
                Log.loggingError("MagicRangeDD4th.initDrawSquareDD4th rangeType is invalid", this.getRangeType());
            }
            
            view.graphics.endFill();
        }
        
    }
}

