//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    import mx.controls.ComboBox;
    
    public class ImageTag {
        
        private static var allTag:String = Language.s.allTag;
        private static var noneTag:String = Language.s.noselectTag;
        private static var characterTag:String = Language.s.characterImageTag;
        private static var mapTag:String = Language.s.mapImageTag;
        private static var floorTileTag:String = Language.s.floorTileImageTag;
        private static var standingGraphicsTag:String = Language.s.standingGraphicTag;
        private static var monsterTag:String = Language.s.monsterImageTag;
        
        
        public static function getAllTag():String {
            return allTag;
        }
        
        public static function getNoneTag():String {
            return noneTag;
        }
        
        public static function getMapTag():String {
            return mapTag;
        }
        
        public static function getFloorTileTag():String {
            return floorTileTag;
        }
        
        public static function getCharacterTag():String {
            return characterTag;
        }
        
        public static function getStandingGraphicsTag():String {
            return standingGraphicsTag;
        }
        
        public static function getMonsterTag():String {
            return monsterTag;
        }
        
        public static function getDefinedTagList():Array {
            return [characterTag, monsterTag, standingGraphicsTag, mapTag, floorTileTag];
        }
        
        static public function getTags(text:String):Array {
            var tags:Array = text.split(/[\s　]+/);
            
            var result:Array = new Array();
            for(var i:int = 0 ; i < tags.length ; i++) {
                var tag:String = tags[i];
                
                if( tag == "" ) {
                    continue;
                }
                
                result.push(tag);
            }
            
            return result;
        }
        
        public function setImageTypes(comboBox:ComboBox, tagInfos:Object, defaultTags:Array, password:String = ""):void {
            Log.logging("setImageTypes begin");
            
            var imageTags:Array = defaultTags.concat();
            
            for(var imageUrl:String in tagInfos) {
                
                if( ! isTargetRoom(imageUrl, tagInfos) ) {
                    continue;
                }
                
                var tagInfo:Object = tagInfos[imageUrl];
                var tags:Array = tagInfo["tags"];
                if( tags == null ) {
                    continue;
                }
                
                if( ! checkPassword(password, tagInfo) ) {
                    continue;
                }
                
                imageTags = addTagsToImageTags(tags, imageTags);
            }
            
            var selected:String = comboBox.text;
            
            comboBox.dataProvider = getComboBoxItems(imageTags);
            comboBox.enabled = true;
            
            if( selected != "" ) {
                Utils.selectComboBox(comboBox, selected, "label");
            }
            
            Log.logging("setImageTypes end");
        }
        
        private function checkPassword(password:String, tagInfo:Object):Boolean {
            var imagePassword:String = tagInfo["password"];
            if( imagePassword == null ) {
                return true;
            }
            
            if( imagePassword == "" ) {
                return true;
            }
            
            return (password == imagePassword);
        }
        
        static public function isTargetRoom(imageUrl:String, tagInfos:Object):Boolean {
           
           if( tagInfos == null ) {
               return true;
           }
           
           var tagInfo:Object = tagInfos[imageUrl];
           if( tagInfo == null ) {
               return true;
           }
           
           if( tagInfo["roomNumber"] == null ) {
               return true;
           }
           
           var roomNumber:int = parseInt(tagInfo["roomNumber"]);
           return (roomNumber == TagManagerWindow.getRoomNumber());
       }
       

        private function addTagsToImageTags(tags:Array, imageTags:Array):Array {
            for(var i:int = 0 ; i < tags.length ; i++) {
                var tag:String = tags[i];
                
                if( tag == "" ) {
                    continue;
                }
                
                if( isInclude(imageTags, tag) ) {
                    continue;
                }
                
                imageTags.push(tag);
            }
            
            return imageTags;
        }
        
        
        public static function isInclude(array:Array, target:String):Boolean {
            for(var i:int = 0 ; i < array.length ; i++) {
                if( array[i] == target ) {
                    return true;
                }
            }
            
            return false;
        }
        
        private function getComboBoxItems(imageTags:Array):Array {
            var items:Array = new Array();
            
            imageTags = Utils.clone(imageTags);
            imageTags.sort(Array.CASEINSENSITIVE);
            
            for(var i:int = 0 ; i < imageTags.length ; i++) {
                items.push( {label: imageTags[i]} );
            }
            
            return items;
        }
    }
}
