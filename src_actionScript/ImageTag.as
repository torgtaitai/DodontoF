//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    import mx.controls.ComboBox;
    
    public class ImageTag {
        
        private static var allTag:String = "（全て）";
        private static var noneTag:String = "（未選択）";
        private static var characterTag:String = "キャラクター画像";
        private static var mapTag:String = "マップ画像";
        private static var floorTileTag:String = "フロアタイル画像";
        private static var standingGraphicsTag:String = "立ち絵";
        
        
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
        
        public static function getDefinedTagList():Array {
            return [characterTag, standingGraphicsTag, mapTag, floorTileTag];
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
        
        public function setImageTypes(comboBox:ComboBox, tagInfos:Object, defaultTags:Array, enabled:Boolean = true):void {
            Log.logging("setImageTypes begin");
            
            var imageTags:Array = defaultTags.concat();
            
            for(var key:String in tagInfos) {
                var tagInfo:Object = tagInfos[key];
                var tags:Array = tagInfo["tags"];
                if( tags == null ) {
                    continue;
                }
                
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
            }
            
            var selected:String = comboBox.text;
            
            comboBox.dataProvider = getComboBoxItems(imageTags);
            comboBox.enabled = enabled;
            
            if( selected != "" ) {
                Utils.selectComboBox(comboBox, selected, "label");
            }
            
            Log.logging("setImageTypes end");
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
            
            for(var i:int = 0 ; i < imageTags.length ; i++) {
                items.push( {label: imageTags[i]} );
            }
            
            return items;
        }
    }
}