//--*-coding:utf-8-*--

package {
    
	import flash.display.Stage;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
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
    
    /** 
     * カードクラス
     */
    public class Card extends MovablePiece {
        
        private var thisObj:Card;
        
        /** 
         * カードは誰かに所持されている場合は所持者のIDを持っていますが、
         * 誰も所持していないカードの場合はIDはこの文字になります。
         */
        static public function getNobodyOwner():String {
            return "nobody";
        }
        
        /** 
         * コマの定義名
         * Pieceの子クラスは常に定義
         */
        public static function getTypeStatic():String {
            return "Card";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        /** 
         * クラス定義名の日本語版。
         * ゴミ箱から拾い上げるときに使用する。
         */
        override public function getTypeName():String {
            return Language.s.card;
        }
        
        
        /** 
         * コマの作製用の初期データを生成
         * @imageName_ カード表の画像URL(もしくはHTML文字列）
         * @imageNameBack_ カード裏の画像URL(もしくはHTML文字列）
         * @x カードのX座標
         * @y カードのY座標
         */
        public static function getJsonData(imageName_:String,
                                           imageNameBack_:String,
                                           x:int,
                                           y:int,
                                           mountName:String = ""):Object {
            
            var params:Object = MovablePiece.getJsonData(getTypeStatic(), x, y);
            
            params["imageName"] = imageName_;
            params["imageNameBack"] = imageNameBack_;
            params["isBack"] = true;
            params["isUpDown"] = false;
            params["isText"] = true;
            params["isOpen"] = false;
            params["owner"] = "";
            params["ownerName"] = "";
            params["mountName"] = mountName;
            params["name"] = "";
            params["canDelete"] = false;
            params["canRewrite"] = false;
            
            return params;
        }
        
        /** 
         * コマの作製用の初期データをここで生成
         */
        override public function getJsonData():Object {
            var params:Object = super.getJsonData();
            
            params["type"] = getType();
            params["imageName"] = this.imageName;
            params["imageNameBack"] = this.imageNameBack;
            params["isBack"] = this.isBack;
            params["isUpDown"] = this.isUpDown;
            params["isText"] = this.isText;
            params["isOpen"] = this.isOpen;
            params["owner"] = this.owner;
            params["ownerName"] = this.ownerName;
            params["mountName"] = this.mountName;
            params["name"] = "";
            params["canDelete"] = this.canDelete;
            params["canRewrite"] = this.canRewrite;
            
            return params;
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
        private var canRewrite:Boolean = false;
        
        private var cardName:String = null;
        
        private var isInitMoved:Boolean = false;
        
        private var nameTextField:TextField = new TextField();
        private var cashMainText:Bitmap = null;
        private var mainTextArea:MovieClip = new MovieClip();
        private var cashSubText:Bitmap = null;
        private var subTextArea:MovieClip = new MovieClip();
        
        private var zoomRate:Number = 4;
        
        static public function get cardLogStrictlyUniqueId():String {
            return "ChatLog";
        }
        
        
        /** 
         * コマのデータを下にカードを作製します。
         */
        public function Card(params:Object) {
            thisObj = this;
            
            setParams(params);
            super(params);
            
            initName();
            view.setBackGroundColor(0xFFFFFF);
            view.setLineDiameter(4 * 2);
            
            setCardName();
        }
        
        /** 
         * 回転可能なコマかを判別。
         */
        override protected function canRotate():Boolean {
            return true;
        }
        
        /** 
         * カードにはカードの属する「山」があり、
         * ここではその山の名前を返す。
         */
        public function getMountName():String {
            return this.mountName;
        }
        
        /** 
         * カードを表示するためのビューを返す。
         */
        public function getView():UIComponent {
            return view;
        }
        
        /** 
         * 初期化・更新するための各種パラメータをここで更新
         */
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
            this.canRewrite = params.canRewrite;
            
            printTitle();
            setWidthHeight();
        }
        
        /** 
         * カード表の画像URL(もしくはHTML文字列）を設定
         */
        public function setImageName(s:String):void {
            this.imageName = s;
        }
        
        public function getImageName():String {
            return this.imageName;
        }
        
        /** 
         * カード裏の画像URL(もしくはHTML文字列）を設定
         */
        public function setImageNameBack(s:String):void {
            this.imageNameBack = s;
        }
        
        public function getImageNameBack():String {
            return this.imageNameBack;
        }
        
        /** 
         * カードの所持者表示の更新
         */
        protected function printTitle():void {
            var text:String = getTitleText();
            
            if( text == null ) {
                return;
            }
            
            this.nameTextField.text = text;
            
            setCardCommand();
        }
        
        /** 
         * カードの所持者表示文字列の取得
         */
        public function getTitleText():String {
            if( this.ownerName == null ) {
                return null;
            }
            
            if( this.owner == getNobodyOwner() ) {
                return Language.s.closedCard;
            }
            
            if( this.isOpen ) {
                return Language.s.publicCard + this.ownerName;
            } else {
                return Language.s.privateCard + this.ownerName;
            }
        }
        
        /** 
         * カードの公開状態の取得。
         */
        public function isOpenMode():Boolean {
            return this.isOpen;
        }
        
        
        /** 
         * ウィッチクエストではカードにコマンドを定義する事ができる。
         * その設定コマンドの表示をここで行う。
         */
        private function setCardCommand():void {
            if( commandMenu == null ) {
                return;
            }
            
            var cardCommand:String = getCardCommand( this.imageName );
            commandMenu.visible = ( cardCommand != "" );
            commandMenu.caption = getCardCommandName( this.imageName );
        }
        
        
        /** 
         * カードは誰かに所持されている場合は所持者のIDを持っている。
         * そのIDを返す。
         */
        public function getOwner():String {
            return this.owner;
        }
        
        /** 
         * カード所持者の名前を返す。
         */
        public function getOwnerName():String {
            return this.ownerName;
        }
        
        /** 
         * カード所持者の名前を設定。
         */
        public function setOwnerName(name:String):void {
            this.ownerName = name;
            this.owner = getSelfOwnerId();
        }
        
        /** 
         * カードピックアップ画面に拡大表示させるかどうかの指定。
         * 子クラスによっては対象外を指定します
         * （カードの山もカードクラスだけど拡大表示対象外）
         */
        public function isPickupable():Boolean {
            return true;
        }
        
        /** 
         * カードの縁取りの色を取得。
         * カードを全員に公開しているかどうかで色が変わります。
         */
        public function getRoundColor():int {
            var roundColor:int = 0xBBBB00;
            if( this.isOpen ) {
                roundColor = 0xAFEEEE;
            }
            return roundColor;
        }
        
        
        /** 
         * 最初にマップに配置された瞬間は、マス目に沿う位置への自動配置（Snapと呼んでいます）は行われない。
         * 一度でも動かされたら、以降はSnapが許可されます。
         */
        override protected function dragged():void {
            isInitMoved = true;
        }
        
        /** 
         * カードのタイトル（所有者）の表示状態
         */
        public function isTitleVisible():Boolean {
            return this.nameTextField.visible;
        }
        
        /** 
         * カードのタイトル（所有者）の表示状態を設定
         */
        public function setTitleVisible(b:Boolean):void {
            this.nameTextField.visible = b;
        }
        
          /** 
           * コマの座標を画面上の何ドットとして表現するかの指定。
           * 普通は Map.getSquareLength() と同一の 50 。
           * 例えばキャラクターが x=1, y=2 の座標に居るとすると、
           * 画面の表示上はマップ上で 50, 100 の座標に表示されます。
           * 
           * しかしカードは歴史的な経緯で扱いが特殊で、座標＝画面上の表示座標となっています。
           * このためここの値は 1 です。
           * 
           * 歴史的経緯って何かといえば、
           * 昔はキャラクターのマップとカードの置き場所は別々に管理されたんです。
           * 今はマップ上にカード置くようになったので、この仕様は混乱の元なんですが
           * 下手に変更すると昔のデータと互換性が無くなるのでこのままとします。
           */
        override public function getSquareLength():int {
            return 1;
        }
        
        
        /** 
         * マップ上の何処のレイヤーに表示されるかを指定します。
         */
        override public function getMapLayer():UIComponent {
            return getMap().getCardLayer();
        }
        
        
        /** 
         * コマの幅がマス目の何マス分かを示します。
         */
        protected function getWidthSize():Number {
            return cardWidth;
        }
        
        /** 
         * コマの高がマス目の何マス分かを示します。
         */
        protected function getHeightSize():Number {
            return cardHeight;
        }
        
        /** 
         * コマの縦横マス数を算出します。
         * 山札の名前が「trump_swf\tAxB」と末尾に「(タブ)AxB」が付く場合、横A，縦Bになります。
         * それ以外の場合は横２，縦３に固定です。
         * また ruby/card.rb に(\t)NxM まで加えた一致する表記がある場合、表示データはそちらに差し替わります。
         * 
         */
        private function setWidthHeight():void {
            var result:Object = getCardSizeInfoCardType( getMountName() );
            
            if( result == null ) {
                cardWidth = 2;
                cardHeight = 3;
            } else {
                cardWidth = result.width;
                cardHeight = result.height
            }
        }
        
        static public function getCardSizeInfoCardType(cardType:String):Object {
            var result:Object = /\t((\d+)x(\d+))/.exec(cardType);
            
            if( result == null ) {
                return null;
            }
            
            var obj:Object = {
                text: result[1],
                width: parseInt(result[2]),
                height: parseInt(result[3])
            }
            
            return obj;
        }
        
        private var cardWidth:Number = 0;
        private var cardHeight:Number = 0;
        
        
        /** 
         * コマの幅がマス目の何マス分かを示します。
         */
        override public function getWidth():int {
            return getWidthSize();
        }
        
        /** 
         * コマの高がマス目の何マス分かを示します。
         */
        override public function getHeight():int {
            return getHeightSize();
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>Card.update() Begin");
            
            super.update(params);
            setParams(params);
            
            updateRefresh();
            
            Log.loggingTuning("=>Card.update() End");
        }

        override public function updateRefresh():void {
            loadViewImage();
        }
        
        
        private function isCardChangeToOpened(isOpenBefore:Boolean):Boolean {
            if( isOpenBefore ) {
                return false;
            }
            
            return this.isOpen;
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            loadViewImage();
            move(x, y, true);
        }
        
        public function isPrintBackSide():Boolean {
            return ( this.isBack || ( ! isOwner()) );
        }
        
        override public function loadViewImage():void {
            setCardName();
            
            var targetImageName:String = getLoadImageUrl();
            
            if( this.isText ) {
                mainTextArea.visible = true;
                printMainText( targetImageName );
            } else {
                mainTextArea.visible = false;
                subTextArea.visible = false;
            }
            
            targetImageName = getImageUrl(targetImageName);
            
            setViewStates();
            
            //伏せたカードの上下がバレないように、伏せカードは強制的に上向きの表示に差し替え
            var viewRotation:Number = getRotation() + getViewRotationDiff();
            
            view.loadImageWidthHeightRotation(targetImageName,
                                              getWidthSize(), getHeightSize(),
                                              viewRotation);
            
            super.loadViewImage();
            
            printTitle();
        }
        
        private function setCardName():void {
            var message:String = getLoadImageUrl();
            this.cardName = getCardNameFromMessage(message);
            this.view.toolTip = getCardToolTips(message);
        }
        
        public function getLoadImageUrl():String {
            var targetImageName:String = this.imageName;
            if( isPrintBackSide() ) {
                targetImageName = this.imageNameBack;
            }
            
            return targetImageName;
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
        
        
        private function setContextMenu():void {
            if( openPrivateMenu == null ) {
                return;
            }
            
            openPrivateMenu.visible = false; //カードを見る：非公開で自分だけ
            openPublicMenu.visible = false; //カードを全員に公開する
            closeSecretMenu.visible = false;  //カードを伏せる：非公開に戻す
            changeOwnerMenu.visible = false; //カードの管理者を自分に変える
            printCardTextMenu.visible = false; //カードテキストをチャットに引用
            removeCardMenu.visible = false; //カード削除
            rewriteCardMenu.visible = false; //カード書き換え
            copyCardMenu.visible = false; //カードコピー
            dumpToTrushMountCardMenu.visible = false; //カード捨て
            
            if( this.isPrintCardText() ) {
                if( ! isPrintBackSide() ) {
                    printCardTextMenu.visible = true;
                }
            }
            
            if( isOwner() ) {
                setContextMenuForOwner();
            } else {
                changeOwnerMenu.visible = true; //カードの管理者を自分に変える
            }
        }
        
        private function setContextMenuForOwner():void {
            
            if( isTrashable() ) {
                dumpToTrushMountCardMenu.visible = ( ! this.canDelete );
            }
            
            removeCardMenu.visible = this.canDelete;
            rewriteCardMenu.visible = this.canRewrite;
            copyCardMenu.visible = isMessageCard();
            
            
            if( this.isOpen ) {
                closeSecretMenu.visible = true ;  //カードを伏せる：非公開に戻す
                return;
            }
            
            if( this.isBack ) {
                openPrivateMenu.visible = true; //カードを見る：非公開で自分だけ
            } else {
                closeSecretMenu.visible = true ;  //カードを伏せる：非公開に戻す
            }
            
            openPublicMenu.visible = true; //カードを全員に公開する
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
        
        
        protected function getContextMenuItemDumptToTrushMountCard(event:ContextMenuEvent):void {
            var trushMount:CardTrushMount = getMap().getTrushMount(this);
            if( trushMount == null ) {
                return;
            }
            
            moveAndDumpToTrushMount(trushMount);
        }
        
        private function moveAndDumpToTrushMount(trushMount:CardTrushMount):void {
            view.x = trushMount.getX();
            view.y = trushMount.getY();
            
            if( this.getCardName() == "" ) {
                printCardLog( Language.s.discardMessage );
            } else {
                printCardLog( Language.s.discardMessageWithCardName, [getCardName()] );
            }
            
            sender.dumpTrushCard( getId(), trushMount.getMountName(), trushMount.getId() );
        }
        
        public function printCardLog(message:String, args:Array = null):void {
            if( args == null ) {
                args = [];
            }
            Utils.sendSystemMessage(message, args, cardLogStrictlyUniqueId);
        }
        
        
        public function getMountNameForDisplay():String {
            return InitCardWindow.getCardName( getMountName() );
        }
        
        
        override public function snapViewPosition():Boolean {
            if( ! thisObj.isInitMoved ) {
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
            
            
            return snapViewPositionCard();
            //return super.snapViewPosition();
        }

        private function snapViewPositionCard():Boolean {
            var length:int = Map.getSquareLength();
            
            var point:Point = getMap().getSnapViewPoint(view.x, view.y, length);
            view.x = point.x * length;
            view.y = point.y * length;
            
            return move(view.x, view.y, true);
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
        

        
        override public function canExtendOnPositionX():Boolean {
            return true;
        }
        
        
        override protected function initEvent():void {
            Log.logging("Card.initEvent begin");
            
            initEventMouseOverOutCardVisible();
            view.doubleClickEnabled = canDoubleClick()
            view.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickEvent);
        }
        
        protected function initEventMouseOverOutCardVisible():void {
            view.addEventListener(MouseEvent.MOUSE_OVER, mouseOverEvent);
            view.addEventListener(MouseEvent.MOUSE_OUT, mouseOutEvent);
        }
        
        protected function mouseOverEvent(event:MouseEvent):void {
            if( ! thisObj.isPickupable() ) {
                return;
            }
            
            DodontoF_Main.getInstance().displayCardPickUp(thisObj);
        }
        
        protected function mouseOutEvent(event:MouseEvent):void {
            DodontoF_Main.getInstance().hideCardPickUp();
        }
        
        
        override protected function canDoubleClick():Boolean {
            return true;
        }
        
        override protected function doubleClickEvent(event:MouseEvent):void {
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
        
        private var commandMenu:ContextMenuItem;
        private var openPrivateMenu:ContextMenuItem;
        private var openPublicMenu:ContextMenuItem;
        private var closeSecretMenu:ContextMenuItem;
        private var changeOwnerMenu:ContextMenuItem;
        private var removeCardMenu:ContextMenuItem;
        private var rewriteCardMenu:ContextMenuItem;
        private var copyCardMenu:ContextMenuItem;
        private var printCardTextMenu:ContextMenuItem;
        private var dumpToTrushMountCardMenu:ContextMenuItem;
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            commandMenu = addMenuItem(menu, "", sendChatMessage, false);
            
            openPrivateMenu = addMenuItem(menu, Language.s.openCardForMe, openPrivate, false);
            openPublicMenu = addMenuItem(menu, Language.s.openCardEveryone, openCard, true);
            closeSecretMenu = addMenuItem(menu, Language.s.closeCard, closeSecret, true);
            changeOwnerMenu = addMenuItem(menu, Language.s.changeCardOwnerToMe, changeOwner, true);
            printCardTextMenu = addMenuItem(menu, Language.s.writeCardTextToChat, getContextMenuItemFunctionPrintCardText, true);
            rewriteCardMenu = addMenuItem(menu, Language.s.changeCard, getContextMenuItemRewriteCard, true);
            copyCardMenu = addMenuItem(menu, Language.s.copyCard, getContextMenuItemCopyCard, true);
            removeCardMenu = addMenuItem(menu, Language.s.deleteCard, getContextMenuItemRemoveCharacter, true);
            dumpToTrushMountCardMenu = addMenuItem(menu, Language.s.dumpCard, getContextMenuItemDumptToTrushMountCard, true);
            
            view.contextMenu = menu;
        }
        
        public function sendChatMessage(event:ContextMenuEvent = null):void {
            var cardCommand:String = getCardCommand( this.imageName );
            if( cardCommand == "" ) {
                return;
            }
            
            var chatWindow:ChatWindow = DodontoF_Main.getInstance().getChatWindow();
            
            var data:ChatSendData = new ChatSendData(chatWindow.getSelectedChatChannleIndex(), cardCommand);
            var gameType:String = getCardCommandGameType( this.imageName );
            data.setGameType(gameType);
            
            chatWindow.sendChatMessageByChatSendData(data);
        }
        
        public function hideContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            view.contextMenu = menu;
        }
        
        protected function isPrintCardText():Boolean {
            return this.isText;
        }
        
        protected function getContextMenuItemFunctionPrintCardText(event:ContextMenuEvent):void {
            var cardMessage:String = getCardMessage();
            DodontoF_Main.getInstance().getChatWindow().addTextToChatMessageInput(cardMessage);
        }
        
        private function getCardMessage():String {
            var message:String = getLoadImageUrl();
            
            var text:String = getCardToolTips(message);
            if( text != "" ) {
                return getCardNameFromMessage(message) + "\n" + text;
            }
            
            var mainText:String = getCardMainText(message);
            var subText:String = getCardSubText(message);
            
            var cardMessage:String = getCardMessageByMainAndSub(mainText, subText);
            
            cardMessage = cardMessage.replace(/<br\/?>/ig, " ");
            cardMessage = cardMessage.replace(/<.+?>/g, '');
            cardMessage = cardMessage.replace(/&amp;/g, '&');
            cardMessage = cardMessage.replace(/&lt;/g, '<');
            cardMessage = cardMessage.replace(/&gt;/g, '>');
            
            cardMessage = cardMessage.replace(/\n/ig, "／");
            
            return cardMessage;
        }
        
        private function getCardMessageByMainAndSub(mainText:String, subText:String):String {
            if( subText == "" ) {
                if( this.isUpDown ) {
                    return ( mainText + "　：　" + (isUpSide() ? Language.s.upSideCard : Language.s.downSideCard) );
                } else {
                    return ( mainText );
                }
            }
            
            if( isUpSide() ) {
                return mainText + "\n" + subText;
            }
            
            return subText + "\n" + mainText;
        }
        
        
        
        protected function getContextMenuItemRewriteCard(event:ContextMenuEvent):void {
            var window:ChangeMessageCardWindow = DodontoF.popup(ChangeMessageCardWindow, true) as ChangeMessageCardWindow;
            var point:Point = new Point(getX(), getY());
            window.setCreatePoint(point);
            window.setCard(this);
        }
        
        
        protected function getContextMenuItemCopyCard(event:ContextMenuEvent):void {
            var json:Object = getJsonData();
            DodontoF_Main.getInstance().getGuiInputSender().getSender().addCard(json);
        }
        
        
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
                view.toolTip = Language.s.yourAreNotCardOwner;
                return;
            }
            
            var thisUserId:String = getSelfOwnerId();
            
            this.isOpen = true;
            this.isBack = false;
            this.owner = thisUserId;
            this.ownerName = getSelfOwnerName();
            
            loadViewImage();
            sender.changeCharacter( getJsonData() );
            
            if( isMessageCard() ) {
                printCardLog(Language.s.openCardMessage, [getCardMessage()]);
            } else {
                printCardLog(Language.s.openCardMessage, [getCardName()]);
            }
        }
        
        private function isMessageCard():Boolean {
            return (mountName == "messageCard");
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
                printCardLog(Language.s.changeCardOwnerMessage, [this.ownerName]);
            }
            
            var thisUserId:String = getSelfOwnerId();
            
            this.owner = thisUserId;
            this.ownerName = getSelfOwnerName()
        }
        
        public function changeOwnerToAnyoneOnLocal(ownerAnyone:String, ownerNameAneone:String):void {
            
            if( ownerAnyone != this.owner ) {
                printCardLog(Language.s.changeCardOwnerToAnyoneMessage, [ownerNameAneone]);
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
        
        public function reverseCardLocal(isBack_:Boolean):void {
            Log.logging("Card.reverse begin");
            
            if( ! isOwner() ) {
                view.toolTip = Language.s.cardOwnerIsNotYouMessage;
                return;
            }
            
            this.isBack = isBack_;
            
            var thisUserId:String = getSelfOwnerId();
            var thisUserName:String = ChatWindow.getInstance().getChatCharacterName();
            
            if( this.isBack ) {
                Log.logging("カードを伏せた場合は、所有者も初期化(未所有）となる。");
                thisUserId = "";
                thisUserName = "";
            }
            
            this.isOpen = false;
            this.owner = thisUserId;
            this.ownerName = thisUserName;
            
            if( ! this.isBack ) {
                if( isMessageCard() ) {
                    printCardLog( Language.s.openMessageCardMessage );
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
        
        static private function getTextFromMessage(message:String, index:int):String {
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
        
        protected function getCardNameFromMessage(message:String):String {
            if( this.isText ) {
                return getTextFromMessage(message, 3);
            }
            return getCardNameWhenImageData(message);
        }
        
        protected function getCardToolTips(message:String):String {
            if( this.isText ) {
                return getCardToolTipsByIndexs(message, 4, 5);
            }
            
            return getCardToolTipsWhenImageData(message);
        }
        
        
        protected function getCardCommandName(message:String):String {
            return getCardCommandParam(message, 0);
        }
        
        protected function getCardCommand(message:String):String {
            return getCardCommandParam(message, 1);
        }
        
        protected function getCardCommandGameType(message:String):String {
            return getCardCommandParam(message, 2);
        }
        
        protected function getCardCommandParam(message:String, index:int):String {
            var base:String = "";
            
            if( this.isText ) {
                base = getTextFromMessage(message, 6);
            } else {
                base = getCardCommandWhenImageData(message);
            }
            
            if( base == "" ) {
                return "";
            }
            
            var params:Array = base.split("|");
            var result:String = params[index];
            if( result == null ) {
                result = "";
            }
            
            return result;
        }
        
        protected function getCardToolTipsByIndexs(message:String, upIndex:int, downIndex:int):String {
            var text:String = getCardToolTipsByIndexsDirectory(message, upIndex, downIndex);
            return text.replace(/\\n/g, "\n");
        }
        
        protected function getCardToolTipsByIndexsDirectory(message:String, upIndex:int, downIndex:int):String {
            var upText:String = getTextFromMessage(message, upIndex);
            if( isUpSide() ){
                return upText;
            }
            
            var downText:String = getTextFromMessage(message, downIndex);
            
            if( downText == "" ) {
                return upText;
            }
            
            return downText;
        }
        
        protected function getImageUrl(message:String):String {
            if( this.isText ) {
                return "image/transparent.gif";
            }
            
            return getImageUrlWhenImageData(message);
        }
        
        protected function getImageUrlWhenImageData(message:String):String {
            return getTextFromMessage(message, 0);
        }
        
        static public function getCardNameWhenImageData(message:String):String {
            return getTextFromMessage(message, 1);
        }
        
        protected function getCardToolTipsWhenImageData(message:String):String {
            return getCardToolTipsByIndexs(message, 2, 3);
        }
        
        protected function getCardCommandWhenImageData(message:String):String {
            return getTextFromMessage(message, 4);
        }
        
        override public function getOwnWidth():int {
            return getWidthSize() * Map.getSquareLength();
        }
        
        override public function getOwnHeight():int {
            return getHeightSize() * Map.getSquareLength();
        }
        
        
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
