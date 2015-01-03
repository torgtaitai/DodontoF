//--*-coding:utf-8-*--

package {
    
    public class ZenkakuToHankaku {
        
        private var isDiceBotText:Boolean = false;
        
        public function changeForDiceBot(str:String):String {
            
            str = changeOnSpace(str);
            
            isDiceBotText = true;
            return change(str);
        }
        
        public function change(str:String):String{
            str = changeOnAlphabet(str);
            str = changeOnNumber(str);
            str = changeOnOperator(str);
            str = changeOnMark(str);
            return str;
        }
        
        public function changeOnSpace(str:String):String {
            str = changeOnAll(str, "　", null, " ");
            return str;
        }
        
        // 文字列の中の全角記号を半角に直して戻す
        public function changeOnMark(str:String):String {
            str = changeOnAll(str, "＠", null, "@");
            str = changeOnAll(str, "「", null, "[");
            str = changeOnAll(str, "」", null, "]");
            str = changeOnAll(str, "［", null, "[");
            str = changeOnAll(str, "］", null, "]");
            str = changeOnAll(str, "、", null, ",");
            str = changeOnAll(str, "，", null, ",");
            str = changeOnAll(str, "＃", null, "#");
            str = changeOnAll(str, "＄", null, "$");
            return str;
        }
        
        // 文字列の中の全角算術記号を半角に直して戻す
        public function changeOnOperator(str:String):String {
            str = changeOnAll(str, "（", null, "(");
            str = changeOnAll(str, "）", null, ")");
            str = changeOnAll(str, "＊", null, "*");
            str = changeOnAll(str, "／", null, "/");
            str = changeOnAll(str, "＋", null, "+");
            str = changeOnAll(str, String.fromCharCode(65293),  null, "-");
            str = changeOnAll(str, "＝", null, "=");
            str = changeOnAll(str, "＞", null, ">");
            str = changeOnAll(str, "＜", null, "<");
            return str;
        }
        
        // 文字列の中の全角英字を半角英字に直して戻す
        public function changeOnAlphabet(str:String):String {
            str = changeOnAll(str, "Ａ", "Ｚ", "A");
            str = changeOnAll(str, "ａ", "ｚ", "a");
            return str;
        }
        
        // 文字列の中の全角数字を半角数字に直して戻す
        public function changeOnNumber(str:String):String {
            str = changeOnAll(str, "０", "９", "0");
            return str;
        }
        
        
        public function changeOnAll(str:String,
                                    startString:String, endString:String,
                                    changeStartString:String):String {
            
            if( endString == null ) {
                endString = startString;
            }
            
            var startCode:Number = startString.charCodeAt(0);
            var endCode:Number = endString.charCodeAt(0);
            var changeStartCode:Number = changeStartString.charCodeAt(0);
            
            return changeOnAllByCode(str, startCode, endCode, changeStartCode);
        }
        
        public function changeOnAllByCode(str:String,
                                          startCode:Number, endCode:Number,
                                          changeStartCode:Number):String {
            var result:String = "";
            var isDiceStringEnd:Boolean = false;
            
            for(var i:int = 0 ; i < str.length ; i++){
                var targetChar:String = str.charAt(i);
                
                if( isDiceStringEnd ) {
                    result += targetChar;
                    continue;
                }
                
                targetChar = getChangedCharacter(targetChar, startCode, endCode, changeStartCode);
                
                if( isCommentPart(targetChar, result) ) {
                    isDiceStringEnd = true;
                }
                
                result += targetChar;
            }
            
            return result;
        }
        
        
        public function getChangedCharacter(targetChar:String,
                                            startCode:Number, endCode:Number,
                                            changeStartCode:Number):String {
            var code:Number = targetChar.charCodeAt(0);
            
            if( (code >= startCode) && (code <= endCode) ) {
                var diff:Number = (code - startCode);
                code = changeStartCode + diff;
            }
            
            return String.fromCharCode(code);
        }
        
        
        /*
         * ダイスボット文字列の場合、コメント部分まで半角変換すると不都合があるので
         * コメント箇所に到達したかをここでチェックする
         */
        private function isCommentPart(targetChar:String, result:String):Boolean {
            
            //ダイスボット文字でない場合は、このチェック自体が不要
            if( ! isDiceBotText ) {
                return false;
            }
            
            //空白じゃないということは、コメント箇所までまだ来ていない
            if( targetChar != " " ) {
                return false;
            }
            
            //ダイスボットの文字列は以下の2パターンが存在する
            // 3d6 コメント  ：パターン１、「３ｄ６」を振る
            // 2 3d6 コメント：パターン２、「３ｄ６」を２回振る。
            // 前者の場合、空白スペース以降の文字列はコメントのため変換不要。
            // 後者の場合、空白スペースを1回までは許容する必要がある。
            // この空白スペースの上限をここでチェックする
            
            var loopCountChecked:Object = diceBotLoopCountReg.exec(result);
            
            //これはパターン１の場合。この場合、以降の文字変換は不要
            if( loopCountChecked == null ) {
                return true;
            }
            
            //ここに来るということは、パターン２。
            //すでに result にスペース文字が含まれているならなら、以降はコメント箇所と言える
            var space:String = loopCountChecked[2];
            return ( space != null );
        }
        
        static private var diceBotLoopCountReg:RegExp = /^[\d０-９]+(\s*$|(\s+).+)$/;
        
        
    }
}
