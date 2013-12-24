//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    
    public class ChangeCharacterWindow extends CharacterWindow {
        import mx.managers.PopUpManager;
        
        protected override function isLoadInitImageList():Boolean {
            return false;
        }
    
        override protected function initImageList():void {
            var images:Array = character.getImages();
            for(var i:int = 0 ; i < images.length ; i++) {
                addImageList(images[i]);
            }
            
            var index:int = findImageInfoIndexByActoin(function(imageInfo:Object):Boolean {
                    return (imageInfo["image"].source == character.getImageUrl());
                });
            
            if( index == -1 ) {
                index = 0;
            }
            selectImageList( index );
            
            Log.logging("ChangeCharacterWindow.initImageList selectImageList index", index);
        }
        
        protected override function init():void {
            if( character.isOnlyOwnMap() ) {
                PopUpManager.removePopUp(this);
            }
            
            title = Language.s.changeCharacterWindowTitle;
            executeButton.label = Language.s.changeCharacterWindowButton;
            
            characterName.text = character.getName();
            
            characterImageUrl.text = imageSelecter.getImageUrlChanger().getShort( character.getImageUrl() );
            imageSelecter.setMirrored(character.isMirrored());
            
            characterSize.value = character.getSize();
            isHide.selected = character.isHideMode();
            characterOtherInfo.text = character.getInfo();
            statusAlias = character.getStatusAlias();
            url.text = character.getUrl();
            
            initCounterValues();
            
            printPreview();
        }
        
        override protected function initInitiative(counterInfo:Object):void {
            counterInfo["initiativeInt"] = Utils.getInitiativeInt(character.getInitiative());
            counterInfo["initiativeModify"] = Utils.getInitiativeModify(character.getInitiative());
        }
        
        public override function sendCharacterData(name:String,
                                                   imageUrl:String,
                                                   images:Array,
                                                   mirrored:Boolean,
                                                   size:int, isHide:Boolean,
                                                   initiative:Number,
                                                   info:String,
                                                   counters:Object, 
                                                   statusAlias:Object,
                                                   url:String):void {
            Log.logging("ChangeCharacterWindow.sendCharacterData Begin statusAlias", statusAlias);
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            
            guiInputSender.changeCharacter(character,
                                           name,
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
            
            Log.logging("ChangeCharacterWindow.sendCharacterData End");
        }
    }
}

