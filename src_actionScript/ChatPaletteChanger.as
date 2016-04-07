//--*-coding:utf-8-*--

package {
    
    import mx.controls.TextInput;
    
    public class ChatPaletteChanger {
        
        private var buffer:Array = new Array();
        private var definitions:Object = new Object();
        private var characterName:TextInput = null;
        
        public function setTexts(array:Array):void {
            buffer = array;
        }
        
        public function getDefinitions():Object {
            return Utils.clone(definitions);
        }
        
        public function getText(index:int, name:TextInput, changerInfos:Array):String {
            characterName = name;
            var line:String = buffer[index];
            
            var definitionsFull:Object = addCounterNamesToDefinition(definitions);
            definitionsFull = addAllChangerToDefinition(definitionsFull, changerInfos, characterName.text);
            
            return getTextFromText(line, definitionsFull);
        }
        
        private function getTextFromText(line:String, definitionsFull:Object):String {
            if( line == null ) {
                return "";
            }
            
            line = line.replace('＊', '*');
            line = line.replace('＠', '@');
            
            for (var key:String in definitionsFull) {
                var value:String = definitionsFull[key];
                
                var pattern:String = "{" + key + "}";
                line = getChangedLine(line, pattern, value);
                var pattern2:String = "｛" + key + "｝";
                line = getChangedLine(line, pattern2, value);
            }
            
            Log.logging("getTextFromText result", line);
            return line;
        }
        
        private function getChangedLine(line:String, pattern:String, value:String):String {
            Log.logging("getChangedLine pattern", pattern);
            
            var oldLine:String = "";
            while (oldLine != line) {
                oldLine = line;
                line = line.replace(pattern, value);
            }
            
            return line;
        }
        
        
        public function analize():void {
            var lines:Array = buffer;
            
            var loopMax:int = 30;  //無限ループに、安全のため上限を設ける
            var index:int = 0;
            
            while( true ) {
                if( index > loopMax ) {
                    break;
                }
                index++;
                
                analizeDefinition(lines);
                
                var newLines:Array = getChangedTexts(lines);
                if( Utils.isSameArray(lines, newLines) ) {
                    break;
                }
                
                lines = newLines;
            }
        }
        
        
        static private var definitionRegExp:RegExp = /^(\/\/|／／)(.+?)\s*(=|＝)\s*(.+?)\s*$/m;
        
        private function analizeDefinition(lines:Array):void {
            definitions = new Object();
            
            for each(var line:String in lines) {
                analizeDefinitionByLine(line);
            }
            
            Log.logging("definitions", definitions);
        }
        
        private function analizeDefinitionByLine(line:String):void {
            var result:Object = definitionRegExp.exec(line);
            if( result == null ) {
                return;
            }
            
            var key:String = result[2];
            var value:String = result[4];
            definitions[key] = value;
        }
        
        private function addCounterNamesToDefinition(hash:Object):Object {
            var result:Object = Utils.clone(hash);
            
            var character:Character = getCharacterFromNameText();
            if( character == null ) {
                return result;
            }

            var counterNames:Array = DodontoF_Main.getInstance().getInitiativeWindow().getCounterNameList();
            
            for each(var counterName:String in counterNames) {
                var count:int = character.getCounter(counterName);
                result[counterName] = "" + count;
            }
            
            return result
        }
        
        private function addAllChangerToDefinition(definitionsFull:Object, changerInfos:Array, currentName:String):Object {
            
            for each(var changerInfo:Object in changerInfos) {
                
                var name:String = changerInfo.name;
                if( name == currentName ) {
                    continue;
                }
                
                var changer:ChatPaletteChanger = changerInfo.changer as ChatPaletteChanger;
                if( changer == null ) {
                    continue;
                }
                
                var anotherDefinitions:Object = changer.getDefinitions();
                for (var key:String in anotherDefinitions) {
                    var newKey:String = key + "@" + name;
                    if( definitionsFull[newKey] == null ) {
                        var value:Object = anotherDefinitions[key];
                        definitionsFull[newKey] = value;
                    }
                }
                
            }
            
            return definitionsFull;
        }
        
        private function getCharacterFromNameText():Character {
            var name:String = characterName.text;
            if( name == "" ) {
                name = ChatWindow.getInstance().getChatCharacterName()
            }
            
            var character:Character = DodontoF_Main.getInstance().getMap().findCharacterByName(name);
            return character;
        }
        
        
        private function getChangedTexts(lines:Array):Array {
            var newLines:Array = new Array();
            
            for each(var line:String in lines) {
                newLines.push( getTextFromText(line, definitions) );
            }
            
            return newLines;
        }
        
    }
}

/*
=====================================
//cl=8
//筋力=3
//知力=7
3d6+{知力}+{cl} エンサイクロペディア[エルディダイト]
2d6+{知力}+3 アイテム鑑定[出自：冒険者]
2d6+{筋力} 筋力判定
=====================================

//A = 1
//B = 2
//AB = {A} + {B}

*/
