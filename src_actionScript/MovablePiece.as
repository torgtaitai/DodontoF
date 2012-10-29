//--*-coding:utf-8-*--

package {
    
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import mx.core.UIComponent;
    import mx.effects.Move;
    import mx.effects.Glow;
    import mx.effects.Parallel;
    import mx.events.EffectEvent;
    import mx.managers.PopUpManager;
    import mx.utils.ArrayUtil;
    import mx.controls.Image;
    
    public class MovablePiece implements Piece {
        
        protected var view:ImageSprite = new ImageSprite();
        
        protected static var dodontoF:DodontoF;
        
        private static var defaultId:String = "0";
        protected var id:String = defaultId;
        private var draggable:Boolean = true;
        
        private var rotation:Number = 0;
        protected var rotater:Rotater;
        
        private var positionX:Number = 0;
        private var positionY:Number = 0;
        
        private var lastParams:Object = null;
        private var map:Map = null;
        
        private var isInitMoved:Boolean = true;
        
        public static function getDefaultId():String {
            return defaultId;
        }
        
        protected function getMap():Map {
            return DodontoF_Main.getInstance().getMap();
        }
        
        private var thisObj:MovablePiece;
        
        protected static var sender:SharedDataSender;
        public static function setSharedDataSender(sender_:SharedDataSender):void {
            sender = sender_;
        }
        
        public static function setDodontoF(dodontoF_:DodontoF):void {
            dodontoF = dodontoF_;
        }
        
        public function getType():String {
            throwNotImplimentedError("getType");
            return "";
        }
        
        public function getTypeName():String {
            return "コマ基本クラス";
        }
        
        public static function getJsonData(type:String,
                                           createPositionX:Number,
                                           createPositionY:Number, 
                                           draggable:Boolean = false,
                                           rotation:Number = 0):Object {
            var jsonData:Object = new Object();
            
            jsonData.type = type;
            jsonData.imgId = defaultId;
            jsonData.x = createPositionX;
            jsonData.y = createPositionY;
            jsonData.rotation = rotation;
            jsonData.draggable = draggable;
            
            return jsonData;
        }
        
        public function getJsonDataEmptyId():Object {
            var jsonData:Object = getJsonData();
            jsonData.imgId = defaultId;
            return jsonData;
        }
        public function getJsonData():Object {
            var jsonData:Object = new Object();
            
            jsonData.type = getType();
            jsonData.imgId = this.getId();
            jsonData.x = this.getX();
            jsonData.y = this.getY();
            jsonData.rotation = this.getRotation();
            jsonData.draggable = this.getDraggable();
            
            return jsonData;
        }
        
        
        public function MovablePiece(params:Object) {
            thisObj = this;
            parallels = new Array();
            
            this.id = params.imgId;
            this.draggable = params.draggable;
            setRotation( params.rotation );
            
        }
        
        protected function canRotate():Boolean {
            return false;
        }
        
        private function initRotater():void {
            if( ! canRotate() ) {
                return;
            }
            
            rotater = new Rotater();
            rotater.init(view, this);
        }
        
        public function getX():Number {
            return positionX;
        }
        
        public function getY():Number {
            return positionY;
        }
        
        public function getViewX():Number {
            return view.x;
        }
        
        public function getViewY():Number {
            return view.y;
        }
        
        public function getSquareLength():int {
            return Map.getSquareLength();
        }
        
        public function isHideMode():Boolean {
            return false;
        }
        
        
        public function addViewPosition(addX:Number, addY:Number):void {
            if( view == null ) {
                return;
            }
            
            view.x = positionX * getSquareLength() + addX;
            view.y = positionY * getSquareLength() + addY;
        }
        
        
        public function getDraggable():Boolean {
            return draggable;
        }
        
        public function init(map_:Map, x:Number, y:Number):void {
            initBegin();
            
            map = map_;
            
            initContextMenu();
            initDraw(x, y);
            initEventAll();
            
            getMapLayer().addChild(view);
            snapViewPosition();
            
            initEnd();
        }
        
        protected function initBegin():void {
        }
        
        protected function initEnd():void {
        }
        
        protected function initContextMenu():void {
            throwNotImplimentedError("initContextMenu");
        }
        
        public function getName():String {
            return "";
        }
        
        public function isGotoGraveyard():Boolean {
            return true;
        }
        
        public function addMenuItem(menu:ContextMenu,
                                    title:String,
                                    function_:Function,
                                    separatorBefore:Boolean = false):ContextMenuItem {
            return MovablePiece.addMenuItem(menu, title, function_, separatorBefore);
        }
        
        static public function addMenuItem(menu:ContextMenu,
                                           title:String,
                                           function_:Function,
                                           separatorBefore:Boolean = false):ContextMenuItem {
            var item:ContextMenuItem = new ContextMenuItem(title);
            item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function_);
            item.separatorBefore = separatorBefore;
            menu.customItems.push(item);
            
            return item;
        }
        
        protected function getContextMenuItemRemoveCharacter(event:ContextMenuEvent):void {
            sendDelete();
        }
        
        public function sendDelete():void {
            sender.removeCharacter(this);
            deleteFromMap();
        }
        
        public function deleteFromMap():void {
            this.remove();
            getMap().removeExistPieces(this);
        }
        
        
        public function remove():void {
            if( view == null ) {
                return;
            }
            
            getMapLayer().removeChild(view);
            view = null;
        }
        
        public function getMapLayer():UIComponent {
            throwNotImplimentedError("getMapLayer");
            return null;
        }
        
        static private var draggingPiece:MovablePiece = null;
        
        protected function initEvent():void {
        }
        
        protected function isDragging():Boolean {
            return (draggingPiece != null);
        }
        
        protected function isSetViewForevroungOnMouseClicked():Boolean {
            if( Rotater.isAnyRotating() ) {
                return false;
            }
            
            return false;
        }
        
        protected function dragged():void {
        }
        
        protected function mouseDownEvent(event:MouseEvent):void {
            if( isSetViewForevroungOnMouseClicked() ){
                thisObj.setViewForeground();
            }
            
            view.startDrag();
            draggingPiece = thisObj;
            dragged();
        }
        
        protected function initEventAll():void {
            view.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    Rotater.stopRotation();
                    
                    if( thisObj.isOnlyOwnMap() ) {
                        return;
                    }
                    
                    if( ! thisObj.getDraggable() ) {
                        return;
                    }
                    
                    event.stopPropagation();
                    
                    mouseDownEvent(event);
                });
            
            view.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
                    if( draggingPiece == null ) {
                        return;
                    }
                    
                    Config.getInstance().setMouseEvent(event);
                    
                    draggingPiece.stopDragging();
                    draggingPiece = null;
                    
                    Config.getInstance().setMouseEvent(null);
                });
            
            view.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
                    if( isDragging() ) {
                        return;
                    }
                    
                    thisObj.zoomLittleForTeachDraggable();
                    thisObj.extendMovablePieceViewPosition( true );
                });
            
            view.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
                    if( isDragging() ) {
                        return;
                    }
                    
                    thisObj.shrinkLittleForTeachDraggable();
                    thisObj.extendMovablePieceViewPosition( false );
                });
            
            setWheelEvent();
            
            initEvent();
            initRotater();
            //            initTurnUper();
        }
        
        
        private function setWheelEvent():void {
            
            //複数キャラクターが積み上がっている場合には、ホイールで順番入れ替え
            view.addEventListener(MouseEvent.MOUSE_WHEEL, function (event:MouseEvent):void {
                    
                    if( ! thisObj.canExtend() ) {
                        return;
                    }
                    
                    var isUp:Boolean = (event.delta > 0);
                    thisObj.rotateViewIndex(isUp);
                    var extended:Boolean = thisObj.extendMovablePieceViewPosition( true );
                    
                    //積み上げキャラを入れ替えしたなら、マップの拡大・縮小は行わない
                    if( extended ) {
                        event.stopPropagation();
                    }
                });
        }
        
        
        private function rotateViewIndex(isUp:Boolean):void {
            var point:Point = new Point(getX(), getY());
            var pieceList:Array = getMap().getSamePositionMovablePieciesOrderdByViewIndex(point);
            
            if( pieceList.length <= 1 ) {
                return;
            }
            
            var first:MovablePiece = pieceList[0] as MovablePiece;
            var last:MovablePiece = pieceList[pieceList.length - 1] as MovablePiece;
            
            if( first == null || last == null ) {
                return;
            }
            
            if( isUp ) {
                first.setViewForeground();
            } else {
                var index:int = first.getViewIndex();
                last.setViewIndex(index);
            }
        }
        
        
        private var isLittleZoomed:Boolean = true;
        
        public function zoomLittleForTeachDraggable():void {
            //移動不可なら「ちょっと拡大」はしない。
            if( ! this.getDraggable() ) {
                return;
            }
            
            if( ! canLittleZoom() ) {
                return;
            }
            
            isLittleZoomed = true;
            
            var zoomPix:int = 3;
            var zoomRate:Number = 1 + (zoomPix / this.getOwnWidth());
            
            this.view.scaleX = zoomRate;
            this.view.scaleY = zoomRate;
        }
        
        public function shrinkLittleForTeachDraggable():void {
            if( ! isLittleZoomed ) {
                return;
            }
            
            this.view.scaleX = 1.0;
            this.view.scaleY = 1.0;
        }
        
        public function canLittleZoom():Boolean {
            var point:Point = new Point(positionX, positionY);
            var samePosition:Array = map.getSamePositionMovablePieciesOrderdByViewIndex(point);
            return (samePosition.length == 1);
        }
        
        private function extendMovablePieceViewPosition(isListed:Boolean):Boolean {
            if( ! canExtend() ) {
                return false;
            }
            
            return map.extendMovablePieceViewPosition( new Point(positionX, positionY), isListed );
        }
        
        public function setPickuped():void {
            extendMovablePieceViewPosition(false);
        }
        
        public function canExtend():Boolean {
            return true;
        }
        
        public function setDraggable(value:Boolean):void {
            this.draggable = value;
        }
        
        public function stopDragging():void {
            Log.logging("snapViewPosition at ", thisObj.id);
            
            view.stopDrag();
            
            var isMoved:Boolean = thisObj.snapViewPosition();
            if( isMoved ) {
                droped();
                sender.moveCharacter(thisObj, thisObj.getX(), thisObj.getY());
                //sender.changeCharacter(thisObj.getJsonData());
            }
        }
        
        protected function droped():void {
        }
        
        
        public function setViewIndex(index:int):void {
            if( view != null ) {
                this.getMapLayer().setChildIndex(view, index);
                //Log.loggingError("setViewIndex index", index);
            }
        }
        
        public function setViewForeground():void {
            setViewIndex( getMapLayer().numChildren - 1 );
        }
        
        public static function isChangedParam(params:Object, thisLastParams:Object):Boolean {
            if( thisLastParams == null) {
                return true;
            }
            
            for(var key:String in params) {
                if( params[key] != thisLastParams[key] ) {
                    return true;
                }
            }
            return false;
        }
        
        public function canMoveMode():Boolean {
            if( DodontoF_Main.getInstance().isReplayMode() ) {
                return false;
            }
            if( DodontoF_Main.getInstance().isVisiterMode() ) {
                return false;
            }
            
            return true;
        }
        
        public function analyzeChangedCharacter(params:Object):Boolean {
            //最後に取得したparamsと同値＝データ変更なしなので処理終了
            if( ! isChangedParam(params, this.lastParams) ) {
                return false;
            }
            this.lastParams = params;
            
            this.draggable = params.draggable;
            
            if( ! canMoveMode() ) {
                this.draggable = false;
            }
            
            isUpdateCalled = false;
            update(params);
            if( ! isUpdateCalled ) {
                throw new Error("Movable.update() is NOT called in override class update method!");
            }
            
            return true;
        }
        
        private var isUpdateCalled:Boolean = false;
        
        protected function update(params:Object):void {
            setRotation( params.rotation );
            updateRotater();
            
            isUpdateCalled = true;
        }
        
        protected function updateRotater():void {
            if( rotater != null ) {
                rotater.update();
            }
        }
        
        public function updateByOwn():void {
            this.update( this.getJsonData() );
        }
        
        public function move(x:Number, y:Number, isForce:Boolean = false):Boolean {
            if( ! isForce ) {
                if( isDragging() ) {
                    return false;
                }
            }
            
            var isMoved:Boolean = false
            if( positionX != x ) {
                positionX = x;
                isMoved = true;
            }
            
            if( positionY != y ) {
                positionY = y;
                isMoved = true;
            }
            
            if( isMoved ) {
                executeMoveEffect();
                
                if( rotater != null ) {
                    rotater.stopRotation();
                }
            }
            
            this.setPickuped();
            
            return isMoved;
        }
        
        private function getMoveData():Object {
            var moveData:Object = new Object();
            moveData.xTo = positionX * getSquareLength();
            moveData.yTo = positionY * getSquareLength();
            return moveData;
        }
        
        private var parallels:Array;
        
        private function moveToCurrentPosition():void {
            var moveData:Object = getMoveData();
            thisObj.view.x = moveData.xTo;
            thisObj.view.y = moveData.yTo;
        }
        
        protected function initCreation():void {
        }
        
        private function executeMoveEffect():void {
            if( isCreating() ) {
                initCreation();
                moveToCurrentPosition();
                return;
            }
            
            if( isInitMoved ) {
                isInitMoved = false;
                moveToCurrentPosition();
                return;
            }
            
            var parallel:Parallel = new Parallel();
            
            var moveResultFunction:Function = function(event:EffectEvent = null):void {
                moveToCurrentPosition();
                
                var index:int = ArrayUtil.getItemIndex(parallel, thisObj.parallels);
                if( index >= 0 ) {
                    thisObj.parallels[index] = null;
                }
            };
            
            var moveData:Object = getMoveData();
            setMoveParallel(moveData, parallel, moveResultFunction);
            
            if( isDragging() ) {
                moveResultFunction();
                return;
            }
            
            parallels.push(parallel);
            
            parallel.play();
        }
        
        private function isCreating():Boolean {
            return (this.id == defaultId);
        }
        
        private function setMoveParallel(moveData:Object,
                                         parallel:Parallel, 
                                         moveResultFunction:Function):void {
            parallel.addEventListener(EffectEvent.EFFECT_END, moveResultFunction);
            parallel.addChild( getGlowEffect() );
            parallel.addChild( getMoveEffect(moveData) );
            parallel.target = view;
        }
        
        private function getGlowEffect():Glow {
            var glow:Glow = new Glow();
            glow.duration = 1500;
            glow.alphaFrom = 1.0;
            glow.alphaTo = 0.0;
            glow.blurXFrom = 70.0;
            glow.blurXTo = 0.0;
            glow.blurYFrom = 70.0;
            glow.blurYTo = 0.0;
            glow.color = 0xFFFF00;
            return glow;
        }
        
        private function getMoveEffect(moveData:Object):Move {
            var moveEffect:Move = new Move();
            moveEffect.duration = 500;
            moveEffect.xTo = moveData.xTo;
            moveEffect.yTo = moveData.yTo;
            
            return moveEffect;
        }
        
        
        public function getId():String {
            return id;
        }
        
        public function isOnlyOwnMap():Boolean {
            return (id == defaultId);
        }
        
        
        public function canExtendOnPositionX():Boolean {
            return false;
        }
        
        public function canExtendOnPositionY():Boolean {
            return false;
        }
        
        public function getViewIndex():int {
            try {
                return getMapLayer().getChildIndex(view);
            } catch (e:Error) {
            }
            return -1;
        }
        
        public function getWidth():int {
            return 1;
        }
        
        public function getHeight():int {
            return getWidth();
        }
        
        public function snapViewPosition():Boolean {
            var point:Point = getMap().getSnapViewPoint(view.x, view.y, getSquareLength());
            view.x = point.x * getSquareLength();
            view.y = point.y * getSquareLength();
            
            return move(point.x, point.y, true);
        }
        
        protected function initDraw(x:Number, y:Number):void {
            throwNotImplimentedError("initDraw");
        }
        
        protected function throwNotImplimentedError(functionName:String):void {
            throw new Error("Movable." + functionName + " is not implimented!");
        }
        
        public function getOwnWidth():int {
            return 1 * Map.getSquareLength();
        }
        
        public function getOwnHeight():int {
            return 1 * Map.getSquareLength();
        }
        
        public function getViewRotationDiff():Number {
            return 0;
        }
        
        public function loadViewImage():void {
            updateRotater();
            
            if( rotater != null ) {
                rotater.setBaseRotation( this.rotation + getViewRotationDiff() );
            }
        }
        
        public function setRotation(rotation:Number):void {
            rotation = ( rotation % 360 );
            this.rotation = rotation;
        }
        
        public function getRotation():Number {
            return this.rotation
        }
        
        public function setDiffRotation(rotationDiff:Number):void {
            var rotation:Number = getRotation();
            rotation += rotationDiff;
            setRotation(rotation);
        }
        
   }
}