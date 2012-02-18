//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    
    public class ChangeCharacterWindow extends CharacterWindow {
        import mx.managers.PopUpManager;
        
        protected override function isLoadInitImageList():Boolean {
            return false;
        }
    
        protected override function init():void {
            if( character.isOnlyOwnMap() ) {
                PopUpManager.removePopUp(this);
            }
            
            title = "キャラクター変更";
            executeButton.label = "変更";
            
            characterName.text = character.getName();
            characterImageUrl.text = imageSelecter.getImageUrlChanger().getShort( character.getImageUrl() );
            characterSize.value = character.getSize();
            isHide.selected = character.isHideMode();
            characterInitiative.value = Utils.getInitiativeInt(character.getInitiative());
            characterInitiativeModify.value = Utils.getInitiativeModify(character.getInitiative());
            characterOtherInfo.text = character.getInfo();
            statusAlias = character.getStatusAlias();
            url.text = character.getUrl();
            
            initCounterValues();
            
            printPreview();
        }
        
        
        public override function sendCharacterData(name:String,
                                                   imageUrl:String,
                                                   size:int, isHide:Boolean,
                                                   initiative:Number,
                                                   info:String,
                                                   counters:Object, 
                                                   statusAlias:Object,
                                                   url:String):void {
            Log.logging("statusAlias", statusAlias);
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            
            guiInputSender.changeCharacter(character,
                                           name,
                                           imageUrl,
                                           size,
                                           isHide,
                                           initiative,
                                           info,
                                           counters,
                                           statusAlias,
                                           url);
        }
    }
}

