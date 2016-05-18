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
    
    
    final public class Character extends InitiativedMovablePiece {
        
        protected var imageUrl:String = "";
        protected var images:Array = new Array();
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
            return Language.s.character;
        }
        
        
        public static function getJsonData(name:String,
                                           imageUrl:String,
                                           images:Array,
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
            jsonData.images = images;
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
            jsonData.images = getImages();
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
        
        public function setImages(images_:Array):void {
            if( images_ == null ) {
                images_ = new Array();
            }
            this.images = images_;
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
            setImages( params.images );
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
        
        public function getImages():Array {
            if( images == null ) {
                images = new Array();
            }
            if( images.length == 0 ) {
                images = [getImageUrl()];
            }
            
            return images;
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
            
            addMenuItem(menu, Language.s.changeCharacter, thisObj.getItemPopUpChangeWindow);
            addMenuItem(menu, Language.s.deleteCharacter, thisObj.getContextMenuItemRemoveCharacter, true);
            addMenuItem(menu, Language.s.cloneCharacter, thisObj.cloneCharacter, true);
            openUrlMenu = addMenuItem(menu, Language.s.openCharacterDataUrl, thisObj.getContextMenuItemOpenUrl, true);
            setUrlMenuVisible();
            
            view.setContextMenu(menu);
        }
        
        protected function cloneCharacter(event:ContextMenuEvent):void {
            Log.logging("cloneCharacter begin");
            cloneCharacterAction();
        }
        
        private function cloneCharacterAction(point:Point = null):void {
            var index:int = getNewDogTagIndex();
            cloneCharacterByIndex(index, point);
        }
        
        private function cloneCharacterByIndex(index:int, point:Point, retryCount:int = 0):Boolean {
            Log.logging("cloneCharacterByIndex index", index);
            Log.logging("retryCount", retryCount);
            if( retryCount > 5 ) {
                return false;
            }
            
            var baseName:String = getBaseName();
            var jsonData:Object = getJsonDataEmptyId();
            jsonData.name = baseName + "_" + index;
            jsonData.dogTag = "" + index;
            
            if( point != null ) {
                jsonData.x = point.x;
                jsonData.y = point.y;
            }
            
            var retryAction:Function = function():Boolean{ return cloneCharacterByIndex(index + 1, point, retryCount + 1); };
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.getSender().addCharacter(jsonData, null, retryAction);
            Log.logging("addCharacter");
            
            return true;
        }
        
        private function getNewDogTagIndex():int {
            var baseName:String = getBaseName();
            var newIndex:int = 1;
            
            var characters:Array = getMap().getCharacters();
            for each (var character:Character in characters) {
                    if( character.getBaseName() != baseName ) {
                        continue;
                    }
                    
                    Log.logging("character.getBaseName()", character.getBaseName());
                    Log.logging("character.getDogTag()", character.getDogTag());
                    var index:int = parseInt( character.getDogTag() );
                    newIndex = Math.max(newIndex, index);
                }
            
            newIndex++;
            Log.logging("newIndex", newIndex);
            
            return newIndex;
        }
        
        public function getBaseName():String {
            var result:Object = /(.+)_(\d+)/.exec( getName() );
            if( result == null ) {
                return getName();
            }
            
            return result[1];
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
        
        override protected function canDoubleClick():Boolean {
            return true;
        }
        
        override protected function doubleClickEvent(event:MouseEvent):void {
            var list:Array = getImages();
            var index:int = list.indexOf(this.imageUrl);
            if(index == -1) {
                return;
            }
            
            var newIndex:int = index + 1;
            if( newIndex > (list.length - 1) ) {
                newIndex = 0;
            }
            
            this.imageUrl = list[newIndex];
            
            sender.changeCharacter( this.getJsonData() );
            loadViewImage();
        }
        
        
        override protected function mouseDownEvent(event:MouseEvent):void {
            //キャラクター待合室を開いてるなら待合室へのドラッグ処理に差し替え
            if( CharacterWaitingRoomWindow.isOpened() ) {
                CharacterWaitingRoomWindow.getInstance().dragEvent(event, thisObj);
                return;
            }
            
            //Ctrlキーを押しながらのクリックで一括削除用の選択<->選択解除へ。
            //一度でもCtrlキーを離してキャラクターをクリックしたら解除へ。
            //あるいはマップをクリックしても選択解除されます。
            if( event.ctrlKey ) {
                clickCharacter(event);
                return;
            }
            
            unselectAllCharacters();
            
            super.mouseDownEvent(event);
        }
        
        
        static public var selectedCharacters:Array = new Array();
        
        static public function getSelectedCharacters():Array {
            return selectedCharacters;
        }
        
        
        public function clickCharacter(event:MouseEvent):void {
            if( isInclude(selectedCharacters, this) ) {
                unselectCharacter();
            } else {
                selectCharacter();
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
        
        private function selectCharacter():void {
            pushSelectedCharacters(this);
            var color:int = 0xFF4500;
            changeSelectedColor(color);
        }
        
        
        static private function pushSelectedCharacters(character:Character):void {
            selectedCharacters.push(character);
            ChatWindow.getInstance().updateSendToCharacters();
        }
        
        static private function popSelectedCharacters():Character {
            var character:Character = selectedCharacters.pop();
            ChatWindow.getInstance().updateSendToCharacters();
            return character;
        }
        
        
        public function changeSelectedColor(color:int = -1):void {
            view.setRoundColor(color);
            view.setLineColor(color);
            loadViewImage();
        }
        
        private function unselectCharacter():void {
            deleteFromArray(selectedCharacters, this);
            this.changeSelectedColor();
        }
        
        static public function unselectAllCharacters():void {
            while( selectedCharacters.length > 0 ) {
                var character:Character = popSelectedCharacters();
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
            if( selectedCharacters.length == 0 ) {
                super.sendDelete();
            } else {
                sendDeleteBatch();
            }
        }
        
        private function sendDeleteBatch():void {
            Log.logging("sendDeleteBatch begin");
            
            sender.removeCharacters(selectedCharacters);
            
            while( selectedCharacters.length > 0 ) {
                var character:Character = popSelectedCharacters();
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
            this.images = params.images
            this.mirrored = params.mirrored;
            this.size = params.size;
            setHide( params.isHide );
            setDogTag( params.dogTag );
            setUrl( params.url );
            
            updateRefresh();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged Characteris changed End");
        }
        
        override public function updateRefresh():void {
            loadViewImage();
            updateStatusMarker();
            setNameTag();
            setCenterTextFields();
        }
        
        private var statusMarkerIndexs:Array = [];
        private var statusMarkerWidth:int = 0;
        
        private function updateStatusMarker():void {
            Log.logging("updateStatusMarker Begin");
            
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
            
            Log.logging("updateStatusMarker End");
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
        
        private function getDogTag():String {
            return this.dogTag;
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
        
        
        override public function setCounters(obj:Object):void {
            super.setCounters(obj);
            drowCounterBars();
        }
        
        override public function setCounter(key:String, value:int):int {
            var result:int = super.setCounter(key, value);
            drowCounterBars();
            return result;
        }
        
        private function drowCounterBars():void {
            if( view == null ) {
                return;
            }
            
            var layer:UIComponent = view;
            layer.graphics.clear();
            
            var barInfos:Array = getStatusBarInfos();
            
            for(var i:int = 0 ; i < barInfos.length ; i++) {
                var info:Object = barInfos[i];
                
                var max:int = InitiativeWindow.getCounterLimitMax(this, info, 0);
                if( max <= 0 ) {
                    continue;
                }
                
                var count:int = getCounter( info["counterName"] );
                if( count <= 0 ) {
                    continue;
                }
                
                var percentage:Number = (1.0 * count / max);
                var index:int = i;
                drowCounterBar(layer, index, barInfos.length, percentage);
            }
        }
            
        private function getStatusBarInfos():Array {
            var barInfos:Array = new Array();
            
            var counterNames:Array = DodontoF_Main.getInstance().getRoundTimer().getCounterNames();
            for(var i:int = 0 ; i < counterNames.length ; i++) {
                var counterName:String = counterNames[i];
                var info:Object = InitiativeWindow.getCounterNameInfo(counterName);
                if( info["max"] == null ) {
                    continue;
                }
                info["counterName"] = counterName;
                barInfos.push(info);
            }
            
            return barInfos;
        }
            
        private function drowCounterBar(layer:UIComponent, index:int, maxCount:int, percentage:Number):void {
            var color:int = parseInt( InitiativeWindow.getCheckBoxDefaultColor(index) );
            
            var positionIndex:int = maxCount - index - 1;
            
            var barHeight:int = 5;
            var baseY:int = -25 - ((barHeight + 1) * positionIndex);
            var drawWidth:Number = getOwnWidth() * percentage;
            
            layer.graphics.lineStyle(1, color);
            layer.graphics.beginFill(color);
            layer.graphics.drawRect(0, baseY, drawWidth, barHeight);
            layer.graphics.endFill();
        }
        
    }
}
