//--*-coding:utf-8-*--

package {
    import mx.controls.Text;
    
    public class ChatMessageLogBoxDummy extends ChatMessageLogBox {
        
        override public function init(novelticMode:NovelticMode):void {
        }
        
        override public function getDefaultLabel():String {
            return "";
        }
        
        override public function getAllChatLogList():Array {
            return new Array();
        }
        
        override public function addBuffer(line:String, time:Number):void {
        }
        
        override public function checkNovelMode():void {
        }
        
        override public function setBackGroundColor(color:String):void {
        }
        
        override public function setLastText(novelticMode:NovelticMode):void {
        }
        
        override public function getChatMessageLogList():Array {
            return new Array();
        }
        
        override public function addNewTextBlock(textBlock:Text, isAddChild:Boolean):void {
        }
        
        override public function createChatMessageLog(novelticMode:NovelticMode):Text {
            var textArea:Text = new Text();
            return textArea;
        }
        
        override public function addChatLogText(novelticMode:NovelticMode, 
                                       chatFontSize:int,
                                       isCurrentChannel:Boolean):Boolean {
            return true;
        }
        
        override public function resetLabelCount():void {
        }
        
        override public function clearChatMessageLog():void {
        }

        
        override public function isScrollPositionBottom():Boolean {
            return true;
        }
        
        override public function validateNow_All():void {
        }
        
        override public function scrollChatBox(chatFontSize:int, isForceScroll:Boolean = false):void {
        }
        
        override public function resizeChatLog(chatFontSize:int, novelticMode:NovelticMode):void {
        }
    

    }
}