//--*-coding:utf-8-*--

package {
    
    import mx.utils.ArrayUtil;
    import mx.controls.Alert;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.geom.Point;
    import mx.core.UIComponent;
    import flash.utils.ByteArray;
    import flash.utils.getQualifiedClassName;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    public class Map {
        
        private static var dodontoF:DodontoF;
        public static function setDodontoF(dodontoF_:DodontoF):void {
            dodontoF = dodontoF_;
        }
        public function getDodontoF():DodontoF {
            return dodontoF;
        }
        
        public static function getSquareLength():int {
            return 50;
        }
        
        private var cardZoomRateDefault:Number = 1.07;
        private var zoomRate:Number = 1.2;
        private var currentZoomRate:Number = 1.0;
        
        protected var baseLayer:UIComponent = new UIComponent();
        protected var imageLayer:ImageSprite = new ImageSprite();
        protected var mapTileLayer:UIComponent = new UIComponent();
        protected var marksLayer:UIComponent = new UIComponent();
        
        protected var overMapLayer:UIComponent = new UIComponent();
        
        protected var clickMapLayer:UIComponent = new UIComponent();
        protected var gridPositionLayer:UIComponent = new UIComponent();
        protected var magicRangeLayer:UIComponent = new UIComponent();
        protected var mapMaskLayer:UIComponent = new UIComponent();
        protected var mapMarkerLayer:UIComponent = new UIComponent();
        protected var gridLayer:UIComponent = new UIComponent();
        protected var characterLayer:UIComponent = new UIComponent();
        protected var hideCharacterLayer:UIComponent = new UIComponent();
        protected var cardLayer:UIComponent = new UIComponent();
        protected var frontLayer:UIComponent = new UIComponent();
        protected var rulerLayer:UIComponent = new UIComponent();
        
        private var thisObj:Map;
        
        private var imageUri:String = "";
        private var mapWidth:int = 1;
        private var mapHeight:int = 1;
        private var gridColor:uint = 0x000000;
        private var squareColors:Array = new Array();
        private var menuClickPoint:Point = new Point();
        
        private var existPieces:Array = new Array();
        
        public function getExistPiecesCount():int {
            return this.existPieces.length;
        }
        
        public function getExistPiece(i:int):Piece {
            return this.existPieces[i];
        }
        
        public function getExistPieces():Array {
            return this.existPieces;
        }
        
        public function setExistPieces(array_:Array):void {
            this.existPieces = array_;
        }
        
        public function addExistPieces(piece:Piece):void {
            this.existPieces.push( piece );
        }
        
        public function removeExistPieces(findTarget:Piece):void {
            var index:int = ArrayUtil.getItemIndex(findTarget, existPieces);
            if( index == -1 ) {
                return;
            }
            
            existPieces.splice(index,1);
        }
        
        public function findExistPiecesByTypeName(typeName:String):Array {
            var result:Array = new Array();
            
            for(var i:int = 0 ; i < existPieces.length ; i++) {
                var existCharacter:Piece = existPieces[i];
                if( existCharacter.getType() == typeName ) {
                    result.push( existCharacter );
                }
            }
            
            return result;
        }
        
        public function findExistCharacterById(characterId:String):Piece {
            Log.logging("characterId", characterId);
            
            if( characterId == "" ) {
                return null;
            }
            
            Log.logging("existPieces.length", existPieces.length);
            
            for(var i:int = 0 ; i < existPieces.length ; i++) {
                var existCharacter:Piece = existPieces[i];
                if( existCharacter.getId() == characterId ) {
                    return existCharacter;
                }
            }
            
            return null;
        }
        
        public function findExistCharacter(characterData:Object):Piece {
            return findExistCharacterById(characterData.imgId);
        }
        
        public function getTargetTypes(targetType:String):Array {
            var results:Array = new Array();
            
            for(var i:int = 0 ; i < existPieces.length ; i++) {
                var piece:Piece = existPieces[i];
                if( piece.getType() != targetType ) {
                    continue;
                }
                results.push(piece);
            }
            
            return results;
        }
        
        public function getCharacters():Array {
            var characters:Array = new Array();
            
            for(var i:int = 0 ; i < existPieces.length ; i++) {
                var piece:Piece = existPieces[i];
                var character:Character = piece as Character;
                if( character == null ) {
                    continue;
                }
                characters.push(character);
            }
            
            return characters;
        }
        
        
        public function getPieciesByType( type:String ):Array {
            var pieces:Array = new Array();
            
            for(var i:int = 0 ; i < existPieces.length ; i++) {
                var piece:Piece = existPieces[i];
                if( piece.getType() != type ) {
                    continue;
                }
                
                pieces.push(piece);
            }
            
            return pieces;
        }
        
        
        public function getSamePositionMovablePieciesOrderdByViewIndex(point:Point):Array {
            var samePositionCharacters:Array = new Array();
            
            for(var i:int = 0 ; i < existPieces.length ; i++) {
                var piece:Piece = existPieces[i];
                var character:MovablePiece = piece as MovablePiece;
                
                if( character == null ) {
                    continue;
                }
                if( character.getX() != point.x ) {
                    continue;
                }
                if( character.getY() != point.y ) {
                    continue;
                }
                if( character.isHideMode() ) {
                    continue;
                }
                
                samePositionCharacters.push(character);
            }
            
            samePositionCharacters.sort(sortedByViewIndex);
            
            return samePositionCharacters;
        }
        
        
        public function getExistCharactersOrderdByViewIndex(point:Point):Array {
            var result:Array = new Array();
            
            for(var i:int = 0 ; i < existPieces.length ; i++) {
                var piece:Piece = existPieces[i];
                var character:Character = piece as Character;
                
                if( character == null ) {
                    continue;
                }
                
                if( character.isHideMode() ) {
                    continue;
                }
                
                if( character.getX() > point.x ) {
                    continue;
                }
                if( point.x >= (character.getX() + character.getWidth()) ) {
                    continue;
                }
                
                if( character.getY() > point.y ) {
                    continue;
                }
                if( point.y >= (character.getY() + character.getHeight()) ) {
                    continue;
                }
                
                result.push(character);
                
                /*
                if( character.getX() > point.x ) {
                    continue;
                }
                if( point.x >= (character.getX() + character.getWidth())) {
                    continue;
                }
                
                if( character.getY() > point.y ) {
                    continue;
                }
                if( point.y >= (character.getY() + character.getHeight())) {
                    continue;
                }
                Alert.show(character.getName()
                           + " point.x : " + point.x
                           + " point.y : " + point.y
                           + " character.getX() : " + character.getX()
                           + " character.getY() : " + character.getY()
                           );
                
                result.push(character);
                */
            }
            
            result.sort(sortedByViewIndex);
            
            return result;
        }
        
        
        public function snapMovablePieceViewPosition(point:Point, isListed:Boolean = false):void {
            var samePositionCharactersForSnapX:Array = new Array();
            var samePositionCharactersForSnapY:Array = new Array();
            var samePositionCharactersForSnapCard:Array = new Array();
            
            var samePositionCharacters:Array = getSamePositionMovablePieciesOrderdByViewIndex(point);
            
            for(var i:int = 0 ; i < samePositionCharacters.length ; i++) {
                var character:MovablePiece = samePositionCharacters[i];
                
                var card:Card = character as Card;
                if( card != null ) {
                    if( card.isForeground() ) {
                        samePositionCharactersForSnapCard.push(card);
                    }
                    continue;
                }
                
                if( character.canSnapOnPositionX() ) {
                    samePositionCharactersForSnapX.push(character);
                    continue;
                }
                
                if( character.canSnapOnPositionY() ) {
                    samePositionCharactersForSnapY.push(character);
                    continue;
                }
            }
            
            snapSortedCharacterToViewPosition(samePositionCharactersForSnapCard, isListed, true, new Array());
            
            snapSortedCharacterToViewPosition(samePositionCharactersForSnapX, isListed, true, new Array());
            
            snapSortedCharacterToViewPosition(samePositionCharactersForSnapY, isListed, false, samePositionCharactersForSnapX);
        }
        
        private function getCharactersSizeInfos(characters:Array, isX:Boolean):Object {
            var info:Object = {
                "totalWidth" : 0,
                "maxSize" : 0
            };
            
            for(var i:int = 0 ; i < characters.length ; i++) {
                var character:MovablePiece = characters[i] as MovablePiece;
                
                if( character == null ) {
                    continue;
                }
                
                var size:int = (isX ? character.getWidth() : character.getHeight());
                if( info.maxSize < size ) {
                    info.maxSize = size;
                }
                
                info.totalWidth += size;
            }
            return info;
        }
        
        private function addViewPosition(character:MovablePiece,
                                         value:Number,
                                         isX:Boolean):void {
            if( isX ) {
                character.addViewPosition( value, 0 );
            } else {
                character.addViewPosition( 0, value );
            }
        }
        
        private function snapSortedCharacterToViewPosition(characters:Array, 
                                                           isListed:Boolean,
                                                           isX:Boolean,
                                                           samePositionCharactersOnBorderLine:Array):void {
            //Log.logging("snapSortedCharacterToViewPosition isListed", isListed);
            //Log.logging("snapSortedCharacterToViewPosition isX", isX);
            
            if(( ! isX ) && ( characters.length <= 1 ) && (samePositionCharactersOnBorderLine.length == 0)) {
                return;
            }
            
            var widthPadding:int = 0;
            for(var i:int = 0 ; i < characters.length ; i++) {
                var character:MovablePiece = characters[i] as MovablePiece;
                
                if( character == null ) {
                    continue;
                }
                
                if( ! isListed ) {
                    character.setViewForeground();
                    addViewPosition(character, (i * 4), isX);
                    continue;
                }
                
                //isListed
                character.setViewForeground();
                
                var widthSizeInfo:Object = getCharactersSizeInfos(characters, isX);
                var totalWidth:int = widthSizeInfo.totalWidth;
                var maxSize:int = widthSizeInfo.maxSize;
                
                var newPosition:int = (widthPadding - (totalWidth / 2) + (maxSize / 2)) * getSquareLength() * 0.97;//0.9;
                
                widthPadding += (isX ? character.getWidth() : character.getHeight());
                
                //Y軸展開の場合でX軸上にキャラがいるなら、真ん中に「X軸キャラの最大高さ分だけ」の空間を空けたい
                if( ! isX ) {
                    newPosition = getNewPositionForSnapOnY(newPosition, i, characters,
                                                           samePositionCharactersOnBorderLine);
                }
                
                addViewPosition(character, newPosition, isX);
            }
        }
        
        private function getNewPositionForSnapOnY(newPosition:int,
                                                  index:int,
                                                  characters:Array,
                                                  samePositionCharactersOnBorderLine:Array):int {
            var sizeInfoOfBorders:Object = getCharactersSizeInfos(samePositionCharactersOnBorderLine, false);
            var spaceSize:int = (sizeInfoOfBorders.maxSize * getSquareLength());
            
            if( index < (characters.length / 2) ) {
                newPosition -= (spaceSize / 2);
            } else {
                newPosition += (spaceSize / 2);
            }
            
            //キャラクター数が偶数の場合、隙間を空けるための座標を調整する必要がある
            if( (characters.length % 2) != 0) {
                newPosition += (-1 * spaceSize / 2);
            }
            
            return newPosition;
        }
        
        private function sortedByViewIndex(a:Object, b:Object):Number {
            var characterA:Character = a as Character;
            var characterB:Character = b as Character;
            
            var indexA:int = a.getViewIndex();
            var indexB:int = b.getViewIndex();
            
            if (indexA < indexB) {
                return -1;
            }
            
            if (indexA > indexB) {
                return 1;
            }
            
            return 0;
        }
        
        
        public function Map() {
            thisObj = this;
            
            initMapLayerEvent();
        }

        private function initMapLayerEvent():void {
            //マウスロールオーバー時の挙動（立ち絵隠し）の登録
            var layers:Array = [this.baseLayer, this.cardLayer];
            
            for(var i:int = 0 ; i < layers.length ; i++) {
                var layer:UIComponent = layers[i];
                
                layer.addEventListener(MouseEvent.ROLL_OVER, function(event:MouseEvent):void {
                    DodontoF_Main.getInstance().getDodontoF().setStandingGraphicVisible(false);
                });
            
                layer.addEventListener(MouseEvent.ROLL_OUT, function(event:MouseEvent):void {
                    DodontoF_Main.getInstance().getDodontoF().setStandingGraphicVisible(true);
                    DodontoF_Main.getInstance().getChatWindow().changeLogVisible(event, true);
                });
            }
        }
        
        public function init(parent:UIComponent):void {
            Log.logging("MapManager init begin");
            
            initContextMenu();
            
            imageLayer.setMaintainAspectRatio(false);
            baseLayer.addChild(imageLayer);
            baseLayer.addChild(mapTileLayer);
            baseLayer.addChild(marksLayer);
            
            baseLayer.addChild(overMapLayer);
            
            clickMapLayer.alpha = 0.01;
            overMapLayer.addChild(clickMapLayer);
            
            overMapLayer.addChild(gridPositionLayer);
            overMapLayer.addChild(hideCharacterLayer);
            overMapLayer.addChild(mapMaskLayer);
            overMapLayer.addChild(magicRangeLayer);
            overMapLayer.addChild(gridLayer);
            overMapLayer.addChild(mapMarkerLayer);
            //overMapLayer.addChild(statusMarkLayer);
            overMapLayer.addChild(characterLayer);
            overMapLayer.addChild(rulerLayer);
            
            rulerLayer.visible = false;
            
            parent.addChild(baseLayer);
            
            cardLayer.x = 150;
            parent.addChild(cardLayer);
            initCardLayer();
            
            parent.addChild(frontLayer);
        }
        
        public function getView():UIComponent {
            return baseLayer;
        }
        
        public function setVisible(b:Boolean):void {
            baseLayer.visible = b;
        }
        
        public function getImageUrl():String {
            return imageUri;
        }
        
        public function getWidth():int {
            return mapWidth;
        }
        
        public function getHeight():int {
            return mapHeight;
        }
        
        public function getGridColor():uint {
            return gridColor;
        }
        
        public function setVisibleGridPositionLayer(visible:Boolean):void {
            gridPositionLayer.visible = visible;
        }
        
        public function setVisibleGridLayer(visible:Boolean):void {
            gridLayer.visible = visible;
        }
        
        public function setVisibleCardLayer(visible:Boolean):void {
            cardLayer.visible = visible;
            DodontoF_Main.getInstance().setVisibleCardPreview(visible);
        }
        
        public function getMagicRangeLayer():UIComponent {
            return magicRangeLayer;
        }
        
        public function getMapMaskLayer():UIComponent {
            return mapMaskLayer;
        }
        
        public function getMapMarkerLayer():UIComponent {
            return mapMarkerLayer;
        }
        
        public function getFrontLayer():UIComponent {
            return frontLayer;
        }
        
        /*
        public function getStatusMarkerLayer():UIComponent {
            return statusMarkLayer;
        }
        */
        
        public function getMapTileLayer():UIComponent {
            return mapTileLayer;
        }
        
        public function getOverMapLayer():UIComponent {
            return overMapLayer;
        }
        
        public function getCharacterLayer():UIComponent {
            return characterLayer;
        }
        
        public function getHideCharacterLayer():UIComponent {
            return hideCharacterLayer;
        }
        
        public function getCardLayer():UIComponent {
            return cardLayer;
        }
        
        public function getRulerLayer():UIComponent {
            return rulerLayer;
        }
        
        public function zoom(isZoom:Boolean):void {
            Log.logging("zoomed isZoom : " + isZoom);
            
            baseLayer.stopDrag();
            
            var rate:Number = zoomRate;
            
            if( ! isZoom ) {
                rate = (1.0 / rate);
            }
            Log.logging("rate : " + rate);
            
            centerZoomingToMousePiont(baseLayer, rate);
            
            currentZoomRate = currentZoomRate * rate;
            baseLayer.scaleX = currentZoomRate;
            baseLayer.scaleY = currentZoomRate;
        }
        
        private function centerZoomingToMousePiont(layer:UIComponent, rate:Number):void {
            Log.logging("layer.mouseX", layer.mouseX);
            Log.logging("layer.mouseY", layer.mouseY);
            
            var localMousePoint:Point = new Point(layer.mouseX, layer.mouseY);
            var currentPoint:Point = layer.localToGlobal( localMousePoint );
            
            Log.logging("get new x...");
            layer.x = getZoomedPointP(currentPoint.x, layer.x, rate);
            Log.logging("layer.x", layer.x);
            
            Log.logging("get new y...");
            layer.y = getZoomedPointP(currentPoint.y, layer.y, rate);
            Log.logging("layer.y", layer.y);
        }
        
        private function getZoomedPointP(currentPointP:Number, mapPointP:Number, rate:Number):Number {
            Log.logging("currentPointP", currentPointP);
            Log.logging("mapPointP", mapPointP);
            
            var distanceP:Number = (currentPointP - mapPointP);
            Log.logging("distanceP", distanceP);
            
            var changedDistanceP:Number = distanceP * rate;
            Log.logging("changedDistanceP", changedDistanceP);
            
            var newDiffP:Number = (changedDistanceP - distanceP);
            Log.logging("newDiffP", newDiffP);
            
            var newMapPointP:Number = mapPointP - newDiffP;
            Log.logging("newMapPointP", newMapPointP);
            
            return newMapPointP;
        }
        
        public function setEvents():void {
            baseLayer.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    baseLayer.startDrag();
                    event.stopPropagation();
                });
            
            baseLayer.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
                    baseLayer.stopDrag();
                });
            
            setRulerEvent();
        }
        
        //centerといいながら、画面構成を鑑みて全体幅・高さの0.4倍の場所を中央と定義しています。
        private function getCenter():Point {
            var centerX:Number = (DodontoF_Main.getInstance().getScreenWidth() * 0.4);
            var centerY:Number = (DodontoF_Main.getInstance().getScreenHeight() * 0.25);
            Log.logging("centerX", centerX);
            Log.logging("centerY", centerY);
            
            return new Point(centerX, centerY);
        }
        
        
        private var rulerStartPosition:Point = null;
        private function setRulerEvent():void {
            
            /*
            rulerLayer.addEventListener(MouseEvent.DOUBLE_CLICK, function(event:MouseEvent):void {
                    event.stopImmediatePropagation();
                    setRulerMode();
                });
            */
            
            rulerLayer.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                });
            
            rulerLayer.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
                    var mouseX:Number = event.localX;
                    var mouseY:Number = event.localY;
                    var layer:UIComponent = lineLayer;
                    
                    layer.graphics.drawCircle(mouseX, mouseY, 3);
                    
                    if( rulerStartPosition == null ) {
                        rulerStartPosition = new Point(mouseX, mouseY);
                        return;
                    }
                    
                    layer.graphics.moveTo(rulerStartPosition.x, rulerStartPosition.y);
                    layer.graphics.lineTo(mouseX, mouseY);
                    var diff:Number =
                        Math.sqrt(Math.pow(rulerStartPosition.x - mouseX, 2) + 
                                  Math.pow(rulerStartPosition.y - mouseY, 2));
                    var diffSquare:Number = diff / getSquareLength();
                    diffSquare = Math.round( diffSquare * 10 ) / 10;
                    
                    ChatWindow.getInstance().addLocalMessage("長さ：" + diffSquare + "マス");
                    
                    rulerStartPosition = null;
                });
        }
        
        public function setRulerMode():void {
            rulerLayer.visible = ( ! rulerLayer.visible);
            setRulerModeByVisible();
        }
        
        private var lineLayer:UIComponent = new UIComponent();
        
        public function setRulerModeByVisible():void {
            if( ! rulerLayer.visible ) {
                rulerLayer.graphics.clear();
                rulerLayer.removeChild( lineLayer );
                return;
            }
            
            lineLayer = new UIComponent();
            rulerLayer.addChild( lineLayer );
            var color:int = 0xFFFF00;
            lineLayer.graphics.lineStyle(1, color);
            lineLayer.graphics.beginFill(color);
            
            rulerLayer.alpha = 0.5;
            rulerLayer.graphics.beginFill(0x000000);
            rulerLayer.graphics.drawRect(0,
                                         0,
                                         getWidth() * getSquareLength(),
                                         getHeight() * getSquareLength());
        }
        
        public function centeringFromPiece(piece:InitiativedMovablePiece):void {
            var center:Point = getCenter();
            
            var currentZoomRate:Number = baseLayer.scaleX;
            Log.logging("currentZoomRate", currentZoomRate);
            Log.logging("piece.getViewX()", piece.getViewX());
            Log.logging("piece.getViewY()", piece.getViewY());
            
            var widthPadding:int = piece.getWidth() * piece.getSquareLength() / 2;
            baseLayer.x = (center.x - (piece.getViewX() + widthPadding) * currentZoomRate);
            baseLayer.y = (center.y - (piece.getViewY() + widthPadding) * currentZoomRate);
            Log.logging("baseLayer.x", baseLayer.x);
            Log.logging("baseLayer.y", baseLayer.y);
        }
        
        private function deepCopy(list:Array):Array {
            var ba:ByteArray = new ByteArray();
            
            ba.writeObject(list);
            ba.position = 0;
            var copy:Array = ba.readObject();  
            
            return copy;
        }
        
        public function changeMarks(squareColors_:Object):void {
            try {
                marksLayer.graphics.clear();
                
                if( squareColors_ == null ) {
                    return;
                }
                
                squareColors = deepCopy(squareColors_ as Array);
                Log.logging("squareColors", squareColors);
                
                for(var y:int = 0 ; y < squareColors.length; y++) {
                    for(var x:int = 0 ; x < squareColors[y].length ; x++) {
                        var color:int = squareColors[y][x];
                        Log.logging("color", color);
                        
                        if( color >= 0 ) {
                            Log.logging("drawing...");
                            Log.logging("x", x * getSquareLength());
                            Log.logging("y", y * getSquareLength());
                            Log.logging("getSquareLength", getSquareLength());
                            marksLayer.graphics.beginFill(color);
                            marksLayer.graphics.drawRect(x * getSquareLength(),
                                                         y * getSquareLength(),
                                                         getSquareLength(),
                                                         getSquareLength());
                            marksLayer.graphics.endFill();
                        }
                    }
                }
            } catch( error:Error ) {
                Log.loggingException("Map.changeMarks()", error);
            }
        }
        
        public function getMarks():Array {
            return squareColors;
        }
        
        public function changeMap(imageUri_:String, mapWidth_:int, mapHeight_:int, gridColor_:uint):void {
            imageUri = imageUri_;
            mapWidth = mapWidth_;
            mapHeight = mapHeight_;
            gridColor = gridColor_;
            
            drawBackGround(baseLayer);
            printGridPosition(mapWidth, mapHeight);
            drawGridOnMap();
            
            imageLayer.loadImageWidthHeight("マップ背景画像", imageUri, mapWidth, mapHeight);
            drawBackGround(clickMapLayer);
        }
        
        private function drawBackGround(layer:UIComponent):void {
            layer.graphics.clear();
            layer.graphics.lineStyle(5, 0x000000);
            layer.graphics.beginFill(0xFFFFFF);
            layer.graphics.drawRect(0, 0, (mapWidth * getSquareLength()), (mapHeight * getSquareLength()));
            layer.graphics.endFill();
        }
        
        private function printGridPosition(xMax:int, yMax:int):void {
            gridPositionLayer.graphics.clear();
            
            while( positionStrings.length > 0 ) {
                var textField:TextField = positionStrings.pop();
                gridPositionLayer.removeChild(textField);
            }
            
            for(var x:int = 0 ; x < xMax ; x++) {
                for(var y:int = 0 ; y < yMax ; y++) {
                    var positionText:String = "" + (x + 1) + "-" + (y + 1);
                    drawGridPositionString(gridPositionLayer, positionText, x * getSquareLength(), y * getSquareLength());
                }
            }
        }
        
        private var positionStrings:Array = new Array();
        
        private function drawGridPositionString(layer:UIComponent, message:String, x:int, y:int):void {
            var textField:TextField = new TextField();
            textField.autoSize = TextFieldAutoSize.CENTER;
            textField.text = message;
            textField.selectable = false;
            textField.textColor = gridColor;
            
            positionStrings.push(textField);
            
            layer.addChild(textField);
            textField.x = (x + (getSquareLength() / 2) - (textField.width / 2));
            textField.y = (y + (getSquareLength() / 2) - (textField.height / 2));
        }
        
        
        private function drawGridOnMap():void {
            drawGrid(mapWidth, mapHeight, gridLayer, getSquareLength(), gridColor);
        }
        
        public static function drawGrid(xMax:int, yMax:int, layer:UIComponent, squareLength:Number, color:uint):void {
            Log.logging("Map.drawGrid");
            Log.logging("xMax", xMax);
            Log.logging("yMax", yMax);
            Log.logging("squareLength", squareLength);
            layer.graphics.clear();
            layer.graphics.lineStyle(1, color);
            drawGridVertical(xMax, yMax, layer, squareLength);
            drawGridHrison(xMax, yMax, layer, squareLength);
        }
        private static function drawGridVertical(xMax:int, yMax:int, layer:UIComponent, squareLength:Number):void {
            for(var x:int = 0 ; x < (xMax + 1) ; x++) {
                var xPosition:int = x * squareLength;
                var yPosition:int = yMax * squareLength;
                layer.graphics.moveTo(xPosition, 0);
                layer.graphics.lineTo(xPosition, yPosition);
            }
        }
        private static function drawGridHrison(xMax:int, yMax:int, layer:UIComponent, squareLength:Number):void {
            for(var y:int = 0 ; y < (yMax + 1) ; y++) {
                var xPosition:int = xMax * squareLength;
                var yPosition:int = y * squareLength;
                layer.graphics.moveTo(0, yPosition);
                layer.graphics.lineTo(xPosition, yPosition);
            }
        }
        
        private function getCreatePointOnCardLayer():Point {
            return new Point(cardLayer.mouseX, cardLayer.mouseY);
        }
        
        public function getMouseCurrentPoint():Point {
            return getLayerPoint(baseLayer);
        }
        
        private function getCreatePoint():Point {
            return getLayerPoint(baseLayer);
        }
        
        private function getLayerPoint(layer:UIComponent):Point {
            var mouseX:Number = layer.mouseX;
            var mouseY:Number = layer.mouseY;
            Log.logging("mouseX", mouseX);
            Log.logging("mouseY", mouseY);
            
            var characterPositionX:int = mouseX / getSquareLength();
            var characterPositionY:int = mouseY / getSquareLength();
            Log.logging("characterPositionX", characterPositionX);
            Log.logging("characterPositionY", characterPositionY);
            
            return new Point(characterPositionX, characterPositionY);
        }
        
        private function addCharacter(event:ContextMenuEvent):void {
            var point:Point = getCreatePoint();
            AddCharacterWindow.setCharacterPosition(point.x, point.y);
            
            Log.logging("DodontoF.popup(AddCharacterWindow, true);");
            DodontoF.popup(AddCharacterWindow, true);
        }
        
        private function addMagicRange(event:ContextMenuEvent):void {
            var point:Point = getCreatePoint();
            AddMagicRangeWindow.setCharacterPosition(point.x, point.y);
            
            Log.logging("DodontoF.popup(AddMagicRangeWindow, true);");
            DodontoF.popup(AddMagicRangeWindow, true);
        }
        
        private function addMagicRangeDD4th(event:ContextMenuEvent):void {
            var point:Point = getCreatePoint();
            AddMagicRangeDD4thWindow.setCharacterPosition(point.x, point.y);
            
            Log.logging("DodontoF.popup(AddMagicRangeDD4thWindow, true);");
            DodontoF.popup(AddMagicRangeDD4thWindow, true);
        }
        
        private function addMagicTimer(event:ContextMenuEvent):void {
            DodontoF.popup(AddMagicTimerWindow, true);
        }
        
        private function addMapMask(event:ContextMenuEvent):void {
            DodontoF.popup(AddMapMaskWindow, false);
        }
        
        private function addMapMarker(event:ContextMenuEvent):void {
            var window:AddMapMarkerWindow = DodontoF.popup(AddMapMarkerWindow, false) as AddMapMarkerWindow;
            //var point:Point = menuClickPoint;
            //window.setPosition(point.x, point.y);
        }
        
        /*
        private function addStatusMarker(event:ContextMenuEvent):void {
            var point:Point = menuClickPoint;
            
            var window:AddStatusMarkerWindow = DodontoF.popup(AddStatusMarkerWindow, false) as AddStatusMarkerWindow;
            window.setPosition(point.x, point.y);
        }
        */
        
        private function addDiceSymbol(event:ContextMenuEvent):void {
            DodontoF.popup(StockDiceSymbolWindow, false);
            /*
            var point:Point = menuClickPoint;
            var ownerName:String = DodontoF_Main.getInstance().getChatWindow().getChatCharacterName();
            var jsonData:Object = DiceSymbol.getJsonData(6, 1, ownerName, point.x, point.y);
            DodontoF_Main.getInstance().getGuiInputSender().getSender().addCharacter(jsonData, "ownerName");
            */
        }
        
        public function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            menu.addEventListener(ContextMenuEvent.MENU_SELECT, function(event:ContextMenuEvent):void {
                    thisObj.menuClickPoint = getCreatePoint();
                });
            
            MovablePiece.addMenuItem(menu, "キャラクター追加", addCharacter);
            MovablePiece.addMenuItem(menu, "魔法範囲追加(D＆D3版)", addMagicRange);
            MovablePiece.addMenuItem(menu, "魔法範囲追加(D＆D4版)", addMagicRangeDD4th);
            MovablePiece.addMenuItem(menu, "魔法タイマー追加", addMagicTimer);
            MovablePiece.addMenuItem(menu, "マップマスク追加", addMapMask);
            MovablePiece.addMenuItem(menu, "マップマーカー追加", addMapMarker);
            //MovablePiece.addMenuItem(menu, "状態マーカー追加", addStatusMarker);
            MovablePiece.addMenuItem(menu, "ダイスシンボル追加", addDiceSymbol, true);
            
            overMapLayer.contextMenu = menu;
        }
        
        private function initCardLayer():void {
            var color:int = 0xFFFFFF;
            cardLayer.graphics.lineStyle(5, color);
            cardLayer.graphics.beginFill(color);
            
            color = 0x2E8B57;
            cardLayer.graphics.beginFill(color);
            cardLayer.graphics.drawRect(0,
                                        0,
                                        1600, 1200);
            cardLayer.scaleX = 0.5;
            cardLayer.scaleY = 0.5;
            
            cardLayer.visible = false;
            
            cardLayer.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    event.stopPropagation();
                    
                    cardLayer.startDrag();
                });
            
            cardLayer.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
                    event.stopPropagation();
                    
                    cardLayer.stopDrag();
                });
            
            initCardLayerContextMenu();
        }
        private function initCardLayerContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            
            menu.hideBuiltInItems();

            MovablePiece.addMenuItem(menu, "手札置き場の作成", addCardZone);
            MovablePiece.addMenuItem(menu, "メッセージカードの追加", addMessageCard, true);
            
            cardLayer.contextMenu = menu;
        }
        
        private function addCardZone(event:ContextMenuEvent):void {
            var point:Point = getCreatePointOnCardLayer();
            DodontoF_Main.getInstance().getGuiInputSender().getSender().addCardZone(Card.getSelfOwnerId(),
                                                                                    Card.getSelfOwnerName(),
                                                                                    point.x, point.y);
        }
        
        
        private function addMessageCard(event:ContextMenuEvent):void {
            var window:AddMessageCardWindow = DodontoF.popup(AddMessageCardWindow, true) as AddMessageCardWindow;
            var point:Point = getCreatePointOnCardLayer();
            window.setCreatePoint(point);
        }
        
        
        public function zoomCardLayer(isZoom:Boolean):void {
            cardLayer.stopDrag();
            
            var cardZoomRate:Number = cardZoomRateDefault;
            if( ! isZoom ) {
                cardZoomRate = (1.0 / cardZoomRate);
            }
            
            centerZoomingToMousePiont(cardLayer, cardZoomRate);
            
            cardLayer.scaleX *= cardZoomRate;
            cardLayer.scaleY *= cardZoomRate;
        }
        
        public function getTrushMountIfHit(card:Card):CardTrushMount {
            
            if( ! card.isTrashable() ) {
                return null;
            }
            
            var trushMounts:Array = getTargetTypes(CardTrushMount.getTypeStatic());
            
            for(var i:int = 0 ; i < trushMounts.length ; i++) {
                var trushMount:CardTrushMount = trushMounts[i];
                if( trushMount == null ) {
                    continue;
                }
                
                if( trushMount.getMountName() != card.getMountName()) {
                    continue;
                }
                
                if( trushMount.hitTestObject(card) ) {
                    return trushMount;
                }
            }
            
            return null;
        }
        
        public function isFloorTileEditMode():Boolean {
            return ( ! overMapLayer.visible );
        }
        
        public function setFloorTileEditMode(b:Boolean):void {
            overMapLayer.visible = ( ! b);
        }
    }
}
