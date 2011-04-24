//--*-coding:utf-8-*--

package {
    
    import mx.controls.Alert;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import mx.core.UIComponent;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.text.TextFieldAutoSize;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.geom.Point;
    import mx.controls.Text;
    import mx.controls.Label;
    import mx.managers.PopUpManager;
    import mx.containers.Box;
    import mx.effects.Glow;
    import flash.text.TextFormat;
    
    public class Card extends MovablePiece {
        
        private var thisObj:Card;
        
        static public function getNobodyOwner():String {
            return "nobody";
        }
        
        public static function getTypeStatic():String {
            return "Card";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        public static function getJsonData(imageName_:String,
                                           imageNameBack_:String,
                                           x:int,
                                           y:int):Object {
            
            var jsonData:Object = MovablePiece.getJsonData(getTypeStatic(), x, y);
            
            jsonData["imageName"] = imageName_;
            jsonData["imageNameBack"] = imageNameBack_;
            jsonData["isBack"] = true;
            jsonData["isText"] = true;
            jsonData["isOpen"] = false;
            jsonData["rotation"] = 0;
            jsonData["owner"] = "";
            jsonData["ownerName"] = "";
            jsonData["mountName"] = "";
            jsonData["name"] = "";
            jsonData["canDelete"] = false;
            
            return jsonData;
        }
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData["type"] = getType();
            jsonData["imageName"] = this.imageName;
            jsonData["imageNameBack"] = this.imageNameBack;
            jsonData["isBack"] = this.isBack;
            jsonData["isText"] = this.isText;
            jsonData["isOpen"] = this.isOpen;
            jsonData["rotation"] = this.rotation;
            jsonData["owner"] = this.owner;
            jsonData["ownerName"] = this.ownerName;
            jsonData["mountName"] = this.mountName;
            jsonData["name"] = "";
            jsonData["canDelete"] = this.canDelete;
            
            return jsonData;
        }
        
        private var isOpen:Boolean = false;
        private var rotation:Number = 0;
        private var owner:String = "";
        private var ownerName:String = "";
        private var isText:Boolean = true;
        private var imageName:String = "";
        private var imageNameBack:String = "";
        private var isBack:Boolean = true;
        private var mountName:String = "";
        private var canDelete:Boolean = false;
        
        private var isInitMovedd:Boolean = false;
        
        private var nameTextField:TextField = new TextField();
        private var cashMainText:Bitmap = null;
        private var mainTextArea:MovieClip = new MovieClip();
        private var cashSubText:Bitmap = null;
        private var subTextArea:MovieClip = new MovieClip();
        
        
        public function Card(params:Object) {
            thisObj = this;
            
            setParams(params);
            super(params);
            
            initName();
            view.setBackGroundColor(0xFFFFFF);
            view.setLineDiameter(4 * 2);
        }
        
        public function getMountName():String {
            return this.mountName;
        }
        
        public function setRate(rate:Number):void {
            view.scaleX = rate;
            view.scaleY = rate;
        }
        public function getView():UIComponent {
            return view;
        }
        
        protected function setParams(params:Object):void {
            this.isOpen = params.isOpen;
            setRotation( Number(params.rotation) );
            this.owner = params.owner;
            this.ownerName = params.ownerName;
            this.isText = params.isText;
            setImageName( params.imageName );
            setImageNameBack( params.imageNameBack );
            this.isBack = params.isBack;
            this.mountName = params.mountName;
            this.canDelete = params.canDelete;
            
            printTitle();
        }
        
        public function setImageName(s:String):void {
            this.imageName = s;
        }
        
        public function setImageNameBack(s:String):void {
            this.imageNameBack = s;
        }
        
        public function setCanDelete(b:Boolean):void {
            canDelete = b;
        }
        
        public function getOwner():String {
            return this.owner;
        }
        
        public function getOwnerName():String {
            return this.ownerName;
        }
        
        public function setOwnerName(name:String):void {
            this.ownerName = name;
            this.owner = getSelfOwnerId();
        }
        
        public function isPickupable():Boolean {
            return true;
        }
        
        private function setViewStates():void {
            if( this.view == null ) {
                return;
            }
            
            var roundColor:int = 0xBBBB00;
            if( this.isOpen ) {
                roundColor = 0xAFEEEE;
            }
            this.view.setRoundColor(roundColor);
            this.view.setLineColor(roundColor);
            
            setContextMenu();
        }
        
        override protected function dragged():void {
            isInitMovedd = true;
        }
        
        private function setContextMenu():void {
            if( openPrivateMenu == null ) {
                return;
            }
            
            openPrivateMenu.visible = false; //"カードを見る：非公開で自分だけ
            openPublicMenu.visible = false; //"カードを全員に公開する
            closeSecretMenu.visible = false;  //カードを伏せる：非公開に戻す
            changeOwnerMenu.visible = false; //"カードの管理者を自分に変える
            printCardTextMenu.visible = false; //カードテキストをチャットに引用
            removeCardMenu.visible = false; //"カード削除
            
            if( this.isPrintCardText() ) {
                if( ! isPrintBackSide() ) {
                    printCardTextMenu.visible = true;
                }
            }
            
            if( this.canDelete ) {
                removeCardMenu.visible = true;
            }
            
            if( ! isOwner() ) {
                changeOwnerMenu.visible = true; //"カードの管理者を自分に変える")
                return;
            }
            
            if( this.isOpen ) {
                closeSecretMenu.visible = true ;  //カードを伏せる：非公開に戻す")
                return;
            }
            
            if( this.isBack ) {
                openPrivateMenu.visible = true; //"カードを見る：非公開で自分だけ")
            }
            
            openPublicMenu.visible = true; //"カードを全員に公開する")
        }
        
        public function getTitleVisible():Boolean {
            return this.nameTextField.visible;
        }
        
        public function setTitleVisible(b:Boolean):void {
            this.nameTextField.visible = b;
        }
        
        protected function printTitle():void {
            var text:String = getTitleText();
            
            if( text == null ) {
                return;
            }
            
            this.nameTextField.text = text;
        }
        
        public function getTitleText():String {
            if( this.ownerName == null ) {
                return null;
            }
            
            if( this.owner == getNobodyOwner() ) {
                return "完全非公開";
            }
            
            if( this.isOpen ) {
                return "公開：" + this.ownerName;
            } else {
                return "非公開：" + this.ownerName;
            }
        }
        
        override public function getSquareLength():int {
            return 1;
        }
        
        override protected function getMapLayer():UIComponent {
            return getMap().getCardLayer();
        }
        
        private var zoomRate:Number = 4;
        private var fontSize:Number = 8;
        
        protected function getWidthSize():Number {
            return 2;
        }
        
        protected function getHeightSize():Number {
            return 3;
        }
        
        override public function getWidth():int {
            return getWidthSize();
        }
        
        override public function getHeight():int {
            return getHeightSize();
        }
        
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>Card.update() Begin");
            
            super.update(params);
            setParams(params);
            
            loadViewImage();
            
            Log.loggingTuning("=>Card.update() End");
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            loadViewImage();
            move(x, y, true);
        }
        
        public function isPrintBackSide():Boolean {
            return ( this.isBack || ( ! isOwner()) );
        }
        
        public function getLoadImageUrl():String {
            var targetImageName:String = this.imageName;
            if( isPrintBackSide() ) {
                targetImageName = this.imageNameBack;
            }
            
            return targetImageName;
        }
        
        public function loadViewImage():void {
            var targetImageName:String = getLoadImageUrl();
            
            if( this.isText ) {
                mainTextArea.visible = true;
                printMainText( targetImageName );
                targetImageName = "image/transparent.gif";
            } else {
                mainTextArea.visible = false;
            }
            
            setViewStates();
            
            //伏せたカードの上下がバレないように、伏せカードは強制的に上向きの表示に差し替え
            var viewRotation:Number = rotation;
            if( isPrintBackSide() ) {
                if( viewRotation >= 180 ) {
                    viewRotation -= 180;
                }
            }
            
            view.loadImageWidthHeightRotation(targetImageName, targetImageName,
                                              getWidthSize(), getHeightSize(),
                                              viewRotation);
            
            printTitle();
        }
        
        protected function isOwner():Boolean {
            //オープン状態のカードはすなわち操作できるカード。
            if( this.isOpen ) {
                return true;
            }
            
            //まだめくったことのないカードは誰でも操作可能
            if( this.owner == "" ) {
                return true;
            }
            
            //非公開のカードは所持者しか操作できない
            var thisUserId:String = getSelfOwnerId();
            Log.logging("thisUserId", thisUserId);
            Log.logging("this.owner", this.owner);
            
            return ( thisUserId == this.owner );
        }
        
        public function isForeground():Boolean {
            return isSetViewForevroungOnMouseClicked();
        }
        
        override protected function isSetViewForevroungOnMouseClicked():Boolean {
            return true;
        }
        
        public function isTrashable():Boolean {
            return true;
        }
        
        private function moveAndDumpToTrushMount(trushMount:CardTrushMount):void {
            view.x = trushMount.getX();
            view.y = trushMount.getY();
            
            sender.dumpTrushCard( getId(), trushMount.getMountName(), trushMount.getId() );
            
        }
        
        override public function snapViewPosition():Boolean {
            if( ! thisObj.isInitMovedd ) {
                return false;
            }
            
            var trushMount:CardTrushMount = getMap().getTrushMountIfHit(this);
            if( trushMount != null ) {
                moveAndDumpToTrushMount(trushMount);
                return false;
            }
            

            var cardZone:CardZone = getHitedCardZone();
            if( cardZone != null ) {
                var isForce:Boolean = true;
                move(cardZone.getCenterX(), cardZone.getCenterY(), isForce);
                changeOwnToAnyoneOnLocal(cardZone.getOwner(), cardZone.getOwnerName());
                sender.changeCharacter( thisObj.getJsonData() );
                return false;
            }
            
            return super.snapViewPosition();
        }
        

        private function getHitedCardZone():CardZone {
            
            if( ! isTrashable() ) {
                return null;
            }
            
            var cardZones:Array = getMap().getTargetTypes([CardZone.getTypeStatic()]);
            
            for(var i:int = 0 ; i < cardZones.length ; i++) {
                var cardZone:CardZone = cardZones[i];
                if( cardZone == null ) {
                    continue;
                }
                
                if( ! cardZone.hitTestObject(this) ) {
                    continue;
                }
                
                return cardZone;
            }
            
            return null;
        }
        

        
        override public function canSnapOnPositionX():Boolean {
            return true;
        }
        /*
        override public function canSnapOnPositionY():Boolean {
            return true;
        }
        */
        
        override protected function initEvent():void {
            Log.logging("Card.initEvent begin");
            
            view.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
                    if( ! thisObj.isPickupable() ) {
                        return;
                    }
                    
                    DodontoF_Main.getInstance().displayCardPreview(thisObj);
                });
            
            view.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
                    DodontoF_Main.getInstance().hideCardPreview();
                });
        }
        
        private function isUpSide():Boolean {
            return (this.rotation <= 90) || (this.rotation > 270);
        }
        
        public function getJsonDataForPreview():Object {
            var obj:Object = this.getJsonData();
            obj.rotation = (isUpSide() ? 0 : 180);
            
            return obj;
        }
        
        private var openPrivateMenu:ContextMenuItem;
        private var openPublicMenu:ContextMenuItem;
        private var closeSecretMenu:ContextMenuItem;
        private var changeOwnerMenu:ContextMenuItem;
        private var removeCardMenu:ContextMenuItem;
        private var printCardTextMenu:ContextMenuItem;
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            openPrivateMenu = addMenuItem(menu, "カードを自分だけが見る（非公開）", openPrivate, false);
            openPublicMenu = addMenuItem(menu, "カードを全員に見せる（公開）", openCard, true);
            closeSecretMenu = addMenuItem(menu, "カードを伏せる（非公開）", closeSecret, false);
            changeOwnerMenu = addMenuItem(menu, "カードを自分の管理へ", changeOwn, true);
            
            addMenuItem(menu, "右回転",    thisObj.getContextMenuItemFunctionRotateCharacter( 90), true);
            addMenuItem(menu, "180度回転", thisObj.getContextMenuItemFunctionRotateCharacter(180));
            addMenuItem(menu, "左回転",    thisObj.getContextMenuItemFunctionRotateCharacter(270));
            
            printCardTextMenu = addMenuItem(menu, "カードテキストをチャットに引用", getContextMenuItemFunctionPrintCardText, true);
            
            removeCardMenu = addMenuItem(menu, "カード削除", getContextMenuItemRemoveCharacter, true);
            
            view.contextMenu = menu;
        }
        
        public function hideContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            view.contextMenu = menu;
        }
        
        protected function isPrintCardText():Boolean {
            return this.isText;
        }
        
        private function getCardMessage(mainText:String, subText:String):String {
            if( subText == null ) {
                return ( mainText + "　：　" + (isUpSide() ? "正位置" : "逆位置") );
            }
            
            if( isUpSide() ) {
                return mainText + "\n" + subText;
            }
            
            return subText + "\n" + mainText;
        }
        
        protected function getContextMenuItemFunctionPrintCardText(event:ContextMenuEvent):void {
            var message:String = getLoadImageUrl();
            var mainText:String = getCardMainText(message);
            var subText:String = getCardSubText(message);
            
            var cardMessage:String = getCardMessage(mainText, subText);
            
            cardMessage = cardMessage.replace(/<br\/?>/ig, " ");
            cardMessage = cardMessage.replace(/<.+?>/g, '');
            cardMessage = cardMessage.replace(/&amp;/g, '&');
            cardMessage = cardMessage.replace(/&lt;/g, '<');
            cardMessage = cardMessage.replace(/&gt;/g, '>');
            
            DodontoF_Main.getInstance().getChatWindow().addTextToChatMessageInput(cardMessage);
        }
        
        public function setRotation(rotation:Number):void {
            rotation = ( rotation % 360 );
            this.rotation = rotation;
        }
        
        protected function getContextMenuItemFunctionRotateCharacter(rotationDiff:Number):Function {
            return function(event:ContextMenuEvent):void {
                var rotation:Number = thisObj.rotation;
                rotation += rotationDiff;
                setRotation(rotation);
                
                thisObj.loadViewImage();
                sender.changeCharacter( thisObj.getJsonData() );
            };
        }
        
        
        override public function isGotoGraveyard():Boolean {
            return false;
        }
        
        public function openPrivate(event:ContextMenuEvent = null):void {
            reverseCard(false);
        }
        
        private function closeSecret(event:ContextMenuEvent = null):void {
            reverseCard(true);
        }
        
        public function getBack():Boolean {
            return this.isBack;
        }
        
        private function openCard(event:ContextMenuEvent = null):void {
            if( ! isOwner() ) {
                Log.loggingError("カードの所持者ではないため公開できません。");
                return;
            }
            
            var thisUserId:String = getSelfOwnerId();
            
            this.isOpen = true;
            this.isBack = false;
            this.owner = thisUserId;
            this.ownerName = getSelfOwnerName();
            
            loadViewImage();
            sender.changeCharacter( getJsonData() );
        }
        
        public function getSelfOwnerId():String {
            return Card.getSelfOwnerId();
        }
        static public function getSelfOwnerId():String {
            return DodontoF_Main.getInstance().getUniqueId();
        }
        
        public function getSelfOwnerName():String {
            return Card.getSelfOwnerName();
        }
        static public function getSelfOwnerName():String {
            return DodontoF_Main.getInstance().getChatWindow().getChatCharacterName();
        }
        
        public function changeOwn(event:ContextMenuEvent = null):void {
            if( event != null ) {
                ChatWindow.getInstance().sendSystemMessage("が「" + this.ownerName + "」のカードを受け取りました。");
            }
            
            var thisUserId:String = getSelfOwnerId();
            
            this.owner = thisUserId;
            this.ownerName = getSelfOwnerName()
            
            loadViewImage();
            sender.changeCharacter( getJsonData() );
        }
        
        public function changeOwnToAnyoneOnLocal(ownerAnyone:String, ownerNameAneone:String):void {
            
            if( ownerAnyone != this.owner ) {
                ChatWindow.getInstance().sendSystemMessage("が「" + ownerNameAneone + "」へカードを渡しました。");
            }
            
            this.owner = ownerAnyone;
            this.ownerName = ownerNameAneone;
            
            loadViewImage();
        }
        
        private function reverseCard(isFaceBack:Boolean):void {
            reverseCardLocal(isFaceBack);
            
            loadViewImage();
            sender.changeCharacter( getJsonData() );
        }
        
        public function reverseCardLocal(isFaceBack:Boolean):void {
            Log.logging("Card.reverse begin");
            
            if( ! isOwner() ) {
                Log.loggingError("カードの所持者ではないため操作できません。");
                return;
            }
            
            var thisUserId:String = getSelfOwnerId();
            var thisUserName:String = ChatWindow.getInstance().getChatCharacterName();
            
            if( isFaceBack ) {
                Log.logging("カードを伏せた場合は、所有者も初期化(未所有）となる。");
                this.isOpen = false;
                thisUserId = "";
                thisUserName = "";
            }
            
            this.isBack = isFaceBack;
            this.owner = thisUserId;
            this.ownerName = thisUserName;
            
            if( ! isFaceBack ) {
                if( this.canDelete ) {
                    ChatWindow.getInstance().sendSystemMessage("がメッセージカードを開きました。");
                }
            }
        }
        
        private function setTextFieldXPosition():void {
            var width:int = getWidthSize() * Map.getSquareLength();
            nameTextField.x = ( (1.0 * width / 2) - (nameTextField.width / 2) );
        }
        
        private function initName():void {
            var textHeight:int = 20;
            
            nameTextField.background = true;
            nameTextField.multiline = false;
            nameTextField.selectable = false;
            nameTextField.mouseEnabled = false;
            nameTextField.y = (textHeight * -1);
            
            nameTextField.autoSize = TextFieldAutoSize.CENTER;
            nameTextField.height = textHeight;
            setTextFieldXPosition();
            
            view.addChild(nameTextField);
            view.addChildToBase(mainTextArea);
            view.addChildToBase(subTextArea); 
        }
        
        private function getTextField(message:String, width:Number, height:Number):TextField {
            if( message == null ) {
                message = "";
            }
            
            var mainTextField:TextField = new TextField();
            mainTextField.wordWrap = true;
            mainTextField.multiline = true;
            mainTextField.selectable = false;
            mainTextField.mouseEnabled = false;
            mainTextField.htmlText = message.replace(/,/g, "\n");
            
            mainTextField.width = width * zoomRate;
            mainTextField.height = height * zoomRate;
            
            return mainTextField;
        }
        
        private function getBitmapFromTextField(textArea:MovieClip, cashText:Bitmap, textField:TextField, backColor:uint):Bitmap {
            var a_mc:MovieClip = new MovieClip();

            a_mc.addChild(textField);
            
            a_mc.graphics.beginFill(backColor);
            a_mc.graphics.drawRect(0, 0, a_mc.width, a_mc.height);
            a_mc.graphics.endFill();
            
            var tmp_cashBitMapData:BitmapData = new BitmapData(a_mc.width, a_mc.height);
            tmp_cashBitMapData.draw(a_mc);
            
            if( cashText != null ) {
                try {
                    textArea.removeChild(cashText);
                } catch(e:Error) {
                }
            }
            
            cashText = new Bitmap(tmp_cashBitMapData, "auto", true);
            cashText.scaleX = (1.0 / zoomRate);
            cashText.scaleY = (1.0 / zoomRate);
            
            textArea.addChild(cashText);
            
            return cashText;
        }
        
        private function getBackColor(text:String):uint {
            if( text == null ) {
                text = '#FFFFFF';
            }
            
            var color:uint = parseInt( text.replace('#', '0x') );
            
            return color;
        }
        
        private function getCardMainText(message:String):String {
            var texts:Array = message.split(/\t/);
            return texts[0];
        }
        private function getCardSubText(message:String):String {
            var texts:Array = message.split(/\t/);
            return texts[1];
        }
        protected function getCardBackColor(message:String):uint {
            var texts:Array = message.split(/\t/);
            return getBackColor(texts[2]);
        }
        
        private function printMainText(message:String):void {
            var texts:Array = message.split(/\t/);
            
            var mainText:String = getCardMainText(message);
            var subText:String = getCardSubText(message);
            var backColor:uint = getCardBackColor(message);
            
            if( subText == null ) {
                subText = "";
            }
            
            var width:Number = getWidthSize() * Map.getSquareLength();
            var height:Number = getHeightSize() * Map.getSquareLength();
            
            var textFieldHeight:Number = height;
            if( subText != "" ) {
                textFieldHeight = height / 2;
            }
            
            var mainTextField:TextField = getTextField(mainText, width, textFieldHeight);
            cashMainText = getBitmapFromTextField(mainTextArea, cashMainText, mainTextField, backColor);
            
            if( subText == "" ) {
                subTextArea.visible = false;
                return;
            }
            
            subTextArea.visible = true;
            
            var subTextField:TextField = getTextField(subText, width, textFieldHeight);
            cashSubText = getBitmapFromTextField(subTextArea, cashSubText, subTextField, backColor);
            rotateSubTextArea(subTextArea, width, height);
        }
        
        private function rotateSubTextArea(textArea:MovieClip, width:Number, height:Number):void {
            textArea.rotation = 180;
            textArea.x = width;
            textArea.y = height;
        }
   }
}
