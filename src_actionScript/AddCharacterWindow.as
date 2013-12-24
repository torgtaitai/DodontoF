//--*-coding:utf-8-*--

package {
    
    /**
     * キャラクター追加画面
     */
    public class AddCharacterWindow extends CharacterWindow {
        
        import mx.managers.PopUpManager;
        
        /**
         * 初期化処理
         */
        protected override function init():void {
            title = Language.s.addCharacterWindowTitle;
            executeButton.label = Language.s.addButton;
            initCounterValues();
            
            characterImageUrl.text = "./image/defaultImageSet/pawn/pawnBlack.png";
            printPreview();
        }
        
        /**
         * キャラクターデータの追加処理
         */
        public override function sendCharacterData(name:String,
                                                   imageUrl:String,
                                                   images:Array,
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
                                                             images,
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

