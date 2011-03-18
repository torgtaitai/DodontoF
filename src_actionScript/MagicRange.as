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
    
    public class MagicRange  extends InitiativedMovablePiece {
        
        private var radius:int = 1;
        private var rangeType:String = "circle";
        private var color:int = 0x000000;
        private var createRound:int = 0;
        private var timeRange:int = 0;
        
        public static function getTypeStatic():String {
            return "magicRangeMarker"
        }
        
        override public function getType():String {
            return getTypeStatic();
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
        
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.feets = getFeets();
            jsonData.rangeType = getRangeType();
            jsonData.color = getColor();
            jsonData.createRound = getCreateRound();
            jsonData.timeRange = getTimeRange();
            
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
            return ["魔法範囲 残り：" + getRestRoundLocal()  + "ラウンド"];
        }
        
        override public function isDead():Boolean {
            return ( getRestRoundLocal() <= 0 );
        }
        

        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, "魔法範囲の変更", this.getItemPopUpChangeWindow);
            addMenuItem(menu, "魔法範囲の削除", this.getContextMenuItemRemoveCharacter);
            
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
        
        override protected function getMapLayer():UIComponent {
            return getMap().getMagicRangeLayer();
        }
        
        protected function getCenterImageUrl():String {
            return "image/centerMarker.png";
        }
        
        private function loadViewImage():void {
            var size:int = 1;
            var halfSquareLength:Number = getSquareLength() / 2;
            var diffPoint:Point = new Point(halfSquareLength,
                                            halfSquareLength * -1);
            view.setIsDrawRound(false);
            view.loadImage(this.name, getCenterImageUrl(), size, diffPoint);
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            clearDrown();
            move(x, y, true);
            initDrawRange();
        }
        
        protected function initDrawRange():void {
            loadViewImage();
            initDrawRangeSquare();
        }
        
        
        private function initDrawRangeSquare():void {
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
            "corn1": [[1, 2], "円錐型(右上)"],
            "corn2": [[2, 3], "円錐型(右)"],
            "corn3": [[3, 4], "円錐型(右下)"],
            "corn4": [[4, 5], "円錐型(下)"],
            "corn5": [[5, 6], "円錐型(左下)"],
            "corn6": [[6, 7], "円錐型(左)"],
            "corn7": [[7, 8], "円錐型(左上)"],
            "corn8": [[8, 1], "円錐型(上)"],
            
            "circle": [[1, 2, 3, 4, 5, 6, 7, 8], "円型"],
            
            rangeTypeSquare: [[], "四角"]
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
        
        private var alreadyDrawedPosition:Object = new Object();
        
        private function clearDrown():void {
            view.graphics.clear();
            alreadyDrawedPosition = new Object();
        }
        
        private function drawSquare(x:int, y:int):void {
            view.graphics.lineStyle(0, 0x000000);
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
            
            view.graphics.drawRect( (x * getSquareLength()),
                                    (y * getSquareLength() * -1),
                                    getSquareLength(),
                                    getSquareLength() );
            view.graphics.endFill();
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>MagicRange update Begin");
            
            super.update(params);
            
            this.radius = (parseInt(params.feets) / 5);
            this.rangeType = params.rangeType;
            this.color = params.color;
            this.timeRange = parseInt(params.timeRange);
            this.createRound = parseInt(params.createRound);
            
            initDraw(getX(), getY());
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged MagicRange changed End");
        }
   }
}