//--*-coding:utf-8-*--

package {
    
    public class AddCharacterWindow extends CharacterWindow {
        
        import mx.managers.PopUpManager;
        
        private static var characterPositionX:int;
        private static var characterPositionY:int;
        
        public static function setCharacterPosition(x:int = 1, y:int = 1):void {
            characterPositionX = x;
            characterPositionY = y;
        }
        
        protected override function init():void {
            title = "キャラクター追加";
            executeButton.label = "追加";
            
            initCounterValues();
            
            characterImageUrl.text = "./image/defaultImageSet/pawn/pawnBlack.png";
            printPreview();
        }
        
        public override function sendCharacterData(name:String,
                                                   imageUrl:String,
                                                   mirrored:Boolean,
                                                   size:int,
                                                   isHide:Boolean,
                                                   initiative:Number,
                                                   info:String,
                                                   counters:Object,
                                                   statusAlias:Object,
                                                   url:String):void {
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            
            var characterParams:Object =
                guiInputSender.getAndCheckAddCharacterParams(name,
                                                             imageUrl, 
                                                             mirrored,
                                                             size,
                                                             isHide, 
                                                             initiative,
                                                             info,
                                                             counters,
                                                             statusAlias,
                                                             url);
            
            var window:StockCharacterWindow =
                PopUpManager.createPopUp(this, StockCharacterWindow, false) as StockCharacterWindow;
            
            window.setParams(characterParams);
        }
    }
}

