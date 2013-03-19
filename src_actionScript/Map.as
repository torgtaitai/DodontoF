//--*-coding:utf-8-*--

package {
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.ui.Keyboard;
    import flash.utils.ByteArray;
    import flash.utils.getQualifiedClassName;
    import mx.controls.Alert;
    import mx.core.UIComponent;
    import mx.utils.ArrayUtil;
    import net.hires.debug.Stats;
    
    
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
        
        private var zoomRate:Number = 1.2;
        private var currentZoomRate:Number = 1.0;

        private var extractViewRate:Number = 0.97;//0.9;
        
        protected var baseLayer:UIComponent = new UIComponent();
        protected var imageLayer:ImageSprite = new ImageSprite();
        protected var mapTileLayer:UIComponent = new UIComponent();
        protected var marksLayer:UIComponent = new UIComponent();
        
        private var mapPainter:MapPainter = new MapPainter();
        
        protected var overMapLayer:UIComponent = new UIComponent();
        
        protected var clickMapLayer:UIComponent = new UIComponent();
        protected var gridPositionLayer:UIComponent = new UIComponent();
        protected var magicRangeLayer:UIComponent = new UIComponent();
        protected var mapMaskLayer:UIComponent = new UIComponent();
        protected var mapMarkerLayer:UIComponent = new UIComponent();
        protected var gridLayer:UIComponent = new UIComponent();
        protected var cardLayer:UIComponent = new UIComponent();
        protected var characterLayer:UIComponent = new UIComponent();
        protected var hideCharacterLayer:UIComponent = new UIComponent();
        protected var frontLayer:UIComponent = new UIComponent();
        protected var rulerLayer:UIComponent = new UIComponent();
        
        static private var thisObj:Map;
        
        private var imageUri:String = "";
        private var mirrored:Boolean = false;
        private var mapWidth:int = 1;
        private var mapHeight:int = 1;
        private var gridColor:uint = 0x000000;
        private var gridInterval:int = 1;
        private var isAlternately:Boolean = false;
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
            
            existPieces.splice(index, 1);
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

        public function findCharacterByName(name:String):Character {
            var characters:Array = findExistPiecesByTypeName(Character.getTypeStatic());
            
            for(var i:int = 0 ; i < characters.length ; i++) {
                var character:Character = characters[i];
                
                if( character.getName() == name ) {
                    return character;
                }
            }
            
            return null;
        }
        
        public function getTargetTypes(targetTypes:Array):Array {
            var results:Array = new Array();
            
            for(var i:int = 0 ; i < existPieces.length ; i++) {
                var piece:Piece = existPieces[i];
                
                for each( var type:String in targetTypes ) {
                    if( piece.getType() != type ) {
                        continue;
                    }
                    
                    results.push(piece);
                }
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
            }
            
            result.sort(sortedByViewIndex);
            
            return result;
        }
        
        
        public function extendMovablePieceViewPosition(point:Point, isListed:Boolean = false):Boolean {
            
            //コマの回転中なら展開は全て一時取りやめ。
            if( Rotater.isAnyRotating() ) {
                return false;
            }
            
            var xCharacters:Array = new Array();
            var yCharacters:Array = new Array();
            var cards:Array = new Array();
            
            var characters:Array = getSamePositionMovablePieciesOrderdByViewIndex(point);
            
            for(var i:int = 0 ; i < characters.length ; i++) {
                var character:MovablePiece = characters[i];
                
                var card:Card = character as Card;
                if( card != null ) {
                    if( card.isForeground() ) {
                        cards.push(card);
                    }
                    continue;
                }
                
                if( character.canExtendOnPositionX() ) {
                    xCharacters.push(character);
                    continue;
                }
                
                if( character.canExtendOnPositionY() ) {
                    yCharacters.push(character);
                    continue;
                }
            }
            
            var cardExtended:Boolean = extendSortedCharacterToViewPosition(cards,       isListed, true);
            var xExtended:Boolean = extendSortedCharacterToViewPosition(xCharacters, isListed, true);
            var yExtended:Boolean = extendSortedCharacterToViewPosition(yCharacters, isListed, false, xCharacters);
            
            var extended:Boolean = (cardExtended || xExtended || yExtended);
            
            return extended;
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
        
        private function extendSortedCharacterToViewPosition(characters:Array, 
                                                             isListed:Boolean,
                                                             isX:Boolean,
                                                             samePositionCharactersOnBorderLine:Array = null):Boolean {
            if( samePositionCharactersOnBorderLine == null ) {
                samePositionCharactersOnBorderLine = new Array();
            }
            
            //Log.loggingTest("characters.length", characters.length);
            //Log.loggingTest("samePositionCharactersOnBorderLine.length", samePositionCharactersOnBorderLine.length);
            
            if(( characters.length <= 1 ) && (samePositionCharactersOnBorderLine.length == 0)) {
                return false;
            }
            
            var extended:Boolean = false;
            
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
                
                var newPosition:int = (widthPadding - (totalWidth / 2) + (maxSize / 2))
                    * getSquareLength() * extractViewRate;
                
                widthPadding += (isX ? character.getWidth() : character.getHeight());
                
                //Y軸展開の場合でX軸上にキャラがいるなら、真ん中に「X軸キャラの最大高さ分だけ」の空間を空けたい
                if( ! isX ) {
                    newPosition = getNewPositionForExtendOnY(newPosition, i, characters,
                                                             samePositionCharactersOnBorderLine);
                }
                
                addViewPosition(character, newPosition, isX);
                extended = true;
            }
            
            return extended;
        }
        
        private function getNewPositionForExtendOnY(newPosition:int,
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
        
        
        public function getCharacterPointFromGlobalPoint(globalPoint:Point):Point {
            var mapLocalPoint:Point = getCharacterLayer().globalToLocal( globalPoint );
            var dropMapPoint:Point = getSnapViewPoint(mapLocalPoint.x, mapLocalPoint.y, getSquareLength());
            return dropMapPoint;
        }
        
        public function getSnapViewPoint(viewX:Number, viewY:Number, squareLength:int):Point {
            var y:Number = getSnapPositionFromViewPosition(viewY, squareLength, false);
            
            var isAlternatelyLocal:Boolean = isAlternatelyPosition(y);
            var x:Number = getSnapPositionFromViewPosition(viewX, squareLength, isAlternatelyLocal);
            
            return new Point(x, y);
        }
        
        private function getSnapPositionFromViewPosition(position:Number, squareLength:int,
                                                                isAlternatelyLocal:Boolean):Number {
            Log.logging("position : ", position);
            
            var newPosition:Number = (position / squareLength);
            
            if( isAlternatelyLocal ) {
                newPosition += 0.5;
            }
            if( Config.getInstance().isSnapMovablePieceMode() ) {
                newPosition = Math.round( newPosition );
            }
            if( isAlternatelyLocal ) {
                newPosition -= 0.5;
            }
            
            Log.logging("newPosition : ", newPosition);
            
            return newPosition;
        }
        
        public function isAlternatelyPosition(y:Number):Boolean {
            Log.logging("isAlternatelyPosition Begin");
            
            
            if( ! isAlternately ) {
                Log.logging("そもそも、マス目は互い違い設定じゃなかった");
                return false;
            }
            
            var gridInterval:int = thisObj.getGridInterval();
            
            if( (gridInterval % 2) == 0 ) {
                Log.logging("マス間隔が偶数なら半マスずらす必要なし");
                return false;
            }
            
            Log.logging("マス間隔が奇数の場合");
            
            if( ! isAlternatelyY(y) ) {
                Log.logging("Y座標から半マスずらす必要なしと判断");
                return false;
            }
            
            Log.logging("マス目の互い違いにあわせる必要があるよ！");
            return true;
        }
        
        
        
        public function Map() {
            thisObj = this;
            initMapLayerEvent();
        }

        private function initMapLayerEvent():void {
            //マウスロールオーバー時の挙動（立ち絵隠し）の登録
            var layers:Array = [this.baseLayer];
            
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
            
            baseLayer.addChild( mapPainter.getOtherDrawLayer() );
            mapPainter.init(this);
            
            baseLayer.addChild(overMapLayer);
            
            clickMapLayer.alpha = 0.01;
            overMapLayer.addChild(clickMapLayer);
            
            overMapLayer.addChild(gridPositionLayer);
            overMapLayer.addChild(hideCharacterLayer);
            overMapLayer.addChild(mapMaskLayer);
            overMapLayer.addChild(magicRangeLayer);
            overMapLayer.addChild(gridLayer);
            overMapLayer.addChild(mapMarkerLayer);
            overMapLayer.addChild(cardLayer);
            overMapLayer.addChild(characterLayer);
            overMapLayer.addChild(rulerLayer);
            
            rulerLayer.visible = false;
            
            parent.addChild(baseLayer);
            parent.addChild(frontLayer);
        }
        
        public function addPaformanceMonitor():void {
            overMapLayer.addChild( new Stats() );
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
        
        public function isMirrored():Boolean {
            return mirrored;
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
        
        public function isAlternatelyMode():Boolean {
            return this.isAlternately;
        }
        
        public function getGridInterval():int {
            return gridInterval;
        }
        
        public function setGridInterval(value:int):void {
            if( value < 1 ) {
                value = 1;
            }
            
            this.gridInterval = value;
        }
        
        public function setVisibleGridPositionLayer(visible:Boolean):void {
            gridPositionLayer.visible = visible;
        }
        
        public function setVisibleGridLayer(visible:Boolean):void {
            gridLayer.visible = visible;
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
            setWheelEvent();
            //setKeyDownEvent();
            
            setMouseDownEvent();
            setMouseUpEvent();
            
            setRulerEvent();
        }
        
        private function setWheelEvent():void {
            var zoomEvent:Function = function (event:MouseEvent):void {
                var isZoom:Boolean = (event.delta > 0);
                thisObj.zoom(isZoom);
            };
            
            getView().addEventListener(MouseEvent.MOUSE_WHEEL, zoomEvent);
        }
        
        /*
        private function setKeyDownEvent():void {
            Log.logging("setKeyDownEvent Begin");
            
            var zoomEvent:Function = function (event:KeyboardEvent):void {
                Log.logging("setKeyDownEvent zoomEvent");
                
                var isZoom:Boolean = false;
                
                if( event.keyCode != Keyboard.	PAGE_UP ) {
                    isZoom = true;
                } else if( event.keyCode != Keyboard.PAGE_DOWN ) {
                    isZoom = false;
                } else {
                    return;
                }
                
                thisObj.zoom(isZoom);
            };
        }
        */
        
        
        public function undoDrawOnMap(resultFunction:Function):void {
            mapPainter.undoDrawOnMap(resultFunction);
        }
        
        public function setDrawState(size:int, color:uint, isErase:Boolean, isLine:Boolean):void {
            mapPainter.setDrawState(size, color, isErase);
            mapPainter.setStraightLineMode(isLine);
        }
        
        public function setDrawMode(b:Boolean):void {
            mapPainter.setDrawMode(b);
        }
        
        public function getDrawMode():Boolean {
            return mapPainter.getDrawMode();
        }
        
        
        private function setMouseDownEvent():void {
            baseLayer.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    
                    if( getDrawMode() ) {
                        mapPainter.beginDrawByPen(event);
                    } else {
                        baseLayer.startDrag();
                        Character.unSelectAllCharacters();
                    }
                    
                    event.stopPropagation();
                });
        }
        
        private function setMouseUpEvent():void {
            baseLayer.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
                    if( getDrawMode() ) {
                        mapPainter.endDrawByPen(event);
                    } else {
                        baseLayer.stopDrag();
                    }
                });
        }
        
        
        public function stopDrag():void {
            baseLayer.stopDrag();
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
                        
                        var xPadding:Number = 0;
                        if( isAlternatelyPosition(y) ) {
                            xPadding = -1 * getSquareLength() / 2;
                        }
                        
                        if( color >= 0 ) {
                            Log.logging("drawing...");
                            Log.logging("x", x * getSquareLength());
                            Log.logging("y", y * getSquareLength());
                            Log.logging("getSquareLength", getSquareLength());
                            marksLayer.graphics.beginFill(color);
                            marksLayer.graphics.drawRect(x * getSquareLength() + xPadding,
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
        
        
        public function changeDraws(draws:Array):void {
            mapPainter.changeDraws(draws);
        }
        
        public function changeMap(imageUri_:String, mirrored_:Boolean,
                                  mapWidth_:int, mapHeight_:int, gridColor_:uint,
                                  gridInterval_:int, isAlternately_:Boolean):void {
            imageUri = imageUri_;
            mirrored = mirrored_;
            mapWidth = mapWidth_;
            mapHeight = mapHeight_;
            gridColor = gridColor_;
            setGridInterval( gridInterval_ );
            isAlternately = isAlternately_;
            
            drawBackGround(baseLayer);
            drawGridPosition(mapWidth, mapHeight);
            drawGridOnMap();
            
            imageLayer.setMirrored(mirrored);
            imageLayer.loadImageWidthHeight(imageUri, mapWidth, mapHeight);
            drawBackGround(clickMapLayer);
        }
        
        private function drawBackGround(layer:UIComponent):void {
            layer.graphics.clear();
            layer.graphics.lineStyle(5, 0x000000);
            layer.graphics.beginFill(0xFFFFFF);
            layer.graphics.drawRect(0, 0, (mapWidth * getSquareLength()), (mapHeight * getSquareLength()));
            layer.graphics.endFill();
        }
        
        private var gridPositionList:Vector.<Bitmap> = new Vector.<Bitmap>();
        
        private function drawGridPosition(xMax:int, yMax:int):void {
            while( gridPositionList.length > 0 ) {
                gridPositionLayer.removeChild(gridPositionList.shift());
            }
            
            gridPositionLayer.graphics.clear();
            
            var squareLength:int = getSquareLength() * gridInterval;
            
            for(var x:int = 0 ; x < xMax ; x++) {
                if(( x % gridInterval) != 0 ) {
                    continue;
                }
                var xIndex:int = x / gridInterval;
                
                for(var y:int = 0 ; y < yMax ; y++) {
                    if(( y % gridInterval) != 0 ) {
                        continue;
                    }
                    
                    if( isOutOfMapPosition(x, y, xMax, yMax) ) {
                        continue;
                    }
                    
                    var yIndex:int = y / gridInterval;
                    drawGridPositionOne(xIndex, yIndex, squareLength);
                }
            }
        }
        
        public function isOutOfMapPosition(x:int, y:int, xMax:int, yMax:int):Boolean {
            Log.logging("\r\rx:" + x + ", xMax:" + xMax + ", y:" + y + ", yMax:" + yMax);
            Log.logging("gridInterval", gridInterval);
            Log.logging("isAlternatelyY(y)", isAlternatelyY(y));
            
            var endX:Number = getMapPositionEndPoint(x, isAlternatelyY(y));
            
            if( isAlternatelyY(y) ) {
                endX += (gridInterval / 2);
            }
            Log.logging("endX", endX);
            
            if( endX >= xMax ) {
                Log.logging("x over");
                return true;
            }
            
            var endY:Number = getMapPositionEndPoint(y);
            Log.logging("endY", endY);
            
            if( endY >= yMax ) {
                Log.logging("y over");
                return true;
            }
            
            return false;
        }
        
        private function getMapPositionEndPoint(v:Number, isAlternatelyYPadding:Boolean = false):Number {
            var result:Number = v + (gridInterval / 2);
            if( isAlternatelyYPadding ) {
                result += 0.5;
            }
            return result;
        }
        
        private function drawGridPositionOne(x:int, y:int, squareLength:int):void {
            var textField:TextField = getGridTextField(squareLength, x, y);
            
            var squareLengthHalf:int = squareLength / 2;
            
            var matrix:Matrix = new Matrix();
            matrix.tx = squareLengthHalf - (textField.width / 2);
            matrix.ty = squareLengthHalf - (textField.height / 2);
            
            var gridPosition:BitmapData = new BitmapData(squareLength, squareLength, true, 0x00000000);
            
            var gridPositionClone:BitmapData = gridPosition.clone();
            gridPositionClone.draw(textField, matrix);
            
            var xPadding:Number = 0;
            if( isAlternatelyYIndex(y) ) {
                xPadding = 0.5;
            }
            
            var gridPositionBitmap:Bitmap = new Bitmap();
            gridPositionBitmap.bitmapData = gridPositionClone;
            gridPositionBitmap.x = (x + xPadding) * squareLength;
            gridPositionBitmap.y = y * squareLength;
            
            gridPositionLayer.addChild( gridPositionBitmap );
            gridPositionList.push( gridPositionBitmap );
        }
        
        private function getGridTextField(length:int, x:int, y:int):TextField {
            var textField:TextField = new TextField();
            
            textField.autoSize = TextFieldAutoSize.LEFT;
            textField.selectable = false;
            textField.textColor = gridColor;
            textField.width = length;
            textField.height = length;
            
            textField.text = "" + (x + 1) + "-" + (y + 1);
            
            return textField;
        }
        
        private function isAlternatelyY(y:int):Boolean {
            var yIndex:int = ( y / gridInterval );
            return isAlternatelyYIndex(yIndex);
        }
        
        private function isAlternatelyYIndex(yIndex:int):Boolean {
            if( ! isAlternately ) {
                return false;
            }
            return ((yIndex % 2) == 0);
        }
        
        private function drawGridOnMap():void {
            drawGrid(mapWidth, mapHeight,
                     gridLayer, getSquareLength(),
                     gridColor, gridInterval, 
                     isAlternately);
        }
        
        public static function drawGrid(xMax:int,
                                        yMax:int,
                                        layer:UIComponent,
                                        squareLength:Number,
                                        color:uint,
                                        gridInterval:int,
                                        isAlternately:Boolean):void {
            Log.logging("Map.drawGrid");
            Log.logging("xMax", xMax);
            Log.logging("yMax", yMax);
            Log.logging("squareLength", squareLength);
            layer.graphics.clear();
            layer.graphics.lineStyle(1, color);
            
            if( isAlternately ) {
                drawGridVerticalAlternately(xMax, yMax, layer, squareLength, gridInterval);
            } else {
                drawGridVertical(xMax, yMax, layer, squareLength, gridInterval);
            }
            drawGridHrison(xMax, yMax, layer, squareLength, gridInterval);
        }
        
        private static function drawGridVertical(xMax:int, yMax:int,
                                                 layer:UIComponent, squareLength:Number,
                                                 interval:int):void {
            var x:int = 0;
            for(; x < xMax ; x++) {
                
                if(( x % interval) != 0 ) {
                    continue;
                }
                
                var xPosition:int = x * squareLength;
                var yPosition:int = yMax * squareLength;
                drawLine(layer, xPosition, 0, xPosition, yPosition);
            }
            
            drawLine(layer, xPosition, 0, xPosition, yPosition);
        }
        
        private static function drawGridVerticalAlternately(xMax:int, yMax:int,
                                                            layer:UIComponent, squareLength:Number,
                                                            interval:int):void {
            var y:int = 0;
            for( ; y < yMax ; y++) {
                if(( y % interval) != 0 ) {
                    continue;
                }
                
                var x:int = 0;
                for(; x < xMax ; x++) {
                    if(( x % interval) != 0 ) {
                        continue;
                    }
                    
                    var xIndex:Number = x;
                    if( (y % (2 * interval)) == 0 ) {
                        xIndex += (1.0 * interval / 2);
                    }
                    if( xIndex > xMax ) {
                        continue;
                    }
                    
                    var x1:int = xIndex * squareLength;
                    
                    var y1:int = y * squareLength;
                    
                    var y2Index:int = Math.min((y + interval), yMax);
                    var y2:int = y2Index * squareLength;
                    
                    drawLine(layer, x1, y1, x1, y2);
                }
            }
        }
        
        private static function drawGridHrison(xMax:int, yMax:int,
                                               layer:UIComponent, squareLength:Number,
                                               interval:int):void {
            var y:int = 0;
            for( ; y < (yMax + 1) ; y++) {
                
                if(( y % interval) != 0 ) {
                    continue;
                }
                
                var xPosition:int = xMax * squareLength;
                var yPosition:int = y * squareLength;
                drawLine(layer, 0, yPosition, xPosition, yPosition);
            }
            
            drawLine(layer, 0, yPosition, xPosition, yPosition);
        }
        
        private static function drawLine(layer:UIComponent, x1:int, y1:int, x2:int, y2:int):void {
            layer.graphics.moveTo(x1, y1);
            layer.graphics.lineTo(x2, y2);
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
            DodontoF.popup(AddCharacterWindow, true);
        }
        
        private function addMagicRange(event:ContextMenuEvent):void {
            var point:Point = getCreatePoint();
            var addMagicRangeWindow:AddMagicRangeWindow = 
                DodontoF.popup(AddMagicRangeWindow, true) as AddMagicRangeWindow;
            
            addMagicRangeWindow.setCharacterPosition(point.x, point.y);
            
            Log.logging("addMagicRange end");
        }
        
        private function addMagicRangeDD4th(event:ContextMenuEvent):void {
            var point:Point = getCreatePoint();
            var addMagicRangeDD4thWindow:AddMagicRangeDD4thWindow
                = DodontoF.popup(AddMagicRangeDD4thWindow, true) as AddMagicRangeDD4thWindow;
            
            addMagicRangeDD4thWindow.setCharacterPosition(point.x, point.y);
            
            Log.logging("addMagicRangeDD4th end");
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
        
        private function addDiceSymbol(event:ContextMenuEvent):void {
            DodontoF.popup(StockDiceSymbolWindow, false);
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
            MovablePiece.addMenuItem(menu, "ダイスシンボル追加", addDiceSymbol, true);
            
            MovablePiece.addMenuItem(menu, "手札置き場の作成", addCardZone, true);
            MovablePiece.addMenuItem(menu, "メッセージカードの追加", addMessageCard);
            
            overMapLayer.contextMenu = menu;
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
        
        private function getCreatePointOnCardLayer():Point {
            return new Point(cardLayer.mouseX, cardLayer.mouseY);
        }
        
        
        public function getTrushMountIfHit(card:Card):CardTrushMount {
            
            if( ! card.isTrashable() ) {
                return null;
            }
            
            var trushMounts:Array = getTargetTypes( [CardTrushMount.getTypeStatic(),
                                                     RandomDungeonCardTrushMount.getTypeStatic()] );
            
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
