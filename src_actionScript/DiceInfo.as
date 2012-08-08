//--*-coding:utf-8-*--
package {
    public class DiceInfo {
        
        public static function getDiceImage(diceType:String, number:int):Class {
            if( number == 0 ) {
                return secretDice;
            }
            
            var imageList:Array = getDiceImageList(diceType);
            return imageList[ number - 1 ];
        }
        
        public static function getDiceMaxNumberImage(diceType:String):Class {
            if( isSecretDiceType(diceType) ) {
                return secretDice;
            }
            
            var imageList:Array = getDiceImageList(diceType);
            var image:Class = imageList[imageList.length - 1];
            return image;
        }
        
        private static function isSecretDiceType(diceType:String):Boolean {
            return ( diceType == "d0" );
        }
        
        static public function getDiceImageUrlGlobal(max:int, number:int):String {
            if( max == 0 ) {
                return "./image/diceImage/secretDice.png";
            }
            
            return "./image/diceImage/" + max + "_dice/" + max + "_dice[" + number + "].png";
        }
        
		[Embed(source='../image/diceImage/unknown.png')]
        private static var secretDice:Class;
        private static var d0List:Array = [secretDice];
        
        //d4
		[Embed(source='../image/diceImage/4_dice/4_dice[1].png')]
        private static var d4_1:Class;
		[Embed(source='../image/diceImage/4_dice/4_dice[2].png')]
        private static var d4_2:Class;
		[Embed(source='../image/diceImage/4_dice/4_dice[3].png')]
        private static var d4_3:Class;
		[Embed(source='../image/diceImage/4_dice/4_dice[4].png')]
        private static var d4_4:Class;
        private static var d4List:Array = [d4_1, d4_2, d4_3, d4_4];
        
        //d6
		[Embed(source='../image/diceImage/6_dice/6_dice[1].png')]
        private static var d6_1:Class;
		[Embed(source='../image/diceImage/6_dice/6_dice[2].png')]
        private static var d6_2:Class;
		[Embed(source='../image/diceImage/6_dice/6_dice[3].png')]
        private static var d6_3:Class;
		[Embed(source='../image/diceImage/6_dice/6_dice[4].png')]
        private static var d6_4:Class;
		[Embed(source='../image/diceImage/6_dice/6_dice[5].png')]
        private static var d6_5:Class;
		[Embed(source='../image/diceImage/6_dice/6_dice[6].png')]
        private static var d6_6:Class;
        private static var d6List:Array = [d6_1, d6_2, d6_3, d6_4, d6_5, d6_6];
        
        //d8
        [Embed(source='../image/diceImage/8_dice/8_dice[1].png')]
            private static var d8_1:Class;
        [Embed(source='../image/diceImage/8_dice/8_dice[2].png')]
            private static var d8_2:Class;
        [Embed(source='../image/diceImage/8_dice/8_dice[3].png')]
            private static var d8_3:Class;
        [Embed(source='../image/diceImage/8_dice/8_dice[4].png')]
            private static var d8_4:Class;
        [Embed(source='../image/diceImage/8_dice/8_dice[5].png')]
            private static var d8_5:Class;
        [Embed(source='../image/diceImage/8_dice/8_dice[6].png')]
            private static var d8_6:Class;
        [Embed(source='../image/diceImage/8_dice/8_dice[7].png')]
            private static var d8_7:Class;
        [Embed(source='../image/diceImage/8_dice/8_dice[8].png')]
            private static var d8_8:Class;
        private static var d8List:Array = [d8_1, d8_2, d8_3, d8_4, d8_5, d8_6, d8_7, d8_8];
        
        //d10
        [Embed(source='../image/diceImage/10_dice/10_dice[1].png')]
            private static var d10_1:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[2].png')]
            private static var d10_2:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[3].png')]
            private static var d10_3:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[4].png')]
            private static var d10_4:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[5].png')]
            private static var d10_5:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[6].png')]
            private static var d10_6:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[7].png')]
            private static var d10_7:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[8].png')]
            private static var d10_8:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[9].png')]
            private static var d10_9:Class;
        [Embed(source='../image/diceImage/10_dice/10_dice[10].png')]
            private static var d10_10:Class;
        private static var d10List:Array = [d10_1, d10_2, d10_3, d10_4, d10_5, d10_6, d10_7, d10_8, d10_9, d10_10];
        
        //d12
        [Embed(source='../image/diceImage/12_dice/12_dice[1].png')]
            private static var d12_1:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[2].png')]
            private static var d12_2:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[3].png')]
            private static var d12_3:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[4].png')]
            private static var d12_4:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[5].png')]
            private static var d12_5:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[6].png')]
            private static var d12_6:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[7].png')]
            private static var d12_7:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[8].png')]
            private static var d12_8:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[9].png')]
            private static var d12_9:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[10].png')]
            private static var d12_10:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[11].png')]
            private static var d12_11:Class;
        [Embed(source='../image/diceImage/12_dice/12_dice[12].png')]
            private static var d12_12:Class;
        private static var d12List:Array = [d12_1, d12_2, d12_3, d12_4, d12_5, d12_6, d12_7, d12_8, d12_9, d12_10, d12_11, d12_12];
        
        //d20
        [Embed(source='../image/diceImage/20_dice/20_dice[1].png')]
            private static var d20_1:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[2].png')]
            private static var d20_2:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[3].png')]
            private static var d20_3:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[4].png')]
            private static var d20_4:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[5].png')]
            private static var d20_5:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[6].png')]
            private static var d20_6:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[7].png')]
            private static var d20_7:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[8].png')]
            private static var d20_8:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[9].png')]
            private static var d20_9:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[10].png')]
            private static var d20_10:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[11].png')]
            private static var d20_11:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[12].png')]
            private static var d20_12:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[13].png')]
            private static var d20_13:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[14].png')]
            private static var d20_14:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[15].png')]
            private static var d20_15:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[16].png')]
            private static var d20_16:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[17].png')]
            private static var d20_17:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[18].png')]
            private static var d20_18:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[19].png')]
            private static var d20_19:Class;
        [Embed(source='../image/diceImage/20_dice/20_dice[20].png')]
            private static var d20_20:Class;
        private static var d20List:Array = [d20_1, d20_2, d20_3, d20_4, d20_5, d20_6, d20_7, d20_8, d20_9, d20_10, d20_11, d20_12, d20_13, d20_14, d20_15, d20_16, d20_17, d20_18, d20_19, d20_20];
        
        //d100
        [Embed(source='../image/diceImage/100_dice/100_dice[1].png')]
            private static var d100_1:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[2].png')]
            private static var d100_2:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[3].png')]
            private static var d100_3:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[4].png')]
            private static var d100_4:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[5].png')]
            private static var d100_5:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[6].png')]
            private static var d100_6:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[7].png')]
            private static var d100_7:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[8].png')]
            private static var d100_8:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[9].png')]
            private static var d100_9:Class;
        [Embed(source='../image/diceImage/100_dice/100_dice[10].png')]
            private static var d100_10:Class;
        private static var d100List:Array = [d100_1, d100_2, d100_3, d100_4, d100_5, d100_6, d100_7, d100_8, d100_9, d100_10];
        
        
        private static var diceTypeInfos:Object = {
            "d0"  : {"max": 0, "maxString":   "0", "imageList" :  d0List, "getResultValue" : noChange},
            "d4"  : {"max": 4, "maxString":   "4", "imageList" :  d4List, "getResultValue" : noChange},
            "d6"  : {"max": 6, "maxString":   "6", "imageList" :  d6List, "getResultValue" : noChange},
            "d8"  : {"max": 8, "maxString":   "8", "imageList" :  d8List, "getResultValue" : noChange},
            "d10" : {"max":10, "maxString":  "10", "imageList" : d10List, "getResultValue" : noChange},
            "d12" : {"max":12, "maxString":  "12", "imageList" : d12List, "getResultValue" : noChange},
            "d20" : {"max":20, "maxString":  "20", "imageList" : d20List, "getResultValue" : noChange},
            "d100": {"max":10, "maxString":"%100", "imageList" :d100List, "getResultValue" : changeToD100Result},
         "d100-10": {"max":10, "maxString": "%10", "imageList" : d10List, "getResultValue" : changeToD100_10Result}
        };
        
        
        public static function isValidDiceMax(max:int):Boolean {
            var diceType:String = 'd' + max;
            var info:Object = diceTypeInfos[diceType];
            return (info != null);
        }
        
        public static function getDiceTypeInfo(diceType:String, infoName:String):Object {
            return diceTypeInfos[diceType][infoName];
        }
        
        
        private static function getDiceImageList(diceType:String):Array {
            return getDiceTypeInfo(diceType, "imageList") as Array;
        }
        
        private static function noChange(value:int):int {
            return value;
        }
        
        private static function changeToD100Result(value:int):int {
            if( value == 10 ) {
                return 0;
            }
            return value * 10;
        }
        
        private static function changeToD100_10Result(value:int):int {
            if( value == 10 ) {
                return 0;
            }
            return value;
        }
        
    }
}
