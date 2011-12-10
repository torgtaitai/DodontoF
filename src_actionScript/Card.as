//--*-coding:utf-8-*--

package {
    
	import flash.display.Stage;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import mx.containers.Box;
    import mx.controls.Alert;
    import mx.controls.Image;
    import mx.controls.Label;
    import mx.controls.Text;
    import mx.core.UIComponent;
    import mx.effects.Glow;
    import mx.managers.PopUpManager;
    
    
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
        
        override public function getTypeName():String {
            return "カード";
        }
        
        public static function getJsonData(imageName_:String,
                                           imageNameBack_:String,
                                           x:int,
                                           y:int):Object {
            
            var jsonData:Object = MovablePiece.getJsonData(getTypeStatic(), x, y);
            
            jsonData["imageName"] = imageName_;
            jsonData["imageNameBack"] = imageNameBack_;
            jsonData["isBack"] = true;
            jsonData["isUpDown"] = false;
            jsonData["isText"] = true;
            jsonData["isOpen"] = false;
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
            jsonData["isUpDown"] = this.isUpDown;
            jsonData["isText"] = this.isText;
            jsonData["isOpen"] = this.isOpen;
            jsonData["owner"] = this.owner;
            jsonData["ownerName"] = this.ownerName;
            jsonData["mountName"] = this.mountName;
            jsonData["name"] = "";
            jsonData["canDelete"] = this.canDelete;
            
            return jsonData;
        }
        
        private var isOpen:Boolean = false;
        private var owner:String = "";
        private var ownerName:String = "";
        private var isUpDown:Boolean = false;
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

        override protected function canRotate():Boolean {
            return true;
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
            this.owner = params.owner;
            this.ownerName = params.ownerName;
            this.isUpDown = params.isUpDown;
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
        
        private function getStringFromParams(params:Object, key:String):String {
            var name:String = params[key];
            
            if( name == null ) {
                return name;
            }
            
            return name;
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
        
        public function getRoundColor():int {
            var roundColor:int = 0xBBBB00;
            if( this.isOpen ) {
                roundColor = 0xAFEEEE;
            }
            return roundColor;
        }
        
        private function setViewStates():void {
            if( this.view == null ) {
                return;
            }
            
            var roundColor:int = getRoundColor();
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
        
        override public function getMapLayer():UIComponent {
            return getMap().getCardLayer();
        }
        
        private var zoomRate:Number = 4;
        
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
        
        override public function loadViewImage():void {
            var targetImageName:String = getLoadImageUrl();
            
            if( this.isText ) {
                mainTextArea.visible = true;
                printMainText( targetImageName );
                targetImageName = "image/transparent.gif";
            } else {
                mainTextArea.visible = false;
                subTextArea.visible = false;
                this.cardName = getCardNameWhenImageData(targetImageName);
                targetImageName = getImageUrlWhenImageData(targetImageName);
            }
            
            setViewStates();
            
            //伏せたカードの上下がバレないように、伏せカードは強制的に上向きの表示に差し替え
            var viewRotation:Number = getRotation() + getViewRotationDiff();
            
            view.loadImageWidthHeightRotation(targetImageName, targetImageName,
                                              getWidthSize(), getHeightSize(),
                                              viewRotation);
            
            super.loadViewImage();
            
            printTitle();
        }
        
        override public function getViewRotationDiff():Number {
            var rotationDiff:Number = 0;
            if( ! isPrintBackSide() ) {
                return rotationDiff;
            }
            
            if( ( getRotation() > 90 ) &&
                ( getRotation() <= 270 ) ){
                rotationDiff = 180;
            }
            
            return rotationDiff;
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
            
            var message:String = "";
            if( this.getCardName() == "" ) {
                message = "が「" + this.getMountNameForDisplay() + "」のカードを捨てました。";
            } else {
                message = "が「" + this.getCardName() + "」を捨てました。";
            }
            
            DodontoF_Main.getInstance().getChatWindow().sendSystemMessage( message );
            sender.dumpTrushCard( getId(), trushMount.getMountName(), trushMount.getId() );
            
        }
        
        public function getMountNameForDisplay():String {
            return InitCardWindow.getCardName( getMountName() );
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
                changeOwnerToAnyoneOnLocal(cardZone.getOwner(), cardZone.getOwnerName());
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
            
            view.doubleClickEnabled = canDoubleClick()
            view.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickEvent);
        }
        
        protected function canDoubleClick():Boolean {
            return true;
        }
        
        protected function doubleClickEvent(event:MouseEvent):void {
            Log.logging("MouseEvent.DOUBLE_CLICK");
            
            //カード自分の物なら表裏を入れ替えるだけで終了。
            if( isOwner() ) {
                var isBackPrint:Boolean = ( ! isPrintBackSide());
                thisObj.reverseCard( isBackPrint );
                return;
            }
            
            
            //カードが自分の物でなければここで自分の物に。
            if( ! isOwner() ) {
                var isPrintMessage:Boolean = true;
                changeOwnerLocal(isPrintMessage);
            }
            
            if( ! isPrintBackSide() ) {
                //カードが表向きなら画像更新して終了。
                loadViewImage();
                sender.changeCharacter( getJsonData() );
            } else {
                //裏向きなら表にして終了。
                thisObj.reverseCard( false );
            }
        }
        
        private function isUpSide():Boolean {
            return (getRotation() <= 90) || (getRotation() > 270);
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
            changeOwnerMenu = addMenuItem(menu, "カードを自分の管理へ", changeOwner, true);
            /*
            addMenuItem(menu, "右回転",    thisObj.getContextMenuItemFunctionRotateCharacter( 90), true);
            addMenuItem(menu, "180度回転", thisObj.getContextMenuItemFunctionRotateCharacter(180));
            addMenuItem(menu, "左回転",    thisObj.getContextMenuItemFunctionRotateCharacter(270));
            */
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
            if( subText == "" ) {
                if( this.isUpDown ) {
                    return ( mainText + "　：　" + (isUpSide() ? "正位置" : "逆位置") );
                } else {
                    return ( mainText );
                }
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
        
        /*
        protected function getContextMenuItemFunctionRotateCharacter(rotationDiff:Number):Function {
            return function(event:ContextMenuEvent):void {
                setDiffRotation(rotationDiff);
                
                thisObj.loadViewImage();
                sender.changeCharacter( thisObj.getJsonData() );
            };
        }
        */
        
        override public function isGotoGraveyard():Boolean {
            return true;
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
                view.toolTip = "カードの所持者ではないため公開できません。";
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
        
        public function changeOwner(event:ContextMenuEvent = null):void {
            var isPrintMessage:Boolean = (event != null);
            changeOwnerLocal( isPrintMessage );
            loadViewImage();
            sender.changeCharacter( getJsonData() );
        }
        
        private function changeOwnerLocal(isPrintMessage:Boolean):void {
            if( isPrintMessage ) {
                ChatWindow.getInstance().sendSystemMessage("が「" + this.ownerName + "」のカードを受け取りました。");
            }
            
            var thisUserId:String = getSelfOwnerId();
            
            this.owner = thisUserId;
            this.ownerName = getSelfOwnerName()
        }
        
        public function changeOwnerToAnyoneOnLocal(ownerAnyone:String, ownerNameAneone:String):void {
            
            if( ownerAnyone != this.owner ) {
                ChatWindow.getInstance().sendSystemMessage("が「" + ownerNameAneone + "」へカードを渡しました。");
            }
            
            this.owner = ownerAnyone;
            this.ownerName = ownerNameAneone;
            
            loadViewImage();
        }
        
        private function reverseCard(isBackPrint:Boolean):void {
            reverseCardLocal(isBackPrint);
            
            loadViewImage();
            sender.changeCharacter( getJsonData() );
        }
        
        public function reverseCardLocal(isBackPrint:Boolean):void {
            Log.logging("Card.reverse begin");
            
            if( ! isOwner() ) {
                view.toolTip = "カードの所持者ではないため操作できません。";
                return;
            }
            
            var thisUserId:String = getSelfOwnerId();
            var thisUserName:String = ChatWindow.getInstance().getChatCharacterName();
            
            if( isBackPrint ) {
                Log.logging("カードを伏せた場合は、所有者も初期化(未所有）となる。");
                this.isOpen = false;
                thisUserId = "";
                thisUserName = "";
            } else {
                this.isOpen = false;
            }
            
            this.isBack = isBackPrint;
            this.owner = thisUserId;
            this.ownerName = thisUserName;
            
            if( ! isBackPrint ) {
                if( this.canDelete ) {
                    ChatWindow.getInstance().sendSystemMessage("がメッセージカードを開きました。");
                }
            }
        }
        
        private function setTextFieldXPosition():void {
            var width:int = getOwnWidth();
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
            if( text == null || text == "" ) {
                text = '#FFFFFF';
            }
            
            var color:uint = parseInt( text.replace('#', '0x') );
            
            return color;
        }
        
        private function getTextFromMessage(message:String, index:int):String {
            var texts:Array = message.split(/\t/);
            var text:String = texts[index];
            if( text == null ) {
                return "";
            }
            return text;
        }
        private function getCardMainText(message:String):String {
            return getTextFromMessage(message, 0);
        }
        private function getCardSubText(message:String):String {
            return getTextFromMessage(message, 1);
        }
        protected function getCardBackColor(message:String):uint {
            var colorText:String = getTextFromMessage(message, 2);
            return getBackColor( colorText );
        }
        protected function getCardNameWhenText(message:String):String {
            return getTextFromMessage(message, 3);
        }
        
        protected function getImageUrlWhenImageData(message:String):String {
            return getTextFromMessage(message, 0);
        }
        
        protected function getCardNameWhenImageData(message:String):String {
            return getTextFromMessage(message, 1);
        }
        
        
        override public function getOwnWidth():int {
            return getWidthSize() * Map.getSquareLength();
        }
        
        override public function getOwnHeight():int {
            return getHeightSize() * Map.getSquareLength();
        }
        
        
        private var cardName:String = null;
        
        public function getCardName():String {
            if( this.cardName == null ) {
                return "";
            }
            
            return this.cardName;
        }
        
        
        private function printMainText(message:String):void {
            var texts:Array = message.split(/\t/);
            
            var mainText:String = getCardMainText(message);
            var subText:String = getCardSubText(message);
            var backColor:uint = getCardBackColor(message);
            this.cardName = getCardNameWhenText(message);
            
            if( subText == null ) {
                subText = "";
            }
            
            var width:Number = getOwnWidth();
            var height:Number = getOwnHeight();
            
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
