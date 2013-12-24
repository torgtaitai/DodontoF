//--*-coding:utf-8-*--

package {
    
    import flash.events.Event;
    import flash.net.FileReference;
    import flash.net.FileFilter;
    import flash.utils.ByteArray;
    import mx.controls.Alert;
    
    public class SaveLoadLocalFile {
        
        private var saveDataName:String = "saveData";
        private var saveDataExt:String = "data";
        private var loadFunction:Function = null;
        private var saveDataTypeName:String = null;
        
        private var fileReferenceForSave:FileReference = new FileReference();
        private var fileReferenceForLoad:FileReference = new FileReference();
        
        public function init(name:String, ext:String, typeName:String, func:Function):void {
            saveDataName = name;
            saveDataExt = ext;
            saveDataTypeName = typeName;
            loadFunction = func;
        }
        
        public function save(saveData:Object, fileName:String):void {
            var saveDataWrapper:Object = {
                saveDataTypeName: saveDataTypeName,
                saveData: saveData };
            
            var data:String = Utils.getJsonString(saveDataWrapper);
            var fileName:String = fileName + "." + saveDataExt;
            fileReferenceForSave.save(data, fileName);
        }
        
        public function load():void {
            fileReferenceForLoad= new FileReference();
            fileReferenceForLoad.addEventListener(Event.SELECT, loadSelect);
            
            var filters:Array = new Array();
            filters.push(new FileFilter(saveDataName + "(*." + saveDataExt + ")", "*." + saveDataExt));
            fileReferenceForLoad.browse(filters);
        }
        
        public function loadSelect(e:Event):void {
            fileReferenceForLoad.addEventListener(Event.COMPLETE, loadComplete);
            fileReferenceForLoad.load();
        }
        
        public function loadComplete(e:Event):void {
            var data:ByteArray = fileReferenceForLoad.data as ByteArray;
            var dataString:String = data.toString();
            
            loadFromText(dataString);
        }
        
        public function loadFromText(dataString:String):void {
            if( dataString == null ) {
                return;
            }
            
            var saveData:Object = Utils.getJsonDataFromString(dataString) as Object;
            
            if( saveData.saveDataTypeName != null ) {
                if( saveData.saveDataTypeName != saveDataTypeName ) {
                    Alert.show( Language.text("saveDataNameNotMatched", saveDataName) );
                    return;
                }
                
                saveData = saveData.saveData;
            }
            
            
            if( saveData == null ) {
                Alert.show(Language.s.canNotOpenSaveDataBecauseInvalid);
                return;
            }
            
            if( loadFunction == null ) {
                return;
            }
            
            loadFunction(saveData);
        }
        
    }
}
