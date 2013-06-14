//--*-coding:utf-8-*--

package {
    
    import flash.display.Shape;
    import mx.core.UIComponent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import mx.effects.*;
    
    public class MessageBaloon {
        
        private var drawSpace:Shape = new Shape();
        private var lineSpace:Shape = new Shape();
        private var shadowSpace:Shape = new Shape();
        private var message:String;
        
        private var width:uint = 100;
        private var height:uint = 35;
        private var fontSize:int = 25;
        
        private var parent:UIComponent;
        private var base:UIComponent = new UIComponent();
        private var resultBase:UIComponent = new UIComponent();
        private var effect:Effect;
        
        public function init(parent_:UIComponent):void {
            parent = parent_;
            
            base.visible = false;
            base.alpha = 0.8;
            
            parent.addChild(base);
            base.addChild(shadowSpace);
            base.addChild(lineSpace);
            base.addChild(drawSpace);
        }
        
        public function printMessage(message_:String):void {
            this.message = message_;
            
            tuneHeigtWidthMessage();
            draw();
            playEffect();
            
            var resultField:TextField = getTextField();
            
            resultBase.y = -height;
            resultBase.addChild(resultField);
            
            parent.addChild(resultBase);
        }
        
        private function tuneHeigtWidthMessage():void {
            var parts:Array = getSplitText(this.message);
            var maxLength:int = getArrayStringMaxLength(parts);
            
            this.height = (this.height - textPadding) * parts.length;
            
            this.width = maxLength * fontSize + 50;
            this.width = this.width + (this.width % 2);//幅は偶数に切り上げ
            
            this.message = parts.join("\n");
        }
        
        
        private var textPadding:int = 3;
        private var lineLimitLength:int = 30;
        
        private function getSplitText(text:String):Array {
            var parts:Array = splitArrayText([text], "。", true);
            parts = splitArrayText(parts, "\n", false);
            
            var result:Array = [];
            
            for each(var text:String in  parts) {
                if( text.length == 0 ) {
                    continue;
                }
                
                
                if( text.length > lineLimitLength ) {
                    //1行が長すぎるならさらに区切る事
                    var delimiters:Array = ["、", "」", "]", "／",  "/"];
                    addSplitedText(text, delimiters, result);
                    continue;
                }
                
                result.push(text);
            }
            
            return result;
        }
        
        private function splitArrayText(parts:Array, separator:String, isInclude:Boolean):Array {
            var result:Array = [];
            
            for each(var text:String in  parts) {
                    
                    while(true) {
                        if( text.length == 0 ) {
                            break;
                        }
                        
                        var index:int = text.indexOf(separator);
                        if( index == -1 ) {
                            result.push(text);
                            break;
                        }
                        
                        var beforeTextEndIndex:int = (isInclude ? (index + 1) : index);
                        var beforeText:String = text.substring(0, beforeTextEndIndex);
                        result.push(beforeText);
                        
                        text = text.substring(index + 1);
                    }
                }
            
            
            return result;
        }
        
        private function addSplitedText(text:String, delimiters:Array, result:Array):void {
            var delimiter:String = delimiters.shift();
            if( delimiter == null ) {
                result.push(text);
                return;
            }
            
            var index:int = text.indexOf(delimiter, (lineLimitLength / 2));
            
            if( index == -1 ) {
                result.push(text);
                return;
            }
            
            var head:String = text.slice(0, index + 1);
            var tail:String = text.slice(index + 1);
            
            result.push(head);
            
            if( tail.length < lineLimitLength ) {
                result.push(tail);
            } else {
                addSplitedText(tail, delimiters, result);
            }
        }
        
        private function getArrayStringMaxLength(parts:Array):int {
            var maxLength:int = 0;
            
            for each(var text:String in parts) {
                    var length:int = text.length;
                    if( length > maxLength ) {
                        maxLength = length;
                    }
                }
            
            return maxLength;
        }
        
        private function playEffect():void {
            base.visible = true;
            initEffect();
            effect.play();
        }
        
        private function initEffect():void {
            var effect:Parallel = new Parallel();
            effect.addChild( getFade() );
            effect.addChild( getBlur() );
            
            effect.duration = 150;
            effect.target = base;
            
            this.effect = effect;
        }
        
        private function getFade():Fade {
            var effect:Fade = new Fade();
            effect.alphaFrom = 0;
            effect.alphaTo = 0.8;
            return effect;
        }

        private function getBlur():Blur {
            var effect:Blur = new Blur();
            effect.blurXFrom = 50;
            effect.blurXTo = 0;
            effect.blurYFrom = 50;
            effect.blurYTo = 0;
            return effect;
        }

        
        private function geGlow():Glow {
            var effect:Glow = new Glow();
            effect.alphaFrom = 0;
            effect.alphaTo = 0.8;
            effect.blurXFrom = 30;
            effect.blurXTo = 0;
            effect.blurYFrom = 30;
            effect.blurYTo = 0;
            return effect;
        }
        
        private function draw():void {
            clear();
            
            drawSpace.graphics.beginFill( getColor() );
            lineSpace.graphics.beginFill(0x333333);
            shadowSpace.graphics.beginFill(0x000000, 0.3);
            
            var roundWidth:uint = 10;//角丸幅
            var lineWidth:uint = 2;
            var shadowOffsetX:uint = 3;
            var shadowOffsetY:uint = 2;
            
            //角丸矩形_x座標,y座標,幅,高さ,角丸半径
            
            drawSpace.graphics.drawRoundRect(0, -height,
                                             width, height,
                                             roundWidth);
            
            lineSpace.graphics.drawRoundRect(-lineWidth, (-height - lineWidth),
                                             (width + (2 * lineWidth)), (height + (2 * lineWidth)),
                                             (roundWidth + lineWidth));
            
            shadowSpace.graphics.drawRoundRect((-lineWidth + shadowOffsetX),
                                               (-height - lineWidth + shadowOffsetY),
                                               (width + (2 * lineWidth)), (height + (2 * lineWidth)),
                                               (roundWidth + lineWidth));
        }
        
        public function clear():void {
            drawSpace.graphics.clear();
            lineSpace.graphics.clear();
            shadowSpace.graphics.clear();
            
            try {
                parent.removeChild(resultBase);
            } catch(e:Error) {
            }
        }
        
        static private var successList:Array = ["成功"];
        static private var failedList:Array = ["失敗"];
        
        static private var successColor:uint = 0x66FF66;
        static private var failedColor:uint = 0xFF0033;
        static private var nomalColor:uint = 0x66FFFF;
        
        private function getColor():uint {
            if( isMatch(successList, this.message) ) {
                return successColor;
            }
            
            if( isMatch(failedList, this.message) ) {
                return failedColor;
            }
            
            return nomalColor;
        }
        
        private function isMatch(results:Array, text:String):Boolean {
            for each(var result:String in results) {
                if( text.indexOf(result) != -1 ) {
                    return true;
                }
            }
            return false;
        }
        
        private function getTextField():TextField {
            var textField:TextField = new TextField();
            
            var format:TextFormat = new TextFormat();
            format.size = fontSize;
            format.bold = true;
            
            textField.defaultTextFormat = format;
            
            textField.wordWrap = false;
            textField.multiline = false;
            textField.selectable = false
            textField.mouseEnabled = false;
            
            textField.width = width;
            textField.height = height;
            textField.autoSize = TextFieldAutoSize.CENTER;
            
            textField.text = this.message;
            
            return textField;
        }
        
    }
}

