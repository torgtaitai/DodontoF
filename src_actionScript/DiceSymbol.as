//--*-coding:utf-8-*--

package {
    
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import mx.controls.Menu;
    import mx.core.UIComponent;
    import mx.events.MenuEvent;
    import mx.managers.PopUpManager;
    
    public class DiceSymbol extends MovablePiece {
        
        private var number:int = 1;
        private var maxNumber:int = 6;
        private var limitMaxNumber:int = 10;
        private var ownerName:String;
        private var owner:String = null;
        private var thisObj:DiceSymbol;
        private var openMenu:ContextMenuItem = null;
        private var hideMenu:ContextMenuItem = null;
        private var allMenus:Array = new Array();
        
        public static function getTypeStatic():String {
            return "diceSymbol";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return "ダイスシンボル";
        }
        
        
        public static function getJsonData(maxNumber:int,
                                           number:int,
                                           owner:String,
                                           ownerName:String,
                                           createPositionX:int,
                                           createPositionY:int):Object {
            var draggable:Boolean = true;
            var jsonData:Object = MovablePiece.getJsonData(getTypeStatic(), createPositionX, createPositionY, draggable);
            
            jsonData.number = number;
            jsonData.maxNumber = maxNumber;
            jsonData.owner = owner;
            jsonData.ownerName = ownerName;
            
            return jsonData;
        }
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.number = getNumber();
            jsonData.maxNumber = getMaxNumber();
            jsonData.owner = owner;
            jsonData.ownerName = ownerName;
            
            return jsonData;
        }
        
        public function DiceSymbol(params:Object) {
            this.thisObj = this;
            
            this.number = parseInt(params.number);
            this.maxNumber = parseInt(params.maxNumber);
            this.owner = params.owner;
            this.ownerName = params.ownerName;
            
            //自分の環境に仮作成する場合のために、作成直後はドラッグ不可に。
            //応答が正常ならどちらにしろupdateで更新されるはずなのでこの実装で問題は無い。
            var draggable:Boolean = false;
            
            super(params);
        }
        
        public function getNumber():int {
            return this.number;
        }
        
        public function getMaxNumber():int {
            return this.maxNumber;
        }
        
        public function setNumber(number_:int):void {
            this.number = number_;
        }
        
        public function setMaxNumber(maxNumber_:int):void {
            this.maxNumber = maxNumber_;
        }
        
        override public function isGotoGraveyard():Boolean {
            return true;
        }
        
        override public function getName():String {
            return getToolTipMessage();
        }
        
        override protected function initContextMenu():void {
            allMenus = new Array();
            
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            openMenu = addMenuItem(menu, "ダイス目を公開する", this.getContextMenuItemOpenDice, true);
            
            allMenus.push( addMenuItem(menu, "ダイスを振る", this.rollDice) );
            
            var loopCount:int = this.maxNumber;
            if( loopCount > limitMaxNumber ) {
                loopCount = limitMaxNumber;
            }
            
            var separatorBefore:Boolean = true;
            if( Config.getInstance().isHaveZeroDice(maxNumber) ) {
                pushSetDiceNumberMenuItem(menu, 0, separatorBefore);
                separatorBefore = false;
            }
            
            for(var i:int = 0 ; i < loopCount ; i++) {
                var n:int = i + 1;
                pushSetDiceNumberMenuItem(menu, n, separatorBefore);
                separatorBefore = false;
            }
            
            if( this.maxNumber > limitMaxNumber ) {
                hideMenu = addMenuItem(menu, "ダイス目を10以上に", 
                                       this.getContextMenuItemSetDiceOver10Function(),
                                       true);
            }
            
            hideMenu = addMenuItem(menu, "ダイスを隠す", this.getContextMenuItemHideDice, true);
            allMenus.push( hideMenu );
            
            allMenus.push( addMenuItem(menu, "ダイスの削除", this.getContextMenuItemRemoveCharacter, true) );
            
            view.contextMenu = menu;
        }
        
        private function pushSetDiceNumberMenuItem(menu:ContextMenu, n:int, separatorBefore:Boolean):void {
            allMenus.push( addMenuItem(menu,
                                       "ダイス目を" + n + "に",
                                       getMenuItemFunctionChangeNumber(n),
                                       separatorBefore) );
        }
        
        private function getContextMenuItemOpenDice(event:ContextMenuEvent):void {
            openDice(true);
        }
        
        private function getContextMenuItemSetDiceOver10Function():Function {
            var from:int = limitMaxNumber + 1;
            var to:int = this.maxNumber;
            
            return function(event:ContextMenuEvent):void {
                var parent:UIComponent = event.mouseTarget as UIComponent;
                var menuData:Array = [];
                for(var i:int = from ; i <= to ; i++) {
                    var index:int = i;
                    
                    var childrenInfo:Object = {
                        label: "" + index,
                        index: index
                    };
                    menuData.push(childrenInfo);
                }
                
                var menu:Menu = Menu.createMenu(parent, menuData);
                
                menu.addEventListener("itemClick", getMenuItemChangeNumberSubMenu);
                var point:Point = parent.localToGlobal(new Point(0, 0));
                menu.show(point.x + parent.width, point.y);
            }
        }
            
        private function getContextMenuItemHideDice(event:ContextMenuEvent):void {
            openDice(false);
        }
        
        private function openDice(isOpen:Boolean):void {
            
            var targetOwner:String = null;
            if( ! isOpen ) {
                targetOwner = DodontoF_Main.getInstance().getStrictlyUniqueId();
            } else {
                sendOpenMessage();
            }
            this.owner = targetOwner;
            
            if( ChatWindow.getInstance() != null ) {
                this.ownerName = ChatWindow.getInstance().getChatCharacterName();
            }
            
            updateRefresh();
            sender.changeCharacter( getJsonData() );
        }
        
        private function sendOpenMessage():void {
            var message:String = "がダイスをオープンしました。出目は" + number + "(" + maxNumber + "面ダイス)です。";
            ChatWindow.getInstance().sendSystemMessage(message);
        }
        
        override protected function getContextMenuItemRemoveCharacter(event:ContextMenuEvent):void {
            DodontoF_Main.getInstance().getDiceBox().clearDice();
            super.getContextMenuItemRemoveCharacter(event);
        }
        
        private function rollDice(event:Event):void {
            if( ! isOpenMode() ) {
                return;
            }
            
            var params:Object = null;
            DodontoF_Main.getInstance().getDiceBox().createDice("d" + maxNumber, params, getId(), changeNumber);
        }

        
        override protected function initEventAll():void {
            super.initEventAll();
            
            view.doubleClickEnabled = true;
            view.addEventListener(MouseEvent.DOUBLE_CLICK, this.rollDice);
        }
        
        public function changeNumber(targetNumber:int):void {
            this.number = targetNumber;
            sender.changeCharacter( getJsonData() );
            drawDice();
        }
        
        public function getMenuItemFunctionChangeNumber(targetNumber:int):Function {
            return function(event:ContextMenuEvent):void {
                thisObj.changeNumber(targetNumber);
            };
        }
        
        public function getMenuItemChangeNumberSubMenu(event:MenuEvent):void {
            var index:int = event.item.index;
            thisObj.changeNumber(index);
        }
        
        /*
        private function getMenuItemRoll(event:ContextMenuEvent):void {
            roll();
        }
        
        private function roll():void {
        }
        */
        
        override public function getMapLayer():UIComponent {
            return getMap().getCharacterLayer();
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            move(x, y, true);
            
            drawDice();
        }
        
        override protected function update(params:Object):void {
            super.update(params);
            
            this.number = params.number;
            this.owner = params.owner;
            this.ownerName = params.ownerName;
            
            updateRefresh();
        }
        
        public function updateRefresh():void {
            initDraw(getX(), getY());
            setHideMode();
        }
        
        private function setAllMenuEnable():void {
            var isVisible:Boolean = isDiceVisible();
            
            for(var i:int = 0 ; i < allMenus.length ; i++) {
                var menu:ContextMenuItem = allMenus[i];
                menu.visible = isVisible;
            }
        }
        
        private function isOpenMode():Boolean {
            if( this.owner == null ) {
                return true;
            }
            
            if( this.owner == "" ) {
                return true;
            }
            
            return false;
        }
        
        override protected function initEnd():void {
            setHideMode();
        }
        
        private function setHideMode():void {
            if( isOpenMode() ) {
                view.setBackGroundColor();
                view.setLineColor();
            } else {
                view.setBackGroundColor(0x000000);
                view.setLineColor(0x996600);
            }
            
            setAllMenuEnable();
            openMenu.visible = ( ! isOpenMode() );
            hideMenu.visible = ( isOpenMode() );
            
            view.initBaseColor();
            printToolTip();
        }
        
        public function refresh():void {
            initDraw(getX(), getY());
        }
        
        override public function canExtendOnPositionX():Boolean {
            return true;
        }
        
        private function isDiceVisible():Boolean {
            if( isOpenMode() ) {
                return true;
            }
            
            if( this.owner == DodontoF_Main.getInstance().getUniqueId() ) {
                return true;
            }
            
            if( this.owner == DodontoF_Main.getInstance().getStrictlyUniqueId() ) {
                return true;
            }
            
            return false;
        }
        
        public function getDiceImageUrl():String {
            if( ! isDiceVisible() ) {
                return Config.getInstance().getTransparentImage();
            }
            
            return DiceInfo.getDiceImageUrlGlobal(this.maxNumber, this.number);
        }
        
        private function drawDice():void {
            var imageUrl:String = getDiceImageUrl();
            var size:int = 1;
            view.loadImage(imageUrl, size);
            
            printToolTip();
        }
        
        private function printToolTip():void {
            view.toolTip = getToolTipMessage();
        }
        
        private function getToolTipMessage():String {
            var toolTipMessage:String = "";
            
            toolTipMessage += "[" + this.ownerName + "]のダイス\n";
            if( ! isOpenMode() ) {
                toolTipMessage += "非公開：";
            }
            if( isDiceVisible() ) {
                toolTipMessage += "" + this.number + " / D" + maxNumber;
            }
            
            return toolTipMessage;
        }
        
    }
}