//--*-coding:utf-8-*--

package {

    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import mx.events.FlexEvent;
    import mx.controls.Text;
    import mx.controls.TextArea;
    import mx.controls.Image;
    import mx.containers.HBox;
    import mx.controls.Button;
    import mx.controls.Alert;
    import mx.events.CloseEvent;
    import mx.managers.PopUpManager;
    
    public class Voter {
        
        [Embed(source='image/icons/exclamation.png')]
        [Bindable]
        private static var rollCallIcon:Class;
        
        [Embed(source='image/icons/tick.png')]
        [Bindable]
        private static var voteIcon:Class;
        
        
        private var chatWindow:ChatWindow;
        
        public function Voter(window:ChatWindow):void {
            chatWindow = window;
        }
        
        private var voteChatEffecter:ChatEffecter = new ChatEffecter("vote");
        private var voteReplayChatEffecter:ChatEffecter = new ChatEffecter("vote_replay_readyOK");
        
        public function execute():void {
            var window:VoteWindow = DodontoF.popup(VoteWindow, true) as VoteWindow;
            window.setVoter(this);
        }
        
        public function executeByParam(count:int, isCallTheRoll:Boolean, question:String):void {
            var params:Object = {
                callerId : getUniqueId(),
                requiredCount : count,
                isCallTheRoll : isCallTheRoll,
                question : question
            };
            recentParamms = params;
            
            var callString:String = voteChatEffecter.getSendMessage(params);
            
            chatWindow.chatMessageTrader_sendMessage_publicChatChannel( callString);
        }
        
        private function getUniqueId():String{
            return DodontoF_Main.getInstance().getUniqueId();
        }
        
        private var calledMemberRequiredCount:int = 0;
        private var yesCount:int = 0;
        private var noCount:int = 0;
        
        private var recentParamms:Object = new Object();
        
        private function checkCallTheRollReplay(message:String,
                                                standingGraphicFilterImageInfos:Array):String {
            var params:Object = voteReplayChatEffecter.getParams(message);
            if( params == null ) {
                return "";
            }
            
            if( calledMemberRequiredCount <= 0 ) {
                return null;
            }
            
            //点呼への応答を受け取った場合には以下の処理を実行
            inclimentVoteReplay(params);
            
            var filterImageInfo:Object = {
                "image" : getFilterImageFromVoteReplay(params)
            };
            
            standingGraphicFilterImageInfos.push(filterImageInfo);
            
            var result:String = getResultVoteReplay(params);
            
            //指定人数応答完了の場合
            if( getVoteReplayCount() >= calledMemberRequiredCount ) {
                result += "\n" + getVoteResult(params);
                yesCount = 0;
                noCount = 0;
            }
            
            return result;
        }
        
        private function getResultVoteReplay(params:Object):String {
            if( params.voteReplay == Alert.OK ) {
                return Language.text("rollCallResult",
                                     getVoteReplayCount(), calledMemberRequiredCount)
            } else if( params.voteReplay == Alert.YES ) {
                return Language.text("voteResultAgree",
                                     getVoteReplayCount(), calledMemberRequiredCount)
            } else if( params.voteReplay == Alert.NO ) {
                return Language.text("voteResultDisagree",
                                     getVoteReplayCount(), calledMemberRequiredCount)
            }
            return "";
        }
        
        private function getVoteResult(params:Object):String {
            if( params.isCallTheRoll ) {
                closeAnswerWindow();
                return Language.s.allReady;
            }
            
            return Language.text("voteTotalResult", yesCount, noCount);
        }
        
        private function getVoteReplayCount():int {
            return (yesCount + noCount);
        }
        
        private function inclimentVoteReplay(params:Object):void {
            if( (params.voteReplay == Alert.OK) || 
                (params.voteReplay == Alert.YES) ) {
                yesCount++;
            } else if( params.voteReplay == Alert.NO ) {
                noCount++;
            }
        }
        
        private function getFilterImageFromVoteReplay(params:Object):String {
            if( (params.voteReplay == Alert.OK) || 
                (params.voteReplay == Alert.YES) ) {
                return "./image/vote/circle.png";
            }
            
            if( (params.voteReplay == Alert.CANCEL) ||
                (params.voteReplay == Alert.NO) ) {
                return "./image/vote/cross.png";
            }
            
            return "./image/vote/triangle.png";
        }
        
        public function received(message:String, effectable:Boolean, 
                                 standingGraphicFilterImageInfos:Array):String {
            
            var result:String = message;
            
            var replayResult:String = checkCallTheRollReplay(message, standingGraphicFilterImageInfos);
            if( replayResult != "" ) {
                result = replayResult;
                return result;
            }
            
            var params:Object = voteChatEffecter.getParams(message);
            if( params == null ) {
                return result;
            }
            
            if( params.isCallTheRoll ) {
                result = Language.s.beginVote;
            } else {
                result = Language.s.beginRollCall + params.question;
            }
            
            yesCount = 0;
            noCount = 0;
            calledMemberRequiredCount = params.requiredCount;
            
            if( ! effectable ) {
                return result;
            }
            
            //自分の投票・点呼なら処理なし
            if( params.callerId == getUniqueId() ) {
                return result;
            }
            
            //見学者には投票権無し。現実は非常だ…
            if( DodontoF_Main.getInstance().isVisiterMode() ) {
                return result;
            }
            
            
            if( params.isCallTheRoll ) {
                answerWindow = Alert.show(Language.s.preshOkWhenReady, Language.s.vote, 
                                          Alert.OK | Alert.NONMODAL, null, 
                                          getSendVoteReplay(params), rollCallIcon);
            } else {
                answerWindow = Alert.show(params.question, Language.s.rollCall, 
                                          Alert.YES | Alert.NO | Alert.NONMODAL, null, 
                                          getSendVoteReplay(params), voteIcon);
            }
            
            initAnserWindow();
            
            return result;
        }
        
        private function initAnserWindow():void {
            answerWindow.alpha = 10.0;
            answerWindow.setStyle("backgroundColor", "0x333300");
            answerWindow.setStyle("headerColors", [0x00CC66, 0x00CC66]);
            answerWindow.setStyle("fillAlphas", 1);
        }
        
        private var answerWindow:Alert;

        private function closeAnswerWindow():void {
            if( answerWindow == null ) {
                return;
            }
            
            PopUpManager.removePopUp(answerWindow);
            answerWindow = null;
        }
        
        private function getSendVoteReplay(baseParams:Object):Function {
            return function(e:CloseEvent):void {
                var params:Object = {
                    isCallTheRoll : baseParams.isCallTheRoll,
                    voteReplay : e.detail
                };
                chatWindow.chatMessageTrader_sendMessage_publicChatChannel( voteReplayChatEffecter.getSendMessage(params) );
                answerWindow = null;
            };
        }
        
    }
}
