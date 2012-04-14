//--*-coding:utf-8-*--
package {
    
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import mx.controls.Image;
    import mx.core.UIComponent;
    import mx.controls.Alert;
    
    
    public class Dice {
        
        public static function getNumberFromValue(value:Number, max:int):int {
            return Math.floor(value * max) + 1;
        }
        
        
        private static var mersenneTwister:MersenneTwister = createMersenneTwister();
            
        private static function createMersenneTwister():MersenneTwister {
            var now:Date = new Date();
            var mt:MersenneTwister = new MersenneTwister( now.valueOf() );
            
            return mt;
        }
        
        public static function getRandomNumber(max:int):int {
            //return getNumberFromValue(Math.random(), max);
            
            var value:Number = mersenneTwister.nextNumber();
            
            return getNumberFromValue(value, max);
        }
        
        private var limitCount:int = 50;
        private var diceSize:int = 100;
        private var changeDirectionIntervalFrameCount:int = 5;
        private var diceTypes:Array = new Array();
        private var dice:Array = new Array();
        private var parent:UIComponent;
        private var parentWindow:UIComponent;
        private var movieClip:MovieClip = new MovieClip();
        
        private var thisObj:Dice;
        
        public function Dice(diceRollPlace:UIComponent, parentWindow_:UIComponent) {
            thisObj = this;
            
            parent = diceRollPlace;
            parentWindow = parentWindow_;
            
            initParent();
        }
        
        private function initParent():void {
            resetParent();
        }

        private function getWindowWidth():int {
            return parent.width;
        }
        
        private function getWindowMaxWidth():int {
            return parent.width + parentWindow.width - diceSize;
        }
        
        private function getWindowHeight():int {
            return parent.height;
        }
        
        public function addDice(diceType:String, imgId:String, resultFunction:Function):void {
            if( diceTypes.length >= this.limitCount ){
                Log.loggingError("dice total count is " + diceTypes.length + "(limit : " + this.limitCount + ")");
                return;
            }
            
            if( isAdded(imgId) ) {
                return;
            }
            
            if( isAllDiceEnded() ) {
                clearDice();
            }
            
            var diceTypeInfo:Object = 
                {"diceType":diceType,
                 "imgId": imgId,
                 "resultFunction" : resultFunction};
            this.diceTypes.push(diceTypeInfo);
            
            var diceTypesBackup:Array = this.diceTypes;
            clearDice();
            this.diceTypes = diceTypesBackup;
            reSetDice();
        }
        
        private function isAdded(imgId:String):Boolean {
            if( imgId == null ) {
                return false;
            }
            
            for(var i:int =0 ; i < this.diceTypes.length ; i++) {
                if( imgId == this.diceTypes[i].imgId ) {
                    return true;
                }
            }
            
            return false;
        }
        
        public function clearDice():void {
            Log.loggingTuning("clearDice start");
            
            for(var i:int = 0 ; i < this.dice.length ; i++) {
                parent.removeChild(this.dice[i].view);
            }
            
            this.stopAnimation();
            
            this.dice = [];
            this.diceTypes = [];
            
            resetParent();
        }
        
        private function resetParent():void {
            parent.scaleX = 1;
            parent.scaleY = 1;
            
            parent.width= parentWindow.x + parentWindow.width;// * 2;
            parent.height= parentWindow.y;// * 2;
            
            parent.x = 0;
            parent.y = parentWindow.y * -1 - diceSize + parentWindow.height;
        }
        
        
        private var diceCountScale:Number = 0.97;
        
        private function setScale():void {
            resetParent();
            return;
            
            for(var i:int =0 ; i < this.diceTypes.length ; i++) {
                var rate:Number = diceCountScale;
                parent.scaleX *= rate;
                parent.scaleY *= rate;
                parent.x += 7;
                parent.y += 3;
            }
        }
        
        private function reSetDice():void {
            setScale();
            
            for(var i:int =0 ; i < this.diceTypes.length ; i++) {
                var diceInfo:Object = {};
                
                diceInfo.number = i;
                diceInfo.diceType = this.diceTypes[i].diceType;
                diceInfo.resultFunction = this.diceTypes[i].resultFunction;
                Log.logging("diceInfo.diceType", diceInfo.diceType);
                setDiceView( diceInfo );
                Log.logging("setDiceView end.");
                
                this.setStartPosition(diceInfo, i);
                this.dice.push(diceInfo);
            }
            
            this.startAnimation();
        }
        
        private function startAnimation():void {
            Log.loggingTuning("startAnimation");
            movieClip.addEventListener(Event.ENTER_FRAME, this.updateDice);
        }
        
        private function stopAnimation():void {
            try {
                movieClip.removeEventListener(Event.ENTER_FRAME, this.updateDice);
                Log.loggingTuning("stopAnimation");
            } catch(e:Error) {
                Log.loggingException("Dice.stopAnimation()", e);
            }
        }
        
        private var updateCounter:int = 0;
        private var updatePassCount:int = getUpdatePassCount();
        
        private function getUpdatePassCount():int {
            var frameRate:int =  DodontoF_Main.getInstance().stage.frameRate;
            var updatePassCount:int = frameRate / 30;
            return updatePassCount;
        }
        
        private function updateDice(event:Event):void {
            updateCounter++;
            if( updateCounter < updatePassCount ) {
                return;
            }
            updateCounter = 0;
            
            for(var i:int = 0;  i < this.dice.length ; i++){
                var diceInfo:Object = this.dice[i];
                this.updateDiceOne(diceInfo);
            }
            
            if( isAllDiceEnded() ) {
                this.stopAnimation();
                this.moveSamePositionDice();
                this.sendResult();
            }
        }
        
        private function sendResult():void {
            var message:String = getDiceResultsText();
            ChatWindow.getInstance().sendDiceRollResultMessageForChatWindowUser(message);
        }
        
        private function getDiceTypesInfo():Object {
            var diceTypesInfo:Object = {};
            
            for(var i:int = 0;  i < this.dice.length ; i++){
                var diceInfo:Object = this.dice[i];
                var diceNo:int = diceInfo.resultValue;
                var diceMax:String = DiceInfo.getDiceTypeInfo(diceInfo.diceType, "maxString") as String;
                
                if( ! diceTypesInfo[diceMax] ) {
                    diceTypesInfo[diceMax] = [];
                }
                diceTypesInfo[diceMax].push(diceNo);
            }
            
            return diceTypesInfo;
        }
        
        private function getDiceTotal():int {
            var total:int = 0;
            
            for(var i:int = 0;  i < this.dice.length ; i++){
                var diceInfo:Object = this.dice[i];
                var diceNo:int = diceInfo.resultValue;
                total += diceNo;
            }
            
            return total;
        }
        
        private function getDiceResultsText():String {
            var diceTypesInfo:Object = getDiceTypesInfo();
            
            var diceMaxs:Array = [];
            for (var key:String in diceTypesInfo) {
                diceMaxs.push(key);
            }
            
            var diceTypesString:String = "";
            for(var i:int = 0;  i < diceMaxs.length ; i++){
                var diceMax:String = diceMaxs[i];
                
                if( diceTypesString.length > 0 ) {
                    diceTypesString += " ";
                }
                
                var diceNoList:Array = diceTypesInfo[diceMax];
                
                diceTypesString += diceNoList.length + "D" + diceMax;
                diceTypesString += " = [" + diceNoList.join(" ") + "]";
            }
            
            var total:int = getDiceTotal();
            var result:String = "ダイス合計：" + total + " (" + diceTypesString + ")";
            return result;
        }
        
        private function moveSamePositionDice():void {
            for(var i:int = 0;  i < this.dice.length ; i++){
                var diceInfo:Object = this.dice[i];
                
                var modX:int = diceSize * -1;
                var modY:int = diceSize * -1;
                var counter:int = 0;
                
                while( isHitAnotherDice(diceInfo.view) ) {
                    
                    if( (counter % 2) == 0 ) {
                        diceInfo.view.x += modX;
                        if(diceInfo.view.x < 0) {
                            diceInfo.view.x = 0;
                            modX *= -1;
                        }
                        
                    } else {
                        diceInfo.view.y += modY;
                        if(diceInfo.view.y < 0) {
                            diceInfo.view.y = 0;
                            modY *= -1;
                        }
                    }
                    
                    counter++;
                }
            }
        }
        
        private function isHitAnotherDice(view:UIComponent):Boolean {
            for(var i:int = 0;  i < this.dice.length ; i++){
                var diceInfo:Object = this.dice[i];
                var targetView:UIComponent = diceInfo.view;
                
                if( targetView == view ) {
                    continue;
                }
                
                if( isHitDice(targetView, view) ) {
                    return true;
                }
            }
            
            return false;
        }
        
        private function isHitDice(image1:UIComponent, image2:UIComponent):Boolean {
            var diffX:int = Math.abs(image1.x - image2.x);
            var diffY:int = Math.abs(image1.y - image2.y);
            var diff:int = Math.sqrt(diffX * diffX + diffY * diffY);
            
            return (diff < (diceSize * 0.5));
        }
        
        private function isAllDiceEnded():Boolean {
            for(var i:int = 0;  i < this.dice.length ; i++){
                var diceInfo:Object = this.dice[i];
                if( diceInfo.state != "end" ) {
                    return false;
                }
            }
            return true;
        }
        
        
        private function updateDiceOne(diceInfo:Object):void {
            
            if( diceInfo == null ) {
                return;
            }
            
            if(diceInfo.state == "start") {
                Log.loggingTuning("updateDiceOne start");
                this.startRolling(diceInfo);
                return;
            }
            
            if(diceInfo.state == "move") {
                this.updateDiceOneMoveState(diceInfo);
                return;
            }
            if( diceInfo.state == "end" ) {
                return;
            }
            
            if( diceInfo.state == "stop" ) {
                changeDirection(diceInfo);
                return;
            }
            
            Log.loggingError("diceInfo.state is invalid.", diceInfo.state);
        }
        
        private function startRolling(diceInfo:Object):void {
            diceInfo.accelerationY = this.diceSize * (getWindowHeight() / 800);
            if(diceInfo.accelerationY < this.diceSize) {
                diceInfo.accelerationY = this.diceSize;
            }
            
            diceInfo.vx = (getWindowWidth() / 1000) * (1 - 0.1 * diceInfo.number) * castPower * -1;// * 25;
            diceInfo.boundBasePositionY = diceInfo.lastPositionY + (getWindowHeight() - diceInfo.lastPositionY) * 0.1;//0.2;
            
            diceInfo.state = "move";
        }
        
        private function changeDirection(diceInfo:Object):void {
            if( diceInfo.direct == null ) {
                diceInfo.direct = "min";
                diceInfo.directCounter = 0;
                return;
            }
            
            diceInfo.directCounter++;
            if( diceInfo.directCounter < changeDirectionIntervalFrameCount ) {
                return;
            }
            diceInfo.directCounter = 0;
            
            if( changeDirectionMax(diceInfo) ) {
                return;
            }
            
            changeDirectionMin(diceInfo);
        }
        
        private function changeDirectionMin(diceInfo:Object):Boolean {
            if( diceInfo.direct != "min" ) {
                return false;
            }
            
            diceInfo.stopedDice.visible = false;
            diceInfo.rotateDice.visible = true;
            diceInfo.direct = "max";
            
            return true;
        }
        
        private function changeDirectionMax(diceInfo:Object):Boolean {
            if( diceInfo.direct != "max" ) {
                return false;
            }
            
            diceInfo.stopedDice.visible = true;
            diceInfo.rotateDice.visible = false;
            diceInfo.direct = "min";
            
            return true;
        }
        
        private function updateDiceOneMoveState(diceInfo:Object):void {
            changeDirection(diceInfo);
            
            diceInfo.accelerationY = diceInfo.accelerationY - 9.8;
            diceInfo.y += (-1.0 * diceInfo.accelerationY);
            diceInfo.x += diceInfo.vx;
            if( (diceInfo.x < 0) || (diceInfo.x > (getWindowWidth() + parentWindow.width) ) ) {
                diceInfo.vx *= -1;
            }
            
            if( this.isFolling(diceInfo) ) {
                this.updateDiceOneFolling(diceInfo);
            }
            
            diceInfo.view.y = diceInfo.y;
            diceInfo.view.x = diceInfo.x;
        }
        
        private function isFolling(diceInfo:Object):Boolean {
            return ((diceInfo.accelerationY < 0) && (diceInfo.y > diceInfo.boundBasePositionY));
        }
        
        private function updateDiceOneFolling(diceInfo:Object):void {
            diceInfo.accelerationY = -1 * diceInfo.accelerationY * 0.94;
            diceInfo.vx *= 0.86;
            diceInfo.y = diceInfo.boundBasePositionY - (diceInfo.y - diceInfo.boundBasePositionY);
            diceInfo.boundBasePositionY = diceInfo.boundBasePositionY * 0.75;
            
            if( this.isReachToEndPoint(diceInfo) ) {
                this.showRollResult(diceInfo);
            }
        }
        
        private function isReachToEndPoint(diceInfo:Object):Boolean {
            //return (diceInfo.boundBasePositionY < diceInfo.lastPositionY);
            return (diceInfo.view.y < diceInfo.lastPositionY);
        }
        
        private function getRoolResult(diceType:String):int {
            var max:int = DiceInfo.getDiceTypeInfo(diceType, "max") as int;
            var result:int = getRandomNumber(max)
            return result;
        }
        
        private function showRollResult(diceInfo:Object):void {
            if( diceInfo == null ) {
                return;
            }
            
            diceInfo.state = "end";
            diceInfo.view.y = diceInfo.y;
            changeDirectionMax(diceInfo);
            
            var resultValue:int = getRoolResult(diceInfo.diceType);
            changeDiceImageToResult(diceInfo, diceInfo.diceType, resultValue);
            var getResultValue:Function = DiceInfo.getDiceTypeInfo(diceInfo.diceType, "getResultValue") as Function;
            resultValue = getResultValue(resultValue);
            Log.logging("resultValue", resultValue);
            
            diceInfo.resultValue = resultValue;
            
            var resultFunction:Function = diceInfo.resultFunction as Function;
            if( resultFunction != null ) {
                Log.logging("resultFunction resultValue", resultValue);
                resultFunction(resultValue);
            }
            
            diceInfo.view.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
                    thisObj.clearDice();
                });
            
            Log.loggingTuning("dice roll is end.")
        }
        
        private function setDiceView(diceInfo:Object):void {
            var diceType:String = diceInfo.diceType;
            
            var view:UIComponent = new UIComponent(); 
            parent.addChild(view);
            view.addEventListener(MouseEvent.MOUSE_DOWN, thisObj.recordCastStartTime);
            view.addEventListener(MouseEvent.MOUSE_UP, thisObj.castDice);
            
            var stopedDice:Image = getDiceViewImageStop(diceType);
            var rotateDice:Image = getDiceViewImageRotate(diceType);
            view.addChild( stopedDice );
            view.addChild( rotateDice );
            
            diceInfo.view = view;
            diceInfo.stopedDice = stopedDice;
            diceInfo.rotateDice = rotateDice;
            
            initContextMenu(view);
        }
        
        private function initContextMenu(view:UIComponent):void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            MovablePiece.addMenuItem(menu, "ダイスの削除", clearDiceFromMenu);
            
            view.contextMenu = menu;
        }
        
        private function clearDiceFromMenu(event:ContextMenuEvent):void {
            clearDice();
        }
        
        private function getDiceViewImageStop(diceType:String):Image {
            var image:Image = new Image();
            
            image.source = DiceInfo.getDiceMaxNumberImage(diceType);
            image.width = diceSize;
            image.height = diceSize;
            image.visible = true;
            
            return image;
        }
        
        private function getDiceViewImageRotate(diceType:String):Image {
            var image:Image = new Image();
            
            image.source = DiceInfo.getDiceImage(diceType, 1);
            image.width = diceSize;
            image.height = diceSize;
            image.visible = false;
            image.rotation = 270;
            image.y = diceSize;
            
            return image;
        }
        
        private function changeDiceImageToResult(diceInfo:Object, diceType:String, resultValue:int):void {
            Log.logging("changeDiceImageToResult start");
            
            diceInfo.stopedDice.visible = true;
            diceInfo.rotateDice.visible = false;
            
            var image:Image = diceInfo.stopedDice;
            Log.logging("diceType", diceType);
            Log.logging("resultValue", resultValue);
            image.source = DiceInfo.getDiceImage(diceType, resultValue);
            
            Log.logging("changeDiceImageToResult end");
        }
        
        private function getStartPosition(i:int, diceCount:int):Object {
            var dicePadding:Number = diceSize / 2;
            
            var xPaddings:Array = [2, 4, 6, 8, 3, 5, 7, 9];
            var xIndex:int = ((diceCount - i - 1) % xPaddings.length);
            var x:int = xPaddings[xIndex] * dicePadding;
            
            var yRate:int = Math.floor((diceCount - i - 1) / (xPaddings.length / 2));
            var y:int = (yRate * dicePadding);
            
            return {"x":x, "y":y};
        }
            
            
        private function setStartPosition(diceInfo:Object, i:int):void {
            var point:Object = this.getStartPosition(i, this.diceTypes.length);
            
            diceInfo.view.x = getWindowWidth() - point.x;
            diceInfo.view.y = getWindowHeight() - point.y;
            
            diceInfo.state = "stop";
            
            diceInfo.lastPositionY = point.y * 1.8;
            diceInfo.y = diceInfo.view.y;
            diceInfo.x = diceInfo.view.x;
            diceInfo.accelerationY = 0;
            
            /*
            obj.img.src = this.getRollingDiceImageFileName(obj.diceType)
                obj.img.style.width = this.diceSize + "px";
            obj.img.alt = "throw!!";
            
            if( this.zIndex ) {
                obj.style.zIndex = this.zIndex;
            }
            
            obj.appendChild(obj.img);
            */
        }
        
        //ダイスロール時の勢い(Power)を決定
        private var castMinPower:Number = 25;
        private var castPower:Number = 25;
        private var castMaxPower:Number = 100;
        //ダイスロールはクリック時間で決まる。最大待ち時間は１秒(1000ミリ秒)
        private var castMaxWaitTime:int = 1000;
        
        
        private var castStartTime:Number = 0;
        
        private function recordCastStartTime(event:MouseEvent):void {
            castStartTime = new Date().time;
        }
        
        private function getCastPower():Number {
            var castEndTime:Number = new Date().time;
            var diffTime:Number = (castEndTime - castStartTime);
            
            //上限待ち時間越えてるなら最大値へ
            if( diffTime > castMaxWaitTime ) {
                return castMaxPower;
            }
            
            var powerRatePerTime:Number = ( (castMaxPower - castMinPower) / castMaxWaitTime );
            return (powerRatePerTime * diffTime + castMinPower);
        }
        
        private function castDice(event:MouseEvent):void {
            castPower = getCastPower();
            castDiceWithPower();
        }
        
        private function castDiceWithPower():void {
            for(var i:int = 0 ; i < this.dice.length ; i++) {
                if(this.dice[i].state == "stop") {
                    this.dice[i].state = "start";
                    Log.loggingTuning("cast dice start");
                }
            }
        }
    }
}
