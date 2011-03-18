//--*-coding:utf-8-*--

package {
    
    import mx.controls.Alert;
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
    import mx.core.UIComponent;
    import mx.binding.utils.BindingUtils;
    import mx.utils.ArrayUtil;
    
    
    public class Character extends InitiativedMovablePiece {
        
        protected var imageUrl:String = "";
        protected var size:int = 1;
        private var isHide:Boolean = false;
        private var rotation:int = 0;
        private var dogTag:String = "";
        
        private var dogTagTextField:TextField = new TextField();
        private var nameTextField:TextField = new TextField();
        private var thisObj:Character;
        
        public function isHit(comp:UIComponent):Boolean {
            return view.hitTestObject(comp);
        }
        
        /*
        public function updateStatusMarker(isMove:Boolean = false):void {
            var statusMarkers:Array = getMap().findExistPiecesByTypeName( StatusMarker.getTypeStatic() );
            addInfos = new Array();
            
            for(var i:int = 0 ; i < statusMarkers.length ; i++) {
                var marker:StatusMarker = statusMarkers[i] as StatusMarker;
                if( marker.getTargetId() != this.getId() ) {
                    continue;
                }
                
                if( isMove ) {
                    marker.dropedByTargetCharacter(getX(), getY());
                }
                
                addInfos.push(marker.getStatusName());
            }
            
            setToolTip();
        }
        
        private var addInfos:Array = new Array();
        
        override public function getAdditionalInfos():Array {
            return addInfos;
        }
        */
        
        override protected function droped():void {
            //var isMove:Boolean = true;
            //updateStatusMarker(isMove);
        }
        
        public static function getTypeStatic():String {
            return "characterData";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        
        public static function getJsonData(name:String,
                                           imageUrl:String,
                                           size:int,
                                           isHide:Boolean,
                                           initiative:Number,
                                           info:String,
                                           rotation:int,
                                           characterPositionX:int,
                                           characterPositionY:int,
                                           dogTag:String):Object {
            var characterJsonData:Object = {
                "name": name,
                "imageName": imageUrl,
                "size": size,
                "isHide": isHide,
                "initiative": initiative,
                "info": info,
                "rotation": rotation,
                "dogTag":dogTag,
                
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
            
            jsonData.imageName = getImageUrl();
            jsonData.size = getSize();
            jsonData.isHide = isHideMode();
            jsonData.rotation = getRotation();
            jsonData.dogTag = this.dogTag;
            
            return jsonData;
        }
        
        public function getRotation():int {
            return rotation;
        }
        
        public function setImageUrl(url_:String):void {
            this.imageUrl = url_;
        }
        
        public function setSize(size_:int):void {
            this.size = size_;
        }
        
        public function setHide(hide_:Boolean):void {
            if( this.isHide == hide_ ) {
                return;
            }
            
            getMapLayer().removeChild(view);
            this.isHide = hide_;
            getMapLayer().addChild(view);
            DodontoF_Main.getInstance().getInitiativeWindow().refresh();
        }
        
        public function Character(params:Object) {
            super(params);
            
            initTextField(nameTextField);
            initTextField(dogTagTextField);
            
            this.imageUrl = params.imageName;
            this.size = params.size;
            this.isHide = params.isHide;
            this.rotation = params.rotation;
            setDogTag( params.dogTag );
            
            thisObj = this;
            
            setNameTag();
        }
        
        public function getImageUrl():String {
            return imageUrl;
        }
        
        public function getSize():int {
            return size;
        }
        
        override public function getWidth():int {
            return size;
        }
        
        override public function canSnapOnPositionX():Boolean {
            return true;
        }
        
        override public function isHideMode():Boolean {
            return isHide;
        }
        
        override public function getInitiative():Number {
            return super.getInitiative();
        }
        
        override public function setViewIndex(index:int):void {
            if( this.isHide ) {
                return;
            }
            super.setViewIndex(index);
        }

        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, "キャラクターの変更", thisObj.getItemPopUpChangeWindow);
            addMenuItem(menu, "右90度回転", thisObj.getContextMenuItemFunctionObRotateCharacter( 90), true);
            addMenuItem(menu, "180度回転",  thisObj.getContextMenuItemFunctionObRotateCharacter(180));
            addMenuItem(menu, "左90度回転", thisObj.getContextMenuItemFunctionObRotateCharacter(-90));
            addMenuItem(menu,  "−＞ 少し右に傾ける",    thisObj.getContextMenuItemFunctionObRotateCharacter( 30), true);
            addMenuItem(menu,  "＜− 少し左に傾ける",    thisObj.getContextMenuItemFunctionObRotateCharacter(-30));
            addMenuItem(menu, "キャラクターの削除", thisObj.getContextMenuItemRemoveCharacter, true);
            
            //view.contextMenu = menu;
            view.setContexMenu(menu);
        }
        
        protected function getContextMenuItemFunctionObRotateCharacter(rotationDiff:Number):Function {
            return function(event:ContextMenuEvent):void {
                var rotation:Number = thisObj.rotation;
                rotation += rotationDiff;
                rotation = ( rotation % 360 );
                thisObj.rotation = rotation;
                
                thisObj.loadViewImage();
                sender.changeCharacter( thisObj.getJsonData() );
            };
        }
        
        override public function popUpChangeWindow():void {
            try {
                Log.logging("contextmenuevent character change.");
                ChangeCharacterWindow.setCharacter(this);
                Log.logging("DodontoF.popup(ChangeCharacterWindow, true);");
                
                var characterWindow:CharacterWindow = DodontoF.popup(ChangeCharacterWindow, true) as CharacterWindow;
                DodontoF_Main.getInstance().setCharacterWindow(characterWindow);
                
                Log.logging("contextmenuevent character changeend");
            } catch(e:Error) {
                Log.loggingExceptionDebug("Character.popUpChangeWindow()", e);
            }
        }
        
        override protected function getMapLayer():UIComponent {
            if( this.isHide ) {
                return getMap().getHideCharacterLayer();
            }
            
            return getMap().getCharacterLayer();
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>Character update Begin");
            
            Log.logging("super params changed.");
            super.update(params);
            
            Log.logging("character local params changed.");
            this.imageUrl = params.imageName;
            this.size = params.size;
            setHide( params.isHide );
            setRotation( params.rotation );
            setDogTag( params.dogTag );
            //updateStatusMarker();
            
            loadViewImage();
            
            setNameTag();
            setCenterTextFields();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged Characteris changed End");
        }
        
        private function setDogTag(dogTag_:String):void {
            this.dogTag = (dogTag_ == null ? "" : dogTag_);
            
            dogTagTextField.text = this.dogTag;
            dogTagTextField.visible = ( this.dogTag != "" );
        }
        
        private function setNameTag():void {
            nameTextField.text = getName();
        }
        
        private function loadViewImage():void {
            view.loadImageWidthHeightRotation(this.name, this.imageUrl,
                                              this.size, this.size,
                                              this.rotation);
        }
        
        private function setCenterTextFields():void {
            setCenterTextFieldXPosition(nameTextField);
            
            //dogTagTextField = getDogTagTextField(this.dogTag);
            setLeftBottomTextFieldPosition(dogTagTextField);
        }
        
        private function setCenterTextFieldXPosition(textField:TextField):void {
            var width:int = getWidth() * getSquareLength();
            textField.x = ( (1.0 * width / 2) - (textField.width / 2) );
        }
        
        private function setLeftBottomTextFieldPosition(textField:TextField):void {
            
            var format:TextFormat = new TextFormat();
            format.size=(getWidth() * getSquareLength() / 3);
            textField.setTextFormat(format);
            
            textField.width = getWidth() * getSquareLength();
            textField.height = getHeight() * getSquareLength();
            textField.alpha = 0.7;
            textField.selectable = false;
            
            textField.x = 0;
            
            var height:int = getHeight() * getSquareLength();
            textField.y = 0;
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            loadViewImage();
            move(x, y, true);
            initName();
            initDogTag();
        }
        
        private function initName():void {
            
            var textHeight:int = 18;
            nameTextField.y = (textHeight * -1);
            nameTextField.height = textHeight;
            setCenterTextFields();
            
            /*
            var format:TextFormat = new TextFormat();
            format.size=12;
            nameTextField.setTextFormat(format);
            */
            
            view.addChild(nameTextField);
        }
        
        private function initDogTag():void {
            var textHeight:int = 18;
            dogTagTextField.height = textHeight;
            view.addChild(dogTagTextField);
        }
        
        private function initTextField(textField:TextField):void {
            textField.background = true;
            textField.multiline = false;
            textField.selectable = false;
            textField.mouseEnabled = false;
            textField.autoSize = TextFieldAutoSize.CENTER;
        }
        
        private function setRotation(targetRotation:int):void {
            thisObj.rotation = targetRotation;
        }
        

        
    }
}
