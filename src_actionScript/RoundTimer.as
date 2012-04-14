//--*-coding:utf-8-*--

package {
    
    public class RoundTimer {
        private var currentRound:int = 0;
        private var initInitiative:int = 0;
        private var currentInitiative:Number = initInitiative;
        private var history:Array = new Array();
        private var sender:SharedDataSender;
        private var isChanged:Boolean = true;
        
        private var counterNames:Array = [];
        
        public function getCounterNames():Array {
            return counterNames.concat();
        }
        
        
        public function setSender(sender_:SharedDataSender):void {
            sender = sender_;
        }
        
        public function setReciever(receiver:SharedDataReceiver):void {
            receiver.setRoundTimer(this);
        }
        
        public function RoundTimer() {
        }
        
        public function clearForReplay():void {
            isChanged = true;
        }
        
        public function getInitiativeWindow():InitiativeWindow {
            return InitiativeWindow.getInstance();
        }
        
        private var initiativedPieces:Array = new Array();
        
        public function getSortedInitiativedPiece():Array {
            sortInitiativedPiece();
            return initiativedPieces.concat();
        }
        
        public function sortInitiativedPiece():void {
            initiativedPieces = initiativedPieces.sort(sortedByInitiative);
        }
        
        public function setExistCharacters(pieces:Array):void {
            var initiativedPiecesTmp:Array = new Array();
            
            for(var i:int = 0 ; i < pieces.length ; i++) {
                var pieceOrg:Piece = pieces[i];
                var piece:InitiativedPiece = pieceOrg as InitiativedPiece;
                if( piece == null ) {
                    continue;
                }

                if( piece.isHideMode() ) {
                    continue;
                }
                
                Log.logging("piece is InitiativedPiece", piece.getName());
                Log.logging("initiative is ", piece.getInitiative());
                initiativedPiecesTmp.push(piece);
            }
            
            initiativedPiecesTmp.sort(sortedByInitiative);
            initiativedPieces = initiativedPiecesTmp;
        }
        
        private function sortedByInitiative(a:Object, b:Object):Number {
            var initiative1:Number = a.getInitiative();
            var initiative2:Number = b.getInitiative();
            
            if (initiative1 < initiative2) {
                return 1;
            }
            
            if (initiative1 > initiative2) {
                return -1;
            }
            
            return 0;
        }
        
        
        private function getInitiatives():Array {
            var initiatives:Array = new Array();
            
            sortInitiativedPiece();
            for(var i:int = 0 ; i < initiativedPieces.length ; i++) {
                var piece:InitiativedPiece= initiativedPieces[i];
                var targetInitiative:Number = piece.getInitiative();
                if( initiatives.indexOf(targetInitiative) == -1 ) {
                    initiatives.push(targetInitiative);
                }
            }
            
            return initiatives;
        }
        
        private function getNextInitiative(initiatives:Array):Number {
            Log.logging("currentInitiative", currentInitiative);
            
            for(var i:int = 0 ; i < initiatives.length ; i++) {
                var targetInitiative:Number = initiatives[i];
                Log.logging("targetInitiative", targetInitiative);
                if( targetInitiative < currentInitiative ) {
                    return targetInitiative
                }
            }
            Log.logging("initiatives.length", initiatives.length);
            
            var nextInitiative:Number = 0;
            if( initiatives.length > 0 ) {
                nextInitiative = initiatives[0];
            }
            
            Log.logging("nextInitiative", nextInitiative);
            return nextInitiative;
        }
        
        private function getMaxInitiative():Number {
            sortInitiativedPiece();
            
            if( initiativedPieces.length == 0 ) {
                return 0;
            }
            
            var piece:InitiativedPiece= initiativedPieces[0];
            return piece.getInitiative();
        }
        
        public function next():void {
            Log.logging("RoundTimer.next begin");
            
            var initiatives:Array = getInitiatives();
            Log.logging("initiatives.length", initiatives.length);
            var nextInitiative:Number = getNextInitiative(initiatives);
            Log.logging("nextInitiative", nextInitiative);
            
            var nextRound:int = this.currentRound;
            if( nextInitiative >= currentInitiative ) {
                nextRound++;
            }
            Log.logging("nextRound", nextRound);
            
            this.pushCurrentToHistory();
            this.sendRoundTimeData(nextRound, nextInitiative);
            
            Log.logging("RoundTimer.next end");
        }
        
        private function pushCurrentToHistory():void {
            
            if( initInitiative == currentInitiative ) {
                return;
            }
            
            var timeData:Object = {
                "round" : this.currentRound,
                "initiative" : this.currentInitiative};
            
            history.push(timeData);
        }
        
        public function previous():void {
            var timeData:Object = this.history.pop();
            if( timeData == null ) {
                return;
            }
            
            this.sendRoundTimeData(timeData.round, timeData.initiative);
        }
        
        public function sendRoundTimeData(round:int, initiative:Number):void {
            sender.sendRoundTimeData(round, initiative, counterNames);
        }
        
        public function reset():void {
            var round:int =  1;
            var initiative:Number = this.getMaxInitiative();
            this.pushCurrentToHistory();
            this.sendRoundTimeData(round, initiative);
        }
        
        public function setCounterNames(names:Array):void {
            if( names == null ) {
                return;
            }
            
            counterNames = new Array();
            for(var i:int = 0 ; i < names.length ; i++) {
                var name:String = names[i];
                name = name.replace(/^＊/, '*');
                
                if( name == "" ) {
                    continue;
                }
                
                counterNames.push( name);
            }
        }
        
        public function sendCounterNames(names:Array):void {
            setCounterNames(names);
            sendRoundTimeData(currentRound, currentInitiative);
        }
        
        public function setTime(currentRound_:int, currentInitiative_:Number):void {
            if( ( currentRound_ != currentRound ) || 
                ( currentInitiative_ != currentInitiative  ) ) {
                isChanged = true;
            }
            
            currentRound = currentRound_;
            currentInitiative = currentInitiative_;
        }
        
        public function getCurrentRound():int {
            return currentRound;
        }
        
        public function getCurrentInitiative():Number {
            return currentInitiative;
        }
        
        public function getHistoryCount():int {
            return history.length;
        }
        
        public function refreshInitiativeList():void {
            getInitiativeWindow().refresh();
            
            if( ! isChanged ) {
                return;
            }
            
            isChanged = false;
            
            var lastPickup:InitiativedPiece = null;
            
            sortInitiativedPiece();
            
            for(var i:int = 0 ; i < initiativedPieces.length ; i++) {
                var piece:InitiativedPiece = initiativedPieces[i];
                if( piece.getInitiative() == currentInitiative ) {
                    piece.pickup();
                    piece.pickupOnInitiative();
                    return;
                }
            }
        }
        
        
    }
}
