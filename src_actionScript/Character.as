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
    import mx.controls.Image;
    
    
    public class Character extends InitiativedMovablePiece {
        
        protected var imageUrl:String = "";
        protected var mirrored:Boolean = false;
        protected var size:int = 1;
        private var isHide:Boolean = false;
        private var dogTag:String = "";
        private var url:String = "";
        
        private var dogTagTextField:TextField = new TextField();
        private var nameTextField:TextField = new TextField();
        private var thisObj:Character;
        private var openUrlMenu:ContextMenuItem;
        
        public function isHit(comp:UIComponent):Boolean {
            return view.hitTestObject(comp);
        }
        

        override protected function droped():void {
            //var isMove:Boolean = true;
        }
        
        public static function getTypeStatic():String {
            return "characterData";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return "キャラクター";
        }
        
        
        public static function getJsonData(name:String,
                                           imageUrl:String,
                                           mirrored:Boolean,
                                           size:int,
                                           isHide:Boolean,
                                           initiative:Number,
                                           info:String,
                                           rotation:Number,
                                           characterPositionX:int,
                                           characterPositionY:int,
                                           dogTag:String,
                                           counters:Object,
                                           statusAlias:Object,
                                           url:String):Object {
            
            var draggable:Boolean = true;
            var jsonData:Object = 
                InitiativedMovablePiece.getJsonData(getTypeStatic(),
                                                    name, initiative, info, counters, statusAlias,
                                                    characterPositionX, characterPositionY,
                                                    draggable, rotation);
            
            jsonData.imageName = imageUrl;
            jsonData.mirrored = mirrored;
            jsonData.size = size;
            jsonData.isHide = isHide;
            jsonData.dogTag = dogTag;
            jsonData.url = url;
            
            return jsonData;
        }
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.imageName = getImageUrl();
            jsonData.mirrored = isMirrored();
            jsonData.size = getSize();
            jsonData.isHide = isHideMode();
            jsonData.dogTag = this.dogTag;
            jsonData.url = this.url;
            
            return jsonData;
        }
        
        public function setImageUrl(url_:String):void {
            this.imageUrl = url_;
        }
        
        public function setMirrored(b:Boolean):void {
            this.mirrored = b;
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
            this.mirrored = params.mirrored;
            this.size = params.size;
            this.isHide = params.isHide;
            setDogTag( params.dogTag );
            setUrl( params.url );
            
            thisObj = this;
            
            setNameTag();
        }
        
        override protected function canRotate():Boolean {
            return true;
        }
        
        override public function getOwnWidth():int {
            return getWidth() * getSquareLength();
        }
        
        override public function getOwnHeight():int {
            return getHeight() * getSquareLength();
        }
        
        public function getView():ImageSprite {
            return view;
        }
        
        public function getImageUrl():String {
            return imageUrl;
        }
        
        public function isMirrored():Boolean {
            return mirrored;
        }
        
        public function getSize():int {
            return size;
        }
        
        override public function getWidth():int {
            return size;
        }
        
        override public function canExtendOnPositionX():Boolean {
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
            addMenuItem(menu, "キャラクターの削除", thisObj.getContextMenuItemRemoveCharacter, true);
            openUrlMenu = addMenuItem(menu, "データ参照先URLを開く", thisObj.getContextMenuItemOpenUrl, true);
            setUrlMenuVisible();
            
            view.setContexMenu(menu);
        }
        
        protected function getContextMenuItemOpenUrl(event:ContextMenuEvent):void {
          if( (url == null) || (url == "") ) {
              return;
          }
          
          DodontoF.openUrl( url );
        }
        
        override public function popUpChangeWindow():void {
            try {
                var characterWindow:CharacterWindow = DodontoF.popup(ChangeCharacterWindow, true) as CharacterWindow;
                characterWindow.setCharacter(this);
                
                DodontoF_Main.getInstance().setCharacterWindow(characterWindow);
            } catch(e:Error) {
                Log.loggingExceptionDebug("Character.popUpChangeWindow()", e);
            }
        }
        
        override public function hasStatus():Boolean {
            return true;
        }
        
        override public function getMapLayer():UIComponent {
            if( this.isHide ) {
                return getMap().getHideCharacterLayer();
            }
            
            return getMap().getCharacterLayer();
        }
        
        
        override protected function mouseDownEvent(event:MouseEvent):void {
            //キャラクター待合室を開いてるなら待合室へのドラッグ処理に差し替え
            if( CharacterWaitingRoomWindow.isOpened() ) {
                CharacterWaitingRoomWindow.getInstance().dragEvent(event, thisObj);
                return;
            }
            
            //Ctrlキーを押しながらのクリックで一括削除用の選択<->選択解除へ。
            //一度でもCtrlキーを離してキャラクターをクリックしたら解除へ。
            if( event.ctrlKey ) {
                clickCharacterForBatchDelete();
                return;
            }
            unSelectAllCharacters();
            
            super.mouseDownEvent(event);
        }
        
        static private var charactersForBatchDelete:Array = new Array();
        
        public function clickCharacterForBatchDelete():void {
            if( isInclude(charactersForBatchDelete, this) ) {
                unSelectCharacterForBatchDelete();
            } else {
                selectCharacterForBatchDelete();
            }
        }
        
        private function isInclude(array:Array, target:Object):Boolean {
            for(var i:int = 0 ; i < array.length ; i++) {
                if( array[i] == target ) {
                    return true;
                }
            }
            return false;
        }
        
        private function selectCharacterForBatchDelete():void {
            charactersForBatchDelete.push(this);
            var color:int = 0xFF4500;
            changeSelectedColor(color);
        }
        
        public function changeSelectedColor(color:int = -1):void {
            view.setRoundColor(color);
            //view.setBackGroundColor(color);
            view.setLineColor(color);
            loadViewImage();
        }
        
        private function unSelectCharacterForBatchDelete():void {
            deleteFromArray(charactersForBatchDelete, this);
            this.changeSelectedColor();
        }
        
        public function unSelectAllCharacters():void {
            while( charactersForBatchDelete.length > 0 ) {
                var character:Character = charactersForBatchDelete.pop();
                character.changeSelectedColor();
            }
        }
        
        private function deleteFromArray(array:Array, target:Object):void {
            var index:int = -1;
            
            for(var i:int = 0 ; i < array.length ; i++) {
                if( array[i] == target ) {
                    index = i;
                }
            }
            
            if( index != -1 ) {
                array.splice(index, 1);
            }
        }
        
        override public function sendDelete():void {
            if( charactersForBatchDelete.length == 0 ) {
                super.sendDelete();
            } else {
                sendDeleteBatch();
            }
        }
        
        private function sendDeleteBatch():void {
            Log.logging("sendDeleteBatch begin");
            
            sender.removeCharacters(charactersForBatchDelete);
            
            while( charactersForBatchDelete.length > 0 ) {
                var character:Character = charactersForBatchDelete.pop();
                character.deleteFromMap();
            }
            
            Log.logging("sendDeleteBatch end");
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>Character update Begin");
            
            Log.logging("super params changed.");
            super.update(params);
            
            Log.logging("character local params changed.");
            this.imageUrl = params.imageName;
            this.mirrored = params.mirrored;
            this.size = params.size;
            setHide( params.isHide );
            setDogTag( params.dogTag );
            setUrl( params.url );
            
            updateRefresh();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged Characteris changed End");
        }
        
        public function updateRefresh():void {
            loadViewImage();
            updateStatusMarker();
            setNameTag();
            setCenterTextFields();
        }
        
        private var statusMarkerIndexs:Array = [];
        private var statusMarkerWidth:int = 0;
        
        private function updateStatusMarker():void {
            if( view == null ) {
                return;
            }
            
            var newStatusMarkerIndexs:Array = getNewMarkerImageIndexs();
            var newStatusMarkerWidth:int = (getOwnWidth() / 5) + 1;
            
            if( newStatusMarkerWidth == statusMarkerWidth ) {
                if( Utils.isSameArray(newStatusMarkerIndexs, statusMarkerIndexs) ) {
                    return;
                }
            }
            Log.logging("newMarkerIndexs has diff refreshing...");
            
            refreshMarkerImage(newStatusMarkerIndexs, newStatusMarkerWidth);
            statusMarkerIndexs = newStatusMarkerIndexs;
            statusMarkerWidth = newStatusMarkerWidth;
        }
        
        
        private function getNewMarkerImageIndexs():Array {
            var newMarkerIndexs:Array = [];
            
            var infos:Array = getStatusInfos();
            for(var i:int = 0 ; i < infos.length ; i++) {
                if( i >= StatusMarkerInfo.getInstance().length() ) {
                    break;
                }
                
                var info:Object = infos[i];
                
                var counterName:String = info.counterName;
                var count:int = getCounter(counterName);
                if( count == 0 ) {
                    continue;
                }
                
                newMarkerIndexs.push(i);
            }
            
            return newMarkerIndexs;
        }
        
        private var statusMarkerBase:UIComponent = null;
        
        private function refreshMarkerImage(newMarkerIndexs:Array, width:int):void {
            if( statusMarkerBase != null ) {
                view.removeChildInner( statusMarkerBase );
            }
            
            statusMarkerBase = new UIComponent();
            
            for(var i:int = 0 ; i < newMarkerIndexs.length ; i++) {
                var newMarkerIndex:int = newMarkerIndexs[i];
                var marker:Image = new Image();
                marker.source = StatusMarkerInfo.getInstance().getMarker(newMarkerIndex);
                marker.width = width;
                marker.height = width;
                
                var index:int = i;
                marker.x = (index % 5) * marker.width - 2;
                marker.y = (this.getHeight() * Map.getSquareLength())
                    - ((Math.floor(index / 5) + 1) * marker.height) + 2;
                
                statusMarkerBase.addChild(marker);
            }
            
            view.addChildInner( statusMarkerBase );
        }
        
        private function setDogTag(dogTag_:String):void {
            this.dogTag = (dogTag_ == null ? "" : dogTag_);
            
            dogTagTextField.text = this.dogTag;
            dogTagTextField.visible = ( this.dogTag != "" );
        }
        
        public function setUrl(url:String):void {
            Log.logging("setUrl url", url);
            
            if( url == null ) {
                url = "";
            }
            
            this.url = url;
            setUrlMenuVisible();
            
            Log.logging("this.url", this.url);
        }
        
        private function setUrlMenuVisible():void {
            if( openUrlMenu == null ){
                return;
            }
            
            openUrlMenu.visible = (this.url != "");
        }
        
        override public function getUrl():String {
            return this.url;
        }
        
        private function setNameTag():void {
            nameTextField.text = getName();
        }
        
        override public function loadViewImage():void {
            view.setMirrored( this.mirrored );
            view.loadImageWidthHeightRotation(this.imageUrl,
                                              this.size, this.size,
                                              getRotation());
            
            super.loadViewImage();
        }
        
        private function setCenterTextFields():void {
            var width:int = getWidth() * getSquareLength();
            setCenterTextFieldXPosition(nameTextField, width);
            
            setLeftBottomTextFieldPosition(dogTagTextField);
        }
        
        static private function setCenterTextFieldXPosition(textField:TextField, width:Number):void {
            textField.x = ( (1.0 * width / 2) - (textField.width / 2) );
            textField.alpha = 0.7;
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
        
        static public function initNameTextField(textField:TextField, width:Number):void {
            var textHeight:int = 18;
            textField.y = (textHeight * -1);
            textField.height = textHeight;
            setCenterTextFieldXPosition(textField, width);
        }
        
        private function initName():void {
            var width:int = getWidth() * getSquareLength();
            initNameTextField(nameTextField, width);
            
            view.addChild(nameTextField);
        }
        
        private function initDogTag():void {
            var textHeight:int = 18;
            dogTagTextField.height = textHeight;
            view.addChild(dogTagTextField);
        }
        
        public static function initTextField(textField:TextField):void {
            textField.background = true;
            textField.multiline = false;
            textField.selectable = false;
            textField.mouseEnabled = false;
            textField.autoSize = TextFieldAutoSize.CENTER;
        }
        
    }
}
