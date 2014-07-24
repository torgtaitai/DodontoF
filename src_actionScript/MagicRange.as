//--*-coding:utf-8-*--

package {
    
    import mx.core.UIComponent;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.geom.Point;
    import mx.utils.StringUtil;

    public class MagicRange extends InitiativedMovablePiece implements MapRange {
        
        private var radius:int = 1;
        private var rangeType:String = "circle";
        private var color:int = 0x000000;
        private var createRound:int = 0;
        private var timeRange:int = 0;
        private var isHide:Boolean = false;
        
        public static function getTypeStatic():String {
            return "magicRangeMarker"
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return Language.s.magicRange3rd;
        }
        
        public static function getJsonData(name:String,
                                           feets:int,
                                           rangeType:String,
                                           color:String,
                                           timeRange:Number,
                                           createRound:Number,
                                           initiative:Number,
                                           info:String,
                                           characterPositionX:int,
                                           characterPositionY:int,
                                           isHide:Boolean = false):Object {
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
            jsonData.rangeType = rangeType;
            jsonData.color = color;
            jsonData.createRound = createRound;
            jsonData.timeRange = timeRange;
            jsonData.isHide = isHide;
            
            jsonData.imageName = "";
            jsonData.size = 0;
            
            return jsonData;
        }
        
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.feets = getFeets();
            jsonData.rangeType = getRangeType();
            jsonData.color = getColor();
            jsonData.createRound = getCreateRound();
            jsonData.timeRange = getTimeRange();
            jsonData.isHide = this.isHide;
            
            return jsonData;
        }
        
        public function getRangeType():String {
            return rangeType;
        }
        
        public function setRangeType(rangeType_:String):void {
            rangeType = rangeType_;
        }
        
        public function MagicRange(params:Object) {
            
            var feets:int = parseInt(params.feets);
            
            radius = (feets / 5);
            rangeType = params.rangeType;
            color = parseInt(params.color);
            
            super(params);
            
            view.setIsDrawBack(false);
        }
        
        public function getRange():int {
            return radius;
        }
        
        public function getFeets():int {
            return radius * 5;
        }
        
        public function setFeets(feets_:int):void {
            radius = feets_ / 5;
        }
        
        public function getRadius():int {
            return radius;
        }
        
        public function getColor():int {
            return color;
        }
        
        public function setColor(color_:int):void {
            color = color_;
        }
        
        public function getCreateRound():int {
            return createRound;
        }
        
        public function setCreateRound(createRound_:int):void {
            createRound = createRound_;
        }
        
        public function getTimeRange():int {
            return timeRange;
        }
        
        public function setTimeRange(timeRange_:int):void {
            timeRange = timeRange_;
        }
        
        override public function isHideMode():Boolean {
            return this.isHide;
        }
        
        public function setHide(b:Boolean):void {
            this.isHide = b;
        }
        
        public function getRestRoundLocal():int {
            return getRestRound(timeRange, createRound, initiative);
        }
        public static function getRestRound(timeRange:int, createRound:int, initiative:Number):int {
            var roundTimer:RoundTimer = DodontoF_Main.getInstance().getRoundTimer();
            var restRound:int = timeRange - (roundTimer.getCurrentRound() - createRound);
            
            if( roundTimer.getCurrentInitiative() > initiative ) {
                restRound += 1;
            }
            
            if( restRound < 0 ) {
                restRound = 0;
            }
            
            return restRound;
        }
        
        override public function getAdditionalInfos():Array {
            var text:String = Language.text("magicRangeRestRound", getRestRoundLocal());
            return [text];
        }
        
        override public function isDead():Boolean {
            return ( getRestRoundLocal() <= 0 );
        }
        

        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, Language.s.changeMagicRangeRightMenu, this.getItemPopUpChangeWindow);
            addMenuItem(menu, Language.s.addMagicRangeRightMenu, this.getContextMenuItemRemoveCharacter);
            
            view.contextMenu = menu;
        }
        
        override public function popUpChangeWindow():void {
            try {
                Log.logging("contextmenuevent mapRange change.");
                ChangeMagicRangeWindow.setMagicRange(this);
                Log.logging("DodontoF.popup(ChangeMagicRangeWindow, true);");
                DodontoF.popup(ChangeMagicRangeWindow, true);
                Log.logging("contextmenuevent magiRange changeend");
            } catch(e:Error) {
                Log.loggingException("MagicRange.popUpChangeWindow()", e);
            }
        }
        
        override public function getMapLayer():UIComponent {
            return getMap().getMagicRangeLayer();
        }
        
        override public function loadViewImage():void {
            var size:int = Utils.getMapRangeSize();
            var halfSquareLength:Number = Utils.getMapRangeSquareLength() / 2;
            var diffPoint:Point = new Point(halfSquareLength,
                                            halfSquareLength * -1);
            view.setIsDrawRound(false);
            view.loadImage(Utils.getCenterImageUrl(), size, diffPoint);
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            move(x, y, true);
            initDrawRange();
        }
        
        public function initDrawRange():void {
            loadViewImage();
            clearDrown();
            initDrawRangeSquare();
        }
        
        private var alreadyDrawedPosition:Object = new Object();
        
        public function clearDrown():void {
            view.graphics.clear();
            alreadyDrawedPosition = new Object();
        }
        
        private function drawSquare(x:int, y:int):void {
            view.graphics.beginFill(color, 0.5);
            
            if( y < 0 ) {
                y += 1;
            }
            
            if( x < 0 ) {
                x += 1;
            }
            
            var positionInfo:String = "[" + x + ", " + y + "]";
            if( alreadyDrawedPosition[positionInfo] != null ) {
                Log.logging("this position is already dorawd", positionInfo);
                return;
            }
            Log.logging("fist dorawing...", positionInfo);
            alreadyDrawedPosition[positionInfo] = true;
            
            var length:int = Utils.getMapRangeSquareLength();
            view.graphics.drawRect( (x * length),
                                    (y * length * -1),
                                    length,
                                    length );
            view.graphics.endFill();
        }
        
        
        public function initDrawRangeSquare():void {
            
            if( rangeType == rangeTypeSquare ) {
                drawSquareMagicRange();
                return;
            }
            
            var rangeTypeData:Array = rangeTypeDataList[rangeType];
            var partNumberList:Array = rangeTypeData[0];
            
            for(var i:int = 0 ; i < partNumberList.length ; i++) {
                var partNumber:int = partNumberList[i];
                drawRangeSquares( partNumber );
                Log.logging("initDraw partNumber", partNumber);
            }
        }

        private function drawSquareMagicRange():void {
            for(var x:int = 0 ; x < (this.radius + 1) ; x++) {
                for(var y:int = 0 ; y < (this.radius + 1) ; y++) {
                    drawSquare(x     , y);
                    drawSquare(x     , y * -1);
                    drawSquare(x * -1, y);
                    drawSquare(x * -1, y * -1);
                }
            }
        }
        
        private var rangeTypeSquare:String = "square";
        
        private var rangeTypeDataList:Object = {
            "corn1": [[1, 2], Language.s.magicRangeTypeCorn1],
            "corn2": [[2, 3], Language.s.magicRangeTypeCorn2],
            "corn3": [[3, 4], Language.s.magicRangeTypeCorn3],
            "corn4": [[4, 5], Language.s.magicRangeTypeCorn4],
            "corn5": [[5, 6], Language.s.magicRangeTypeCorn5],
            "corn6": [[6, 7], Language.s.magicRangeTypeCorn6],
            "corn7": [[7, 8], Language.s.magicRangeTypeCorn7],
            "corn8": [[8, 1], Language.s.magicRangeTypeCorn8],
            
            "circle": [[1, 2, 3, 4, 5, 6, 7, 8], Language.s.magicRangeTypeCircle],
            
            rangeTypeSquare: [[], Language.s.magicRangeTypeSquare]
        };
        
        
        private function drawRangeSquares(partNumber:int):void {
            switch(partNumber) {
            case 1:
                drawTargetRangeSquares(radius,  1,  0,  0,  1);
                break;
            case 2:
                drawTargetRangeSquares(radius,  0,  1,  1,  0);
                break;
            case 3:
                drawTargetRangeSquares(radius,  0,  1, -1,  0);
                break;
            case 4:
                drawTargetRangeSquares(radius,  1,  0,  0, -1);
                break;
            case 5:
                drawTargetRangeSquares(radius, -1,  0,  0, -1);
                break;
            case 6:
                drawTargetRangeSquares(radius,  0, -1, -1,  0);
                break;
            case 7:
                drawTargetRangeSquares(radius,  0, -1,  1,  0);
                break;
            case 8:
                drawTargetRangeSquares(radius, -1,  0,  0,  1);
                break;
            defalt:
                Log.logging("drawTargetRangeSquares invalid partNumber", partNumber);
                break;
            }
        }
        
        private function drawTargetRangeSquares(max:int,
                                                xRate1:int, yRate1:int,
                                                xRate2:int, yRate2:int):void {
            for(var x:int = 1; x <= max ; x++) {
                if( (x % 2) == 0 ) {
                    max--;
                }
                
                for(var y:int = x; y <= max ; y++) {
                    drawSquare( (x * xRate1 + y * yRate1),
                                (x * xRate2 + y * yRate2) );
                }
            }
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>MagicRange update Begin");
            
            super.update(params);
            
            this.radius = (parseInt(params.feets) / 5);
            this.rangeType = params.rangeType;
            this.color = params.color;
            this.timeRange = parseInt(params.timeRange);
            this.createRound = parseInt(params.createRound);
            this.isHide = params.isHide;
            
            updateRefresh();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged MagicRange changed End");
        }
        
        override public function updateRefresh():void {
            initDraw(getX(), getY());
        }
        
        override public function snapViewPosition():Boolean {
            return snapViewPositionForMapRange(this);
        }
        
   }
}
