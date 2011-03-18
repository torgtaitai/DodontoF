//--*-coding:utf-8-*--

package {
    import flash.events.Event;
    
    public class SharedDataSenderDummy extends SharedDataSender {
        
        private var receiver:SharedDataReceiverDummy;
        private var resultFunction:Function;
        private var thisObj:SharedDataSender ;
        
        public function getRefreshedCount():int {
            return receiver.getRefreshedCount();
        }
        
        public function init():void {
            thisObj = this;
            
            receiver.init();
            resultFunction = null;
            
            clearLastUpdateTimes();
        }
        
        public function setResultFunction(resultFunction_:Function):void {
            resultFunction = resultFunction_;
        }
        
        
        override protected function newReceiverForInitialize():SharedDataReceiver {
            receiver = new SharedDataReceiverDummy();
            
            return receiver;
        }
        
        
        override protected function sendCommandDataCatched(paramsString:String,
                                                           callBack:Function,
                                                           callBackForError:Function,
                                                           isRefresh:Boolean = false):void {
            
            var wrappedCallBack:Function = callBack;
            var wrappedCallBackError:Function = callBack;
            
            if( resultFunction != null ) {
                wrappedCallBack = function(event:Event):void {
                    if( callBack != null ) {
                        callBack.call(thisObj, event);
                    }
                    resultFunction.call();
                }
                wrappedCallBackError = function(event:Event):void {
                    if( callBackForError != null ) {
                        callBackForError.call(this, event);
                    }
                }
            }
            
            super.sendCommandDataCatched(paramsString, wrappedCallBack,
                                         wrappedCallBackError, isRefresh);
        }
        
        override protected function startRefreshTimeout():void {
            //NO action
        }

    }
}

